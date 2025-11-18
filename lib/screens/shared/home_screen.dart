import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import '../../models/user.dart';
import '../../services/auth_service.dart';
import '../student/student_dashboard_screen.dart';
import '../teacher/teacher_dashboard_screen.dart';
import '../admin/admin_dashboard_screen_new.dart';
import '../student/face_enrollment_screen.dart';
import 'login_screen.dart';

class HomeScreen extends StatefulWidget {
  final List<CameraDescription>? cameras;
  final User? currentUser;
  const HomeScreen({super.key, this.cameras, this.currentUser});

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
      print('Error loading current user: $e');
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
            if (_currentUser!.role == 'student')
              IconButton(
                icon: const Icon(Icons.face, color: Colors.white),
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
      body: _currentUser != null
          ? _currentUser!.role == 'admin'
              ? AdminDashboardScreenNew(
                  currentUser: _currentUser!,
                  cameras: widget.cameras,
                )
              : _currentUser!.role == 'instructor'
                  ? TeacherDashboardScreen(
                      cameras: widget.cameras,
                      currentUser: _currentUser!,
                    )
                  : StudentDashboardScreen(
                      cameras: widget.cameras,
                      currentUser: _currentUser,
                    )
          : const Center(child: CircularProgressIndicator()),
    );
  }
}