import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../screens/widgets/class_card.dart';
import '../../mock/mock_data.dart';
import '../../mock/mock_models.dart';

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  String _selectedFilter = 'all';
  bool _isTeacher = false;
  List<ClassModel> _allClasses = [];
  List<ClassModel> _filteredClasses = [];

  @override
  void initState() {
    super.initState();
    _loadScheduleData();
  }

  void _loadScheduleData() {
    // Check if we're coming from teacher or student home
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      if (args != null) {
        setState(() {
          _isTeacher = args['isTeacher'] ?? false;
          _allClasses = MockData.getClassesForUser(_isTeacher ? 'teacher' : 'student');
          _applyFilter(_selectedFilter);
        });
      } else {
        // Default to student if no arguments
        setState(() {
          _allClasses = MockData.getClassesForUser('student');
          _applyFilter(_selectedFilter);
        });
      }
    });
  }

  void _applyFilter(String filter) {
    setState(() {
      _selectedFilter = filter;
      switch (filter) {
        case 'attended':
          _filteredClasses = _allClasses
              .where((classItem) => classItem.status == 'attended')
              .toList();
          break;
        case 'missed':
          _filteredClasses = _allClasses
              .where((classItem) => classItem.status == 'missed')
              .toList();
          break;
        case 'upcoming':
          _filteredClasses = _allClasses
              .where((classItem) => classItem.status == 'upcoming')
              .toList();
          break;
        default:
          _filteredClasses = List.from(_allClasses);
      }
    });
  }

  Map<String, List<ClassModel>> _groupClassesByDay(List<ClassModel> classes) {
    final Map<String, List<ClassModel>> grouped = {};

    for (var classItem in classes) {
      if (!grouped.containsKey(classItem.day)) {
        grouped[classItem.day] = [];
      }
      grouped[classItem.day]!.add(classItem);
    }

    // Sort days in week order
    final dayOrder = [
      'Thứ Hai', 'Thứ Ba', 'Thứ Tư', 'Thứ Năm', 'Thứ Sáu', 'Thứ Bảy', 'Chủ Nhật'
    ];

    final sortedGrouped = <String, List<ClassModel>>{};
    for (var day in dayOrder) {
      if (grouped.containsKey(day)) {
        sortedGrouped[day] = grouped[day]!;
      }
    }

    return sortedGrouped;
  }

  @override
  Widget build(BuildContext context) {
    final groupedClasses = _groupClassesByDay(_filteredClasses);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: Text(
          'Lịch học',
          style: AppTextStyles.heading3.copyWith(
            color: AppColors.onBackground,
          ),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            color: AppColors.divider,
          ),
        ),
      ),
      body: Column(
        children: [
          // Filter Chips
          Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bộ lọc',
                  style: AppTextStyles.heading4,
                ),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip('Tất cả', 'all'),
                      const SizedBox(width: 12),
                      _buildFilterChip('Đã điểm danh', 'attended'),
                      const SizedBox(width: 12),
                      _buildFilterChip('Vắng mặt', 'missed'),
                      const SizedBox(width: 12),
                      _buildFilterChip('Sắp tới', 'upcoming'),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Schedule List
          Expanded(
            child: groupedClasses.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.schedule_outlined,
                          size: 80,
                          color: AppColors.onSurface.withValues(alpha: 0.3),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Không có lịch học nào',
                          style: AppTextStyles.heading4.copyWith(
                            color: AppColors.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Thử thay đổi bộ lọc để xem các lớp học khác',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.onSurface.withValues(alpha: 0.5),
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: groupedClasses.keys.length,
                    itemBuilder: (context, index) {
                      final day = groupedClasses.keys.elementAt(index);
                      final dayClasses = groupedClasses[day]!;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Day Header
                          Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              day,
                              style: AppTextStyles.heading4.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),

                          // Classes for this day
                          ...dayClasses.map((classItem) => Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: ClassCard(
                              classItem: classItem,
                              onTap: () => _showClassDetails(classItem),
                              showAction: _isTeacher && classItem.status.toLowerCase() == 'ongoing',
                              actionText: 'Bắt đầu điểm danh',
                              onActionPressed: _isTeacher
                                  ? () => _startAttendance(classItem)
                                  : null,
                            ),
                          )),

                          if (index < groupedClasses.keys.length - 1)
                            const SizedBox(height: 24),
                        ],
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _selectedFilter == value;

    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          _applyFilter(value);
        }
      },
      backgroundColor: AppColors.surface,
      selectedColor: AppColors.primary.withValues(alpha: 0.2),
      checkmarkColor: AppColors.primary,
      labelStyle: AppTextStyles.bodyMedium.copyWith(
        color: isSelected ? AppColors.primary : AppColors.onSurface,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isSelected ? AppColors.primary : AppColors.divider,
          width: 1,
        ),
      ),
    );
  }

  void _showClassDetails(ClassModel classItem) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(classItem.subject),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow(Icons.calendar_today_outlined, 'Thứ', classItem.day),
            _buildDetailRow(Icons.access_time, 'Thời gian', classItem.time),
            _buildDetailRow(Icons.location_on_outlined, 'Phòng', classItem.room),
            if (!_isTeacher && classItem.teacher.isNotEmpty)
              _buildDetailRow(Icons.person_outline, 'Giảng viên', classItem.teacher),
            if (_isTeacher) ...[
              _buildDetailRow(Icons.person_outline, 'Giảng viên', classItem.teacher),
              _buildDetailRow(Icons.people_outline, 'Số sinh viên', '${classItem.students.length}'),
            ],
            const SizedBox(height: 12),
            _buildStatusChip(classItem.status),
          ],
        ),
        actions: [
          if (!_isTeacher && classItem.status == 'upcoming')
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _navigateToAttendance(classItem);
              },
              child: Text(
                'Điểm danh ngay',
                style: AppTextStyles.buttonMedium.copyWith(
                  color: AppColors.primary,
                ),
              ),
            ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(
            icon,
            size: 18,
            color: AppColors.onSurface.withValues(alpha: 0.6),
          ),
          const SizedBox(width: 12),
          Text(
            '$label:',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.onSurface.withValues(alpha: 0.7),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.onBackground,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color statusColor;
    String statusText;

    switch (status.toLowerCase()) {
      case 'attended':
        statusColor = AppColors.success;
        statusText = 'Đã điểm danh';
        break;
      case 'missed':
        statusColor = AppColors.error;
        statusText = 'Vắng mặt';
        break;
      case 'ongoing':
        statusColor = AppColors.info;
        statusText = 'Đang diễn ra';
        break;
      case 'upcoming':
      default:
        statusColor = AppColors.warning;
        statusText = 'Sắp diễn ra';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        statusText,
        style: AppTextStyles.bodySmall.copyWith(
          color: statusColor,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  void _navigateToAttendance(ClassModel classItem) {
    Navigator.pushNamed(
      context,
      '/camera',
      arguments: classItem,
    );
  }

  void _startAttendance(ClassModel classItem) {
    Navigator.pushNamed(
      context,
      '/camera',
      arguments: classItem,
    );
  }
}