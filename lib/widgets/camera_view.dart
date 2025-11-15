import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';
import '../core/widgets/real_camera_preview.dart';
import '../core/services/camera_service.dart';
import '../core/services/api_service.dart';
import '../core/services/location_service.dart';

class CameraView extends StatefulWidget {
  final dynamic classItem; // Can be null for student, ClassModel for teacher

  const CameraView({
    super.key,
    this.classItem,
  });

  @override
  State<CameraView> createState() => _CameraViewState();
}

class _CameraViewState extends State<CameraView>
    with TickerProviderStateMixin {
  bool _isProcessing = false;
  bool _hasPermissions = false;
  bool _permissionsChecked = false;
  Map<String, dynamic>? _currentLocation;

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    );

    _fadeController.forward();
    _checkPermissions();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    CameraService.dispose();
    super.dispose();
  }

  Future<void> _checkPermissions() async {
    try {
      // Check camera permission
      final cameraPermission = await Permission.camera.request();
      // Check location permission
      final locationPermission = await Permission.location.request();

      setState(() {
        _hasPermissions = cameraPermission.isGranted && locationPermission.isGranted;
        _permissionsChecked = true;
      });

      if (_hasPermissions) {
        _getCurrentLocation();
      }
    } catch (e) {
      debugPrint('Error checking permissions: $e');
      setState(() {
        _permissionsChecked = true;
      });
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      final location = await LocationService.getCurrentLocation();
      setState(() {
        _currentLocation = location;
      });
    } catch (e) {
      debugPrint('Error getting location: $e');
    }
  }

  
  Future<void> _processFaceRecognition(String imagePath) async {
    try {
      setState(() {
        _isProcessing = true;
      });

      // Get current location if not available
      if (_currentLocation == null) {
        await _getCurrentLocation();
      }

      // Simulate processing delay
      await Future.delayed(const Duration(seconds: 2));

      // Call API for face recognition
      // Note: You'll need to pass actual classId and userId from your app state
      final result = await ApiService.uploadImageForFaceRecognition(
        imagePath: imagePath,
        classId: widget.classItem?['id'] ?? 'demo_class_id', // Replace with actual class ID
        userId: 'demo_user_id', // Replace with actual user ID from login
        gpsData: _currentLocation,
        deviceId: 'flutter_device',
      );

      final isSuccess = result != null && result.contains('successful');

      if (mounted) {
        Navigator.pushReplacementNamed(
          context,
          '/result',
          arguments: {
            'success': isSuccess,
            'timestamp': DateTime.now(),
            'classItem': widget.classItem,
            'message': result ?? 'Điểm danh thành công!',
          },
        );
      }
    } catch (e) {
      debugPrint('Face recognition error: $e');
      if (mounted) {
        _showErrorDialog('Lỗi nhận diện khuôn mặt: $e');
      }
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Lỗi'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
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
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Text(
          'Điểm danh Face ID',
          style: AppTextStyles.heading4.copyWith(
            color: AppColors.onBackground,
          ),
        ),
        centerTitle: true,
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Column(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    const SizedBox(height: 20),

                    // Instructions or permissions warning
                    if (!_isProcessing) ...[
                      if (!_permissionsChecked)
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.warning.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppColors.warning.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.sync,
                                color: AppColors.warning,
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Đang kiểm tra quyền truy cập...',
                                  style: AppTextStyles.bodyMedium.copyWith(
                                    color: AppColors.warning,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )
                      else if (!_hasPermissions)
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.error.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppColors.error.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.error_outline,
                                color: AppColors.error,
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Vui lòng cấp quyền truy cập camera và vị trí để sử dụng tính năng này',
                                  style: AppTextStyles.bodyMedium.copyWith(
                                    color: AppColors.error,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.info.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppColors.info.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                color: AppColors.info,
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Vui lòng đặt khuôn mặt của bạn vào khung và chụp ảnh',
                                  style: AppTextStyles.bodyMedium.copyWith(
                                    color: AppColors.info,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 32),
                    ],

                    // Real Camera Preview
                    Expanded(
                      child: Center(
                        child: RealCameraPreview(
                          isScanning: _isProcessing,
                          height: MediaQuery.of(context).size.height * 0.5,
                          onImageCaptured: _hasPermissions ? _processFaceRecognition : null,
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Processing Status
                    if (_isProcessing) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                AppColors.primary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Đang xử lý...',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ] else ...[
                      // Class info (for teachers)
                      if (widget.classItem != null) ...[
                        Container(
                          width: double.infinity,
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
                              Text(
                                widget.classItem?.subject ?? '',
                                style: AppTextStyles.heading4,
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(
                                    Icons.location_on_outlined,
                                    size: 16,
                                    color: AppColors.onSurface.withValues(alpha: 0.6),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Phòng ${widget.classItem?.room ?? ''}',
                                    style: AppTextStyles.bodySmall.copyWith(
                                      color: AppColors.onSurface.withValues(alpha: 0.7),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Icon(
                                    Icons.access_time,
                                    size: 16,
                                    color: AppColors.onSurface.withValues(alpha: 0.6),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    widget.classItem?.time ?? '',
                                    style: AppTextStyles.bodySmall.copyWith(
                                      color: AppColors.onSurface.withValues(alpha: 0.7),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],

                      // Cancel Button
                      SizedBox(
                        width: double.infinity,
                        child: TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: Text(
                            'Hủy',
                            style: AppTextStyles.buttonMedium.copyWith(
                              color: AppColors.error,
                            ),
                          ),
                        ),
                      ),

                      // Location status
                      if (_currentLocation != null) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.success.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.location_on,
                                color: AppColors.success,
                                size: 16,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Đã xác định vị trí',
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: AppColors.success,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
