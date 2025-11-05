import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/class_service.dart';
import '../models/attendance_model.dart';
import '../models/user.dart';
import '../models/class_model.dart';

class AttendanceHistoryScreen extends StatefulWidget {
  final User currentUser;

  const AttendanceHistoryScreen({
    super.key,
    required this.currentUser,
  });

  @override
  State<AttendanceHistoryScreen> createState() => _AttendanceHistoryScreenState();
}

class _AttendanceHistoryScreenState extends State<AttendanceHistoryScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  List<AttendanceModel> _attendanceRecords = [];
  List<ClassModel> _allClasses = [];
  Map<String, ClassModel> _classMap = {};
  bool _isLoading = true;
  String _selectedFilter = 'all';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadAttendanceHistory();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAttendanceHistory() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Load attendance records and classes in parallel
      final results = await Future.wait([
        ClassService.getAttendanceRecords(widget.currentUser.id),
        ClassService.getUpcomingClasses(),
      ]);

      final attendanceRecords = results[0] as List<AttendanceModel>;
      final allClasses = results[1] as List<ClassModel>;

      // Create class map for easy lookup
      final classMap = <String, ClassModel>{};
      for (final cls in allClasses) {
        classMap[cls.id] = cls;
      }

      setState(() {
        _attendanceRecords = attendanceRecords;
        _allClasses = allClasses;
        _classMap = classMap;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading attendance history: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  List<AttendanceModel> _getFilteredRecords() {
    switch (_selectedFilter) {
      case 'present':
        return _attendanceRecords.where((r) => r.status == AttendanceStatus.present).toList();
      case 'late':
        return _attendanceRecords.where((r) => r.status == AttendanceStatus.late).toList();
      case 'absent':
        return _attendanceRecords.where((r) => r.status == AttendanceStatus.absent).toList();
      case 'excused':
        return _attendanceRecords.where((r) => r.status == AttendanceStatus.excused).toList();
      default:
        return _attendanceRecords;
    }
  }

  Map<String, dynamic> _getStatistics() {
    if (_attendanceRecords.isEmpty) {
      return {
        'total': 0,
        'present': 0,
        'late': 0,
        'absent': 0,
        'excused': 0,
        'rate': 0.0,
      };
    }

    final present = _attendanceRecords.where((r) => r.status == AttendanceStatus.present).length;
    final late = _attendanceRecords.where((r) => r.status == AttendanceStatus.late).length;
    final absent = _attendanceRecords.where((r) => r.status == AttendanceStatus.absent).length;
    final excused = _attendanceRecords.where((r) => r.status == AttendanceStatus.excused).length;
    final total = _attendanceRecords.length;

    final attended = present + late + excused;
    final rate = total > 0 ? (attended / total) * 100 : 0.0;

    return {
      'total': total,
      'present': present,
      'late': late,
      'absent': absent,
      'excused': excused,
      'rate': rate,
    };
  }

  List<AttendanceModel> _getRecordsByMonth() {
    final now = DateTime.now();
    return _attendanceRecords.where((record) {
      return record.checkInTime.year == now.year &&
             record.checkInTime.month == now.month;
    }).toList();
  }

  List<AttendanceModel> _getRecordsByWeek() {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    return _attendanceRecords.where((record) {
      return record.checkInTime.isAfter(weekStart.subtract(const Duration(days: 1)));
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final stats = _getStatistics();
    final filteredRecords = _getFilteredRecords();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Lịch sử điểm danh',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Thống kê'),
            Tab(text: 'Tất cả'),
            Tab(text: 'Tháng này'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildStatisticsView(stats),
          _buildAllRecordsView(filteredRecords),
          _buildMonthlyView(),
        ],
      ),
    );
  }

  Widget _buildStatisticsView(Map<String, dynamic> stats) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Overall Statistics Card
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.analytics, color: Colors.blue[700], size: 24),
                      const SizedBox(width: 8),
                      const Text(
                        'Thống kê tổng quan',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Attendance Rate
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue[200]!),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Tỷ lệ chuyên cần',
                              style: TextStyle(
                                color: Colors.blue[700],
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${stats['total'].toStringAsFixed(0)} buổi học',
                              style: TextStyle(
                                color: Colors.blue[600],
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          '${stats['rate'].toStringAsFixed(1)}%',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: stats['rate'] >= 80 ? Colors.green : Colors.orange,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Status Grid
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          'Có mặt',
                          '${stats['present']}',
                          Colors.green,
                          Icons.check_circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildStatCard(
                          'Đi muộn',
                          '${stats['late']}',
                          Colors.orange,
                          Icons.access_time,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          'Vắng mặt',
                          '${stats['absent']}',
                          Colors.red,
                          Icons.cancel,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildStatCard(
                          'Có phép',
                          '${stats['excused']}',
                          Colors.blue,
                          Icons.event_available,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Recent Activity Card
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.history, color: Colors.blue[700]),
                      const SizedBox(width: 8),
                      const Text(
                        'Hoạt động gần đây',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (_attendanceRecords.isEmpty)
                    Center(
                      child: Column(
                        children: [
                          Icon(Icons.history_edu, size: 48, color: Colors.grey[400]),
                          const SizedBox(height: 8),
                          Text(
                            'Chưa có lịch sử điểm danh',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    )
                  else
                    ..._attendanceRecords.take(5).map((record) => _buildCompactAttendanceRecord(record)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color.withOpacity(0.8),
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildAllRecordsView(List<AttendanceModel> records) {
    return Column(
      children: [
        // Filter Chips
        Container(
          padding: const EdgeInsets.all(16),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip('Tất cả', 'all', Icons.list),
                const SizedBox(width: 8),
                _buildFilterChip('Có mặt', 'present', Icons.check_circle),
                const SizedBox(width: 8),
                _buildFilterChip('Đi muộn', 'late', Icons.access_time),
                const SizedBox(width: 8),
                _buildFilterChip('Vắng mặt', 'absent', Icons.cancel),
                const SizedBox(width: 8),
                _buildFilterChip('Có phép', 'excused', Icons.event_available),
              ],
            ),
          ),
        ),

        // Records List
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : records.isEmpty
                  ? _buildEmptyState('Không có bản ghi điểm danh nào')
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: records.length,
                      itemBuilder: (context, index) {
                        return _buildAttendanceRecord(records[index]);
                      },
                    ),
        ),
      ],
    );
  }

  Widget _buildMonthlyView() {
    final monthlyRecords = _getRecordsByMonth();
    final weeklyRecords = _getRecordsByWeek();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Week Summary
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.date_range, color: Colors.blue[700]),
                      const SizedBox(width: 8),
                      const Text(
                        'Tuần này',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Đã điểm danh: ${weeklyRecords.length} buổi',
                    style: const TextStyle(fontSize: 16),
                  ),
                  if (weeklyRecords.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    ...weeklyRecords.take(3).map((record) => _buildCompactAttendanceRecord(record)),
                  ],
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Month Summary
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.calendar_month, color: Colors.blue[700]),
                      const SizedBox(width: 8),
                      Text(
                        'Tháng ${DateTime.now().month}/${DateTime.now().year}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Đã điểm danh: ${monthlyRecords.length} buổi',
                    style: const TextStyle(fontSize: 16),
                  ),
                  if (monthlyRecords.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    ...monthlyRecords.map((record) => _buildCompactAttendanceRecord(record)),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value, IconData icon) {
    final isSelected = _selectedFilter == value;
    return FilterChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16),
          const SizedBox(width: 4),
          Text(label),
        ],
      ),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedFilter = value;
        });
      },
      backgroundColor: Colors.grey[200],
      selectedColor: Colors.blue[100],
      checkmarkColor: Colors.blue[700],
    );
  }

  Widget _buildAttendanceRecord(AttendanceModel record) {
    final classInfo = _classMap[record.classId];

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.only(bottom: 12),
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
                    color: record.statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _getStatusIcon(record.status),
                    color: record.statusColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        classInfo?.name ?? 'Lớp học không xác định',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (classInfo != null) ...[
                        Text(
                          classInfo.subject,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: record.statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    record.statusText,
                    style: TextStyle(
                      color: record.statusColor,
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
                  'Giờ vào: ${record.formattedCheckInTime}',
                  style: TextStyle(color: Colors.grey[600]),
                ),
                if (record.formattedCheckOutTime != null) ...[
                  const SizedBox(width: 16),
                  Icon(Icons.logout, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    'Giờ ra: ${record.formattedCheckOutTime}',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ],
            ),
            if (record.latitude != null && record.longitude != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    'Vị trí: ${record.latitude!.toStringAsFixed(6)}, ${record.longitude!.toStringAsFixed(6)}',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                ],
              ),
            ],
            if (record.notes?.isNotEmpty == true) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.note, size: 16, color: Colors.blue[700]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        record.notes!,
                        style: TextStyle(
                          color: Colors.blue[700],
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCompactAttendanceRecord(AttendanceModel record) {
    final classInfo = _classMap[record.classId];

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            _getStatusIcon(record.status),
            color: record.statusColor,
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  classInfo?.name ?? 'Lớp học không xác định',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  DateFormat('dd/MM HH:mm').format(record.checkInTime),
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          Text(
            record.statusText,
            style: TextStyle(
              color: record.statusColor,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.history_edu,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Bắt đầu điểm danh để xem lịch sử',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  IconData _getStatusIcon(AttendanceStatus status) {
    switch (status) {
      case AttendanceStatus.present:
        return Icons.check_circle;
      case AttendanceStatus.late:
        return Icons.access_time;
      case AttendanceStatus.absent:
        return Icons.cancel;
      case AttendanceStatus.excused:
        return Icons.event_available;
      case AttendanceStatus.unknown:
        return Icons.help;
    }
  }
}