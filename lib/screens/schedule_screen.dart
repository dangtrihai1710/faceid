import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/class_service.dart';
import '../models/class_model.dart';
import '../models/user.dart';
import '../models/attendance_model.dart';
import 'class_detail_screen.dart';

class ScheduleScreen extends StatefulWidget {
  final User currentUser;

  const ScheduleScreen({
    super.key,
    required this.currentUser,
  });

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  List<ClassModel> _allClasses = [];
  bool _isLoading = true;
  DateTime _selectedWeek = DateTime.now();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadSchedule();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadSchedule() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final classes = await ClassService.getUpcomingClasses();
      setState(() {
        _allClasses = classes;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading schedule: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  List<ClassModel> _getClassesForWeek(DateTime weekStart) {
    final weekEnd = weekStart.add(const Duration(days: 6));
    return _allClasses.where((cls) {
      final classDate = cls.startTime;
      return classDate.isAfter(weekStart.subtract(const Duration(days: 1))) &&
             classDate.isBefore(weekEnd.add(const Duration(days: 1)));
    }).toList();
  }

  List<ClassModel> _getClassesForDay(DateTime day) {
    return _allClasses.where((cls) {
      return cls.startTime.year == day.year &&
             cls.startTime.month == day.month &&
             cls.startTime.day == day.day;
    }).toList();
  }

  void _changeWeek(int direction) {
    setState(() {
      _selectedWeek = _selectedWeek.add(Duration(days: 7 * direction));
    });
  }

  String _formatWeekRange(DateTime weekStart) {
    final weekEnd = weekStart.add(const Duration(days: 6));
    final startFormat = DateFormat('dd/MM');
    final endFormat = DateFormat('dd/MM');
    return '${startFormat.format(weekStart)} - ${endFormat.format(weekEnd)}';
  }

  DateTime _getWeekStart(DateTime date) {
    final day = date.weekday;
    return date.subtract(Duration(days: day - 1));
  }

  @override
  Widget build(BuildContext context) {
    final weekStart = _getWeekStart(_selectedWeek);
    final weekClasses = _getClassesForWeek(weekStart);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Lịch học',
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
            Tab(text: 'Theo tuần'),
            Tab(text: 'Theo ngày'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildWeekView(weekStart, weekClasses),
          _buildDayView(),
        ],
      ),
    );
  }

  Widget _buildWeekView(DateTime weekStart, List<ClassModel> weekClasses) {
    return Column(
      children: [
        // Week Navigation
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.blue[50],
          child: Row(
            children: [
              IconButton(
                onPressed: () => _changeWeek(-1),
                icon: const Icon(Icons.chevron_left),
                color: Colors.blue[700],
              ),
              Expanded(
                child: Center(
                  child: Text(
                    'Tuần ${_formatWeekRange(weekStart)}',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[700],
                    ),
                  ),
                ),
              ),
              IconButton(
                onPressed: () => _changeWeek(1),
                icon: const Icon(Icons.chevron_right),
                color: Colors.blue[700],
              ),
            ],
          ),
        ),

        // Week Classes
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : weekClasses.isEmpty
                  ? _buildEmptyState('Không có lớp học trong tuần này')
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: 7,
                      itemBuilder: (context, index) {
                        final day = weekStart.add(Duration(days: index));
                        final dayClasses = _getClassesForDay(day);
                        return _buildDayCard(day, dayClasses);
                      },
                    ),
        ),
      ],
    );
  }

  Widget _buildDayView() {
    final today = DateTime.now();
    final todayClasses = _getClassesForDay(today);

    return Column(
      children: [
        // Date Header
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.blue[50],
          child: Row(
            children: [
              Icon(Icons.calendar_today, color: Colors.blue[700]),
              const SizedBox(width: 8),
              Text(
                'Hôm nay - ${DateFormat('EEEE, dd/MM/yyyy').format(today)}',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[700],
                ),
              ),
            ],
          ),
        ),

        // Today's Classes
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : todayClasses.isEmpty
                  ? _buildEmptyState('Không có lớp học hôm nay')
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: todayClasses.length,
                      itemBuilder: (context, index) {
                        return _buildClassCard(todayClasses[index]);
                      },
                    ),
        ),
      ],
    );
  }

  Widget _buildDayCard(DateTime day, List<ClassModel> dayClasses) {
    final isToday = _isSameDay(day, DateTime.now());
    final dayName = DateFormat('EEEE').format(day);
    final dayDate = DateFormat('dd/MM').format(day);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isToday ? Colors.blue[50] : Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: isToday ? Border.all(color: Colors.blue[300]!) : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Day Header
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isToday ? Colors.blue[100] : Colors.grey[200],
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 20,
                  color: isToday ? Colors.blue[700] : Colors.grey[600],
                ),
                const SizedBox(width: 8),
                Text(
                  '$dayName - $dayDate',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isToday ? Colors.blue[700] : Colors.grey[700],
                  ),
                ),
                if (isToday) ...[
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.blue[700],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Hôm nay',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Classes for the day
          if (dayClasses.isEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              child: Center(
                child: Text(
                  'Không có lớp học',
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            )
          else
            Column(
              children: dayClasses.map((cls) => _buildCompactClassCard(cls)).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildCompactClassCard(ClassModel cls) {
    return InkWell(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => ClassDetailScreen(
              classModel: cls,
              currentUser: widget.currentUser,
              cameras: const [],
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: cls.isAttendanceOpen ? Colors.green : Colors.grey[300]!,
            width: cls.isAttendanceOpen ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _getClassStatusColor(cls).withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(
                cls.isAttendanceOpen ? Icons.how_to_reg : Icons.school,
                color: cls.isAttendanceOpen ? Colors.green : _getClassStatusColor(cls),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    cls.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    cls.subject,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                  Row(
                    children: [
                      Icon(Icons.access_time, size: 12, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        cls.timeRange,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Icon(Icons.location_on, size: 12, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        cls.room,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: cls.isAttendanceOpen
                        ? Colors.green.withOpacity(0.1)
                        : _getClassStatusColor(cls).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    cls.statusText,
                    style: TextStyle(
                      color: cls.isAttendanceOpen ? Colors.green : _getClassStatusColor(cls),
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 12,
                  color: Colors.grey[400],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClassCard(ClassModel cls) {
    return InkWell(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => ClassDetailScreen(
              classModel: cls,
              currentUser: widget.currentUser,
              cameras: const [],
            ),
          ),
        );
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: cls.isAttendanceOpen ? Colors.green : Colors.grey[300]!,
            width: cls.isAttendanceOpen ? 2 : 1,
          ),
          boxShadow: cls.isAttendanceOpen
              ? [
                  BoxShadow(
                    color: Colors.green.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _getClassStatusColor(cls).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    cls.isAttendanceOpen ? Icons.how_to_reg : Icons.school,
                    color: cls.isAttendanceOpen ? Colors.green : _getClassStatusColor(cls),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        cls.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        cls.subject,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: cls.isAttendanceOpen
                        ? Colors.green.withOpacity(0.1)
                        : _getClassStatusColor(cls).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    cls.statusText,
                    style: TextStyle(
                      color: cls.isAttendanceOpen ? Colors.green : _getClassStatusColor(cls),
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
                Icon(Icons.access_time, color: Colors.grey[600], size: 16),
                const SizedBox(width: 4),
                Text(
                  cls.timeRange,
                  style: TextStyle(color: Colors.grey[600]),
                ),
                const SizedBox(width: 16),
                Icon(Icons.location_on, color: Colors.grey[600], size: 16),
                const SizedBox(width: 4),
                Text(
                  cls.room,
                  style: TextStyle(color: Colors.grey[600]),
                ),
                const Spacer(),
                if (cls.isAttendanceOpen)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.notifications_active, size: 14, color: Colors.green),
                        const SizedBox(width: 4),
                        Text(
                          'Đang mở điểm danh',
                          style: TextStyle(
                            color: Colors.green,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            if (cls.isAttendanceOpen) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info, size: 16, color: Colors.green[700]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Giảng viên đã mở điểm danh cho lớp học này',
                        style: TextStyle(
                          color: Colors.green[700],
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

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.calendar_month,
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
            'Các lịch học sẽ được cập nhật khi có lịch mới',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
           date1.month == date2.month &&
           date1.day == date2.day;
  }

  Color _getClassStatusColor(ClassModel cls) {
    if (cls.isAttendanceOpen) return Colors.green;
    if (cls.isOngoing) return Colors.blue;
    if (cls.isUpcoming && cls.isToday) return Colors.orange;
    if (cls.isUpcoming) return Colors.purple;
    return Colors.grey;
  }
}