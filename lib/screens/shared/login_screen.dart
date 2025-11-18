import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import '../../models/user.dart';
import '../../services/auth_service.dart';
import '../../services/admin_api_service.dart';
import '../../services/api_service.dart';
import 'home_screen.dart';
import '../admin/admin_dashboard_screen_new.dart';

class LoginScreen extends StatefulWidget {
  final List<CameraDescription>? cameras;
  const LoginScreen({super.key, this.cameras});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _userIdController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;
  String _selectedRole = 'student';

  // Admin secret login variables
  int _logoTapCount = 0;
  DateTime? _lastLogoTap;

  @override
  void dispose() {
    _userIdController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      User user;

      // Try FastAPI first, fallback to AuthService
      try {
        print('🔐 Attempting login via FastAPI...');
        final apiResult = await ApiService.login(
          _userIdController.text.trim(),
          _passwordController.text,
          _selectedRole,
        );

        if (apiResult['success'] == true) {
          user = apiResult['user'] as User;
          print('✅ Login successful via FastAPI');
        } else {
          throw Exception(apiResult['message'] ?? 'Đăng nhập thất bại');
        }
      } catch (e) {
        print('⚠️ FastAPI login failed: $e');
        print('🔄 Trying local authentication...');

        // Fallback to local auth
        await AuthService.createDemoUsers();
        final authService = AuthService();
        user = await authService.login(
          _userIdController.text.trim(),
          _passwordController.text,
          role: _selectedRole,
        );
      }

      if (mounted) {
        // Navigate to appropriate screen based on user role
        if (user.role == 'admin') {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => AdminDashboardScreenNew(cameras: widget.cameras, currentUser: user),
            ),
          );
        } else {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => HomeScreen(cameras: widget.cameras, currentUser: user),
            ),
          );
        }
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showSecretAdminLogin() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.admin_panel_settings, color: Color(0xFFf093fb)),
            SizedBox(width: 8),
            Text('Đăng nhập Admin'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: InputDecoration(
                labelText: 'Tài khoản admin',
                hintText: 'admin',
                border: OutlineInputBorder(),
              ),
              onChanged: (value) => _userIdController.text = value,
            ),
            SizedBox(height: 16),
            TextField(
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Mật khẩu',
                hintText: 'admin123',
                border: OutlineInputBorder(),
              ),
              onChanged: (value) => _passwordController.text = value,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              setState(() => _isLoading = true);

              try {
                // Try admin login via FastAPI first
                final apiResult = await ApiService.login(
                  _userIdController.text.trim(),
                  _passwordController.text,
                  'admin',
                );

                if (apiResult['success'] == true) {
                  final user = apiResult['user'] as User;
                  if (mounted) {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                        builder: (context) => AdminDashboardScreenNew(cameras: widget.cameras, currentUser: user),
                      ),
                    );
                  }
                } else {
                  // Try local admin fallback
                  await AdminApiService.initializeAdmin();
                  final adminResult = await AdminApiService.adminLogin(
                    _userIdController.text.trim(),
                    _passwordController.text,
                  );

                  if (adminResult?['success'] == true) {
                    final user = adminResult!['user'] as User;
                    if (mounted) {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                          builder: (context) => AdminDashboardScreenNew(cameras: widget.cameras, currentUser: user),
                        ),
                      );
                    }
                  } else {
                    setState(() {
                      _errorMessage = 'Đăng nhập admin thất bại';
                    });
                  }
                }
              } catch (e) {
                setState(() {
                  _errorMessage = 'Lỗi: ${e.toString()}';
                });
              } finally {
                setState(() => _isLoading = false);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFFf093fb),
              foregroundColor: Colors.white,
            ),
            child: Text('Đăng nhập'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF667eea),
              Color(0xFF764ba2),
              Color(0xFFf093fb),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Logo Section
                    GestureDetector(
                      onTap: () {
                        // Admin secret login - tap logo 5 times quickly
                        final now = DateTime.now();
                        if (_lastLogoTap != null &&
                            now.difference(_lastLogoTap!).inMilliseconds < 500) {
                          _logoTapCount++;
                          if (_logoTapCount >= 5) {
                            _showSecretAdminLogin();
                            _logoTapCount = 0;
                          }
                        } else {
                          _logoTapCount = 1;
                        }
                        _lastLogoTap = now;
                      },
                      child: Container(
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.face_retouching_natural,
                            size: 60,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Title
                    const Text(
                      'FaceID\nAttendance',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Hệ thống điểm danh thông minh',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white70,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    const SizedBox(height: 48),

                    // Login Card
                    Container(
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Login Header
                          const Text(
                            'Chào mừng trở lại! 👋',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1a1a1a),
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Vui lòng đăng nhập để tiếp tục',
                            style: TextStyle(
                              fontSize: 14,
                              color: Color(0xFF666666),
                            ),
                          ),
                          const SizedBox(height: 32),

                          // Role Selection
                          const Text(
                            'Chọn vai trò',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1a1a1a),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Container(
                            decoration: BoxDecoration(
                              color: Color(0xFFF5F5F5),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Color(0xFFE0E0E0)),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () => setState(() => _selectedRole = 'student'),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(vertical: 16),
                                      decoration: BoxDecoration(
                                        color: _selectedRole == 'student'
                                            ? Colors.white
                                            : Colors.transparent,
                                        borderRadius: const BorderRadius.only(
                                          topLeft: Radius.circular(16),
                                          bottomLeft: Radius.circular(16),
                                        ),
                                        boxShadow: _selectedRole == 'student'
                                            ? [
                                                BoxShadow(
                                                  color: Colors.blue.withOpacity(0.2),
                                                  blurRadius: 8,
                                                  offset: const Offset(0, 2),
                                                ),
                                              ]
                                            : [],
                                      ),
                                      child: Column(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(12),
                                            decoration: BoxDecoration(
                                              color: _selectedRole == 'student'
                                                  ? Color(0xFF667eea).withOpacity(0.1)
                                                  : Colors.transparent,
                                              shape: BoxShape.circle,
                                            ),
                                            child: Icon(
                                              Icons.school,
                                              size: 24,
                                              color: _selectedRole == 'student'
                                                  ? Color(0xFF667eea)
                                                  : Color(0xFF999999),
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            'Sinh viên',
                                            style: TextStyle(
                                              color: _selectedRole == 'student'
                                                  ? Color(0xFF667eea)
                                                  : Color(0xFF999999),
                                              fontWeight: FontWeight.w600,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () => setState(() => _selectedRole = 'instructor'),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(vertical: 16),
                                      decoration: BoxDecoration(
                                        color: _selectedRole == 'instructor'
                                            ? Colors.white
                                            : Colors.transparent,
                                        boxShadow: _selectedRole == 'instructor'
                                            ? [
                                                BoxShadow(
                                                  color: Colors.purple.withOpacity(0.2),
                                                  blurRadius: 8,
                                                  offset: const Offset(0, 2),
                                                ),
                                              ]
                                            : [],
                                      ),
                                      child: Column(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(12),
                                            decoration: BoxDecoration(
                                              color: _selectedRole == 'instructor'
                                                  ? Color(0xFF764ba2).withOpacity(0.1)
                                                  : Colors.transparent,
                                              shape: BoxShape.circle,
                                            ),
                                            child: Icon(
                                              Icons.person,
                                              size: 24,
                                              color: _selectedRole == 'instructor'
                                                  ? Color(0xFF764ba2)
                                                  : Color(0xFF999999),
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            'Giảng viên',
                                            style: TextStyle(
                                              color: _selectedRole == 'instructor'
                                                  ? Color(0xFF764ba2)
                                                  : Color(0xFF999999),
                                              fontWeight: FontWeight.w600,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),

                          // User ID Field
                          Text(
                            _selectedRole == 'student'
                                ? 'Mã sinh viên'
                                : 'Mã giảng viên',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1a1a1a),
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _userIdController,
                            decoration: InputDecoration(
                              prefixIcon: Container(
                                padding: const EdgeInsets.all(12),
                                child: Icon(
                                  _selectedRole == 'student'
                                      ? Icons.school
                                      : Icons.person,
                                  color: Color(0xFF667eea),
                                  size: 20,
                                ),
                              ),
                              hintText: _selectedRole == 'student'
                                  ? 'Ví dụ: SV001'
                                  : 'Ví dụ: GV001',
                              hintStyle: const TextStyle(color: Color(0xFF999999)),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Color(0xFF667eea), width: 2),
                              ),
                              errorBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.red.shade400, width: 2),
                              ),
                              filled: true,
                              fillColor: Color(0xFFF8F8F8),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 16,
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Vui lòng nhập mã đăng nhập';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),

                          // Password Field
                          const Text(
                            'Mật khẩu',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1a1a1a),
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            decoration: InputDecoration(
                              prefixIcon: Container(
                                padding: const EdgeInsets.all(12),
                                child: const Icon(
                                  Icons.lock,
                                  color: Color(0xFF667eea),
                                  size: 20,
                                ),
                              ),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                  color: Color(0xFF999999),
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscurePassword = !_obscurePassword;
                                  });
                                },
                              ),
                              hintText: 'Nhập mật khẩu',
                              hintStyle: const TextStyle(color: Color(0xFF999999)),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Color(0xFF667eea), width: 2),
                              ),
                              errorBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.red.shade400, width: 2),
                              ),
                              filled: true,
                              fillColor: Color(0xFFF8F8F8),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 16,
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Vui lòng nhập mật khẩu';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 24),

                          // Error Message
                          if (_errorMessage != null)
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.red.shade50,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.red.shade200),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.error_outline, color: Colors.red.shade600, size: 20),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      _errorMessage!,
                                      style: TextStyle(
                                        color: Colors.red.shade600,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          if (_errorMessage != null) const SizedBox(height: 24),

                          // Login Button
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _login,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _selectedRole == 'admin'
                                    ? Color(0xFFf093fb)
                                    : _selectedRole == 'instructor'
                                        ? Color(0xFF764ba2)
                                        : Color(0xFF667eea),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                elevation: 0,
                                shadowColor: Colors.transparent,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                      height: 24,
                                      width: 24,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 3,
                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                      ),
                                    )
                                  : Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        const Icon(Icons.login_rounded, size: 20),
                                        const SizedBox(width: 8),
                                        const Text(
                                          'ĐĂNG NHẬP',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                            ),
                          ),
                          const SizedBox(height: 32),

                          // Help Section
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Color(0xFF667eea).withOpacity(0.1), Color(0xFF764ba2).withOpacity(0.1)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Color(0xFF667eea).withOpacity(0.2)),
                            ),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Color(0xFF667eea).withOpacity(0.2),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.info_outline,
                                        size: 16,
                                        color: Color(0xFF667eea),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    const Text(
                                      'Tài khoản demo',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF1a1a1a),
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                const Text(
                                  'Sử dụng tài khoản sinh viên hoặc giảng viên để kiểm thử',
                                  style: TextStyle(
                                    color: Color(0xFF666666),
                                    fontSize: 14,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: Colors.blue.withOpacity(0.3)),
                                      ),
                                      child: const Text(
                                        'SV001/123456',
                                        style: TextStyle(
                                          color: Colors.blue,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: Colors.purple.withOpacity(0.3)),
                                      ),
                                      child: const Text(
                                        'GV001/123456',
                                        style: TextStyle(
                                          color: Colors.purple,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 48),

                    // Footer
                    Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white.withOpacity(0.2)),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.security, color: Colors.white70, size: 16),
                              SizedBox(width: 8),
                              Text(
                                'Bảo mật & An toàn',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          '© 2024 FaceID Attendance System',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.6),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}