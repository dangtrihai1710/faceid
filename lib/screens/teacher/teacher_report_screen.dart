import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import '../../models/user.dart';
import '../../models/class_model.dart';
import '../../models/attendance_model.dart';
import '../../services/api_service.dart';

class AttendanceTrendData {
  final String date;
  final int present;
  final int absent;
  final int late;

  AttendanceTrendData({
    required this.date,
    required this.present,
    required this.absent,
    required this.late,
  });
}

class PieChartData {
  final String status;
  final int count;
  final Color color;

  PieChartData({
    required this.status,
    required this.count,
    required this.color,
  });
}

class ClassStatsData {
  final String className;
  final int totalStudents;
  final int attendanceRate;

  ClassStatsData({
    required this.className,
    required this.totalStudents,
    required this.attendanceRate,
  });
}

class TeacherReportScreen extends StatefulWidget {
  final User currentUser;

  const TeacherReportScreen({
    super.key,
    required this.currentUser,
  });

  @override
  State<TeacherReportScreen> createState() => _TeacherReportScreenState();
}

class _TeacherReportScreenState extends State<TeacherReportScreen>
    with TickerProviderStateMixin {
  List<ClassModel> _allClasses = [];
  List<AttendanceModel> _attendanceRecords = [];
  bool _isLoading = true;
  String _selectedPeriod = 'week';
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final classesResponse = await ApiService.makeAuthenticatedRequest(
        'GET',
        '/api/v1/classes/?per_page=100',
      );

      if (classesResponse['success'] == true && classesResponse['data'] != null) {
        final classesData = classesResponse['data'] as List;
        final classes = classesData.map((json) => ClassModel.fromJson(json)).toList();

        final attendanceResponse = await ApiService.makeAuthenticatedRequest(
          'GET',
          '/api/v1/attendance/?per_page=1000',
        );

        List<AttendanceModel> attendanceRecords = [];
        if (attendanceResponse['success'] == true && attendanceResponse['data'] != null) {
          final attendanceData = attendanceResponse['data'] as List;
          attendanceRecords = attendanceData.map((json) => AttendanceModel.fromJson(json)).toList();
        }

        if (mounted) {
          setState(() {
            _allClasses = classes;
            _attendanceRecords = attendanceRecords;
            _isLoading = false;
          });
        }
      } else {
        throw Exception(classesResponse['message'] ?? 'Failed to load data');
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

  Map<String, dynamic> _calculateStats() {
    final totalSessions = _attendanceRecords.length;
    final presentCount = _attendanceRecords.where((r) => r.status == 'present').length;
    final absentCount = _attendanceRecords.where((r) => r.status == 'absent').length;
    final lateCount = _attendanceRecords.where((r) => r.status == 'late').length;

    return {
      'totalSessions': totalSessions,
      'presentCount': presentCount,
      'absentCount': absentCount,
      'lateCount': lateCount,
      'attendanceRate': totalSessions > 0 ? ((presentCount / totalSessions) * 100).round() : 0,
    };
  }

  List<AttendanceTrendData> _getTrendData() {
    final now = DateTime.now();
    final List<AttendanceTrendData> trendData = [];

    for (int i = 6; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final dateStr = DateFormat('MM/dd').format(date);

      final dayRecords = _attendanceRecords.where((record) {
        final recordDate = record.checkInTime;
        return recordDate.year == date.year &&
            recordDate.month == date.month &&
            recordDate.day == date.day;
      }).toList();

      final present = dayRecords.where((r) => r.status == 'present').length;
      final absent = dayRecords.where((r) => r.status == 'absent').length;
      final late = dayRecords.where((r) => r.status == 'late').length;

      trendData.add(AttendanceTrendData(
        date: dateStr,
        present: present,
        absent: absent,
        late: late,
      ));
    }

    return trendData;
  }

  List<PieChartData> _getPieChartData() {
    final stats = _calculateStats();

    return [
      PieChartData(
        status: 'Có mặt',
        count: stats['presentCount'],
        color: Colors.green,
      ),
      PieChartData(
        status: 'Vắng mặt',
        count: stats['absentCount'],
        color: Colors.red,
      ),
      PieChartData(
        status: 'Đi muộn',
        count: stats['lateCount'],
        color: Colors.orange,
      ),
    ];
  }

  List<ClassStatsData> _getClassStatsData() {
    return _allClasses.take(5).map((classModel) {
      final classRecords = _attendanceRecords.where((record) =>
          record.classId == classModel.id || record.classId == classModel.name).toList();
      final presentCount = classRecords.where((r) => r.status == 'present').length;
      final attendanceRate = classRecords.isNotEmpty
          ? ((presentCount / classRecords.length) * 100).round()
          : 0;

      return ClassStatsData(
        className: classModel.displayName,
        totalStudents: classRecords.length,
        attendanceRate: attendanceRate,
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Báo cáo điểm danh'),
        backgroundColor: Colors.purple[700],
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Tổng quan'),
            Tab(text: 'Biểu đồ'),
            Tab(text: 'Chi tiết'),
          ],
        ),
      ),
      body: _isLoading
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
              onRefresh: _loadData,
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildOverviewTab(),
                  _buildChartsTab(),
                  _buildDetailedReportTab(),
                ],
              ),
            ),
    );
  }

  Widget _buildOverviewTab() {
    final stats = _calculateStats();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildOverviewStats(stats),
          const SizedBox(height: 24),
          _buildRecentClasses(),
        ],
      ),
    );
  }

  Widget _buildOverviewStats(Map<String, dynamic> stats) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.purple[50]!,
            Colors.purple[100]!,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.purple.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Thống kê điểm danh',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.purple[700],
            ),
          ),
          const SizedBox(height: 20),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 1.5,
            children: [
              _buildStatCard(
                'Tổng buổi học',
                '${stats['totalSessions']}',
                Icons.event,
                Colors.blue,
              ),
              _buildStatCard(
                'Có mặt',
                '${stats['presentCount']}',
                Icons.check_circle,
                Colors.green,
              ),
              _buildStatCard(
                'Vắng mặt',
                '${stats['absentCount']}',
                Icons.cancel,
                Colors.red,
              ),
              _buildStatCard(
                'Đi muộn',
                '${stats['lateCount']}',
                Icons.access_time,
                Colors.orange,
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Text(
                  'Tỷ lệ điểm danh',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${stats['attendanceRate']}%',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: stats['attendanceRate'] >= 80 ? Colors.green : Colors.orange,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 32),
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
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildRecentClasses() {
    final recentRecords = _attendanceRecords.take(10).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Hoạt động gần đây',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
          ),
        ),
        const SizedBox(height: 16),
        if (recentRecords.isEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.history, color: Colors.grey[600]),
                const SizedBox(width: 12),
                Text(
                  'Chưa có hoạt động điểm danh nào',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          )
        else
          ...recentRecords.map((record) => _buildActivityCard(record)),
      ],
    );
  }

  Widget _buildActivityCard(AttendanceModel record) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: record.statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.check_circle,
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
                  'Sinh viên điểm danh',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                Text(
                  'Giờ vào: ${record.formattedCheckInTime}',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: record.statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
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
    );
  }

  Widget _buildChartsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTrendChart(),
          const SizedBox(height: 24),
          _buildPieChart(),
          const SizedBox(height: 24),
          _buildClassStatsChart(),
        ],
      ),
    );
  }

  Widget _buildTrendChart() {
    final trendData = _getTrendData();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Xu hướng điểm danh 7 ngày qua',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 300,
            child: SfCartesianChart(
              primaryXAxis: CategoryAxis(
                title: AxisTitle(text: 'Ngày'),
              ),
              primaryYAxis: NumericAxis(
                title: AxisTitle(text: 'Số lượng'),
              ),
              legend: Legend(isVisible: true),
              tooltipBehavior: TooltipBehavior(enable: true),
              series: [
                LineSeries<AttendanceTrendData, String>(
                  name: 'Có mặt',
                  dataSource: trendData,
                  xValueMapper: (AttendanceTrendData data, _) => data.date,
                  yValueMapper: (AttendanceTrendData data, _) => data.present,
                  color: Colors.green,
                ),
                LineSeries<AttendanceTrendData, String>(
                  name: 'Vắng mặt',
                  dataSource: trendData,
                  xValueMapper: (AttendanceTrendData data, _) => data.date,
                  yValueMapper: (AttendanceTrendData data, _) => data.absent,
                  color: Colors.red,
                ),
                LineSeries<AttendanceTrendData, String>(
                  name: 'Đi muộn',
                  dataSource: trendData,
                  xValueMapper: (AttendanceTrendData data, _) => data.date,
                  yValueMapper: (AttendanceTrendData data, _) => data.late,
                  color: Colors.orange,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPieChart() {
    final pieChartData = _getPieChartData();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Phân bổ trạng thái điểm danh',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 300,
            child: SfCircularChart(
              legend: Legend(isVisible: true, position: LegendPosition.bottom),
              tooltipBehavior: TooltipBehavior(enable: true),
              series: [
                PieSeries<PieChartData, String>(
                  dataSource: pieChartData,
                  xValueMapper: (PieChartData data, _) => data.status,
                  yValueMapper: (PieChartData data, _) => data.count,
                  pointColorMapper: (PieChartData data, _) => data.color,
                  dataLabelSettings: const DataLabelSettings(isVisible: true),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClassStatsChart() {
    final classStatsData = _getClassStatsData();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tỷ lệ điểm danh theo lớp',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 300,
            child: SfCartesianChart(
              primaryXAxis: CategoryAxis(
                title: AxisTitle(text: 'Lớp học'),
              ),
              primaryYAxis: NumericAxis(
                title: AxisTitle(text: 'Tỷ lệ (%)'),
                minimum: 0,
                maximum: 100,
              ),
              tooltipBehavior: TooltipBehavior(enable: true),
              series: [
                ColumnSeries<ClassStatsData, String>(
                  dataSource: classStatsData,
                  xValueMapper: (ClassStatsData data, _) => data.className,
                  yValueMapper: (ClassStatsData data, _) => data.attendanceRate,
                  pointColorMapper: (ClassStatsData data, _) =>
                      data.attendanceRate >= 80 ? Colors.green : Colors.orange,
                  dataLabelSettings: const DataLabelSettings(isVisible: true),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailedReportTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDetailedStats(),
          const SizedBox(height: 24),
          _buildClasswiseReport(),
        ],
      ),
    );
  }

  Widget _buildDetailedStats() {
    final stats = _calculateStats();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Thống kê chi tiết',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 20),
          Table(
            columnWidths: const {
              0: FlexColumnWidth(2),
              1: FlexColumnWidth(1),
            },
            border: TableBorder.all(
              color: Colors.grey[300]!,
              width: 1,
            ),
            children: [
              TableRow(
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                ),
                children: [
                  _buildTableCell('Chỉ số', isHeader: true),
                  _buildTableCell('Giá trị', isHeader: true),
                ],
              ),
              TableRow(
                children: [
                  _buildTableCell('Tổng buổi học'),
                  _buildTableCell('${stats['totalSessions']}'),
                ],
              ),
              TableRow(
                children: [
                  _buildTableCell('Số lần có mặt'),
                  _buildTableCell('${stats['presentCount']}'),
                ],
              ),
              TableRow(
                children: [
                  _buildTableCell('Số lần vắng mặt'),
                  _buildTableCell('${stats['absentCount']}'),
                ],
              ),
              TableRow(
                children: [
                  _buildTableCell('Số lần đi muộn'),
                  _buildTableCell('${stats['lateCount']}'),
                ],
              ),
              TableRow(
                children: [
                  _buildTableCell('Tỷ lệ điểm danh'),
                  _buildTableCell('${stats['attendanceRate']}%'),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTableCell(String text, {bool isHeader = false}) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Text(
        text,
        style: TextStyle(
          fontWeight: isHeader ? FontWeight.bold : FontWeight.normal,
          fontSize: isHeader ? 14 : 12,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildClasswiseReport() {
    final classStatsData = _getClassStatsData();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Báo cáo theo lớp học',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 20),
          Table(
            columnWidths: const {
              0: FlexColumnWidth(3),
              1: FlexColumnWidth(1),
              2: FlexColumnWidth(1),
            },
            border: TableBorder.all(
              color: Colors.grey[300]!,
              width: 1,
            ),
            children: [
              TableRow(
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                ),
                children: [
                  _buildTableCell('Lớp học', isHeader: true),
                  _buildTableCell('SV điểm danh', isHeader: true),
                  _buildTableCell('Tỷ lệ (%)', isHeader: true),
                ],
              ),
              ...classStatsData.map((data) => TableRow(
                children: [
                  _buildTableCell(data.className),
                  _buildTableCell('${data.totalStudents}'),
                  _buildTableCell('${data.attendanceRate}%'),
                ],
              )),
            ],
          ),
        ],
      ),
    );
  }
}