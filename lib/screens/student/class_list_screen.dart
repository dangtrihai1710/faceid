import 'package:flutter/material.dart';
import '../../models/user.dart';
import '../../models/class_model.dart';
import '../../services/class_service.dart';

class ClassListScreen extends StatefulWidget {
  final User currentUser;

  const ClassListScreen({
    super.key,
    required this.currentUser,
  });

  @override
  State<ClassListScreen> createState() => _ClassListScreenState();
}

class _ClassListScreenState extends State<ClassListScreen> {
  List<ClassModel> _allClasses = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadClasses();
  }

  Future<void> _loadClasses() async {
    try {
      final classes = await ClassService.getUpcomingClasses();
      setState(() {
        _allClasses = classes;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi tải danh sách môn học: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Danh sách môn học'),
        backgroundColor: Colors.orange[700],
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Đang tải danh sách môn học...'),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadClasses,
              child: _allClasses.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.schedule,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Không có môn học nào',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _allClasses.length,
                      itemBuilder: (context, index) {
                        final classModel = _allClasses[index];
                        return _buildClassCard(classModel);
                      },
                    ),
            ),
    );
  }

  Widget _buildClassCard(ClassModel classModel) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _getClassStatusColor(classModel).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      _getClassStatusIcon(classModel),
                      color: _getClassStatusColor(classModel),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          classModel.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          classModel.subject,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Class Details
              _buildDetailRow('Giảng viên', classModel.instructor),
              _buildDetailRow('Phòng học', classModel.room),
              _buildDetailRow('Thời gian', classModel.timeRange),

              if (classModel.description != null && classModel.description!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  classModel.description!,
                  style: TextStyle(
                    color: Colors.grey[700],
                    fontSize: 13,
                  ),
                ),
              ],

              const SizedBox(height: 12),

              // Status and Action
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _getClassStatusColor(classModel).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      classModel.statusText,
                      style: TextStyle(
                        color: _getClassStatusColor(classModel),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),

                  // Action Buttons
                  Row(
                    children: [
                      if (classModel.isToday)
                        IconButton(
                          onPressed: () {
                            _showClassDetails(classModel);
                          },
                          icon: Icon(
                            Icons.info_outline,
                            color: Colors.blue[700],
                          ),
                          tooltip: 'Xem chi tiết',
                        ),
                      if (classModel.isAttendanceOpen)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.green,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'Đang mở điểm danh',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(
            Icons.label,
            size: 14,
            color: Colors.grey[600],
          ),
          const SizedBox(width: 8),
          Text(
            '$label:',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[800],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getClassStatusColor(ClassModel classModel) {
    if (classModel.isAttendanceOpen) return Colors.green;
    if (classModel.isOngoing) return Colors.blue;
    if (classModel.isUpcoming && classModel.isToday) return Colors.orange;
    if (classModel.isUpcoming) return Colors.purple;
    return Colors.grey;
  }

  IconData _getClassStatusIcon(ClassModel classModel) {
    if (classModel.isAttendanceOpen) return Icons.how_to_reg;
    if (classModel.isOngoing) return Icons.play_circle;
    if (classModel.isUpcoming && classModel.isToday) return Icons.schedule;
    if (classModel.isUpcoming) return Icons.event;
    return Icons.check_circle;
  }

  void _showClassDetails(ClassModel classModel) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),

            Text(
              classModel.name,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            _buildDetailModalRow('Môn học', classModel.subject),
            _buildDetailModalRow('Giảng viên', classModel.instructor),
            _buildDetailModalRow('Phòng học', classModel.room),
            _buildDetailModalRow('Thời gian', classModel.timeRange),
            _buildDetailModalRow('Trạng thái', classModel.statusText),

            if (classModel.description != null && classModel.description!.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Text(
                'Mô tả:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              Text(classModel.description!),
            ],

            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange[700],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text('Đóng'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailModalRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}