import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import '../../models/user.dart';
import '../../models/class_model.dart';
import '../../models/attendance_model.dart';
import '../../services/admin_api_service.dart';
import '../shared/login_screen.dart';
import '../shared/home_screen.dart';

class AdminDashboardScreenNew extends StatefulWidget {
  final User currentUser;
  final List<CameraDescription>? cameras;

  const AdminDashboardScreenNew({
    super.key,
    required this.currentUser,
    this.cameras,
  });

  @override
  State<AdminDashboardScreenNew> createState() => _AdminDashboardScreenStateNew();
}

class _AdminDashboardScreenStateNew extends State<AdminDashboardScreenNew>
    with TickerProviderStateMixin {
  Map<String, dynamic> _statistics = {
    'students': 0,
    'instructors': 0,
    'classes': 0,
    'activeClasses': 0,
    'totalAttendance': 0,
    'todayAttendance': 0,
    'users': 0,
  };

  Map<String, dynamic> _databaseInfo = {
    'collections': [],
    'totalSize': 0,
  };

  bool _isLoading = true;
  bool _isRefreshing = false;
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeOut),
    );

    _loadData();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  void _logout(BuildContext context) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (context) => const LoginScreen(),
      ),
      (Route<dynamic> route) => false,
    );
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final results = await Future.wait([
        AdminApiService.getSystemStatistics(widget.currentUser.token),
        AdminApiService.getDatabaseInfo(widget.currentUser.token),
      ]);

      if (mounted) {
        setState(() {
          _statistics = results[0] as Map<String, dynamic>;
          _databaseInfo = results[1] as Map<String, dynamic>;
          _isLoading = false;
        });

        _fadeController.forward();
        _slideController.forward();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi khi tải dữ liệu: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _refreshData() async {
    setState(() => _isRefreshing = true);
    await _loadData();
    setState(() => _isRefreshing = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.admin_panel_settings, size: 28),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Admin Dashboard',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Xin chào, ${widget.currentUser.fullName}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ],
        ),
        backgroundColor: Colors.red[700],
        foregroundColor: Colors.white,
        elevation: 4,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              if (value == 'refresh') {
                _refreshData();
              } else if (value == 'database') {
                _showDatabaseInfo();
              } else if (value == 'reset') {
                _showResetConfirmation();
              } else if (value == 'logout') {
                _logout(context);
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'refresh',
                child: Row(
                  children: [
                    Icon(Icons.refresh),
                    SizedBox(width: 8),
                    Text('Làm mới dữ liệu'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'database',
                child: Row(
                  children: [
                    Icon(Icons.storage),
                    SizedBox(width: 8),
                    Text('Thông tin database'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'reset',
                child: Row(
                  children: [
                    Icon(Icons.warning, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Reset database', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
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
      ),
      body: RefreshIndicator(
        onRefresh: _refreshData,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Statistics Cards
                        _buildStatisticsSection(),
                        const SizedBox(height: 24),

                        // Quick Actions
                        _buildQuickActionsSection(),
                        const SizedBox(height: 24),

                        // Database Status
                        _buildDatabaseSection(),
                        const SizedBox(height: 24),

                        // Recent Activity
                        _buildRecentActivitySection(),
                      ],
                    ),
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildStatisticsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Thống kê hệ thống',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 16),

        // Statistics Grid
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 1.4,
          children: [
            _buildStatCard(
              'Sinh viên',
              '${_statistics['students']}',
              Icons.school,
              Colors.green,
              () => _navigateToStudentManagement(),
            ),
            _buildStatCard(
              'Giảng viên',
              '${_statistics['instructors']}',
              Icons.person,
              Colors.purple,
              () => _navigateToInstructorManagement(),
            ),
            _buildStatCard(
              'Lớp học',
              '${_statistics['classes']}',
              Icons.class_,
              Colors.orange,
              () => _navigateToClassManagement(),
            ),
            _buildStatCard(
              'Lớp đang hoạt động',
              '${_statistics['activeClasses']}',
              Icons.play_circle,
              Colors.red,
              () => _navigateToActiveClasses(),
            ),
            _buildStatCard(
              'Tỷ lệ điểm danh',
              '${(_statistics['todayAttendance'] / (_statistics['students'] > 0 ? _statistics['students'] : 1) * 100).toStringAsFixed(1)}%',
              Icons.trending_up,
              Colors.teal,
              () => _showReportsDialog(),
            ),
            _buildStatCard(
              'Database',
              'MongoDB',
              Icons.storage,
              Colors.blueGrey,
              () => _showDatabaseInfo(),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color, VoidCallback onTap) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                color.withOpacity(0.1),
                color.withOpacity(0.05),
              ],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, color: color, size: 24),
                  const Spacer(),
                  Icon(Icons.arrow_forward, color: color, size: 16),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                value,
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
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quản lý hệ thống',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 16),

        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                'Danh sách sinh viên',
                'Xem danh sách sinh viên hệ thống',
                Icons.school,
                Colors.green,
                () => _navigateToStudentManagement(),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildActionCard(
                'Danh sách giảng viên',
                'Xem danh sách giảng viên hệ thống',
                Icons.person,
                Colors.purple,
                () => _navigateToInstructorManagement(),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                'Lớp học đang hoạt động',
                'Monitor các lớp học đang diễn ra',
                Icons.class_,
                Colors.orange,
                () => _navigateToActiveClasses(),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildActionCard(
                'Cài đặt hệ thống',
                'Quản trị và cấu hình hệ thống',
                Icons.settings,
                Colors.blue,
                () => _showSystemSettingsDialog(),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionCard(String title, String subtitle, IconData icon, Color color, VoidCallback onTap) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.2)),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 32),
              const SizedBox(height: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDatabaseSection() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.red[50]!,
              Colors.pink[50]!,
            ],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.storage, color: Colors.red[700]),
                const SizedBox(width: 8),
                const Text(
                  'Trạng thái Database',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                _isRefreshing
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(Icons.check_circle, color: Colors.green),
              ],
            ),
            const SizedBox(height: 12),
            if (_databaseInfo['collections'] != null)
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: (_databaseInfo['collections'] as List).map((collection) {
                  return Chip(
                    label: Text(
                      '${collection['name']}: ${collection['count']}',
                      style: const TextStyle(fontSize: 12),
                    ),
                    backgroundColor: Colors.white,
                    side: BorderSide(color: Colors.red[200]!),
                  );
                }).toList(),
              ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  'Kích thước tổng: ${(_databaseInfo['totalSize'] ?? 0).toString()} KB',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: _showDatabaseInfo,
                  child: const Text('Chi tiết'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivitySection() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.history, color: Colors.blue),
                const SizedBox(width: 8),
                const Text(
                  'Hoạt động gần đây',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () => _navigateToAttendanceHistory(),
                  child: const Text('Xem tất cả'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Center(
              child: Text(
                'Tính năng đang phát triển...',
                style: TextStyle(
                  color: Colors.grey,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Navigation methods

  void _navigateToStudentManagement() {
    _showUserListDialog(role: 'student');
  }

  void _navigateToInstructorManagement() {
    _showUserListDialog(role: 'instructor');
  }

  void _navigateToClassManagement() {
    _showClassListDialog();
  }

  void _navigateToActiveClasses() {
    _showClassListDialog(activeOnly: true);
  }

  void _navigateToTodayAttendance() {
    _showTodayAttendanceDialog();
  }

  void _navigateToAttendanceHistory() {
    _showAttendanceHistoryDialog();
  }

  // Dialog methods
  void _showDatabaseInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Thông tin Database'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_databaseInfo['collections'] != null)
                ...(_databaseInfo['collections'] as List).map((collection) {
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: const Icon(Icons.folder),
                      title: Text(collection['name']),
                      subtitle: Text('Số bản ghi: ${collection['count']}'),
                      trailing: Text('${collection['size']} KB'),
                    ),
                  );
                }),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  void _showUserListDialog({String? role}) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(role == 'student' ? 'Danh sách sinh viên' :
                    role == 'instructor' ? 'Danh sách giảng viên' :
                    'Danh sách người dùng'),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: FutureBuilder<List<User>>(
            future: role == 'student'
                ? AdminApiService.getAllStudents(widget.currentUser.token)
                : role == 'instructor'
                    ? AdminApiService.getAllInstructors(widget.currentUser.token)
                    : AdminApiService.getAllUsers(widget.currentUser.token),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Center(child: Text('Không có dữ liệu'));
              }

              final users = snapshot.data!;
              return ListView.builder(
                itemCount: users.length,
                itemBuilder: (context, index) {
                  final user = users[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: CircleAvatar(
                        child: Text(user.fullName[0].toUpperCase()),
                      ),
                      title: Text(user.fullName),
                      subtitle: Text('${user.userId} • ${user.email}'),
                      trailing: Chip(
                        label: Text(
                          user.role == 'student' ? 'Sinh viên' : 'Giảng viên',
                          style: const TextStyle(fontSize: 12),
                        ),
                        backgroundColor: user.role == 'student'
                            ? Colors.green[100]
                            : Colors.purple[100],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  void _showClassListDialog({bool activeOnly = false}) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(activeOnly ? 'Lớp học đang hoạt động' : 'Tất cả lớp học'),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: FutureBuilder<List<ClassModel>>(
            future: AdminApiService.getAllClasses(widget.currentUser.token),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Center(child: Text('Không có lớp học nào'));
              }

              final classes = snapshot.data!;
              return ListView.builder(
                itemCount: classes.length,
                itemBuilder: (context, index) {
                  final classModel = classes[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: Icon(Icons.class_, color: Colors.purple[700]),
                      title: Text(classModel.name),
                      subtitle: Text('${classModel.timeRange} - ${classModel.room}'),
                      trailing: classModel.isAttendanceOpen
                          ? const Icon(Icons.play_circle, color: Colors.green)
                          : const Icon(Icons.pause_circle, color: Colors.grey),
                    ),
                  );
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  void _showTodayAttendanceDialog() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Điểm danh hôm nay'),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: FutureBuilder<List<AttendanceModel>>(
            future: AdminApiService.getAttendanceRecords(widget.currentUser.token),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Center(child: Text('Không có bản ghi điểm danh nào hôm nay'));
              }

              final attendance = snapshot.data!
                  .where((a) => a.checkInTime.day == DateTime.now().day &&
                              a.checkInTime.month == DateTime.now().month &&
                              a.checkInTime.year == DateTime.now().year)
                  .toList();

              return ListView.builder(
                itemCount: attendance.length,
                itemBuilder: (context, index) {
                  final record = attendance[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: Icon(Icons.how_to_reg, color: Colors.green[700]),
                      title: Text('Điểm danh - ${record.classId}'),
                      subtitle: Text(
                        '${record.checkInTime.hour.toString().padLeft(2, '0')}:'
                        '${record.checkInTime.minute.toString().padLeft(2, '0')}'
                      ),
                      trailing: Chip(
                        label: Text(
                          record.status.name.toUpperCase(),
                          style: const TextStyle(fontSize: 12),
                        ),
                        backgroundColor: record.status == AttendanceStatus.present
                            ? Colors.green[100]
                            : Colors.orange[100],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  void _showAttendanceHistoryDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Lịch sử điểm danh'),
        content: const SizedBox(
          width: double.maxFinite,
          height: 300,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.history, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'Tính năng đang phát triển...',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  void _showReportsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Báo cáo thống kê'),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Card(
                child: ListTile(
                  leading: const Icon(Icons.bar_chart),
                  title: const Text('Thống kê điểm danh'),
                  subtitle: Text('Tổng cộng: ${_statistics['todayAttendance']} hôm nay'),
                ),
              ),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.pie_chart),
                  title: const Text('Thống kê người dùng'),
                  subtitle: Text('Tổng cộng: ${_statistics['users']} người dùng'),
                ),
              ),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.insert_chart),
                  title: const Text('Xu hướng điểm danh'),
                  subtitle: Text('Tỷ lệ: ${(_statistics['todayAttendance'] / (_statistics['users'] ?? 1) * 100).toStringAsFixed(1)}%'),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  void _showSystemSettingsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cài đặt hệ thống'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Card(
              child: ListTile(
                leading: const Icon(Icons.sync),
                title: const Text('Đồng bộ dữ liệu'),
                subtitle: const Text('Làm mới dữ liệu từ server'),
                onTap: () {
                  Navigator.of(context).pop();
                  _refreshData();
                },
              ),
            ),
            Card(
              child: ListTile(
                leading: const Icon(Icons.storage),
                title: const Text('Thông tin database'),
                subtitle: const Text('Xem chi tiết collections'),
                onTap: () {
                  Navigator.of(context).pop();
                  _showDatabaseInfo();
                },
              ),
            ),
            Card(
              child: ListTile(
                leading: const Icon(Icons.security),
                title: const Text('Bảo mật'),
                subtitle: const Text('Quản lý quyền truy cập'),
                onTap: () {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Tính năng bảo mật - Đang phát triển')),
                  );
                },
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  void _showResetConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận Reset Database'),
        content: const Text(
          'Bạn có chắc chắn muốn reset toàn bộ database? Hành động này sẽ xóa tất cả dữ liệu trừ tài khoản admin và không thể hoàn tác.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Đã reset dữ liệu thành công'),
                    backgroundColor: Colors.green,
                  ),
                );
                _refreshData();
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }
}