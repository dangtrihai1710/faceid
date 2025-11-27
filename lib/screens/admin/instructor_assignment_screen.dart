import 'package:flutter/material.dart';
import '../../models/class_model.dart';
import '../../models/user.dart';
import '../../services/api_service.dart';

class InstructorAssignmentScreen extends StatefulWidget {
  final ClassModel classItem;
  final User currentUser;

  const InstructorAssignmentScreen({
    super.key,
    required this.classItem,
    required this.currentUser,
  });

  @override
  State<InstructorAssignmentScreen> createState() => _InstructorAssignmentScreenState();
}

class _InstructorAssignmentScreenState extends State<InstructorAssignmentScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _instructors = [];
  List<Map<String, dynamic>> _filteredInstructors = [];
  Map<String, dynamic>? _selectedInstructor;
  bool _isLoading = true;
  bool _isAssigning = false;
  final bool _isUpdatingClass = false;

  @override
  void initState() {
    super.initState();
    _loadInstructors();
    _searchController.addListener(_filterInstructors);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadInstructors() async {
    try {
      final token = ApiService.getToken();
      final instructors = await ApiService.getInstructors(token);

      setState(() {
        _instructors = instructors;
        _filteredInstructors = List.from(instructors);

        // Pre-select current instructor if any
        if (widget.classItem.instructor.isNotEmpty) {
          _selectedInstructor = instructors.firstWhere(
            (instructor) => instructor['user_id'] == widget.classItem.instructor,
            orElse: () => instructors.isNotEmpty ? instructors.first : {} as Map<String, dynamic>,
          );
        }

        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showError('Lỗi khi tải danh sách giảng viên: $e');
    }
  }

  void _filterInstructors() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredInstructors = _instructors.where((instructor) {
        final name = (instructor['full_name'] ?? '').toLowerCase();
        final userId = (instructor['user_id'] ?? '').toLowerCase();
        final email = (instructor['email'] ?? '').toLowerCase();
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

  String _getShortenedName(String name) {
    if (name.length <= 15) return name;
    return '${name.substring(0, 15)}...';
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

  Future<void> _assignInstructor() async {
    if (_selectedInstructor == null) {
      _showError('Vui lòng chọn một giảng viên');
      return;
    }

    setState(() => _isAssigning = true);

    try {
      final token = ApiService.getToken();

      // Update the class with the new instructor
      final classUpdateData = {
        'instructor_id': _selectedInstructor!['user_id'],
        'instructor_name': _selectedInstructor!['full_name'],
      };

      final classResult = await ApiService.updateClass(
        token,
        widget.classItem.id,
        classUpdateData,
      );

      if (classResult['success'] == true) {
        // Update instructor's subject classes if needed
        final currentSubjectIds = (_selectedInstructor!['subject_class_ids'] as List?)?.cast<String>() ?? [];
        if (!currentSubjectIds.contains(widget.classItem.id)) {
          currentSubjectIds.add(widget.classItem.id);
          final instructorUpdateData = {
            'subject_class_ids': currentSubjectIds,
          };

          await ApiService.updateUser(
            token,
            _selectedInstructor!['_id'],
            instructorUpdateData,
          );
        }

        _showSuccess('Phân công giảng viên thành công');
        if (mounted) {
          Navigator.of(context).pop(true); // Return true to indicate success
        }
      } else {
        _showError(classResult['message'] ?? 'Không thể phân công giảng viên');
      }
    } catch (e) {
      _showError('Lỗi khi phân công giảng viên: $e');
    } finally {
      if (mounted) {
        setState(() => _isAssigning = false);
      }
    }
  }

  Widget _buildInstructorCard(Map<String, dynamic> instructor) {
    final isSelected = _selectedInstructor?['_id'] == instructor['_id'];

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedInstructor = instructor;
          });
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              // Custom radio button using Icon to avoid deprecated Radio widget
              Icon(
                isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                color: Theme.of(context).primaryColor,
                size: 24,
              ),
              const SizedBox(width: 12),
              CircleAvatar(
                backgroundColor: Colors.purple[100],
                child: Text(
                  (instructor['full_name'] ?? '').substring(0, 1).toUpperCase(),
                  style: TextStyle(color: Colors.purple[700]),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      instructor['full_name'] ?? '',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    Text('Mã: ${instructor['user_id'] ?? ''}'),
                    Text(instructor['email'] ?? ''),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildClassInfoCard() {
    return Container(
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
              _buildStatItem('Phòng học', widget.classItem.room, Icons.room),
              _buildStatItem('Sĩ tối đa', '${widget.classItem.maxStudents ?? '∞'}', Icons.person_outline),
              _buildStatItem('Giảng viên', widget.classItem.displayInstructorName, Icons.person),
            ],
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
          textAlign: TextAlign.center,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Phân công giảng viên - ${widget.classItem.name}'),
        backgroundColor: Colors.purple[700],
        foregroundColor: Colors.white,
        actions: [
          if (_selectedInstructor != null)
            Chip(
              label: Text('Đã chọn: ${_getShortenedName(_selectedInstructor!['full_name'] ?? '')}'),
              backgroundColor: Colors.purple[100],
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // Class info card
          _buildClassInfoCard(),

          // Search bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Tìm kiếm giảng viên',
                hintText: 'Nhập tên, mã giảng viên hoặc email',
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

          // Instructors count
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Text(
                  '${_filteredInstructors.length} giảng viên',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
              ],
            ),
          ),

          // Instructor list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredInstructors.isEmpty
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
                              'Không có giảng viên nào trong hệ thống',
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
                        itemCount: _filteredInstructors.length,
                        itemBuilder: (context, index) {
                          return _buildInstructorCard(_filteredInstructors[index]);
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
              color: Colors.black.withValues(alpha: 0.1),
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
              onPressed: (_isAssigning || _isUpdatingClass) ? null : _assignInstructor,
              style: ElevatedButton.styleFrom(
                backgroundColor: _selectedInstructor != null ? Colors.purple[700] : Colors.grey,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: (_isAssigning || _isUpdatingClass)
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(
                      _selectedInstructor != null
                          ? 'Phân công ${_selectedInstructor!['full_name']}'
                          : 'Vui lòng chọn giảng viên',
                    ),
            ),
          ),
        ),
      ),
    );
  }
}