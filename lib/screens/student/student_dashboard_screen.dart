import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import '../../models/user.dart';
import '../student/qr_scanner_screen.dart';
import '../student/schedule_screen.dart';
import '../student/attendance_history_screen.dart';
import '../student/profile_screen.dart';
import '../shared/login_screen.dart';
import 'face_scan_screen.dart';
import 'class_list_screen.dart';

class StudentDashboardScreen extends StatefulWidget {
  final List<CameraDescription>? cameras;
  final User? currentUser;

  const StudentDashboardScreen({
    super.key,
    this.cameras,
    this.currentUser,
  });

  @override
  State<StudentDashboardScreen> createState() => _StudentDashboardScreenState();
}

class _StudentDashboardScreenState extends State<StudentDashboardScreen> {
  void _logout(BuildContext context) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (context) => LoginScreen(cameras: widget.cameras),
      ),
      (Route<dynamic> route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Trang sinh viên'),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _logout(context),
            tooltip: 'Đăng xuất',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Chào mừng, ${widget.currentUser?.fullName ?? 'Sinh viên'}!',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),

            // Grid of action buttons
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 1.2,
                children: [
                  _buildActionCard(
                    context,
                    'Điểm danh',
                    'Quét mặt hoặc QR',
                    Icons.fingerprint,
                    Colors.green,
                    () => _showAttendanceOptions(context),
                  ),
                  _buildActionCard(
                    context,
                    'Thời khóa biểu',
                    'Xem lịch học theo tuần',
                    Icons.calendar_month,
                    Colors.blue,
                    () {
                      if (widget.currentUser != null) {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => ScheduleScreen(currentUser: widget.currentUser!),
                          ),
                        );
                      }
                    },
                  ),
                  _buildActionCard(
                    context,
                    'Lịch học',
                    'Danh sách môn học',
                    Icons.schedule,
                    Colors.orange,
                    () {
                      if (widget.currentUser != null) {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => ClassListScreen(currentUser: widget.currentUser!),
                          ),
                        );
                      }
                    },
                  ),
                  _buildActionCard(
                    context,
                    'Hồ sơ',
                    'Thông tin cá nhân',
                    Icons.person,
                    Colors.purple,
                    () {
                      if (widget.currentUser != null) {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => ProfileScreen(currentUser: widget.currentUser!),
                          ),
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: color.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: color,
              size: 48,
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: color.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _showAttendanceOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Chọn phương thức điểm danh',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: _buildAttendanceOption(
                    context,
                    'Quét mặt',
                    'Sử dụng nhận diện khuôn mặt',
                    Icons.face,
                    Colors.blue,
                    () {
                      Navigator.of(context).pop();
                      if (widget.currentUser != null) {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => FaceScanScreen(
                              currentUser: widget.currentUser!,
                              cameras: widget.cameras,
                            ),
                          ),
                        );
                      }
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildAttendanceOption(
                    context,
                    'Quét QR',
                    'Quét mã QR điểm danh',
                    Icons.qr_code_2,
                    Colors.green,
                    () {
                      Navigator.of(context).pop();
                      if (widget.currentUser != null) {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => QRScannerScreen(
                              currentUser: widget.currentUser!,
                            ),
                          ),
                        );
                      }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildAttendanceOption(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: color.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: color,
              size: 48,
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: color.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}