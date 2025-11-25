import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/user.dart';
import '../models/class_model.dart';

class ApiService {
  // Change this to your FastAPI server URL
  static const String _baseUrl = 'http://127.0.0.1:8002'; // Fixed to match backend port
  // For mobile testing, use your computer's IP address
  // static const String _baseUrl = 'http://192.168.1.100:8000'; // Replace with your IP

  static String _token = '';

  static void setToken(String token) {
    _token = token;
  }

  static String getToken() {
    return _token;
  }

  static Map<String, String> _getHeaders() {
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (_token.isNotEmpty) 'Authorization': 'Bearer $_token',
    };
  }

  // Handle network errors
  static dynamic _handleError(http.Response response) {
    print('❌ API Error: ${response.statusCode} - ${response.body}');

    switch (response.statusCode) {
      case 400:
        return {'success': false, 'message': 'Dữ liệu không hợp lệ'};
      case 401:
        return {'success': false, 'message': 'Chưa đăng nhập hoặc token hết hạn'};
      case 403:
        return {'success': false, 'message': 'Không có quyền truy cập'};
      case 404:
        return {'success': false, 'message': 'Không tìm thấy dữ liệu'};
      case 500:
        return {'success': false, 'message': 'Lỗi server'};
      default:
        return {'success': false, 'message': 'Lỗi kết nối: ${response.statusCode}'};
    }
  }

  // User login
  static Future<Map<String, dynamic>> login(String userId, String password, String role) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/v1/auth/login'),
        headers: _getHeaders(),
        body: jsonEncode({
          'user_id': userId,
          'password': password,
          'role': role,
        }),
      ).timeout(const Duration(seconds: 10));

      print('🔐 Login attempt: $userId as $role');
      print('📡 Response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Check if user data exists - user is nested inside data.user
        final userData = data['data']?['user'];
        if (userData == null) {
          print('❌ ERROR: user field is null in response');
          print('🔍 DEBUG: data structure: ${data}');
          return {
            'success': false,
            'message': 'Phản hồi thiếu trường user - Response: ${response.body}',
          };
        }

        if (userData is! Map<String, dynamic>) {
          print('❌ ERROR: user field is not a Map, got ${userData.runtimeType}');
          return {
            'success': false,
            'message': 'Trường user không đúng định dạng - Response: ${response.body}',
          };
        }

        setToken(data['data']?['access_token'] ?? '');

        return {
          'success': true,
          'access_token': data['data']?['access_token'],
          'token': data['data']?['access_token'],
          'user': User(
            id: userData['_id']?.toString() ?? userId,
            userId: userData['userId'] ?? userData['user_id'] ?? userId,
            email: userData['email'] ?? '',
            fullName: userData['full_name'] ?? userData['fullName'] ?? userData['username'] ?? userId,
            role: userData['role'] ?? role,
            token: data['data']?['access_token'] ?? '',
            createdAt: DateTime.tryParse(userData['created_at'] ?? userData['createdAt'] ?? '') ?? DateTime.now(),
          ),
        };
      } else {
        return _handleError(response);
      }
    } on SocketException {
      return {'success': false, 'message': 'Không thể kết nối tới server. Vui lòng kiểm tra kết nối mạng.'};
    } on HttpException {
      return {'success': false, 'message': 'Lỗi HTTP. Vui lòng thử lại sau.'};
    } on FormatException {
      return {'success': false, 'message': 'Dữ liệu trả về không đúng định dạng.'};
    } catch (e) {
      print('❌ Login error: $e');
      return {'success': false, 'message': 'Lỗi không xác định: $e'};
    }
  }

  // Get all users
  static Future<Map<String, dynamic>> getAllUsers(String token) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/api/v1/users/'),
        headers: _getHeaders(),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // Check if data has expected structure
        if (data is Map<String, dynamic> && data.containsKey('data')) {
          final usersData = data['data'];
          if (usersData is List) {
            return {'success': true, 'accounts': usersData};
          }
        }
        return {'success': false, 'accounts': []};
      } else {
        return _handleError(response);
      }
    } catch (e) {
      print('❌ Get users error: $e');
      return {'success': false, 'message': 'Lỗi khi lấy danh sách người dùng'};
    }
  }

  // Get all classes
  static Future<List<ClassModel>> getAllClasses(String token) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/api/v1/classes/'),
        headers: _getHeaders(),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // Check if data has expected structure
        if (data is Map<String, dynamic> && data.containsKey('data')) {
          final classesData = data['data'];
          if (classesData is List) {
            return classesData.map((item) => ClassModel.fromJson(item)).toList();
          }
        }
        return [];
      } else {
        print('❌ Get classes error: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('❌ Get classes error: $e');
      return [];
    }
  }

  // Get attendance records for a specific class
  static Future<List<Map<String, dynamic>>> getAttendanceRecords(String token, {String? classId}) async {
    try {
      if (classId == null) {
        print('❌ Error: class_id is required for attendance records');
        return [];
      }

      final response = await http.get(
        Uri.parse('$_baseUrl/api/v1/attendance/$classId'),
        headers: _getHeaders(),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // Check if data has expected structure
        if (data is Map<String, dynamic> && data.containsKey('data')) {
          final attendanceData = data['data'];
          if (attendanceData is List) {
            return attendanceData.cast<Map<String, dynamic>>();
          }
        }
        return [];
      } else {
        print('❌ Get attendance error: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('❌ Get attendance error: $e');
      return [];
    }
  }

  // Create attendance record using face recognition
  static Future<Map<String, dynamic>> createAttendance(String token, Map<String, dynamic> attendanceData) async {
    try {
      // Backend doesn't have generic POST /attendance/ endpoint
      // Attendance is created through specific methods: face, QR, or code
      print('⚠️ Create attendance: Use specific attendance methods (face/QR/code)');
      return {
        'success': false,
        'message': 'Sử dụng các phương thức điểm danh cụ thể: face recognition, QR code, hoặc short code'
      };
    } catch (e) {
      print('❌ Create attendance error: $e');
      return {'success': false, 'message': 'Lỗi khi tạo bản ghi điểm danh'};
    }
  }

  // Face recognition
  static Future<Map<String, dynamic>> recognizeFace(String token, String imagePath) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$_baseUrl/face/recognize'),
      );
      request.headers.addAll(_getHeaders());
      request.files.add(await http.MultipartFile.fromPath('image', imagePath));

      final streamedResponse = await request.send().timeout(const Duration(seconds: 30));
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {'success': true, 'user': data};
      } else {
        return _handleError(response);
      }
    } catch (e) {
      print('❌ Face recognition error: $e');
      return {'success': false, 'message': 'Lỗi nhận diện khuôn mặt'};
    }
  }

  // Create account (register)
  static Future<Map<String, dynamic>> createAccount(String token, Map<String, dynamic> userData) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/v1/users/'),
        headers: _getHeaders(),
        body: jsonEncode(userData),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return {'success': true, 'user': data};
      } else {
        return _handleError(response);
      }
    } catch (e) {
      print('❌ Create account error: $e');
      return {'success': false, 'message': 'Lỗi khi tạo tài khoản'};
    }
  }

  // CRUD operations for users
  static Future<Map<String, dynamic>> createUser(String token, Map<String, dynamic> userData) async {
    return await makeAuthenticatedRequest('POST', '/api/v1/users/', body: userData);
  }

  static Future<Map<String, dynamic>> updateUser(String token, String userId, Map<String, dynamic> userData) async {
    return await makeAuthenticatedRequest('PUT', '/api/v1/users/$userId', body: userData);
  }

  static Future<Map<String, dynamic>> deleteUser(String token, String userId) async {
    return await makeAuthenticatedRequest('DELETE', '/api/v1/users/$userId');
  }

  static Future<Map<String, dynamic>> resetUserPassword(String token, String userId) async {
    return await makeAuthenticatedRequest('POST', '/api/v1/users/$userId/reset-password');
  }

  static Future<Map<String, dynamic>> updateUserStatus(String token, String userId, bool isActive) async {
    return await makeAuthenticatedRequest('PUT', '/api/v1/users/$userId/status', body: {'is_active': isActive});
  }

  // CRUD operations for classes
  static Future<Map<String, dynamic>> createClass(String token, Map<String, dynamic> classData) async {
    return await makeAuthenticatedRequest('POST', '/api/v1/classes/', body: classData);
  }

  static Future<Map<String, dynamic>> updateClass(String token, String classId, Map<String, dynamic> classData) async {
    return await makeAuthenticatedRequest('PUT', '/api/v1/classes/$classId', body: classData);
  }

  static Future<Map<String, dynamic>> deleteClass(String token, String classId) async {
    return await makeAuthenticatedRequest('DELETE', '/api/v1/classes/$classId');
  }

  static Future<Map<String, dynamic>> updateClassStatus(String token, String classId, bool isActive) async {
    return await makeAuthenticatedRequest('PUT', '/api/v1/classes/$classId/status', body: {'is_active': isActive});
  }

  static Future<Map<String, dynamic>> assignInstructor(String token, String classId, String instructorId) async {
    return await updateClass(token, classId, {
      'instructor_id': instructorId,
    });
  }

  static Future<List<Map<String, dynamic>>> getInstructors(String token) async {
    try {
      final result = await getAllUsers(token);
      if (result['success'] != true) {
        return [];
      }
      final allUsers = result['accounts'] as List? ?? [];
      final instructors = allUsers
          .where((user) => user['role'] == 'instructor')
          .map((e) => e as Map<String, dynamic>)
          .toList();
      return instructors;
    } catch (e) {
      print('❌ Get instructors error: $e');
      return [];
    }
  }

  // Test server connection
  static Future<bool> testConnection() async {
    try {
      // Test auth service as primary connection
      final response = await http.get(
        Uri.parse('$_baseUrl/'),
      ).timeout(const Duration(seconds: 5));

      return response.statusCode == 200;
    } catch (e) {
      print('❌ Connection test failed: $e');
      return false;
    }
  }

  // Get server info
  static Future<Map<String, dynamic>> getServerInfo() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/info'),
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {'status': 'error', 'message': 'Server not responding'};
      }
    } catch (e) {
      return {'status': 'error', 'message': 'Connection failed'};
    }
  }

  // Make authenticated request (for CRUD operations)
  static Future<Map<String, dynamic>> makeAuthenticatedRequest(
    String method,
    String endpoint, {
    Map<String, dynamic>? body,
    Map<String, String>? queryParams,
  }) async {
    try {
      Uri uri = Uri.parse('$_baseUrl$endpoint');
      if (queryParams != null) {
        uri = uri.replace(queryParameters: queryParams);
      }

      http.Response response;
      final headers = _getHeaders();

      switch (method.toUpperCase()) {
        case 'GET':
          response = await http.get(uri, headers: headers).timeout(const Duration(seconds: 10));
          break;
        case 'POST':
          response = await http.post(
            uri,
            headers: headers,
            body: body != null ? jsonEncode(body) : null,
          ).timeout(const Duration(seconds: 10));
          break;
        case 'PUT':
          response = await http.put(
            uri,
            headers: headers,
            body: body != null ? jsonEncode(body) : null,
          ).timeout(const Duration(seconds: 10));
          break;
        case 'DELETE':
          response = await http.delete(uri, headers: headers).timeout(const Duration(seconds: 10));
          break;
        default:
          return {'success': false, 'message': 'Phương thức HTTP không được hỗ trợ'};
      }

      print('🔍 DEBUG: $method $endpoint - ${response.statusCode}');

      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (response.body.isEmpty) {
          return {'success': true};
        }
        final data = jsonDecode(response.body);
        return {'success': true, ...data};
      } else {
        return _handleError(response);
      }
    } on SocketException {
      return {'success': false, 'message': 'Không thể kết nối tới server. Vui lòng kiểm tra kết nối mạng.'};
    } on HttpException {
      return {'success': false, 'message': 'Lỗi HTTP. Vui lòng thử lại sau.'};
    } on FormatException {
      return {'success': false, 'message': 'Dữ liệu trả về không đúng định dạng.'};
    } catch (e) {
      print('❌ Authenticated request error: $e');
      return {'success': false, 'message': 'Lỗi không xác định: $e'};
    }
  }
}