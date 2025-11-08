import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:image/image.dart' as img;
import '../models/api_response.dart';
import '../config/api_config.dart';
import 'api_client.dart';

class FaceRecognitionResult {
  final bool success;
  final String? studentId;
  final String? studentName;
  final double? confidence;
  final String? message;
  final DateTime timestamp;

  FaceRecognitionResult({
    required this.success,
    this.studentId,
    this.studentName,
    this.confidence,
    this.message,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  factory FaceRecognitionResult.fromJson(Map<String, dynamic> json) {
    return FaceRecognitionResult(
      success: json['success'] ?? false,
      studentId: json['student_id'],
      studentName: json['student_name'],
      confidence: json['confidence']?.toDouble(),
      message: json['message'],
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'])
          : DateTime.now(),
    );
  }
}

class FaceService {
  static final FaceService _instance = FaceService._internal();
  factory FaceService() => _instance;
  FaceService._internal();

  final ApiClient _apiClient = ApiClient();

  // Initialize service
  void initialize() {
    _apiClient.initialize();
  }

  // Enroll face for a user
  Future<ApiResponse<Map<String, dynamic>>> enrollFace({
    required String userId,
    required File imageFile,
    ProgressCallback? onProgress,
  }) async {
    try {
      // Validate and process image
      final processedImage = await _processImage(imageFile);
      if (processedImage == null) {
        return ApiResponse.error('Invalid image file');
      }

      final fileName = processedImage.path.split('/').last;
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(processedImage.path, filename: fileName),
        'user_id': userId,
      });

      final response = await _apiClient.post<Map<String, dynamic>>(
        '${ApiConfig.attendanceEndpoint}/enroll-face',
        data: formData,
      );

      debugPrint('Face enrollment ${response.success ? "successful" : "failed"} for user: $userId');
      return response;
    } catch (e) {
      debugPrint('Face enrollment error: $e');
      return ApiResponse.error(e.toString());
    }
  }

  // Recognize face for attendance
  Future<ApiResponse<FaceRecognitionResult>> recognizeFace({
    required String classId,
    required File imageFile,
    ProgressCallback? onProgress,
  }) async {
    try {
      // Validate and process image
      final processedImage = await _processImage(imageFile);
      if (processedImage == null) {
        return ApiResponse.error('Invalid image file');
      }

      // Convert image to base64
      final imageBytes = await processedImage.readAsBytes();
      final base64Image = base64Encode(imageBytes);
      final imageData = 'data:image/jpeg;base64,$base64Image';

      final response = await _apiClient.post<FaceRecognitionResult>(
        ApiConfig.recognizeFaceEndpoint,
        data: {
          'image_data': imageData,
          'class_id': classId,
        },
        fromJson: (data) => FaceRecognitionResult.fromJson(data),
      );

      if (response.success && response.data != null) {
        final result = response.data!;
        debugPrint('Face recognition: ${result.success ? "SUCCESS" : "FAILED"}');
        if (result.success && result.studentName != null) {
          debugPrint('Recognized: ${result.studentName} (Confidence: ${result.confidence})');
        }
      }

      return response;
    } catch (e) {
      debugPrint('Face recognition error: $e');
      return ApiResponse.error(e.toString());
    }
  }

  // Get face enrollment status
  Future<ApiResponse<Map<String, dynamic>>> getFaceEnrollmentStatus(String userId) async {
    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        '${ApiConfig.usersEndpoint}/$userId/face-status',
      );

      return response;
    } catch (e) {
      debugPrint('Get face enrollment status error: $e');
      return ApiResponse.error(e.toString());
    }
  }

  // Delete face enrollment
  Future<ApiResponse<String>> deleteFaceEnrollment(String userId) async {
    try {
      final response = await _apiClient.delete<String>(
        '${ApiConfig.usersEndpoint}/$userId/face-enrollment',
      );

      debugPrint('Face enrollment deleted for user: $userId');
      return response;
    } catch (e) {
      debugPrint('Delete face enrollment error: $e');
      return ApiResponse.error(e.toString());
    }
  }

  // Update face enrollment
  Future<ApiResponse<Map<String, dynamic>>> updateFaceEnrollment({
    required String userId,
    required File imageFile,
    ProgressCallback? onProgress,
  }) async {
    try {
      // Validate and process image
      final processedImage = await _processImage(imageFile);
      if (processedImage == null) {
        return ApiResponse.error('Invalid image file');
      }

      final fileName = processedImage.path.split('/').last;
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(processedImage.path, filename: fileName),
        'user_id': userId,
      });

      final response = await _apiClient.put<Map<String, dynamic>>(
        '${ApiConfig.usersEndpoint}/$userId/face-enrollment',
        data: formData,
      );

      debugPrint('Face enrollment updated for user: $userId');
      return response;
    } catch (e) {
      debugPrint('Update face enrollment error: $e');
      return ApiResponse.error(e.toString());
    }
  }

  // Process and validate image
  Future<File?> _processImage(File imageFile) async {
    try {
      // Validate file size
      final fileSize = await imageFile.length();
      if (fileSize > ApiConstants.maxFileSize) {
        debugPrint('Image file too large: $fileSize bytes');
        return null;
      }

      // Validate file type
      final bytes = await imageFile.readAsBytes();
      final mimeType = _detectImageMimeType(bytes);
      if (!ApiConstants.allowedImageTypes.contains(mimeType)) {
        debugPrint('Unsupported image type: $mimeType');
        return null;
      }

      // Process image to optimize for face recognition
      final processedImage = await _optimizeImageForFaceRecognition(imageFile);
      return processedImage;
    } catch (e) {
      debugPrint('Image processing error: $e');
      return null;
    }
  }

  // Detect MIME type from file bytes
  String _detectImageMimeType(Uint8List bytes) {
    if (bytes.length < 4) return 'application/octet-stream';

    final signature = bytes.take(4).toList();

    // JPEG signature
    if (signature[0] == 0xFF && signature[1] == 0xD8 && signature[2] == 0xFF) {
      return 'image/jpeg';
    }

    // PNG signature
    if (signature[0] == 0x89 && signature[1] == 0x50 && signature[2] == 0x4E && signature[3] == 0x47) {
      return 'image/png';
    }

    // WebP signature
    if (signature[0] == 0x52 && signature[1] == 0x49 && signature[2] == 0x46 && signature[3] == 0x46) {
      return 'image/webp';
    }

    return 'application/octet-stream';
  }

  // Optimize image for face recognition
  Future<File> _optimizeImageForFaceRecognition(File imageFile) async {
    try {
      final bytes = await imageFile.readAsBytes();
      final image = img.decodeImage(bytes)!;

      // Resize if too large (keeping aspect ratio)
      if (image.width > ApiConstants.maxImageDimension || image.height > ApiConstants.maxImageDimension) {
        final thumbnail = img.copyResize(
          image,
          width: ApiConstants.maxImageDimension,
          height: ApiConstants.maxImageDimension,
          maintainAspect: true,
        );

        // Save optimized image
        final optimizedBytes = img.encodeJpg(thumbnail, quality: 85);
        final optimizedFile = File('${imageFile.path}_optimized.jpg');
        await optimizedFile.writeAsBytes(optimizedBytes);
        return optimizedFile;
      }

      return imageFile;
    } catch (e) {
      debugPrint('Image optimization error: $e');
      return imageFile;
    }
  }

  // Get face recognition settings
  Future<ApiResponse<Map<String, dynamic>>> getFaceRecognitionSettings() async {
    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        '${ApiConfig.adminEndpoint}/face-recognition-settings',
      );

      return response;
    } catch (e) {
      debugPrint('Get face recognition settings error: $e');
      return ApiResponse.error(e.toString());
    }
  }

  // Test face recognition with sample image
  Future<ApiResponse<Map<String, dynamic>>> testFaceRecognition(File imageFile) async {
    try {
      final processedImage = await _processImage(imageFile);
      if (processedImage == null) {
        return ApiResponse.error('Invalid image file');
      }

      final response = await _apiClient.upload<Map<String, dynamic>>(
        '${ApiConfig.adminEndpoint}/test-face-recognition',
        file: processedImage,
      );

      return response;
    } catch (e) {
      debugPrint('Test face recognition error: $e');
      return ApiResponse.error(e.toString());
    }
  }
}

// Type alias for progress callback
typedef ProgressCallback = void Function(double progress);