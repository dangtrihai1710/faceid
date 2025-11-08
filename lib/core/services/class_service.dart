import 'package:flutter/foundation.dart';
import '../models/api_response.dart';
import '../models/class_models.dart';
import '../config/api_config.dart';
import 'api_client.dart';

class ClassService {
  static final ClassService _instance = ClassService._internal();
  factory ClassService() => _instance;
  ClassService._internal();

  final ApiClient _apiClient = ApiClient();

  // Get all classes for current user
  Future<ApiResponse<List<Class>>> getClasses() async {
    try {
      final response = await _apiClient.get<List<Class>>(
        ApiConfig.classesEndpoint,
        fromJson: (data) {
          if (data is List) {
            return data.map((item) => Class.fromJson(item)).toList();
          }
          return <Class>[];
        },
      );

      return response;
    } catch (e) {
      debugPrint('Get classes failed: $e');
      return ApiResponse.error(e.toString());
    }
  }

  // Get class by ID
  Future<ApiResponse<Class>> getClassById(String classId) async {
    try {
      final response = await _apiClient.get<Class>(
        '${ApiConfig.classesEndpoint}/$classId',
        fromJson: (data) => Class.fromJson(data),
      );

      return response;
    } catch (e) {
      debugPrint('Get class by ID failed: $e');
      return ApiResponse.error(e.toString());
    }
  }

  // Create new class (for instructors/admins)
  Future<ApiResponse<Class>> createClass(CreateClassRequest request) async {
    try {
      final response = await _apiClient.post<Class>(
        ApiConfig.classesEndpoint,
        data: request.toJson(),
        fromJson: (data) => Class.fromJson(data),
      );

      return response;
    } catch (e) {
      debugPrint('Create class failed: $e');
      return ApiResponse.error(e.toString());
    }
  }

  // Update class information (for instructors/admins)
  Future<ApiResponse<Class>> updateClass(String classId, Class updatedClass) async {
    try {
      final response = await _apiClient.put<Class>(
        '${ApiConfig.classesEndpoint}/$classId',
        data: updatedClass.toJson(),
        fromJson: (data) => Class.fromJson(data),
      );

      return response;
    } catch (e) {
      debugPrint('Update class failed: $e');
      return ApiResponse.error(e.toString());
    }
  }

  // Delete class (for instructors/admins)
  Future<ApiResponse<String>> deleteClass(String classId) async {
    try {
      final response = await _apiClient.delete<String>(
        '${ApiConfig.classesEndpoint}/$classId',
      );

      return response;
    } catch (e) {
      debugPrint('Delete class failed: $e');
      return ApiResponse.error(e.toString());
    }
  }

  // Enroll students in class (for instructors/admins)
  Future<ApiResponse<String>> enrollStudents(String classId, List<String> studentIds) async {
    try {
      final request = EnrollStudentsRequest(studentIds: studentIds);

      final response = await _apiClient.post<String>(
        '${ApiConfig.classesEndpoint}/$classId/enroll',
        data: request.toJson(),
      );

      return response;
    } catch (e) {
      debugPrint('Enroll students failed: $e');
      return ApiResponse.error(e.toString());
    }
  }

  // Remove students from class (for instructors/admins)
  Future<ApiResponse<String>> removeStudents(String classId, List<String> studentIds) async {
    try {
      final request = EnrollStudentsRequest(studentIds: studentIds);

      final response = await _apiClient.post<String>(
        '${ApiConfig.classesEndpoint}/$classId/remove',
        data: request.toJson(),
      );

      return response;
    } catch (e) {
      debugPrint('Remove students failed: $e');
      return ApiResponse.error(e.toString());
    }
  }

  // Get attendance sessions for a class
  Future<ApiResponse<List<AttendanceSession>>> getAttendanceSessions(String classId) async {
    try {
      final response = await _apiClient.get<List<AttendanceSession>>(
        '${ApiConfig.classesEndpoint}/$classId/sessions',
        fromJson: (data) {
          if (data is List) {
            return data.map((item) => AttendanceSession.fromJson(item)).toList();
          }
          return <AttendanceSession>[];
        },
      );

      return response;
    } catch (e) {
      debugPrint('Get attendance sessions failed: $e');
      return ApiResponse.error(e.toString());
    }
  }

  // Start attendance session (for instructors)
  Future<ApiResponse<AttendanceSession>> startAttendanceSession(String classId) async {
    try {
      final response = await _apiClient.post<AttendanceSession>(
        '${ApiConfig.classesEndpoint}/$classId/start-session',
        fromJson: (data) => AttendanceSession.fromJson(data),
      );

      return response;
    } catch (e) {
      debugPrint('Start attendance session failed: $e');
      return ApiResponse.error(e.toString());
    }
  }

  // End attendance session (for instructors)
  Future<ApiResponse<String>> endAttendanceSession(String classId, String sessionId) async {
    try {
      final response = await _apiClient.post<String>(
        '${ApiConfig.classesEndpoint}/$classId/sessions/$sessionId/end',
      );

      return response;
    } catch (e) {
      debugPrint('End attendance session failed: $e');
      return ApiResponse.error(e.toString());
    }
  }
}