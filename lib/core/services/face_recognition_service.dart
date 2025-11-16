import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import '../models/api_response.dart';
import '../models/class_models.dart';
import 'test_data_service.dart';

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

      // For testing, simulate face detection
      if (kDebugMode) {
        await Future.delayed(const Duration(milliseconds: 500));
        final testResult = _simulateFaceDetection();
        return testResult;
      }

      // Real API call would go here for production
      // For now, simulate the response
      final testResult = _simulateFaceDetection();
      return testResult;
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

      // For testing, always use simulation
      await Future.delayed(const Duration(milliseconds: 800));
      final testResult = _simulateFaceRecognition(classId);
      return testResult;
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
  }) async {
    try {
      if (!await imageFile.exists()) {
        return ApiResponse.error('Image file does not exist');
      }

      // For testing, always simulate face registration
      await Future.delayed(const Duration(seconds: 1));
      return ApiResponse.success({
        'success': true,
        'message': 'Face registered successfully',
        'student_id': studentId,
        'face_id': 'face_${DateTime.now().millisecondsSinceEpoch}',
        'threshold': 0.85,
        'processing_time_ms': 450,
      });
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

      // For testing, simulate batch face registration
      await Future.delayed(const Duration(seconds: 2));

      // Simulate face quality validation for all images
      final validImages = <String>[];
      final failedImages = <String>[];

      for (int i = 0; i < imageFiles.length; i++) {
        final validation = await validateFaceImage(imageFiles[i]);
        if (validation) {
          validImages.add('face_${studentId}_${i + 1}');
        } else {
          failedImages.add('image_${i + 1}');
        }
      }

      if (validImages.isEmpty) {
        return ApiResponse.error('No valid face images found. Please ensure all images clearly show your face.');
      }

      // Calculate overall quality score
      final qualityScore = validImages.length / imageFiles.length;
      final registrationSuccess = qualityScore >= 0.8; // At least 80% of images must be valid

      return ApiResponse.success({
        'success': registrationSuccess,
        'message': registrationSuccess
            ? 'Đăng ký khuôn mặt thành công! Đã lưu ${validImages.length}/5 ảnh lên hệ thống.'
            : 'Đăng ký khuôn mặt chưa thành công. Chỉ ${validImages.length}/5 ảnh đạt chất lượng. Vui lòng chụp lại.',
        'student_id': studentId,
        'class_id': classId,
        'valid_images': validImages,
        'failed_images': failedImages,
        'total_uploaded': imageFiles.length,
        'quality_score': qualityScore,
        'threshold_met': qualityScore >= 0.8,
        'face_ids': validImages,
        'processing_time_ms': 1200,
        'mongodb_saved': registrationSuccess, // Indicates if saved to MongoDB Atlas
        'registration_confidence': qualityScore,
      });
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
  FaceDetectionResult _simulateFaceDetection() {
    final random = Random();
    final success = random.nextDouble() > 0.1; // 90% success rate

    if (success) {
      // Generate random face bounding box
      final faces = [
        Face(
          id: 1,
          boundingBox: FaceRect(
            50 + random.nextDouble() * 100,
            50 + random.nextDouble() * 100,
            100 + random.nextDouble() * 50,
            120 + random.nextDouble() * 50,
          ),
          confidence: 0.8 + random.nextDouble() * 0.19,
          landmarks: {
            'left_eye': [150.0, 120.0],
            'right_eye': [180.0, 120.0],
            'nose': [165.0, 140.0],
            'mouth': [165.0, 160.0],
          },
        )
      ];

      return FaceDetectionResult(
        success: true,
        faces: faces,
        metadata: {
          'processing_time': '${(random.nextDouble() * 500).toStringAsFixed(0)}ms',
          'image_quality': 'high',
        },
      );
    } else {
      return FaceDetectionResult(
        success: false,
        faces: [],
        errorMessage: random.nextBool()
            ? 'No face detected in image'
            : 'Face too small or blurry',
      );
    }
  }

  // Simulate face recognition for testing with 85% threshold
  FaceRecognitionResult _simulateFaceRecognition(String? classId) {
    final random = Random();

    // Get students for this class
    List<Map<String, dynamic>> students = [];
    if (classId != null) {
      students = TestDataService.getStudentsInClass(classId);
    }
    if (students.isEmpty) {
      students = TestDataService.getTestStudents();
    }

    if (students.isNotEmpty) {
      final student = students[random.nextInt(students.length)];

      // Simulate face recognition with confidence scoring
      final baseConfidence = 0.75 + random.nextDouble() * 0.24; // 75-99% base confidence
      final threshold = 0.85; // 85% threshold for successful recognition

      // Add some variance to simulate real-world conditions
      final finalConfidence = baseConfidence;
      final success = finalConfidence >= threshold;

      if (success) {
        return FaceRecognitionResult(
          success: true,
          studentId: student['id'],
          studentName: student['name'],
          confidence: finalConfidence,
          metadata: {
            'threshold': threshold,
            'recognition_method': 'face_id',
            'class_id': classId,
            'timestamp': DateTime.now().toIso8601String(),
            'recognition_time': '${(random.nextDouble() * 300).toStringAsFixed(0)}ms',
            'model_version': '2.1.0',
            'quality_score': finalConfidence,
          },
        );
      } else {
        return FaceRecognitionResult(
          success: false,
          errorMessage: 'Nhận diện thất bại: Độ chính xác ${(finalConfidence * 100).toStringAsFixed(1)}% < ngưỡng ${(threshold * 100).toStringAsFixed(0)}%',
          confidence: finalConfidence,
          metadata: {
            'threshold': threshold,
            'recognition_method': 'face_id',
            'class_id': classId,
            'timestamp': DateTime.now().toIso8601String(),
            'recognition_time': '${(random.nextDouble() * 300).toStringAsFixed(0)}ms',
            'reason': 'confidence_below_threshold',
            'quality_score': finalConfidence,
          },
        );
      }
    }

    return FaceRecognitionResult(
      success: false,
      errorMessage: 'Không tìm thấy dữ liệu sinh viên cho lớp học này',
      metadata: {
        'threshold': 0.85,
        'class_id': classId,
        'reason': 'no_students_found',
      },
    );
  }

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