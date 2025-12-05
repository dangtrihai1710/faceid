import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'dart:convert';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static late Dio _dio;
  static const String _baseUrl = 'http://192.168.100.142:8000'; // Updated backend URL
  static String? _authToken;
  static const String _tokenKey = 'auth_token';

  static Future<void> _initialize() async {
    // Load token from storage
    await _loadToken();

    _dio = Dio(BaseOptions(
      baseUrl: _baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (_authToken != null) 'Authorization': 'Bearer $_authToken',
      },
    ));

    // Add request interceptor for authorization
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          debugPrint('API Request: ${options.method} ${options.uri}');
          if (options.data != null) {
            debugPrint('Request Data: ${options.data}');
          }
          // Add auth token if available
          if (_authToken != null) {
            options.headers['Authorization'] = 'Bearer $_authToken';
          }
          handler.next(options);
        },
        onResponse: (response, handler) {
          debugPrint('API Response: ${response.statusCode}');
          handler.next(response);
        },
        onError: (error, handler) {
          debugPrint('API Error: ${error.message}');
          if (error.response != null) {
            debugPrint('Error Response: ${error.response?.data}');
          }
          handler.next(error);
        },
      ),
    );
  }

  // Token management methods
  static Future<void> saveToken(String token) async {
    _authToken = token;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_tokenKey, token);
      debugPrint('Token saved successfully');
    } catch (e) {
      debugPrint('Error saving token: $e');
    }
  }

  static Future<void> _loadToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _authToken = prefs.getString(_tokenKey);
      if (_authToken != null) {
        debugPrint('Token loaded successfully');
      }
    } catch (e) {
      debugPrint('Error loading token: $e');
    }
  }

  static Future<void> clearToken() async {
    _authToken = null;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_tokenKey);
      debugPrint('Token cleared successfully');
    } catch (e) {
      debugPrint('Error clearing token: $e');
    }
  }

  static bool hasToken() {
    return _authToken != null && _authToken!.isNotEmpty;
  }

  // Check if user is authenticated before making API calls
  static bool ensureAuthenticated() {
    if (!hasToken()) {
      debugPrint('Error: No authentication token available. Please login first.');
      return false;
    }
    return true;
  }

  // Login method that saves token to both systems
  static Future<Map<String, dynamic>?> simpleLogin({
    required String userId,
    required String password,
  }) async {
    await _initialize();
    try {
      final response = await _dio.post(
        '/api/v1/auth/login',
        data: {
          'user_id': userId,
          'password': password,
        },
      );

      if (response.statusCode == 200) {
        final responseData = response.data;
        if (responseData['data'] != null && responseData['data']['access_token'] != null) {
          await saveToken(responseData['data']['access_token']);
          debugPrint('Simple login successful, token saved');
        }
        return responseData;
      }
    } catch (e) {
      debugPrint('Simple login error: $e');
      return {
        'success': false,
        'message': 'Login failed: $e',
      };
    }
    return null;
  }

  static Future<String?> uploadImageForFaceRecognition({
    required String imagePath,
    required String classId,
    required String userId,
    Map<String, dynamic>? gpsData,
    String? deviceId,
    double confidenceThreshold = 0.85,
  }) async {
    if (!ensureAuthenticated()) {
      return 'Error: Please login first to use face recognition';
    }

    await _initialize();
    return _performFaceRecognitionUpload(
      imagePath: imagePath,
      classId: classId,
      userId: userId,
      gpsData: gpsData,
      deviceId: deviceId,
      confidenceThreshold: confidenceThreshold,
    );
  }

  static Future<Map<String, dynamic>?> registerFaceForUser({
    required String imagePath,
    required String userId,
    required String classId,
    required String fullName,
    String? email,
    String? phone,
    Map<String, dynamic>? gpsData,
    String? deviceId,
    double confidenceThreshold = 0.85,
  }) async {
    if (!ensureAuthenticated()) {
      return {
        'success': false,
        'message': 'Please login first to register face',
      };
    }

    await _initialize();
    try {
      // Read image file and convert to base64
      final imageFile = File(imagePath);
      final imageBytes = await imageFile.readAsBytes();
      final base64Image = base64Encode(imageBytes);

      final requestData = {
        'image_data': 'data:image/jpeg;base64,$base64Image',
        'user_id': userId,
        'class_id': classId,
        'full_name': fullName,
        'confidence_threshold': confidenceThreshold,
        if (email != null) 'email': email,
        if (phone != null) 'phone': phone,
        'gps_data': gpsData,
        'device_id': deviceId ?? 'unknown',
        'registration_type': 'face_id',
        'location_validation_required': true,
      };

      final response = await _dio.post(
        '/api/v1/attendance/register-face',
        data: requestData,
        options: Options(
          headers: {
            'Content-Type': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return response.data;
      } else {
        return {
          'success': false,
          'message': 'Server error: ${response.statusCode}',
        };
      }
    } on DioException catch (e) {
      if (e.response?.data?['detail'] != null) {
        return {
          'success': false,
          'message': e.response!.data['detail'],
        };
      }
      return {
        'success': false,
        'message': 'Network error: ${e.message}',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Unexpected error: $e',
      };
    }
  }

  static Future<Map<String, dynamic>?> uploadMultipleFaceImages({
    required List<String> imagePaths,
    required String classId,
    Map<String, dynamic>? gpsData,
    String? deviceId,
    double confidenceThreshold = 0.85,
  }) async {
    if (!ensureAuthenticated()) {
      return {
        'success': false,
        'message': 'Please login first to register face',
      };
    }

    await _initialize();
    try {
      final List<Map<String, String>> imageData = [];

      for (String imagePath in imagePaths) {
        final imageFile = File(imagePath);
        final imageBytes = await imageFile.readAsBytes();
        final base64Image = base64Encode(imageBytes);

        imageData.add({
          'image_data': 'data:image/jpeg;base64,$base64Image',
        });
      }

      final requestData = {
        'images': imageData,
        'confidence_threshold': confidenceThreshold,
        'gps_data': gpsData,
        'device_id': deviceId ?? 'unknown',
        'location_validation_required': true,
      };

      final response = await _dio.post(
        '/api/v1/attendance/register-faces-multiple',
        data: requestData,
        options: Options(
          headers: {
            'Content-Type': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return response.data;
      } else {
        return {
          'success': false,
          'message': 'Server error: ${response.statusCode}',
        };
      }
    } on DioException catch (e) {
      if (e.response?.data?['detail'] != null) {
        return {
          'success': false,
          'message': e.response!.data['detail'],
        };
      }
      return {
        'success': false,
        'message': 'Network error: ${e.message}',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Unexpected error: $e',
      };
    }
  }

  static Future<Map<String, dynamic>?> getCurrentUser() async {
    if (!ensureAuthenticated()) {
      return null;
    }

    await _initialize();
    try {
      final response = await _dio.get('/api/v1/auth/me');

      if (response.statusCode == 200) {
        return response.data;
      }
    } on DioException catch (e) {
      if (e.response?.data?['detail'] != null) {
        debugPrint('Get current user error: ${e.response!.data['detail']}');
      }
      debugPrint('Get current user network error: ${e.message}');
    } catch (e) {
      debugPrint('Get current user unexpected error: $e');
    }
    return null;
  }

  static Future<String?> _performFaceRecognitionUpload({
    required String imagePath,
    required String classId,
    required String userId,
    Map<String, dynamic>? gpsData,
    String? deviceId,
    double confidenceThreshold = 0.85,
  }) async {
    await _initialize();
    try {
      // Read image file and convert to base64
      final imageFile = File(imagePath);
      final imageBytes = await imageFile.readAsBytes();
      final base64Image = base64Encode(imageBytes);

      final requestData = {
        'image_data': 'data:image/jpeg;base64,$base64Image',
        'class_id': classId,
        'confidence_threshold': confidenceThreshold,
        'gps_data': gpsData,
        'device_id': deviceId ?? 'unknown',
        'location_validation_required': true,
      };

      // DEBUG: Log request data
      debugPrint('🔍 DEBUG: Face recognition request data: $requestData');
      debugPrint('🔍 DEBUG: class_id in request: ${requestData['class_id']}');

      final response = await _dio.post(
        '/api/v1/attendance/recognize-face',
        data: requestData,
        options: Options(
          headers: {
            'Content-Type': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200) {
        final result = response.data;
        if (result['success'] == true && result['attendance_marked'] == true) {
          return 'Face recognition successful! Attendance marked.';
        } else {
          return result['message'] ?? 'Face recognition failed';
        }
      } else {
        return 'Server error: ${response.statusCode}';
      }
    } on DioException catch (e) {
      if (e.response?.data?['detail'] != null) {
        return e.response!.data['detail'];
      }
      return 'Network error: ${e.message}';
    } catch (e) {
      return 'Unexpected error: $e';
    }
  }

  static Future<Map<String, dynamic>?> suggestUserIds({
    required String role,
    int count = 5,
  }) async {
    await _initialize();
    try {
      final response = await _dio.get(
        '/api/v1/auth/suggest-user-id',
        queryParameters: {
          'role': role,
          'count': count,
        },
      );

      if (response.statusCode == 200) {
        return response.data;
      }
    } on DioException catch (e) {
      if (e.response?.data?['detail'] != null) {
        return {
          'success': false,
          'message': e.response!.data['detail'],
        };
      }
      return {
        'success': false,
        'message': 'Network error: ${e.message}',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Unexpected error: $e',
      };
    }
    return null;
  }

  static Future<Map<String, dynamic>?> checkUserIdAvailability({
    required String userId,
  }) async {
    await _initialize();
    try {
      final response = await _dio.post(
        '/api/v1/auth/check-user-id',
        data: {'user_id': userId},
      );

      if (response.statusCode == 200) {
        return response.data;
      }
    } on DioException catch (e) {
      if (e.response?.data?['detail'] != null) {
        return {
          'success': false,
          'message': e.response!.data['detail'],
        };
      }
      return {
        'success': false,
        'message': 'Network error: ${e.message}',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Unexpected error: $e',
      };
    }
    return null;
  }

  static Future<Map<String, dynamic>?> autoRegister({
    required String email,
    required String fullName,
    required String password,
    required String role,
    String? phone,
  }) async {
    await _initialize();
    try {
      // Auto generate user_id
      final timestamp = DateTime.now().millisecondsSinceEpoch.toString().substring(7);
      final prefix = role == 'student' ? 'SV' : 'GV';
      final autoUserId = '$prefix$timestamp';

      // Truncate password if longer than 50 characters
      final truncatedPassword = password.length > 50 ? password.substring(0, 50) : password;

      final requestData = {
        'user_id': autoUserId,
        'email': email,
        'full_name': fullName,
        'password': truncatedPassword,
        'role': role,
        if (phone != null) 'phone': phone,
      };

      final response = await _dio.post(
        '/api/v1/auth/register',
        data: requestData,
      );

      if (response.statusCode == 201) {
        return {
          'success': true,
          'data': {
            ...response.data,
            'userId': autoUserId, // Return the generated user_id
          }
        };
      }
    } on DioException catch (e) {
      if (e.response?.data?['detail'] != null) {
        return {
          'success': false,
          'message': e.response!.data['detail'],
        };
      }
      return {
        'success': false,
        'message': 'Network error: ${e.message}',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Unexpected error: $e',
      };
    }
    return null;
  }

  static Future<Map<String, dynamic>?> registerUser({
    required String userId,
    required String email,
    required String fullName,
    required String password,
    required String role, // 'student' or 'instructor'
    String? phone,
  }) async {
    await _initialize();
    try {
      // Truncate password if longer than 50 characters
      final truncatedPassword = password.length > 50 ? password.substring(0, 50) : password;

      final requestData = {
        'user_id': userId,
        'email': email,
        'full_name': fullName,
        'password': truncatedPassword,
        'role': role,
        'phone': phone,
      };

      final response = await _dio.post(
        '/api/v1/auth/register',
        data: requestData,
      );

      if (response.statusCode == 201) {
        return response.data;
      }
    } on DioException catch (e) {
      if (e.response?.data?['detail'] != null) {
        return {
          'success': false,
          'message': e.response!.data['detail'],
        };
      }
      return {
        'success': false,
        'message': 'Network error: ${e.message}',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Unexpected error: $e',
      };
    }
    return null;
  }

  static Future<Map<String, dynamic>?> login({
    required String userId,
    required String password,
  }) async {
    await _initialize();
    try {
      // Truncate password if longer than 72 bytes for bcrypt compatibility
      final passwordBytes = password.codeUnits; // Get UTF-8 bytes
      final truncatedPassword = passwordBytes.length > 72
          ? String.fromCharCodes(passwordBytes.take(72))
          : password;

      debugPrint('Original password: $password (length: ${password.length})');
      debugPrint('Password bytes: ${passwordBytes.length}');
      debugPrint('Truncated password: $truncatedPassword');

      final requestData = {
        'user_id': userId,
        'password': truncatedPassword,
      };

      final response = await _dio.post(
        '/api/v1/auth/login',
        data: requestData,
      );

      if (response.statusCode == 200) {
        // Save the token from successful login
        final responseData = response.data;
        if (responseData['data'] != null && responseData['data']['access_token'] != null) {
          await saveToken(responseData['data']['access_token']);
          debugPrint('Login successful, token saved');
        }
        return responseData;
      }
    } on DioException catch (e) {
      if (e.response?.data?['detail'] != null) {
        return {
          'success': false,
          'message': e.response!.data['detail'],
        };
      }
      return {
        'success': false,
        'message': 'Network error: ${e.message}',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Unexpected error: $e',
      };
    }
    return null;
  }

  static Future<Map<String, dynamic>?> getAttendanceHistory({
    required String classId,
    String? date,
    int page = 1,
    int perPage = 20,
  }) async {
    await _initialize();
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'per_page': perPage,
      };

      if (date != null) {
        queryParams['date'] = date;
      }

      final response = await _dio.get(
        '/api/v1/attendance/$classId',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        return response.data;
      }
    } catch (e) {
      debugPrint('Error fetching attendance history: $e');
    }
    return null;
  }

  static Future<bool> testConnection() async {
    try {
      await _initialize();
      final response = await _dio.get('/docs');
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // Face Registration Status Methods
  static Future<Map<String, dynamic>?> getFaceRegistrationStatus(String userId) async {
    try {
      await _initialize();
      final response = await _dio.get(
        '/api/v1/attendance/face-status/$userId',
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            if (_authToken != null) 'Authorization': 'Bearer $_authToken',
          },
        ),
      );

      if (response.statusCode == 200) {
        debugPrint('Face registration status: ${response.data}');
        return response.data;
      }
    } catch (e) {
      debugPrint('Error fetching face registration status: $e');
    }
    return null;
  }

  static Future<bool> isUserFaceRegistered(String userId) async {
    final statusData = await getFaceRegistrationStatus(userId);
    if (statusData != null && statusData['success'] == true) {
      return statusData['is_registered'] == true;
    }
    return false;
  }

  // Get student classes from real API
  static Future<List<Map<String, dynamic>>> getStudentClasses() async {
    if (!ensureAuthenticated()) {
      throw Exception('User not authenticated');
    }

    try {
      final response = await _dio.get(
        '/api/v1/classes/',
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            if (_authToken != null) 'Authorization': 'Bearer $_authToken',
          },
        ),
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        final List<dynamic> classesData = response.data['data'] ?? [];
        debugPrint('✅ Loaded ${classesData.length} classes from API');
        return classesData.map((classData) => Map<String, dynamic>.from(classData)).toList();
      } else {
        debugPrint('❌ Failed to get student classes: ${response.data}');
        return [];
      }
    } on DioException catch (e) {
      debugPrint('❌ DioException getting student classes: ${e.response?.data ?? e.message}');
      return [];
    } catch (e) {
      debugPrint('❌ Error getting student classes: $e');
      return [];
    }
  }

  // Teacher-specific methods
  static Future<List<Map<String, dynamic>>> getTeacherClasses() async {
    if (!ensureAuthenticated()) {
      throw Exception('User not authenticated');
    }

    try {
      // Use the general classes endpoint which supports role-based filtering
      final response = await _dio.get(
        '/api/v1/classes/',
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            if (_authToken != null) 'Authorization': 'Bearer $_authToken',
          },
        ),
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        final List<dynamic> classesData = response.data['data'] ?? [];
        debugPrint('✅ Loaded ${classesData.length} teacher classes from API');
        return classesData.map((classData) => Map<String, dynamic>.from(classData)).toList();
      } else {
        debugPrint('❌ Failed to get teacher classes: ${response.data}');
        return [];
      }
    } on DioException catch (e) {
      debugPrint('❌ DioException getting teacher classes: ${e.response?.data ?? e.message}');
      return [];
    } catch (e) {
      debugPrint('❌ Error getting teacher classes: $e');
      return [];
    }
  }

  static Future<List<Map<String, dynamic>>> getTeacherTodayClasses() async {
    if (!ensureAuthenticated()) {
      throw Exception('User not authenticated');
    }

    try {
      // Use the general classes endpoint with date filter
      final response = await _dio.get(
        '/api/v1/classes/',
        queryParameters: {'class_status': 'active'}, // Filter for active classes
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            if (_authToken != null) 'Authorization': 'Bearer $_authToken',
          },
        ),
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        final List<dynamic> classesData = response.data['data'] ?? [];
        // Filter for today's classes on client side
        final today = DateTime.now();
        final todayClasses = classesData.where((classData) {
          // Simple date check - you might want to improve this logic
          final classDate = DateTime.tryParse(classData['schedule']?['date'] ?? '');
          return classDate != null &&
                 classDate.year == today.year &&
                 classDate.month == today.month &&
                 classDate.day == today.day;
        }).toList();

        debugPrint('✅ Loaded ${todayClasses.length} today classes from API');
        return todayClasses.map((classData) => Map<String, dynamic>.from(classData)).toList();
      } else {
        debugPrint('❌ Failed to get today classes: ${response.data}');
        return [];
      }
    } on DioException catch (e) {
      debugPrint('❌ DioException getting today classes: ${e.response?.data ?? e.message}');
      return [];
    } catch (e) {
      debugPrint('❌ Error getting today classes: $e');
      return [];
    }
  }

  static Future<Map<String, dynamic>> getTeacherStats() async {
    if (!ensureAuthenticated()) {
      throw Exception('User not authenticated');
    }

    try {
      // Get teacher classes and calculate stats
      final teacherClasses = await getTeacherClasses();

      int totalStudents = 0;
      int activeClasses = 0;

      for (final classData in teacherClasses) {
        final studentIds = classData['student_ids'] ?? classData['studentIds'] ?? [];
        totalStudents += (studentIds as List).length;

        final status = classData['status'] ?? 'active';
        if (status == 'active') {
          activeClasses++;
        }
      }

      final stats = {
        'totalClasses': teacherClasses.length,
        'totalStudents': totalStudents,
        'todayAttendance': 0, // Would need attendance API to calculate this
        'activeClasses': activeClasses,
      };

      debugPrint('✅ Calculated teacher stats: $stats');
      return stats;
    } catch (e) {
      debugPrint('❌ Error calculating teacher stats: $e');
      return {
        'totalClasses': 0,
        'totalStudents': 0,
        'todayAttendance': 0,
        'activeClasses': 0,
      };
    }
  }

  static Future<Map<String, dynamic>?> saveManualAttendance(String classId, Map<String, dynamic> attendanceData) async {
    if (!ensureAuthenticated()) {
      return {
        'success': false,
        'message': 'Please login first to save attendance',
      };
    }

    await _initialize();
    try {
      final response = await _dio.post(
        '/api/v1/attendance/manual/$classId',
        data: attendanceData,
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            if (_authToken != null) 'Authorization': 'Bearer $_authToken',
          },
        ),
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        return response.data;
      } else {
        return {
          'success': false,
          'message': response.data['message'] ?? 'Failed to save attendance',
        };
      }
    } on DioException catch (e) {
      if (e.response?.data?['detail'] != null) {
        return {
          'success': false,
          'message': e.response!.data['detail'],
        };
      }
      return {
        'success': false,
        'message': 'Network error: ${e.message}',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Unexpected error: $e',
      };
    }
  }

  static Future<Map<String, dynamic>?> enrollStudents(String classId, List<String> studentIds) async {
    if (!ensureAuthenticated()) {
      return {
        'success': false,
        'message': 'Please login first to enroll students',
      };
    }

    await _initialize();
    try {
      final response = await _dio.post(
        '/api/v1/classes/$classId/enroll',
        data: {'student_ids': studentIds},
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            if (_authToken != null) 'Authorization': 'Bearer $_authToken',
          },
        ),
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        return response.data;
      } else {
        return {
          'success': false,
          'message': response.data['message'] ?? 'Failed to enroll students',
        };
      }
    } on DioException catch (e) {
      if (e.response?.data?['detail'] != null) {
        return {
          'success': false,
          'message': e.response!.data['detail'],
        };
      }
      return {
        'success': false,
        'message': 'Network error: ${e.message}',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Unexpected error: $e',
      };
    }
  }

  static Future<Map<String, dynamic>?> removeStudents(String classId, List<String> studentIds) async {
    if (!ensureAuthenticated()) {
      return {
        'success': false,
        'message': 'Please login first to remove students',
      };
    }

    await _initialize();
    try {
      final response = await _dio.post(
        '/api/v1/classes/$classId/remove-students',
        data: {'student_ids': studentIds},
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            if (_authToken != null) 'Authorization': 'Bearer $_authToken',
          },
        ),
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        return response.data;
      } else {
        return {
          'success': false,
          'message': response.data['message'] ?? 'Failed to remove students',
        };
      }
    } on DioException catch (e) {
      if (e.response?.data?['detail'] != null) {
        return {
          'success': false,
          'message': e.response!.data['detail'],
        };
      }
      return {
        'success': false,
        'message': 'Network error: ${e.message}',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Unexpected error: $e',
      };
    }
  }

  static Future<Map<String, dynamic>?> startAttendanceSession(String classId, Map<String, dynamic> sessionData) async {
    if (!ensureAuthenticated()) {
      return {
        'success': false,
        'message': 'Please login first to start attendance session',
      };
    }

    await _initialize();
    try {
      final response = await _dio.post(
        '/api/v1/classes/$classId/start-attendance-session',
        data: sessionData,
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            if (_authToken != null) 'Authorization': 'Bearer $_authToken',
          },
        ),
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        return response.data;
      } else {
        return {
          'success': false,
          'message': response.data['message'] ?? 'Failed to start attendance session',
        };
      }
    } on DioException catch (e) {
      if (e.response?.data?['detail'] != null) {
        return {
          'success': false,
          'message': e.response!.data['detail'],
        };
      }
      return {
        'success': false,
        'message': 'Network error: ${e.message}',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Unexpected error: $e',
      };
    }
  }

  static Future<Map<String, dynamic>?> stopAttendanceSession(String classId) async {
    if (!ensureAuthenticated()) {
      return {
        'success': false,
        'message': 'Please login first to stop attendance session',
      };
    }

    await _initialize();
    try {
      final response = await _dio.post(
        '/api/v1/classes/$classId/stop-attendance-session',
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            if (_authToken != null) 'Authorization': 'Bearer $_authToken',
          },
        ),
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        return response.data;
      } else {
        return {
          'success': false,
          'message': response.data['message'] ?? 'Failed to stop attendance session',
        };
      }
    } on DioException catch (e) {
      if (e.response?.data?['detail'] != null) {
        return {
          'success': false,
          'message': e.response!.data['detail'],
        };
      }
      return {
        'success': false,
        'message': 'Network error: ${e.message}',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Unexpected error: $e',
      };
    }
  }

  static Future<Map<String, dynamic>?> getAttendanceRecords(String classId, {String? date}) async {
    if (!ensureAuthenticated()) {
      return {
        'success': false,
        'message': 'Please login first to get attendance records',
      };
    }

    await _initialize();
    try {
      final queryParams = <String, dynamic>{};
      if (date != null) {
        queryParams['date'] = date;
      }

      final response = await _dio.get(
        '/api/v1/attendance/$classId',
        queryParameters: queryParams,
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            if (_authToken != null) 'Authorization': 'Bearer $_authToken',
          },
        ),
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        return response.data;
      } else {
        return {
          'success': false,
          'message': response.data['message'] ?? 'Failed to get attendance records',
        };
      }
    } on DioException catch (e) {
      if (e.response?.data?['detail'] != null) {
        return {
          'success': false,
          'message': e.response!.data['detail'],
        };
      }
      return {
        'success': false,
        'message': 'Network error: ${e.message}',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Unexpected error: $e',
      };
    }
  }

  static Future<Map<String, dynamic>?> getTeacherStatistics(String teacherId) async {
    if (!ensureAuthenticated()) {
      return {
        'success': false,
        'message': 'Please login first to get statistics',
      };
    }

    await _initialize();
    try {
      final response = await _dio.get(
        '/api/v1/users/$teacherId/statistics',
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            if (_authToken != null) 'Authorization': 'Bearer $_authToken',
          },
        ),
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        return response.data;
      } else {
        return {
          'success': false,
          'message': response.data['message'] ?? 'Failed to get statistics',
        };
      }
    } on DioException catch (e) {
      if (e.response?.data?['detail'] != null) {
        return {
          'success': false,
          'message': e.response!.data['detail'],
        };
      }
      return {
        'success': false,
        'message': 'Network error: ${e.message}',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Unexpected error: $e',
      };
    }
  }

  static Future<Map<String, dynamic>?> getTeacherClassesWithStats({bool includeStats = true}) async {
    if (!ensureAuthenticated()) {
      return {
        'success': false,
        'message': 'Please login first to get classes',
      };
    }

    await _initialize();
    try {
      final response = await _dio.get(
        '/api/v1/classes/',
        queryParameters: includeStats ? {'include_stats': 'true'} : null,
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            if (_authToken != null) 'Authorization': 'Bearer $_authToken',
          },
        ),
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        return response.data;
      } else {
        return {
          'success': false,
          'message': response.data['message'] ?? 'Failed to get classes',
        };
      }
    } on DioException catch (e) {
      if (e.response?.data?['detail'] != null) {
        return {
          'success': false,
          'message': e.response!.data['detail'],
        };
      }
      return {
        'success': false,
        'message': 'Network error: ${e.message}',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Unexpected error: $e',
      };
    }
  }

  static Future<Map<String, dynamic>?> updateUserProfile(String userId, Map<String, dynamic> profileData) async {
    if (!ensureAuthenticated()) {
      return {
        'success': false,
        'message': 'Please login first to update profile',
      };
    }

    await _initialize();
    try {
      final response = await _dio.put(
        '/api/v1/users/$userId',
        data: profileData,
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            if (_authToken != null) 'Authorization': 'Bearer $_authToken',
          },
        ),
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        return response.data;
      } else {
        return {
          'success': false,
          'message': response.data['message'] ?? 'Failed to update profile',
        };
      }
    } on DioException catch (e) {
      if (e.response?.data?['detail'] != null) {
        return {
          'success': false,
          'message': e.response!.data['detail'],
        };
      }
      return {
        'success': false,
        'message': 'Network error: ${e.message}',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Unexpected error: $e',
      };
    }
  }

  static Future<Map<String, dynamic>?> changePassword(String userId, Map<String, dynamic> passwordData) async {
    if (!ensureAuthenticated()) {
      return {
        'success': false,
        'message': 'Please login first to change password',
      };
    }

    await _initialize();
    try {
      final response = await _dio.post(
        '/api/v1/users/$userId/change-password',
        data: passwordData,
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            if (_authToken != null) 'Authorization': 'Bearer $_authToken',
          },
        ),
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        return response.data;
      } else {
        return {
          'success': false,
          'message': response.data['message'] ?? 'Failed to change password',
        };
      }
    } on DioException catch (e) {
      if (e.response?.data?['detail'] != null) {
        return {
          'success': false,
          'message': e.response!.data['detail'],
        };
      }
      return {
        'success': false,
        'message': 'Network error: ${e.message}',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Unexpected error: $e',
      };
    }
  }

  static Future<Map<String, dynamic>?> createAttendanceCode(String classId, {Duration? duration}) async {
    debugPrint('🔍 API: createAttendanceCode called with classId: "$classId", duration: ${duration?.inMinutes ?? 'null'} minutes');

    if (!ensureAuthenticated()) {
      debugPrint('🔍 API: Authentication check failed');
      throw Exception('User not authenticated');
    }

    debugPrint('🔍 API: Authentication check passed, token: ${_authToken?.substring(0, 20) ?? 'null'}...');

    try {
      final Map<String, dynamic> requestData = {
        'class_id': classId,
        if (duration != null) 'duration_minutes': duration.inMinutes,
      };

      debugPrint('🔍 API: Request data: $requestData');
      debugPrint('🔍 API: Making POST request to /api/v1/attendance/code');

      final response = await _dio.post(
        '/api/v1/attendance/code',
        data: requestData,
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            if (_authToken != null) 'Authorization': 'Bearer $_authToken',
          },
        ),
      );

      debugPrint('🔍 API: Response received');
      debugPrint('🔍 API: Status code: ${response.statusCode}');
      debugPrint('🔍 API: Response data: ${response.data}');
      debugPrint('🔍 API: Response data type: ${response.data.runtimeType}');

      if (response.statusCode == 201 && response.data['success'] == true) {
        debugPrint('✅ API: Created attendance code successfully');
        debugPrint('🔍 API: Returning data: ${response.data['data']}');
        return response.data['data'];
      } else {
        debugPrint('❌ API: Failed to create attendance code');
        debugPrint('🔍 API: Status code check: ${response.statusCode == 201}');
        debugPrint('🔍 API: Success check: ${response.data['success']}');
        debugPrint('🔍 API: Full response: ${response.data}');
        return null;
      }
    } on DioException catch (e) {
      debugPrint('🔍 API: DioException caught');
      debugPrint('🔍 API: Exception type: ${e.type}');
      debugPrint('🔍 API: Exception message: ${e.message}');
      debugPrint('🔍 API: Response status: ${e.response?.statusCode}');
      debugPrint('🔍 API: Response data: ${e.response?.data}');
      return null;
    } catch (e) {
      debugPrint('🔍 API: Generic error caught: $e');
      debugPrint('🔍 API: Error type: ${e.runtimeType}');
      return null;
    }
  }
}