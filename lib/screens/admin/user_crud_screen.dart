import 'package:flutter/material.dart';
import '../../models/user.dart';
import '../../services/api_service.dart';
import 'user_form_screen.dart';

class UserCRUDScreen extends StatefulWidget {
  final User currentUser;

  const UserCRUDScreen({
    super.key,
    required this.currentUser,
  });

  @override
  State<UserCRUDScreen> createState() => _UserCRUDScreenState();
}

class _UserCRUDScreenState extends State<UserCRUDScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _users = [];
  List<Map<String, dynamic>> _filteredUsers = [];
  bool _isLoading = true;
  String _selectedRole = 'Tất cả';

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
        _showError('Bạn chưa đăng nhập');
        return;
      }

      final result = await ApiService.getAllUsers(token);
      if (result['success'] == true && result['accounts'] != null) {
        final usersList = result['accounts'] as List;
        setState(() {
          _users = usersList.cast<Map<String, dynamic>>();
          _filteredUsers = List.from(_users);
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
        _showError(result['message'] ?? 'Không thể tải danh sách người dùng');
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showError('Lỗi: $e');
    }
  }

  void _filterUsers() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredUsers = _users.where((user) {
        final name = user['full_name']?.toString().toLowerCase() ?? '';
        final email = user['email']?.toString().toLowerCase() ?? '';
        final userId = user['user_id']?.toString().toLowerCase() ?? '';
        final role = user['role']?.toString() ?? '';

        final matchesSearch = name.contains(query) ||
                              email.contains(query) ||
                              userId.contains(query);

        final matchesRole = _selectedRole == 'Tất cả' || role == _selectedRole;

        return matchesSearch && matchesRole;
      }).toList();
    });
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
    }
  }

  void _showSuccess(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.green),
      );
    }
  }

  Future<void> _navigateToUserForm([Map<String, dynamic>? user]) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UserFormScreen(
          user: user != null ? User.fromJson(user) : null,
        ),
      ),
    );

    if (result == true) {
      _loadUsers();
    }
  }

  Future<void> _deleteUser(Map<String, dynamic> user) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: Text('Bạn có chắc chắn muốn xóa người dùng "${user['full_name']}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final token = ApiService.getToken();
        final result = await ApiService.deleteUser(token, user['_id'].toString());

        if (result['success'] == true) {
          _showSuccess('Xóa người dùng thành công');
          _loadUsers();
        } else {
          _showError(result['message'] ?? 'Không thể xóa người dùng');
        }
      } catch (e) {
        _showError('Lỗi: $e');
      }
    }
  }

  Future<void> _toggleUserStatus(Map<String, dynamic> user) async {
    try {
      final token = ApiService.getToken();
      final newStatus = !(user['is_active'] ?? true);

      final result = await ApiService.updateUserStatus(
        token,
        user['_id'].toString(),
        newStatus
      );

      if (result['success'] == true) {
        _showSuccess(newStatus ? 'Kích hoạt người dùng thành công' : 'Vô hiệu hóa người dùng thành công');
        _loadUsers();
      } else {
        _showError(result['message'] ?? 'Không thể cập nhật trạng thái');
      }
    } catch (e) {
      _showError('Lỗi: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý người dùng'),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadUsers,
            tooltip: 'Tải lại',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search and filters
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Search bar
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    labelText: 'Tìm kiếm người dùng',
                    hintText: 'Nhập tên, email hoặc mã người dùng',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                            },
                          )
                        : null,
                  ),
                ),
                const SizedBox(height: 16),

                // Role filter
                DropdownButtonFormField<String>(
                  initialValue: _selectedRole,
                  decoration: InputDecoration(
                    labelText: 'Lọc theo vai trò',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    prefixIcon: const Icon(Icons.filter_list),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'Tất cả', child: Text('Tất cả')),
                    DropdownMenuItem(value: 'admin', child: Text('Admin')),
                    DropdownMenuItem(value: 'instructor', child: Text('Giảng viên')),
                    DropdownMenuItem(value: 'student', child: Text('Sinh viên')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedRole = value!;
                    });
                    _filterUsers();
                  },
                ),
              ],
            ),
          ),

          // Users list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredUsers.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.people_outline,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Không tìm thấy người dùng nào',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _filteredUsers.length,
                        itemBuilder: (context, index) {
                          final user = _filteredUsers[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: _getRoleColor(user['role']),
                                child: Text(
                                  user['full_name']?.toString().substring(0, 1).toUpperCase() ?? 'U',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              title: Text(
                                user['full_name']?.toString() ?? 'Unknown',
                                style: const TextStyle(fontWeight: FontWeight.w600),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(user['email']?.toString() ?? ''),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Chip(
                                        label: Text(
                                          _getRoleDisplayName(user['role']),
                                          style: const TextStyle(fontSize: 12),
                                        ),
                                        backgroundColor: _getRoleColor(user['role']).withValues(alpha: 0.1),
                                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                      ),
                                      const SizedBox(width: 8),
                                      if (user['is_active'] == true)
                                        Chip(
                                          label: const Text(
                                            'Hoạt động',
                                            style: TextStyle(fontSize: 12, color: Colors.white),
                                          ),
                                          backgroundColor: Colors.green,
                                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                        )
                                      else
                                        Chip(
                                          label: const Text(
                                            'Vô hiệu',
                                            style: TextStyle(fontSize: 12, color: Colors.white),
                                          ),
                                          backgroundColor: Colors.red,
                                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                              trailing: PopupMenuButton<String>(
                                onSelected: (value) {
                                  switch (value) {
                                    case 'edit':
                                      _navigateToUserForm(user);
                                      break;
                                    case 'toggle_status':
                                      _toggleUserStatus(user);
                                      break;
                                    case 'delete':
                                      _deleteUser(user);
                                      break;
                                  }
                                },
                                itemBuilder: (context) => [
                                  const PopupMenuItem(
                                    value: 'edit',
                                    child: Row(
                                      children: [
                                        Icon(Icons.edit, size: 18),
                                        SizedBox(width: 8),
                                        Text('Sửa'),
                                      ],
                                    ),
                                  ),
                                  PopupMenuItem(
                                    value: 'toggle_status',
                                    child: Row(
                                      children: [
                                        Icon(
                                          user['is_active'] == true ? Icons.block : Icons.check_circle,
                                          size: 18,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(user['is_active'] == true ? 'Vô hiệu hóa' : 'Kích hoạt'),
                                      ],
                                    ),
                                  ),
                                  const PopupMenuItem(
                                    value: 'delete',
                                    child: Row(
                                      children: [
                                        Icon(Icons.delete, size: 18, color: Colors.red),
                                        SizedBox(width: 8),
                                        Text('Xóa', style: TextStyle(color: Colors.red)),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToUserForm(),
        backgroundColor: Colors.blue[700],
        child: const Icon(Icons.add),
      ),
    );
  }

  Color _getRoleColor(String? role) {
    switch (role) {
      case 'admin':
        return Colors.red[700]!;
      case 'instructor':
        return Colors.purple[700]!;
      case 'student':
        return Colors.blue[700]!;
      default:
        return Colors.grey[700]!;
    }
  }

  String _getRoleDisplayName(String? role) {
    switch (role) {
      case 'admin':
        return 'Admin';
      case 'instructor':
        return 'Giảng viên';
      case 'student':
        return 'Sinh viên';
      default:
        return 'Unknown';
    }
  }
}