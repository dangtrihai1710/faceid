import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/user.dart';
import '../../models/class_model.dart';
import '../../services/api_service.dart';

class TeacherScheduleScreen extends StatefulWidget {
  final User currentUser;

  const TeacherScheduleScreen({
    super.key,
    required this.currentUser,
  });

  @override
  State<TeacherScheduleScreen> createState() => _TeacherScheduleScreenState();
}

class _TeacherScheduleScreenState extends State<TeacherScheduleScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  List<ClassModel> _allClasses = [];
  List<ClassModel> _todayClasses = [];
  List<ClassModel> _weekClasses = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
    _loadData();
    _animationController.forward();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final response = await ApiService.makeAuthenticatedRequest(
        'GET',
        '/api/v1/classes/?per_page=100',
      );

      if (response['success'] == true && response['data'] != null) {
        final classesData = response['data'] as List;
        final classes = classesData.map((json) => ClassModel.fromJson(json)).toList();

        if (mounted) {
          setState(() {
            _allClasses = classes;
            _todayClasses = _allClasses.where((cls) => cls.isToday).toList();
            _weekClasses = _getWeekClasses();
            _isLoading = false;
          });
        }
      } else {
        throw Exception(response['message'] ?? 'Failed to load schedule');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi tải thời khóa biểu: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  List<ClassModel> _getWeekClasses() {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final weekEnd = weekStart.add(const Duration(days: 6));

    return _allClasses.where((cls) {
      final classDate = DateTime(
        cls.startTime.year,
        cls.startTime.month,
        cls.startTime.day,
      );
      return classDate.isAfter(weekStart.subtract(const Duration(days: 1))) &&
          classDate.isBefore(weekEnd.add(const Duration(days: 1)));
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Thời khóa biểu'),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Hôm nay', icon: Icon(Icons.today)),
            Tab(text: 'Tuần này', icon: Icon(Icons.calendar_view_week)),
            Tab(text: 'Tất cả', icon: Icon(Icons.calendar_month)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: 'Làm mới',
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
                  Text('Đang tải thời khóa biểu...'),
                ],
              ),
            )
          : FadeTransition(
              opacity: _fadeAnimation,
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildTodaySchedule(),
                  _buildWeekSchedule(),
                  _buildAllSchedule(),
                ],
              ),
            ),
    );
  }

  Widget _buildTodaySchedule() {
    final now = DateTime.now();
    final greeting = _getGreeting(now);

    return RefreshIndicator(
      onRefresh: _loadData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDateHeader(now, greeting),
            const SizedBox(height: 24),
            if (_todayClasses.isEmpty)
              _buildEmptySchedule('Hôm nay không có lịch dạy')
            else
              ..._todayClasses.map((cls) => _buildScheduleCard(cls, true)),
            const SizedBox(height: 100), // Extra padding for scrolling
          ],
        ),
      ),
    );
  }

  Widget _buildWeekSchedule() {
    final now = DateTime.now();
    return RefreshIndicator(
      onRefresh: _loadData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildWeekHeader(),
            const SizedBox(height: 24),
            if (_weekClasses.isEmpty)
              _buildEmptySchedule('Tuần này không có lịch dạy')
            else
              ..._groupClassesByDay().entries.map((entry) {
                return _buildDaySchedule(entry.key, entry.value);
              }),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildAllSchedule() {
    return RefreshIndicator(
      onRefresh: _loadData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildAllClassesHeader(),
            const SizedBox(height: 24),
            if (_allClasses.isEmpty)
              _buildEmptySchedule('Không có lịch dạy nào')
            else
              ..._allClasses.map((cls) => _buildScheduleCard(cls, false)),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  String _getGreeting(DateTime dateTime) {
    final hour = dateTime.hour;
    if (hour < 12) return 'Chào buổi sáng';
    if (hour < 18) return 'Chào buổi chiều';
    return 'Chào buổi tối';
  }

  Widget _buildDateHeader(DateTime date, String greeting) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.blue[600]!,
            Colors.blue[800]!,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$greeting, ${widget.currentUser.fullName}!',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.calendar_today, color: Colors.white70, size: 20),
              const SizedBox(width: 8),
              Text(
                DateFormat('EEEE, d MMMM yyyy', 'vi_VN').format(date),
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.schedule, color: Colors.white70, size: 20),
              const SizedBox(width: 8),
              Text(
                '${_todayClasses.length} buổi học hôm nay',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWeekHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.purple[600]!,
            Colors.purple[800]!,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.purple.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Lịch tuần này',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.date_range, color: Colors.white70, size: 20),
              const SizedBox(width: 8),
              Text(
                '${_getWeekRange()}',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.class_, color: Colors.white70, size: 20),
              const SizedBox(width: 8),
              Text(
                '${_weekClasses.length} buổi học trong tuần',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAllClassesHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.green[600]!,
            Colors.green[800]!,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Tất cả lịch dạy',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.list_alt, color: Colors.white70, size: 20),
              const SizedBox(width: 8),
              Text(
                '${_allClasses.length} lớp học',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getWeekRange() {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final weekEnd = weekStart.add(const Duration(days: 6));

    return '${DateFormat('d/M').format(weekStart)} - ${DateFormat('d/M/yyyy').format(weekEnd)}';
  }

  Map<String, List<ClassModel>> _groupClassesByDay() {
    final Map<String, List<ClassModel>> grouped = {};

    for (final cls in _weekClasses) {
      final dayKey = DateFormat('EEEE, d/M', 'vi_VN').format(cls.startTime);
      if (!grouped.containsKey(dayKey)) {
        grouped[dayKey] = [];
      }
      grouped[dayKey]!.add(cls);
    }

    // Sort classes by time for each day
    for (final day in grouped.keys) {
      grouped[day]!.sort((a, b) => a.startTime.compareTo(b.startTime));
    }

    return grouped;
  }

  Widget _buildDaySchedule(String day, List<ClassModel> classes) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.purple[100],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            day,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.purple[800],
            ),
          ),
        ),
        ...classes.map((cls) => _buildScheduleCard(cls, false)),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildEmptySchedule(String message) {
    return Container(
      padding: const EdgeInsets.all(40),
      margin: const EdgeInsets.only(top: 40),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        children: [
          Icon(
            Icons.event_busy,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Thư giãn và tận hưởng thời gian rảnh nhé!',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleCard(ClassModel classModel, bool showTodayStatus) {
    final isNow = classModel.isOngoing;
    final isUpcoming = classModel.isUpcoming;
    final isPast = !isNow && !isUpcoming;

    Color cardColor = Colors.white;
    Color borderColor = Colors.grey[300]!;

    if (isNow) {
      borderColor = Colors.green;
    } else if (isUpcoming && classModel.isToday) {
      borderColor = Colors.orange;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: isNow ? 2 : 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
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
                    color: _getStatusColor(classModel).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _getStatusIcon(classModel),
                    color: _getStatusColor(classModel),
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
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      if (classModel.isSubjectClass)
                        Text(
                          classModel.subject,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        )
                      else
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'Lớp khóa ${classModel.name}',
                            style: TextStyle(
                              color: Colors.blue[700],
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                if (showTodayStatus)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _getStatusColor(classModel).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _getStatusText(classModel),
                      style: TextStyle(
                        color: _getStatusColor(classModel),
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
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
                const SizedBox(width: 16),
                Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  classModel.room,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            if (classModel.description != null && classModel.description!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                classModel.description!,
                style: TextStyle(
                  color: Colors.grey[700],
                  fontSize: 13,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(ClassModel classModel) {
    if (classModel.isOngoing) return Colors.green;
    if (classModel.isUpcoming && classModel.isToday) return Colors.orange;
    if (classModel.isUpcoming) return Colors.blue;
    return Colors.grey;
  }

  IconData _getStatusIcon(ClassModel classModel) {
    if (classModel.isOngoing) return Icons.play_circle;
    if (classModel.isUpcoming && classModel.isToday) return Icons.schedule;
    if (classModel.isUpcoming) return Icons.event;
    return Icons.check_circle;
  }

  String _getStatusText(ClassModel classModel) {
    if (classModel.isOngoing) return 'Đang diễn ra';
    if (classModel.isUpcoming && classModel.isToday) return 'Sắp bắt đầu';
    if (classModel.isUpcoming) return 'Sắp tới';
    return 'Đã kết thúc';
  }
}