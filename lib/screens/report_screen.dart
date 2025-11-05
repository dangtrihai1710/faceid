import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/class_service.dart';
import '../models/attendance_model.dart';
import '../models/user.dart';
import '../models/class_model.dart';

class ReportScreen extends StatefulWidget {
  final User currentUser;

  const ReportScreen({
    super.key,
    required this.currentUser,
  });

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  List<ClassModel> _allClasses = [];
  List<AttendanceModel> _allAttendanceRecords = [];
  Map<String, List<AttendanceModel>> _attendanceByClass = {};
  Map<String, ClassModel> _classMap = {};
  bool _isLoading = true;
  String _selectedClassId = '';
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadReportData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadReportData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Load data in parallel
      final results = await Future.wait([
        ClassService.getUpcomingClasses(),
        ClassService.getAllAttendanceRecords(), // We'll need to add this method
      ]);

      final classes = results[0] as List<ClassModel>;
      final attendanceRecords = results[1] as List<AttendanceModel>;

      // Group attendance by class
      final attendanceByClass = <String, List<AttendanceModel>>{};
      for (final record in attendanceRecords) {
        attendanceByClass.putIfAbsent(record.classId, () => []).add(record);
      }

      // Create class map
      final classMap = <String, ClassModel>{};
      for (final cls in classes) {
        classMap[cls.id] = cls;
      }

      setState(() {
        _allClasses = classes;
        _allAttendanceRecords = attendanceRecords;
        _attendanceByClass = attendanceByClass;
        _classMap = classMap;
        if (classes.isNotEmpty) {
          _selectedClassId = classes.first.id;
        }
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading report data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  List<AttendanceModel> _getFilteredRecords() {
    var records = _selectedClassId.isEmpty
        ? _allAttendanceRecords
        : _attendanceByClass[_selectedClassId] ?? [];

    if (_startDate != null) {
      records = records.where((r) => r.checkInTime.isAfter(_startDate!)).toList();
    }

    if (_endDate != null) {
      final endOfDay = DateTime(_endDate!.year, _endDate!.month, _endDate!.day, 23, 59, 59);
      records = records.where((r) => r.checkInTime.isBefore(endOfDay)).toList();
    }

    return records;
  }

  Map<String, dynamic> _getClassStatistics(String classId) {
    final records = _attendanceByClass[classId] ?? [];
    if (records.isEmpty) {
      return {
        'total': 0,
        'present': 0,
        'late': 0,
        'absent': 0,
        'excused': 0,
        'rate': 0.0,
        'uniqueStudents': <String>{},
      };
    }

    final present = records.where((r) => r.status == AttendanceStatus.present).length;
    final late = records.where((r) => r.status == AttendanceStatus.late).length;
    final absent = records.where((r) => r.status == AttendanceStatus.absent).length;
    final excused = records.where((r) => r.status == AttendanceStatus.excused).length;
    final total = records.length;

    final attended = present + late + excused;
    final rate = total > 0 ? (attended / total) * 100 : 0.0;

    // Get unique students
    final uniqueStudents = records.map((r) => r.userId).toSet();

    return {
      'total': total,
      'present': present,
      'late': late,
      'absent': absent,
      'excused': excused,
      'rate': rate,
      'uniqueStudents': uniqueStudents,
    };
  }

  Future<void> _exportReport() async {
    // TODO: Implement report export functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Tính năng xuất báo cáo sắp ra mắt!'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Báo cáo chuyên cần',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.purple[700],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: _exportReport,
            tooltip: 'Xuất báo cáo',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Filter Section
                Container(
                  padding: const EdgeInsets.all(16),
                  color: Colors.purple[50],
                  child: Column(
                    children: [
                      // Class Filter
                      Row(
                        children: [
                          Icon(Icons.class_, color: Colors.purple[700]),
                          const SizedBox(width: 8),
                          const Text(
                            'Lớp học:',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _selectedClassId.isEmpty ? null : _selectedClassId,
                              decoration: InputDecoration(
                                hintText: 'Tất cả lớp học',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                isDense: true,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                              ),
                              items: [
                                const DropdownMenuItem(
                                  value: '',
                                  child: Text('Tất cả lớp học'),
                                ),
                                ..._allClasses.map((cls) => DropdownMenuItem(
                                  value: cls.id,
                                  child: Text('${cls.name} - ${cls.subject}'),
                                )),
                              ],
                              onChanged: (value) {
                                setState(() {
                                  _selectedClassId = value ?? '';
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Date Range Filter
                      Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: () => _selectDate(true),
                              child: InputDecorator(
                                decoration: InputDecoration(
                                  labelText: 'Từ ngày',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  isDense: true,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                ),
                                child: Text(
                                  _startDate != null
                                      ? DateFormat('dd/MM/yyyy').format(_startDate!)
                                      : 'Chọn ngày',
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: InkWell(
                              onTap: () => _selectDate(false),
                              child: InputDecorator(
                                decoration: InputDecoration(
                                  labelText: 'Đến ngày',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  isDense: true,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                ),
                                child: Text(
                                  _endDate != null
                                      ? DateFormat('dd/MM/yyyy').format(_endDate!)
                                      : 'Chọn ngày',
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              setState(() {
                                _startDate = null;
                                _endDate = null;
                              });
                            },
                            tooltip: 'Xóa bộ lọc',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Tab Content
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildOverviewTab(),
                      _buildDetailedTab(),
                      _buildStudentTab(),
                    ],
                  ),
                ),
              ],
            ),
      bottomNavigationBar: TabBar(
        controller: _tabController,
        indicatorColor: Colors.purple[700],
        labelColor: Colors.purple[700],
        unselectedLabelColor: Colors.grey,
        tabs: const [
          Tab(text: 'Tổng quan'),
          Tab(text: 'Chi tiết'),
          Tab(text: 'Sinh viên'),
        ],
      ),
    );
  }

  Widget _buildOverviewTab() {
    final filteredRecords = _getFilteredRecords();

    if (_selectedClassId.isNotEmpty) {
      final stats = _getClassStatistics(_selectedClassId);
      return _buildClassOverview(_selectedClassId, stats);
    }

    // Show overview for all classes
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Tổng quan tất cả lớp học',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ..._allClasses.map((cls) {
            final stats = _getClassStatistics(cls.id);
            return _buildClassOverviewCard(cls, stats);
          }),
        ],
      ),
    );
  }

  Widget _buildClassOverview(String classId, Map<String, dynamic> stats) {
    final classInfo = _classMap[classId];
    if (classInfo == null) return const SizedBox();

    final classRecords = _getFilteredRecords();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Class Header
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
                      Icon(Icons.class_, color: Colors.purple[700], size: 24),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              classInfo.name,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              classInfo.subject,
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
                  const SizedBox(height: 20),

                  // Statistics
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          'Tỷ lệ chuyên cần',
                          '${stats['rate'].toStringAsFixed(1)}%',
                          stats['rate'] >= 80 ? Colors.green : Colors.orange,
                          Icons.analytics,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard(
                          'Sinh viên',
                          '${stats['uniqueStudents'].length}',
                          Colors.blue,
                          Icons.people,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
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
                      const SizedBox(width: 8),
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

          // Recent Attendance
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Hoạt động điểm danh gần đây',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (classRecords.isEmpty)
                    const Center(
                      child: Text('Không có dữ liệu điểm danh'),
                    )
                  else
                    ...classRecords.take(10).map((record) => _buildAttendanceRecord(record)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClassOverviewCard(ClassModel cls, Map<String, dynamic> stats) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.class_, color: Colors.purple[700]),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        cls.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        cls.subject,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '${stats['rate'].toStringAsFixed(1)}%',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: stats['rate'] >= 80 ? Colors.green : Colors.orange,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildMiniStatCard('Có mặt', '${stats['present']}', Colors.green),
                const SizedBox(width: 8),
                _buildMiniStatCard('Đi muộn', '${stats['late']}', Colors.orange),
                const SizedBox(width: 8),
                _buildMiniStatCard('Vắng', '${stats['absent']}', Colors.red),
                const SizedBox(width: 8),
                _buildMiniStatCard('SV', '${stats['uniqueStudents'].length}', Colors.blue),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailedTab() {
    final filteredRecords = _getFilteredRecords();

    return Column(
      children: [
        // Summary Header
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.grey[100],
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Tổng cộng: ${filteredRecords.length} bản ghi',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              ElevatedButton.icon(
                onPressed: _exportReport,
                icon: const Icon(Icons.download, size: 16),
                label: const Text('Xuất Excel'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),

        // Records List
        Expanded(
          child: filteredRecords.isEmpty
              ? const Center(
                  child: Text('Không có dữ liệu nào khớp với bộ lọc'),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredRecords.length,
                  itemBuilder: (context, index) {
                    return _buildAttendanceRecord(filteredRecords[index]);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildStudentTab() {
    // Group records by student
    final studentRecords = <String, List<AttendanceModel>>{};
    for (final record in _getFilteredRecords()) {
      studentRecords.putIfAbsent(record.userId, () => []).add(record);
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: studentRecords.length,
      itemBuilder: (context, index) {
        final studentId = studentRecords.keys.elementAt(index);
        final records = studentRecords[studentId]!;

        return _buildStudentCard(studentId, records);
      },
    );
  }

  Widget _buildAttendanceRecord(AttendanceModel record) {
    final classInfo = _classMap[record.classId];

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: record.statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(
                _getStatusIcon(record.status),
                color: record.statusColor,
                size: 16,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    classInfo?.name ?? 'Lớp không xác định',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    'Sinh viên: ${record.userId}',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    DateFormat('dd/MM/yyyy HH:mm').format(record.checkInTime),
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: record.statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                record.statusText,
                style: TextStyle(
                  color: record.statusColor,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStudentCard(String studentId, List<AttendanceModel> records) {
    final present = records.where((r) => r.status == AttendanceStatus.present).length;
    final late = records.where((r) => r.status == AttendanceStatus.late).length;
    final absent = records.where((r) => r.status == AttendanceStatus.absent).length;
    final excused = records.where((r) => r.status == AttendanceStatus.excused).length;
    final total = records.length;
    final rate = total > 0 ? ((present + late + excused) / total) * 100 : 0.0;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.purple[700],
                  child: Text(
                    studentId.substring(0, 2).toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Sinh viên: $studentId',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Điểm danh: $total buổi',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '${rate.toStringAsFixed(1)}%',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: rate >= 80 ? Colors.green : Colors.orange,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildMiniStatCard('Có mặt', '$present', Colors.green),
                const SizedBox(width: 8),
                _buildMiniStatCard('Đi muộn', '$late', Colors.orange),
                const SizedBox(width: 8),
                _buildMiniStatCard('Vắng', '$absent', Colors.red),
                const SizedBox(width: 8),
                _buildMiniStatCard('Phép', '$excused', Colors.blue),
              ],
            ),
          ],
        ),
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
              fontSize: 20,
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

  Widget _buildMiniStatCard(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: color.withOpacity(0.8),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectDate(bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );

    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
    }
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