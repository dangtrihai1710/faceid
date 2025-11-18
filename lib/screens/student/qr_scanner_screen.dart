import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../services/qr_service.dart';
import '../../services/class_service.dart';
import '../../services/auth_service.dart';
import '../../models/attendance_model.dart';
import '../../models/user.dart';
import '../../models/class_model.dart';
import 'package:geolocator/geolocator.dart';

class QRScannerScreen extends StatefulWidget {
  final User currentUser;

  const QRScannerScreen({
    super.key,
    required this.currentUser,
  });

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  bool _isScanning = true;
  bool _isProcessing = false;
  String? _scannedData;
  String? _statusMessage;
  Position? _currentPosition;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() => _statusMessage = "Vui lòng bật GPS");
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() => _statusMessage = "Chưa cấp quyền định vị");
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() => _statusMessage = "Quyền GPS bị từ chối vĩnh viễn");
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _currentPosition = position;
      });
    } catch (e) {
      print("GPS Error: $e");
      setState(() => _statusMessage = "Lỗi lấy vị trí GPS");
    }
  }

  Future<void> _processQRCode(String qrData) async {
    setState(() {
      _isProcessing = true;
      _statusMessage = "Đang xử lý QR Code...";
      _isScanning = false;
    });

    try {
      // Validate QR Code
      final validation = await QRService.validateQRCodeData(qrData);

      if (validation != null && validation.containsKey('error')) {
        setState(() {
          _statusMessage = validation['error'];
          _isProcessing = false;
        });
        return;
      }

      final classId = validation!['classId'] as String;
      final className = validation['className'] as String;

      // Get class information
      final classModel = await ClassService.getClassById(classId);
      if (classModel == null) {
        setState(() {
          _statusMessage = "Không tìm thấy thông tin lớp học";
          _isProcessing = false;
        });
        return;
      }

      // Check if attendance is open
      if (!classModel.isAttendanceOpen) {
        setState(() {
          _statusMessage = "Lớp học chưa mở điểm danh";
          _isProcessing = false;
        });
        return;
      }

      // Check if already checked in
      final existingRecords = await ClassService.getAttendanceRecords(widget.currentUser.id);
      final alreadyCheckedIn = existingRecords.any((record) =>
        record.classId == classId &&
        record.checkInTime.day == DateTime.now().day &&
        record.checkInTime.month == DateTime.now().month &&
        record.checkInTime.year == DateTime.now().year
      );

      if (alreadyCheckedIn) {
        setState(() {
          _statusMessage = "Bạn đã điểm danh lớp học này hôm nay";
          _isProcessing = false;
        });
        return;
      }

      // Create attendance record
      final attendance = AttendanceModel(
        id: 'att_${DateTime.now().millisecondsSinceEpoch}',
        classId: classId,
        userId: widget.currentUser.id,
        checkInTime: DateTime.now(),
        latitude: _currentPosition?.latitude,
        longitude: _currentPosition?.longitude,
        status: AttendanceStatus.present,
        notes: 'Điểm danh qua QR Code',
      );

      // Save attendance record
      await ClassService.saveAttendanceRecord(attendance);

      setState(() {
        _statusMessage = "✅ Điểm danh thành công!";
        _isProcessing = false;
      });

      // Show success dialog
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Text('✅ Điểm danh thành công!'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Lớp: $className'),
                const SizedBox(height: 8),
                Text('Thời gian: ${DateTime.now().toString().substring(0, 19)}'),
                if (_currentPosition != null) ...[
                  const SizedBox(height: 8),
                  Text('Vị trí: ${_currentPosition!.latitude.toStringAsFixed(6)}, ${_currentPosition!.longitude.toStringAsFixed(6)}'),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).pop();
                },
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      print('Error processing QR code: $e');
      setState(() {
        _statusMessage = "Lỗi khi xử lý QR Code: $e";
        _isProcessing = false;
      });
    }
  }

  void _onDetect(BarcodeCapture capture) {
    if (!_isScanning || _isProcessing) return;

    final barcode = capture.barcodes.first;
    if (barcode.rawValue != null) {
      final scannedData = barcode.rawValue!;

      // Prevent multiple scans of same code
      if (_scannedData != scannedData) {
        setState(() {
          _scannedData = scannedData;
        });
        _processQRCode(scannedData);
      }
    }
  }

  void _resetScan() {
    setState(() {
      _isScanning = true;
      _scannedData = null;
      _statusMessage = null;
      _isProcessing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quét mã QR'),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Camera View
          Expanded(
            flex: 3,
            child: Stack(
              children: [
                MobileScanner(
                  controller: MobileScannerController(
                    detectionSpeed: DetectionSpeed.normal,
                    facing: CameraFacing.back,
                  ),
                  onDetect: _onDetect,
                ),
                if (_isScanning)
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Colors.red.withOpacity(0.5),
                        width: 2,
                      ),
                    ),
                    child: CustomPaint(
                      painter: QRScannerOverlayPainter(),
                    ),
                  ),
                if (_isProcessing)
                  Container(
                    color: Colors.black.withOpacity(0.5),
                    child: const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Đang xử lý...',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Status and Controls
          Expanded(
            flex: 1,
            child: Container(
              padding: const EdgeInsets.all(16),
              color: Colors.grey[100],
              child: Column(
                children: [
                  if (_statusMessage != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _statusMessage!.contains('✅')
                            ? Colors.green[100]
                            : _statusMessage!.contains('❌') || _statusMessage!.contains('Lỗi')
                                ? Colors.red[100]
                                : Colors.blue[100],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: _statusMessage!.contains('✅')
                              ? Colors.green
                              : _statusMessage!.contains('❌') || _statusMessage!.contains('Lỗi')
                                  ? Colors.red
                                  : Colors.blue,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _statusMessage!.contains('✅')
                                ? Icons.check_circle
                                : _statusMessage!.contains('❌') || _statusMessage!.contains('Lỗi')
                                    ? Icons.error
                                    : Icons.info,
                            color: _statusMessage!.contains('✅')
                                ? Colors.green
                                : _statusMessage!.contains('❌') || _statusMessage!.contains('Lỗi')
                                    ? Colors.red
                                    : Colors.blue,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _statusMessage!,
                              style: TextStyle(
                                color: _statusMessage!.contains('✅')
                                    ? Colors.green[700]
                                    : _statusMessage!.contains('❌') || _statusMessage!.contains('Lỗi')
                                        ? Colors.red[700]
                                        : Colors.blue[700],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Instructions
                  if (_isScanning) ...[
                    Text(
                      'Hướng camera vào mã QR để điểm danh',
                      style: TextStyle(
                        color: Colors.grey[700],
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Đảm bảo mã QR được cấp bởi giảng viên',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ] else if (!_isProcessing) ...[
                    ElevatedButton.icon(
                      onPressed: _resetScan,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Quét lại'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue[700],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class QRScannerOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.red
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final path = Path();

    // Draw scanning corner brackets
    final double cornerLength = 30;
    final double cornerWidth = 4;

    // Top-left corner
    path.moveTo(50, 50);
    path.lineTo(50 + cornerLength, 50);
    path.moveTo(50, 50);
    path.lineTo(50, 50 + cornerLength);

    // Top-right corner
    path.moveTo(size.width - 50, 50);
    path.lineTo(size.width - 50 - cornerLength, 50);
    path.moveTo(size.width - 50, 50);
    path.lineTo(size.width - 50, 50 + cornerLength);

    // Bottom-left corner
    path.moveTo(50, size.height - 50);
    path.lineTo(50 + cornerLength, size.height - 50);
    path.moveTo(50, size.height - 50);
    path.lineTo(50, size.height - 50 - cornerLength);

    // Bottom-right corner
    path.moveTo(size.width - 50, size.height - 50);
    path.lineTo(size.width - 50 - cornerLength, size.height - 50);
    path.moveTo(size.width - 50, size.height - 50);
    path.lineTo(size.width - 50, size.height - 50 - cornerLength);

    // Draw scan line animation
    final scanLineY = (DateTime.now().millisecondsSinceEpoch % 2000) / 2000 * (size.height - 100) + 50;
    final scanLinePaint = Paint()
      ..color = Colors.red.withOpacity(0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    canvas.drawLine(
      Offset(50, scanLineY),
      Offset(size.width - 50, scanLineY),
      scanLinePaint,
    );

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}