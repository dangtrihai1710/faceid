import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:geolocator/geolocator.dart';
import '../widgets/camera_view.dart';
import '../services/auth_service.dart';
import '../services/class_service.dart';
import '../services/face_enrollment_service.dart';
import '../models/user.dart';
import '../models/class_model.dart';
import '../models/attendance_model.dart';
import 'login_screen.dart';
import 'face_enrollment_screen.dart';
import 'class_detail_screen.dart';
import 'qr_scanner_screen.dart';
import 'qr_generator_screen.dart';
import 'teacher_scan_screen.dart';
import 'schedule_screen.dart';
import 'attendance_history_screen.dart';
import 'profile_screen.dart';
import 'report_screen.dart';

class HomeScreen extends StatefulWidget {
  final List<CameraDescription>? cameras;
  final User? currentUser;
  const HomeScreen({super.key, this.cameras, this.currentUser});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  CameraController? _cameraController;
  bool _loading = false;
  String _statusMessage = "Sẵn sàng điểm danh";
  double? _latitude;
  double? _longitude;
  User? _currentUser;
  final AuthService _authService = AuthService();

  // Data for home screen
  List<ClassModel> _upcomingClasses = [];
  List<AttendanceModel> _attendanceRecords = [];
  Map<String, int> _attendanceStats = {};
  double _attendanceRate = 0.0;
  bool _isLoadingData = true;
  bool _hasEnrolledFaces = false;

  @override
  void initState() {
    super.initState();
    // If currentUser is passed from constructor, use it
    if (widget.currentUser != null) {
      _currentUser = widget.currentUser;
    }
    _getCurrentLocation();
    _loadCurrentUser();
  }

  Future<void> _loadCurrentUser() async {
    try {
      // If currentUser is already set from constructor, don't override
      if (_currentUser != null) {
        _loadHomeData();
        return;
      }

      final user = await _authService.getCurrentUser();
      if (mounted) {
        setState(() {
          _currentUser = user;
        });
        // Only load home data after user is loaded
        _loadHomeData();
      }
    } catch (e) {
      print('Error loading current user: $e');
      // Set loading to false even if user loading fails
      if (mounted) {
        setState(() {
          _isLoadingData = false;
        });
      }
    }
  }

  Future<void> _loadHomeData() async {
    if (_currentUser == null) return;

    try {
      // Only show loading if data is empty (first time load)
      final isFirstLoad = _upcomingClasses.isEmpty && _attendanceRecords.isEmpty;
      if (isFirstLoad) {
        setState(() {
          _isLoadingData = true;
        });
      }

      // Load data in parallel
      final results = await Future.wait([
        ClassService.getUpcomingClasses(),
        ClassService.getAttendanceRecords(_currentUser!.id),
        ClassService.getAttendanceStats(_currentUser!.id),
        ClassService.getAttendanceRate(_currentUser!.id),
        FaceEnrollmentService.hasEnrolledFaces(_currentUser!.id),
      ]);

      if (mounted) {
        setState(() {
          _upcomingClasses = results[0] as List<ClassModel>;
          _attendanceRecords = results[1] as List<AttendanceModel>;
          _attendanceStats = results[2] as Map<String, int>;
          _attendanceRate = results[3] as double;
          _hasEnrolledFaces = results[4] as bool;
          _isLoadingData = false;
        });
      }
    } catch (e) {
      print('Error loading home data: $e');
      if (mounted) {
        setState(() {
          _isLoadingData = false;
        });
      }
    }
  }

  Future<void> _logout() async {
    try {
      await _authService.logout();
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi khi đăng xuất: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// 📍 Lấy vị trí GPS
  Future<void> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() => _statusMessage = "⚠️ Vui lòng bật GPS");
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() => _statusMessage = "❌ Chưa cấp quyền định vị");
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() => _statusMessage = "❌ Quyền GPS bị từ chối vĩnh viễn");
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _latitude = position.latitude;
        _longitude = position.longitude;
        _statusMessage = "✅ Sẵn sàng điểm danh";
      });

      print("📍 GPS Location: ${position.latitude}, ${position.longitude}");
    } catch (e) {
      print("❌ GPS Error: $e");
      setState(() => _statusMessage = "⚠️ Lỗi lấy vị trí GPS");
    }
  }

  /// 📷 Sự kiện bấm nút "Điểm danh ngay"
  Future<void> _onAttendancePressed() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      setState(() => _statusMessage = "⚠️ Camera chưa sẵn sàng");
      return;
    }

    setState(() {
      _loading = true;
      _statusMessage = "📸 Đang chụp & xử lý...";
    });

    try {
      final XFile file = await _cameraController!.takePicture();

      // 🧠 Giả lập gửi ảnh & xử lý
      await Future.delayed(const Duration(seconds: 2));

      // Create attendance record
      final attendance = AttendanceModel(
        id: 'att_${DateTime.now().millisecondsSinceEpoch}',
        classId: _upcomingClasses.isNotEmpty ? _upcomingClasses.first.id : 'demo_class',
        userId: _currentUser?.id ?? 'demo_user',
        checkInTime: DateTime.now(),
        photoPath: file.path,
        latitude: _latitude,
        longitude: _longitude,
        status: AttendanceStatus.present,
      );

      // Save attendance record
      await ClassService.saveAttendanceRecord(attendance);

      // Reload data
      await _loadHomeData();

      setState(() {
        _loading = false;
        _statusMessage = "✅ Điểm danh thành công!";
      });

      print("📷 Ảnh lưu tạm: ${file.path}");

      // Show success dialog
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('✅ Điểm danh thành công!'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Thời gian: ${DateTime.now().toString().substring(0, 19)}'),
                if (_latitude != null && _longitude != null) ...[
                  const SizedBox(height: 8),
                  Text('Vị trí: ${_latitude!.toStringAsFixed(6)}, ${_longitude!.toStringAsFixed(6)}'),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      setState(() {
        _loading = false;
        _statusMessage = "❌ Lỗi khi chụp ảnh: $e";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _currentUser?.role == 'instructor'
              ? "Trang giảng viên"
              : "FaceID Attendance",
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: _currentUser?.role == 'instructor'
            ? Colors.purple[700]
            : Colors.blue[700],
        foregroundColor: Colors.white,
        elevation: 2,
        centerTitle: true,
        actions: [
          if (_currentUser != null) ...[
            // Face Enrollment Button (only for students)
            if (_currentUser!.role != 'instructor')
              IconButton(
                icon: Icon(
                  _hasEnrolledFaces ? Icons.face : Icons.face_outlined,
                  color: Colors.white,
                ),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => FaceEnrollmentScreen(
                        user: _currentUser!,
                        cameras: widget.cameras,
                      ),
                    ),
                  );
                },
                tooltip: 'Đăng ký khuôn mặt',
              ),
            // Instructor Tools Button
            if (_currentUser!.role == 'instructor')
              IconButton(
                icon: const Icon(Icons.notifications, color: Colors.white),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Tính năng thông báo sắp ra mắt!')),
                  );
                },
                tooltip: 'Thông báo',
              ),
            // Profile Menu
            PopupMenuButton<String>(
              icon: CircleAvatar(
                backgroundColor: Colors.white,
                child: Text(
                  _currentUser!.fullName.isNotEmpty
                      ? _currentUser!.fullName[0].toUpperCase()
                      : 'U',
                  style: TextStyle(
                    color: _currentUser!.role == 'instructor'
                        ? Colors.purple[700]
                        : Colors.blue[700],
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              onSelected: (value) {
                if (value == 'logout') {
                  _logout();
                } else if (value == 'profile') {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Tính năng hồ sơ cá nhân sắp ra mắt!')),
                  );
                } else if (value == 'settings') {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Tính năng cài đặt sắp ra mắt!')),
                  );
                }
              },
              itemBuilder: (BuildContext context) => [
                PopupMenuItem<String>(
                  value: 'profile',
                  child: Row(
                    children: [
                      const Icon(Icons.person),
                      const SizedBox(width: 8),
                      Text(_currentUser!.fullName),
                    ],
                  ),
                ),
                if (_currentUser!.role == 'instructor') ...[
                  PopupMenuItem<String>(
                    value: 'settings',
                    child: Row(
                      children: [
                        const Icon(Icons.settings),
                        const SizedBox(width: 8),
                        Text('Cài đặt'),
                      ],
                    ),
                  ),
                ],
                const PopupMenuItem<String>(
                  value: 'logout',
                  child: Row(
                    children: [
                      Icon(Icons.logout, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Đăng xuất', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadHomeData,
        child: _isLoadingData
            ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Đang tải dữ liệu...'),
                  ],
                ),
              )
            : _currentUser?.role == 'instructor'
                ? _buildInstructorInterface()
                : _buildStudentInterface(),
      ),
    );
  }

  Widget _buildUserInfoSection() {
    final isInstructor = _currentUser?.role == 'instructor';

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: isInstructor ? Colors.purple[700] : Colors.blue[700],
              child: Text(
                _currentUser?.fullName.isNotEmpty == true
                    ? _currentUser!.fullName[0].toUpperCase()
                    : 'U',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _currentUser?.fullName ?? 'User',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    _currentUser?.email ?? 'user@example.com',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                  Row(
                    children: [
                      Text(
                        isInstructor ? 'Giảng viên: ' : 'MSSV: ',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        _currentUser?.username ?? 'N/A',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Column(
              children: [
                Icon(
                  isInstructor ? Icons.school : Icons.verified_user,
                  color: isInstructor ? Colors.purple[600] : Colors.green[600],
                  size: 28,
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isInstructor ? Colors.purple[100] : Colors.green[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    isInstructor ? 'Giảng viên' : 'Sinh viên',
                    style: TextStyle(
                      color: isInstructor ? Colors.purple[700] : Colors.green[700],
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttendanceStatusSection() {
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
                Icon(Icons.analytics, color: Colors.blue[700]),
                const SizedBox(width: 8),
                const Text(
                  'Trạng thái điểm danh',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Attendance Rate
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Tỷ lệ điểm danh',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                  Text(
                    '${_attendanceRate.toStringAsFixed(1)}%',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: _attendanceRate >= 80 ? Colors.green : Colors.orange,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Attendance Statistics
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Có mặt',
                    '${_attendanceStats['present'] ?? 0}',
                    Colors.green,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildStatCard(
                    'Đi muộn',
                    '${_attendanceStats['late'] ?? 0}',
                    Colors.orange,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildStatCard(
                    'Vắng mặt',
                    '${_attendanceStats['absent'] ?? 0}',
                    Colors.red,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildStatCard(
                    'Có phép',
                    '${_attendanceStats['excused'] ?? 0}',
                    Colors.blue,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUpcomingClassesSection() {
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
                Icon(Icons.event, color: Colors.blue[700]),
                const SizedBox(width: 8),
                const Text(
                  'Các buổi học sắp diễn ra',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            if (_upcomingClasses.isEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.grey[600]),
                    const SizedBox(width: 8),
                    Text(
                      'Không có buổi học sắp tới',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
              )
            else
              ..._upcomingClasses.take(3).map((cls) => _buildClassCard(cls)),
          ],
        ),
      ),
    );
  }

  Widget _buildClassCard(ClassModel cls) {
    return InkWell(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => ClassDetailScreen(
              classModel: cls,
              currentUser: _currentUser!,
              cameras: widget.cameras,
            ),
          ),
        );
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: cls.isAttendanceOpen
                ? Colors.green
                : Colors.grey[300]!,
            width: cls.isAttendanceOpen ? 2 : 1,
          ),
          boxShadow: cls.isAttendanceOpen
              ? [
                  BoxShadow(
                    color: Colors.green.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _getClassStatusColor(cls).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                cls.isAttendanceOpen ? Icons.how_to_reg : Icons.school,
                color: cls.isAttendanceOpen ? Colors.green : _getClassStatusColor(cls),
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    cls.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    cls.subject,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                  Row(
                    children: [
                      Icon(Icons.person, size: 14, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        cls.instructor,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Icon(Icons.location_on, size: 14, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        cls.room,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  if (cls.isAttendanceOpen) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.check_circle, size: 12, color: Colors.green),
                        const SizedBox(width: 4),
                        Text(
                          'Đang mở điểm danh',
                          style: TextStyle(
                            color: Colors.green,
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  cls.timeRange,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: cls.isAttendanceOpen
                        ? Colors.green.withOpacity(0.1)
                        : _getClassStatusColor(cls).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    cls.statusText,
                    style: TextStyle(
                      color: cls.isAttendanceOpen ? Colors.green : _getClassStatusColor(cls),
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 12,
                  color: Colors.grey[400],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getClassStatusColor(ClassModel cls) {
    if (cls.isAttendanceOpen) return Colors.green;
    if (cls.isOngoing) return Colors.blue;
    if (cls.isUpcoming && cls.isToday) return Colors.orange;
    if (cls.isUpcoming) return Colors.purple;
    return Colors.grey;
  }

  Widget _buildRecentAttendanceSection() {
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
                Icon(Icons.history, color: Colors.blue[700]),
                const SizedBox(width: 8),
                const Text(
                  'Lịch sử điểm danh gần đây',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            if (_attendanceRecords.isEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.grey[600]),
                    const SizedBox(width: 8),
                    Text(
                      'Chưa có lịch sử điểm danh',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
              )
            else
              ..._attendanceRecords.take(3).map((record) => _buildAttendanceCard(record)),
          ],
        ),
      ),
    );
  }

  Widget _buildAttendanceCard(AttendanceModel record) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: record.statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.check_circle,
              color: record.statusColor,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Điểm danh - ${record.checkInTime.day}/${record.checkInTime.month}/${record.checkInTime.year}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                Text(
                  'Giờ vào: ${record.formattedCheckInTime}',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
                if (record.formattedCheckOutTime != null)
                  Text(
                    'Giờ ra: ${record.formattedCheckOutTime}',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: record.statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              record.statusText,
              style: TextStyle(
                color: record.statusColor,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentInterface() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // User Info Section
          _buildUserInfoSection(),
          const SizedBox(height: 20),

          // Quick Actions for Students
          _buildStudentQuickActions(),
          const SizedBox(height: 20),

          // Attendance Status Section
          _buildAttendanceStatusSection(),
          const SizedBox(height: 20),

          // Upcoming Classes Section
          _buildUpcomingClassesSection(),
          const SizedBox(height: 20),

          // Recent Attendance Records
          _buildRecentAttendanceSection(),
          const SizedBox(height: 20),

          // Camera Section for Quick Check-in
          _buildCameraSection(),
        ],
      ),
    );
  }

  Widget _buildStudentQuickActions() {
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
                Icon(Icons.bolt, color: Colors.blue[700]),
                const SizedBox(width: 8),
                const Text(
                  'Thao tác nhanh',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: _buildActionButton(
                    'Quét QR',
                    Icons.qr_code_scanner,
                    Colors.blue,
                    () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => QRScannerScreen(
                            currentUser: _currentUser!,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildActionButton(
                    'Lịch học',
                    Icons.schedule,
                    Colors.green,
                    () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => ScheduleScreen(
                            currentUser: _currentUser!,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildActionButton(
                    'Lịch sử',
                    Icons.history,
                    Colors.orange,
                    () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => AttendanceHistoryScreen(
                            currentUser: _currentUser!,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildActionButton(
                    'Hồ sơ',
                    Icons.person,
                    Colors.purple,
                    () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => ProfileScreen(
                            currentUser: _currentUser!,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInstructorInterface() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // User Info Section
          _buildUserInfoSection(),
          const SizedBox(height: 20),

          // Instructor Dashboard Stats
          _buildInstructorDashboardSection(),
          const SizedBox(height: 20),

          // Instructor Classes Management
          _buildInstructorClassesSection(),
          const SizedBox(height: 20),

          // Recent Attendance Activity
          _buildInstructorAttendanceActivity(),
          const SizedBox(height: 20),

          // Quick Actions
          _buildInstructorQuickActions(),
        ],
      ),
    );
  }

  Widget _buildInstructorDashboardSection() {
    // Calculate real-time statistics
    final todayClasses = _upcomingClasses.where((cls) => cls.isToday).toList();
    final activeClasses = _upcomingClasses.where((cls) => cls.isAttendanceOpen).toList();
    final totalStudents = _upcomingClasses.fold<int>(0, (sum, cls) => sum + 10); // Assuming 10 students per class
    final presentToday = _attendanceRecords.where((record) {
      final today = DateTime.now();
      return record.checkInTime.day == today.day &&
             record.checkInTime.month == today.month &&
             record.checkInTime.year == today.year &&
             record.status == AttendanceStatus.present;
    }).length;

    final attendanceRateToday = totalStudents > 0 ? (presentToday / totalStudents * 100).round() : 0;

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
                Icon(Icons.dashboard, color: Colors.purple[700]),
                const SizedBox(width: 8),
                const Text(
                  'Tổng quan hôm nay',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.purple[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Cập nhật: ${DateTime.now().hour.toString().padLeft(2, '0')}:${DateTime.now().minute.toString().padLeft(2, '0')}',
                    style: TextStyle(
                      color: Colors.purple[700],
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Main Stats Grid
            Row(
              children: [
                Expanded(
                  child: _buildInstructorStatCard(
                    'Lớp học hôm nay',
                    '${todayClasses.length}',
                    Icons.class_,
                    Colors.blue,
                    subtitle: 'Đang diễn ra: ${todayClasses.where((cls) => cls.isOngoing).length}',
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildInstructorStatCard(
                    'Đang điểm danh',
                    '${activeClasses.length}',
                    Icons.how_to_reg,
                    Colors.green,
                    subtitle: activeClasses.isEmpty ? 'Chưa mở' : 'Mở điểm danh',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildInstructorStatCard(
                    'Tổng sinh viên',
                    '$totalStudents',
                    Icons.people,
                    Colors.orange,
                    subtitle: 'Đã điểm danh: $presentToday',
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildInstructorStatCard(
                    'Tỷ lệ điểm danh',
                    '$attendanceRateToday%',
                    Icons.bar_chart,
                    attendanceRateToday >= 80 ? Colors.green : attendanceRateToday >= 60 ? Colors.orange : Colors.red,
                    subtitle: 'Mục tiêu: 80%',
                  ),
                ),
              ],
            ),

            // Weekly Progress
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.trending_up, color: Colors.purple[600], size: 16),
                      const SizedBox(width: 8),
                      Text(
                        'Tiến độ tuần này',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.purple[700],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _buildDayIndicator('T2', true),
                      _buildDayIndicator('T3', true),
                      _buildDayIndicator('T4', false),
                      _buildDayIndicator('T5', true),
                      _buildDayIndicator('T6', false),
                      _buildDayIndicator('T7', false),
                      _buildDayIndicator('CN', false),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInstructorStatCard(String label, String value, IconData icon, Color color, {String? subtitle}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color.withOpacity(0.8),
            ),
            textAlign: TextAlign.center,
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 10,
                color: color.withOpacity(0.6),
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDayIndicator(String day, bool isActive) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 2),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? Colors.purple[500] : Colors.grey[300],
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          day,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isActive ? Colors.white : Colors.grey[600],
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildInstructorClassesSection() {
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
                Icon(Icons.class_, color: Colors.purple[700]),
                const SizedBox(width: 8),
                const Text(
                  'Quản lý lớp học',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: () {
                    // TODO: Navigate to add class screen
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Tính năng tạo lớp học sắp ra mắt!')),
                    );
                  },
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Tạo lớp'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple[700],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            if (_upcomingClasses.isEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.grey[600]),
                    const SizedBox(width: 8),
                    Text(
                      'Chưa có lớp học nào',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
              )
            else
              ..._upcomingClasses.take(5).map((cls) => _buildInstructorClassCard(cls)),
          ],
        ),
      ),
    );
  }

  Widget _buildInstructorClassCard(ClassModel cls) {
    return InkWell(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => ClassDetailScreen(
              classModel: cls,
              currentUser: _currentUser!,
              cameras: widget.cameras,
            ),
          ),
        );
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: cls.isAttendanceOpen
                ? Colors.green
                : Colors.grey[300]!,
            width: cls.isAttendanceOpen ? 2 : 1,
          ),
          boxShadow: cls.isAttendanceOpen
              ? [
                  BoxShadow(
                    color: Colors.green.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _getClassStatusColor(cls).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                cls.isAttendanceOpen ? Icons.how_to_reg : Icons.school,
                color: cls.isAttendanceOpen ? Colors.green : _getClassStatusColor(cls),
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    cls.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    cls.subject,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                  Row(
                    children: [
                      Icon(Icons.location_on, size: 14, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        cls.room,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Icon(Icons.schedule, size: 14, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        cls.timeRange,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  if (cls.isAttendanceOpen) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.check_circle, size: 12, color: Colors.green),
                        const SizedBox(width: 4),
                        Text(
                          'Đang mở điểm danh',
                          style: TextStyle(
                            color: Colors.green,
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: cls.isAttendanceOpen
                        ? Colors.green.withOpacity(0.1)
                        : _getClassStatusColor(cls).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    cls.statusText,
                    style: TextStyle(
                      color: cls.isAttendanceOpen ? Colors.green : _getClassStatusColor(cls),
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 12,
                  color: Colors.grey[400],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInstructorAttendanceActivity() {
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
                Icon(Icons.history, color: Colors.purple[700]),
                const SizedBox(width: 8),
                const Text(
                  'Hoạt động điểm danh gần đây',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            if (_attendanceRecords.isEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.grey[600]),
                    const SizedBox(width: 8),
                    Text(
                      'Chưa có hoạt động điểm danh nào',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
              )
            else
              ..._attendanceRecords.take(3).map((record) => _buildInstructorAttendanceCard(record)),
          ],
        ),
      ),
    );
  }

  Widget _buildInstructorAttendanceCard(AttendanceModel record) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: record.statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.person_outline,
              color: record.statusColor,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Sinh viên đã điểm danh',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                Text(
                  'Thời gian: ${record.formattedCheckInTime}',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
                Text(
                  'Lớp: ${record.classId}',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: record.statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              record.statusText,
              style: TextStyle(
                color: record.statusColor,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstructorQuickActions() {
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
                Icon(Icons.bolt, color: Colors.purple[700]),
                const SizedBox(width: 8),
                const Text(
                  'Thao tác nhanh',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: _buildActionButton(
                    'Tạo QR',
                    Icons.qr_code,
                    Colors.blue,
                    () {
                      if (_upcomingClasses.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Không có lớp học nào!')),
                        );
                        return;
                      }

                      // Find first ongoing class
                      final ongoingClass = _upcomingClasses.firstWhere(
                        (cls) => cls.isOngoing,
                        orElse: () => _upcomingClasses.first,
                      );

                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => QRGeneratorScreen(
                            classModel: ongoingClass,
                            currentUser: _currentUser!,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildActionButton(
                    'Báo cáo',
                    Icons.assessment,
                    Colors.green,
                    () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => ReportScreen(
                            currentUser: _currentUser!,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildActionButton(
                    'Danh sách SV',
                    Icons.people,
                    Colors.orange,
                    () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Tính năng quản lý sinh viên sắp ra mắt!')),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildActionButton(
                    'Cài đặt',
                    Icons.settings,
                    Colors.purple,
                    () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Tính năng cài đặt sắp ra mắt!')),
                      );
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(String label, IconData icon, Color color, VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color.withOpacity(0.1),
        foregroundColor: color,
        elevation: 0,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: color.withOpacity(0.3)),
        ),
      ),
      child: Column(
        children: [
          Icon(icon, size: 24),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCameraSection() {
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
                Icon(Icons.camera_alt, color: Colors.blue[700]),
                const SizedBox(width: 8),
                const Text(
                  'Điểm danh nhanh',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Camera View
            Container(
              height: 200,
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(12),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: CameraView(
                  cameras: widget.cameras,
                  onControllerReady: (controller) {
                    _cameraController = controller;
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Status and Location
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _statusMessage.contains('✅')
                    ? Colors.green[50]
                    : _statusMessage.contains('❌')
                        ? Colors.red[50]
                        : Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _statusMessage.contains('✅')
                      ? Colors.green
                      : _statusMessage.contains('❌')
                          ? Colors.red
                          : Colors.blue,
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _statusMessage.contains('✅')
                        ? Icons.check_circle
                        : _statusMessage.contains('❌')
                            ? Icons.error
                            : Icons.info,
                    color: _statusMessage.contains('✅')
                        ? Colors.green
                        : _statusMessage.contains('❌')
                            ? Colors.red
                            : Colors.blue,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _statusMessage,
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        color: _statusMessage.contains('✅')
                            ? Colors.green[700]
                            : _statusMessage.contains('❌')
                                ? Colors.red[700]
                                : Colors.blue[700],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Location info
            if (_latitude != null && _longitude != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.location_on, color: Colors.red[600]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Vị trí: ${_latitude!.toStringAsFixed(6)}, ${_longitude!.toStringAsFixed(6)}',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 16),

            // Check-in Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _loading ? null : _onAttendancePressed,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[700],
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
                child: _loading
                    ? const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          ),
                          SizedBox(width: 12),
                          Text('Đang xử lý...'),
                        ],
                      )
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.camera_alt),
                          SizedBox(width: 8),
                          Text(
                            'Điểm danh ngay',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}