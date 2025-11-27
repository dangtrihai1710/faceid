import 'package:flutter/material.dart';
import '../../models/class_model.dart';
import '../../models/user.dart';
import '../../services/api_service.dart';
import 'dart:developer' as developer;

class ClassStudentsScreen extends StatefulWidget {
  final ClassModel classItem;
  final User currentUser;

  const ClassStudentsScreen({
    super.key,
    required this.classItem,
    required this.currentUser,
  });

  @override
  State<ClassStudentsScreen> createState() => _ClassStudentsScreenState();
}

class _ClassStudentsScreenState extends State<ClassStudentsScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _students = [];
  List<Map<String, dynamic>> _availableStudents = [];
  List<Map<String, dynamic>> _filteredStudents = [];
  List<Map<String, dynamic>> _filteredAvailableStudents = [];
    bool _isLoadingStudents = true;
  bool _isLoadingAvailable = true;
  final Set<String> _addingStudents = {}; // Track which students are being added

  @override
  void initState() {
    super.initState();
    _loadData();
    _searchController.addListener(_filterData);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      final token = ApiService.getToken();

      // Load current students in class
      final studentsResult = await ApiService.getAllUsers(token);
      final allUsers = studentsResult['accounts'] as List? ?? [];
      _students = allUsers
          .where((user) => user['role'] == 'student')
          .where((user) {
            final subjectClassIds = user['subject_class_ids'];
            final inThisClass = subjectClassIds is List
                ? subjectClassIds.contains(widget.classItem.id)
                : false;
            return inThisClass || user['academic_class_id'] == widget.classItem.id;
          })
          .map((e) => e as Map<String, dynamic>)
          .toList();

      // Load available students (not in this class)
      _availableStudents = allUsers
          .where((user) => user['role'] == 'student')
          .where((user) {
            final subjectClassIds = user['subject_class_ids'];
            final inThisClass = subjectClassIds is List
                ? subjectClassIds.contains(widget.classItem.id)
                : false;
            return !inThisClass && user['academic_class_id'] != widget.classItem.id;
          })
          .map((e) => e as Map<String, dynamic>)
          .toList();

      setState(() {
        _filteredStudents = List.from(_students);
        _filteredAvailableStudents = List.from(_availableStudents);
        _isLoadingStudents = false;
        _isLoadingAvailable = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingStudents = false;
        _isLoadingAvailable = false;
      });
      _showError('Lỗi khi tải dữ liệu: $e');
    }
  }

  void _filterData() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredStudents = _students.where((student) {
        final name = (student['full_name'] ?? '').toLowerCase();
        final userId = (student['user_id'] ?? '').toLowerCase();
        final email = (student['email'] ?? '').toLowerCase();
        return name.contains(query) || userId.contains(query) || email.contains(query);
      }).toList();

      _filteredAvailableStudents = _availableStudents.where((student) {
        final name = (student['full_name'] ?? '').toLowerCase();
        final userId = (student['user_id'] ?? '').toLowerCase();
        final email = (student['email'] ?? '').toLowerCase();
        return name.contains(query) || userId.contains(query) || email.contains(query);
      }).toList();
    });
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showSuccess(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _addStudentToClass(Map<String, dynamic> student) async {
    final studentId = student['_id']?.toString() ?? '';

    // Add to loading set
    setState(() {
      _addingStudents.add(studentId);
    });

    try {
      final token = ApiService.getToken();

      // Debug logging
      developer.log('🔍 DEBUG: Adding student to class', name: 'ClassStudents.addStudent');
      developer.log('🔍 DEBUG: Student data: $student', name: 'ClassStudents.addStudent');
      developer.log('🔍 DEBUG: Student ID: $studentId', name: 'ClassStudents.addStudent');
      developer.log('🔍 DEBUG: Class ID: ${widget.classItem.id}', name: 'ClassStudents.addStudent');
      developer.log('🔍 DEBUG: Class type: ${widget.classItem.classType}', name: 'ClassStudents.addStudent');

      // Determine class type and update accordingly
      final classType = widget.classItem.classType;
      final updateData = <String, dynamic>{};

      if (classType == 'academic') {
        updateData['academic_class_id'] = widget.classItem.id;
      } else {
        List<String> currentSubjectIds = [];
        if (student['subject_class_ids'] is List) {
          currentSubjectIds = (student['subject_class_ids'] as List)
              .map((e) => e.toString())
              .toList();
        }
        if (!currentSubjectIds.contains(widget.classItem.id)) {
          currentSubjectIds.add(widget.classItem.id);
          updateData['subject_class_ids'] = currentSubjectIds;
          developer.log('🔍 DEBUG: Adding to existing subject classes: $currentSubjectIds', name: 'ClassStudents.addStudent');
        } else {
          developer.log('🔍 DEBUG: Student already in this subject class', name: 'ClassStudents.addStudent');
        }
      }

      developer.log('🔍 DEBUG: Update data: $updateData', name: 'ClassStudents.addStudent');

      // Only send update if there's actual data to update
      if (updateData.isEmpty) {
        _showError('Sinh viên đã có trong lớp này rồi');
        return;
      }

      final result = await ApiService.updateUser(token, student['_id'], updateData);
      developer.log('🔍 DEBUG: API result: $result', name: 'ClassStudents.addStudent');

      if (result['success'] == true) {
        _showSuccess('Thêm sinh viên vào lớp thành công');

        // Move student from available to current list immediately
        if (mounted) {
          setState(() {
            // Remove from available list
            _availableStudents.removeWhere((s) => s['_id'] == student['_id']);
            _filteredAvailableStudents.removeWhere((s) => s['_id'] == student['_id']);

            // Add to current students list
            _students.add(student);
            _filteredStudents.add(student);
          });
        }

        // Also reload data to ensure consistency
        await _loadData();
      } else {
        _showError(result['message'] ?? 'Không thể thêm sinh viên vào lớp');
      }
    } catch (e) {
      developer.log('🔍 DEBUG: Exception caught: $e', name: 'ClassStudents.addStudent', level: 1000);
      _showError('Lỗi: $e');
    } finally {
      // Remove from loading set
      setState(() {
        _addingStudents.remove(studentId);
      });
    }
  }

  Future<void> _removeStudentFromClass(Map<String, dynamic> student) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: Text('Bạn có chắc chắn muốn xóa sinh viên "${student['full_name']}" khỏi lớp "${widget.classItem.name}"?'),
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

        // Determine class type and update accordingly
        final classType = widget.classItem.classType;
        final updateData = <String, dynamic>{};

        if (classType == 'academic') {
          updateData['academic_class_id'] = null;
        } else {
          List<String> currentSubjectIds = [];
          if (student['subject_class_ids'] is List) {
            currentSubjectIds = (student['subject_class_ids'] as List)
                .map((e) => e.toString())
                .toList();
          }
          currentSubjectIds.remove(widget.classItem.id);
          updateData['subject_class_ids'] = currentSubjectIds;
        }

        final result = await ApiService.updateUser(token, student['_id'], updateData);

        if (result['success'] == true) {
          _showSuccess('Xóa sinh viên khỏi lớp thành công');

          // Move student from current to available list immediately
          if (mounted) {
            setState(() {
              // Remove from current students list
              _students.removeWhere((s) => s['_id'] == student['_id']);
              _filteredStudents.removeWhere((s) => s['_id'] == student['_id']);

              // Add to available list
              _availableStudents.add(student);
              _filteredAvailableStudents.add(student);
            });
          }

          // Also reload data to ensure consistency
          await _loadData();
        } else {
          _showError(result['message'] ?? 'Không thể xóa sinh viên khỏi lớp');
        }
      } catch (e) {
        _showError('Lỗi: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Sinh viên - ${widget.classItem.name}'),
        backgroundColor: Colors.green[700],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: 'Tải lại',
          ),
        ],
      ),
      body: Column(
        children: [
          // Class info card
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  widget.classItem.classType == 'academic'
                      ? Colors.blue.withValues(alpha: 0.1)
                      : Colors.green.withValues(alpha: 0.1),
                  widget.classItem.classType == 'academic'
                      ? Colors.blue.withValues(alpha: 0.05)
                      : Colors.green.withValues(alpha: 0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: widget.classItem.classType == 'academic'
                    ? Colors.blue.withValues(alpha: 0.3)
                    : Colors.green.withValues(alpha: 0.3),
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(
                      widget.classItem.classType == 'academic' ? Icons.school : Icons.book,
                      size: 32,
                      color: widget.classItem.classType == 'academic' ? Colors.blue : Colors.green,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.classItem.name,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: widget.classItem.classType == 'academic'
                                  ? Colors.blue[700]
                                  : Colors.green[700],
                            ),
                          ),
                          Text(
                            widget.classItem.classType == 'academic' ? 'Lớp khóa học' : 'Lớp môn học',
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
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatItem('Sinh viên', '${_students.length}', Icons.people),
                    _buildStatItem('Tối đa', '${widget.classItem.maxStudents ?? '∞'}', Icons.person_outline),
                    _buildStatItem('Phòng học', widget.classItem.room, Icons.room),
                    _buildStatItem('Giảng viên', widget.classItem.displayInstructorName, Icons.person),
                  ],
                ),
              ],
            ),
          ),

          // Search bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Tìm kiếm sinh viên',
                hintText: 'Nhập tên, mã sinh viên hoặc email',
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
          ),

          // Tabs
          Expanded(
            child: DefaultTabController(
              length: 2,
              child: Column(
                children: [
                  TabBar(
                    labelColor: widget.classItem.classType == 'academic' ? Colors.blue : Colors.green,
                    unselectedLabelColor: Colors.grey,
                    indicatorColor: widget.classItem.classType == 'academic' ? Colors.blue : Colors.green,
                    tabs: [
                      Tab(
                        text: 'Sinh viên trong lớp (${_students.length})',
                        icon: const Icon(Icons.people),
                      ),
                      Tab(
                        text: 'Thêm sinh viên (${_availableStudents.length})',
                        icon: const Icon(Icons.person_add),
                      ),
                    ],
                  ),
                  Expanded(
                    child: TabBarView(
                      children: [
                        // Students in class tab
                        _isLoadingStudents
                            ? const Center(child: CircularProgressIndicator())
                            : _filteredStudents.isEmpty
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
                                          'Chưa có sinh viên nào trong lớp',
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
                                      final student = _filteredStudents[index];
                                      return Card(
                                        margin: const EdgeInsets.only(bottom: 8),
                                        child: ListTile(
                                          leading: CircleAvatar(
                                            backgroundColor: widget.classItem.classType == 'academic'
                                                ? Colors.blue[700]
                                                : Colors.green[700],
                                            child: Text(
                                              (student['full_name'] ?? '').substring(0, 1).toUpperCase(),
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          title: Text(
                                            student['full_name'] ?? '',
                                            style: const TextStyle(fontWeight: FontWeight.w600),
                                          ),
                                          subtitle: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text('Mã: ${student['user_id'] ?? ''}'),
                                              Text(student['email'] ?? ''),
                                            ],
                                          ),
                                          trailing: IconButton(
                                            icon: const Icon(Icons.remove_circle, color: Colors.red),
                                            onPressed: () => _removeStudentFromClass(student),
                                            tooltip: 'Xóa khỏi lớp',
                                          ),
                                        ),
                                      );
                                    },
                                  ),

                        // Available students tab
                        _isLoadingAvailable
                            ? const Center(child: CircularProgressIndicator())
                            : _filteredAvailableStudents.isEmpty
                                ? Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.person_add_disabled,
                                          size: 64,
                                          color: Colors.grey[400],
                                        ),
                                        const SizedBox(height: 16),
                                        Text(
                                          'Không có sinh viên nào để thêm',
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
                                    itemCount: _filteredAvailableStudents.length,
                                    itemBuilder: (context, index) {
                                      final student = _filteredAvailableStudents[index];
                                      return Card(
                                        margin: const EdgeInsets.only(bottom: 8),
                                        child: ListTile(
                                          leading: CircleAvatar(
                                            backgroundColor: Colors.orange[700],
                                            child: Text(
                                              (student['full_name'] ?? '').substring(0, 1).toUpperCase(),
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          title: Text(
                                            student['full_name'] ?? '',
                                            style: const TextStyle(fontWeight: FontWeight.w600),
                                          ),
                                          subtitle: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text('Mã: ${student['user_id'] ?? ''}'),
                                              Text(student['email'] ?? ''),
                                            ],
                                          ),
                                          trailing: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              _addingStudents.contains(student['_id']?.toString() ?? '')
                                                  ? SizedBox(
                                                      width: 20,
                                                      height: 20,
                                                      child: CircularProgressIndicator(
                                                        strokeWidth: 2,
                                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
                                                      ),
                                                    )
                                                  : ElevatedButton.icon(
                                                      onPressed: () => _addStudentToClass(student),
                                                      icon: const Icon(Icons.add, size: 16),
                                                      label: const Text('Lưu'),
                                                      style: ElevatedButton.styleFrom(
                                                        backgroundColor: Colors.green,
                                                        foregroundColor: Colors.white,
                                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                                        minimumSize: Size(60, 32),
                                                      ),
                                                    ),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }
}