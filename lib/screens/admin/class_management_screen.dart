import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/class_model.dart';
import '../../models/user.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';

class ClassManagementScreen extends StatefulWidget {
  final User currentUser;

  const ClassManagementScreen({
    super.key,
    required this.currentUser,
  });

  @override
  State<ClassManagementScreen> createState() => _ClassManagementScreenState();
}

class _ClassManagementScreenState extends State<ClassManagementScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<ClassModel> _classes = [];
  List<ClassModel> _filteredClasses = [];
  bool _isLoading = true;
  String _selectedInstructor = 'Tất cả';
  String _selectedStatus = 'Tất cả';
  String _selectedDay = 'Tất cả';
  int _currentPage = 1;
  int _classesPerPage = 10;
  List<ClassModel> _selectedClasses = [];
  bool _isSelecting = false;

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
        throw Exception('No authentication token');
      }

      // Get classes from API
      final classesData = await ApiService.getAllClasses(token);

      setState(() {
        _classes = classesData.map((data) {
          if (data is Map<String, dynamic>) {
            return ClassModel.fromJson(data);
          } else {
            // Handle case where API returns class objects directly
            return data as ClassModel;
          }
        }).toList();
        _filteredClasses = List.from(_classes);
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorSnackbar('Không thể tải danh sách lớp học: $e');
    }
  }

  void _filterClasses() {
    setState(() {
      _filteredClasses = _classes.where((classItem) {
        final matchesSearch = classItem.name.toLowerCase().contains(_searchController.text.toLowerCase()) ||
                            classItem.courseCode.toLowerCase().contains(_searchController.text.toLowerCase()) ||
                            (classItem.instructorName?.toLowerCase().contains(_searchController.text.toLowerCase()) ?? false);

        final matchesInstructor = _selectedInstructor == 'Tất cả' || classItem.instructorName == _selectedInstructor;
        final matchesStatus = _selectedStatus == 'Tất cả' ||
                              (_selectedStatus == 'Đang hoạt động' && classItem.isActive) ||
                              (_selectedStatus == 'Không hoạt động' && !classItem.isActive);
        final matchesDay = _selectedDay == 'Tất cả' || classItem.timeRange.contains(_selectedDay);

        return matchesSearch && matchesInstructor && matchesStatus && matchesDay;
      }).toList();
      _currentPage = 1;
    });
  }

  List<ClassModel> get _paginatedClasses {
    final startIndex = (_currentPage - 1) * _classesPerPage;
    final endIndex = startIndex + _classesPerPage;
    return _filteredClasses.skip(startIndex).take(_classesPerPage).toList();
  }

  int get _totalPages => (_filteredClasses.length / _classesPerPage).ceil();

  void _showClassForm({ClassModel? classItem}) {
    showDialog(
      context: context,
      builder: (context) => ClassFormDialog(
        classItem: classItem,
        onSave: (classData) async {
          try {
            final token = ApiService.getToken();
            if (classItem != null) {
              await ApiService.updateClass(token, classItem.id, classData);
              _showSuccessSnackbar('Cập nhật lớp học thành công');
            } else {
              await ApiService.createClass(token, classData);
              _showSuccessSnackbar('Tạo lớp học thành công');
            }
            await _loadClasses();
          } catch (e) {
            _showErrorSnackbar('Thao tác thất bại: $e');
          }
        },
      ),
    );
  }

  void _confirmDelete(ClassModel classItem) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: Text('Bạn có chắc chắn muốn xóa lớp học "${classItem.name}"?'),
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
                await ApiService.deleteClass(token, classItem.id);
                _showSuccessSnackbar('Xóa lớp học thành công');
                await _loadClasses();
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

  void _toggleClassStatus(ClassModel classItem) async {
    try {
      final token = ApiService.getToken();
      final newStatus = !classItem.isActive;
      await ApiService.updateClassStatus(token, classItem.id, newStatus);
      _showSuccessSnackbar('Cập nhật trạng thái thành công');
      await _loadClasses();
    } catch (e) {
      _showErrorSnackbar('Cập nhật trạng thái thất bại: $e');
    }
  }

  void _showStudentManagement(ClassModel classItem) {
    showDialog(
      context: context,
      builder: (context) => StudentManagementDialog(classItem: classItem),
    );
  }

  void _showInstructorAssignment(ClassModel classItem) {
    showDialog(
      context: context,
      builder: (context) => InstructorAssignmentDialog(
        classItem: classItem,
        onAssign: (instructorId) async {
          try {
            final token = ApiService.getToken();
            await ApiService.assignInstructor(token, classItem.id, instructorId);
            _showSuccessSnackbar('Phân công giảng viên thành công');
            await _loadClasses();
          } catch (e) {
            _showErrorSnackbar('Phân công thất bại: $e');
          }
        },
      ),
    );
  }

  void _bulkAction(String action) async {
    if (_selectedClasses.isEmpty) {
      _showErrorSnackbar('Vui lòng chọn lớp học');
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
          content: Text('Bạn có chắc chắn muốn $actionText ${_selectedClasses.length} lớp học đã chọn?'),
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
      for (final classItem in _selectedClasses) {
        switch (action) {
          case 'activate':
            await ApiService.updateClassStatus(token, classItem.id, true);
            break;
          case 'deactivate':
            await ApiService.updateClassStatus(token, classItem.id, false);
            break;
          case 'delete':
            await ApiService.deleteClass(token, classItem.id);
            break;
        }
      }
      _showSuccessSnackbar('$actionText thành công ${_selectedClasses.length} lớp học');
      setState(() {
        _selectedClasses.clear();
        _isSelecting = false;
      });
      await _loadClasses();
    } catch (e) {
      _showErrorSnackbar('Thao tác hàng loạt thất bại: $e');
    }
  }

  void _toggleClassSelection(ClassModel classItem) {
    setState(() {
      if (_selectedClasses.contains(classItem)) {
        _selectedClasses.remove(classItem);
      } else {
        _selectedClasses.add(classItem);
      }
      if (_selectedClasses.isEmpty) {
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

  List<String> get _uniqueInstructors {
    final instructors = _classes.map((c) => c.instructorName ?? 'Chưa có giảng viên').toSet().toList();
    instructors.sort();
    return instructors;
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
                : _filteredClasses.isEmpty
                    ? _buildEmptyState()
                    : _buildClassTable(),
          ),
          if (_filteredClasses.isNotEmpty) _buildPagination(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showClassForm(),
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
                hintText: 'Tìm kiếm theo tên, mã môn, giảng viên...',
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
                  _selectedClasses.clear();
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
              value: _selectedInstructor,
              decoration: InputDecoration(
                labelText: 'Giảng viên',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              items: [
                const DropdownMenuItem(value: 'Tất cả', child: Text('Tất cả')),
                ..._uniqueInstructors.map((instructor) => DropdownMenuItem(
                  value: instructor,
                  child: Text(instructor),
                )),
              ],
              onChanged: (value) {
                setState(() => _selectedInstructor = value!);
                _filterClasses();
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
                DropdownMenuItem(value: 'Đang hoạt động', child: Text('Đang hoạt động')),
                DropdownMenuItem(value: 'Không hoạt động', child: Text('Không hoạt động')),
              ],
              onChanged: (value) {
                setState(() => _selectedStatus = value!);
                _filterClasses();
              },
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: DropdownButtonFormField<String>(
              value: _selectedDay,
              decoration: InputDecoration(
                labelText: 'Thứ',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              items: const [
                DropdownMenuItem(value: 'Tất cả', child: Text('Tất cả')),
                DropdownMenuItem(value: 'Thứ 2', child: Text('Thứ 2')),
                DropdownMenuItem(value: 'Thứ 3', child: Text('Thứ 3')),
                DropdownMenuItem(value: 'Thứ 4', child: Text('Thứ 4')),
                DropdownMenuItem(value: 'Thứ 5', child: Text('Thứ 5')),
                DropdownMenuItem(value: 'Thứ 6', child: Text('Thứ 6')),
                DropdownMenuItem(value: 'Thứ 7', child: Text('Thứ 7')),
                DropdownMenuItem(value: 'Chủ Nhật', child: Text('Chủ Nhật')),
              ],
              onChanged: (value) {
                setState(() => _selectedDay = value!);
                _filterClasses();
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
            Icons.class_outlined,
            size: 80,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'Không tìm thấy lớp học nào',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Thử thay đổi bộ lọc hoặc tạo lớp học mới',
            style: TextStyle(
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClassTable() {
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
                      value: _selectedClasses.length == _paginatedClasses.length,
                      onChanged: (value) {
                        setState(() {
                          if (value == true) {
                            _selectedClasses = List.from(_paginatedClasses);
                          } else {
                            _selectedClasses.clear();
                          }
                        });
                      },
                    ),
                  ),
                Expanded(flex: 1, child: _buildTableHeader('Mã môn')),
                Expanded(flex: 2, child: _buildTableHeader('Tên lớp')),
                Expanded(flex: 1, child: _buildTableHeader('Phòng')),
                Expanded(flex: 2, child: _buildTableHeader('Giảng viên')),
                Expanded(flex: 1, child: _buildTableHeader('Số SV')),
                Expanded(flex: 1, child: _buildTableHeader('Trạng thái')),
                Expanded(flex: 1, child: _buildTableHeader('Thao tác')),
              ],
            ),
          ),
          // Table rows
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _paginatedClasses.length,
            itemBuilder: (context, index) {
              final classItem = _paginatedClasses[index];
              return _buildClassRow(classItem);
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

  Widget _buildClassRow(ClassModel classItem) {
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
                value: _selectedClasses.contains(classItem),
                onChanged: (value) => _toggleClassSelection(classItem),
              ),
            ),
          Expanded(flex: 1, child: Text(classItem.courseCode)),
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  classItem.name,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                Text(
                  classItem.timeRange,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          Expanded(flex: 1, child: Text(classItem.room)),
          Expanded(
            flex: 2,
            child: Text(
              classItem.instructorName ?? 'Chưa phân công',
              style: TextStyle(
                color: classItem.instructorName != null ? Colors.black : Colors.grey,
              ),
            ),
          ),
          Expanded(flex: 1, child: Text('${classItem.studentCount ?? 0}')),
          Expanded(
            flex: 1,
            child: Row(
              children: [
                Icon(
                  classItem.isActive ? Icons.check_circle : Icons.cancel,
                  size: 16,
                  color: classItem.isActive ? Colors.green : Colors.red,
                ),
                const SizedBox(width: 4),
                Text(
                  classItem.isActive ? 'Hoạt động' : 'Không hoạt động',
                  style: TextStyle(
                    color: classItem.isActive ? Colors.green : Colors.red,
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
                  onPressed: () => _showClassForm(classItem: classItem),
                  icon: const Icon(Icons.edit, size: 18),
                  tooltip: 'Chỉnh sửa',
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, size: 18),
                  onSelected: (action) {
                    switch (action) {
                      case 'toggle_status':
                        _toggleClassStatus(classItem);
                        break;
                      case 'manage_students':
                        _showStudentManagement(classItem);
                        break;
                      case 'assign_instructor':
                        _showInstructorAssignment(classItem);
                        break;
                      case 'delete':
                        _confirmDelete(classItem);
                        break;
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'toggle_status',
                      child: Text(classItem.isActive ? 'Vô hiệu hóa' : 'Kích hoạt'),
                    ),
                    const PopupMenuItem(
                      value: 'manage_students',
                      child: Text('Quản lý sinh viên'),
                    ),
                    const PopupMenuItem(
                      value: 'assign_instructor',
                      child: Text('Phân công giảng viên'),
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
            'Hiển thị ${(_currentPage - 1) * _classesPerPage + 1}-${_currentPage * _classesPerPage > _filteredClasses.length ? _filteredClasses.length : _currentPage * _classesPerPage} của ${_filteredClasses.length} lớp học',
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
}

class ClassFormDialog extends StatefulWidget {
  final ClassModel? classItem;
  final Function(Map<String, dynamic>) onSave;

  const ClassFormDialog({
    super.key,
    this.classItem,
    required this.onSave,
  });

  @override
  State<ClassFormDialog> createState() => _ClassFormDialogState();
}

class _ClassFormDialogState extends State<ClassFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _classNameController = TextEditingController();
  final _courseCodeController = TextEditingController();
  final _roomController = TextEditingController();
  final _timeController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _selectedDay = 'Thứ 2';
  String _selectedTime = '7:00-9:00';
  bool _isActive = true;

  @override
  void initState() {
    super.initState();
    if (widget.classItem != null) {
      _classNameController.text = widget.classItem!.name;
      _courseCodeController.text = widget.classItem!.courseCode;
      _roomController.text = widget.classItem!.room;
      _timeController.text = widget.classItem!.timeRange;
      _descriptionController.text = widget.classItem!.description ?? '';
      _isActive = widget.classItem!.isActive;
    }
  }

  @override
  void dispose() {
    _classNameController.dispose();
    _courseCodeController.dispose();
    _roomController.dispose();
    _timeController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _saveClass() {
    if (_formKey.currentState!.validate()) {
      final classData = {
        'name': _classNameController.text,
        'course_code': _courseCodeController.text,
        'room': _roomController.text,
        'time_range': '$_selectedDay $_selectedTime',
        'description': _descriptionController.text,
        'is_active': _isActive,
      };

      widget.onSave(classData);
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
                widget.classItem != null ? 'Cập nhật lớp học' : 'Tạo lớp học mới',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _classNameController,
                      decoration: const InputDecoration(
                        labelText: 'Tên lớp học',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Vui lòng nhập tên lớp học';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _courseCodeController,
                      decoration: const InputDecoration(
                        labelText: 'Mã môn học',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Vui lòng nhập mã môn học';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _roomController,
                      decoration: const InputDecoration(
                        labelText: 'Phòng học',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Vui lòng nhập phòng học';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _timeController,
                      decoration: const InputDecoration(
                        labelText: 'Thời gian',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _selectedDay,
                      decoration: const InputDecoration(
                        labelText: 'Thứ',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'Thứ 2', child: Text('Thứ 2')),
                        DropdownMenuItem(value: 'Thứ 3', child: Text('Thứ 3')),
                        DropdownMenuItem(value: 'Thứ 4', child: Text('Thứ 4')),
                        DropdownMenuItem(value: 'Thứ 5', child: Text('Thứ 5')),
                        DropdownMenuItem(value: 'Thứ 6', child: Text('Thứ 6')),
                        DropdownMenuItem(value: 'Thứ 7', child: Text('Thứ 7')),
                        DropdownMenuItem(value: 'Chủ Nhật', child: Text('Chủ Nhật')),
                      ],
                      onChanged: (value) {
                        setState(() => _selectedDay = value!);
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _selectedTime,
                      decoration: const InputDecoration(
                        labelText: 'Ca học',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(value: '7:00-9:00', child: Text('Sáng (7:00-9:00)')),
                        DropdownMenuItem(value: '9:30-11:30', child: Text('Sáng (9:30-11:30)')),
                        DropdownMenuItem(value: '13:30-15:30', child: Text('Chiều (13:30-15:30)')),
                        DropdownMenuItem(value: '16:00-18:00', child: Text('Chiều (16:00-18:00)')),
                        DropdownMenuItem(value: '19:00-21:00', child: Text('Tối (19:00-21:00)')),
                      ],
                      onChanged: (value) {
                        setState(() => _selectedTime = value!);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Mô tả',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
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
                    onPressed: _saveClass,
                    child: Text(widget.classItem != null ? 'Cập nhật' : 'Tạo'),
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

class StudentManagementDialog extends StatefulWidget {
  final ClassModel classItem;

  const StudentManagementDialog({
    super.key,
    required this.classItem,
  });

  @override
  State<StudentManagementDialog> createState() => _StudentManagementDialogState();
}

class _StudentManagementDialogState extends State<StudentManagementDialog> {
  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 600,
        height: 500,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quản lý sinh viên - ${widget.classItem.name}',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.people,
                      size: 80,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Danh sách sinh viên',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${widget.classItem.studentCount ?? 0} sinh viên',
                      style: TextStyle(
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Đóng'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class InstructorAssignmentDialog extends StatefulWidget {
  final ClassModel classItem;
  final Function(String) onAssign;

  const InstructorAssignmentDialog({
    super.key,
    required this.classItem,
    required this.onAssign,
  });

  @override
  State<InstructorAssignmentDialog> createState() => _InstructorAssignmentDialogState();
}

class _InstructorAssignmentDialogState extends State<InstructorAssignmentDialog> {
  String? _selectedInstructor;
  bool _isLoading = false;
  List<Map<String, dynamic>> _instructors = [];

  @override
  void initState() {
    super.initState();
    _loadInstructors();
  }

  Future<void> _loadInstructors() async {
    try {
      final token = ApiService.getToken();
      final instructorsData = await ApiService.getInstructors(token);
      setState(() {
        _instructors = instructorsData.cast<Map<String, dynamic>>();
      });
    } catch (e) {
      print('Error loading instructors: $e');
    }
  }

  void _assignInstructor() {
    if (_selectedInstructor != null) {
      widget.onAssign(_selectedInstructor!);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 400,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Phân công giảng viên - ${widget.classItem.name}',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            DropdownButtonFormField<String>(
              value: _selectedInstructor,
              decoration: const InputDecoration(
                labelText: 'Chọn giảng viên',
                border: OutlineInputBorder(),
              ),
              items: _instructors.map((instructor) {
                return DropdownMenuItem<String>(
                  value: instructor['id'],
                  child: Text('${instructor['full_name']} (${instructor['user_id']})'),
                );
              }).toList(),
              onChanged: (value) {
                setState(() => _selectedInstructor = value);
              },
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
                  onPressed: _selectedInstructor != null ? _assignInstructor : null,
                  child: const Text('Phân công'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}