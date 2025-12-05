import 'package:flutter/material.dart';
import '../../models/user.dart';
import '../login/login_screen_api.dart';
import '../../core/services/api_service.dart' as CoreApi;

class TeacherProfileScreen extends StatefulWidget {
   final User currentUser;
   final bool showAsTab;

   const TeacherProfileScreen({
     super.key,
     required this.currentUser,
     this.showAsTab = false,
   });

  @override
  State<TeacherProfileScreen> createState() => _TeacherProfileScreenState();
}

class _TeacherProfileScreenState extends State<TeacherProfileScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late TabController _tabController;

  bool _isEditing = false;
  bool _isSaving = false;
  Map<String, dynamic> _profileStats = {
    'totalClasses': 0,
    'totalStudents': 0,
    'totalSessions': 0,
    'completedSessions': 0,
  };
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeControllers();
    _initializeTabs();
    _loadProfileStats();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeOut));

    _animationController.forward();
  }

  void _initializeTabs() {
    _tabController = TabController(length: 2, vsync: this);
  }

  void _initializeControllers() {
    _fullNameController.text = widget.currentUser.fullName;
    _emailController.text = widget.currentUser.email;
    _phoneController.text = widget.currentUser.phone ?? '';
  }

  @override
  void dispose() {
    _animationController.dispose();
    _tabController.dispose();
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _loadProfileStats() async {
    try {
      final statsResponse = await CoreApi.ApiService.getTeacherStatistics(widget.currentUser.userId);

      if (statsResponse != null && statsResponse['success'] == true) {
        final statsData = statsResponse['data'] ?? {};
        if (mounted) {
          setState(() {
            _profileStats = {
              'totalClasses': statsData['total_classes'] ?? 0,
              'totalStudents': statsData['total_students'] ?? 0,
              'totalSessions': statsData['total_sessions'] ?? 0,
              'completedSessions': statsData['completed_sessions'] ?? 0,
            };
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading profile stats: $e');
      // Keep default values
    }
  }

  void _logout(BuildContext context) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (context) => const LoginScreenApi(),
      ),
      (Route<dynamic> route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final content = FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Column(
          children: [
            if (!widget.showAsTab) ...[
              // Show app bar and tabs only when not used as tab
              Container(
                color: Colors.purple[700],
                child: SafeArea(
                  bottom: false,
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Row(
                          children: [
                            const Text(
                              'Hồ sơ cá nhân',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Spacer(),
                            if (_isSaving)
                              const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            else
                              IconButton(
                                icon: Icon(_isEditing ? Icons.save : Icons.edit),
                                tooltip: _isEditing ? 'Lưu thay đổi' : 'Chỉnh sửa hồ sơ',
                                color: Colors.white,
                                onPressed: () {
                                  setState(() {
                                    _isEditing = !_isEditing;
                                  });
                                  if (!_isEditing) {
                                    _saveProfile();
                                  }
                                },
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ] else ...[
              // When used as tab, show minimal header with just save button
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                color: Colors.transparent,
                child: Row(
                  children: [
                    const Spacer(),
                    if (_isSaving)
                      const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.grey),
                        ),
                      )
                    else
                      IconButton(
                        icon: Icon(_isEditing ? Icons.save : Icons.edit),
                        tooltip: _isEditing ? 'Lưu thay đổi' : 'Chỉnh sửa hồ sơ',
                        color: Colors.grey[700],
                        onPressed: () {
                          setState(() {
                            _isEditing = !_isEditing;
                          });
                          if (!_isEditing) {
                            _saveProfile();
                          }
                        },
                      ),
                  ],
                ),
              ),
            ],
            // Main content without tabs
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildProfileHeader(),
                    const SizedBox(height: 24),
                    _buildProfileForm(),
                    const SizedBox(height: 24),
                    _buildStatisticsCards(),
                    const SizedBox(height: 24),
                    _buildPasswordChangeSection(),
                    const SizedBox(height: 24),
                    _buildSettingsSection(),
                    const SizedBox(height: 24),
                    _buildLogoutButton(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );

    // Return content with or without Scaffold based on showAsTab
    if (widget.showAsTab) {
      return content;
    } else {
      return Scaffold(
        backgroundColor: Colors.grey[50],
        body: content,
      );
    }
  }

  Widget _buildProfileHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.purple[600]!,
            Colors.purple[800]!,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.purple.withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: 60,
                backgroundColor: Colors.white.withValues(alpha: 0.2),
                child: Text(
                  widget.currentUser.fullName.isNotEmpty
                      ? widget.currentUser.fullName[0].toUpperCase()
                      : 'G',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: const Icon(
                    Icons.check,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            widget.currentUser.fullName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'Giảng viên',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.9),
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Mã GV: ${widget.currentUser.userId}',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileForm() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Thông tin cá nhân',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 20),
            _buildTextField(
              'Họ và tên',
              _fullNameController,
              Icons.person,
              enabled: _isEditing,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              'Email',
              _emailController,
              Icons.email,
              enabled: _isEditing,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              'Số điện thoại',
              _phoneController,
              Icons.phone,
              enabled: _isEditing,
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 16),
            _buildInfoRow('Mã định danh', widget.currentUser.userId, Icons.badge),
            _buildInfoRow('Vai trò', 'Giảng viên', Icons.work),
            _buildInfoRow('Ngày tham gia',
                widget.currentUser.createdAt.toString().substring(0, 10),
                Icons.calendar_today),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller,
    IconData icon, {
    bool enabled = true,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      enabled: enabled,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.purple[600]),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.purple[600]!, width: 2),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[200]!),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Container(
            constraints: const BoxConstraints(minWidth: 100),
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatisticsCards() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Thống kê',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Lớp học',
                _profileStats['totalClasses'].toString(),
                Icons.class_,
                Colors.blue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Sinh viên',
                _profileStats['totalStudents'].toString(),
                Icons.people,
                Colors.green,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Buổi học',
                _profileStats['totalSessions'].toString(),
                Icons.event,
                Colors.orange,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Hoàn thành',
                _profileStats['completedSessions'].toString(),
                Icons.check_circle,
                Colors.purple,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              color: color.withValues(alpha: 0.8),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsSection() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          _buildSettingItem(
            'Thông báo',
            Icons.notifications,
            Colors.orange,
            () => _showNotificationSettings(),
          ),
          _buildDivider(),
          _buildSettingItem(
            'Bảo mật',
            Icons.security,
            Colors.red,
            () => _showPrivacySettings(),
          ),
        ],
      ),
    );
  }

  Widget _buildPasswordChangeSection() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.lock,
                    color: Colors.blue,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Đổi mật khẩu',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                        ),
                      ),
                      Text(
                        'Cập nhật mật khẩu để bảo mật tài khoản',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _showChangePasswordDialog(),
                icon: const Icon(Icons.lock_outline),
                label: const Text('Thay đổi mật khẩu'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingItem(
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: color, size: 24),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 16,
        ),
      ),
      trailing: Icon(Icons.chevron_right, color: Colors.grey[400]),
      onTap: onTap,
    );
  }

  Widget _buildDivider() {
    return Padding(
      padding: const EdgeInsets.only(left: 72),
      child: Divider(height: 1, color: Colors.grey[200]),
    );
  }

  Widget _buildLogoutButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () => _showLogoutDialog(),
        icon: const Icon(Icons.logout),
        label: const Text('Đăng xuất'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
        ),
      ),
    );
  }

  void _saveProfile() async {
    // Validate input
    if (_fullNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng nhập họ và tên'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_emailController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng nhập email'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Email validation
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(_emailController.text.trim())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Email không hợp lệ'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      // Prepare profile data
      final profileData = {
        'full_name': _fullNameController.text.trim(),
        'email': _emailController.text.trim(),
        'phone': _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
      };

      // Call API to update profile
      final response = await CoreApi.ApiService.updateUserProfile(widget.currentUser.userId, profileData);

      if (response != null && response['success'] == true) {
        // Update local user data if needed
        // Note: In a real app, you might want to update the user object or refresh from server

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Cập nhật hồ sơ thành công!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        throw Exception(response?['message'] ?? 'Failed to update profile');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi cập nhật hồ sơ: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  void _showChangePasswordDialog() {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    bool isChanging = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Đổi mật khẩu'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: currentPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Mật khẩu hiện tại',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: newPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Mật khẩu mới',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: confirmPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Xác nhận mật khẩu mới',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Hủy'),
            ),
            if (isChanging)
              const CircularProgressIndicator()
            else
              ElevatedButton(
                onPressed: () async {
                  // Validate inputs
                  if (currentPasswordController.text.isEmpty ||
                      newPasswordController.text.isEmpty ||
                      confirmPasswordController.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Vui lòng điền đầy đủ thông tin'),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }

                  if (newPasswordController.text != confirmPasswordController.text) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Mật khẩu xác nhận không khớp'),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }

                  if (newPasswordController.text.length < 6) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Mật khẩu mới phải có ít nhất 6 ký tự'),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }

                  setState(() {
                    isChanging = true;
                  });

                  try {
                    final passwordData = {
                      'current_password': currentPasswordController.text,
                      'new_password': newPasswordController.text,
                    };

                    final response = await CoreApi.ApiService.changePassword(widget.currentUser.userId, passwordData);

                    if (response != null && response['success'] == true) {
                      Navigator.of(context).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Đổi mật khẩu thành công!'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    } else {
                      throw Exception(response?['message'] ?? 'Failed to change password');
                    }
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Lỗi đổi mật khẩu: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  } finally {
                    setState(() {
                      isChanging = false;
                    });
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                child: const Text('Đổi mật khẩu'),
              ),
          ],
        ),
      ),
    );
  }

  void _showNotificationSettings() {
    bool pushNotifications = true;
    bool emailNotifications = false;
    bool attendanceReminders = true;
    bool classUpdates = true;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Cài đặt thông báo'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SwitchListTile(
                title: const Text('Thông báo đẩy'),
                subtitle: const Text('Nhận thông báo trên thiết bị'),
                value: pushNotifications,
                onChanged: (value) {
                  setState(() => pushNotifications = value);
                },
              ),
              SwitchListTile(
                title: const Text('Email thông báo'),
                subtitle: const Text('Nhận thông báo qua email'),
                value: emailNotifications,
                onChanged: (value) {
                  setState(() => emailNotifications = value);
                },
              ),
              SwitchListTile(
                title: const Text('Nhắc nhở điểm danh'),
                subtitle: const Text('Thông báo khi đến giờ điểm danh'),
                value: attendanceReminders,
                onChanged: (value) {
                  setState(() => attendanceReminders = value);
                },
              ),
              SwitchListTile(
                title: const Text('Cập nhật lớp học'),
                subtitle: const Text('Thông báo thay đổi lịch học'),
                value: classUpdates,
                onChanged: (value) {
                  setState(() => classUpdates = value);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  // TODO: Implement API call to save notification settings
                  // final settings = {
                  //   'push_notifications': pushNotifications,
                  //   'email_notifications': emailNotifications,
                  //   'attendance_reminders': attendanceReminders,
                  //   'class_updates': classUpdates,
                  // };
                  // await CoreApi.ApiService.updateNotificationSettings(widget.currentUser.userId, settings);

                  if (mounted) {
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Đã lưu cài đặt thông báo'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Lỗi lưu cài đặt: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              child: const Text('Lưu'),
            ),
          ],
        ),
      ),
    );
  }

  void _showPrivacySettings() {
    bool biometricLogin = false;
    bool autoLogout = true;
    int autoLogoutMinutes = 30;
    bool dataSharing = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Cài đặt bảo mật'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SwitchListTile(
                  title: const Text('Đăng nhập sinh trắc học'),
                  subtitle: const Text('Sử dụng vân tay/khuôn mặt'),
                  value: biometricLogin,
                  onChanged: (value) {
                    setState(() => biometricLogin = value);
                  },
                ),
                SwitchListTile(
                  title: const Text('Tự động đăng xuất'),
                  subtitle: const Text('Đăng xuất khi không hoạt động'),
                  value: autoLogout,
                  onChanged: (value) {
                    setState(() => autoLogout = value);
                  },
                ),
                if (autoLogout) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Text('Thời gian: '),
                      Expanded(
                        child: DropdownButton<int>(
                          value: autoLogoutMinutes,
                          items: [15, 30, 60, 120].map((minutes) {
                            return DropdownMenuItem(
                              value: minutes,
                              child: Text('$minutes phút'),
                            );
                          }).toList(),
                          onChanged: (value) {
                            if (value != null) {
                              setState(() => autoLogoutMinutes = value);
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ],
                const Divider(),
                SwitchListTile(
                  title: const Text('Chia sẻ dữ liệu'),
                  subtitle: const Text('Cho phép chia sẻ dữ liệu học tập'),
                  value: dataSharing,
                  onChanged: (value) {
                    setState(() => dataSharing = value);
                  },
                ),
                const SizedBox(height: 8),
                const Text(
                  'Dữ liệu của bạn được mã hóa và bảo mật theo tiêu chuẩn quốc tế.',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  // TODO: Implement API call to save privacy settings
                  // final settings = {
                  //   'biometric_login': biometricLogin,
                  //   'auto_logout': autoLogout,
                  //   'auto_logout_minutes': autoLogoutMinutes,
                  //   'data_sharing': dataSharing,
                  // };
                  // await CoreApi.ApiService.updatePrivacySettings(widget.currentUser.userId, settings);

                  if (mounted) {
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Đã lưu cài đặt bảo mật'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Lỗi lưu cài đặt: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              child: const Text('Lưu'),
            ),
          ],
        ),
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận đăng xuất'),
        content: const Text('Bạn có chắc chắn muốn đăng xuất?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _logout(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Đăng xuất'),
          ),
        ],
      ),
    );
  }
}