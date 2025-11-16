import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/services/camera_service.dart';
import '../../core/services/face_recognition_service.dart';
import '../../core/services/api_service.dart';
import '../../core/models/class_models.dart';

class FaceAttendanceScreen extends StatefulWidget {
  final AttendanceSession session;
  final Function(AttendanceRecord)? onAttendanceSuccess;

  const FaceAttendanceScreen({
    super.key,
    required this.session,
    this.onAttendanceSuccess,
  });

  @override
  State<FaceAttendanceScreen> createState() => _FaceAttendanceScreenState();
}

class _FaceAttendanceScreenState extends State<FaceAttendanceScreen> {
  bool _isScanning = false;
  bool _isCameraInitialized = false;
  String? _errorMessage;
  String? _lastRecognitionResult;
  double? _lastConfidenceScore;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  @override
  void dispose() {
    CameraService.dispose();
    super.dispose();
  }

  Future<void> _initializeCamera() async {
    try {
      await CameraService.initialize();
      setState(() {
        _isCameraInitialized = CameraService.isInitialized;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Lỗi khởi tạo camera: $e';
        _isCameraInitialized = false;
      });
    }
  }

  Future<void> _scanFace() async {
    if (_isProcessing || !CameraService.isInitialized) return;

    setState(() {
      _isScanning = true;
      _isProcessing = true;
      _errorMessage = null;
      _lastRecognitionResult = null;
      _lastConfidenceScore = null;
    });

    HapticFeedback.mediumImpact();

    try {
      // Capture image from camera
      final imagePath = await CameraService.captureImage();

      if (imagePath == null) {
        throw Exception('Không thể chụp ảnh từ camera');
      }

      final imageFile = File(imagePath);

      // Perform face recognition
      final faceRecognitionService = FaceRecognitionService();
      final recognitionResult = await faceRecognitionService.recognizeFace(
        imageFile,
        sessionId: widget.session.id,
        classId: widget.session.classId,
      );

      if (mounted) {
        if (recognitionResult.success) {
          final confidence = recognitionResult.confidence ?? 0.0;
          final threshold = 0.85; // 85% threshold

          setState(() {
            _lastRecognitionResult = recognitionResult.studentName;
            _lastConfidenceScore = confidence;
          });

          if (confidence >= threshold) {
            // Face recognition successful, mark attendance
            await _markAttendance(imageFile, recognitionResult);
          } else {
            // Confidence below threshold
            _showThresholdFailureDialog(confidence, threshold);
          }
        } else {
          setState(() {
            _errorMessage = recognitionResult.errorMessage ?? 'Nhận diện khuôn mặt thất bại';
          });
          HapticFeedback.heavyImpact();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Lỗi khi quét khuôn mặt: $e';
        });
        HapticFeedback.heavyImpact();
      }
    } finally {
      if (mounted) {
        setState(() {
          _isScanning = false;
          _isProcessing = false;
        });
      }
    }
  }

  Future<void> _markAttendance(File imageFile, dynamic recognitionResult) async {
    try {
      // Use the real API service for face recognition attendance
      final result = await ApiService.uploadImageForFaceRecognition(
        imagePath: imageFile.path,
        classId: widget.session.classId,
        userId: recognitionResult['student_id'] ?? 'unknown',
        confidenceThreshold: 0.85,
      );

      if (mounted) {
        if (result != null && result.contains('successful')) {
          HapticFeedback.lightImpact();
          // Create a mock attendance record for success dialog
          final attendanceRecord = AttendanceRecord(
            id: 'face_attendance_${DateTime.now().millisecondsSinceEpoch}',
            studentId: recognitionResult['student_id'] ?? 'unknown',
            studentName: recognitionResult['student_name'] ?? 'Unknown',
            classId: widget.session.classId,
            className: widget.session.className,
            sessionId: widget.session.id,
            checkInTime: DateTime.now(),
            status: 'on_time',
            method: 'face_recognition',
            confidence: recognitionResult['confidence'] ?? 0.9,
          );
          _showAttendanceSuccessDialog(attendanceRecord);
        } else {
          _showErrorDialog('Điểm danh thất bại', result ?? 'Lỗi không xác định');
        }
      }
    } catch (e) {
      if (mounted) {
        _showErrorDialog('Lỗi điểm danh', 'Không thể đánh dấu điểm danh: $e');
      }
    }
  }

  void _showAttendanceSuccessDialog(AttendanceRecord record) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.check_circle, color: AppColors.success),
            const SizedBox(width: 8),
            const Text('Điểm danh thành công!'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Sinh viên: ${record.studentName}'),
            Text('Lớp: ${record.className}'),
            Text('Thời gian: ${_formatTime(record.checkInTime)}'),
            Text('Trạng thái: ${_getStatusText(record.status)}'),
            if (record.confidence != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.face, size: 20, color: AppColors.success),
                    const SizedBox(width: 8),
                    Text(
                      'Độ chính xác Face ID: ${(record.confidence! * 100).toStringAsFixed(1)}%',
                      style: TextStyle(
                        color: AppColors.success,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop();
              widget.onAttendanceSuccess?.call(record);
            },
            child: Text('Hoàn thành', style: TextStyle(color: AppColors.primary)),
          ),
        ],
      ),
    );
  }

  void _showThresholdFailureDialog(double confidence, double threshold) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.error_outline, color: AppColors.warning),
            const SizedBox(width: 8),
            const Text('Độ chính xác chưa đạt'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Nhận diện khuôn mặt thành công nhưng độ chính xác chưa đạt ngưỡng.'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.assessment, size: 20, color: AppColors.warning),
                      const SizedBox(width: 8),
                      Text('Độ chính xác: ${(confidence * 100).toStringAsFixed(1)}%'),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.flag, size: 20, color: AppColors.primary),
                      const SizedBox(width: 8),
                      Text('Ngưỡng yêu cầu: ${(threshold * 100).toStringAsFixed(0)}%'),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text('Gợi ý: Đảm bảo ánh sáng tốt và nhìn thẳng vào camera.'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Thử lại', style: TextStyle(color: AppColors.primary)),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.error, color: AppColors.error),
            const SizedBox(width: 8),
            Text(title),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('OK', style: TextStyle(color: AppColors.primary)),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'on_time':
        return 'Đúng giờ';
      case 'late':
        return 'Đi muộn';
      case 'absent':
        return 'Vắng mặt';
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Điểm danh Face ID'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Session Info
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.session.className,
                      style: AppTextStyles.heading4.copyWith(
                        color: AppColors.onPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Mã phiên: ${widget.session.id}',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.onPrimary.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Camera View
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Stack(
                      children: [
                        if (_isCameraInitialized && CameraService.controller != null)
                          Stack(
                            children: [
                              // Real camera preview
                              SizedBox.expand(
                                child: FittedBox(
                                  fit: BoxFit.cover,
                                  child: SizedBox(
                                    width: CameraService.controller!.value.previewSize!.height,
                                    height: CameraService.controller!.value.previewSize!.width,
                                    child: CameraService.controller!.buildPreview(),
                                  ),
                                ),
                              ),
                              _buildFaceScanOverlay(),
                            ],
                          )
                        else
                          _buildCameraFallback(),

                        // Scanning indicator
                        if (_isScanning)
                          Container(
                            color: Colors.white.withValues(alpha: 0.3),
                            child: const Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  CircularProgressIndicator(
                                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                                  ),
                                  SizedBox(height: 16),
                                  Text(
                                    'Đang nhận diện khuôn mặt...',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
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

              const SizedBox(height: 20),

              // Recognition Result or Error
              if (_lastRecognitionResult != null) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.check_circle, color: AppColors.success),
                          const SizedBox(width: 8),
                          Text(
                            'Nhận diện thành công',
                            style: AppTextStyles.heading4.copyWith(
                              color: AppColors.success,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text('Sinh viên: $_lastRecognitionResult'),
                      if (_lastConfidenceScore != null)
                        Text(
                          'Độ chính xác: ${(_lastConfidenceScore! * 100).toStringAsFixed(1)}%',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: _lastConfidenceScore! >= 0.85
                                ? AppColors.success
                                : AppColors.warning,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              if (_errorMessage != null) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error, color: AppColors.error),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.error,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Scan Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: _isProcessing ? null : _scanFace,
                  icon: _isProcessing
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.face),
                  label: Text(_isProcessing ? 'Đang xử lý...' : 'Quét Face ID'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFaceScanOverlay() {
    return Stack(
      children: [
        // Face guide frame
        Center(
          child: Container(
            width: 280,
            height: 350,
            decoration: BoxDecoration(
              border: Border.all(
                color: Colors.white,
                width: 3,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.face,
                  size: 80,
                  color: Colors.white.withValues(alpha: 0.8),
                ),
                const SizedBox(height: 16),
                Text(
                  'Đưa khuôn mặt vào khung',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    shadows: [
                      Shadow(
                        color: Colors.black.withValues(alpha: 0.5),
                        offset: const Offset(1, 1),
                        blurRadius: 2,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        // Corner indicators
        Positioned(
          top: MediaQuery.of(context).size.height * 0.25 - 140,
          left: MediaQuery.of(context).size.width * 0.5 - 140,
          child: _buildCorner(Colors.white),
        ),
        Positioned(
          top: MediaQuery.of(context).size.height * 0.25 - 140,
          right: MediaQuery.of(context).size.width * 0.5 - 140,
          child: _buildCorner(Colors.white, mirror: true),
        ),
        Positioned(
          bottom: MediaQuery.of(context).size.height * 0.25 - 210,
          left: MediaQuery.of(context).size.width * 0.5 - 140,
          child: _buildCorner(Colors.white),
        ),
        Positioned(
          bottom: MediaQuery.of(context).size.height * 0.25 - 210,
          right: MediaQuery.of(context).size.width * 0.5 - 140,
          child: _buildCorner(Colors.white, mirror: true),
        ),
      ],
    );
  }

  Widget _buildCorner(Color color, {bool mirror = false}) {
    return Transform.rotate(
      angle: mirror ? 1.5708 : 0,
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(color: color, width: 4),
            left: BorderSide(color: color, width: 4),
          ),
        ),
      ),
    );
  }

  Widget _buildCameraFallback() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Colors.grey[100],
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.camera_alt_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Camera không khả dụng',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Vui lòng kiểm tra quyền truy cập camera',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }
}