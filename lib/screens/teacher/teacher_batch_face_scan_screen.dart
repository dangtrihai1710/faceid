import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:camera/camera.dart';
import 'package:geolocator/geolocator.dart';
import '../../models/user.dart';
import '../../models/class_model.dart';
import '../../models/attendance_model.dart';
import '../../services/class_service.dart';
import '../../widgets/camera_view.dart';

class TeacherBatchFaceScanScreen extends StatefulWidget {
  final User currentUser;
  final List<CameraDescription>? cameras;
  final ClassModel classModel;

  const TeacherBatchFaceScanScreen({
    super.key,
    required this.currentUser,
    this.cameras,
    required this.classModel,
  });

  @override
  State<TeacherBatchFaceScanScreen> createState() => _TeacherBatchFaceScanScreenState();
}

class _TeacherBatchFaceScanScreenState extends State<TeacherBatchFaceScanScreen>
    with TickerProviderStateMixin {
  CameraController? _cameraController;
  bool _isScanning = false;
  String _statusMessage = "Chuẩn bị quét khuôn mặt tập thể";
  List<AttendanceModel> _scannedStudents = [];
  List<String> _scannedFaceIds = [];
  double? _latitude;
  double? _longitude;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
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
        _statusMessage = "✅ Sẵn sàng quét khuôn mặt tập thể";
      });
    } catch (e) {
      setState(() => _statusMessage = "⚠️ Lỗi lấy vị trí GPS");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quét khuôn mặt tập thể'),
        backgroundColor: Colors.purple[700],
        foregroundColor: Colors.white,
        actions: [
          if (_scannedStudents.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.checklist, color: Colors.white),
              onPressed: _showAttendanceSummary,
              tooltip: 'Xem danh sách điểm danh',
            ),
          if (_scannedStudents.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.save, color: Colors.white),
              onPressed: _saveAllAttendance,
              tooltip: 'Lưu tất cả',
            ),
        ],
      ),
      body: Column(
        children: [
          // Class Info
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.purple[50],
            child: Row(
              children: [
                Icon(Icons.class_, color: Colors.purple[700]),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.classModel.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.purple,
                        ),
                      ),
                      Text(
                        '${widget.classModel.timeRange} - ${widget.classModel.room}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.purple[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${_scannedStudents.length} sinh viên đã quét',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.purple,
                    ),
                  ),
                ),
              ],
            ),
          ),

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
                    // Face Recognition Overlay
                    Container(
                      color: Colors.black.withOpacity(0.3),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Spacer(),
                          // Face Scanning Area
                          Container(
                            width: 300,
                            height: 200,
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: Colors.green.withOpacity(0.5),
                                width: 2,
                              ),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Stack(
                              children: [
                                // Center Crosshair
                                Center(
                                  child: CustomPaint(
                                    size: const Size(300, 200),
                                    painter: FaceScanPainter(),
                                  ),
                                ),
                                // Scanned Faces Overlay
                                ...List.generate(
                                  _scannedStudents.length,
                                  (index) => _buildScannedFaceOverlay(index),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Hướng camera vào khuôn mặt sinh viên',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Ứng dụng: ${
                              _scannedStudents.isEmpty
                                ? 'Chưa có sinh viên nào'
                                : '${_scannedStudents.length} sinh viên'
                            }',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 14,
                            ),
                          ),
                          const Spacer(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Controls
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
                if (_latitude != null && _longitude != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Vị trí: ${_latitude!.toStringAsFixed(6)}, ${_longitude!.toStringAsFixed(6)}',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isScanning ? null : _startBatchScanning,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _isScanning ? Colors.grey : Colors.purple[700],
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
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
                                  Text('Đang quét...'),
                                ],
                              )
                            : const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.face),
                                  SizedBox(width: 8),
                                  Text(
                                    'Bắt đầu quét',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    if (_scannedStudents.isNotEmpty)
                      ElevatedButton(
                        onPressed: _clearScannedStudents,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red[600],
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.clear),
                            SizedBox(width: 8),
                            Text('Xóa danh sách'),
                          ],
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScannedFaceOverlay(int index) {
    final positions = [
      Offset(100, 50),
      Offset(200, 50),
      Offset(150, 100),
      Offset(100, 150),
      Offset(200, 150),
      Offset(150, 50),
      Offset(125, 125),
      Offset(175, 75),
    ];

    final position = positions[index % positions.length];

    return Positioned(
      left: position.dx - 25,
      top: position.dy - 25,
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          border: Border.all(
            color: Colors.green,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(25),
        ),
        child: const Icon(
          Icons.check_circle,
          color: Colors.green,
          size: 24,
        ),
      ),
    );
  }

  IconData _getStatusIcon() {
    if (_scannedStudents.isNotEmpty) return Icons.people;
    if (_isScanning) return Icons.camera_alt;
    if (_statusMessage.contains('✅')) return Icons.check_circle;
    if (_statusMessage.contains('❌')) return Icons.error;
    return Icons.info;
  }

  Color _getStatusColor() {
    if (_scannedStudents.isNotEmpty) return Colors.green;
    if (_isScanning) return Colors.blue;
    if (_statusMessage.contains('✅')) return Colors.green;
    if (_statusMessage.contains('❌')) return Colors.red;
    if (_statusMessage.contains('⚠️')) return Colors.orange;
    return Colors.purple;
  }

  Future<void> _startBatchScanning() async {
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
      _isScanning = true;
      _statusMessage = "📸 Đang quét khuôn mặt...";
    });

    try {
      // Simulate batch face scanning
      for (int i = 0; i < 5; i++) {
        if (!_isScanning) break; // User cancelled

        await Future.delayed(const Duration(seconds: 1));

        final attendance = AttendanceModel(
          id: 'att_${DateTime.now().millisecondsSinceEpoch}_$i',
          classId: widget.classModel.id,
          userId: 'student_${DateTime.now().millisecondsSinceEpoch}_$i',
          checkInTime: DateTime.now(),
          latitude: _latitude,
          longitude: _longitude,
          status: AttendanceStatus.present,
          notes: 'Điểm danh bằng quét khuôn mặt tập thể',
        );

        setState(() {
          _scannedStudents.add(attendance);
          _scannedFaceIds.add('face_${DateTime.now().millisecondsSinceEpoch}_$i');
        });

        HapticFeedback.lightImpact();
      }
    } catch (e) {
      setState(() {
        _isScanning = false;
        _statusMessage = "❌ Lỗi khi quét: $e";
      });
    }

    setState(() {
      _isScanning = false;
      _statusMessage = "✅ Hoàn thành quét tập thể";
    });

    // Auto-save after scanning
    if (_scannedStudents.isNotEmpty) {
      _saveAllAttendance();
    }
  }

  void _clearScannedStudents() {
    setState(() {
      _scannedStudents.clear();
      _scannedFaceIds.clear();
      _statusMessage = "✅ Đã xóa danh sách sinh viên";
    });

    HapticFeedback.mediumImpact();
  }

  void _saveAllAttendance() async {
    try {
      for (final attendance in _scannedStudents) {
        await ClassService.saveAttendanceRecord(attendance);
      }

      setState(() {
        _statusMessage = "✅ Đã lưu ${_scannedStudents.length} bản ghi điểm danh";
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Đã lưu thành công ${_scannedStudents.length} bản ghi điểm danh!',
            style: const TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.green[600],
          duration: const Duration(seconds: 3),
        ),
      );

      HapticFeedback.heavyImpact();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi khi lưu: $e'),
          backgroundColor: Colors.red[600],
        ),
      );
    }
  }

  void _showAttendanceSummary() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Icon(Icons.people, color: Colors.purple[700]),
                const SizedBox(width: 8),
                Text(
                  'Danh sách điểm danh (${_scannedStudents.length} sinh viên)',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Lớp: ${widget.classModel.name}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              'Thời gian: ${widget.classModel.timeRange}',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _scannedStudents.length,
                itemBuilder: (context, index) {
                  final attendance = _scannedStudents[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[200]!),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 16,
                          backgroundColor: Colors.green[100],
                          child: Text(
                            '${index + 1}',
                            style: const TextStyle(
                              color: Colors.green,
                              fontSize: 14,
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
                                'Sinh viên ${index + 1}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                              Text(
                                'ID: ${attendance.userId}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                              Text(
                                'Check-in: ${attendance.formattedCheckInTime}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.check_circle,
                          color: Colors.green[600],
                          size: 20,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _saveAllAttendance();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple[700],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.save),
                    const SizedBox(width: 8),
                    Text('Lưu tất cả (${_scannedStudents.length})'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Đóng'),
            ),
          ],
        ),
      ),
    );
  }
}

// Custom painter for face scanning overlay
class FaceScanPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.green.withOpacity(0.3)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    // Draw face outline
    final centerX = size.width / 2;
    final centerY = size.height / 2;
    final faceWidth = size.width * 0.6;
    final faceHeight = size.height * 0.8;

    // Face oval
    final rect = Rect.fromCenter(
      center: Offset(centerX, centerY),
      width: faceWidth,
      height: faceHeight,
    );
    canvas.drawOval(rect, paint);

    // Eyes
    final eyeRadius = 8.0;
    final eyeY = centerY - faceHeight * 0.15;
    final eyeSpacing = faceWidth * 0.25;

    canvas.drawCircle(
      Offset(centerX - eyeSpacing, eyeY),
      eyeRadius,
      paint,
    );
    canvas.drawCircle(
      Offset(centerX + eyeSpacing, eyeY),
      eyeRadius,
      paint,
    );

    // Nose
    final noseY = centerY;
    final noseWidth = 12;
    canvas.drawLine(
      Offset(centerX - noseWidth/2, noseY + 10),
      Offset(centerX + noseWidth/2, noseY + 10),
      paint,
    );

    // Mouth
    final mouthY = centerY + faceHeight * 0.2;
    final mouthWidth = faceWidth * 0.3;
    canvas.drawLine(
      Offset(centerX - mouthWidth/2, mouthY),
      Offset(centerX + mouthWidth/2, mouthY),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}