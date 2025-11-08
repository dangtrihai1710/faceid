import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/primary_button.dart';
import '../../core/widgets/stat_card.dart';
import '../../core/widgets/info_card.dart';
import '../../screens/widgets/class_card.dart';
import '../../mock/mock_data.dart';
import '../../mock/mock_models.dart';

class StudentHomeScreen extends StatefulWidget {
  const StudentHomeScreen({super.key});

  @override
  State<StudentHomeScreen> createState() => _StudentHomeScreenState();
}

class _StudentHomeScreenState extends State<StudentHomeScreen> {
  late User _currentUser;
  late List<ClassModel> _todayClasses;
  late AttendanceStats _stats;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  void _loadUserData() {
    setState(() {
      _currentUser = MockData.getCurrentUser('student');
      _todayClasses = MockData.getTodayClasses('student');
      _stats = MockData.studentStats;
    });
  }

  ClassModel? get _currentClass {
    final now = DateTime.now();
    final currentMinutes = now.hour * 60 + now.minute;

    for (var classItem in _todayClasses) {
      final times = classItem.time.split(' - ');
      if (times.length == 2) {
        final startTimeParts = times[0].split(':');
        final endTimeParts = times[1].split(':');

        if (startTimeParts.length == 2 && endTimeParts.length == 2) {
          final startMinutes = int.parse(startTimeParts[0]) * 60 + int.parse(startTimeParts[1]);
          final endMinutes = int.parse(endTimeParts[0]) * 60 + int.parse(endTimeParts[1]);

          if (currentMinutes >= startMinutes && currentMinutes <= endMinutes) {
            return classItem;
          }
        }
      }
    }
    return null;
  }

  void _onBottomNavTap(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Future<void> _navigateToCamera() async {
    Navigator.pushNamed(context, '/camera').then((_) {
      _loadUserData(); // Refresh data after returning from camera
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentClass = _currentClass;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Xin chào, ${_currentUser.name.split(' ').last} 👋',
              style: AppTextStyles.heading3.copyWith(
                color: AppColors.onBackground,
              ),
            ),
            Text(
              'Chúc bạn một ngày học tập tốt!',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.onSurface.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Không có thông báo mới')),
              );
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            color: AppColors.divider,
          ),
        ),
      ),

      body: _selectedIndex == 0
          ? _buildHomeView(currentClass)
          : _selectedIndex == 1
              ? _buildScheduleView()
              : _selectedIndex == 2
                  ? _buildStatsView()
                  : _buildProfileView(),

      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildHomeView(ClassModel? currentClass) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Current Class Card
          if (currentClass != null) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.onPrimary.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.class_outlined,
                          color: AppColors.onPrimary,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Lớp học hiện tại',
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: AppColors.onPrimary.withValues(alpha: 0.8),
                              ),
                            ),
                            Text(
                              currentClass.subject,
                              style: AppTextStyles.heading3.copyWith(
                                color: AppColors.onPrimary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _buildInfoChip(
                        Icons.location_on_outlined,
                        'Phòng ${currentClass.room}',
                      ),
                      const SizedBox(width: 12),
                      _buildInfoChip(
                        Icons.access_time,
                        currentClass.time,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 16,
                        color: AppColors.onPrimary.withValues(alpha: 0.8),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Trạng thái: Chưa điểm danh',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.onPrimary.withValues(alpha: 0.9),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ] else ...[
            InfoCard(
              title: 'Không có lớp học hiện tại',
              subtitle: 'Hãy kiểm tra lịch học của bạn',
              icon: Icons.info_outline,
              iconColor: AppColors.info,
              backgroundColor: AppColors.surface,
            ),
            const SizedBox(height: 24),
          ],

          // Take Attendance Button
          Container(
            width: double.infinity,
            height: 120,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.primary.withValues(alpha: 0.1),
                  AppColors.secondary.withValues(alpha: 0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.3),
                width: 2,
              ),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: currentClass != null ? _navigateToCamera : null,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: currentClass != null
                              ? AppColors.primary
                              : AppColors.divider,
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Icon(
                          Icons.camera_alt_outlined,
                          size: 30,
                          color: currentClass != null
                              ? AppColors.onPrimary
                              : AppColors.onSurface.withValues(alpha: 0.5),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '📸 Điểm danh (Face ID)',
                        style: AppTextStyles.buttonLarge.copyWith(
                          color: currentClass != null
                              ? AppColors.primary
                              : AppColors.onSurface.withValues(alpha: 0.5),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (currentClass == null)
                        Text(
                          'Chỉ có thể điểm danh trong giờ học',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.onSurface.withValues(alpha: 0.7),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 32),

          // Today's Schedule
          Row(
            children: [
              Text(
                'Lịch học hôm nay',
                style: AppTextStyles.heading3,
              ),
              const Spacer(),
              TextButton(
                onPressed: () {
                  setState(() {
                    _selectedIndex = 1;
                  });
                },
                child: Text(
                  'Xem tất cả',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_todayClasses.isEmpty)
            InfoCard(
              title: 'Không có lịch học hôm nay',
              subtitle: 'Hãy kiểm tra lịch học vào các ngày khác',
              icon: Icons.event_busy,
              iconColor: AppColors.warning,
            )
          else
            ..._todayClasses.map((classItem) => ClassCard(
              classItem: classItem,
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Chi tiết: ${classItem.subject}')),
                );
              },
            )),

          const SizedBox(height: 32),

          // Quick Stats
          Row(
            children: [
              Text(
                'Thống kê nhanh',
                style: AppTextStyles.heading3,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: StatCard(
                  title: 'Đã tham gia',
                  value: '${_stats.attendedClasses}',
                  icon: Icons.check_circle_outline,
                  iconColor: AppColors.success,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: StatCard(
                  title: 'Vắng mặt',
                  value: '${_stats.missedClasses}',
                  icon: Icons.cancel_outlined,
                  iconColor: AppColors.error,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.onPrimary.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: AppColors.onPrimary.withValues(alpha: 0.9),
          ),
          const SizedBox(width: 4),
          Text(
            text,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.onPrimary.withValues(alpha: 0.9),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleView() {
    return Center(
      child: Text(
        'Schedule Screen - Coming Soon',
        style: AppTextStyles.heading2,
      ),
    );
  }

  Widget _buildStatsView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Thống kê điểm danh',
            style: AppTextStyles.heading2,
          ),
          const SizedBox(height: 24),
          CircularProgressStat(
            title: 'Tỷ lệ tham gia',
            percentage: _stats.attendanceRate / 100,
            value: '${(_stats.attendanceRate).toInt()}%',
            color: AppColors.primary,
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: StatCard(
                  title: 'Tổng số lớp',
                  value: '${_stats.totalClasses}',
                  icon: Icons.class_outlined,
                  iconColor: AppColors.primary,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: StatCard(
                  title: 'Đi học',
                  value: '${_stats.attendedClasses}',
                  icon: Icons.check_circle_outline,
                  iconColor: AppColors.success,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: StatCard(
                  title: 'Vắng mặt',
                  value: '${_stats.missedClasses}',
                  icon: Icons.cancel_outlined,
                  iconColor: AppColors.error,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: StatCard(
                  title: 'Đi muộn',
                  value: '${_stats.lateClasses}',
                  icon: Icons.schedule,
                  iconColor: AppColors.warning,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProfileView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const SizedBox(height: 20),
          CircleAvatar(
            radius: 60,
            backgroundColor: AppColors.primary,
            child: Text(
              _currentUser.avatar,
              style: const TextStyle(fontSize: 60),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            _currentUser.name,
            style: AppTextStyles.heading2,
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _currentUser.role == 'student' ? 'Sinh viên' : 'Giảng viên',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(height: 32),
          InfoCard(
            title: 'Email',
            subtitle: _currentUser.email,
            icon: Icons.email_outlined,
            iconColor: AppColors.info,
          ),
          const SizedBox(height: 12),
          InfoCard(
            title: 'Mã số',
            subtitle: _currentUser.id,
            icon: Icons.badge_outlined,
            iconColor: AppColors.info,
          ),
          const SizedBox(height: 12),
          InfoCard(
            title: 'Khoa',
            subtitle: _currentUser.department,
            icon: Icons.business_outlined,
            iconColor: AppColors.info,
          ),
          const SizedBox(height: 32),
          PrimaryButton(
            text: 'Đăng xuất',
            onPressed: () {
              Navigator.pushReplacementNamed(context, '/login');
            },
            backgroundColor: AppColors.error,
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavigationBar() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onBottomNavTap,
        backgroundColor: Colors.transparent,
        elevation: 0,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.onSurface.withValues(alpha: 0.6),
        selectedLabelStyle: AppTextStyles.bodySmall.copyWith(
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: AppTextStyles.bodySmall,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Trang chủ',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.schedule_outlined),
            activeIcon: Icon(Icons.schedule),
            label: 'Lịch học',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart_outlined),
            activeIcon: Icon(Icons.bar_chart),
            label: 'Thống kê',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Cá nhân',
          ),
        ],
      ),
    );
  }
}