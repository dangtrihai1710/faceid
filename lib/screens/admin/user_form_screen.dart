import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/user.dart';
import '../../services/api_service.dart';

class UserFormScreen extends StatefulWidget {
  final User? user;

  const UserFormScreen({
    super.key,
    this.user,
  });

  @override
  State<UserFormScreen> createState() => _UserFormScreenState();
}

class _UserFormScreenState extends State<UserFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _userIdController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _academicClassController = TextEditingController();
  final List<String> _subjectClassIds = [];

  String _selectedRole = 'student';
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void initState() {
    super.initState();
    if (widget.user != null) {
      _populateForm();
    }
  }

  void _populateForm() {
    final user = widget.user!;
    _userIdController.text = user.userId;
    _fullNameController.text = user.fullName;
    _emailController.text = user.email;
    _selectedRole = user.role;
    _academicClassController.text = user.academicClassId ?? '';

    if (user.subjectClassIds != null) {
      _subjectClassIds.addAll(user.subjectClassIds!);
    }
  }

  @override
  void dispose() {
    _userIdController.dispose();
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _academicClassController.dispose();
    super.dispose();
  }

  bool _isEditing() => widget.user != null;

  String _getUserIdHint() {
    switch (_selectedRole) {
      case 'instructor':
        return 'GV001, GV002...';
      case 'student':
        return 'SV001, SV002...';
      case 'admin':
        return 'AD001, AD002...';
      default:
        return 'Nhập mã số người dùng';
    }
  }

  String _getUserIdHelperText() {
    switch (_selectedRole) {
      case 'instructor':
        return 'Mã giảng viên phải bắt đầu bằng "GV"';
      case 'student':
        return 'Mã sinh viên phải bắt đầu bằng "SV"';
      case 'admin':
        return 'Mã admin phải bắt đầu bằng "AD"';
      default:
        return '';
    }
  }

  Future<void> _saveUser() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Password validation for new users or when password is provided
    if (!_isEditing() || _passwordController.text.isNotEmpty) {
      if (_passwordController.text != _confirmPasswordController.text) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Mật khẩu xác nhận không khớp'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      if (_passwordController.text.length < 6) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Mật khẩu phải có ít nhất 6 ký tự'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }

    setState(() {
      _isLoading = true;
    });

    try {
      Map<String, dynamic> result;

      if (_isEditing()) {
        // Update existing user
        result = await ApiService.updateUser(
          ApiService.getToken(),
          widget.user!.id,
          {
            'email': _emailController.text.trim(),
            'full_name': _fullNameController.text.trim(),
            'role': _selectedRole,
            'academic_class_id': _academicClassController.text.trim().isNotEmpty
                ? _academicClassController.text.trim()
                : null,
            'subject_class_ids': _subjectClassIds.isNotEmpty ? _subjectClassIds : null,
            if (_passwordController.text.isNotEmpty) 'password': _passwordController.text,
          },
        );
      } else {
        // Create new user
        result = await ApiService.createUser(
          ApiService.getToken(),
          {
            'user_id': _userIdController.text.trim(),
            'email': _emailController.text.trim(),
            'full_name': _fullNameController.text.trim(),
            'password': _passwordController.text,
            'role': _selectedRole,
            'academic_class_id': _academicClassController.text.trim().isNotEmpty
                ? _academicClassController.text.trim()
                : null,
            'subject_class_ids': _subjectClassIds.isNotEmpty ? _subjectClassIds : null,
          },
        );
      }

      if (mounted) {
        if (result['success'] == true) {
          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(_isEditing() ? 'Cập nhật người dùng thành công' : 'Tạo người dùng thành công'),
              backgroundColor: Colors.green,
            ),
          );

          Navigator.of(context).pop(true); // Return true to indicate success
        } else {
          // Show error message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Lỗi khi lưu người dùng'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _addSubjectClass() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        final controller = TextEditingController();
        return AlertDialog(
          title: const Text('Thêm lớp môn học'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              hintText: 'Nhập mã lớp môn học (ví dụ: LAP101)',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: () {
                final value = controller.text.trim();
                if (value.isNotEmpty && !_subjectClassIds.contains(value)) {
                  setState(() {
                    _subjectClassIds.add(value);
                  });
                }
                Navigator.of(context).pop();
              },
              child: const Text('Thêm'),
            ),
          ],
        );
      },
    );
  }

  void _removeSubjectClass(String classId) {
    setState(() {
      _subjectClassIds.remove(classId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing() ? 'Sửa người dùng' : 'Thêm người dùng mới'),
        backgroundColor: const Color(0xFF2196F3),
        foregroundColor: Colors.white,
        actions: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // User ID
              TextFormField(
                controller: _userIdController,
                decoration: InputDecoration(
                  labelText: 'Mã số người dùng',
                  hintText: _getUserIdHint(),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.person),
                  helperText: _getUserIdHelperText(),
                  enabled: !_isEditing(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Vui lòng nhập mã số người dùng';
                  }

                  // Validate user ID format based on role
                  if (_selectedRole == 'instructor' && !value.toUpperCase().startsWith('GV')) {
                    return 'Mã giảng viên phải bắt đầu bằng "GV"';
                  }
                  if (_selectedRole == 'student' && !value.toUpperCase().startsWith('SV')) {
                    return 'Mã sinh viên phải bắt đầu bằng "SV"';
                  }
                  if (_selectedRole == 'admin' && !value.toUpperCase().startsWith('AD')) {
                    return 'Mã admin phải bắt đầu bằng "AD"';
                  }

                  return null;
                },
                inputFormatters: [
                  FilteringTextInputFormatter.deny(RegExp(r'\s')),
                  UpperCaseTextFormatter(), // Convert to uppercase
                ],
                onChanged: (value) {
                  setState(() {});
                },
              ),
              const SizedBox(height: 16),

              // Full Name
              TextFormField(
                controller: _fullNameController,
                decoration: InputDecoration(
                  labelText: 'Họ và tên',
                  hintText: 'Nhập họ và tên đầy đủ',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.badge),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Vui lòng nhập họ và tên';
                  }
                  if (value.trim().length < 2) {
                    return 'Họ và tên phải có ít nhất 2 ký tự';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Email
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: 'Email',
                  hintText: 'user@example.com',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.email),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Vui lòng nhập email';
                  }
                  if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                    return 'Email không hợp lệ';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Password
              if (!_isEditing() || _passwordController.text.isNotEmpty)
                TextFormField(
                  controller: _passwordController,
                  decoration: InputDecoration(
                    labelText: _isEditing() ? 'Mật khẩu mới (để trống nếu không đổi)' : 'Mật khẩu',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    prefixIcon: const Icon(Icons.lock),
                    suffixIcon: IconButton(
                      icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                  ),
                  obscureText: _obscurePassword,
                  validator: (value) {
                    if (!_isEditing() && (value == null || value.isEmpty)) {
                      return 'Vui lòng nhập mật khẩu';
                    }
                    if (value != null && value.isNotEmpty && value.length < 6) {
                      return 'Mật khẩu phải có ít nhất 6 ký tự';
                    }
                    return null;
                  },
                ),
              const SizedBox(height: 16),

              // Confirm Password
              if (!_isEditing() || _passwordController.text.isNotEmpty)
                TextFormField(
                  controller: _confirmPasswordController,
                  decoration: InputDecoration(
                    labelText: 'Xác nhận mật khẩu',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(_obscureConfirmPassword ? Icons.visibility_off : Icons.visibility),
                      onPressed: () {
                        setState(() {
                          _obscureConfirmPassword = !_obscureConfirmPassword;
                        });
                      },
                    ),
                  ),
                  obscureText: _obscureConfirmPassword,
                  validator: (value) {
                    if (!_isEditing() && (value == null || value.isEmpty)) {
                      return 'Vui lòng xác nhận mật khẩu';
                    }
                    return null;
                  },
                ),
              const SizedBox(height: 16),

              // Role
              DropdownButtonFormField<String>(
initialValue: _selectedRole,
                decoration: InputDecoration(
                  labelText: 'Vai trò',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.admin_panel_settings),
                ),
                items: const [
                  DropdownMenuItem(value: 'student', child: Text('Sinh viên')),
                  DropdownMenuItem(value: 'instructor', child: Text('Giảng viên')),
                  DropdownMenuItem(value: 'admin', child: Text('Admin')),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedRole = value!;
                  });
                },
              ),
              const SizedBox(height: 16),

              // Academic Class (for students)
              if (_selectedRole == 'student')
                TextFormField(
                  controller: _academicClassController,
                  decoration: InputDecoration(
                    labelText: 'Lớp theo khóa học',
                    hintText: 'VD: 25ABC1, 25ABC2',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    prefixIcon: const Icon(Icons.class_),
                    helperText: 'Định dạng: NămKhóaLớpSốThứ (ví dụ: 25ABC1)',
                  ),
                ),
              const SizedBox(height: 16),

              // Subject Classes (for instructors)
              if (_selectedRole == 'instructor') ...[
                const Text(
                  'Các lớp môn học giảng dạy:',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 8),
                if (_subjectClassIds.isNotEmpty)
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _subjectClassIds.map((classId) {
                      return Chip(
                        label: Text(classId),
                        onDeleted: () => _removeSubjectClass(classId),
                        deleteIcon: const Icon(Icons.close, size: 18),
                        backgroundColor: Colors.blue.withValues(alpha: 0.1),
                      );
                    }).toList(),
                  ),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  onPressed: _addSubjectClass,
                  icon: const Icon(Icons.add),
                  label: const Text('Thêm lớp môn học'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.withValues(alpha: 0.1),
                    foregroundColor: Colors.blue,
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Save Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveUser,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2196F3),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                  child: Text(
                    _isLoading ? 'Đang lưu...' : (_isEditing() ? 'Cập nhật' : 'Thêm mới'),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Custom TextInputFormatter to convert text to uppercase
class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return TextEditingValue(
      text: newValue.text.toUpperCase(),
      selection: newValue.selection,
    );
  }
}