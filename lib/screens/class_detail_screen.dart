import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:geolocator/geolocator.dart';
import '../models/class_model.dart';
import '../models/user.dart';
import '../models/attendance_model.dart';
import '../services/class_service.dart';
import '../services/auth_service.dart';
import '../widgets/camera_view.dart';

class ClassDetailScreen extends StatefulWidget {
  final ClassModel classModel;
  final User currentUser;
  final List<CameraDescription>? cameras;

  const ClassDetailScreen({
    super.key,
    required this.classModel,
    required this.currentUser,
    this.cameras,
  });

  @override
  State<ClassDetailScreen> createState() => _ClassDetailScreenState();
}

class _ClassDetailScreenState extends State<ClassDetailScreen> {
  final ClassService _classService = ClassService();
  final AuthService _authService = AuthService();
  CameraController? _cameraController;
  bool _isCameraInitialized = false;
  bool _isProcessingAttendance = false;
  bool _isLoadingAttendance = false;
  List<AttendanceModel> _attendanceList = [];
  Position? _currentPosition;
  String? _statusMessage;
  late ClassModel _currentClass;

  @override
  void initState() {
    super.initState();
    _currentClass = widget.classModel;
    _initializeCamera();
    _getCurrentLocation();
    _loadAttendanceList();
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  Future<void> _initializeCamera() async {
    if (widget.cameras != null && widget.cameras!.isNotEmpty) {
      try {
        _cameraController = CameraController(
          widget.cameras!.first,
          ResolutionPreset.high,
          enableAudio: false,
        );
        await _cameraController!.initialize();
        if (mounted) {
          setState(() {
            _isCameraInitialized = true;
          });
        }
      } catch (e) {
        print('Camera initialization error: $e');
        setState(() {
          _statusMessage = "Camera không khả dụng";
        });
      }
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _statusMessage = "Dịch vụ vị trí không bật";
        });
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _statusMessage = "Quyền truy cập vị trí bị từ chối";
          });
          return;
        }
      }

      final position = await Geolocator.getCurrentPosition();
      setState(() {
        _currentPosition = position;
      });
    } catch (e) {
      print('Location error: $e');
      setState(() {
        _statusMessage = "Lỗi lấy vị trí: $e";
      });
    }
  }

  Future<void> _loadAttendanceList() async {
    setState(() {
      _isLoadingAttendance = true;
    });

    try {
      final attendanceList = await ClassService.getAttendanceRecordsByClass(_currentClass.id);
      setState(() {
        _attendanceList = attendanceList;
        _isLoadingAttendance = false;
      });
    } catch (e) {
      print('Error loading attendance list: $e');
      setState(() {
        _isLoadingAttendance = false;
        _statusMessage = "Lỗi tải danh sách điểm danh";
      });
    }
  }

  bool _isInstructor() {
    return widget.currentUser.fullName.toLowerCase() == _currentClass.instructor.toLowerCase() ||
           widget.currentUser.role == 'instructor';
  }

  Future<void> _toggleAttendance() async {
    try {
      final newIsOpen = !_currentClass.isAttendanceOpen;
      final updatedClass = _currentClass.copyWith(
        isAttendanceOpen: newIsOpen,
        attendanceOpenTime: newIsOpen ? DateTime.now() : null,
        attendanceCloseTime: newIsOpen ? null : DateTime.now(),
      );

      await ClassService.updateClass(updatedClass);

      setState(() {
        _currentClass = updatedClass;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_currentClass.isAttendanceOpen
              ? 'Đã mở điểm danh cho lớp học'
              : 'Đã đóng điểm danh cho lớp học'),
          backgroundColor: _currentClass.isAttendanceOpen ? Colors.green : Colors.orange,
        ),
      );
    } catch (e) {
      print('Error toggling attendance: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lỗi khi thay đổi trạng thái điểm danh'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _markAttendance() async {
    if (!_currentClass.isAttendanceOpen) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lớp học chưa mở điểm danh'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Camera chưa sẵn sàng'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isProcessingAttendance = true;
      _statusMessage = "Đang xử lý điểm danh...";
    });

    try {
      final XFile file = await _cameraController!.takePicture();

      // Simulate face recognition and attendance processing
      await Future.delayed(const Duration(seconds: 3));

      final attendance = AttendanceModel(
        id: 'att_${DateTime.now().millisecondsSinceEpoch}',
        classId: _currentClass.id,
        userId: widget.currentUser.id,
        checkInTime: DateTime.now(),
        photoPath: file.path,
        latitude: _currentPosition?.latitude,
        longitude: _currentPosition?.longitude,
        status: AttendanceStatus.present,
      );

      await ClassService.saveAttendanceRecord(attendance);
      await _loadAttendanceList();

      setState(() {
        _isProcessingAttendance = false;
        _statusMessage = "✅ Điểm danh thành công!";
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Điểm danh thành công!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      print('Attendance error: $e');
      setState(() {
        _isProcessingAttendance = false;
        _statusMessage = "Lỗi điểm danh: $e";
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi điểm danh: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Color _getStatusColor() {
    if (_currentClass.isAttendanceOpen) return Colors.green;
    if (_currentClass.isOngoing) return Colors.blue;
    if (_currentClass.isUpcoming) return Colors.orange;
    return Colors.grey;
  }

  Widget _buildClassInfoCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.class_,
                  color: _getStatusColor(),
                  size: 32,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _currentClass.name,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        _currentClass.subject,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getStatusColor().withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _getStatusColor()),
                  ),
                  child: Text(
                    _currentClass.statusText,
                    style: TextStyle(
                      color: _getStatusColor(),
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(Icons.person, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Text(
                  'Giảng viên: ${_currentClass.instructor}',
                  style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.access_time, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Text(
                  'Thời gian: ${_currentClass.timeRange}',
                  style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.location_on, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Text(
                  'Phòng: ${_currentClass.room}',
                  style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                ),
              ],
            ),
            if (_currentClass.description != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.description, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _currentClass.description!,
                      style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAttendanceControl() {
    if (_isInstructor()) {
      return Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.admin_panel_settings, color: Colors.purple[700]),
                  const SizedBox(width: 8),
                  const Text(
                    'Điều khiển điểm danh',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _currentClass.isAttendanceOpen
                      ? Colors.green.withOpacity(0.1)
                      : Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _currentClass.isAttendanceOpen ? Colors.green : Colors.orange,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _currentClass.attendanceStatusText,
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        color: _currentClass.isAttendanceOpen ? Colors.green : Colors.orange,
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: _currentClass.canOpenAttendance || _currentClass.canCloseAttendance
                          ? _toggleAttendance
                          : null,
                      icon: Icon(
                        _currentClass.isAttendanceOpen ? Icons.lock : Icons.lock_open,
                      ),
                      label: Text(
                        _currentClass.isAttendanceOpen ? 'Đóng điểm danh' : 'Mở điểm danh',
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _currentClass.isAttendanceOpen ? Colors.orange : Colors.green,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              if (!_currentClass.canOpenAttendance && !_currentClass.canCloseAttendance) ...[
                const SizedBox(height: 8),
                Text(
                  _currentClass.isCompleted
                      ? 'Lớp học đã kết thúc'
                      : 'Chỉ có thể mở/đóng điểm danh trong thời gian diễn ra lớp học',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    }

    // Student view
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.how_to_reg, color: Colors.blue[700]),
                const SizedBox(width: 8),
                const Text(
                  'Điểm danh',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _currentClass.isAttendanceOpen
                    ? Colors.green.withOpacity(0.1)
                    : Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _currentClass.isAttendanceOpen ? Colors.green : Colors.grey,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _currentClass.attendanceStatusText,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: _currentClass.isAttendanceOpen ? Colors.green : Colors.grey,
                          ),
                        ),
                        if (!_currentClass.isAttendanceOpen) ...[
                          const SizedBox(height: 4),
                          Text(
                            'Vui lòng chờ giảng viên mở điểm danh',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Icon(
                    _currentClass.isAttendanceOpen
                        ? Icons.check_circle
                        : Icons.access_time,
                    color: _currentClass.isAttendanceOpen ? Colors.green : Colors.grey,
                    size: 32,
                  ),
                ],
              ),
            ),
            if (_statusMessage != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue),
                ),
                child: Text(
                  _statusMessage!,
                  style: TextStyle(
                    color: Colors.blue[700],
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAttendanceSection() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.people, color: Colors.indigo[700]),
                const SizedBox(width: 8),
                Text(
                  'Đã điểm danh (${_attendanceList.length})',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_isLoadingAttendance)
              const Center(child: CircularProgressIndicator())
            else if (_attendanceList.isEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Center(
                  child: Text(
                    'Chưa có ai điểm danh',
                    style: TextStyle(
                      color: Colors.grey,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _attendanceList.length,
                itemBuilder: (context, index) {
                  final attendance = _attendanceList[index];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: attendance.statusColor.withOpacity(0.2),
                      child: Icon(
                        Icons.person,
                        color: attendance.statusColor,
                        size: 20,
                      ),
                    ),
                    title: Text(
                      'Sinh viên ${index + 1}',
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    subtitle: Text(
                      'Thời gian: ${attendance.formattedCheckInTime}',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: attendance.statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        attendance.statusText,
                        style: TextStyle(
                          color: attendance.statusColor,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCameraSection() {
    if (!_isInstructor() && _currentClass.isAttendanceOpen) {
      return Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.camera_alt, color: Colors.green[700]),
                  const SizedBox(width: 8),
                  const Text(
                    'Điểm danh bằng FaceID',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (_isCameraInitialized && _cameraController != null)
                Container(
                  height: 200,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: CameraPreview(_cameraController!),
                  ),
                )
              else
                Container(
                  height: 200,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.camera_alt_outlined, size: 48, color: Colors.grey),
                        SizedBox(height: 8),
                        Text('Camera không khả dụng', style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isProcessingAttendance ? null : _markAttendance,
                  icon: _isProcessingAttendance
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.face),
                  label: Text(
                    _isProcessingAttendance ? 'Đang xử lý...' : 'Điểm danh ngay',
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return const SizedBox.shrink();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chi tiết lớp học'),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
        elevation: 2,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildClassInfoCard(),
            const SizedBox(height: 16),
            _buildAttendanceControl(),
            const SizedBox(height: 16),
            _buildCameraSection(),
            const SizedBox(height: 16),
            _buildAttendanceSection(),
          ],
        ),
      ),
    );
  }
}