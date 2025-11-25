import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/user.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../models/class_model.dart';

class UserManagementScreen extends StatefulWidget {
  final User currentUser;

  const UserManagementScreen({
    super.key,
    required this.currentUser,
  });

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<User> _users = [];
  List<User> _filteredUsers = [];
  bool _isLoading = true;
  String _selectedRole = 'Tất cả';
  String _selectedStatus = 'Tất cả';
  int _currentPage = 1;
  int _usersPerPage = 10;
  List<User> _selectedUsers = [];
  bool _isSelecting = false;

  @override
  void initState() {
    super.initState();
    _loadUsers();
    _searchController.addListener(_filterUsers);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    try {
      setState(() => _isLoading = true);

      final token = ApiService.getToken();
      if (token.isEmpty) {
        throw Exception('No authentication token');
      }

      // Get users from API
      final usersResult = await ApiService.getAllUsers(token);

      if (usersResult['success'] == true) {
        final usersData = usersResult['accounts'] as List;
        setState(() {
          _users = usersData.map((data) {
            if (data is Map<String, dynamic>) {
              return User.fromJson(data);
            } else {
              // Handle case where API returns user objects directly
              return data as User;
            }
          }).toList();
          _filteredUsers = List.from(_users);
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
        _showErrorSnackbar('Không thể tải danh sách người dùng: ${usersResult['message']}');
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorSnackbar('Không thể tải danh sách người dùng: $e');
    }
  }

  void _filterUsers() {
    setState(() {
      _filteredUsers = _users.where((user) {
        final matchesSearch = user.fullName.toLowerCase().contains(_searchController.text.toLowerCase()) ||
                            user.email.toLowerCase().contains(_searchController.text.toLowerCase()) ||
                            user.userId.toLowerCase().contains(_searchController.text.toLowerCase());

        final matchesRole = _selectedRole == 'Tất cả' || user.role == _selectedRole;
        final matchesStatus = _selectedStatus == 'Tất cả' ||
                              (_selectedStatus == 'Hoạt động' && user.isActive) ||
                              (_selectedStatus == 'Không hoạt động' && !user.isActive);

        return matchesSearch && matchesRole && matchesStatus;
      }).toList();
      _currentPage = 1;
    });
  }

  List<User> get _paginatedUsers {
    final startIndex = (_currentPage - 1) * _usersPerPage;
    final endIndex = startIndex + _usersPerPage;
    return _filteredUsers.skip(startIndex).take(_usersPerPage).toList();
  }

  int get _totalPages => (_filteredUsers.length / _usersPerPage).ceil();

  void _showUserForm({User? user}) {
    showDialog(
      context: context,
      builder: (context) => UserFormDialog(
        user: user,
        onSave: (userData) async {
          try {
            final token = ApiService.getToken();
            if (user != null) {
              await ApiService.updateUser(token, user.userId, userData);
              _showSuccessSnackbar('Cập nhật người dùng thành công');
            } else {
              await ApiService.createUser(token, userData);
              _showSuccessSnackbar('Tạo người dùng thành công');
            }
            await _loadUsers();
          } catch (e) {
            _showErrorSnackbar('Thao tác thất bại: $e');
          }
        },
      ),
    );
  }

  void _confirmDelete(User user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: Text('Bạn có chắc chắn muốn xóa người dùng "${user.fullName}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                final token = ApiService.getToken();
                await ApiService.deleteUser(token, user.userId);
                _showSuccessSnackbar('Xóa người dùng thành công');
                await _loadUsers();
              } catch (e) {
                _showErrorSnackbar('Xóa thất bại: $e');
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
  }

  void _resetPassword(User user) async {
    try {
      final token = ApiService.getToken();
      await ApiService.resetUserPassword(token, user.userId);
      _showSuccessSnackbar('Đặt lại mật khẩu thành công');
    } catch (e) {
      _showErrorSnackbar('Đặt lại mật khẩu thất bại: $e');
    }
  }

  void _toggleUserStatus(User user) async {
    try {
      final token = ApiService.getToken();
      final newStatus = !user.isActive;
      await ApiService.updateUserStatus(token, user.userId, newStatus);
      _showSuccessSnackbar('Cập nhật trạng thái thành công');
      await _loadUsers();
    } catch (e) {
      _showErrorSnackbar('Cập nhật trạng thái thất bại: $e');
    }
  }

  void _bulkAction(String action) async {
    if (_selectedUsers.isEmpty) {
      _showErrorSnackbar('Vui lòng chọn người dùng');
      return;
    }

    bool confirm = false;
    String actionText = '';

    switch (action) {
      case 'activate':
        actionText = 'kích hoạt';
        confirm = true;
        break;
      case 'deactivate':
        actionText = 'vô hiệu hóa';
        confirm = true;
        break;
      case 'delete':
        actionText = 'xóa';
        confirm = true;
        break;
    }

    if (confirm) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Xác nhận $actionText'),
          content: Text('Bạn có chắc chắn muốn $actionText ${_selectedUsers.length} người dùng đã chọn?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: Text(actionText),
            ),
          ],
        ),
      );

      if (!confirmed) return;
    }

    try {
      final token = ApiService.getToken();
      for (final user in _selectedUsers) {
        switch (action) {
          case 'activate':
            await ApiService.updateUserStatus(token, user.userId, true);
            break;
          case 'deactivate':
            await ApiService.updateUserStatus(token, user.userId, false);
            break;
          case 'delete':
            await ApiService.deleteUser(token, user.userId);
            break;
        }
      }
      _showSuccessSnackbar('$actionText thành công ${_selectedUsers.length} người dùng');
      setState(() {
        _selectedUsers.clear();
        _isSelecting = false;
      });
      await _loadUsers();
    } catch (e) {
      _showErrorSnackbar('Thao tác hàng loạt thất bại: $e');
    }
  }

  void _toggleUserSelection(User user) {
    setState(() {
      if (_selectedUsers.contains(user)) {
        _selectedUsers.remove(user);
      } else {
        _selectedUsers.add(user);
      }
      if (_selectedUsers.isEmpty) {
        _isSelecting = false;
      }
    });
  }

  void _showSuccessSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: Column(
        children: [
          _buildHeader(),
          _buildFilters(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredUsers.isEmpty
                    ? _buildEmptyState()
                    : _buildUserTable(),
          ),
          if (_filteredUsers.isNotEmpty) _buildPagination(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showUserForm(),
        backgroundColor: Theme.of(context).primaryColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Tìm kiếm theo tên, email, mã người dùng...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey.shade100,
              ),
            ),
          ),
          const SizedBox(width: 16),
          if (_isSelecting) ...[
            IconButton(
              onPressed: () => _bulkAction('activate'),
              icon: const Icon(Icons.check_circle, color: Colors.green),
              tooltip: 'Kích hoạt đã chọn',
            ),
            IconButton(
              onPressed: () => _bulkAction('deactivate'),
              icon: const Icon(Icons.block, color: Colors.orange),
              tooltip: 'Vô hiệu hóa đã chọn',
            ),
            IconButton(
              onPressed: () => _bulkAction('delete'),
              icon: const Icon(Icons.delete, color: Colors.red),
              tooltip: 'Xóa đã chọn',
            ),
            IconButton(
              onPressed: () {
                setState(() {
                  _selectedUsers.clear();
                  _isSelecting = false;
                });
              },
              icon: const Icon(Icons.close),
              tooltip: 'Hủy chọn',
            ),
          ] else ...[
            IconButton(
              onPressed: () => setState(() => _isSelecting = true),
              icon: const Icon(Icons.checklist),
              tooltip: 'Chọn nhiều',
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Row(
        children: [
          Expanded(
            child: DropdownButtonFormField<String>(
              value: _selectedRole,
              decoration: InputDecoration(
                labelText: 'Vai trò',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              items: const [
                DropdownMenuItem(value: 'Tất cả', child: Text('Tất cả')),
                DropdownMenuItem(value: 'admin', child: Text('Admin')),
                DropdownMenuItem(value: 'instructor', child: Text('Giảng viên')),
                DropdownMenuItem(value: 'student', child: Text('Sinh viên')),
              ],
              onChanged: (value) {
                setState(() => _selectedRole = value!);
                _filterUsers();
              },
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: DropdownButtonFormField<String>(
              value: _selectedStatus,
              decoration: InputDecoration(
                labelText: 'Trạng thái',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              items: const [
                DropdownMenuItem(value: 'Tất cả', child: Text('Tất cả')),
                DropdownMenuItem(value: 'Hoạt động', child: Text('Hoạt động')),
                DropdownMenuItem(value: 'Không hoạt động', child: Text('Không hoạt động')),
              ],
              onChanged: (value) {
                setState(() => _selectedStatus = value!);
                _filterUsers();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.people_outline,
            size: 80,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'Không tìm thấy người dùng nào',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Thử thay đổi bộ lọc hoặc tạo người dùng mới',
            style: TextStyle(
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserTable() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Table header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                if (_isSelecting)
                  Container(
                    width: 40,
                    alignment: Alignment.center,
                    child: Checkbox(
                      value: _selectedUsers.length == _paginatedUsers.length,
                      onChanged: (value) {
                        setState(() {
                          if (value == true) {
                            _selectedUsers = List.from(_paginatedUsers);
                          } else {
                            _selectedUsers.clear();
                          }
                        });
                      },
                    ),
                  ),
                Expanded(flex: 1, child: _buildTableHeader('Mã NV')),
                Expanded(flex: 2, child: _buildTableHeader('Họ tên')),
                Expanded(flex: 2, child: _buildTableHeader('Email')),
                Expanded(flex: 1, child: _buildTableHeader('Vai trò')),
                Expanded(flex: 1, child: _buildTableHeader('Trạng thái')),
                Expanded(flex: 1, child: _buildTableHeader('Thao tác')),
              ],
            ),
          ),
          // Table rows
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _paginatedUsers.length,
            itemBuilder: (context, index) {
              final user = _paginatedUsers[index];
              return _buildUserRow(user);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTableHeader(String text) {
    return Text(
      text,
      style: TextStyle(
        fontWeight: FontWeight.w600,
        color: Colors.grey.shade700,
      ),
    );
  }

  Widget _buildUserRow(User user) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade200),
        ),
      ),
      child: Row(
        children: [
          if (_isSelecting)
            Container(
              width: 40,
              alignment: Alignment.center,
              child: Checkbox(
                value: _selectedUsers.contains(user),
                onChanged: (value) => _toggleUserSelection(user),
              ),
            ),
          Expanded(flex: 1, child: Text(user.userId)),
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.fullName,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                if (user.role == 'student' && user.studentId != null)
                  Text(
                    'MSSV: ${user.studentId}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
              ],
            ),
          ),
          Expanded(flex: 2, child: Text(user.email)),
          Expanded(
            flex: 1,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _getRoleColor(user.role).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _getRoleText(user.role),
                style: TextStyle(
                  color: _getRoleColor(user.role),
                  fontWeight: FontWeight.w500,
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Row(
              children: [
                Icon(
                  user.isActive ? Icons.check_circle : Icons.cancel,
                  size: 16,
                  color: user.isActive ? Colors.green : Colors.red,
                ),
                const SizedBox(width: 4),
                Text(
                  user.isActive ? 'Hoạt động' : 'Không hoạt động',
                  style: TextStyle(
                    color: user.isActive ? Colors.green : Colors.red,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 1,
            child: Row(
              children: [
                IconButton(
                  onPressed: () => _showUserForm(user: user),
                  icon: const Icon(Icons.edit, size: 18),
                  tooltip: 'Chỉnh sửa',
                ),
                IconButton(
                  onPressed: () => _resetPassword(user),
                  icon: const Icon(Icons.lock_reset, size: 18),
                  tooltip: 'Đặt lại mật khẩu',
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, size: 18),
                  onSelected: (action) {
                    switch (action) {
                      case 'toggle_status':
                        _toggleUserStatus(user);
                        break;
                      case 'delete':
                        _confirmDelete(user);
                        break;
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'toggle_status',
                      child: Text(user.isActive ? 'Vô hiệu hóa' : 'Kích hoạt'),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Text('Xóa'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPagination() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Hiển thị ${(_currentPage - 1) * _usersPerPage + 1}-${_currentPage * _usersPerPage > _filteredUsers.length ? _filteredUsers.length : _currentPage * _usersPerPage} của ${_filteredUsers.length} người dùng',
            style: TextStyle(color: Colors.grey.shade600),
          ),
          Row(
            children: [
              IconButton(
                onPressed: _currentPage > 1
                    ? () => setState(() => _currentPage--)
                    : null,
                icon: const Icon(Icons.chevron_left),
              ),
              Text(
                'Trang $_currentPage/$_totalPages',
                style: TextStyle(color: Colors.grey.shade700),
              ),
              IconButton(
                onPressed: _currentPage < _totalPages
                    ? () => setState(() => _currentPage++)
                    : null,
                icon: const Icon(Icons.chevron_right),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getRoleColor(String role) {
    switch (role) {
      case 'admin':
        return Colors.purple;
      case 'instructor':
        return Colors.blue;
      case 'student':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  String _getRoleText(String role) {
    switch (role) {
      case 'admin':
        return 'Admin';
      case 'instructor':
        return 'Giảng viên';
      case 'student':
        return 'Sinh viên';
      default:
        return role;
    }
  }
}

class UserFormDialog extends StatefulWidget {
  final User? user;
  final Function(Map<String, dynamic>) onSave;

  const UserFormDialog({
    super.key,
    this.user,
    required this.onSave,
  });

  @override
  State<UserFormDialog> createState() => _UserFormDialogState();
}

class _UserFormDialogState extends State<UserFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _userIdController = TextEditingController();
  final _studentIdController = TextEditingController();
  String _selectedRole = 'student';
  bool _isActive = true;

  @override
  void initState() {
    super.initState();
    if (widget.user != null) {
      _fullNameController.text = widget.user!.fullName;
      _emailController.text = widget.user!.email;
      _userIdController.text = widget.user!.userId;
      _selectedRole = widget.user!.role;
      _isActive = widget.user!.isActive;
      if (widget.user!.studentId != null) {
        _studentIdController.text = widget.user!.studentId!;
      }
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _userIdController.dispose();
    _studentIdController.dispose();
    super.dispose();
  }

  void _saveUser() {
    if (_formKey.currentState!.validate()) {
      final userData = {
        'full_name': _fullNameController.text,
        'email': _emailController.text,
        'user_id': _userIdController.text,
        'role': _selectedRole,
        'is_active': _isActive,
      };

      if (_selectedRole == 'student' && _studentIdController.text.isNotEmpty) {
        userData['student_id'] = _studentIdController.text;
      }

      widget.onSave(userData);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 500,
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.user != null ? 'Cập nhật người dùng' : 'Tạo người dùng mới',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _fullNameController,
                      decoration: const InputDecoration(
                        labelText: 'Họ tên',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Vui lòng nhập họ tên';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _userIdController,
                      decoration: const InputDecoration(
                        labelText: 'Mã người dùng',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Vui lòng nhập mã người dùng';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Vui lòng nhập email';
                  }
                  if (!value.contains('@')) {
                    return 'Email không hợp lệ';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _selectedRole,
                      decoration: const InputDecoration(
                        labelText: 'Vai trò',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'student', child: Text('Sinh viên')),
                        DropdownMenuItem(value: 'instructor', child: Text('Giảng viên')),
                        DropdownMenuItem(value: 'admin', child: Text('Admin')),
                      ],
                      onChanged: (value) {
                        setState(() => _selectedRole = value!);
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _selectedRole == 'student'
                        ? TextFormField(
                            controller: _studentIdController,
                            decoration: const InputDecoration(
                              labelText: 'Mã số sinh viên',
                              border: OutlineInputBorder(),
                            ),
                          )
                        : const SizedBox.shrink(),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Checkbox(
                    value: _isActive,
                    onChanged: (value) => setState(() => _isActive = value!),
                  ),
                  const Text('Kích hoạt'),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Hủy'),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: _saveUser,
                    child: Text(widget.user != null ? 'Cập nhật' : 'Tạo'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}