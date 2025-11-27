import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'dart:math';
import '../../models/user.dart';
import '../../models/class_model.dart';
import '../../services/api_service.dart';
import 'dart:developer' as developer;

class TeacherAttendanceCodeScreen extends StatefulWidget {
  final User currentUser;
  final ClassModel classModel;
  final String codeType; // 'qr' or 'pin'

  const TeacherAttendanceCodeScreen({
    super.key,
    required this.currentUser,
    required this.classModel,
    required this.codeType,
  });

  @override
  State<TeacherAttendanceCodeScreen> createState() => _TeacherAttendanceCodeScreenState();
}

class _TeacherAttendanceCodeScreenState extends State<TeacherAttendanceCodeScreen>
    with TickerProviderStateMixin {
  String? _generatedCode;
  DateTime? _generatedTime;
  final int _validDuration = 15; // 15 minutes
  bool _isActive = false;
  List<Map<String, dynamic>> _attendanceList = [];
  late AnimationController _animationController;
  
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  String _generateRandomCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    return String.fromCharCodes(Iterable.generate(
      6,
      (_) => chars.codeUnitAt(random.nextInt(chars.length)),
    ));
  }

  Future<void> _generateCode() async {
    setState(() {
      _generatedCode = _generateRandomCode();
      _generatedTime = DateTime.now();
      _isActive = true;
      _attendanceList = [];
    });

    _animationController.forward();

    try {
      final sessionData = {
        'class_id': widget.classModel.id,
        'attendance_code': _generatedCode,
        'code_type': widget.codeType.toUpperCase(),
        'expires_in_minutes': _validDuration,
      };

      final response = await ApiService.makeAuthenticatedRequest(
        'POST',
        '/api/v1/classes/${widget.classModel.id}/start-attendance-session',
        body: sessionData,
      );

      if (response['success'] == true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Đã tạo ${widget.codeType == 'qr' ? 'QR Code' : 'mã PIN'} thành công!'),
              backgroundColor: Colors.green,
            ),
          );
        }

        // Start checking attendance
        _startAttendanceMonitoring();
      } else {
        throw Exception(response['message'] ?? 'Failed to create session');
      }
    } catch (e) {
      setState(() {
        _isActive = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi tạo mã: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _startAttendanceMonitoring() {
    // Check attendance every 5 seconds
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted && _isActive) {
        _checkAttendanceUpdates();
      }
    });
  }

  Future<void> _checkAttendanceUpdates() async {
    try {
      // Get attendance records for the class
      final response = await ApiService.makeAuthenticatedRequest(
        'GET',
        '/api/v1/attendance/${widget.classModel.id}',
      );

      if (response['success'] == true && response['data'] != null) {
        final attendees = response['data'] as List;
        setState(() {
          _attendanceList = attendees.map((attendee) => {
            'studentId': attendee['student_id'] ?? '',
            'studentName': attendee['student_name'] ?? 'Unknown',
            'checkInTime': attendee['check_in_time'] ?? '',
            'status': attendee['status'] ?? 'present',
          }).toList();
        });
      }

      // Continue monitoring if session is still active
      if (_isActive && _generatedTime != null) {
        final now = DateTime.now();
        final validUntil = _generatedTime!.add(Duration(minutes: _validDuration));

        if (now.isBefore(validUntil)) {
          Future.delayed(const Duration(seconds: 5), () {
            if (mounted && _isActive) {
              _checkAttendanceUpdates();
            }
          });
        } else {
          _endSession();
        }
      }
    } catch (e) {
      developer.log('Error checking attendance: $e', name: 'TeacherAttendanceCode.check', level: 1000);
    }
  }

  void _endSession() async {
    try {
      // Stop the attendance session on the backend
      await ApiService.makeAuthenticatedRequest(
        'POST',
        '/api/v1/classes/${widget.classModel.id}/stop-attendance-session',
      );
    } catch (e) {
      developer.log('Error stopping session: $e', name: 'TeacherAttendanceCode.stop', level: 1000);
    }

    setState(() {
      _isActive = false;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Phiên điểm danh đã kết thúc!'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  bool _isSessionValid() {
    if (_generatedTime == null || !_isActive) return false;

    final now = DateTime.now();
    final validUntil = _generatedTime!.add(Duration(minutes: _validDuration));
    return now.isBefore(validUntil);
  }

  Duration get _remainingTime {
    if (_generatedTime == null) return Duration.zero;

    final now = DateTime.now();
    final validUntil = _generatedTime!.add(Duration(minutes: _validDuration));
    return validUntil.difference(now);
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          widget.codeType == 'qr' ? 'Tạo QR Code' : 'Tạo mã PIN',
        ),
        backgroundColor: widget.codeType == 'qr' ? Colors.blue : Colors.orange,
        foregroundColor: Colors.white,
        actions: [
          if (_isActive)
            IconButton(
              onPressed: _endSession,
              icon: const Icon(Icons.stop),
              tooltip: 'Kết thúc phiên',
            ),
        ],
      ),
      body: _generatedCode == null
          ? _buildGenerateCodeScreen()
          : _buildActiveSessionScreen(),
    );
  }

  Widget _buildGenerateCodeScreen() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              children: [
                Icon(
                  widget.codeType == 'qr' ? Icons.qr_code : Icons.pin,
                  size: 100,
                  color: widget.codeType == 'qr' ? Colors.blue : Colors.orange,
                ),
                const SizedBox(height: 24),
                Text(
                  'Lớp: ${widget.classModel.displayName}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Phòng: ${widget.classModel.room}',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Môn học: ${widget.classModel.subject}',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 32),
                Text(
                  'Thời gian hiệu lực: $_validDuration phút',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[500],
                  ),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _generateCode,
                    icon: Icon(
                      widget.codeType == 'qr' ? Icons.qr_code_2 : Icons.vpn_key,
                    ),
                    label: const Text('Tạo mã điểm danh'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: widget.codeType == 'qr' ? Colors.blue : Colors.orange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveSessionScreen() {
    final isValid = _isSessionValid();

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // Status Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isValid
                    ? [Colors.green[400]!, Colors.green[600]!]
                    : [Colors.red[400]!, Colors.red[600]!],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Icon(
                  isValid ? Icons.check_circle : Icons.access_time,
                  color: Colors.white,
                  size: 32,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isValid ? 'Phiên đang hoạt động' : 'Phiên đã hết hạn',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (isValid)
                        Text(
                          'Thời gian còn lại: ${_formatDuration(_remainingTime)}',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontSize: 14,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Code Display
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Text(
                  widget.codeType == 'qr' ? 'QR Code điểm danh' : 'Mã PIN điểm danh',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                if (widget.codeType == 'qr')
                  QrImageView(
                    data: _generatedCode!,
                    version: QrVersions.auto,
                    size: 200.0,
                    backgroundColor: Colors.white,
                  )
                else
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.orange[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.orange[300]!),
                    ),
                    child: Text(
                      _generatedCode!,
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange[700],
                        letterSpacing: 8,
                      ),
                    ),
                  ),
                const SizedBox(height: 16),
                Text(
                  'Mã: $_generatedCode',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Attendance Statistics
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.people, color: Colors.grey[700]),
                    const SizedBox(width: 8),
                    Text(
                      'Đã điểm danh: ${_attendanceList.length} sinh viên',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (_attendanceList.isNotEmpty)
                  ..._attendanceList.take(5).map((attendee) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Icon(Icons.check_circle,
                             color: Colors.green,
                             size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            attendee['studentName'],
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                        Text(
                          attendee['checkInTime'],
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ))
                else
                  Text(
                    'Chưa có sinh viên điểm danh',
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}