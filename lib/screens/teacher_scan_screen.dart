import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:geolocator/geolocator.dart';
import '../models/user.dart';
import '../models/class_model.dart';
import '../models/attendance_model.dart';
import '../services/class_service.dart';
import '../widgets/camera_view.dart';

class TeacherScanScreen extends StatefulWidget {
  final ClassModel classModel;
  final User currentUser;
  final List<CameraDescription>? cameras;

  const TeacherScanScreen({
    super.key,
    required this.classModel,
    required this.currentUser,
    this.cameras,
  });

  @override
  State<TeacherScanScreen> createState() => _TeacherScanScreenState();
}

class _TeacherScanScreenState extends State<TeacherScanScreen>
    with TickerProviderStateMixin {
  CameraController? _cameraController;
  bool _isCameraInitialized = false;
  bool _isScanning = false;
  bool _isProcessing = false;
  Position? _currentPosition;
  String? _statusMessage;
  List<AttendanceModel> _scannedStudents = [];
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
    _getCurrentLocation();
    _loadScannedStudents();

    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _pulseController.dispose();
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
            _statusMessage = "📷 Sẵn sàng quét FaceID";
          });
        }
      } catch (e) {
        print('Camera initialization error: $e');
        setState(() {
          _statusMessage = "❌ Camera không khả dụng";
        });
      }
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _statusMessage = "⚠️ Vui lòng bật GPS";
        });
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _statusMessage = "❌ Quyền vị trí bị từ chối";
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
        _statusMessage = "⚠️ Lỗi lấy vị trí: $e";
      });
    }
  }

  Future<void> _loadScannedStudents() async {
    try {
      final today = DateTime.now();
      final attendanceRecords = await ClassService.getAttendanceRecordsByClass(widget.classModel.id);
      final todayRecords = attendanceRecords.where((record) {
        return record.checkInTime.day == today.day &&
               record.checkInTime.month == today.month &&
               record.checkInTime.year == today.year;
      }).toList();

      setState(() {
        _scannedStudents = todayRecords;
      });
    } catch (e) {
      print('Error loading scanned students: $e');
    }
  }

  Future<void> _scanStudent() async {
    if (_isProcessing) return;

    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      setState(() {
        _statusMessage = "❌ Camera chưa sẵn sàng";
      });
      return;
    }

    setState(() {
      _isProcessing = true;
      _statusMessage = "🔍 Đang nhận diện khuôn mặt...";
    });

    try {
      final XFile file = await _cameraController!.takePicture();

      // Simulate face recognition processing
      await Future.delayed(const Duration(seconds: 2));

      // Simulate successful recognition (random for demo)
      final isRecognized = DateTime.now().millisecond % 3 != 0; // ~67% success rate

      if (isRecognized) {
        // Generate mock student data
        final studentNames = [
          'Nguyễn Văn An', 'Trần Thị Bình', 'Lê Văn Cường',
          'Phạm Thị Dung', 'Hoàng Văn Em', 'Đỗ Thị Giang'
        ];

        final randomStudent = studentNames[DateTime.now().millisecond % studentNames.length];

        // Check if already scanned
        final alreadyScanned = _scannedStudents.any((attendance) =>
            attendance.userId.contains(randomStudent.split(' ').last.toLowerCase()));

        if (!alreadyScanned) {
          final attendance = AttendanceModel(
            id: 'att_${DateTime.now().millisecondsSinceEpoch}',
            classId: widget.classModel.id,
            userId: 'student_${randomStudent.split(' ').last.toLowerCase()}',
            checkInTime: DateTime.now(),
            photoPath: file.path,
            latitude: _currentPosition?.latitude,
            longitude: _currentPosition?.longitude,
            status: DateTime.now().difference(widget.classModel.startTime).inMinutes > 15
                ? AttendanceStatus.late
                : AttendanceStatus.present,
          );

          await ClassService.saveAttendanceRecord(attendance);

          setState(() {
            _scannedStudents.add(attendance);
            _statusMessage = "✅ Đã điểm danh: $randomStudent";
          });

          // Show success feedback
          _showSuccessFeedback(randomStudent);
        } else {
          setState(() {
            _statusMessage = "⚠️ Sinh viên này đã điểm danh";
          });
        }
      } else {
        setState(() {
          _statusMessage = "❌ Không nhận diện được khuôn mặt";
        });
      }
    } catch (e) {
      print('Scan error: $e');
      setState(() {
        _statusMessage = "❌ Lỗi quét: $e";
      });
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  void _showSuccessFeedback(String studentName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.green,
        title: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            const Text('Điểm danh thành công!', style: TextStyle(color: Colors.white)),
          ],
        ),
        content: Text(
          '$studentName đã được điểm danh thành công.',
          style: const TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    // Auto-dismiss after 2 seconds
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        Navigator.of(context).pop();
      }
    });
  }

  void _toggleScanning() {
    setState(() {
      _isScanning = !_isScanning;
      if (_isScanning) {
        _statusMessage = "🔍 Đang trong chế độ quét...";
        _startAutoScan();
      } else {
        _statusMessage = "⏸️ Đã dừng quét";
      }
    });
  }

  void _startAutoScan() {
    if (!_isScanning) return;

    Future.delayed(const Duration(seconds: 3), () {
      if (_isScanning && mounted) {
        _scanStudent();
        _startAutoScan(); // Continue scanning
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quét FaceID hàng loạt'),
        backgroundColor: Colors.purple[700],
        foregroundColor: Colors.white,
        elevation: 2,
        actions: [
          IconButton(
            icon: Icon(_isScanning ? Icons.pause : Icons.play_arrow),
            onPressed: _toggleScanning,
            tooltip: _isScanning ? 'Dừng quét' : 'Bắt đầu quét',
          ),
        ],
      ),
      body: Column(
        children: [
          // Status Bar
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _isScanning ? Colors.purple[700] : Colors.grey[700],
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.classModel.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.people, color: Colors.white, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      'Đã quét: ${_scannedStudents.length} sinh viên',
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                    ),
                    const Spacer(),
                    if (_isScanning)
                      AnimatedBuilder(
                        animation: _pulseAnimation,
                        builder: (context, child) {
                          return Transform.scale(
                            scale: _pulseAnimation.value,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                'ĐANG QUÉT',
                                style: TextStyle(
                                  color: Colors.white,
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
                if (_statusMessage != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _statusMessage!,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Camera Section
          Expanded(
            flex: 2,
            child: Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Stack(
                  children: [
                    if (_isCameraInitialized && _cameraController != null)
                      CameraPreview(_cameraController!)
                    else
                      Container(
                        color: Colors.black,
                        child: const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.camera_alt_outlined, size: 64, color: Colors.white54),
                              SizedBox(height: 8),
                              Text(
                                'Camera không khả dụng',
                                style: TextStyle(color: Colors.white54),
                              ),
                            ],
                          ),
                        ),
                      ),

                    // Scanning Overlay
                    if (_isScanning)
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.green, width: 3),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: CustomPaint(
                          painter: ScanningOverlayPainter(),
                          size: Size.infinite,
                        ),
                      ),

                    // Processing Overlay
                    if (_isProcessing)
                      Container(
                        color: Colors.black.withOpacity(0.5),
                        child: const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CircularProgressIndicator(color: Colors.white),
                              SizedBox(height: 16),
                              Text(
                                'Đang xử lý...',
                                style: TextStyle(color: Colors.white, fontSize: 16),
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

          // Scanned Students List
          Expanded(
            flex: 1,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.purple[50],
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(12),
                        topRight: Radius.circular(12),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.history, color: Colors.purple[700]),
                        const SizedBox(width: 8),
                        Text(
                          'Sinh viên đã quét (${_scannedStudents.length})',
                          style: TextStyle(
                            color: Colors.purple[700],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: _scannedStudents.isEmpty
                        ? const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.face_outlined, size: 48, color: Colors.grey),
                                SizedBox(height: 8),
                                Text(
                                  'Chưa có sinh viên nào được quét',
                                  style: TextStyle(color: Colors.grey),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(8),
                            itemCount: _scannedStudents.length,
                            itemBuilder: (context, index) {
                              final attendance = _scannedStudents[index];
                              return ListTile(
                                dense: true,
                                leading: CircleAvatar(
                                  radius: 16,
                                  backgroundColor: attendance.status == AttendanceStatus.present
                                      ? Colors.green
                                      : Colors.orange,
                                  child: Icon(
                                    attendance.status == AttendanceStatus.present
                                        ? Icons.check
                                        : Icons.access_time,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                ),
                                title: Text(
                                  'Sinh viên ${index + 1}',
                                  style: const TextStyle(fontSize: 14),
                                ),
                                subtitle: Text(
                                  '${attendance.checkInTime.hour.toString().padLeft(2, '0')}:${attendance.checkInTime.minute.toString().padLeft(2, '0')}',
                                  style: const TextStyle(fontSize: 12),
                                ),
                                trailing: Text(
                                  attendance.status == AttendanceStatus.present ? 'Đúng giờ' : 'Trễ',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: attendance.status == AttendanceStatus.present
                                        ? Colors.green
                                        : Colors.orange,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),

          // Bottom Action Bar
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isProcessing ? null : _scanStudent,
                    icon: _isProcessing
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.camera_alt),
                    label: Text(_isProcessing ? 'Đang xử lý...' : 'Quét ngay'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple[700],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  icon: const Icon(Icons.done),
                  label: const Text('Hoàn thành'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ScanningOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.green.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final path = Path();

    // Draw scanning corners
    final cornerLength = 30.0;
    final cornerWidth = 4.0;

    // Top-left corner
    path.moveTo(0, cornerLength);
    path.lineTo(0, 0);
    path.lineTo(cornerLength, 0);

    // Top-right corner
    path.moveTo(size.width - cornerLength, 0);
    path.lineTo(size.width, 0);
    path.lineTo(size.width, cornerLength);

    // Bottom-right corner
    path.moveTo(size.width, size.height - cornerLength);
    path.lineTo(size.width, size.height);
    path.lineTo(size.width - cornerLength, size.height);

    // Bottom-left corner
    path.moveTo(cornerLength, size.height);
    path.lineTo(0, size.height);
    path.lineTo(0, size.height - cornerLength);

    final cornerPaint = Paint()
      ..color = Colors.green
      ..strokeWidth = cornerWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(path, cornerPaint);

    // Draw center scanning line
    final linePaint = Paint()
      ..color = Colors.green.withOpacity(0.8)
      ..strokeWidth = 2;

    final currentTime = DateTime.now().millisecondsSinceEpoch / 1000;
    final lineY = (currentTime % 2.0) / 2.0 * size.height;

    canvas.drawLine(
      Offset(size.width * 0.1, lineY),
      Offset(size.width * 0.9, lineY),
      linePaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}