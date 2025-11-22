import 'dart:io';
import 'package:flutter/foundation.dart';
import '../models/api_response.dart';
import '../models/class_models.dart';
import 'face_recognition_service.dart';
// import 'test_data_service.dart'; // Using real API now

class AttendanceFaceService {
  static final AttendanceFaceService _instance = AttendanceFaceService._internal();
  factory AttendanceFaceService() => _instance;
  AttendanceFaceService._internal();

  final FaceRecognitionService _faceRecognitionService = FaceRecognitionService();

  // Mark attendance using face recognition
  Future<ApiResponse<AttendanceRecord>> markAttendanceWithFace(
    String sessionId,
    File faceImage, {
    String? classId,
    String? className,
  }) async {
    try {
      // Process attendance with face recognition
      final attendanceRecord = await _faceRecognitionService.processAttendanceWithFace(
        faceImage,
        sessionId,
        classId: classId,
        className: className,
      );

      if (attendanceRecord != null) {
        return ApiResponse.success(attendanceRecord);
      } else {
        return ApiResponse.error('Face recognition failed - no attendance record created');
      }
    } catch (e) {
      debugPrint('Face recognition attendance failed: $e');
      return ApiResponse.error(e.toString());
    }
  }

  // Create a test attendance session
  AttendanceSession createTestSession(String classId) {
    return AttendanceSession(
      id: 'session_${DateTime.now().millisecondsSinceEpoch}',
      classId: classId,
      className: 'Test Class',
      instructorId: 'test_instructor',
      startTime: DateTime.now(),
      status: 'active',
      checkedInStudents: [],
      createdAt: DateTime.now(),
    );
  }

  // Get test classes for demonstration
  List<Class> getTestClasses() {
    return [
      Class(
        id: 'class_001',
        name: 'Lập trình Flutter Nâng cao',
        code: 'FLUTTER001',
        description: 'Khóa học phát triển ứng dụng di động với Flutter',
        instructorId: 'GV001',
        instructorName: 'Nguyễn Văn A',
        enrolledStudents: ['SV001', 'SV002', 'SV003'],
        maxStudents: 30,
        isActive: true,
        startDate: DateTime.now().subtract(const Duration(days: 30)),
        endDate: DateTime.now().add(const Duration(days: 60)),
        createdAt: DateTime.now().subtract(const Duration(days: 35)),
        updatedAt: DateTime.now(),
      ),
    ];
  }

  // Get students in a class for testing
  List<Map<String, dynamic>> getStudentsInClass(String classId) {
    return [
      {'id': 'SV001', 'name': 'Nguyễn Văn B', 'email': 'sv001@university.edu.vn'},
      {'id': 'SV002', 'name': 'Trần Thị C', 'email': 'sv002@university.edu.vn'},
      {'id': 'SV003', 'name': 'Lê Văn D', 'email': 'sv003@university.edu.vn'},
    ];
  }

  // Get test attendance records for a session
  List<AttendanceRecord> getTestAttendanceRecords(
    String sessionId,
    String classId, {
    int count = 5,
  }) {
    final students = getStudentsInClass(classId);
    final testClasses = getTestClasses();
    final className = testClasses.firstWhere((c) => c.id == classId,
        orElse: () => testClasses.first).name;

    final records = <AttendanceRecord>[];
    for (int i = 0; i < count && i < students.length; i++) {
      final record = AttendanceRecord(
        id: 'record_${DateTime.now().millisecondsSinceEpoch}_$i',
        studentId: students[i]['id'],
        studentName: students[i]['name'],
        classId: classId,
        className: className,
        sessionId: sessionId,
        checkInTime: DateTime.now().subtract(Duration(minutes: i * 5)),
        status: i % 4 == 0 ? 'late' : 'on_time',
        method: 'face',
        confidence: 0.85 + (i * 0.02),
      );
      records.add(record);
    }

    return records;
  }

  // Get attendance statistics
  Map<String, dynamic> getAttendanceStats(String classId) {
    final testClasses = getTestClasses();
    final classInfo = testClasses.firstWhere((c) => c.id == classId,
        orElse: () => testClasses.first);

    return {
      'total_enrolled': classInfo.enrolledStudents.length,
      'max_capacity': classInfo.maxStudents,
      'attendance_rate': 0.85, // Mock 85% attendance rate
      'last_session_date': DateTime.now().toIso8601String(),
      'average_confidence': 0.92, // Mock confidence score
    };
  }

  // Simulate real-time face scanning
  Future<Map<String, dynamic>> simulateFaceScanning() async {
    // Simulate scanning delay
    await Future.delayed(const Duration(milliseconds: 1500));

    final result = {
      'success': true,
      'student_id': 'SV001',
      'student_name': 'Nguyễn Văn B',
      'confidence': 0.92,
      'message': 'Face recognized successfully'
    };

    if (result['success'] == true) {
      return {
        'success': true,
        'student': {
          'id': result['student_id'],
          'name': result['student_name'],
          'confidence': result['confidence'],
        },
        'message': 'Face recognized successfully',
      };
    } else {
      return {
        'success': false,
        'message': result['message'] ?? 'Face recognition failed',
      };
    }
  }

  // Validate session before scanning
  bool validateSession(AttendanceSession session) {
    final now = DateTime.now();

    // Check if session is active and not expired (e.g., 2 hours)
    final sessionAge = now.difference(session.startTime);
    if (sessionAge.inHours > 2) {
      return false;
    }

    return session.isActive;
  }

  // Get session status
  String getSessionStatus(AttendanceSession session) {
    final now = DateTime.now();
    final sessionAge = now.difference(session.startTime);

    if (!session.isActive) {
      return 'Đã kết thúc';
    } else if (sessionAge.inMinutes < 15) {
      return 'Vừa bắt đầu';
    } else if (sessionAge.inMinutes < 60) {
      return 'Đang diễn ra';
    } else if (sessionAge.inMinutes < 120) {
      return 'Sắp kết thúc';
    } else {
      return 'Quá thời gian';
    }
  }

  // Export attendance data
  Future<Map<String, dynamic>> exportAttendanceData(
    String classId, {
    DateTime? startDate,
    DateTime? endDate,
    String format = 'json',
  }) async {
    try {
      // Simulate export delay
      await Future.delayed(const Duration(seconds: 1));

      final className = getTestClasses().first.name;
      final records = getTestAttendanceRecords(
        'session_export_${DateTime.now().millisecondsSinceEpoch}',
        classId,
        count: 10,
      );

      return {
        'success': true,
        'format': format,
        'class_name': className,
        'export_date': DateTime.now().toIso8601String(),
        'record_count': records.length,
        'data': format == 'json'
            ? records.map((r) => r.toJson()).toList()
            : _convertToCsv(records),
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Export failed: $e',
      };
    }
  }

  // Convert records to CSV format
  String _convertToCsv(List<AttendanceRecord> records) {
    if (records.isEmpty) return '';

    final headers = [
      'Student ID', 'Student Name', 'Class', 'Check-in Time',
      'Status', 'Method', 'Confidence'
    ].join(',');

    final rows = records.map((record) {
      return [
        record.studentId,
        record.studentName,
        record.className,
        record.checkInTime.toIso8601String(),
        record.status,
        record.method,
        record.confidence?.toStringAsFixed(3) ?? '',
      ].join(',');
    }).join('\n');

    return '$headers\n$rows';
  }

  // Get face recognition quality metrics
  Map<String, dynamic> getFaceQualityMetrics() {
    return {
      'recognition_accuracy': 0.94,
      'false_positive_rate': 0.02,
      'false_negative_rate': 0.04,
      'average_processing_time_ms': 250,
      'supported_lighting_conditions': ['indoor', 'outdoor', 'mixed'],
      'supported_angles': ['frontal', 'slight_left', 'slight_right'],
      'min_face_size_pixels': 64,
      'max_face_size_pixels': 512,
      'model_version': '2.1.0',
    };
  }

  // Test face recognition with sample data
  Future<List<Map<String, dynamic>>> testFaceRecognition() async {
    final students = getStudentsInClass('class_001');
    final results = <Map<String, dynamic>>[];

    for (int i = 0; i < 5 && i < students.length; i++) {
      await Future.delayed(const Duration(milliseconds: 300));

      final success = (i % 5) != 0; // 80% success rate
      results.add({
        'student_id': students[i]['id'],
        'student_name': students[i]['name'],
        'success': success,
        'confidence': success ? 0.85 + (0.1 * (1 - i / 5)) : 0.0,
        'processing_time_ms': 200 + (i * 50),
        'timestamp': DateTime.now().subtract(Duration(seconds: i * 5)).toIso8601String(),
      });
    }

    return results;
  }
}