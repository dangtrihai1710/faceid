import 'package:flutter/material.dart';
import 'dart:async';
import 'package:camera/camera.dart';
import 'package:geolocator/geolocator.dart';
import '../models/class_model.dart';
import '../models/user.dart';
import '../models/attendance_model.dart';
import '../services/class_service.dart';
import '../services/auth_service.dart';
import '../widgets/camera_view.dart';
import 'qr_generator_screen.dart';
import 'qr_generator_enhanced_screen.dart';
import 'teacher_scan_screen.dart';

class ClassDetailScreen extends StatefulWidget {
  final ClassModel classModel;
  final User currentUser;
  final List<CameraDescription>? cameras;

  const ClassDetailScreen({
    super.key,
    required this.classModel,
    required this.currentUser,
    this.cameras,
  });

  @override
  State<ClassDetailScreen> createState() => _ClassDetailScreenState();
}

class _ClassDetailScreenState extends State<ClassDetailScreen> {
  final ClassService _classService = ClassService();
  final AuthService _authService = AuthService();
  CameraController? _cameraController;
  bool _isCameraInitialized = false;
  bool _isProcessingAttendance = false;
  bool _isLoadingAttendance = false;
  bool _isLoadingStudents = false;
  List<AttendanceModel> _attendanceList = [];
  List<User> _studentList = [];
  Position? _currentPosition;
  String? _statusMessage;
  late ClassModel _currentClass;
  Timer? _realtimeUpdateTimer;

  @override
  void initState() {
    super.initState();
    _currentClass = widget.classModel;
    _initializeCamera();
    _getCurrentLocation();
    _loadAttendanceList();
    _loadStudentList();
    _startRealtimeUpdates();
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _realtimeUpdateTimer?.cancel();
    super.dispose();
  }

  Future<void> _initializeCamera() async {
    if (widget.cameras != null && widget.cameras!.isNotEmpty) {
      try {
        _cameraController = CameraController(
          widget.cameras!.first,
          ResolutionPreset.high,
          enableAudio: false,
        );
        await _cameraController!.initialize();
        if (mounted) {
          setState(() {
            _isCameraInitialized = true;
          });
        }
      } catch (e) {
        print('Camera initialization error: $e');
        setState(() {
          _statusMessage = "Camera không khả dụng";
        });
      }
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _statusMessage = "Dịch vụ vị trí không bật";
        });
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _statusMessage = "Quyền truy cập vị trí bị từ chối";
          });
          return;
        }
      }

      final position = await Geolocator.getCurrentPosition();
      setState(() {
        _currentPosition = position;
      });
    } catch (e) {
      print('Location error: $e');
      setState(() {
        _statusMessage = "Lỗi lấy vị trí: $e";
      });
    }
  }

  Future<void> _loadAttendanceList() async {
    setState(() {
      _isLoadingAttendance = true;
    });

    try {
      final attendanceList = await ClassService.getAttendanceRecordsByClass(_currentClass.id);
      setState(() {
        _attendanceList = attendanceList;
        _isLoadingAttendance = false;
      });
    } catch (e) {
      print('Error loading attendance list: $e');
      setState(() {
        _isLoadingAttendance = false;
        _statusMessage = "Lỗi tải danh sách điểm danh";
      });
    }
  }

  Future<void> _loadStudentList() async {
    if (!_isInstructor()) return;

    setState(() {
      _isLoadingStudents = true;
    });

    try {
      // Simulate loading student list - in real app, this would come from database
      final students = _generateMockStudents();
      setState(() {
        _studentList = students;
        _isLoadingStudents = false;
      });
    } catch (e) {
      print('Error loading student list: $e');
      setState(() {
        _isLoadingStudents = false;
      });
    }
  }

  List<User> _generateMockStudents() {
    // Mock student data for demonstration
    return [
      User(id: '1', fullName: 'Nguyễn Văn An', email: 'an@example.com', username: 'an', token: 'token1', role: 'student', createdAt: DateTime.now()),
      User(id: '2', fullName: 'Trần Thị Bình', email: 'binh@example.com', username: 'binh', token: 'token2', role: 'student', createdAt: DateTime.now()),
      User(id: '3', fullName: 'Lê Văn Cường', email: 'cuong@example.com', username: 'cuong', token: 'token3', role: 'student', createdAt: DateTime.now()),
      User(id: '4', fullName: 'Phạm Thị Dung', email: 'dung@example.com', username: 'dung', token: 'token4', role: 'student', createdAt: DateTime.now()),
      User(id: '5', fullName: 'Hoàng Văn Em', email: 'em@example.com', username: 'em', token: 'token5', role: 'student', createdAt: DateTime.now()),
      User(id: '6', fullName: 'Đỗ Thị Giang', email: 'giang@example.com', username: 'giang', token: 'token6', role: 'student', createdAt: DateTime.now()),
      User(id: '7', fullName: 'Bùi Văn Hùng', email: 'hung@example.com', username: 'hung', token: 'token7', role: 'student', createdAt: DateTime.now()),
      User(id: '8', fullName: 'Ngô Thị Lan', email: 'lan@example.com', username: 'lan', token: 'token8', role: 'student', createdAt: DateTime.now()),
      User(id: '9', fullName: 'Đinh Văn Minh', email: 'minh@example.com', username: 'minh', token: 'token9', role: 'student', createdAt: DateTime.now()),
      User(id: '10', fullName: 'Vũ Thị Nga', email: 'nga@example.com', username: 'nga', token: 'token10', role: 'student', createdAt: DateTime.now()),
    ];
  }

  bool _isInstructor() {
    return widget.currentUser.fullName.toLowerCase() == _currentClass.instructor.toLowerCase() ||
           widget.currentUser.role == 'instructor';
  }

  Future<void> _toggleAttendance() async {
    try {
      final newIsOpen = !_currentClass.isAttendanceOpen;
      final updatedClass = _currentClass.copyWith(
        isAttendanceOpen: newIsOpen,
        attendanceOpenTime: newIsOpen ? DateTime.now() : null,
        attendanceCloseTime: newIsOpen ? null : DateTime.now(),
      );

      await ClassService.updateClass(updatedClass);

      setState(() {
        _currentClass = updatedClass;
      });

      // Start/stop real-time updates based on session status
      if (_currentClass.isAttendanceOpen) {
        _startRealtimeUpdates();
      } else {
        _stopRealtimeUpdates();
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_currentClass.isAttendanceOpen
              ? '✅ Đã mở buổi học - Sinh viên có thể điểm danh'
              : '🔒 Đã chốt buổi học - Không thể điểm danh thêm'),
          backgroundColor: _currentClass.isAttendanceOpen ? Colors.green : Colors.orange,
        ),
      );
    } catch (e) {
      print('Error toggling attendance: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lỗi khi thay đổi trạng thái điểm danh'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  AttendanceStatus _getStudentAttendanceStatus(String studentId) {
    try {
      final today = DateTime.now();
      final todayAttendance = _attendanceList.where((attendance) {
        return attendance.userId == studentId &&
               attendance.checkInTime.day == today.day &&
               attendance.checkInTime.month == today.month &&
               attendance.checkInTime.year == today.year;
      }).toList();

      if (todayAttendance.isNotEmpty) {
        return todayAttendance.first.status;
      }
      return AttendanceStatus.absent; // Default to absent if no record
    } catch (e) {
      return AttendanceStatus.absent;
    }
  }

  int _getPresentCount() {
    return _studentList.where((student) {
      final status = _getStudentAttendanceStatus(student.id);
      return status == AttendanceStatus.present || status == AttendanceStatus.late;
    }).length;
  }

  int _getAbsentCount() {
    return _studentList.where((student) {
      final status = _getStudentAttendanceStatus(student.id);
      return status == AttendanceStatus.absent;
    }).length;
  }

  void _startRealtimeUpdates() {
    if (!_isInstructor()) return;

    _realtimeUpdateTimer?.cancel();
    _realtimeUpdateTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      if (mounted && _currentClass.isAttendanceOpen) {
        _loadAttendanceList();
      }
    });
  }

  void _stopRealtimeUpdates() {
    _realtimeUpdateTimer?.cancel();
  }

  String _getLastUpdateTime() {
    final now = DateTime.now();
    return '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';
  }

  List<AttendanceModel> _getRecentAttendance() {
    final fiveMinutesAgo = DateTime.now().subtract(const Duration(minutes: 5));
    return _attendanceList.where((attendance) {
      return attendance.checkInTime.isAfter(fiveMinutesAgo);
    }).toList();
  }

  Future<void> _markAttendance() async {
    if (!_currentClass.isAttendanceOpen) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lớp học chưa mở điểm danh'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Camera chưa sẵn sàng'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isProcessingAttendance = true;
      _statusMessage = "Đang xử lý điểm danh...";
    });

    try {
      final XFile file = await _cameraController!.takePicture();

      // Simulate face recognition and attendance processing
      await Future.delayed(const Duration(seconds: 3));

      final attendance = AttendanceModel(
        id: 'att_${DateTime.now().millisecondsSinceEpoch}',
        classId: _currentClass.id,
        userId: widget.currentUser.id,
        checkInTime: DateTime.now(),
        photoPath: file.path,
        latitude: _currentPosition?.latitude,
        longitude: _currentPosition?.longitude,
        status: AttendanceStatus.present,
      );

      await ClassService.saveAttendanceRecord(attendance);
      await _loadAttendanceList();

      setState(() {
        _isProcessingAttendance = false;
        _statusMessage = "✅ Điểm danh thành công!";
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Điểm danh thành công!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      print('Attendance error: $e');
      setState(() {
        _isProcessingAttendance = false;
        _statusMessage = "Lỗi điểm danh: $e";
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi điểm danh: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Color _getClassStatusColor() {
    if (_currentClass.isAttendanceOpen) return Colors.green;
    if (_currentClass.isOngoing) return Colors.blue;
    if (_currentClass.isUpcoming) return Colors.orange;
    return Colors.grey;
  }

  Widget _buildClassInfoCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.class_,
                  color: _getClassStatusColor(),
                  size: 32,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _currentClass.name,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        _currentClass.subject,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getClassStatusColor().withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _getClassStatusColor()),
                  ),
                  child: Text(
                    _currentClass.statusText,
                    style: TextStyle(
                      color: _getClassStatusColor(),
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(Icons.person, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Text(
                  'Giảng viên: ${_currentClass.instructor}',
                  style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.access_time, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Text(
                  'Thời gian: ${_currentClass.timeRange}',
                  style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.location_on, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Text(
                  'Phòng: ${_currentClass.room}',
                  style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                ),
              ],
            ),
            if (_currentClass.description != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.description, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _currentClass.description!,
                      style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAttendanceControl() {
    if (_isInstructor()) {
      return Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.admin_panel_settings, color: Colors.purple[700]),
                  const SizedBox(width: 8),
                  const Text(
                    'Điều khiển buổi học',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Session Status Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _currentClass.isAttendanceOpen
                      ? Colors.green.withOpacity(0.1)
                      : Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _currentClass.isAttendanceOpen ? Colors.green : Colors.orange,
                    width: 2,
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _currentClass.isAttendanceOpen ? Icons.lock_open : Icons.lock,
                          color: _currentClass.isAttendanceOpen ? Colors.green : Colors.orange,
                          size: 32,
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _currentClass.isAttendanceOpen ? 'BUỔI HỌC ĐANG MỞ' : 'BUỔI HỌC ĐÃ ĐÓNG',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: _currentClass.isAttendanceOpen ? Colors.green : Colors.orange,
                              ),
                            ),
                            Text(
                              _currentClass.attendanceStatusText,
                              style: TextStyle(
                                color: _currentClass.isAttendanceOpen ? Colors.green[700] : Colors.orange[700],
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _currentClass.canOpenAttendance || _currentClass.canCloseAttendance
                                ? _toggleAttendance
                                : null,
                            icon: Icon(
                              _currentClass.isAttendanceOpen ? Icons.lock : Icons.lock_open,
                            ),
                            label: Text(
                              _currentClass.isAttendanceOpen ? 'Chốt buổi học' : 'Mở buổi học',
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _currentClass.isAttendanceOpen ? Colors.red : Colors.green,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              if (!_currentClass.canOpenAttendance && !_currentClass.canCloseAttendance) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.grey[600]),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _currentClass.isCompleted
                              ? 'Lớp học đã kết thúc, không thể thay đổi trạng thái'
                              : 'Chỉ có thể mở/đóng điểm danh trong thời gian diễn ra lớp học',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 16),

              // Action Buttons
              if (_currentClass.isAttendanceOpen) ...[
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => QRGeneratorEnhancedScreen(
                                classModel: _currentClass,
                                currentUser: widget.currentUser,
                              ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.qr_code),
                        label: const Text('Tạo QR OTP'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue[700],
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => TeacherScanScreen(
                                classModel: _currentClass,
                                currentUser: widget.currentUser,
                                cameras: widget.cameras,
                              ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.camera_alt),
                        label: const Text('Quét FaceID'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.purple[700],
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      );
    }

    // Student view
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.how_to_reg, color: Colors.blue[700]),
                const SizedBox(width: 8),
                const Text(
                  'Điểm danh',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _currentClass.isAttendanceOpen
                    ? Colors.green.withOpacity(0.1)
                    : Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _currentClass.isAttendanceOpen ? Colors.green : Colors.grey,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _currentClass.attendanceStatusText,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: _currentClass.isAttendanceOpen ? Colors.green : Colors.grey,
                          ),
                        ),
                        if (!_currentClass.isAttendanceOpen) ...[
                          const SizedBox(height: 4),
                          Text(
                            'Vui lòng chờ giảng viên mở điểm danh',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Icon(
                    _currentClass.isAttendanceOpen
                        ? Icons.check_circle
                        : Icons.access_time,
                    color: _currentClass.isAttendanceOpen ? Colors.green : Colors.grey,
                    size: 32,
                  ),
                ],
              ),
            ),
            if (_statusMessage != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue),
                ),
                child: Text(
                  _statusMessage!,
                  style: TextStyle(
                    color: Colors.blue[700],
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStudentListSection() {
    if (!_isInstructor()) return const SizedBox.shrink();

    final recentAttendance = _getRecentAttendance();

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.group, color: Colors.purple[700]),
                const SizedBox(width: 8),
                Text(
                  'Danh sách sinh viên (${_studentList.length})',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                // Real-time indicator
                if (_currentClass.isAttendanceOpen) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.green),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Colors.green,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'LIVE',
                          style: const TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                // Statistics
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.green),
                  ),
                  child: Text(
                    '✅ ${_getPresentCount()} có mặt',
                    style: const TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.red),
                  ),
                  child: Text(
                    '❌ ${_getAbsentCount()} vắng',
                    style: const TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),

            // Real-time activity feed
            if (recentAttendance.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.notifications_active, color: Colors.blue[700], size: 16),
                        const SizedBox(width: 4),
                        Text(
                          'Điểm danh gần đây',
                          style: TextStyle(
                            color: Colors.blue[700],
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          'Cập nhật: ${_getLastUpdateTime()}',
                          style: TextStyle(
                            color: Colors.blue[600],
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ...recentAttendance.take(3).map((attendance) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          children: [
                            Icon(
                              attendance.status == AttendanceStatus.present
                                  ? Icons.check_circle
                                  : Icons.access_time,
                              color: attendance.status == AttendanceStatus.present
                                  ? Colors.green
                                  : Colors.orange,
                              size: 12,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                'Sinh viên vừa điểm danh',
                                style: TextStyle(
                                  color: Colors.blue[700],
                                  fontSize: 11,
                                ),
                              ),
                            ),
                            Text(
                              '${attendance.checkInTime.minute.toString().padLeft(2, '0')}:${attendance.checkInTime.second.toString().padLeft(2, '0')}',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 16),
            if (_isLoadingStudents)
              const Center(child: CircularProgressIndicator())
            else if (_studentList.isEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Center(
                  child: Text(
                    'Chưa có danh sách sinh viên',
                    style: TextStyle(
                      color: Colors.grey,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _studentList.length,
                itemBuilder: (context, index) {
                  final student = _studentList[index];
                  final attendanceStatus = _getStudentAttendanceStatus(student.id);
                  final statusColor = _getStatusColor(attendanceStatus);
                  final statusText = _getStatusText(attendanceStatus);
                  final statusIcon = _getStatusIcon(attendanceStatus);

                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      leading: CircleAvatar(
                        backgroundColor: statusColor.withOpacity(0.2),
                        child: Icon(
                          Icons.person,
                          color: statusColor,
                          size: 20,
                        ),
                      ),
                      title: Text(
                        student.fullName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      subtitle: Text(
                        student.email,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: statusColor.withOpacity(0.3)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              statusIcon,
                              color: statusColor,
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              statusText,
                              style: TextStyle(
                                color: statusColor,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(AttendanceStatus status) {
    switch (status) {
      case AttendanceStatus.present:
        return Colors.green;
      case AttendanceStatus.late:
        return Colors.orange;
      case AttendanceStatus.absent:
        return Colors.red;
      case AttendanceStatus.excused:
        return Colors.blue;
      case AttendanceStatus.unknown:
        return Colors.grey;
    }
  }

  String _getStatusText(AttendanceStatus status) {
    switch (status) {
      case AttendanceStatus.present:
        return 'Có mặt';
      case AttendanceStatus.late:
        return 'Trễ';
      case AttendanceStatus.absent:
        return 'Vắng';
      case AttendanceStatus.excused:
        return 'Có phép';
      case AttendanceStatus.unknown:
        return 'Chưa điểm danh';
    }
  }

  IconData _getStatusIcon(AttendanceStatus status) {
    switch (status) {
      case AttendanceStatus.present:
        return Icons.check_circle;
      case AttendanceStatus.late:
        return Icons.access_time;
      case AttendanceStatus.absent:
        return Icons.cancel;
      case AttendanceStatus.excused:
        return Icons.event_available;
      case AttendanceStatus.unknown:
        return Icons.help;
    }
  }

  Widget _buildAttendanceSection() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.people, color: Colors.indigo[700]),
                const SizedBox(width: 8),
                Text(
                  'Lịch sử điểm danh (${_attendanceList.length})',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_isLoadingAttendance)
              const Center(child: CircularProgressIndicator())
            else if (_attendanceList.isEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Center(
                  child: Text(
                    'Chưa có ai điểm danh',
                    style: TextStyle(
                      color: Colors.grey,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _attendanceList.length,
                itemBuilder: (context, index) {
                  final attendance = _attendanceList[index];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: attendance.statusColor.withOpacity(0.2),
                      child: Icon(
                        Icons.person,
                        color: attendance.statusColor,
                        size: 20,
                      ),
                    ),
                    title: Text(
                      'Sinh viên ${index + 1}',
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    subtitle: Text(
                      'Thời gian: ${attendance.formattedCheckInTime}',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: attendance.statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        attendance.statusText,
                        style: TextStyle(
                          color: attendance.statusColor,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCameraSection() {
    if (!_isInstructor() && _currentClass.isAttendanceOpen) {
      return Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.camera_alt, color: Colors.green[700]),
                  const SizedBox(width: 8),
                  const Text(
                    'Điểm danh bằng FaceID',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (_isCameraInitialized && _cameraController != null)
                Container(
                  height: 200,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: CameraPreview(_cameraController!),
                  ),
                )
              else
                Container(
                  height: 200,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.camera_alt_outlined, size: 48, color: Colors.grey),
                        SizedBox(height: 8),
                        Text('Camera không khả dụng', style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isProcessingAttendance ? null : _markAttendance,
                  icon: _isProcessingAttendance
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.face),
                  label: Text(
                    _isProcessingAttendance ? 'Đang xử lý...' : 'Điểm danh ngay',
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return const SizedBox.shrink();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isInstructor() ? 'Quản lý lớp học' : 'Chi tiết lớp học'),
        backgroundColor: _isInstructor() ? Colors.purple[700] : Colors.blue[700],
        foregroundColor: Colors.white,
        elevation: 2,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await _loadAttendanceList();
          await _loadStudentList();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildClassInfoCard(),
              const SizedBox(height: 16),
              _buildAttendanceControl(),
              const SizedBox(height: 16),
              if (_isInstructor()) ...[
                _buildStudentListSection(),
                const SizedBox(height: 16),
              ],
              if (!_isInstructor()) _buildCameraSection(),
              const SizedBox(height: 16),
              _buildAttendanceSection(),
            ],
          ),
        ),
      ),
    );
  }
}