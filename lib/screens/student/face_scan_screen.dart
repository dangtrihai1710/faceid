import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:geolocator/geolocator.dart';
import '../../models/user.dart';
import '../../models/attendance_model.dart';
import '../../models/class_model.dart';
import '../../services/class_service.dart';
import '../../widgets/camera_view.dart';

class FaceScanScreen extends StatefulWidget {
  final User currentUser;
  final List<CameraDescription>? cameras;

  const FaceScanScreen({
    super.key,
    required this.currentUser,
    this.cameras,
  });

  @override
  State<FaceScanScreen> createState() => _FaceScanScreenState();
}

class _FaceScanScreenState extends State<FaceScanScreen> {
  CameraController? _cameraController;
  bool _isScanning = false;
  bool _isSuccess = false;
  String _statusMessage = "Chuẩn bị quét khuôn mặt";
  String? _selectedClassId;
  List<ClassModel> _todayClasses = [];
  double? _latitude;
  double? _longitude;

  @override
  void initState() {
    super.initState();
    _loadTodayClasses();
    _getCurrentLocation();
  }

  Future<void> _loadTodayClasses() async {
    try {
      final classes = await ClassService.getUpcomingClasses();
      setState(() {
        _todayClasses = classes.where((cls) => cls.isToday).toList();
      });
    } catch (e) {
      print('Error loading classes: $e');
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() => _statusMessage = "⚠️ Vui lòng bật GPS");
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() => _statusMessage = "❌ Chưa cấp quyền định vị");
          return;
        }
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _latitude = position.latitude;
        _longitude = position.longitude;
        _statusMessage = "✅ Sẵn sàng quét khuôn mặt";
      });
    } catch (e) {
      setState(() => _statusMessage = "⚠️ Lỗi lấy vị trí GPS");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quét khuôn mặt điểm danh'),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Class Selection
          if (_todayClasses.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.blue[50],
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Chọn môn học:',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _selectedClassId,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    hint: const Text('Chọn môn học để điểm danh'),
                    items: _todayClasses.map((cls) {
                      return DropdownMenuItem<String>(
                        value: cls.id,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(cls.name),
                            Text(
                              '${cls.timeRange} - ${cls.room}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedClassId = value;
                      });
                    },
                  ),
                ],
              ),
            ),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.orange[50],
              child: Row(
                children: [
                  Icon(Icons.info, color: Colors.orange[700]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Không có lớp học nào hôm nay để điểm danh',
                      style: TextStyle(color: Colors.orange[700]),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Camera View
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Stack(
                  children: [
                    CameraView(
                      cameras: widget.cameras,
                      onControllerReady: (controller) {
                        setState(() {
                          _cameraController = controller;
                        });
                      },
                    ),
                    // Face Scan Overlay
                    if (!_isSuccess)
                      Center(
                        child: Container(
                          width: 250,
                          height: 250,
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: Colors.green.withOpacity(0.5),
                              width: 3,
                            ),
                            borderRadius: BorderRadius.circular(125),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.face,
                                size: 60,
                                color: Colors.green.withOpacity(0.7),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Đặt mặt vào khung',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    // Success Overlay
                    if (_isSuccess)
                      Container(
                        color: Colors.green.withOpacity(0.9),
                        child: const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.check_circle,
                                size: 80,
                                color: Colors.white,
                              ),
                              SizedBox(height: 16),
                              Text(
                                'Điểm danh thành công!',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),

          // Status Bar
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(
                      _getStatusIcon(),
                      color: _getStatusColor(),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _statusMessage,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: _getStatusColor(),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Location Info
                if (_latitude != null && _longitude != null)
                  Text(
                    'Vị trí: ${_latitude!.toStringAsFixed(6)}, ${_longitude!.toStringAsFixed(6)}',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
          ),

          // Scan Button
          Container(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _canScan() ? _scanFace : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isSuccess ? Colors.green : Colors.blue[700],
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
                child: _isScanning
                    ? const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          ),
                          SizedBox(width: 12),
                          Text('Đang xử lý...'),
                        ],
                      )
                    : _isSuccess
                        ? const Text('Điểm danh thành công!')
                        : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.camera_alt),
                              SizedBox(width: 8),
                              Text(
                                'Quét khuôn mặt',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool _canScan() {
    return !_isScanning &&
           _cameraController != null &&
           _cameraController!.value.isInitialized &&
           _selectedClassId != null;
  }

  IconData _getStatusIcon() {
    if (_isSuccess) return Icons.check_circle;
    if (_isScanning) return Icons.camera_alt;
    if (_statusMessage.contains('✅')) return Icons.check_circle;
    if (_statusMessage.contains('❌')) return Icons.error;
    return Icons.info;
  }

  Color _getStatusColor() {
    if (_isSuccess) return Colors.green;
    if (_isScanning) return Colors.blue;
    if (_statusMessage.contains('✅')) return Colors.green;
    if (_statusMessage.contains('❌')) return Colors.red;
    if (_statusMessage.contains('⚠️')) return Colors.orange;
    return Colors.blue;
  }

  Future<void> _scanFace() async {
    if (!_canScan()) return;

    setState(() {
      _isScanning = true;
      _statusMessage = "📸 Đang chụp và xử lý khuôn mặt...";
    });

    try {
      // Simulate face scanning
      await Future.delayed(const Duration(seconds: 2));

      // Create attendance record
      final attendance = AttendanceModel(
        id: 'att_${DateTime.now().millisecondsSinceEpoch}',
        classId: _selectedClassId!,
        userId: widget.currentUser.id,
        checkInTime: DateTime.now(),
        latitude: _latitude,
        longitude: _longitude,
        status: AttendanceStatus.present,
      );

      // Save attendance record
      await ClassService.saveAttendanceRecord(attendance);

      setState(() {
        _isScanning = false;
        _isSuccess = true;
        _statusMessage = "✅ Điểm danh thành công!";
      });

      // Auto navigate back after success
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          Navigator.of(context).pop();
        }
      });

    } catch (e) {
      setState(() {
        _isScanning = false;
        _statusMessage = "❌ Lỗi khi quét khuôn mặt: $e";
      });
    }
  }
}