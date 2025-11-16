import 'dart:io';
import 'package:flutter/foundation.dart';
import '../models/api_response.dart';
import '../models/class_models.dart';
import 'api_service.dart';

// Rect helper class
class FaceRect {
  final double left;
  final double top;
  final double width;
  final double height;

  FaceRect(this.left, this.top, this.width, this.height);

  double get right => left + width;
  double get bottom => top + height;
}

// Face information
class Face {
  final int id;
  final FaceRect boundingBox;
  final Map<String, dynamic>? landmarks;
  final double confidence;
  final Map<String, dynamic>? metadata;

  Face({
    required this.id,
    required this.boundingBox,
    this.landmarks,
    required this.confidence,
    this.metadata,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'boundingBox': {
        'left': boundingBox.left,
        'top': boundingBox.top,
        'width': boundingBox.width,
        'height': boundingBox.height,
      },
      'landmarks': landmarks,
      'confidence': confidence,
      'metadata': metadata,
    };
  }
}

// Face detection result
class FaceDetectionResult {
  final bool success;
  final List<Face> faces;
  final String? errorMessage;
  final Map<String, dynamic>? metadata;

  FaceDetectionResult({
    required this.success,
    required this.faces,
    this.errorMessage,
    this.metadata,
  });
}

// Face recognition result
class FaceRecognitionResult {
  final bool success;
  final String? studentId;
  final String? studentName;
  final double? confidence;
  final String? errorMessage;
  final Map<String, dynamic>? metadata;

  FaceRecognitionResult({
    required this.success,
    this.studentId,
    this.studentName,
    this.confidence,
    this.errorMessage,
    this.metadata,
  });
}

class FaceRecognitionService {
  static final FaceRecognitionService _instance = FaceRecognitionService._internal();
  factory FaceRecognitionService() => _instance;
  FaceRecognitionService._internal();

  
  // Detect faces in image
  Future<FaceDetectionResult> detectFaces(File imageFile) async {
    try {
      if (!await imageFile.exists()) {
        return FaceDetectionResult(
          success: false,
          faces: [],
          errorMessage: 'Image file does not exist',
        );
      }

      // For now, return a simple face detection result
      // In production, this would use a real face detection API
      await Future.delayed(const Duration(milliseconds: 500));

      // Return a simple success result for face detection
      return FaceDetectionResult(
        success: true,
        faces: [
          Face(
            id: 1,
            boundingBox: FaceRect(100, 100, 200, 250),
            confidence: 0.9,
            landmarks: {
              'left_eye': [150.0, 150.0],
              'right_eye': [250.0, 150.0],
              'nose': [200.0, 200.0],
              'mouth': [200.0, 250.0],
            },
          )
        ],
        metadata: {
          'processing_time': '500ms',
          'image_quality': 'good',
        },
      );
    } catch (e) {
      debugPrint('Face detection error: $e');
      return FaceDetectionResult(
        success: false,
        faces: [],
        errorMessage: 'Error: $e',
      );
    }
  }

  // Recognize face and return student information
  Future<FaceRecognitionResult> recognizeFace(
    File imageFile, {
    String? sessionId,
    String? classId,
  }) async {
    try {
      if (!await imageFile.exists()) {
        return FaceRecognitionResult(
          success: false,
          errorMessage: 'Image file does not exist',
        );
      }

      // Use real API for face recognition
      final result = await ApiService.uploadImageForFaceRecognition(
        imagePath: imageFile.path,
        classId: classId ?? '',
        userId: 'face_recognition_scan', // Temporary user ID for scanning
        confidenceThreshold: 0.85,
      );

      if (result != null && result.contains('successful')) {
        // Parse the successful response
        return FaceRecognitionResult(
          success: true,
          studentId: 'recognized_student',
          studentName: 'Recognized Student',
          confidence: 0.9, // Default confidence when API says successful
          metadata: {
            'threshold': 0.85,
            'recognition_method': 'face_id',
            'class_id': classId,
            'timestamp': DateTime.now().toIso8601String(),
            'api_response': result,
          },
        );
      } else {
        // Face recognition failed - return failure with API message
        return FaceRecognitionResult(
          success: false,
          errorMessage: result ?? 'Face recognition failed',
          metadata: {
            'threshold': 0.85,
            'recognition_method': 'face_id',
            'class_id': classId,
            'timestamp': DateTime.now().toIso8601String(),
            'api_response': result,
          },
        );
      }
    } catch (e) {
      debugPrint('Face recognition error: $e');
      return FaceRecognitionResult(
        success: false,
        errorMessage: 'Error: $e',
      );
    }
  }

  // Register face for a student
  Future<ApiResponse<Map<String, dynamic>>> registerFace(
    File imageFile,
    String studentId, {
    String? classId,
    String? fullName,
    String? email,
  }) async {
    try {
      if (!await imageFile.exists()) {
        return ApiResponse.error('Image file does not exist');
      }

      // Use real API for face registration
      final result = await ApiService.registerFaceForUser(
        imagePath: imageFile.path,
        userId: studentId,
        classId: classId ?? '',
        fullName: fullName ?? 'Student',
        email: email,
        confidenceThreshold: 0.85,
      );

      if (result != null && result['success'] == true) {
        return ApiResponse.success(result);
      } else {
        final message = result?['message'] ?? 'Face registration failed';
        return ApiResponse.error(message);
      }
    } catch (e) {
      debugPrint('Face registration error: $e');
      return ApiResponse.error('Error: $e');
    }
  }

  // Register multiple face images for a student (for 5-image registration process)
  Future<ApiResponse<Map<String, dynamic>>> registerMultipleFaces(
    List<File> imageFiles,
    String studentId, {
    String? classId,
    String? fullName,
    String? email,
    double confidenceThreshold = 0.85,
  }) async {
    try {
      if (imageFiles.isEmpty) {
        return ApiResponse.error('No images provided');
      }

      // Validate all images exist
      for (var file in imageFiles) {
        if (!await file.exists()) {
          return ApiResponse.error('Image file does not exist: ${file.path}');
        }
      }

      // Convert File objects to String paths
      final List<String> imagePaths = imageFiles.map((file) => file.path).toList();

      // Use real API for multiple face registration
      final result = await ApiService.uploadMultipleFaceImages(
        imagePaths: imagePaths,
        userId: studentId,
        classId: classId ?? '',
        fullName: fullName ?? 'Student',
        email: email,
        confidenceThreshold: confidenceThreshold,
      );

      if (result != null && result['success'] == true) {
        return ApiResponse.success(result);
      } else {
        final message = result?['message'] ?? 'Multiple face registration failed';
        return ApiResponse.error(message);
      }
    } catch (e) {
      debugPrint('Batch face registration error: $e');
      return ApiResponse.error('Lỗi đăng ký khuôn mặt: $e');
    }
  }

  // Validate face image quality
  Future<bool> validateFaceImage(File imageFile) async {
    try {
      // Basic validation checks
      if (!await imageFile.exists()) return false;

      final fileSize = await imageFile.length();
      if (fileSize < 10 * 1024) { // Less than 10KB
        return false;
      }
      if (fileSize > 5 * 1024 * 1024) { // More than 5MB
        return false;
      }

      // For testing, simulate face detection validation
      if (kDebugMode) {
        final detectionResult = await detectFaces(imageFile);
        return detectionResult.success && detectionResult.faces.isNotEmpty;
      }

      return true;
    } catch (e) {
      debugPrint('Face image validation error: $e');
      return false;
    }
  }

  // Simulate face detection for testing
  
  // Get face recognition statistics
  Future<Map<String, dynamic>> getRecognitionStats() async {
    try {
      // For testing, return mock statistics
      return {
        'total_faces_registered': 150,
        'recognition_accuracy': 0.94,
        'avg_recognition_time_ms': 250,
        'model_version': '2.1.0',
        'last_updated': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      debugPrint('Error getting recognition stats: $e');
      return {};
    }
  }

  // Process attendance with face recognition
  Future<AttendanceRecord?> processAttendanceWithFace(
    File imageFile,
    String sessionId, {
    String? classId,
    String? className,
  }) async {
    try {
      // First, detect faces
      final detectionResult = await detectFaces(imageFile);
      if (!detectionResult.success || detectionResult.faces.isEmpty) {
        throw Exception('No face detected in image');
      }

      // Then, recognize the face
      final recognitionResult = await recognizeFace(
        imageFile,
        sessionId: sessionId,
        classId: classId,
      );

      if (!recognitionResult.success) {
        throw Exception(recognitionResult.errorMessage ?? 'Face recognition failed');
      }

      // Create attendance record
      final timestamp = DateTime.now();
      final status = _determineAttendanceStatus(timestamp, classId);

      return AttendanceRecord(
        id: 'record_${timestamp.millisecondsSinceEpoch}',
        studentId: recognitionResult.studentId!,
        studentName: recognitionResult.studentName!,
        classId: classId ?? '',
        className: className ?? '',
        sessionId: sessionId,
        checkInTime: timestamp,
        status: status,
        method: 'face',
        confidence: recognitionResult.confidence,
        metadata: {
          'detection_confidence': detectionResult.faces.first.confidence,
          'recognition_confidence': recognitionResult.confidence,
          'face_count': detectionResult.faces.length,
          'processing_time': recognitionResult.metadata?['recognition_time'],
        },
      );
    } catch (e) {
      debugPrint('Error processing attendance with face: $e');
      return null;
    }
  }

  // Determine attendance status based on check-in time
  String _determineAttendanceStatus(DateTime checkInTime, String? classId) {
    // Simple logic - in real app, this would check class schedule
    final now = DateTime.now();
    final lateThreshold = DateTime(now.year, now.month, now.day, 7, 15, 0); // 7:15 AM

    if (checkInTime.isBefore(lateThreshold)) {
      return 'on_time';
    } else if (checkInTime.isBefore(DateTime(now.year, now.month, now.day, 9, 0, 0))) {
      return 'late';
    } else {
      return 'absent';
    }
  }
}