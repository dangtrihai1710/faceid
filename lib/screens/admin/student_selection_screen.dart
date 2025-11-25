import 'package:flutter/material.dart';
import '../../models/user.dart';
import '../../models/class_model.dart';
import '../../services/admin_crud_service.dart';

class StudentSelectionScreen extends StatefulWidget {
  final ClassModel subjectClass;

  const StudentSelectionScreen({
    super.key,
    required this.subjectClass,
  });

  @override
  State<StudentSelectionScreen> createState() => _StudentSelectionScreenState();
}

class _StudentSelectionScreenState extends State<StudentSelectionScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<User> _allStudents = [];
  List<User> _filteredStudents = [];
  List<User> _selectedStudents = [];
  List<User> _availableStudents = [];
  bool _isLoading = true;
  bool _isAssigning = false;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      // Get all students
      final usersResult = await AdminCrudService.getAllUsers(
        role: 'student',
        perPage: 100, // Load students
      );

      // Get current subject class details to see enrolled students
      final classResult = await AdminCrudService.getAllClasses();

      if (mounted) {
        final studentsData = usersResult['data'] as List? ?? [];
        final allStudents = studentsData.map((json) => User.fromJson(json)).toList();

        // Filter out students who are already in this subject class
        final enrolledStudentIds = widget.subjectClass.studentIds ?? [];
        final availableStudents = allStudents.where((student) {
          return !enrolledStudentIds.contains(student.id) &&
                 !enrolledStudentIds.contains(student.userId);
        }).toList();

        setState(() {
          _allStudents = allStudents;
          _availableStudents = availableStudents;
          _filteredStudents = availableStudents;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi tải dữ liệu: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _filterStudents(String query) {
    setState(() {
      _searchQuery = query.toLowerCase();
      _filteredStudents = _availableStudents.where((student) {
        return student.fullName.toLowerCase().contains(_searchQuery) ||
               student.userId.toLowerCase().contains(_searchQuery) ||
               student.email.toLowerCase().contains(_searchQuery);
      }).toList();
    });
  }

  void _toggleStudentSelection(User student) {
    setState(() {
      if (_selectedStudents.contains(student)) {
        _selectedStudents.remove(student);
      } else {
        _selectedStudents.add(student);
      }
    });
  }

  void _toggleSelectAll() {
    setState(() {
      if (_selectedStudents.length == _filteredStudents.length) {
        _selectedStudents.clear();
      } else {
        _selectedStudents = List.from(_filteredStudents);
      }
    });
  }

  Future<void> _assignStudents() async {
    if (_selectedStudents.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng chọn ít nhất một sinh viên'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isAssigning = true);

    try {
      // Get academic classes for auto-assignment
      final classesResult = await AdminCrudService.getAllClasses();
      final classesData = classesResult['data'] as List? ?? [];
      final allClasses = classesData.map((json) => ClassModel.fromJson(json)).toList();
      final academicClasses = allClasses.where((c) => c.classType == 'academic').toList();

      // Prepare student IDs
      final studentIds = _selectedStudents.map((s) => s.userId).toList();

      // First, add students to subject class
      await AdminCrudService.enrollStudents(
        classId: widget.subjectClass.id,
        studentIds: studentIds,
      );

      // Auto-assign students to academic classes with balancing logic
      if (academicClasses.isNotEmpty) {
        for (int i = 0; i < _selectedStudents.length; i++) {
          final student = _selectedStudents[i];
          // Round-robin assignment to balance class sizes
          final targetClass = academicClasses[i % academicClasses.length];

          // Update student with academic class
          await AdminCrudService.updateUser(
            userId: student.userId,
            academicClassId: targetClass.id,
            subjectClassIds: [widget.subjectClass.id], // Add subject class
          );
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Đã thêm ${_selectedStudents.length} sinh viên vào ${widget.subjectClass.displayName} '
              'và phân công vào lớp khóa học thành công'
            ),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop(true); // Return true to indicate success
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi khi thêm sinh viên: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isAssigning = false);
      }
    }
  }

  Widget _buildStudentCard(User student) {
    final isSelected = _selectedStudents.contains(student);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          child: Text(student.fullName.isNotEmpty ? student.fullName[0].toUpperCase() : 'S'),
        ),
        title: Text(student.fullName),
        subtitle: Text('${student.userId} • ${student.email}'),
        trailing: Checkbox(
          value: isSelected,
          onChanged: (_) => _toggleStudentSelection(student),
        ),
        onTap: () => _toggleStudentSelection(student),
        selected: isSelected,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Thêm sinh viên vào ${widget.subjectClass.displayName}'),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
        actions: [
          if (_selectedStudents.isNotEmpty)
            Chip(
              label: Text('${_selectedStudents.length} đã chọn'),
              backgroundColor: Colors.green[100],
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Container(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Tìm kiếm sinh viên...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _filterStudents('');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: _filterStudents,
            ),
          ),

          // Actions row
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Text(
                  '${_filteredStudents.length} sinh viên khả dụng',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: _filteredStudents.isEmpty ? null : _toggleSelectAll,
                  icon: const Icon(Icons.select_all),
                  label: Text(_selectedStudents.length == _filteredStudents.length
                      ? 'Bỏ chọn tất cả' : 'Chọn tất cả'),
                ),
              ],
            ),
          ),

          // Student list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredStudents.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.person_search,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _searchQuery.isNotEmpty
                                  ? 'Không tìm thấy sinh viên nào'
                                  : 'Không có sinh viên nào khả dụng',
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
                        itemCount: _filteredStudents.length,
                        itemBuilder: (context, index) {
                          return _buildStudentCard(_filteredStudents[index]);
                        },
                      ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _isAssigning ? null : _assignStudents,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isAssigning
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text('Thêm ${_selectedStudents.length} sinh viên'),
            ),
          ),
        ),
      ),
    );
  }
}