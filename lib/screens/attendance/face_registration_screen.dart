import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:camera/camera.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/primary_button.dart';
import '../../core/services/api_service.dart';
import '../../core/services/face_recognition_service.dart';
import '../../core/models/user_models.dart' as user_models;

class FaceRegistrationScreen extends StatefulWidget {
  final user_models.User currentUser;
  final String classId;
  final VoidCallback? onRegistrationComplete;

  const FaceRegistrationScreen({
    super.key,
    required this.currentUser,
    required this.classId,
    this.onRegistrationComplete,
  });

  @override
  State<FaceRegistrationScreen> createState() => _FaceRegistrationScreenState();
}

class _FaceRegistrationScreenState extends State<FaceRegistrationScreen> {
  CameraController? _cameraController;
  bool _isCameraInitialized = false;
  bool _isProcessing = false;
  final List<File> _capturedImages = [];
  int _currentStep = 1;
  final int _totalSteps = 5;

  // Face detection requirements
  final List<String> _stepInstructions = [
    'Hướng mặt thẳng vào camera',
    'Nhìn sang trái một chút',
    'Nhìn sang phải một chút',
    'Nhìn lên trên một chút',
    'Nhìn xuống dưới một chút'
  ];

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  Future<void> _initializeCamera() async {
    try {
      // Request camera permissions first
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        if (mounted) {
          _showErrorDialog('Không tìm thấy camera nào trên thiết bị');
        }
        return;
      }

      // Try to get front camera first
      CameraDescription? camera;

      try {
        camera = cameras.firstWhere(
          (cam) => cam.lensDirection == CameraLensDirection.front,
        );
      } catch (e) {
        // If front camera not found, use any camera
        debugPrint('Front camera not found, using default camera: $e');
        camera = cameras.first;
      }

      // Camera is guaranteed to be non-null from the previous checks

      // Set camera controller with better settings
      _cameraController = CameraController(
        camera,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      await _cameraController!.initialize();

      // Verify camera is properly initialized
      if (!_cameraController!.value.isInitialized) {
        throw Exception('Camera failed to initialize');
      }

      if (mounted) {
        setState(() {
          _isCameraInitialized = true;
        });
      }
    } catch (e) {
      debugPrint('Camera initialization error: $e');

      // Try to continue without camera for testing
      if (mounted) {
        _showErrorDialog(
          'Không thể khởi tạo camera: $e\n\n'
          'Vui lòng kiểm tra:\n'
          '1. Quyền truy cập camera đã được cấp\n'
          '2. Camera đang hoạt động tốt\n'
          '3. Thiết bị hỗ trợ camera'
        );
      }
    }
  }

  Future<void> _capturePhoto() async {
    if (_cameraController == null || _cameraController!.value.isTakingPicture) {
      return;
    }

    try {
      setState(() {
        _isProcessing = true;
      });

      HapticFeedback.lightImpact();

      final XFile photo = await _cameraController!.takePicture();
      final File imageFile = File(photo.path);

      // Validate image quality
      final isValid = await _validateFaceImage(imageFile);

      if (!isValid) {
        if (mounted) {
          _showErrorDialog('Ảnh không hợp lệ. Vui lòng đảm bảo khuôn mặt rõ ràng và đủ ánh sáng.');
        }
        return;
      }

      // Convert and optimize image
      final optimizedImage = await _optimizeImage(imageFile);

      setState(() {
        _capturedImages.add(optimizedImage);
        _isProcessing = false;
        _currentStep++;
      });

      HapticFeedback.mediumImpact();

      if (_capturedImages.length == _totalSteps) {
        _completeRegistration();
      }
    } catch (e) {
      setState(() {
        _isProcessing = false;
      });
      debugPrint('Photo capture error: $e');
      if (mounted) {
        _showErrorDialog('Lỗi khi chụp ảnh: $e');
      }
    }
  }

  Future<void> _pickImageFromGallery() async {
    try {
      setState(() {
        _isProcessing = true;
      });

      HapticFeedback.lightImpact();

      final ImagePicker picker = ImagePicker();
      final XFile? pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 600,
        imageQuality: 90,
      );

      if (pickedFile == null) {
        setState(() {
          _isProcessing = false;
        });
        return;
      }

      final File imageFile = File(pickedFile.path);

      // Validate image quality
      final isValid = await _validateFaceImage(imageFile);

      if (!isValid) {
        if (mounted) {
          _showErrorDialog('Ảnh không hợp lệ. Vui lòng chọn ảnh có khuôn mặt rõ ràng.');
        }
        return;
      }

      // Convert and optimize image
      final optimizedImage = await _optimizeImage(imageFile);

      setState(() {
        _capturedImages.add(optimizedImage);
        _isProcessing = false;
        _currentStep++;
      });

      HapticFeedback.mediumImpact();

      if (_capturedImages.length == _totalSteps) {
        _completeRegistration();
      }
    } catch (e) {
      setState(() {
        _isProcessing = false;
      });
      debugPrint('Gallery pick error: $e');
      if (mounted) {
        _showErrorDialog('Lỗi khi chọn ảnh: $e');
      }
    }
  }

  Future<bool> _validateFaceImage(File imageFile) async {
    try {
      final faceRecognitionService = FaceRecognitionService();
      return await faceRecognitionService.validateFaceImage(imageFile);
    } catch (e) {
      debugPrint('Face validation error: $e');
      return false;
    }
  }

  Future<File> _optimizeImage(File imageFile) async {
    try {
      final bytes = await imageFile.readAsBytes();
      final image = img.decodeImage(bytes)!;

      // Resize to standard size for face recognition
      final resized = img.copyResize(
        image,
        width: 800,
        height: 600,
        interpolation: img.Interpolation.cubic,
      );

      // Convert back to file
      final optimizedBytes = img.encodeJpg(resized, quality: 90);
      final optimizedFile = File(imageFile.path);
      await optimizedFile.writeAsBytes(optimizedBytes);

      return optimizedFile;
    } catch (e) {
      debugPrint('Image optimization error: $e');
      return imageFile;
    }
  }

  Future<void> _completeRegistration() async {
    try {
      setState(() {
        _isProcessing = true;
      });

      // Convert File objects to String paths
      final List<String> imagePaths = _capturedImages.map((file) => file.path).toList();

      // Use the real API service to register face images
      final result = await ApiService.uploadMultipleFaceImages(
        imagePaths: imagePaths,
        userId: widget.currentUser.id,
        classId: widget.classId,
        fullName: widget.currentUser.fullName,
        email: widget.currentUser.email,
        confidenceThreshold: 0.85,
      );

      if (result == null || result['success'] != true) {
        final message = result?['message'] ?? 'Đăng ký thất bại. Vui lòng thử lại.';
        throw Exception(message);
      }

      if (mounted) {
        _showSuccessDialog();
      }
    } catch (e) {
      setState(() {
        _isProcessing = false;
      });
      debugPrint('Registration completion error: $e');
      if (mounted) {
        _showErrorDialog('Đăng ký thất bại: $e');
      }
    }
  }

  void _retakePhoto() {
    if (_capturedImages.isNotEmpty) {
      final lastImage = _capturedImages.removeLast();
      try {
        lastImage.deleteSync();
      } catch (e) {
        debugPrint('Error deleting file: $e');
      }

      setState(() {
        _currentStep--;
      });
    }
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
            style: AppTextStyles.heading3.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Vui lòng sử dụng nút "Chọn ảnh từ thư viện"\nđể tải lên ảnh',
            style: AppTextStyles.bodyMedium.copyWith(
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Icon(
            Icons.photo_library_outlined,
            size: 40,
            color: AppColors.primary,
          ),
          const SizedBox(height: 8),
          Text(
            'Sử dụng gallery để upload',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.check_circle, color: AppColors.success),
            const SizedBox(width: 8),
            const Text('Đăng ký thành công!'),
          ],
        ),
        content: const Text(
          'Khuôn mặt của bạn đã được đăng ký thành công vào hệ thống. '
          'Giờ bạn có thể sử dụng Face ID để điểm danh.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop();
              widget.onRegistrationComplete?.call();
            },
            child: Text('OK', style: TextStyle(color: AppColors.primary)),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.error, color: AppColors.error),
            const SizedBox(width: 8),
            const Text('Lỗi'),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Đăng ký Face ID'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        elevation: 0,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Progress Header
            Container(
              padding: const EdgeInsets.all(16),
              color: AppColors.primary,
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Bước $_currentStep/$_totalSteps',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.onPrimary,
                        ),
                      ),
                      Text(
                        '${_capturedImages.length}/$_totalSteps ảnh',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.onPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: _capturedImages.length / _totalSteps,
                    backgroundColor: AppColors.onPrimary.withValues(alpha: 0.3),
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.onPrimary),
                  ),
                ],
              ),
            ),

            // Main Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Instructions
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.face,
                            size: 48,
                            color: AppColors.primary,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _currentStep <= _totalSteps
                                ? _stepInstructions[_currentStep - 1]
                                : 'Đang xử lý...',
                            style: AppTextStyles.heading4,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Đảm bảo khuôn mặt của bạn nằm trong khung hình và đủ ánh sáng',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.onSurface.withValues(alpha: 0.7),
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Camera Preview - Fixed overflow issue
                    Expanded(
                      child: Container(
                        width: double.infinity,
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
                          child: _isCameraInitialized && _cameraController != null
                              ? Stack(
                                  children: [
                                    // Camera preview with aspect ratio
                                    SizedBox(
                                      width: double.infinity,
                                      height: double.infinity,
                                      child: FittedBox(
                                        fit: BoxFit.cover,
                                        child: SizedBox(
                                          width: _cameraController!.value.previewSize!.height,
                                          height: _cameraController!.value.previewSize!.width,
                                          child: CameraPreview(_cameraController!),
                                        ),
                                      ),
                                    ),
                                    // Face overlay guide - adjusted for better visibility
                                    Align(
                                      alignment: Alignment.center,
                                      child: Container(
                                        width: 280,  // Increased from 200
                                        height: 350, // Increased from 250, better aspect ratio for face
                                        decoration: BoxDecoration(
                                          border: Border.all(
                                            color: _isProcessing
                                                ? AppColors.error
                                                : AppColors.success,
                                            width: 3,
                                          ),
                                          borderRadius: BorderRadius.circular(140),
                                        ),
                                        child: _isProcessing
                                            ? const Center(
                                                child: Column(
                                                  mainAxisAlignment: MainAxisAlignment.center,
                                                  children: [
                                                    CircularProgressIndicator(
                                                      color: Colors.white,
                                                      strokeWidth: 3,
                                                    ),
                                                    SizedBox(height: 16),
                                                    Text(
                                                      'Đang xử lý...',
                                                      style: TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 16,
                                                        fontWeight: FontWeight.bold,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              )
                                            : Column(
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                children: [
                                                  Icon(
                                                    Icons.face,
                                                    color: Colors.white.withValues(alpha: 0.8),
                                                    size: 80,
                                                  ),
                                                  const SizedBox(height: 8),
                                                  Text(
                                                    'Đặt khuôn mặt vào khung',
                                                    style: TextStyle(
                                                      color: Colors.white.withValues(alpha: 0.9),
                                                      fontSize: 14,
                                                      fontWeight: FontWeight.w500,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                      ),
                                    ),
                                  ],
                                )
                              : _buildCameraFallback(),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Action Buttons
                    Column(
                      children: [
                        Row(
                          children: [
                            if (_capturedImages.isNotEmpty) ...[
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: _isProcessing ? null : _retakePhoto,
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    side: BorderSide(color: AppColors.error),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.refresh, color: AppColors.error),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Chụp lại',
                                        style: TextStyle(color: AppColors.error),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                            ],
                            Expanded(
                              flex: _capturedImages.isNotEmpty ? 1 : 2,
                              child: PrimaryButton(
                                text: _currentStep > _totalSteps
                                    ? 'Đang xử lý...'
                                    : 'Chụp ảnh',
                                onPressed: (_isProcessing || _currentStep > _totalSteps)
                                    ? null
                                    : _capturePhoto,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 12),

                        // Upload from Gallery Button
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: (_isProcessing || _currentStep > _totalSteps)
                                ? null
                                : _pickImageFromGallery,
                            icon: const Icon(Icons.photo_library_outlined),
                            label: const Text('Hoặc chọn ảnh từ thư viện'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              side: BorderSide(color: AppColors.primary.withValues(alpha: 0.7)),
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
            ),
          ],
        ),
      ),
    );
  }
}