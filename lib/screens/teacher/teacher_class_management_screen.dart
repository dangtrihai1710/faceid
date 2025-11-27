import 'package:flutter/material.dart';
import '../../models/user.dart';
import '../../models/class_model.dart';
import '../../services/api_service.dart';
import 'teacher_attendance_code_screen.dart';
import 'teacher_class_students_screen.dart';

class TeacherClassManagementScreen extends StatefulWidget {
  final User currentUser;

  const TeacherClassManagementScreen({
    super.key,
    required this.currentUser,
  });

  @override
  State<TeacherClassManagementScreen> createState() => _TeacherClassManagementScreenState();
}

class _TeacherClassManagementScreenState extends State<TeacherClassManagementScreen>
    with TickerProviderStateMixin {
  List<ClassModel> _allClasses = [];
  List<ClassModel> _filteredClasses = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _selectedFilter = 'all';
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadClasses();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadClasses() async {
    setState(() => _isLoading = true);

    try {
      // Fetch all classes without instructor_id parameter to avoid ClientException
      final response = await ApiService.makeAuthenticatedRequest(
        'GET',
        '/api/v1/classes/?per_page=100',
      );

      if (response['success'] == true && response['data'] != null) {
        final classesData = response['data'] as List;
        final allClasses = classesData.map((json) => ClassModel.fromJson(json)).toList();

        // Filter classes by current instructor (client-side filtering only)
        final instructorClasses = allClasses.where((classItem) {
          return classItem.instructor == widget.currentUser.userId ||
                 classItem.instructorName?.contains(widget.currentUser.fullName) == true;
        }).toList();

        if (mounted) {
          setState(() {
            _allClasses = instructorClasses;
            _filteredClasses = instructorClasses;
            _isLoading = false;
          });
        }
      } else {
        throw Exception(response['message'] ?? 'Failed to load classes');
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

  void _applyFilter() {
    setState(() {
      _filteredClasses = _allClasses.where((classModel) {
        bool matchesSearch = classModel.displayName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            classModel.subject.toLowerCase().contains(_searchQuery.toLowerCase());

        if (!matchesSearch) return false;

        switch (_selectedFilter) {
          case 'today':
            return classModel.isToday;
          case 'ongoing':
            return classModel.isOngoing;
          case 'past':
            return classModel.isPast;
          default:
            return true;
        }
      }).toList();
    });
  }

  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Quản lý lớp học'),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Hôm nay'),
            Tab(text: 'Đang diễn ra'),
            Tab(text: 'Tất cả'),
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
              onRefresh: _loadClasses,
              child: Column(
                children: [
                  _buildSearchAndFilter(),
                  _buildStatsRow(),
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildClassList(_filteredClasses.where((c) => c.isToday).toList()),
                        _buildClassList(_filteredClasses.where((c) => c.isOngoing).toList()),
                        _buildClassList(_filteredClasses),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildSearchAndFilter() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          TextField(
            onChanged: (value) {
              _searchQuery = value;
              _applyFilter();
            },
            decoration: InputDecoration(
              hintText: 'Tìm kiếm lớp học...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      FilterChip(
                        label: const Text('Tất cả'),
                        selected: _selectedFilter == 'all',
                        onSelected: (value) {
                          _selectedFilter = 'all';
                          _applyFilter();
                        },
                      ),
                      const SizedBox(width: 8),
                      FilterChip(
                        label: const Text('Hôm nay'),
                        selected: _selectedFilter == 'today',
                        onSelected: (value) {
                          _selectedFilter = 'today';
                          _applyFilter();
                        },
                      ),
                      const SizedBox(width: 8),
                      FilterChip(
                        label: const Text('Đang diễn ra'),
                        selected: _selectedFilter == 'ongoing',
                        onSelected: (value) {
                          _selectedFilter = 'ongoing';
                          _applyFilter();
                        },
                      ),
                      const SizedBox(width: 8),
                      FilterChip(
                        label: const Text('Đã kết thúc'),
                        selected: _selectedFilter == 'past',
                        onSelected: (value) {
                          _selectedFilter = 'past';
                          _applyFilter();
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow() {
    final todayCount = _allClasses.where((c) => c.isToday).length;
    final ongoingCount = _allClasses.where((c) => c.isOngoing).length;
    final totalCount = _allClasses.length;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard('Hôm nay', todayCount.toString(), Colors.blue),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard('Đang diễn ra', ongoingCount.toString(), Colors.green),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard('Tất cả', totalCount.toString(), Colors.orange),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, Color color) {
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
            label,
            style: TextStyle(
              fontSize: 12,
              color: color.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClassList(List<ClassModel> classes) {
    if (classes.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.class_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Không có lớp học nào',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: classes.length,
      itemBuilder: (context, index) {
        final classModel = classes[index];
        return _buildClassCard(classModel);
      },
    );
  }

  Widget _buildClassCard(ClassModel classModel) {
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
            // Student count information
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
                if (classModel.studentIds != null && classModel.studentIds!.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(left: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'Đã đăng ký',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.green[700],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            // Hành động quản lý lớp - đi thẳng đến danh sách sinh viên
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _viewStudentList(classModel),
                icon: const Icon(Icons.people),
                label: const Text('Danh sách sinh viên'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _showAttendanceOptions(classModel),
                    icon: const Icon(Icons.how_to_reg),
                    label: const Text('Điểm danh'),
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
                    label: const Text('Danh sách SV'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple,
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
    // Note: Face scanning screen navigation will be implemented when feature is ready
    // Expected navigation: Navigator.pushNamed(context, '/face-scanning', arguments: classModel);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Tính năng quét mặt điểm danh đang được phát triển cho lớp: ${classModel.displayName}'),
        backgroundColor: Colors.teal,
      ),
    );
  }
}