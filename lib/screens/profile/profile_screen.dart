import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/primary_button.dart';
import '../../core/widgets/info_card.dart';
import '../../core/widgets/stat_card.dart';
import '../../mock/mock_data.dart';
import '../../mock/mock_models.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late User _currentUser;
  late AttendanceStats _stats;
  bool _isTeacher = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  void _loadUserData() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      if (args != null) {
        setState(() {
          _isTeacher = args['isTeacher'] ?? false;
          _currentUser = MockData.getCurrentUser(_isTeacher ? 'teacher' : 'student');
          _stats = _isTeacher ? MockData.teacherStats : MockData.studentStats;
        });
      } else {
        // Default to student if no arguments
        setState(() {
          _isTeacher = false;
          _currentUser = MockData.getCurrentUser('student');
          _stats = MockData.studentStats;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: Text(
          'Hồ sơ cá nhân',
          style: AppTextStyles.heading3.copyWith(
            color: AppColors.onBackground,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Tính năng đang phát triển')),
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Profile Header
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
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: AppColors.onPrimary.withValues(alpha: 0.2),
                    child: Text(
                      _currentUser.avatar,
                      style: const TextStyle(fontSize: 50),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _currentUser.name,
                    style: AppTextStyles.heading2.copyWith(
                      color: AppColors.onPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.onPrimary.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _isTeacher ? 'Giảng viên' : 'Sinh viên',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.onPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _currentUser.department,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.onPrimary.withValues(alpha: 0.9),
                    ),
                  ),
                ],
              ),
            ),

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
                    title: _isTeacher ? 'Tổng lớp' : 'Tổng buổi học',
                    value: '${_stats.totalClasses}',
                    icon: Icons.calendar_today_outlined,
                    iconColor: AppColors.primary,
                    showProgress: false,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: StatCard(
                    title: _isTeacher ? 'Tổng sinh viên' : 'Đã tham gia',
                    value: _isTeacher ? '48' : '${_stats.attendedClasses}',
                    icon: _isTeacher ? Icons.people_outline : Icons.check_circle_outline,
                    iconColor: AppColors.success,
                    showProgress: false,
                  ),
                ),
              ],
            ),
            if (!_isTeacher) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: StatCard(
                      title: 'Vắng mặt',
                      value: '${_stats.missedClasses}',
                      icon: Icons.cancel_outlined,
                      iconColor: AppColors.error,
                      showProgress: false,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: StatCard(
                      title: 'Tỷ lệ',
                      value: '${_stats.attendanceRate.toInt()}%',
                      icon: Icons.trending_up_outlined,
                      iconColor: AppColors.info,
                      showProgress: true,
                      progress: _stats.attendanceRate / 100,
                    ),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 32),

            // Personal Information
            Row(
              children: [
                Text(
                  'Thông tin cá nhân',
                  style: AppTextStyles.heading3,
                ),
              ],
            ),
            const SizedBox(height: 16),
            InfoCard(
              title: 'Email',
              subtitle: _currentUser.email,
              icon: Icons.email_outlined,
              iconColor: AppColors.info,
            ),
            const SizedBox(height: 12),
            InfoCard(
              title: _isTeacher ? 'Mã giảng viên' : 'Mã sinh viên',
              subtitle: _currentUser.id,
              icon: Icons.badge_outlined,
              iconColor: AppColors.info,
            ),
            const SizedBox(height: 12),
            InfoCard(
              title: 'Khoa/Phòng ban',
              subtitle: _currentUser.department,
              icon: Icons.business_outlined,
              iconColor: AppColors.info,
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
            Container(
              width: double.infinity,
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
                  _buildActionTile(
                    Icons.edit_outlined,
                    'Chỉnh sửa thông tin',
                    () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Tính năng đang phát triển')),
                      );
                    },
                  ),
                  Divider(height: 1, color: AppColors.divider),
                  _buildActionTile(
                    Icons.history_outlined,
                    'Lịch sử điểm danh',
                    () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Tính năng đang phát triển')),
                      );
                    },
                  ),
                  Divider(height: 1, color: AppColors.divider),
                  _buildActionTile(
                    Icons.download_outlined,
                    'Xuất báo cáo',
                    () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Tính năng đang phát triển')),
                      );
                    },
                  ),
                  Divider(height: 1, color: AppColors.divider),
                  _buildActionTile(
                    Icons.notifications_outlined,
                    'Cài đặt thông báo',
                    () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Tính năng đang phát triển')),
                      );
                    },
                  ),
                  Divider(height: 1, color: AppColors.divider),
                  _buildActionTile(
                    Icons.help_outline,
                    'Trợ giúp & Hỗ trợ',
                    () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Tính năng đang phát triển')),
                      );
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Logout Button
            PrimaryButton(
              text: 'Đăng xuất',
              onPressed: _showLogoutConfirmation,
              backgroundColor: AppColors.error,
            ),

            const SizedBox(height: 20),

            // App Version
            Text(
              'FaceID Attendance v1.0.0',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.onSurface.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionTile(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Icon(
        icon,
        color: AppColors.primary,
        size: 24,
      ),
      title: Text(
        title,
        style: AppTextStyles.bodyMedium.copyWith(
          color: AppColors.onBackground,
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: Icon(
        Icons.arrow_forward_ios,
        size: 16,
        color: AppColors.onSurface.withValues(alpha: 0.5),
      ),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
    );
  }

  void _showLogoutConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận đăng xuất'),
        content: const Text('Bạn có chắc chắn muốn đăng xuất khỏi ứng dụng?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushReplacementNamed(context, '/login');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: AppColors.onPrimary,
            ),
            child: const Text('Đăng xuất'),
          ),
        ],
      ),
    );
  }
}