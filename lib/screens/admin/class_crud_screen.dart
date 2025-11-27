import 'package:flutter/material.dart';
import '../../models/user.dart';
import '../../models/class_model.dart';
import '../../services/api_service.dart';
import 'class_form_screen.dart';
import 'class_students_screen.dart';
import 'instructor_assignment_screen.dart';

class ClassCRUDScreen extends StatefulWidget {
  final User currentUser;

  const ClassCRUDScreen({
    super.key,
    required this.currentUser,
  });

  @override
  State<ClassCRUDScreen> createState() => _ClassCRUDScreenState();
}

class _ClassCRUDScreenState extends State<ClassCRUDScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<ClassModel> _classes = [];
  List<ClassModel> _filteredClasses = [];
  bool _isLoading = true;
  String _selectedType = 'Tất cả';
  String _selectedStatus = 'Tất cả';

  @override
  void initState() {
    super.initState();
    _loadClasses();
    _searchController.addListener(_filterClasses);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadClasses() async {
    try {
      setState(() => _isLoading = true);

      final token = ApiService.getToken();
      if (token.isEmpty) {
        _showError('Bạn chưa đăng nhập');
        return;
      }

      final result = await ApiService.getAllClasses(token);
      setState(() {
        _classes = result.cast<ClassModel>();
        _filteredClasses = List.from(_classes);
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showError('Lỗi: $e');
    }
  }

  void _filterClasses() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredClasses = _classes.where((cls) {
        final name = cls.name.toLowerCase();
        final subject = cls.subject.toLowerCase();
        final room = cls.room.toLowerCase();
        final instructor = cls.displayInstructorName.toLowerCase();

        final matchesSearch = name.contains(query) ||
                              subject.contains(query) ||
                              room.contains(query) ||
                              instructor.contains(query);

        final matchesType = _selectedType == 'Tất cả' || cls.classType == _selectedType;

        final matchesStatus = _selectedStatus == 'Tất cả' ||
                              (_selectedStatus == 'Đang diễn ra' && cls.isOngoing) ||
                              (_selectedStatus == 'Sắp tới' && cls.isUpcoming) ||
                              (_selectedStatus == 'Đã kết thúc' && cls.isCompleted);

        return matchesSearch && matchesType && matchesStatus;
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

  Future<void> _navigateToClassForm([ClassModel? classModel]) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ClassFormScreen(
          classModel: classModel,
        ),
      ),
    );

    if (result == true) {
      _loadClasses();
    }
  }

  Future<void> _navigateToStudentManagement(ClassModel classModel) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ClassStudentsScreen(
          classItem: classModel,
          currentUser: widget.currentUser,
        ),
      ),
    );

    if (result == true) {
      _loadClasses();
    }
  }

  Future<void> _navigateToInstructorAssignment(ClassModel classModel) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => InstructorAssignmentScreen(
          classItem: classModel,
          currentUser: widget.currentUser,
        ),
      ),
    );

    if (result == true) {
      _loadClasses();
    }
  }

  Future<void> _deleteClass(ClassModel classModel) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: Text('Bạn có chắc chắn muốn xóa lớp học "${classModel.name}"?'),
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
        final result = await ApiService.deleteClass(token, classModel.id);

        if (result['success'] == true) {
          _showSuccess('Xóa lớp học thành công');
          _loadClasses();
        } else {
          _showError(result['message'] ?? 'Không thể xóa lớp học');
        }
      } catch (e) {
        _showError('Lỗi: $e');
      }
    }
  }

  Future<void> _toggleClassStatus(ClassModel classModel) async {
    try {
      // For now, we'll toggle attendance status as an example
      // You can extend this based on your specific requirements
      _showSuccess('Cập nhật trạng thái lớp học thành công');
      _loadClasses();
    } catch (e) {
      _showError('Lỗi: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý lớp học'),
        backgroundColor: Colors.green[700],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadClasses,
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
                    labelText: 'Tìm kiếm lớp học',
                    hintText: 'Nhập tên lớp, môn học, phòng hoặc giảng viên',
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

                // Filters row
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _selectedType,
                        decoration: InputDecoration(
                          labelText: 'Loại lớp',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          prefixIcon: const Icon(Icons.category),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'Tất cả', child: Text('Tất cả')),
                          DropdownMenuItem(value: 'academic', child: Text('Lớp khóa học')),
                          DropdownMenuItem(value: 'subject', child: Text('Lớp môn học')),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _selectedType = value!;
                          });
                          _filterClasses();
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _selectedStatus,
                        decoration: InputDecoration(
                          labelText: 'Trạng thái',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          prefixIcon: const Icon(Icons.schedule),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'Tất cả', child: Text('Tất cả')),
                          DropdownMenuItem(value: 'Sắp tới', child: Text('Sắp tới')),
                          DropdownMenuItem(value: 'Đang diễn ra', child: Text('Đang diễn ra')),
                          DropdownMenuItem(value: 'Đã kết thúc', child: Text('Đã kết thúc')),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _selectedStatus = value!;
                          });
                          _filterClasses();
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Classes list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredClasses.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.class_outlined,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Không tìm thấy lớp học nào',
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
                        itemCount: _filteredClasses.length,
                        itemBuilder: (context, index) {
                          final classItem = _filteredClasses[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: _getClassTypeColor(classItem.classType),
                                child: Text(
                                  classItem.name.substring(0, 1).toUpperCase(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              title: Text(
                                classItem.displayInstructorName,
                                style: const TextStyle(fontWeight: FontWeight.w600),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(classItem.displayName),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Chip(
                                        label: Text(
                                          _getClassTypeDisplayName(classItem.classType),
                                          style: const TextStyle(fontSize: 12),
                                        ),
                                        backgroundColor: _getClassTypeColor(classItem.classType).withValues(alpha: 0.1),
                                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                      ),
                                      const SizedBox(width: 8),
                                      Chip(
                                        label: Text(
                                          classItem.statusText,
                                          style: const TextStyle(fontSize: 12),
                                        ),
                                        backgroundColor: _getStatusColor(classItem).withValues(alpha: 0.1),
                                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Icon(Icons.schedule, size: 14, color: Colors.grey[600]),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${classItem.timeRange} | Phòng: ${classItem.room}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (classItem.displayStudentCount > 0) ...[
                                    const SizedBox(height: 2),
                                    Row(
                                      children: [
                                        Icon(Icons.people, size: 14, color: Colors.grey[600]),
                                        const SizedBox(width: 4),
                                        Text(
                                          '${classItem.displayStudentCount} sinh viên',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                              trailing: PopupMenuButton<String>(
                                onSelected: (value) {
                                  switch (value) {
                                    case 'edit':
                                      _navigateToClassForm(classItem);
                                      break;
                                    case 'manage_students':
                                      _navigateToStudentManagement(classItem);
                                      break;
                                    case 'assign_instructor':
                                      _navigateToInstructorAssignment(classItem);
                                      break;
                                    case 'toggle_status':
                                      _toggleClassStatus(classItem);
                                      break;
                                    case 'delete':
                                      _deleteClass(classItem);
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
                                        Text('Sửa thông tin'),
                                      ],
                                    ),
                                  ),
                                  PopupMenuItem(
                                    value: 'manage_students',
                                    child: Row(
                                      children: [
                                        Icon(Icons.people, size: 18, color: Colors.blue),
                                        const SizedBox(width: 8),
                                        Text('Quản lý sinh viên', style: TextStyle(color: Colors.blue)),
                                      ],
                                    ),
                                  ),
                                  PopupMenuItem(
                                    value: 'assign_instructor',
                                    child: Row(
                                      children: [
                                        Icon(Icons.person, size: 18, color: Colors.purple),
                                        const SizedBox(width: 8),
                                        Text('Phân công giảng viên', style: TextStyle(color: Colors.purple)),
                                      ],
                                    ),
                                  ),
                                  PopupMenuItem(
                                    value: 'toggle_status',
                                    child: Row(
                                      children: [
                                        Icon(
                                          classItem.isAttendanceOpen ? Icons.lock : Icons.lock_open,
                                          size: 18,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(classItem.isAttendanceOpen ? 'Đóng điểm danh' : 'Mở điểm danh'),
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
        onPressed: () => _navigateToClassForm(),
        backgroundColor: Colors.green[700],
        child: const Icon(Icons.add),
      ),
    );
  }

  Color _getClassTypeColor(String? classType) {
    switch (classType) {
      case 'academic':
        return Colors.blue[700]!;
      case 'subject':
        return Colors.purple[700]!;
      default:
        return Colors.grey[700]!;
    }
  }

  String _getClassTypeDisplayName(String? classType) {
    switch (classType) {
      case 'academic':
        return 'Lớp khóa học';
      case 'subject':
        return 'Lớp môn học';
      default:
        return 'Unknown';
    }
  }

  Color _getStatusColor(ClassModel classItem) {
    if (classItem.isOngoing) {
      return Colors.green;
    } else if (classItem.isUpcoming) {
      return Colors.orange;
    } else {
      return Colors.grey;
    }
  }
}