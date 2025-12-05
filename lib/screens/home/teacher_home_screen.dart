import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../models/user.dart';
import '../teacher/teacher_class_management_screen.dart';
import '../teacher/teacher_attendance_management_screen.dart';
import '../teacher/teacher_schedule_screen.dart';
import '../teacher/teacher_report_screen.dart';
import '../teacher/teacher_profile_screen.dart';
import '../../core/services/api_service.dart' as CoreApi;

class TeacherHomeScreen extends StatefulWidget {
  final User currentUser;

  const TeacherHomeScreen({
    super.key,
    required this.currentUser,
  });

  @override
  State<TeacherHomeScreen> createState() => _TeacherHomeScreenState();
}

class _TeacherHomeScreenState extends State<TeacherHomeScreen> {
  late User _currentUser;
  List<Map<String, dynamic>> _todayClasses = [];
  Map<String, dynamic> _stats = {
    'totalClasses': 6,
    'totalStudents': 127,
    'todayAttendance': 87,
    'activeClasses': 4,
  };
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    // Use user data passed from login screen directly
    _currentUser = widget.currentUser;

    // Load additional data with timeout to avoid hanging
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        _loadAdditionalDataWithTimeout();
      }
    });
  }

  Future<void> _loadAdditionalDataWithTimeout() async {
    try {
      // Load additional data with timeout to prevent hanging
      await Future.wait([
        _loadClasses().timeout(const Duration(seconds: 5)),
        _loadBasicStats().timeout(const Duration(seconds: 5)),
      ]);
    } catch (e) {
      debugPrint('Timeout or error loading additional data: $e');
      // Use fallback data and ensure loading state is reset
      if (mounted) {
        setState(() {
          _todayClasses = _getFallbackClasses();
        });
      }
    }
  }

  List<Map<String, dynamic>> _getFallbackClasses() {
    return [
      {
        'id': '1',
        'name': 'Lập trình nâng cao',
        'code': 'IT4050',
        'time': '7:00 - 9:00',
        'room': 'Phòng A101',
        'students': 45,
        'status': 'upcoming',
      },
      {
        'id': '2',
        'name': 'Cơ sở dữ liệu',
        'code': 'IT4060',
        'time': '9:30 - 11:30',
        'room': 'Phòng B205',
        'students': 42,
        'status': 'upcoming',
      },
    ];
  }

  Future<void> _loadClasses() async {
    try {
      // Use getStudentClasses API endpoint which is available and works
      final classesData = await CoreApi.ApiService.getStudentClasses();
      setState(() {
        _todayClasses = classesData.isEmpty ? _getFallbackClasses() : classesData;
      });
      debugPrint('✅ Loaded ${classesData.length} classes from existing API');
    } catch (e) {
      debugPrint('❌ Error loading classes from existing API: $e');
      setState(() {
        _todayClasses = _getFallbackClasses();
      });
    }
  }

  Future<void> _loadBasicStats() async {
    try {
      // Try to get real statistics from API
      final statsResponse = await CoreApi.ApiService.getTeacherStatistics(_currentUser.userId);

      if (statsResponse != null && statsResponse['success'] == true) {
        final statsData = statsResponse['data'] ?? {};
        setState(() {
          _stats = {
            'totalClasses': statsData['total_classes'] ?? _todayClasses.length,
            'totalStudents': statsData['total_students'] ?? _calculateTotalStudents(),
            'todayAttendance': statsData['today_attendance_rate'] ?? _calculateAttendanceRate(),
            'activeClasses': statsData['active_classes'] ?? _calculateActiveClasses(),
          };
        });
        debugPrint('✅ Loaded real statistics from API');
      } else {
        // Fallback to calculated stats
        setState(() {
          _stats = {
            'totalClasses': _todayClasses.length,
            'totalStudents': _calculateTotalStudents(),
            'todayAttendance': _calculateAttendanceRate(),
            'activeClasses': _calculateActiveClasses(),
          };
        });
        debugPrint('⚠️ Using calculated statistics (API not available)');
      }
    } catch (e) {
      debugPrint('❌ Error loading basic stats: $e');
      // Fallback to calculated stats
      setState(() {
        _stats = {
          'totalClasses': _todayClasses.length,
          'totalStudents': _calculateTotalStudents(),
          'todayAttendance': _calculateAttendanceRate(),
          'activeClasses': _calculateActiveClasses(),
        };
      });
    }
  }

  int _calculateTotalStudents() {
    // Calculate total students from today's classes
    int total = 0;
    for (var classData in _todayClasses) {
      total += (classData['students'] as num?)?.toInt() ?? 0;
    }
    return total > 0 ? total : 127; // Default fallback
  }

  int _calculateAttendanceRate() {
    // Simulate attendance rate calculation
    return 87; // Default value
  }

  int _calculateActiveClasses() {
    // Count active classes
    int count = 0;
    for (var classData in _todayClasses) {
      if (classData['status'] == 'upcoming' || classData['status'] == 'active') {
        count++;
      }
    }
    return count > 0 ? count : 4; // Default fallback
  }

  
  
  String _getAppBarTitle() {
    switch (_selectedIndex) {
      case 0:
        return 'Trang chủ Giáo viên';
      case 1:
        return 'Quản lý lớp học';
      case 2:
        return 'Điểm danh';
      case 3:
        return 'Hồ sơ cá nhân';
      default:
        return 'Trang chủ Giáo viên';
    }
  }

  Widget _buildHomeTabContent() {
    return RefreshIndicator(
      onRefresh: () async {
        await _loadAdditionalDataWithTimeout();
      },
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          16,
          16,
          16,
          16 + MediaQuery.of(context).padding.bottom + 60, // Account for bottom nav
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Xin chào,',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.onPrimary.withValues(alpha: 0.8),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _currentUser.fullName,
                    style: AppTextStyles.heading2.copyWith(
                      color: AppColors.onPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Chúc bạn một ngày làm việc hiệu quả!',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.onPrimary.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Stats Section
            Text(
              'Thống kê hôm nay',
              style: AppTextStyles.heading4,
            ),
            const SizedBox(height: 12),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.4,
              children: [
                _buildStatCard(
                  'Lớp học',
                  '${_stats['totalClasses']}',
                  Icons.class_outlined,
                  AppColors.primary,
                ),
                _buildStatCard(
                  'Sinh viên',
                  '${_stats['totalStudents']}',
                  Icons.people_outline,
                  AppColors.secondary,
                ),
                _buildStatCard(
                  'Điểm danh',
                  '${_stats['todayAttendance']}%',
                  Icons.check_circle_outline,
                  AppColors.success,
                ),
                _buildStatCard(
                  'Lớp hoạt động',
                  '${_stats['activeClasses']}',
                  Icons.play_circle_outline,
                  AppColors.warning,
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Quick Actions
            Text(
              'Thao tác nhanh',
              style: AppTextStyles.heading4,
            ),
            const SizedBox(height: 12),

            // TẠO MÃ ĐIỂM DANH BUTTON
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  debugPrint('✅ TẠO MÃ ĐIỂM DANH CLICKED!');
                  _showCreateAttendanceCodeDialog();
                },
                icon: Icon(Icons.qr_code_scanner),
                label: Text('Tạo mã điểm danh'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.secondary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
            const SizedBox(height: 12),

            GridView.count(
              shrinkWrap: true,
              physics: const AlwaysScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.1,
              children: [
                _buildActionCard(
                  'Quản lý lớp',
                  Icons.school_outlined,
                  AppColors.primary,
                  () {
                    if (true) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => TeacherClassManagementScreen(
                            currentUser: _currentUser,
                          ),
                        ),
                      );
                    }
                  },
                ),
                _buildActionCard(
                  'Tạo mã điểm danh',
                  Icons.qr_code_scanner,
                  AppColors.secondary,
                  () {
                    debugPrint('🔥 BUTTON PRESSED: Tạo mã điểm danh button clicked!');
                    _showCreateAttendanceCodeDialog();
                  },
                ),
                _buildActionCard(
                  'Lịch teaching',
                  Icons.schedule,
                  AppColors.success,
                  () {
                    if (true) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => TeacherScheduleScreen(
                            currentUser: _currentUser,
                          ),
                        ),
                      );
                    }
                  },
                ),
                _buildActionCard(
                  'Báo cáo',
                  Icons.assessment_outlined,
                  AppColors.warning,
                  () {
                    if (true) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => TeacherReportScreen(
                            currentUser: _currentUser,
                          ),
                        ),
                      );
                    }
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          _getAppBarTitle(),
          style: AppTextStyles.heading3,
        ),
        backgroundColor: AppColors.surface,
        elevation: 0,
        actions: _selectedIndex == 0 ? [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              // Notifications will be implemented in future release
            },
          ),
        ] : null,
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          // Tab 0: Trang chủ
          _buildHomeTabContent(),

          // Tab 1: Lớp học - Direct content without Scaffold
          TeacherClassManagementScreen(
            currentUser: _currentUser,
            showAsTab: true,
          ),

          // Tab 2: Điểm danh - Direct attendance-focused content
          TeacherAttendanceManagementScreen(
            currentUser: _currentUser,
          ),

          // Tab 3: Cá nhân - Full profile screen with tabs
          TeacherProfileScreen(currentUser: _currentUser, showAsTab: true),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.onSurface.withValues(alpha: 0.6),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Trang chủ',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.school_outlined),
            activeIcon: Icon(Icons.school),
            label: 'Lớp học',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.qr_code_scanner_outlined),
            activeIcon: Icon(Icons.qr_code_scanner),
            label: 'Điểm danh',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Cá nhân',
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: color,
            size: 24,
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: AppTextStyles.heading3.copyWith(
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.onSurface.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  
  Widget _buildActionCard(String title, IconData icon, Color color, VoidCallback onTap) {
    debugPrint('🔍 Building action card: $title');
    return InkWell(
      onTap: () {
        debugPrint('🔥 CARD TAPPED: $title');
        onTap();
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: color.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: color,
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: AppTextStyles.bodyMedium.copyWith(
                color: color,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }



  
  void _showCreateAttendanceCodeDialog() {
    debugPrint('🔍 DEBUG: _showCreateAttendanceCodeDialog called');
    debugPrint('🔍 DEBUG: _todayClasses.length: ${_todayClasses.length}');

    if (_todayClasses.isEmpty) {
      debugPrint('🔍 DEBUG: No classes available, showing warning');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Không có lớp học nào để tạo mã điểm danh'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tạo mã điểm danh'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Chọn lớp học để tạo mã điểm danh:'),
            const SizedBox(height: 16),
            ..._todayClasses.asMap().entries.map((entry) {
              final index = entry.key;
              final classData = entry.value;
              debugPrint('🔍 DEBUG: Class[$index]: ${classData.toString()}');
              debugPrint('🔍 DEBUG: Class[$index] ID: ${classData['id']}');
              debugPrint('🔍 DEBUG: Class[$index] Name: ${classData['name']}');

              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  title: Text(classData['name'] ?? 'Lớp không xác định'),
                  subtitle: Text(
                    'Mã: ${classData['code'] ?? 'N/A'} | Phòng: ${classData['room'] ?? 'N/A'}',
                  ),
                  leading: Icon(Icons.school_outlined, color: AppColors.primary),
                  onTap: () {
                    debugPrint('🔍 DEBUG: Class selected: ${classData['id']} - ${classData['name']}');
                    Navigator.pop(context);
                    _createAttendanceCodeForClass(
                      classData['id']?.toString() ?? '',
                      classData['name'] ?? 'Lớp không xác định',
                    );
                  },
                ),
              );
            }),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
        ],
      ),
    );
  }

  Future<void> _createAttendanceCodeForClass(String classId, String className) async {
    debugPrint('🔍 DEBUG: _createAttendanceCodeForClass started');
    debugPrint('🔍 DEBUG: classId: "$classId"');
    debugPrint('🔍 DEBUG: className: "$className"');
    debugPrint('🔍 DEBUG: classId.isEmpty: ${classId.isEmpty}');

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text('Đang tạo mã điểm danh...'),
          ],
        ),
      ),
    );

    try {
      debugPrint('🔄 Creating attendance code for class: $className');
      debugPrint('🔍 DEBUG: About to call ApiService.createAttendanceCode...');

      final result = await CoreApi.ApiService.createAttendanceCode(
        classId,
        duration: const Duration(minutes: 15), // 15 minutes default
      );

      debugPrint('🔍 DEBUG: API call completed');
      debugPrint('🔍 DEBUG: Result type: ${result.runtimeType}');
      debugPrint('🔍 DEBUG: Result value: $result');

      // Close loading dialog
      if (mounted) {
        Navigator.pop(context);
      }

      if (result != null) {
        debugPrint('🔍 DEBUG: Success case - result is not null');
        debugPrint('🔍 DEBUG: Result keys: ${result.keys.toList()}');
        debugPrint("🔍 DEBUG: Result['code']: ${result['code']}");

        // Success - show code dialog
        if (mounted) {
          debugPrint('🔍 DEBUG: Showing success dialog');
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Text('Mã điểm danh thành công!'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Lớp: $className'),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.qr_code_2, color: AppColors.primary, size: 32),
                        const SizedBox(width: 16),
                        Text(
                          result['code']?.toString() ?? 'ERROR',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Mã có hiệu lực trong 15 phút',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Đóng'),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    // Navigate to attendance functionality
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('Tính năng điểm danh đang phát triển'),
                          backgroundColor: AppColors.info,
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Bắt đầu điểm danh'),
                ),
              ],
            ),
          );
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✅ Đã tạo mã điểm danh cho lớp $className'),
              backgroundColor: AppColors.success,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } else {
        debugPrint('🔍 DEBUG: Error case - result is null');
        // Error
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('❌ Không thể tạo mã điểm danh cho lớp $className - API trả về null'),
              backgroundColor: AppColors.error,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('🔍 DEBUG: Exception caught: $e');
      debugPrint('🔍 DEBUG: Exception type: ${e.runtimeType}');
      // Close loading dialog
      if (mounted) {
        Navigator.pop(context);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: $e'),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

}