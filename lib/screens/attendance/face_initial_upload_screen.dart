import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/services/api_service.dart';
import '../../core/services/face_recognition_service.dart';
import '../../core/models/user_models.dart' as user_models;

class FaceInitialUploadScreen extends StatefulWidget {
  final user_models.User currentUser;
  final String classId;
  final VoidCallback? onUploadComplete;

  const FaceInitialUploadScreen({
    super.key,
    required this.currentUser,
    required this.classId,
    this.onUploadComplete,
  });

  @override
  State<FaceInitialUploadScreen> createState() => _FaceInitialUploadScreenState();
}

class _FaceInitialUploadScreenState extends State<FaceInitialUploadScreen> {
  final ImagePicker _imagePicker = ImagePicker();
  final List<File> _selectedImages = [];
  bool _isProcessing = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Đăng ký Face ID lần đầu'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.face,
                      size: 48,
                      color: AppColors.onPrimary,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Chào mừng ${widget.currentUser.fullName}!',
                      style: AppTextStyles.heading3.copyWith(
                        color: AppColors.onPrimary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Tải lên 5 ảnh khuôn mặt với các góc khác nhau',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.onPrimary.withValues(alpha: 0.9),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    LinearProgressIndicator(
                      value: _selectedImages.length / 5,
                      backgroundColor: AppColors.onPrimary.withValues(alpha: 0.3),
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.onPrimary),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${_selectedImages.length}/5 ảnh đã tải lên',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.onPrimary,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Upload area
              Expanded(
                child: _selectedImages.length < 5
                    ? _buildUploadArea()
                    : _buildCompleteArea(),
              ),

              const SizedBox(height: 20),

              // Action buttons
              if (_selectedImages.length == 5) ...[
                ElevatedButton(
                  onPressed: _isProcessing ? null : _submitRegistration,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isProcessing
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
                            SizedBox(width: 8),
                            Text('Đang đăng ký...'),
                          ],
                        )
                      : const Text('Đăng ký Face ID'),
                ),
              ] else if (_selectedImages.isNotEmpty) ...[
                OutlinedButton(
                  onPressed: _isProcessing ? null : _resetImages,
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: AppColors.error),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Xóa và bắt đầu lại',
                    style: TextStyle(color: AppColors.error),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUploadArea() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.3),
          style: BorderStyle.solid,
          width: 2,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: _isProcessing ? null : _pickImageFromStep,
        borderRadius: BorderRadius.circular(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.cloud_upload_outlined,
              size: 64,
              color: _isProcessing
                  ? AppColors.onSurface.withValues(alpha: 0.4)
                  : AppColors.primary,
            ),
            const SizedBox(height: 16),
            Text(
              _isProcessing ? 'Đang xử lý...' : 'Chạm để tải lên ảnh',
              style: AppTextStyles.bodyLarge.copyWith(
                color: _isProcessing
                    ? AppColors.onSurface.withValues(alpha: 0.6)
                    : AppColors.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (!_isProcessing) ...[
              const SizedBox(height: 8),
              Text(
                'Ảnh ${_selectedImages.length + 1}: ${_getInstruction(_selectedImages.length)}',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.onSurface.withValues(alpha: 0.7),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCompleteArea() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.check_circle,
          size: 80,
          color: AppColors.success,
        ),
        const SizedBox(height: 16),
        Text(
          'Đã tải lên đủ 5 ảnh!',
          style: AppTextStyles.heading3.copyWith(
            color: AppColors.success,
          ),
        ),
        const SizedBox(height: 16),
        // Preview uploaded images
        SizedBox(
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _selectedImages.length,
            itemBuilder: (context, index) {
              return Container(
                margin: const EdgeInsets.only(right: 8),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(
                    _selectedImages[index],
                    width: 80,
                    height: 100,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 80,
                        height: 100,
                        color: AppColors.surface,
                        child: const Icon(Icons.error),
                      );
                    },
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  String _getInstruction(int index) {
    final instructions = [
      'Ảnh thẳng - nhìn vào camera',
      'Ảnh bên trái - hơi nghiêng đầu sang trái',
      'Ảnh bên phải - hơi nghiêng đầu sang phải',
      'Ảnh phía trên - hơi ngẩng đầu lên',
      'Ảnh phía dưới - hơi cúi đầu xuống',
    ];
    return instructions[index];
  }

  Future<void> _pickImageFromStep() async {
    try {
      setState(() {
        _isProcessing = true;
      });

      HapticFeedback.lightImpact();

      final ImageSource? source = await showDialog<ImageSource>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Chọn nguồn ảnh'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Chụp ảnh mới'),
                onTap: () => Navigator.of(context).pop(ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Chọn từ thư viện'),
                onTap: () => Navigator.of(context).pop(ImageSource.gallery),
              ),
            ],
          ),
        ),
      );

      if (source == null) {
        setState(() {
          _isProcessing = false;
        });
        return;
      }

      final XFile? pickedFile = await _imagePicker.pickImage(
        source: source,
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
      final isValid = await _validateImageQuality(imageFile);

      if (!isValid) {
        if (mounted) {
          _showErrorDialog('Ảnh không hợp lệ. Vui lòng chọn ảnh có khuôn mặt rõ ràng.');
        }
        return;
      }

      setState(() {
        _selectedImages.add(imageFile);
        _isProcessing = false;
        HapticFeedback.mediumImpact();
      });
    } catch (e) {
      setState(() {
        _isProcessing = false;
      });
      debugPrint('Image pick error: $e');
      if (mounted) {
        _showErrorDialog('Lỗi khi chọn ảnh: $e');
      }
    }
  }

  Future<bool> _validateImageQuality(File imageFile) async {
    try {
      final faceRecognitionService = FaceRecognitionService();
      return await faceRecognitionService.validateFaceImage(imageFile);
    } catch (e) {
      debugPrint('Image validation error: $e');
      return true; // Allow if validation fails
    }
  }

  Future<void> _submitRegistration() async {
    try {
      setState(() {
        _isProcessing = true;
      });

      // Convert File objects to String paths
      final List<String> imagePaths = _selectedImages.map((file) => file.path).toList();

      // Use the real API service to register face images
      final result = await ApiService.uploadMultipleFaceImages(
        imagePaths: imagePaths,
        classId: widget.classId,
        confidenceThreshold: 0.85,
      );

      if (mounted) {
        if (result != null && result['success'] == true) {
          final message = result['message'] ?? 'Đăng ký thành công';
          final validCount = result['valid_images']?.length ?? _selectedImages.length;
          final qualityScore = ((result['quality_score'] ?? 0.0) * 100).toStringAsFixed(1);
          final mongoSaved = result['mongodb_saved'] ?? false;

          _showSuccessDialogWithDetails(
            message: message,
            validImages: validCount,
            qualityScore: qualityScore,
            mongoSaved: mongoSaved,
          );
        } else {
          final message = result?['message'] ?? 'Đăng ký thất bại. Vui lòng thử lại.';
          String detailedMessage = message;

          if (result != null) {
            final validCount = result['valid_images']?.length ?? 0;
            if (validCount > 0) {
              detailedMessage = '$message\n$validCount/${_selectedImages.length} ảnh đã được lưu thành công.';
            }
          }

          _showErrorDialogWithRetry(detailedMessage);
        }
      }
    } catch (e) {
      setState(() {
        _isProcessing = false;
      });
      debugPrint('Registration submission error: $e');
      if (mounted) {
        _showErrorDialogWithRetry('Lỗi đăng ký: $e');
      }
    }
  }

  void _resetImages() {
    setState(() {
      _selectedImages.clear();
      _isProcessing = false;
    });
  }

  
  void _showSuccessDialogWithDetails({
    required String message,
    required int validImages,
    required String qualityScore,
    required bool mongoSaved,
  }) {
    setState(() {
      _isProcessing = false;
    });

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.check_circle, color: AppColors.success),
            const SizedBox(width: 8),
            const Text('Đăng ký Face ID thành công!'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(message),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.photo_library, size: 20, color: AppColors.primary),
                const SizedBox(width: 8),
                Text('Ảnh hợp lệ: $validImages/5'),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.assessment, size: 20, color: AppColors.primary),
                const SizedBox(width: 8),
                Text('Chất lượng: $qualityScore%'),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.storage, size: 20, color: mongoSaved ? AppColors.success : AppColors.error),
                const SizedBox(width: 8),
                Text('MongoDB Atlas: ${mongoSaved ? "Đã lưu" : "Lỗi lưu"}'),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 20, color: AppColors.success),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Giờ bạn có thể sử dụng Face ID để điểm danh nhanh chóng và an toàn.',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.success,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop();
              widget.onUploadComplete?.call();
            },
            child: Text('Bắt đầu sử dụng', style: TextStyle(color: AppColors.primary)),
          ),
        ],
      ),
    );
  }

  void _showErrorDialogWithRetry(String message) {
    setState(() {
      _isProcessing = false;
    });

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.error, color: AppColors.error),
            const SizedBox(width: 8),
            const Text('Đăng ký thất bại'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(message),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.info.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.lightbulb_outline, size: 20, color: AppColors.info),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Gợi ý: Đảm bảo ảnh rõ nét, đủ sáng và khuôn mặt nằm trong khung hình.',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.info,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Huỷ', style: TextStyle(color: AppColors.onSurface.withValues(alpha: 0.6))),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _resetImages();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Chụp lại'),
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
}