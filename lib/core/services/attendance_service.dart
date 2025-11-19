import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../models/api_response.dart';
import '../models/class_models.dart';
import '../config/api_config.dart';
import 'api_client.dart';

class AttendanceService {
  static final AttendanceService _instance = AttendanceService._internal();
  factory AttendanceService() => _instance;
  AttendanceService._internal();

  final ApiClient _apiClient = ApiClient();

  // Get attendance history for current user
  Future<ApiResponse<List<AttendanceRecord>>> getAttendanceHistory() async {
    try {
      final response = await _apiClient.get<List<AttendanceRecord>>(
        ApiConfig.attendanceHistoryEndpoint,
        fromJson: (data) {
          if (data is List) {
            return data.map((item) => AttendanceRecord.fromJson(item)).toList();
          }
          return <AttendanceRecord>[];
        },
      );

      return response;
    } catch (e) {
      debugPrint('Get attendance history failed: $e');
      return ApiResponse.error(e.toString());
    }
  }

  // Mark attendance using face recognition
  Future<ApiResponse<AttendanceRecord>> markAttendanceWithFace(
    String sessionId,
    File faceImage, {
    String? classId,
  }) async {
    try {
      // Convert image to base64
      final imageBytes = await faceImage.readAsBytes();
      final base64Image = base64Encode(imageBytes);
      final imageData = 'data:image/jpeg;base64,$base64Image';

      final response = await _apiClient.post<AttendanceRecord>(
        ApiConfig.recognizeFaceEndpoint,
        data: {
          'image_data': imageData,
          'session_id': sessionId,
          'class_id': classId ?? 'CLASS_FACEID_DEMO',  // Add class_id with default fallback
          'confidence_threshold': 0.85,
        },
        fromJson: (data) => AttendanceRecord.fromJson(data),
      );

      return response;
    } catch (e) {
      debugPrint('Face recognition attendance failed: $e');
      return ApiResponse.error(e.toString());
    }
  }

  // Mark attendance using QR code
  Future<ApiResponse<AttendanceRecord>> markAttendanceWithQR(
    String sessionId,
    String qrCode,
  ) async {
    try {
      final response = await _apiClient.post<AttendanceRecord>(
        ApiConfig.qrAttendanceEndpoint,
        data: {
          'session_id': sessionId,
          'qr_code': qrCode,
        },
        fromJson: (data) => AttendanceRecord.fromJson(data),
      );

      return response;
    } catch (e) {
      debugPrint('QR code attendance failed: $e');
      return ApiResponse.error(e.toString());
    }
  }

  // Mark attendance using short code
  Future<ApiResponse<AttendanceRecord>> markAttendanceWithCode(
    String sessionId,
    String shortCode,
  ) async {
    try {
      final response = await _apiClient.post<AttendanceRecord>(
        ApiConfig.codeAttendanceEndpoint,
        data: {
          'session_id': sessionId,
          'short_code': shortCode,
        },
        fromJson: (data) => AttendanceRecord.fromJson(data),
      );

      return response;
    } catch (e) {
      debugPrint('Short code attendance failed: $e');
      return ApiResponse.error(e.toString());
    }
  }

  // Get attendance records for a specific class
  Future<ApiResponse<List<AttendanceRecord>>> getClassAttendance(
    String classId, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      Map<String, dynamic> queryParams = {};
      if (startDate != null) {
        queryParams['start_date'] = startDate.toIso8601String().split('T')[0];
      }
      if (endDate != null) {
        queryParams['end_date'] = endDate.toIso8601String().split('T')[0];
      }

      final response = await _apiClient.get<List<AttendanceRecord>>(
        '${ApiConfig.attendanceEndpoint}/class/$classId',
        queryParameters: queryParams,
        fromJson: (data) {
          if (data is List) {
            return data.map((item) => AttendanceRecord.fromJson(item)).toList();
          }
          return <AttendanceRecord>[];
        },
      );

      return response;
    } catch (e) {
      debugPrint('Get class attendance failed: $e');
      return ApiResponse.error(e.toString());
    }
  }

  // Get attendance records for a specific session
  Future<ApiResponse<List<AttendanceRecord>>> getSessionAttendance(
    String sessionId,
  ) async {
    try {
      final response = await _apiClient.get<List<AttendanceRecord>>(
        '${ApiConfig.attendanceEndpoint}/session/$sessionId',
        fromJson: (data) {
          if (data is List) {
            return data.map((item) => AttendanceRecord.fromJson(item)).toList();
          }
          return <AttendanceRecord>[];
        },
      );

      return response;
    } catch (e) {
      debugPrint('Get session attendance failed: $e');
      return ApiResponse.error(e.toString());
    }
  }

  // Get attendance statistics for a student
  Future<ApiResponse<Map<String, dynamic>>> getStudentAttendanceStats(
    String studentId,
  ) async {
    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        '${ApiConfig.attendanceEndpoint}/student/$studentId/stats',
      );

      return response;
    } catch (e) {
      debugPrint('Get student attendance stats failed: $e');
      return ApiResponse.error(e.toString());
    }
  }

  // Get attendance statistics for a class
  Future<ApiResponse<Map<String, dynamic>>> getClassAttendanceStats(
    String classId,
  ) async {
    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        '${ApiConfig.attendanceEndpoint}/class/$classId/stats',
      );

      return response;
    } catch (e) {
      debugPrint('Get class attendance stats failed: $e');
      return ApiResponse.error(e.toString());
    }
  }

  // Update attendance record (for instructors/admins)
  Future<ApiResponse<AttendanceRecord>> updateAttendanceRecord(
    String recordId,
    AttendanceRecord updatedRecord,
  ) async {
    try {
      final response = await _apiClient.put<AttendanceRecord>(
        '${ApiConfig.attendanceEndpoint}/records/$recordId',
        data: updatedRecord.toJson(),
        fromJson: (data) => AttendanceRecord.fromJson(data),
      );

      return response;
    } catch (e) {
      debugPrint('Update attendance record failed: $e');
      return ApiResponse.error(e.toString());
    }
  }

  // Delete attendance record (for instructors/admins)
  Future<ApiResponse<String>> deleteAttendanceRecord(String recordId) async {
    try {
      final response = await _apiClient.delete<String>(
        '${ApiConfig.attendanceEndpoint}/records/$recordId',
      );

      return response;
    } catch (e) {
      debugPrint('Delete attendance record failed: $e');
      return ApiResponse.error(e.toString());
    }
  }

  // Export attendance records for a class
  Future<ApiResponse<String>> exportClassAttendance(
    String classId, {
    DateTime? startDate,
    DateTime? endDate,
    String format = 'csv', // 'csv', 'excel', 'pdf'
  }) async {
    try {
      Map<String, dynamic> queryParams = {
        'format': format,
      };
      if (startDate != null) {
        queryParams['start_date'] = startDate.toIso8601String().split('T')[0];
      }
      if (endDate != null) {
        queryParams['end_date'] = endDate.toIso8601String().split('T')[0];
      }

      final response = await _apiClient.get<String>(
        '${ApiConfig.attendanceEndpoint}/class/$classId/export',
        queryParameters: queryParams,
      );

      return response;
    } catch (e) {
      debugPrint('Export class attendance failed: $e');
      return ApiResponse.error(e.toString());
    }
  }

  // Get attendance summary for dashboard
  Future<ApiResponse<Map<String, dynamic>>> getAttendanceSummary() async {
    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        '${ApiConfig.attendanceEndpoint}/summary',
      );

      return response;
    } catch (e) {
      debugPrint('Get attendance summary failed: $e');
      return ApiResponse.error(e.toString());
    }
  }
}