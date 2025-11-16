import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'dart:convert';
import 'dart:io';

class ApiService {
  static late Dio _dio;
  static const String _baseUrl = 'http://192.168.100.142:8000'; // Updated backend URL

  static void _initialize() {
    _dio = Dio(BaseOptions(
      baseUrl: _baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));

    // Add request interceptor for authorization if needed
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          debugPrint('API Request: ${options.method} ${options.uri}');
          if (options.data != null) {
            debugPrint('Request Data: ${options.data}');
          }
          // Add auth token if available
          // final token = getAuthToken();
          // if (token != null) {
          //   options.headers['Authorization'] = 'Bearer $token';
          // }
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

  static Future<String?> uploadImageForFaceRecognition({
    required String imagePath,
    required String classId,
    required String userId,
    Map<String, dynamic>? gpsData,
    String? deviceId,
    double confidenceThreshold = 0.85,
  }) {
    _initialize();
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
    _initialize();
    try {
      // Read image file and convert to base64
      final imageFile = File(imagePath);
      final imageBytes = await imageFile.readAsBytes();
      final base64Image = base64Encode(imageBytes);

      final requestData = {
        'image_data': base64Image,
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
    required String userId,
    required String classId,
    required String fullName,
    String? email,
    String? phone,
    Map<String, dynamic>? gpsData,
    String? deviceId,
    double confidenceThreshold = 0.85,
  }) async {
    _initialize();
    try {
      final List<Map<String, String>> imageData = [];

      for (String imagePath in imagePaths) {
        final imageFile = File(imagePath);
        final imageBytes = await imageFile.readAsBytes();
        final base64Image = base64Encode(imageBytes);

        imageData.add({
          'image_data': base64Image,
          'image_name': 'face_${imageData.length + 1}.jpg',
        });
      }

      final requestData = {
        'images': imageData,
        'user_id': userId,
        'class_id': classId,
        'full_name': fullName,
        'confidence_threshold': confidenceThreshold,
        if (email != null) 'email': email,
        if (phone != null) 'phone': phone,
        'gps_data': gpsData,
        'device_id': deviceId ?? 'unknown',
        'registration_type': 'face_id_multiple',
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

  static Future<String?> _performFaceRecognitionUpload({
    required String imagePath,
    required String classId,
    required String userId,
    Map<String, dynamic>? gpsData,
    String? deviceId,
    double confidenceThreshold = 0.85,
  }) async {
    try {
      // Read image file and convert to base64
      final imageFile = File(imagePath);
      final imageBytes = await imageFile.readAsBytes();
      final base64Image = base64Encode(imageBytes);

      final requestData = {
        'image_data': base64Image,
        'class_id': classId,
        'confidence_threshold': confidenceThreshold,
        'gps_data': gpsData,
        'device_id': deviceId ?? 'unknown',
        'location_validation_required': true,
      };

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
    _initialize();
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
    _initialize();
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
    _initialize();
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
    _initialize();
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
    _initialize();
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

  static Future<Map<String, dynamic>?> getAttendanceHistory({
    required String classId,
    String? date,
    int page = 1,
    int perPage = 20,
  }) async {
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
      final response = await _dio.get('/docs');
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}