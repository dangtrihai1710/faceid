import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/primary_button.dart';
import '../../core/widgets/stat_card.dart';
import '../../core/widgets/info_card.dart';
import '../../screens/widgets/class_card.dart';
import '../../mock/mock_data.dart';
import '../../mock/mock_models.dart';

class TeacherHomeScreen extends StatefulWidget {
  const TeacherHomeScreen({super.key});

  @override
  State<TeacherHomeScreen> createState() => _TeacherHomeScreenState();
}

class _TeacherHomeScreenState extends State<TeacherHomeScreen> {
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
      _currentUser = MockData.getCurrentUser('teacher');
      _todayClasses = MockData.getTodayClasses('teacher');
      _stats = MockData.teacherStats;
    });
  }

  void _onBottomNavTap(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Future<void> _navigateToCamera(ClassModel classItem) async {
    Navigator.pushNamed(context, '/camera', arguments: classItem).then((_) {
      _loadUserData(); // Refresh data after returning from camera
    });
  }

  void _showClassDetails(ClassModel classItem) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(classItem.subject),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Phòng: ${classItem.room}'),
            Text('Thời gian: ${classItem.time}'),
            Text('Giảng viên: ${classItem.teacher}'),
            const SizedBox(height: 12),
            Text(
              'Số lượng sinh viên: ${classItem.students.length}',
              style: AppTextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            if (classItem.students.isNotEmpty) ...[
              const SizedBox(height: 8),
              const Text('Danh sách sinh viên:'),
              ...classItem.students.take(5).map((student) => Padding(
                padding: const EdgeInsets.only(left: 16, top: 4),
                child: Text('• $student'),
              )),
              if (classItem.students.length > 5)
                Text('... và ${classItem.students.length - 5} sinh viên khác'),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Chào buổi sáng, ${_currentUser.name.split(' ').last} 👋',
              style: AppTextStyles.heading3.copyWith(
                color: AppColors.onBackground,
              ),
            ),
            Text(
              'Hôm nay bạn có ${_todayClasses.length} lớp học',
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
          ? _buildHomeView()
          : _selectedIndex == 1
              ? _buildScheduleView()
              : _selectedIndex == 2
                  ? _buildStatsView()
                  : _buildProfileView(),

      bottomNavigationBar: _buildBottomNavigationBar(),

      floatingActionButton: _selectedIndex == 0
          ? FloatingActionButton.extended(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Tính năng đang phát triển')),
                );
              },
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.onPrimary,
              icon: const Icon(Icons.add),
              label: const Text('Thêm lớp'),
            )
          : null,
    );
  }

  Widget _buildHomeView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Welcome Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
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
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.onPrimary.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.school_outlined,
                        color: AppColors.onPrimary,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Quản lý điểm danh',
                            style: AppTextStyles.heading3.copyWith(
                              color: AppColors.onPrimary,
                            ),
                          ),
                          Text(
                            'Tiện lợi, nhanh chóng, chính xác',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.onPrimary.withValues(alpha: 0.9),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: _buildQuickStat(
                        'Lớp hôm nay',
                        '${_todayClasses.length}',
                        Icons.today_outlined,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildQuickStat(
                        'Tổng sinh viên',
                        '${_todayClasses.fold<int>(0, (sum, classItem) => sum + classItem.students.length)}',
                        Icons.people_outline,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // Today's Classes
          Row(
            children: [
              Text(
                'Lớp học hôm nay',
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
              title: 'Không có lớp học hôm nay',
              subtitle: 'Hãy kiểm tra lịch học vào các ngày khác',
              icon: Icons.event_busy,
              iconColor: AppColors.warning,
            )
          else
            ..._todayClasses.map((classItem) => ClassCard(
              classItem: classItem,
              onTap: () => _showClassDetails(classItem),
              onActionPressed: () => _navigateToCamera(classItem),
              actionText: classItem.status.toLowerCase() == 'ongoing'
                  ? 'Bắt đầu điểm danh'
                  : 'Xem chi tiết',
              showAction: true,
            )),

          const SizedBox(height: 32),

          // Recent Attendance Summary
          Row(
            children: [
              Text(
                'Tóm tắt điểm danh gần đây',
                style: AppTextStyles.heading3,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
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
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Tỷ lệ tham gia trung bình',
                      style: AppTextStyles.bodyLarge,
                    ),
                    Text(
                      '85%',
                      style: AppTextStyles.heading3.copyWith(
                        color: AppColors.success,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  height: 8,
                  decoration: BoxDecoration(
                    color: AppColors.divider,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: 0.85,
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.success,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildMiniStat(
                        'Có mặt',
                        '42',
                        AppColors.success,
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 40,
                      color: AppColors.divider,
                    ),
                    Expanded(
                      child: _buildMiniStat(
                        'Vắng mặt',
                        '6',
                        AppColors.error,
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 40,
                      color: AppColors.divider,
                    ),
                    Expanded(
                      child: _buildMiniStat(
                        'Đi muộn',
                        '2',
                        AppColors.warning,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // Quick Actions
          Row(
            children: [
              Text(
                'Thao tác nhanh',
                style: AppTextStyles.heading3,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildQuickAction(
                  Icons.history_outlined,
                  'Lịch sử điểm danh',
                  AppColors.info,
                  () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Tính năng đang phát triển')),
                    );
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildQuickAction(
                  Icons.download_outlined,
                  'Xuất báo cáo',
                  AppColors.secondary,
                  () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Tính năng đang phát triển')),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStat(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.onPrimary.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: AppColors.onPrimary,
            size: 24,
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: AppTextStyles.heading3.copyWith(
              color: AppColors.onPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            title,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.onPrimary.withValues(alpha: 0.9),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: AppTextStyles.heading4.copyWith(
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.onSurface.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickAction(IconData icon, String label, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
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
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: color,
                size: 24,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              label,
              style: AppTextStyles.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
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
            'Thống kê giảng dạy',
            style: AppTextStyles.heading2,
          ),
          const SizedBox(height: 24),
          CircularProgressStat(
            title: 'Tỷ lệ tham gia trung bình',
            percentage: 0.85,
            value: '85%',
            color: AppColors.primary,
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: StatCard(
                  title: 'Tổng lớp học',
                  value: '${_stats.totalClasses}',
                  icon: Icons.class_outlined,
                  iconColor: AppColors.primary,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: StatCard(
                  title: 'Tổng sinh viên',
                  value: '48',
                  icon: Icons.people_outline,
                  iconColor: AppColors.info,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: StatCard(
                  title: 'Tổng điểm danh',
                  value: '156',
                  icon: Icons.how_to_reg_outlined,
                  iconColor: AppColors.success,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: StatCard(
                  title: 'Tuần này',
                  value: '12',
                  icon: Icons.date_range_outlined,
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
              'Giảng viên',
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
            title: 'Mã giảng viên',
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
            label: 'Lịch giảng',
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