import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'dart:math' as math;
import '../../models/user.dart';
import '../../models/class_model.dart';
import '../../services/api_service.dart';

class AttendanceSessionScreen extends StatefulWidget {
  final User currentUser;
  final ClassModel classItem;

  const AttendanceSessionScreen({
    super.key,
    required this.currentUser,
    required this.classItem,
  });

  @override
  State<AttendanceSessionScreen> createState() => _AttendanceSessionScreenState();
}

class _AttendanceSessionScreenState extends State<AttendanceSessionScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _pulseController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _pulseAnimation;

  String _sessionCode = '';
  String _qrData = '';
  bool _isSessionActive = false;
  bool _isLoading = false;
  int _selectedDuration = 30; // minutes
  DateTime? _sessionStartTime;
  DateTime? _sessionEndTime;

  // List of durations to choose from
  final List<int> _durations = [5, 10, 15, 30, 45, 60];

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _generateSessionCode();
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeIn),
    );

    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _fadeController.forward();
    _pulseController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  String _generateSessionCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = math.Random.secure();
    _sessionCode = List.generate(6, (_) => chars[random.nextInt(chars.length)])
        .join();

    // Create QR data with session info
    _qrData = '''
{
  "sessionId": "${DateTime.now().millisecondsSinceEpoch}",
  "classId": "${widget.classItem.id}",
  "className": "${widget.classItem.name}",
  "sessionCode": "$_sessionCode",
  "instructor": "${widget.currentUser.fullName}",
  "timestamp": "${DateTime.now().toIso8601String()}"
}
''';

    return _sessionCode;
  }

  Future<void> _startAttendanceSession() async {
    setState(() => _isLoading = true);

    try {
      // Start attendance session via API
      final response = await ApiService.makeAuthenticatedRequest(
        'POST',
        '/api/v1/classes/${widget.classItem.id}/attendance/start',
        body: {
          'duration_minutes': _selectedDuration,
          'attendance_method': 'all', // Allow both QR and PIN
          'location': widget.classItem.room,
          'require_location_validation': false,
          'allow_offsite_attendance': true,
        },
      );

      if (response['success'] == true) {
        setState(() {
          _isSessionActive = true;
          _sessionStartTime = DateTime.now();
          _sessionEndTime = DateTime.now().add(Duration(minutes: _selectedDuration));
          _isLoading = false;
        });

        // Show success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Phiên điểm danh đã bắt đầu! Mã PIN: $_sessionCode'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 3),
            ),
          );
        }

        // Auto-stop session when duration ends
        Future.delayed(Duration(minutes: _selectedDuration), () {
          if (mounted && _isSessionActive) {
            _stopAttendanceSession();
          }
        });
      } else {
        throw Exception(response['message'] ?? 'Failed to start session');
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi khi bắt đầu phiên điểm danh: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _stopAttendanceSession() async {
    try {
      // Stop attendance session via API
      final response = await ApiService.makeAuthenticatedRequest(
        'POST',
        '/api/v1/classes/${widget.classItem.id}/attendance/stop',
      );

      setState(() {
        _isSessionActive = false;
        _sessionStartTime = null;
        _sessionEndTime = null;
      });

      if (response['success'] == true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Phiên điểm danh đã kết thúc'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi khi kết thúc phiên: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _getRemainingTime() {
    if (!_isSessionActive || _sessionEndTime == null) return '';

    final remaining = _sessionEndTime!.difference(DateTime.now());
    if (remaining.isNegative) return 'Đã hết thời gian';

    final minutes = remaining.inMinutes;
    final seconds = remaining.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Điểm danh: ${widget.classItem.name}'),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Class Info Card
              _buildClassInfoCard(),

              const SizedBox(height: 24),

              // Session Control
              _buildSessionControl(),

              const SizedBox(height: 24),

              // QR Code Display
              if (_isSessionActive) ...[
                _buildQRCodeSection(),
                const SizedBox(height: 24),
                _buildSessionStatus(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildClassInfoCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.class_, color: Colors.blue[700], size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.classItem.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (widget.classItem.isSubjectClass)
                        Text(
                          widget.classItem.subject,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.room, color: Colors.grey[600], size: 16),
                const SizedBox(width: 4),
                Text(
                  widget.classItem.room,
                  style: TextStyle(color: Colors.grey[600]),
                ),
                const SizedBox(width: 16),
                Icon(Icons.schedule, color: Colors.grey[600], size: 16),
                const SizedBox(width: 4),
                Text(
                  widget.classItem.timeRange,
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSessionControl() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Thiết lập phiên điểm danh',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // Duration Selection
            const Text('Thời gian (phút):'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _durations.map((duration) {
                final isSelected = _selectedDuration == duration;
                return InkWell(
                  onTap: _isSessionActive ? null : () {
                    setState(() => _selectedDuration = duration);
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Colors.blue[700]
                          : Colors.grey[200],
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '$duration phút',
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.grey[700],
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 20),

            // Session Code Display
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Mã PIN:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Row(
                    children: [
                      Text(
                        _sessionCode,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: () {
                          setState(() => _generateSessionCode());
                        },
                        icon: const Icon(Icons.refresh),
                        tooltip: 'Tạo mã mới',
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isLoading || _isSessionActive
                        ? null
                        : _startAttendanceSession,
                    icon: _isLoading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.play_arrow),
                    label: Text(_isLoading ? 'Đang xử lý...' : 'Bắt đầu điểm danh'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                if (_isSessionActive) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _stopAttendanceSession,
                      icon: const Icon(Icons.stop),
                      label: const Text('Kết thúc'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQRCodeSection() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              'Quét mã QR để điểm danh',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // QR Code with pulse animation
            AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _pulseAnimation.value,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blue.withOpacity(0.3),
                          spreadRadius: 2,
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: QrImageView(
                      data: _qrData,
                      version: QrVersions.auto,
                      size: 200.0,
                      backgroundColor: Colors.white,
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 16),
            Text(
              'HOẶC nhập mã PIN: $_sessionCode',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSessionStatus() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Phiên đang hoạt động',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  const Text('Thời gian còn lại:', style: TextStyle(fontSize: 12)),
                  Text(
                    _getRemainingTime(),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}