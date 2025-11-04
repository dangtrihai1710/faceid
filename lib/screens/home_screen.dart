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

class HomeScreen extends StatefulWidget {
  final List<CameraDescription>? cameras;
  const HomeScreen({super.key, this.cameras});

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
    _getCurrentLocation();
    _loadCurrentUser();
  }

  Future<void> _loadCurrentUser() async {
    try {
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
        title: const Text(
          "FaceID Attendance",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
        elevation: 2,
        centerTitle: true,
        actions: [
          if (_currentUser != null) ...[
            // Face Enrollment Button
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
            // Profile Menu
            PopupMenuButton<String>(
              icon: CircleAvatar(
                backgroundColor: Colors.white,
                child: Text(
                  _currentUser!.fullName.isNotEmpty
                      ? _currentUser!.fullName[0].toUpperCase()
                      : 'U',
                  style: TextStyle(
                    color: Colors.blue[700],
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              onSelected: (value) {
                if (value == 'logout') {
                  _logout();
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
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // User Info Section
                    _buildUserInfoSection(),
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
              ),
      ),
    );
  }

  Widget _buildUserInfoSection() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: Colors.blue[700],
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
                  Text(
                    'MSSV: ${_currentUser?.username ?? 'N/A'}',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.verified_user,
              color: Colors.green[600],
              size: 28,
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