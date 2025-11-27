import 'package:flutter/material.dart';
import '../../models/user.dart';
import '../../models/class_model.dart';
import '../../models/student_model.dart';
import '../../services/api_service.dart';
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
    _loadStudents();
  }

  Future<void> _loadStudents() async {
    setState(() => _isLoading = true);

    try {
      developer.log('🔍 DEBUG: Loading students for class ${widget.classModel.id}', name: 'TeacherClassStudents.load');

      // First, get class details with student IDs
      final classResponse = await ApiService.makeAuthenticatedRequest(
        'GET',
        '/api/v1/classes/${widget.classModel.id}',
      );

      developer.log('🔍 DEBUG: Class response: $classResponse', name: 'TeacherClassStudents.load');

      if (classResponse['success'] != true || classResponse['data'] == null) {
        throw Exception(classResponse['message'] ?? 'Failed to load class details');
      }

      final classData = classResponse['data'];
      final List<dynamic> studentIds = classData['studentIds'] ?? classData['student_ids'] ?? [];

      developer.log('🔍 DEBUG: Found ${studentIds.length} student IDs: $studentIds', name: 'TeacherClassStudents.load');

      // Get detailed information for each student
      final List<StudentModel> students = [];

      for (final studentId in studentIds) {
        try {
          developer.log('🔍 DEBUG: Loading student $studentId', name: 'TeacherClassStudents.load');
          final userResponse = await ApiService.makeAuthenticatedRequest(
            'GET',
            '/api/v1/users/$studentId',
          );

          developer.log('🔍 DEBUG: User response for $studentId: $userResponse', name: 'TeacherClassStudents.load');

          if (userResponse['success'] == true && userResponse['data'] != null) {
            final userData = userResponse['data'];
            developer.log('🔍 DEBUG: User data for $studentId: $userData', name: 'TeacherClassStudents.load');

            // Convert user data to StudentModel - use studentId as ID
            final student = StudentModel.fromJson({
              'id': studentId, // Use the student ID directly
              'studentId': studentId, // Also use as studentId field
              'fullName': userData['fullName'] ?? userData['full_name'] ?? 'Unknown Student',
              'email': userData['email'] ?? '',
              'phone': userData['phone'],
              'classId': widget.classModel.id,
              'avatar': userData['avatar'],
              'createdAt': userData['createdAt'],
            });

            developer.log('🔍 DEBUG: Created student model: ${student.fullName}', name: 'TeacherClassStudents.load');
            students.add(student);
          } else {
            developer.log('🔍 DEBUG: Failed to load user data for $studentId', name: 'TeacherClassStudents.load', level: 1000);
          }
        } catch (e) {
          developer.log('🔍 DEBUG: Error loading student $studentId: $e', name: 'TeacherClassStudents.load', level: 1000);
          // Continue with other students even if one fails
        }
      }

      developer.log('🔍 DEBUG: Total students created: ${students.length}', name: 'TeacherClassStudents.load');

      // Initialize attendance status
      final attendanceMap = <String, String>{};
      for (final student in students) {
        attendanceMap[student.id] = 'absent'; // Default status
      }

      developer.log('🔍 DEBUG: Setting state with ${students.length} students', name: 'TeacherClassStudents.load');

      if (mounted) {
        setState(() {
          _students = students;
          _attendanceStatus = attendanceMap;
          _isLoading = false;
        });

        developer.log('🔍 DEBUG: State set. Students count: ${_students.length}', name: 'TeacherClassStudents.load');
        for (final student in _students) {
          developer.log('🔍 DEBUG: Student in state: ${student.fullName} (${student.id})', name: 'TeacherClassStudents.load');
        }
      }
    } catch (e) {
      developer.log('🔍 DEBUG: Error in _loadStudents: $e', name: 'TeacherClassStudents.load', level: 1000);
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi tải dữ liệu sinh viên: $e'),
            backgroundColor: Colors.red,
          ),
        );
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
        trailing: Container(
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
      // Manual attendance saving - placeholder implementation
      // Note: Backend endpoint for manual attendance needs to be implemented
      // Note: Proper attendance saving will be implemented when backend endpoint is available
      // Expected API: ApiService.saveManualAttendance(classId: widget.classModel.id, attendanceData: _students)

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã lưu điểm danh thành công! (Tính năng đang phát triển)'),
            backgroundColor: Colors.green,
          ),
        );
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
}