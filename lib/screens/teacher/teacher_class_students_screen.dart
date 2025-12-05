import 'package:flutter/material.dart';
import '../../models/user.dart';
import '../../models/class_model.dart';
import '../../models/student_model.dart';
import '../../core/services/api_service.dart' as CoreApi;
import 'teacher_attendance_code_screen.dart';
import 'dart:developer' as developer;

class TeacherClassStudentsScreen extends StatefulWidget {
  final User currentUser;
  final ClassModel classModel;

  const TeacherClassStudentsScreen({
    super.key,
    required this.currentUser,
    required this.classModel,
  });

  @override
  State<TeacherClassStudentsScreen> createState() => _TeacherClassStudentsScreenState();
}

class _TeacherClassStudentsScreenState extends State<TeacherClassStudentsScreen> {
  List<StudentModel> _students = [];
  bool _isLoading = true;
  String _searchQuery = '';
  Map<String, String> _attendanceStatus = {};

  @override
  void initState() {
    super.initState();
    _checkAuthentication();
  }

  void _checkAuthentication() {
    final hasToken = CoreApi.ApiService.hasToken();
    developer.log('🔑 Authentication check in students screen: ${hasToken ? "Has token" : "No token"}', name: 'TeacherClassStudents');

    if (!hasToken) {
      // No token, redirect back
      developer.log('🚫 No authentication token found in students screen, going back', name: 'TeacherClassStudents');
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Vui lòng đăng nhập để tiếp tục'),
              backgroundColor: Colors.orange,
            ),
          );
          Navigator.of(context).pop();
        }
      });
      return;
    }

    // Token exists, proceed to load students
    developer.log('✅ Authentication passed in students screen, loading students', name: 'TeacherClassStudents');
    _loadStudents();
  }

  Future<void> _loadStudents() async {
    setState(() => _isLoading = true);

    try {
      developer.log('🔍 DEBUG: Loading students for class ${widget.classModel.id}', name: 'TeacherClassStudents.load');

      // For now, create mock students since the API calls are complex
      // In a real implementation, you would call the appropriate API endpoints
      final List<StudentModel> students = [];

      // Mock student data - replace with actual API calls
      if (widget.classModel.studentIds != null && widget.classModel.studentIds!.isNotEmpty) {
        for (int i = 0; i < widget.classModel.studentIds!.length; i++) {
          final studentId = widget.classModel.studentIds![i];
          final student = StudentModel.fromJson({
            'id': studentId,
            'studentId': studentId,
            'fullName': 'Sinh viên ${i + 1}', // Mock name
            'email': '$studentId@student.edu.vn',
            'phone': null,
            'classId': widget.classModel.id,
            'avatar': null,
            'createdAt': DateTime.now().toIso8601String(),
          });
          students.add(student);
        }
      }

      developer.log('🔍 DEBUG: Total students created: ${students.length}', name: 'TeacherClassStudents.load');

      // Initialize attendance status
      final attendanceMap = <String, String>{};
      for (final student in students) {
        attendanceMap[student.id] = 'absent'; // Default status
      }

      if (mounted) {
        setState(() {
          _students = students;
          _attendanceStatus = attendanceMap;
          _isLoading = false;
        });
      }
    } catch (e) {
      developer.log('🔍 DEBUG: Error in _loadStudents: $e', name: 'TeacherClassStudents.load', level: 1000);
      if (mounted) {
        setState(() => _isLoading = false);

        // Check if it's an authentication error
        final errorMessage = e.toString();
        if (errorMessage.contains('403') || errorMessage.contains('Not authenticated') || errorMessage.contains('token')) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.'),
              backgroundColor: Colors.red,
            ),
          );
          // Navigate back to previous screen (class management)
          Future.delayed(const Duration(seconds: 2), () {
            if (mounted) {
              Navigator.of(context).pop();
            }
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Lỗi tải dữ liệu sinh viên: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  List<StudentModel> get _filteredStudents {
    developer.log('🔍 DEBUG: Getting filtered students. Search query: "$_searchQuery", Total students: ${_students.length}', name: 'TeacherClassStudents.filter');

    if (_searchQuery.isEmpty) {
      developer.log('🔍 DEBUG: No search query, returning all ${_students.length} students', name: 'TeacherClassStudents.filter');
      return _students;
    }

    final filtered = _students.where((student) =>
      student.fullName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
      student.email.toLowerCase().contains(_searchQuery.toLowerCase()) ||
      (student.phone?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false)
    ).toList();

    developer.log('🔍 DEBUG: Filtered to ${filtered.length} students', name: 'TeacherClassStudents.filter');
    return filtered;
  }

  void _toggleAttendance(String studentId) {
    setState(() {
      final currentStatus = _attendanceStatus[studentId] ?? 'absent';
      switch (currentStatus) {
        case 'absent':
          _attendanceStatus[studentId] = 'present';
          break;
        case 'present':
          _attendanceStatus[studentId] = 'late';
          break;
        case 'late':
          _attendanceStatus[studentId] = 'absent';
          break;
      }
    });
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'present':
        return Colors.green;
      case 'late':
        return Colors.orange;
      case 'absent':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'present':
        return 'Có mặt';
      case 'late':
        return 'Muộn';
      case 'absent':
        return 'Vắng';
      default:
        return 'Chưa điểm danh';
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'present':
        return Icons.check_circle;
      case 'late':
        return Icons.schedule;
      case 'absent':
        return Icons.cancel;
      default:
        return Icons.help_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredStudents = _filteredStudents;
    final presentCount = _attendanceStatus.values.where((s) => s == 'present').length;
    final lateCount = _attendanceStatus.values.where((s) => s == 'late').length;
    final absentCount = _attendanceStatus.values.where((s) => s == 'absent').length;

    developer.log('🔍 DEBUG: Building UI - Loading: $_isLoading, Total students: ${_students.length}, Filtered: ${filteredStudents.length}', name: 'TeacherClassStudents.build');

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(widget.classModel.displayName),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: _addStudents,
            icon: const Icon(Icons.person_add),
            tooltip: 'Thêm sinh viên',
          ),
          IconButton(
            onPressed: _showAttendanceOptions,
            icon: const Icon(Icons.more_vert),
            tooltip: 'Tùy chọn điểm danh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Đang tải danh sách sinh viên...'),
                ],
              ),
            )
          : Column(
              children: [
                // Statistics Card
                Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildStatItem('Có mặt', presentCount.toString(), Colors.green),
                      ),
                      Expanded(
                        child: _buildStatItem('Muộn', lateCount.toString(), Colors.orange),
                      ),
                      Expanded(
                        child: _buildStatItem('Vắng', absentCount.toString(), Colors.red),
                      ),
                    ],
                  ),
                ),

                // Search Bar
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  child: TextField(
                    onChanged: (value) {
                      setState(() => _searchQuery = value);
                    },
                    decoration: InputDecoration(
                      hintText: 'Tìm kiếm sinh viên...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                  ),
                ),

                const SizedBox(height: 8),

                // Students List
                Expanded(
                  child: filteredStudents.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.people, size: 64, color: Colors.grey[400]),
                              const SizedBox(height: 16),
                              Text(
                                'Không có sinh viên nào',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: filteredStudents.length,
                          itemBuilder: (context, index) {
                            final student = filteredStudents[index];
                            final status = _attendanceStatus[student.id] ?? 'absent';
                            return _buildStudentCard(student, status);
                          },
                        ),
                ),
              ],
            ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton(
            heroTag: "save",
            onPressed: _saveAttendance,
            backgroundColor: Colors.green,
            tooltip: 'Lưu điểm danh',
            child: const Icon(Icons.save),
          ),
          const SizedBox(height: 8),
          FloatingActionButton(
            heroTag: "qr",
            onPressed: _generateQRCode,
            backgroundColor: Colors.blue,
            tooltip: 'Tạo QR Code',
            child: const Icon(Icons.qr_code),
          ),
          const SizedBox(height: 8),
          FloatingActionButton(
            heroTag: "pin",
            onPressed: _generatePINCode,
            backgroundColor: Colors.orange,
            tooltip: 'Tạo mã PIN',
            child: const Icon(Icons.vpn_key),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
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

  Widget _buildStudentCard(StudentModel student, String status) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.blue[100],
          child: student.avatar != null
              ? ClipOval(
                  child: Image.network(
                    student.avatar!,
                    width: 40,
                    height: 40,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Icon(Icons.person, color: Colors.blue[700]);
                    },
                  ),
                )
              : Icon(Icons.person, color: Colors.blue[700]),
        ),
        title: Text(
          student.fullName,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (student.studentId != null)
              Text(
                student.studentId!,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            if (student.phone != null)
              Text(
                student.phone!,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[500],
                ),
              ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Remove student button
            IconButton(
              onPressed: () => _removeStudent(student.id, student.fullName),
              icon: const Icon(Icons.remove_circle),
              color: Colors.red,
              tooltip: 'Xóa sinh viên khỏi lớp',
              iconSize: 20,
            ),
            // Attendance status
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _getStatusColor(status).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _getStatusIcon(status),
                    size: 16,
                    color: _getStatusColor(status),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _getStatusText(status),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _getStatusColor(status),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        onTap: () => _toggleAttendance(student.id),
      ),
    );
  }

  void _showAttendanceOptions() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tùy chọn điểm danh'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Chọn phương thức điểm danh cho lớp này:'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _markAllPresent();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Điểm danh tất cả'),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _clearAllAttendance();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Xóa tất cả'),
          ),
        ],
      ),
    );
  }

  void _markAllPresent() {
    setState(() {
      for (final student in _students) {
        _attendanceStatus[student.id] = 'present';
      }
    });
  }

  void _clearAllAttendance() {
    setState(() {
      for (final student in _students) {
        _attendanceStatus[student.id] = 'absent';
      }
    });
  }

  void _saveAttendance() async {
    try {
      // Prepare attendance data for API
      final attendanceUpdates = <Map<String, dynamic>>[];

      for (final student in _students) {
        final status = _attendanceStatus[student.id] ?? 'absent';
        attendanceUpdates.add({
          'student_id': student.id,
          'status': status,
        });
      }

      final attendanceData = {
        'attendance_updates': attendanceUpdates,
      };

      final result = await CoreApi.ApiService.saveManualAttendance(widget.classModel.id, attendanceData);

      if (result != null && result['success'] == true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Đã lưu điểm danh thành công cho ${result['data']['marked_count']} sinh viên!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        throw Exception(result?['message'] ?? 'Failed to save attendance');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi lưu điểm danh: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _generateQRCode() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => TeacherAttendanceCodeScreen(
          currentUser: widget.currentUser,
          classModel: widget.classModel,
          codeType: 'qr',
        ),
      ),
    );
  }

  void _generatePINCode() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => TeacherAttendanceCodeScreen(
          currentUser: widget.currentUser,
          classModel: widget.classModel,
          codeType: 'pin',
        ),
      ),
    );
  }

  void _addStudents() {
    // Show dialog to add students
    showDialog(
      context: context,
      builder: (context) => AddStudentsDialog(
        classModel: widget.classModel,
        onStudentsAdded: _onStudentsAdded,
      ),
    );
  }

  void _onStudentsAdded() {
    // Refresh the student list
    _loadStudents();
  }

  void _removeStudent(String studentId, String studentName) {
    // Show confirmation dialog to remove student
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa sinh viên'),
        content: Text('Bạn có chắc muốn xóa sinh viên $studentName khỏi lớp này?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _confirmRemoveStudent(studentId, studentName);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
  }

  void _confirmRemoveStudent(String studentId, String studentName) async {
    try {
      // Call API to remove student from class
      final result = await CoreApi.ApiService.removeStudents(widget.classModel.id, [studentId]);

      if (result != null && result['success'] == true) {
        // Refresh the student list
        _loadStudents();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Đã xóa sinh viên $studentName khỏi lớp'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        throw Exception(result?['message'] ?? 'Failed to remove student');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi khi xóa sinh viên: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

// Dialog for adding students to class
class AddStudentsDialog extends StatefulWidget {
  final ClassModel classModel;
  final VoidCallback onStudentsAdded;

  const AddStudentsDialog({
    super.key,
    required this.classModel,
    required this.onStudentsAdded,
  });

  @override
  State<AddStudentsDialog> createState() => _AddStudentsDialogState();
}

class _AddStudentsDialogState extends State<AddStudentsDialog> {
  final TextEditingController _studentIdsController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // No need to load students, use text input instead
  }

  @override
  void dispose() {
    _studentIdsController.dispose();
    super.dispose();
  }

  // Simplified: no need to load available students, just use text input


  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Thêm sinh viên vào lớp'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Nhập ID sinh viên (cách nhau bằng dấu phẩy):'),
          const SizedBox(height: 16),
          TextField(
            controller: _studentIdsController,
            decoration: const InputDecoration(
              hintText: 'Ví dụ: SV001, SV002, SV003',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Hủy'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _addStudentsFromInput,
          child: _isLoading ? const CircularProgressIndicator() : const Text('Thêm'),
        ),
      ],
    );
  }

  Future<void> _addStudentsFromInput() async {
    final input = _studentIdsController.text.trim();
    if (input.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập ID sinh viên')),
      );
      return;
    }

    // Parse student IDs from input
    final studentIds = input
        .split(',')
        .map((id) => id.trim())
        .where((id) => id.isNotEmpty)
        .toList();

    if (studentIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không tìm thấy ID sinh viên hợp lệ')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final result = await CoreApi.ApiService.enrollStudents(widget.classModel.id, studentIds);

      if (result != null && result['success'] == true) {
        widget.onStudentsAdded();
        Navigator.of(context).pop();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đã thêm ${result['data']['enrolled_count']} sinh viên vào lớp'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        throw Exception(result?['message'] ?? 'Failed to add students');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi khi thêm sinh viên: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}