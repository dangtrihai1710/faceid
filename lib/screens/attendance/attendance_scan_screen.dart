import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/services/attendance_service.dart';
import '../../core/models/class_models.dart';
import '../../widgets/qr_scanner.dart';

class AttendanceScanScreen extends StatefulWidget {
  final AttendanceSession session;
  final Function(AttendanceRecord)? onAttendanceSuccess;

  const AttendanceScanScreen({
    super.key,
    required this.session,
    this.onAttendanceSuccess,
  });

  @override
  State<AttendanceScanScreen> createState() => _AttendanceScanScreenState();
}

class _AttendanceScanScreenState extends State<AttendanceScanScreen> {
  bool _isScanning = false;
  final bool _isCameraInitialized = true; // QR scanner handles camera internally
  String? _errorMessage;
  int _successfulScans = 0;

  @override
  void initState() {
    super.initState();
    // QR scanner initializes camera automatically
  }

  
  Future<void> _processQRCode(String qrData) async {
    if (_isScanning) return;

    setState(() {
      _isScanning = true;
      _errorMessage = null;
    });

    HapticFeedback.lightImpact();

    try {
      // Parse QR code data
      // Expected format: "ATTENDANCE:{sessionId}:{studentId}"
      if (!qrData.startsWith('ATTENDANCE:')) {
        throw Exception('Mã QR không hợp lệ cho điểm danh');
      }

      final parts = qrData.split(':');
      if (parts.length < 3) {
        throw Exception('Mã QR không đủ thông tin');
      }

      final sessionId = parts[1];
      final studentId = parts[2];

      // Validate session
      if (sessionId != widget.session.id) {
        throw Exception('Mã QR không khớp với phiên điểm danh hiện tại');
      }

      // Process attendance using QR code
      final result = await AttendanceService().markAttendanceWithQR(
        widget.session.id,
        studentId,
      );

      if (result.success && result.data != null) {
        setState(() {
          _successfulScans++;
        });

        HapticFeedback.heavyImpact();

        // Show success message
        _showSuccessDialog(result.data!);

        // Notify parent widget
        widget.onAttendanceSuccess?.call(result.data!);
      } else {
        setState(() {
          _errorMessage = result.message ?? 'Điểm danh thất bại';
        });
        HapticFeedback.heavyImpact();
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Lỗi xử lý mã QR: $e';
      });
      HapticFeedback.heavyImpact();
    } finally {
      setState(() {
        _isScanning = false;
      });
    }
  }

  void _showSuccessDialog(AttendanceRecord record) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.check_circle, color: AppColors.primary, size: 28),
            const SizedBox(width: 12),
            const Text('Điểm danh thành công!'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Họ và tên: ${record.studentName}'),
            Text('Lớp: ${record.className}'),
            Text('Thời gian: ${_formatTime(record.checkInTime)}'),
            Text('Trạng thái: ${_getStatusText(record.status)}'),
            if (record.confidence != null)
              Text('Độ chính xác: ${(record.confidence! * 100).toStringAsFixed(1)}%'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Optionally go back to previous screen
              if (widget.onAttendanceSuccess != null) {
                Navigator.of(context).pop();
              }
            },
            child: const Text('Tiếp tục quét'),
          ),
          if (widget.onAttendanceSuccess == null)
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop();
              },
              child: Text('Hoàn thành', style: TextStyle(color: AppColors.primary)),
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
        return 'Muộn';
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
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: AppColors.onBackground),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Quét mã QR điểm danh',
          style: AppTextStyles.heading3.copyWith(
            color: AppColors.onBackground,
          ),
        ),
        centerTitle: true,
        actions: [
          if (_successfulScans > 0)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '$_successfulScans',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Session Info
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
              ),
              child: Column(
                children: [
                  Text(
                    widget.session.className,
                    style: AppTextStyles.heading3.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Giảng viên: ${widget.session.instructorId}',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                  if (widget.session.isActive)
                    Container(
                      margin: const EdgeInsets.only(top: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'Đang hoạt động',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: Colors.green,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // QR Scanner View
            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: _isCameraInitialized
                      ? Stack(
                          children: [
                            QRScanner(
                              onScan: (qrData) {
                                _processQRCode(qrData);
                              },
                              continuous: !_isScanning,
                            ),
                            // Scanning overlay
                            if (_isScanning)
                              Container(
                                color: Colors.black.withValues(alpha: 0.3),
                                child: const Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      CircularProgressIndicator(
                                        valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                                      ),
                                      SizedBox(height: 16),
                                      Text(
                                        'Đang xử lý mã QR...',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            if (_errorMessage != null)
                              Positioned(
                                bottom: 20,
                                left: 20,
                                right: 20,
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.red.withValues(alpha: 0.9),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    _errorMessage!,
                                    style: AppTextStyles.bodyMedium.copyWith(
                                      color: Colors.white,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                          ],
                        )
                      : Container(
                          color: Colors.grey.shade300,
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.qr_code_scanner,
                                  size: 64,
                                  color: Colors.grey.shade600,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  _errorMessage ?? 'Đang khởi tạo camera...',
                                  style: AppTextStyles.bodyMedium.copyWith(
                                    color: Colors.grey.shade600,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                if (_errorMessage != null) ...[
                                  const SizedBox(height: 16),
                                  ElevatedButton.icon(
                                    onPressed: () {
                                      setState(() {
                                        _errorMessage = null;
                                      });
                                    },
                                    icon: const Icon(Icons.refresh),
                                    label: const Text('Thử lại'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.primary,
                                      foregroundColor: Colors.white,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                ),
              ),
            ),

            // Instructions
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Đưa mã QR vào vùng quét để điểm danh',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.onSurface.withValues(alpha: 0.6),
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}