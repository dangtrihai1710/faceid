import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/primary_button.dart';
import '../../screens/attendance/attendance_scan_screen.dart';
import '../../screens/attendance/face_attendance_screen.dart';
import '../../screens/attendance/face_registration_screen.dart';
import '../../screens/attendance/face_initial_upload_screen.dart';
import '../../core/models/user_models.dart' as user_models;
import '../../core/models/class_models.dart';
import '../../core/services/attendance_face_service.dart';
// import '../../core/services/test_data_service.dart'; // Using real API instead
import '../../core/services/api_service.dart';

class StudentHomeScreen extends StatefulWidget {
  const StudentHomeScreen({super.key});

  @override
  State<StudentHomeScreen> createState() => _StudentHomeScreenState();
}

class _StudentHomeScreenState extends State<StudentHomeScreen> {
  user_models.User? _currentUser;
  List<Class> _todayClasses = [];
  user_models.AttendanceStats _stats = user_models.AttendanceStats(
    totalClasses: 0,
    attendedClasses: 0,
    missedClasses: 0,
    lateClasses: 0,
    attendanceRate: 0.0,
  );
  int _selectedIndex = 0;
  final AttendanceFaceService _attendanceService = AttendanceFaceService();

  // Face registration status
  bool _isFaceRegistered = false;
  Map<String, dynamic>? _faceRegistrationStatus;
  bool _isLoadingFaceStatus = false;

  // Real classes data from API
  List<Class> _apiClasses = [];
  bool _isLoadingClasses = false;

  // Convert API data to Class object
  Class _convertApiDataToClass(Map<String, dynamic> apiData) {

    return Class(
      id: apiData['_id']?.toString() ?? apiData['id']?.toString() ?? '',
      name: apiData['name']?.toString() ?? '',
      code: apiData['subject_code']?.toString() ?? apiData['code']?.toString() ?? '',
      description: apiData['description']?.toString(),
      instructorId: apiData['instructor_id']?.toString() ?? '',
      instructorName: apiData['instructor_name']?.toString() ?? '',
      enrolledStudents: List<String>.from(apiData['student_ids'] ?? []),
      maxStudents: (apiData['max_students'] as num?)?.toInt() ?? 50,
      isActive: apiData['status']?.toString() != 'inactive',
      startDate: DateTime.now().subtract(const Duration(days: 30)),
      endDate: DateTime.now().add(const Duration(days: 90)),
      createdAt: apiData['created_at'] != null
          ? DateTime.parse(apiData['created_at'])
          : DateTime.now(),
      updatedAt: apiData['updated_at'] != null
          ? DateTime.parse(apiData['updated_at'])
          : DateTime.now(),
    );
  }

  // Load classes from real API
  Future<void> _loadClassesFromApi() async {
    if (_currentUser == null) return;

    setState(() {
      _isLoadingClasses = true;
    });

    try {
      debugPrint('🔄 Loading classes from API for user: ${_currentUser!.id}');
      final classesData = await ApiService.getStudentClasses();

      final classes = classesData.map((data) => _convertApiDataToClass(data)).toList();

      if (mounted) {
        setState(() {
          _apiClasses = classes;
          _todayClasses = classes; // Update _todayClasses with real data
          _isLoadingClasses = false;
        });
        debugPrint('✅ Loaded ${classes.length} classes from API');
        for (var cls in classes) {
          debugPrint('   - ${cls.name} (${cls.code}) - Giảng viên: ${cls.instructorName}');
        }
      }
    } catch (e) {
      debugPrint('❌ Error loading classes from API: $e');
      if (mounted) {
        setState(() {
          _isLoadingClasses = false;
        });
        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi tải dữ liệu lớp học: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      // Check if user has authentication token
      if (ApiService.hasToken()) {
        // Try to get user data from API first for fresh data
        final userData = await ApiService.getCurrentUser();

        if (userData != null && userData['data'] != null) {
          final userInfo = userData['data'];
          _currentUser = user_models.User(
            id: userInfo['userId'] ?? 'Unknown',
            userCode: userInfo['userId'] ?? 'Unknown',
            fullName: userInfo['fullName'] ?? 'Unknown User',
            email: userInfo['email'] ?? 'unknown@email.com',
            role: userInfo['role'] ?? 'student',
            department: 'Công nghệ thông tin', // Backend doesn't provide department yet
            createdAt: DateTime.now().subtract(const Duration(days: 365)),
            updatedAt: DateTime.now(),
          );

          debugPrint('✅ User data loaded from API: ${_currentUser!.fullName}');
        } else {
          // Fallback user if API fails
          debugPrint('⚠️ API failed, using fallback user');
          _currentUser = user_models.User(
            id: 'SV001',
            userCode: 'SV001',
            fullName: 'Sinh viên',
            email: 'student@university.edu.vn',
            role: 'student',
            department: 'Công nghệ thông tin',
            createdAt: DateTime.now().subtract(const Duration(days: 365)),
            updatedAt: DateTime.now(),
          );
        }
      } else {
        // No token available
        debugPrint('⚠️ No authentication token found');
        _currentUser = user_models.User(
          id: 'SV001',
          userCode: 'SV001',
          fullName: 'Sinh viên',
          email: 'student@university.edu.vn',
          role: 'student',
          department: 'Công nghệ thông tin',
          createdAt: DateTime.now().subtract(const Duration(days: 365)),
          updatedAt: DateTime.now(),
        );
      }

      // Get student classes using real API
      if (_currentUser != null) {
        await _loadClassesFromApi();

        // Mock stats for now - will implement real stats later
        _stats = user_models.AttendanceStats(
          totalClasses: _todayClasses.length,
          attendedClasses: _todayClasses.isNotEmpty ? (_todayClasses.length * 8 ~/ 10) : 0, // Mock 80% attendance
          missedClasses: _todayClasses.isNotEmpty ? (_todayClasses.length * 1 ~/ 10) : 0,
          lateClasses: _todayClasses.isNotEmpty ? (_todayClasses.length * 1 ~/ 10) : 0,
          attendanceRate: _todayClasses.isNotEmpty ? 0.89 : 0.0,
        );

        // Check face registration status
        debugPrint('🔍 Current user before Face ID check: ${_currentUser?.id} - ${_currentUser?.fullName}');
        await _checkFaceRegistrationStatus();
      }
    } catch (e) {
      debugPrint('❌ Error loading user data: $e');
      // Fallback user on any error
      _currentUser = user_models.User(
        id: 'SV001',
        userCode: 'SV001',
        fullName: 'Sinh viên',
        email: 'student@university.edu.vn',
        role: 'student',
        department: 'Công nghệ thông tin',
        createdAt: DateTime.now().subtract(const Duration(days: 365)),
        updatedAt: DateTime.now(),
      );
      // Try to load classes even for fallback user
      await _loadClassesFromApi();
    }

    // Set state to trigger UI update
    if (mounted) {
      setState(() {});
    }
  }

  Class? get _currentClass {
    final now = DateTime.now();
    final currentMinutes = now.hour * 60 + now.minute;

    for (var classItem in _todayClasses) {
      // Simple time check - in real app would parse schedule better
      if (classItem.name.contains('7:00') && currentMinutes >= 420 && currentMinutes <= 540) {
        return classItem;
      } else if (classItem.name.contains('14:00') && currentMinutes >= 840 && currentMinutes <= 960) {
        return classItem;
      }
    }
    return null;
  }

  void _onBottomNavTap(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _navigateToFaceAttendance(Class classItem) async {
    try {
      // Create attendance session
      final session = _attendanceService.createTestSession(classItem.id);

      // Navigate to Face ID attendance screen
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => FaceAttendanceScreen(
            session: session,
            onAttendanceSuccess: (record) {
              _showAttendanceSuccessDialog(record);
            },
          ),
        ),
      );

      // Refresh stats after returning
      _loadUserData();
    } catch (e) {
      _showErrorDialog('Lỗi khi mở màn hình điểm danh Face ID: $e');
    }
  }

  void _navigateToQRAttendance(Class classItem) async {
    try {
      // Create attendance session
      final session = _attendanceService.createTestSession(classItem.id);

      // Navigate to QR scan screen
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AttendanceScanScreen(
            session: session,
            onAttendanceSuccess: (record) {
              _showAttendanceSuccessDialog(record);
            },
          ),
        ),
      );

      // Refresh stats after returning
      _loadUserData();
    } catch (e) {
      _showErrorDialog('Lỗi khi mở màn hình điểm danh QR: $e');
    }
  }

  void _navigateToFaceRegistration(Class classItem) async {
    if (_currentUser == null) {
      _showErrorDialog('Chưa tải được thông tin người dùng');
      return;
    }

    try {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => FaceRegistrationScreen(
            currentUser: _currentUser!,
            classId: classItem.id,
            onRegistrationComplete: () {
              _showAttendanceSuccessDialog(AttendanceRecord(
                id: 'face_registration_${DateTime.now().millisecondsSinceEpoch}',
                studentId: _currentUser!.id,
                studentName: _currentUser!.fullName,
                classId: classItem.id,
                className: classItem.name,
                sessionId: 'registration_${DateTime.now().millisecondsSinceEpoch}',
                checkInTime: DateTime.now(),
                status: 'registered',
                method: 'face_registration',
                confidence: 1.0,
              ));
              _loadUserData(); // Refresh data
            },
          ),
        ),
      );
    } catch (e) {
      _showErrorDialog('Lỗi khi mở màn hình đăng ký Face ID: $e');
    }
  }

  void _navigateToInitialFaceUpload(Class classItem) async {
    if (_currentUser == null) {
      _showErrorDialog('Chưa tải được thông tin người dùng');
      return;
    }

    try {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => FaceInitialUploadScreen(
            currentUser: _currentUser!,
            classId: classItem.id,
            onUploadComplete: () {
              _showAttendanceSuccessDialog(AttendanceRecord(
                id: 'face_initial_upload_${DateTime.now().millisecondsSinceEpoch}',
                studentId: _currentUser!.id,
                studentName: _currentUser!.fullName,
                classId: classItem.id,
                className: classItem.name,
                sessionId: 'initial_upload_${DateTime.now().millisecondsSinceEpoch}',
                checkInTime: DateTime.now(),
                status: 'face_id_registered',
                method: 'face_initial_upload',
                confidence: 1.0,
              ));
              _loadUserData(); // Refresh data
            },
          ),
        ),
      );
    } catch (e) {
      _showErrorDialog('Lỗi khi mở màn hình đăng ký Face ID lần đầu: $e');
    }
  }

  void _showAttendanceSuccessDialog(AttendanceRecord record) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.check_circle, color: AppColors.success, size: 28),
            const SizedBox(width: 12),
            const Text('Điểm danh thành công!'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Họ và tên: ${record.studentName}'),
            Text('Lớp: ${record.className}'),
            Text('Thời gian: ${record.checkInTime.hour.toString().padLeft(2, '0')}:${record.checkInTime.minute.toString().padLeft(2, '0')}'),
            Text('Trạng thái: ${_getStatusText(record.status)}'),
            if (record.confidence != null)
              Text('Độ chính xác: ${(record.confidence! * 100).toStringAsFixed(1)}%'),
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

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Lỗi'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'on_time':
        return 'Đúng giờ';
      case 'late':
        return 'Muộn';
      case 'absent':
        return 'Vắng mặt';
      default:
        return status;
    }
  }

  // Check face registration status
  Future<void> _checkFaceRegistrationStatus() async {
    if (_currentUser == null) return;

    try {
      setState(() {
        _isLoadingFaceStatus = true;
      });

      final statusData = await ApiService.getFaceRegistrationStatus(_currentUser!.id);

      // Debug full API response
      debugPrint('🔍 Face ID API Response for user: ${_currentUser!.id}');
      debugPrint('   Full response: $statusData');

      if (statusData != null) {
        // Handle multiple possible response formats
        bool isRegistered = false;

        // Standard format with 'success' field
        if (statusData['success'] == true) {
          isRegistered = statusData['is_registered'] == true;
        }
        // Alternative format - check if user has encodings and status is active
        else if (statusData['num_encodings'] != null &&
                 statusData['status'] == 'active' &&
                 (statusData['num_encodings'] as int) > 0) {
          isRegistered = true;
          debugPrint('✅ Using alternative format - detected active face registration');
        }
        // Another format - direct check of required fields
        else if (statusData['encodings'] != null &&
                 statusData['encodings'].length > 0) {
          isRegistered = true;
          debugPrint('✅ Using encodings format - detected face registration');
        }

        setState(() {
          _isFaceRegistered = isRegistered;
          _faceRegistrationStatus = statusData;
        });

        debugPrint('✅ Face registration status: $_isFaceRegistered');
        debugPrint('   - is_registered determined: $isRegistered');
        debugPrint('   - success field: ${statusData['success']}');
        debugPrint('   - num_encodings: ${statusData['num_encodings']}');
        debugPrint('   - avg_quality: ${statusData['avg_quality']}');
        debugPrint('   - status: ${statusData['status']}');
        debugPrint('   - encodings length: ${statusData['encodings']?.length}');

        if (_isFaceRegistered) {
          debugPrint('   - Registered images: ${_faceRegistrationStatus!['num_encodings'] ?? statusData['encodings']?.length}');
          debugPrint('   - Average quality: ${_faceRegistrationStatus!['avg_quality']}');
        }
      } else {
        setState(() {
          _isFaceRegistered = false;
          _faceRegistrationStatus = null;
        });
        debugPrint('❌ Failed to get face registration status');
        debugPrint('   - statusData is null: ${statusData == null}');
        if (statusData != null) {
          debugPrint('   - success field: ${statusData['success']}');
          debugPrint('   - is_registered field: ${statusData['is_registered']}');
        }
      }
    } catch (e) {
      debugPrint('❌ Error checking face registration status: $e');
      setState(() {
        _isFaceRegistered = false;
        _faceRegistrationStatus = null;
      });
    } finally {
      setState(() {
        _isLoadingFaceStatus = false;
      });
    }
  }

  // Show face registration options dialog
  void _showFaceRegistrationOptions() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Quản lý Face ID'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Trạng thái: Đã đăng ký ${_faceRegistrationStatus!['num_encodings']} ảnh',
                style: AppTextStyles.bodySmall,
              ),
              const SizedBox(height: 8),
              Text(
                'Chất lượng: ${(_faceRegistrationStatus!['avg_quality'] * 100).toStringAsFixed(1)}%',
                style: AppTextStyles.bodySmall,
              ),
              const SizedBox(height: 16),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Đóng'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: IndexedStack(
          index: _selectedIndex,
          children: [
            _buildHomeTab(),
            _buildClassesTab(),
            _buildProfileTab(),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onBottomNavTap,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Trang chủ',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.class_),
            label: 'Lớp học',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Cá nhân',
          ),
        ],
      ),
    );
  }

  Widget _buildHomeTab() {
    final currentClass = _currentClass;

    // Show loading if user data not loaded yet
    if (_currentUser == null) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Welcome Section - Material 3 Improved
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primary, AppColors.primary.withValues(alpha: 0.8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(20),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Row(
                  children: [
                    // Avatar
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.3),
                          width: 2,
                        ),
                      ),
                      child: const Icon(
                        Icons.person,
                        size: 28,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 16),

                    // Text content
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Chào buổi sáng,',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: Colors.white.withValues(alpha: 0.9),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _currentUser!.fullName,
                            style: AppTextStyles.heading2.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 22,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              _currentUser!.userCode,
                              style: AppTextStyles.bodySmall.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Notification bell
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.notifications_outlined,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Current Class Section
          if (currentClass != null) ...[
            _buildCurrentClassCard(currentClass),
            const SizedBox(height: 20),
          ],

          // Quick Actions
          _buildQuickActions(),
          const SizedBox(height: 20),

          // Statistics
          _buildStatsGrid(),
          const SizedBox(height: 20),

          // Today's Schedule
          _buildTodaySchedule(),
        ],
      ),
    );
  }

  Widget _buildCurrentClassCard(Class classItem) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.class_, color: Colors.orange, size: 24),
              const SizedBox(width: 12),
              Text(
                'Đang học',
                style: AppTextStyles.heading4.copyWith(
                  color: Colors.orange,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            classItem.name,
            style: AppTextStyles.heading3.copyWith(
              color: Colors.orange,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${classItem.name} • Giảng viên: ${classItem.instructorName}',
            style: AppTextStyles.bodyMedium.copyWith(
              color: Colors.orange.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _navigateToFaceAttendance(classItem),
                  icon: const Icon(Icons.face),
                  label: const Text('Điểm danh Face ID'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _navigateToFaceRegistration(classItem),
                  icon: const Icon(Icons.camera_enhance),
                  label: const Text('Đăng ký Face ID'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
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
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.how_to_reg,
                color: AppColors.primary,
                size: 20,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Điểm danh',
              style: AppTextStyles.heading4.copyWith(
                color: AppColors.onBackground,
                fontWeight: FontWeight.w700,
                fontSize: 18,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Main attendance button
        Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 20),
          child: Material(
            elevation: 6,
            borderRadius: BorderRadius.circular(20),
            shadowColor: AppColors.primary.withValues(alpha: 0.4),
            child: InkWell(
              onTap: () {
                final currentClass = _getCurrentClass();
                if (currentClass != null) {
                  _showAttendanceMethodsDialog();
                } else if (_todayClasses.isNotEmpty) {
                  _showWaitingDialog();
                } else {
                  _showErrorDialog('Không có lớp học để điểm danh hôm nay');
                }
              },
              borderRadius: BorderRadius.circular(20),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primary,
                      AppColors.primaryVariant,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 32),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Animated icon
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        Icons.touch_app,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),

                    // Text content
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'ĐIỂM DANH NGAY',
                            style: AppTextStyles.heading3.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _todayClasses.isNotEmpty
                                ? 'Có ${_todayClasses.length} lớp đang diễn ra'
                                : 'Không có lịch học hôm nay',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: Colors.white.withValues(alpha: 0.9),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Arrow
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.arrow_forward,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),

        // Quick actions below - 2x2 grid
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.2, // Adjust for equal height cards
          children: [
            // Lịch sử điểm danh
            _buildQuickActionCard(
              icon: Icons.history,
              label: 'Lịch sử điểm danh',
              color: AppColors.info,
              backgroundColor: AppColors.info.withValues(alpha: 0.1),
              onTap: () {
                _showErrorDialog('Tính năng đang phát triển');
              },
            ),
            // Lịch học
            _buildQuickActionCard(
              icon: Icons.calendar_month,
              label: 'Lịch học',
              color: AppColors.secondary,
              backgroundColor: AppColors.secondary.withValues(alpha: 0.1),
              onTap: () {
                _showErrorDialog('Tính năng đang phát triển');
              },
            ),
            // Thêm 2 ô trống để làm grid 2x2
            _buildQuickActionCard(
              icon: Icons.analytics,
              label: 'Thống kê',
              color: AppColors.success,
              backgroundColor: AppColors.success.withValues(alpha: 0.1),
              onTap: () {
                _showErrorDialog('Tính năng đang phát triển');
              },
            ),
            _buildQuickActionCard(
              icon: Icons.notifications,
              label: 'Thông báo',
              color: AppColors.warning,
              backgroundColor: AppColors.warning.withValues(alpha: 0.1),
              onTap: () {
                _showErrorDialog('Tính năng đang phát triển');
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickActionCard({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? color,
    Color? backgroundColor,
  }) {
    final cardColor = color ?? AppColors.primary;
    final bgColor = backgroundColor ?? AppColors.primary.withValues(alpha: 0.1);

    return Material(
      elevation: 2,
      borderRadius: BorderRadius.circular(16),
      shadowColor: cardColor.withValues(alpha: 0.2),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: cardColor.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: cardColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  size: 28,
                  color: cardColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: cardColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsGrid() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        Row(
          children: [
            Icon(
              Icons.analytics_outlined,
              color: AppColors.primary,
              size: 24,
            ),
            const SizedBox(width: 8),
            Text(
              'Thống kê điểm danh',
              style: AppTextStyles.heading4.copyWith(
                color: AppColors.onBackground,
                fontWeight: FontWeight.w700,
                fontSize: 18,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Main progress card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Tỷ lệ điểm danh',
                    style: AppTextStyles.heading4.copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    '${(_stats.attendanceRate * 100).toStringAsFixed(1)}%',
                    style: AppTextStyles.heading3.copyWith(
                      fontWeight: FontWeight.w700,
                      color: _getAttendanceColor(_stats.attendanceRate),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Progress bar
              Container(
                height: 12,
                decoration: BoxDecoration(
                  color: AppColors.surface.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: _stats.attendanceRate.clamp(0.0, 1.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: _getAttendanceColor(_stats.attendanceRate),
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              Text(
                _getAttendanceMessage(_stats.attendanceRate),
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.onSurface.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Mini stats grid
        Row(
          children: [
            Expanded(
              child: _buildMiniStatCard(
                title: 'Đúng giờ',
                value: '${_stats.attendedClasses}',
                icon: Icons.check_circle,
                color: AppColors.success,
                backgroundColor: AppColors.success.withValues(alpha: 0.1),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMiniStatCard(
                title: 'Đi muộn',
                value: '${_stats.lateClasses}',
                icon: Icons.schedule,
                color: AppColors.warning,
                backgroundColor: AppColors.warning.withValues(alpha: 0.1),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMiniStatCard(
                title: 'Vắng mặt',
                value: '${_stats.missedClasses}',
                icon: Icons.cancel,
                color: AppColors.error,
                backgroundColor: AppColors.error.withValues(alpha: 0.1),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMiniStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required Color backgroundColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              size: 20,
              color: color,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: AppTextStyles.heading3.copyWith(
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          Text(
            title,
            style: AppTextStyles.bodySmall.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Color _getAttendanceColor(double rate) {
    if (rate >= 0.95) return AppColors.success;
    if (rate >= 0.85) return AppColors.primary;
    if (rate >= 0.75) return AppColors.warning;
    return AppColors.error;
  }

  String _getAttendanceMessage(double rate) {
    if (rate >= 0.95) return 'Xuất sắc! Tiếp tục phát huy';
    if (rate >= 0.85) return 'Tốt! Cố gắng giữ vững';
    if (rate >= 0.75) return 'Khá! Cần cải thiện hơn';
    return 'Cần nỗ lực nhiều hơn';
  }

  Widget _buildTodaySchedule() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        Row(
          children: [
            Icon(
              Icons.calendar_today_outlined,
              color: AppColors.primary,
              size: 24,
            ),
            const SizedBox(width: 8),
            Text(
              'Lịch học hôm nay',
              style: AppTextStyles.heading4.copyWith(
                color: AppColors.onBackground,
                fontWeight: FontWeight.w700,
                fontSize: 18,
              ),
            ),
            const Spacer(),
            if (_todayClasses.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${_todayClasses.length} lớp',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),

        if (_todayClasses.isEmpty)
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.onSurface.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.event_available,
                    size: 32,
                    color: AppColors.onSurface.withValues(alpha: 0.5),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Không có lịch học hôm nay',
                  style: AppTextStyles.heading4.copyWith(
                    color: AppColors.onSurface.withValues(alpha: 0.7),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Thư giãn và chuẩn bị cho ngày mai nhé!',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.onSurface.withValues(alpha: 0.5),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          )
        else
          ..._todayClasses.map((classItem) => Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: _buildClassCard(classItem),
          )),
      ],
    );
  }

  Widget _buildClassCard(Class classItem) {
    return InkWell(
      onTap: () => _showClassOptionsDialog(classItem),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.onSurface.withValues(alpha: 0.1)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.class_, color: AppColors.primary, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    classItem.name,
                    style: AppTextStyles.heading4.copyWith(
                      color: AppColors.onBackground,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${classItem.name} • Giảng viên: ${classItem.instructorName}',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.onSurface.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  'Giảng viên: ${classItem.instructorName}',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.onSurface.withValues(alpha: 0.6),
                  ),
                ),
                const Spacer(),
                Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClassesTab() {
    if (_currentUser == null) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    // Show loading while fetching classes from API
    if (_isLoadingClasses) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text(
              'Đang tải danh sách lớp học...',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    // Use the already loaded classes from API
    final studentClasses = _apiClasses;

    return RefreshIndicator(
      onRefresh: _loadClassesFromApi,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Lớp học của bạn',
                  style: AppTextStyles.heading3.copyWith(
                    color: AppColors.onBackground,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${studentClasses.length} lớp',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          if (studentClasses.isEmpty)
            Center(
              child: Column(
                children: [
                  Icon(
                    Icons.class_,
                    size: 64,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Chưa đăng ký lớp học nào',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            )
          else
            ...studentClasses.map((classItem) => Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _buildClassCard(classItem),
            )),
        ],
      ),
    ),
    );
  }

  Widget _buildProfileTab() {
    if (_currentUser == null) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Profile Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.person,
                    size: 50,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  _currentUser!.fullName,
                  style: AppTextStyles.heading3.copyWith(
                    color: AppColors.onBackground,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _currentUser!.userCode,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.onSurface.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _currentUser!.email,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.onSurface.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _currentUser!.department ?? 'Công nghệ thông tin',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.onSurface.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Profile Information
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.person,
                        color: AppColors.primary,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        'Thông tin cá nhân',
                        style: AppTextStyles.heading4,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildInfoRow('Họ và tên', _currentUser!.fullName),
                _buildInfoRow('Mã sinh viên', _currentUser!.userCode),
                _buildInfoRow('Email', _currentUser!.email),
                _buildInfoRow('Khoa', _currentUser!.department ?? 'Công nghệ thông tin'),
                _buildInfoRow('Vai trò', _currentUser!.role),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Settings
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.settings,
                        color: AppColors.primary,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        'Cài đặt',
                        style: AppTextStyles.heading4,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: Icon(Icons.notifications, color: AppColors.primary),
                  title: Text('Thông báo'),
                  trailing: Icon(Icons.chevron_right),
                  onTap: () => _showErrorDialog('Tính năng đang phát triển'),
                ),
                ListTile(
                  leading: Icon(Icons.security, color: AppColors.primary),
                  title: Text('Bảo mật'),
                  trailing: Icon(Icons.chevron_right),
                  onTap: () => _showErrorDialog('Tính năng đang phát triển'),
                ),
                ListTile(
                  leading: Icon(Icons.help, color: AppColors.primary),
                  title: Text('Trợ giúp'),
                  trailing: Icon(Icons.chevron_right),
                  onTap: () => _showErrorDialog('Tính năng đang phát triển'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Face ID Management
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.face,
                        color: AppColors.primary,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        'Quản lý Face ID',
                        style: AppTextStyles.heading4,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Face Registration Status Display
                if (_isLoadingFaceStatus)
                  Container(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(strokeWidth: 2),
                        const SizedBox(width: 12),
                        Text(
                          'Đang kiểm tra trạng thái Face ID...',
                          style: AppTextStyles.bodySmall,
                        ),
                      ],
                    ),
                  )
                else if (_isFaceRegistered)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Icon(Icons.verified, color: Colors.green, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '✅ Đã đăng ký Face ID thành công',
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: Colors.green,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Đã đăng ký ${_faceRegistrationStatus!['num_encodings']} ảnh khuôn mặt',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                        Text(
                          'Chất lượng trung bình: ${(_faceRegistrationStatus!['avg_quality'] * 100).toStringAsFixed(1)}%',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                        if (_todayClasses.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          OutlinedButton.icon(
                            onPressed: () => _showFaceRegistrationOptions(),
                            icon: const Icon(Icons.settings, size: 16),
                            label: const Text('Quản lý đăng ký'),
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: AppColors.primary),
                              foregroundColor: AppColors.primary,
                            ),
                          ),
                        ],
                      ],
                    ),
                  )
                else ...[
                  // Đăng ký Face ID cho user (không theo lớp)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Icon(Icons.new_releases, color: Colors.orange, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Chưa đăng ký Face ID',
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: Colors.orange,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Đăng ký Face ID một lần để sử dụng cho tất cả các lớp học',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: Colors.grey[600],
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              // Sử dụng lớp đầu tiên để đăng ký Face ID (API sẽ gán cho user)
                              if (_todayClasses.isNotEmpty) {
                                _navigateToInitialFaceUpload(_todayClasses.first);
                              } else {
                                _showErrorDialog('Không có lớp học để đăng ký Face ID');
                              }
                            },
                            icon: const Icon(Icons.camera_enhance, size: 16),
                            label: const Text('Đăng ký Face ID'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 16),
                if (_faceRegistrationStatus != null)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.green.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.check_circle,
                              color: Colors.green.shade600,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '✅ Đã đăng ký Face ID thành công',
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: Colors.green,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Đã đăng ký ${_faceRegistrationStatus!['num_encodings']} ảnh khuôn mặt',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                        Text(
                          'Chất lượng trung bình: ${(_faceRegistrationStatus!['avg_quality'] * 100).toStringAsFixed(1)}%',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                        Text(
                          '(Không có lớp học để quản lý)',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: Colors.grey[500],
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      children: [
                        Icon(Icons.info_outline, color: Colors.grey, size: 24),
                        const SizedBox(height: 8),
                        Text(
                          'Chưa có lớp học để đăng ký Face ID',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ],
            ),
          ),
          const SizedBox(height: 20),

          // Logout Button
          PrimaryButton(
            text: 'Đăng xuất',
            onPressed: _showLogoutDialog,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: AppTextStyles.bodyMedium.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.onSurface.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  void _showClassOptionsDialog(Class classItem) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Chọn phương thức điểm danh'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Lớp: ${classItem.name}', style: AppTextStyles.bodyMedium),
            const SizedBox(height: 8),
            Text('Thời gian: ${classItem.name}', style: AppTextStyles.bodySmall),
            const SizedBox(height: 16),
            Text('Chọn phương thức điểm danh:', style: AppTextStyles.bodyMedium),
          ],
        ),
        actions: [
          // QR Code option
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 8),
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).pop();
                _navigateToQRAttendance(classItem);
              },
              icon: const Icon(Icons.qr_code_scanner),
              label: const Text('Quét mã QR'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          // Face ID option
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 8),
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).pop();
                _navigateToFaceAttendance(classItem);
              },
              icon: const Icon(Icons.face),
              label: const Text('Quét Face ID'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          // PIN option
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 8),
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).pop();
                _showPINDialog(classItem);
              },
              icon: const Icon(Icons.dialpad),
              label: const Text('Điểm danh bằng PIN'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.success,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          // Cancel button
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Hủy', style: TextStyle(color: Colors.grey)),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Đăng xuất'),
        content: const Text('Bạn có chắc chắn muốn đăng xuất?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();

              // Show loading indicator
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Đang đăng xuất...')),
              );

              // Check if widget is still mounted before navigating
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Đăng xuất thành công!')),
                );
                Navigator.pushReplacementNamed(context, '/login');
              }
            },
            child: Text(
              'Đăng xuất',
              style: TextStyle(color: AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }

  // Method to find current class based on current time
  Class? _getCurrentClass() {
    final now = DateTime.now();
    final currentMinutes = now.hour * 60 + now.minute;
    final currentDay = now.weekday;

    debugPrint('🔍 Looking for current class:');
    debugPrint('   Current day: ${_getDayName(currentDay)} ($currentDay)');
    debugPrint('   Current time: ${now.hour}:${now.minute.toString().padLeft(2, '0')} ($currentMinutes minutes)');
    debugPrint('   Today classes count: ${_todayClasses.length}');

    if (_todayClasses.isEmpty) {
      debugPrint('   ❌ No classes today');
      return null;
    }

    for (Class classItem in _todayClasses) {
      debugPrint('   Checking class: ${classItem.name}');
      debugPrint('     - Schedule: ${classItem.name}');

      // Parse schedule to find time patterns
      if (_isCurrentClassInSchedule(classItem.name, currentMinutes)) {
        debugPrint('✅ Found current class: ${classItem.name}');
        return classItem;
      }
    }

    debugPrint('❌ No current class found');
    return null;
  }

  // Method to show waiting dialog
  void _showWaitingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.schedule, color: AppColors.primary),
            const SizedBox(width: 8),
            const Text('Mời đợi'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 16),
            Icon(
              Icons.access_time_filled,
              size: 48,
              color: AppColors.primary,
            ),
            const SizedBox(height: 16),
            Text(
              'Chưa đến thời điểm điểm danh',
              style: AppTextStyles.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Vui lòng quay lại vào thời gian của buổi học',
              style: AppTextStyles.bodySmall.copyWith(
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            // Hiển thị các lớp học hôm nay
            if (_todayClasses.isNotEmpty) ...[
              const Divider(),
              const SizedBox(height: 8),
              Text(
                'Các lớp học hôm nay:',
                style: AppTextStyles.bodySmall.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              ..._todayClasses.take(3).map((classItem) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    Icon(Icons.school_outlined, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${classItem.name} (${classItem.code})',
                        style: AppTextStyles.bodySmall,
                      ),
                    ),
                  ],
                ),
              )),
              if (_todayClasses.length > 3)
                Text(
                  '... và ${_todayClasses.length - 3} lớp khác',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: Colors.grey[500],
                  ),
                ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.primary,
            ),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  // Method to get day name
  String _getDayName(int day) {
    switch (day) {
      case 1: return 'Thứ Hai';
      case 2: return 'Thứ Ba';
      case 3: return 'Thứ Tư';
      case 4: return 'Thứ Năm';
      case 5: return 'Thứ Sáu';
      case 6: return 'Thứ Bảy';
      case 7: return 'Chủ Nhật';
      default: return 'Unknown';
    }
  }

  // Method to check if current time matches class schedule
  bool _isCurrentClassInSchedule(String schedule, int currentMinutes) {
    // Check for morning classes (7:00 - 9:00 = 420 - 540 minutes)
    if (schedule.contains('7:00') && currentMinutes >= 420 && currentMinutes <= 540) {
      return true;
    }
    // Check for afternoon classes (14:00 - 16:00 = 840 - 960 minutes)
    if (schedule.contains('14:00') && currentMinutes >= 840 && currentMinutes <= 960) {
      return true;
    }
    // Check for other common time slots
    if (schedule.contains('9:30') && currentMinutes >= 570 && currentMinutes <= 690) {
      return true;
    }
    if (schedule.contains('16:30') && currentMinutes >= 990 && currentMinutes <= 1110) {
      return true;
    }

    return false;
  }

  
  // Method to get current class name for display
  String _getCurrentClassName() {
    final currentClass = _getCurrentClass();
    if (currentClass != null) {
      return '${currentClass.name} (Đang diễn ra)';
    } else if (_todayClasses.isNotEmpty) {
      return 'Không có lớp học đang diễn ra';
    } else {
      return 'Không có lớp học hôm nay';
    }
  }

  // Method to show attendance methods dialog
  void _showAttendanceMethodsDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(20),
          ),
        ),
        child: DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.5,
          maxChildSize: 0.9,
          builder: (context, scrollController) => SingleChildScrollView(
            controller: scrollController,
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle bar
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.how_to_reg,
                        color: AppColors.primary,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Chọn phương thức điểm danh',
                            style: AppTextStyles.heading3.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            _getCurrentClassName(),
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.onSurface.withValues(alpha: 0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                // Attendance methods
                Column(
                  children: [
                    _buildAttendanceMethodCard(
                      icon: Icons.face,
                      title: 'Face ID',
                      subtitle: 'Sử dụng khuôn mặt để điểm danh nhanh chóng',
                      color: AppColors.primary,
                      gradientColors: [AppColors.primary, AppColors.primaryVariant],
                      onTap: () {
                        Navigator.pop(context);
                        final currentClass = _getCurrentClass();
                        if (currentClass != null) {
                          _navigateToFaceAttendance(currentClass);
                        } else {
                          _showErrorDialog('Không có lớp học đang diễn ra để điểm danh');
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildAttendanceMethodCard(
                      icon: Icons.qr_code_scanner,
                      title: 'Quét mã QR',
                      subtitle: 'Quét mã QR từ giảng viên để điểm danh',
                      color: AppColors.success,
                      gradientColors: [AppColors.success, AppColors.success.withValues(alpha: 0.8)],
                      onTap: () {
                        Navigator.pop(context);
                        final currentClass = _getCurrentClass();
                        if (currentClass != null) {
                          _navigateToQRAttendance(currentClass);
                        } else {
                          _showErrorDialog('Không có lớp học đang diễn ra để điểm danh');
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildAttendanceMethodCard(
                      icon: Icons.dialpad,
                      title: 'Mã PIN',
                      subtitle: 'Nhập mã PIN 4 chữ số để điểm danh',
                      color: AppColors.warning,
                      gradientColors: [AppColors.warning, AppColors.warning.withValues(alpha: 0.8)],
                      onTap: () {
                        Navigator.pop(context);
                        final currentClass = _getCurrentClass();
                        if (currentClass != null) {
                          _showPINDialog(currentClass);
                        } else {
                          _showErrorDialog('Không có lớp học đang diễn ra để điểm danh');
                        }
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                // Cancel button
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      side: BorderSide(
                        color: AppColors.onSurface.withValues(alpha: 0.2),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      'Hủy',
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // New method for building attendance method cards
  Widget _buildAttendanceMethodCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required List<Color> gradientColors,
    required VoidCallback onTap,
  }) {
    return Material(
      elevation: 4,
      borderRadius: BorderRadius.circular(16),
      shadowColor: color.withValues(alpha: 0.3),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                color.withValues(alpha: 0.08),
                color.withValues(alpha: 0.02),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: color.withValues(alpha: 0.2),
              width: 1.5,
            ),
          ),
          child: Row(
            children: [
              // Icon container
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: gradientColors,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Icon(
                  icon,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),

              // Text content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTextStyles.heading4.copyWith(
                        fontWeight: FontWeight.w700,
                        color: color,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),

              // Arrow icon
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.arrow_forward_ios,
                  color: color,
                  size: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // PIN dialog method
  void _showPINDialog(Class classItem) {
    String enteredPIN = '';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.dialpad,
                  color: AppColors.warning,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Nhập mã PIN',
                style: AppTextStyles.heading4.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Nhập mã PIN 4 chữ số để điểm danh',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.onSurface.withValues(alpha: 0.7),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),

              // PIN display
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.warning.withValues(alpha: 0.3),
                    width: 2,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(4, (index) {
                    return Container(
                      width: 24,
                      height: 32,
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: AppColors.divider,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          index < enteredPIN.length ? enteredPIN[index] : '',
                          style: AppTextStyles.heading3.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppColors.warning,
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
              const SizedBox(height: 24),

              // Number pad
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 3,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.5,
                children: [
                  ...List.generate(9, (index) {
                    final number = (index + 1).toString();
                    return _buildPINButton(
                      number: number,
                      onPressed: () {
                        if (enteredPIN.length < 4) {
                          setState(() {
                            enteredPIN += number;
                          });
                        }
                      },
                    );
                  }),
                  _buildPINButton(
                    number: 'CLR',
                    onPressed: () {
                      setState(() {
                        enteredPIN = '';
                      });
                    },
                    backgroundColor: AppColors.error.withValues(alpha: 0.1),
                    textColor: AppColors.error,
                  ),
                  _buildPINButton(
                    number: '0',
                    onPressed: () {
                      if (enteredPIN.length < 4) {
                        setState(() {
                          enteredPIN += '0';
                        });
                      }
                    },
                  ),
                  _buildPINButton(
                    number: '⌫',
                    onPressed: () {
                      if (enteredPIN.isNotEmpty) {
                        setState(() {
                          enteredPIN = enteredPIN.substring(0, enteredPIN.length - 1);
                        });
                      }
                    },
                    backgroundColor: AppColors.background,
                    textColor: AppColors.onSurface,
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Hủy',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ),
            if (enteredPIN.length == 4)
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _processPINAttendance(classItem, enteredPIN);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.warning,
                  foregroundColor: Colors.white,
                ),
                child: Text(
                  'Xác nhận',
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPINButton({
    required String number,
    required VoidCallback onPressed,
    Color? backgroundColor,
    Color? textColor,
  }) {
    final bgColor = backgroundColor ?? AppColors.primary;
    final txtColor = textColor ?? Colors.white;

    return Material(
      elevation: 2,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              number,
              style: AppTextStyles.heading3.copyWith(
                fontWeight: FontWeight.w700,
                color: txtColor,
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _processPINAttendance(Class classItem, String pin) {
    // Mock PIN validation - in real app, this would validate against server
    if (pin == '1234') {
      _showAttendanceSuccessDialog(AttendanceRecord(
        id: 'pin_${DateTime.now().millisecondsSinceEpoch}',
        studentId: _currentUser!.id,
        studentName: _currentUser!.fullName,
        classId: classItem.id,
        className: classItem.name,
        sessionId: 'session_${DateTime.now().millisecondsSinceEpoch}',
        checkInTime: DateTime.now(),
        status: 'on_time',
        method: 'pin',
        confidence: 1.0,
      ));
    } else {
      _showErrorDialog('Mã PIN không chính xác. Vui lòng thử lại.');
    }
  }
}