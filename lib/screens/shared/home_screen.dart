import 'package:flutter/material.dart';
import '../../models/user.dart';
import '../../services/auth_service.dart';
import '../admin/user_crud_screen.dart';
import '../admin/class_crud_screen.dart';
import '../teacher/teacher_class_management_screen.dart';
import '../student/student_dashboard_screen_new.dart';
import 'login_screen.dart';
import 'dart:developer' as developer;

class HomeScreen extends StatefulWidget {
  final User? currentUser;
  const HomeScreen({super.key, this.currentUser});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  User? _currentUser;
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    // If currentUser is passed from constructor, use it
    if (widget.currentUser != null) {
      _currentUser = widget.currentUser;
    } else {
      _loadCurrentUser();
    }
  }

  Future<void> _loadCurrentUser() async {
    try {
      final user = await _authService.getCurrentUser();
      if (mounted) {
        setState(() {
          _currentUser = user;
        });
      }
    } catch (e) {
      developer.log('Error loading current user: $e', name: 'HomeScreen.user', level: 1000);
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

  Widget _buildSimpleDashboard() {
    Color primaryColor = _currentUser?.role == 'admin'
        ? Colors.red[700]!
        : _currentUser?.role == 'instructor'
            ? Colors.purple[700]!
            : Colors.blue[700]!;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text('FaceID - ${_currentUser?.fullName ?? ""}'),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: _logout,
            tooltip: 'Đăng xuất',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: primaryColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Xin chào, ${_currentUser?.fullName ?? ""}',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Mã: ${_currentUser?.userId ?? ""} | Vai trò: ${_getRoleText(_currentUser?.role ?? "")}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Menu options
            Text(
              'Chức năng',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 16),

            Expanded(
              child: _buildMenuItems(primaryColor),
            ),
          ],
        ),
      ),
    );
  }

  String _getRoleText(String role) {
    switch (role) {
      case 'admin':
        return 'Quản trị viên';
      case 'instructor':
        return 'Giảng viên';
      case 'student':
        return 'Sinh viên';
      default:
        return 'Người dùng';
    }
  }

  Widget _buildMenuItems(Color primaryColor) {
    List<Map<String, dynamic>> menuItems = _getMenuItems();

    return ListView.builder(
      itemCount: menuItems.length,
      itemBuilder: (context, index) {
        final item = menuItems[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                item['icon'],
                color: primaryColor,
                size: 24,
              ),
            ),
            title: Text(
              item['title'],
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: Text(
              item['subtitle'],
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: item['onTap'],
          ),
        );
      },
    );
  }

  List<Map<String, dynamic>> _getMenuItems() {
    if (_currentUser?.role == 'admin') {
      return [
        {
          'title': 'Quản lý người dùng',
          'subtitle': 'Thêm, sửa, xóa tài khoản sinh viên, giảng viên',
          'icon': Icons.people,
          'onTap': () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => UserCRUDScreen(currentUser: _currentUser!),
              ),
            );
          },
        },
        {
          'title': 'Quản lý lớp học',
          'subtitle': 'Tạo và quản lý các lớp học',
          'icon': Icons.class_,
          'onTap': () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => ClassCRUDScreen(currentUser: _currentUser!),
              ),
            );
          },
        },
      ];
    } else if (_currentUser?.role == 'instructor') {
      return [
        {
          'title': 'Quản lý lớp học',
          'subtitle': 'Xem danh sách lớp và quản lý sinh viên',
          'icon': Icons.class_,
          'onTap': () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => TeacherClassManagementScreen(currentUser: _currentUser!),
              ),
            );
          },
        },
        {
          'title': 'Tạo mã điểm danh',
          'subtitle': 'Tạo mã QR hoặc mã PIN để sinh viên điểm danh',
          'icon': Icons.qr_code_scanner,
          'onTap': () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => TeacherClassManagementScreen(currentUser: _currentUser!),
              ),
            );
          },
        },
        {
          'title': 'Lịch teaching',
          'subtitle': 'Xem lịch dạy của bạn',
          'icon': Icons.schedule,
          'onTap': () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Tính năng đang phát triển')),
            );
          },
        },
        {
          'title': 'Báo cáo điểm danh',
          'subtitle': 'Xem thống kê điểm danh',
          'icon': Icons.assessment,
          'onTap': () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Tính năng đang phát triển')),
            );
          },
        },
      ];
    } else {
      return [
        {
          'title': 'Trang chủ sinh viên',
          'subtitle': 'Quản lý lớp học và điểm danh',
          'icon': Icons.dashboard,
          'onTap': () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => StudentDashboardScreenNew(currentUser: _currentUser!),
              ),
            );
          },
        },
      ];
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_currentUser == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // Use simple dashboard for all roles
    return _buildSimpleDashboard();
  }
}