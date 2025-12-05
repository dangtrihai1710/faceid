import 'package:flutter/material.dart';
import '../../models/user.dart';
import '../../models/class_model.dart';
import '../../core/services/api_service.dart' as core_api;
import 'teacher_attendance_code_screen.dart';
import 'teacher_class_students_screen.dart';

class TeacherAttendanceManagementScreen extends StatefulWidget {
  final User currentUser;

  const TeacherAttendanceManagementScreen({
    super.key,
    required this.currentUser,
  });

  @override
  State<TeacherAttendanceManagementScreen> createState() => _TeacherAttendanceManagementScreenState();
}

class _TeacherAttendanceManagementScreenState extends State<TeacherAttendanceManagementScreen> {
  List<ClassModel> _allClasses = [];
  List<ClassModel> _attendanceClasses = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadClasses();
  }

  Future<void> _loadClasses() async {
    setState(() => _isLoading = true);

    try {
      final classesData = await core_api.ApiService.getTeacherClasses();

      if (classesData.isNotEmpty) {
        final allClasses = classesData.map((json) => ClassModel.fromJson(json)).toList();

        // Filter classes by current instructor
        final instructorClasses = allClasses.where((classItem) {
          return classItem.instructor == widget.currentUser.userId ||
                 classItem.instructorName?.contains(widget.currentUser.fullName) == true;
        }).toList();

        // Filter for attendance-relevant classes
        final attendanceClasses = instructorClasses.where((classModel) {
          return classModel.isToday || classModel.isOngoing ||
                 (DateTime.now().difference(classModel.endTime).inHours < 2);
        }).toList();

        if (mounted) {
          setState(() {
            _allClasses = instructorClasses;
            _attendanceClasses = attendanceClasses;
            _isLoading = false;
          });
        }
      } else {
        throw Exception('Failed to load classes');
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

  void _showAttendanceOptions(ClassModel classModel) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Điểm danh'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.how_to_reg, size: 64, color: Colors.green),
            const SizedBox(height: 16),
            Text('Lớp: ${classModel.displayName}'),
            Text('Phòng: ${classModel.room}'),
            const SizedBox(height: 16),
            const Text('Chọn hình thức điểm danh:'),
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
              _generateQRCode(classModel);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
            child: const Text('QR Code'),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _generatePINCode(classModel);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('Mã PIN'),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _faceScanning(classModel);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
            child: const Text('Quét mặt'),
          ),
        ],
      ),
    );
  }

  void _generateQRCode(ClassModel classModel) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => TeacherAttendanceCodeScreen(
          currentUser: widget.currentUser,
          classModel: classModel,
          codeType: 'qr',
        ),
      ),
    );
  }

  void _generatePINCode(ClassModel classModel) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => TeacherAttendanceCodeScreen(
          currentUser: widget.currentUser,
          classModel: classModel,
          codeType: 'pin',
        ),
      ),
    );
  }

  void _viewStudentList(ClassModel classModel) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => TeacherClassStudentsScreen(
          currentUser: widget.currentUser,
          classModel: classModel,
        ),
      ),
    );
  }

  void _faceScanning(ClassModel classModel) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Tính năng quét mặt điểm danh đang được phát triển cho lớp: ${classModel.displayName}'),
        backgroundColor: Colors.teal,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _isLoading
        ? const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Đang tải dữ liệu...'),
              ],
            ),
          )
        : RefreshIndicator(
            onRefresh: _loadClasses,
            child: Column(
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(16),
                  color: Colors.green[50],
                  child: Row(
                    children: [
                      Icon(Icons.qr_code_scanner, color: Colors.green[700], size: 32),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Quản lý điểm danh',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.green[800],
                              ),
                            ),
                            Text(
                              'Chọn lớp để bắt đầu phiên điểm danh',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.green[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Stats
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildStatCard('Lớp hôm nay', _attendanceClasses.where((c) => c.isToday).length.toString(), Colors.blue),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard('Đang diễn ra', _attendanceClasses.where((c) => c.isOngoing).length.toString(), Colors.green),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard('Tổng lớp', _allClasses.length.toString(), Colors.orange),
                      ),
                    ],
                  ),
                ),

                // Class list
                Expanded(
                  child: _attendanceClasses.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.event_busy, size: 64, color: Colors.grey[400]),
                              const SizedBox(height: 16),
                              Text(
                                'Không có lớp nào cần điểm danh',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Các lớp sẽ xuất hiện khi đến thời gian học',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[500],
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _attendanceClasses.length,
                          itemBuilder: (context, index) {
                            final classModel = _attendanceClasses[index];
                            return _buildAttendanceClassCard(classModel);
                          },
                        ),
                ),
              ],
            ),
          );
  }

  Widget _buildStatCard(String title, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: color.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceClassCard(ClassModel classModel) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: classModel.isOngoing
                        ? Colors.green.withValues(alpha: 0.1)
                        : Colors.blue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    classModel.isOngoing ? Icons.play_circle : Icons.schedule,
                    color: classModel.isOngoing ? Colors.green : Colors.blue,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        classModel.displayName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        classModel.subject,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                if (classModel.isOngoing)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Đang diễn ra',
                      style: TextStyle(
                        color: Colors.green,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  classModel.timeRange,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(width: 16),
                Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  classModel.room,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.people_outline, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  'Sinh viên: ${classModel.studentIds?.length ?? 0}${classModel.maxStudents != null ? '/${classModel.maxStudents}' : ''}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _showAttendanceOptions(classModel),
                    icon: const Icon(Icons.qr_code_scanner),
                    label: const Text('Tạo mã điểm danh'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _viewStudentList(classModel),
                    icon: const Icon(Icons.people),
                    label: const Text('Xem sinh viên'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}