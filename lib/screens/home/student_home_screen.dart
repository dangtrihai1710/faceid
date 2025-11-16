import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/primary_button.dart';
import '../../core/widgets/stat_card.dart';
import '../../screens/attendance/attendance_scan_screen.dart';
import '../../screens/attendance/face_attendance_screen.dart';
import '../../screens/attendance/face_registration_screen.dart';
import '../../screens/attendance/face_initial_upload_screen.dart';
import '../../core/models/user_models.dart' as user_models;
import '../../core/models/class_models.dart';
import '../../core/services/attendance_face_service.dart';
import '../../core/services/test_data_service.dart';

class StudentHomeScreen extends StatefulWidget {
  const StudentHomeScreen({super.key});

  @override
  State<StudentHomeScreen> createState() => _StudentHomeScreenState();
}

class _StudentHomeScreenState extends State<StudentHomeScreen> {
  late user_models.User _currentUser;
  late List<Class> _todayClasses;
  late user_models.AttendanceStats _stats;
  int _selectedIndex = 0;
  final AttendanceFaceService _attendanceService = AttendanceFaceService();

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  void _loadUserData() {
    setState(() {
      // Mock user Nguyễn Văn An
      _currentUser = user_models.User(
        id: 'SV001',
        userCode: 'SV001',
        fullName: 'Nguyễn Văn An',
        email: 'nguyen.van.an@university.edu.vn',
        role: 'student',
        department: 'Công nghệ thông tin',
        createdAt: DateTime.now().subtract(const Duration(days: 365)),
        updatedAt: DateTime.now(),
      );

      // Get student classes
      final studentClasses = TestDataService.getClassesForStudent(_currentUser.id);
      _todayClasses = studentClasses;

      // Mock stats
      _stats = user_models.AttendanceStats(
        totalClasses: 45,
        attendedClasses: 40,
        missedClasses: 3,
        lateClasses: 2,
        attendanceRate: 0.89,
      );
    });
  }

  Class? get _currentClass {
    final now = DateTime.now();
    final currentMinutes = now.hour * 60 + now.minute;

    for (var classItem in _todayClasses) {
      // Simple time check - in real app would parse schedule better
      if (classItem.schedule.contains('7:00') && currentMinutes >= 420 && currentMinutes <= 540) {
        return classItem;
      } else if (classItem.schedule.contains('14:00') && currentMinutes >= 840 && currentMinutes <= 960) {
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
    try {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => FaceRegistrationScreen(
            currentUser: _currentUser,
            classId: classItem.id,
            onRegistrationComplete: () {
              _showAttendanceSuccessDialog(AttendanceRecord(
                id: 'face_registration_${DateTime.now().millisecondsSinceEpoch}',
                studentId: _currentUser.id,
                studentName: _currentUser.fullName,
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
    try {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => FaceInitialUploadScreen(
            currentUser: _currentUser,
            classId: classItem.id,
            onUploadComplete: () {
              _showAttendanceSuccessDialog(AttendanceRecord(
                id: 'face_initial_upload_${DateTime.now().millisecondsSinceEpoch}',
                studentId: _currentUser.id,
                studentName: _currentUser.fullName,
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

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Welcome Section
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primary, AppColors.primary.withValues(alpha: 0.8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Xin chào,',
                  style: AppTextStyles.bodyLarge.copyWith(
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _currentUser.fullName,
                  style: AppTextStyles.heading2.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _currentUser.userCode,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                ),
              ],
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
            '${classItem.schedule} • Phòng ${classItem.room}',
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
        Text(
          'Thao tác nhanh',
          style: AppTextStyles.heading4.copyWith(
            color: AppColors.onBackground,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildQuickActionCard(
                icon: Icons.qr_code_scanner,
                label: 'Quét QR',
                onTap: () {
                  if (_todayClasses.isNotEmpty) {
                    _navigateToQRAttendance(_todayClasses.first);
                  } else {
                    _showErrorDialog('Không có lớp học hôm nay');
                  }
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildQuickActionCard(
                icon: Icons.face,
                label: 'Face ID',
                onTap: () {
                  if (_todayClasses.isNotEmpty) {
                    _navigateToFaceAttendance(_todayClasses.first);
                  } else {
                    _showErrorDialog('Không có lớp học hôm nay');
                  }
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildQuickActionCard(
                icon: Icons.history,
                label: 'Lịch sử',
                onTap: () {
                  _showErrorDialog('Tính năng đang phát triển');
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildQuickActionCard(
                icon: Icons.calendar_today,
                label: 'Lịch học',
                onTap: () {
                  _showErrorDialog('Tính năng đang phát triển');
                },
              ),
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
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.onSurface.withValues(alpha: 0.1)),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 32,
              color: AppColors.primary,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.onSurface,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsGrid() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Thống kê điểm danh',
          style: AppTextStyles.heading4.copyWith(
            color: AppColors.onBackground,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: StatCard(
                title: 'Tỷ lệ điểm danh',
                value: '${(_stats.attendanceRate * 100).toStringAsFixed(1)}%',
                icon: Icons.check_circle,
                iconColor: AppColors.success,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: StatCard(
                title: 'Buổi đã tham gia',
                value: '${_stats.attendedClasses}',
                icon: Icons.class_,
                iconColor: AppColors.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: StatCard(
                title: 'Buổi đi muộn',
                value: '${_stats.lateClasses}',
                icon: Icons.schedule,
                iconColor: Colors.orange,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: StatCard(
                title: 'Buổi vắng',
                value: '${_stats.missedClasses}',
                icon: Icons.cancel,
                iconColor: AppColors.error,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTodaySchedule() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Lịch học hôm nay',
          style: AppTextStyles.heading4.copyWith(
            color: AppColors.onBackground,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        if (_todayClasses.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Column(
                children: [
                  Icon(
                    Icons.event_available,
                    size: 48,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Không có lịch học hôm nay',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          ..._todayClasses.map((classItem) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
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
              '${classItem.schedule} • Phòng ${classItem.room}',
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
    final studentClasses = TestDataService.getClassesForStudent(_currentUser.id);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Lớp học của bạn',
            style: AppTextStyles.heading3.copyWith(
              color: AppColors.onBackground,
              fontWeight: FontWeight.bold,
            ),
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
    );
  }

  Widget _buildProfileTab() {
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
                  _currentUser.fullName,
                  style: AppTextStyles.heading3.copyWith(
                    color: AppColors.onBackground,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _currentUser.userCode,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.onSurface.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _currentUser.email,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.onSurface.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _currentUser.department ?? 'Công nghệ thông tin',
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
                _buildInfoRow('Họ và tên', _currentUser.fullName),
                _buildInfoRow('Mã sinh viên', _currentUser.userCode),
                _buildInfoRow('Email', _currentUser.email),
                _buildInfoRow('Khoa', _currentUser.department ?? 'Công nghệ thông tin'),
                _buildInfoRow('Vai trò', _currentUser.role),
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
                if (_todayClasses.isNotEmpty) ...[
                  Text(
                    'Chọn lớp học để đăng ký Face ID:',
                    style: AppTextStyles.bodySmall,
                  ),
                  const SizedBox(height: 12),

                  // Đăng ký lần đầu - nổi bật
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
                                'Đăng ký lần đầu (chưa có dữ liệu)',
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: Colors.orange,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ..._todayClasses.map((classItem) => Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () => _navigateToInitialFaceUpload(classItem),
                              icon: const Icon(Icons.photo_camera_outlined, size: 16),
                              label: Text('Lần đầu - ${classItem.name}'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 8),
                              ),
                            ),
                          ),
                        )),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Đăng ký thêm ảnh - nếu cần
                  ExpansionTile(
                    title: Text(
                      'Đăng ký thêm ảnh',
                      style: AppTextStyles.bodySmall,
                    ),
                    tilePadding: EdgeInsets.zero,
                    children: _todayClasses.map((classItem) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: OutlinedButton.icon(
                        onPressed: () => _navigateToFaceRegistration(classItem),
                        icon: const Icon(Icons.camera_enhance, size: 16),
                        label: Text('Thêm ảnh - ${classItem.name}'),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: AppColors.primary),
                          foregroundColor: AppColors.primary,
                        ),
                      ),
                    )).toList(),
                  ),
                ] else ...[
                  Text(
                    'Bạn chưa có lớp học nào để đăng ký Face ID.',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.onSurface.withValues(alpha: 0.7),
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
            Text('Thời gian: ${classItem.schedule}', style: AppTextStyles.bodySmall),
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
}