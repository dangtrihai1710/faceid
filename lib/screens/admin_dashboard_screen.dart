import 'package:flutter/material.dart';
import '../models/user.dart';
import '../models/class_model.dart';
import '../services/admin_service.dart';
import 'student_management_screen.dart';
import 'instructor_management_screen.dart';
import 'class_management_screen.dart';
import 'home_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  final User adminUser;

  const AdminDashboardScreen({
    super.key,
    required this.adminUser,
  });

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  Map<String, int> _statistics = {
    'students': 0,
    'instructors': 0,
    'classes': 0,
    'activeClasses': 0,
  };
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStatistics();
  }

  Future<void> _loadStatistics() async {
    final stats = await AdminService.getSystemStatistics();
    setState(() {
      _statistics = stats;
      _isLoading = false;
    });
  }

  void _showRoleSelectionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Chọn vai trò đăng nhập'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Bạn muốn đăng nhập với vai trò nào?'),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.school, color: Colors.blue),
              title: const Text('Sinh viên'),
              subtitle: const Text('Truy cập giao diện sinh viên'),
              onTap: () {
                Navigator.of(context).pop();
                _loginAsRole('student');
              },
            ),
            ListTile(
              leading: const Icon(Icons.person, color: Colors.purple),
              title: const Text('Giảng viên'),
              subtitle: const Text('Truy cập giao diện giảng viên'),
              onTap: () {
                Navigator.of(context).pop();
                _loginAsRole('instructor');
              },
            ),
            ListTile(
              leading: const Icon(Icons.admin_panel_settings, color: Colors.red),
              title: const Text('Admin'),
              subtitle: const Text('Ở lại trang quản trị'),
              onTap: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Hủy'),
          ),
        ],
      ),
    );
  }

  void _loginAsRole(String role) {
    // Create a user with the selected role for demo purposes
    final roleUser = User(
      id: 'demo_user',
      username: 'demo',
      fullName: 'Demo User',
      email: 'demo@faceid.com',
      role: role,
      token: 'demo_token_${DateTime.now().millisecondsSinceEpoch}',
    );

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => HomeScreen(currentUser: roleUser),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        backgroundColor: Colors.red[700],
        foregroundColor: Colors.white,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.switch_account),
            onPressed: _showRoleSelectionDialog,
            tooltip: 'Chuyển vai trò',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadStatistics,
            tooltip: 'Làm mới',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Welcome Section
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.red[400]!, Colors.red[700]!],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.red.withOpacity(0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Chào mừng, Admin!',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Quản lý toàn bộ hệ thống điểm danh',
                          style: TextStyle(
                            color: Colors.red[100],
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: _showRoleSelectionDialog,
                          icon: const Icon(Icons.switch_account),
                          label: const Text('Đăng nhập với vai trò khác'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.red[700],
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Statistics Cards
                  const Text(
                    'Thống kê hệ thống',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),

                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1.2,
                    children: [
                      _buildStatCard(
                        'Sinh viên',
                        _statistics['students']!,
                        Icons.school,
                        Colors.blue,
                      ),
                      _buildStatCard(
                        'Giảng viên',
                        _statistics['instructors']!,
                        Icons.person,
                        Colors.purple,
                      ),
                      _buildStatCard(
                        'Lớp học',
                        _statistics['classes']!,
                        Icons.class_,
                        Colors.green,
                      ),
                      _buildStatCard(
                        'Đang hoạt động',
                        _statistics['activeClasses']!,
                        Icons.play_circle,
                        Colors.orange,
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),

                  // Management Sections
                  const Text(
                    'Quản lý hệ thống',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),

                  _buildManagementSection(
                    'Quản lý sinh viên',
                    'Thêm, sửa, xóa sinh viên',
                    Icons.people_alt,
                    Colors.blue,
                    () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const StudentManagementScreen(),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  _buildManagementSection(
                    'Quản lý giảng viên',
                    'Thêm, sửa, xóa giảng viên',
                    Icons.co_present,
                    Colors.purple,
                    () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const InstructorManagementScreen(),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  _buildManagementSection(
                    'Quản lý lớp học',
                    'Thêm, sửa, xóa lớp học',
                    Icons.class_,
                    Colors.green,
                    () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const ClassManagementScreen(),
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Quick Actions
                  const Text(
                    'Thao tác nhanh',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),

                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            // TODO: Show system logs
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Tính năng đang phát triển'),
                              ),
                            );
                          },
                          icon: const Icon(Icons.history),
                          label: const Text('Xem logs'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey[600],
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            // TODO: Export data
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Tính năng đang phát triển'),
                              ),
                            );
                          },
                          icon: const Icon(Icons.download),
                          label: const Text('Xuất dữ liệu'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.teal,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
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

  Widget _buildStatCard(
    String title,
    int count,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 32, color: color),
          const SizedBox(height: 8),
          Text(
            count.toString(),
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildManagementSection(
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 28),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            color: Colors.grey[600],
          ),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          color: color,
          size: 16,
        ),
        onTap: onTap,
      ),
    );
  }
}