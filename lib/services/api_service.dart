import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/user.dart';
import '../models/class_model.dart';
import '../models/attendance_model.dart';

class ApiService {
  // Change this to your FastAPI server URL
  static const String _baseUrl = 'http://127.0.0.1:8000'; // Default localhost
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
        Uri.parse('$_baseUrl/auth/login'),
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
        setToken(data['access_token'] ?? '');

        return {
          'success': true,
          'access_token': data['access_token'],
          'token': data['access_token'],
          'user': User(
            id: data['user']['id']?.toString() ?? data['user']['_id']?.toString() ?? '',
            userId: data['user']['user_id'] ?? data['user']['userId'] ?? userId,
            email: data['user']['email'] ?? '',
            fullName: data['user']['full_name'] ?? data['user']['fullName'] ?? data['user']['username'] ?? userId,
            role: data['user']['role'] ?? role,
            token: data['access_token'] ?? '',
            createdAt: DateTime.tryParse(data['user']['created_at'] ?? data['user']['createdAt'] ?? '') ?? DateTime.now(),
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
        Uri.parse('$_baseUrl/users'),
        headers: _getHeaders(),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {'success': true, 'accounts': data['users'] ?? data ?? []};
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
        Uri.parse('$_baseUrl/classes/'),
        headers: _getHeaders(),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((item) => ClassModel.fromJson(item)).toList();
      } else {
        print('❌ Get classes error: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('❌ Get classes error: $e');
      return [];
    }
  }

  // Get attendance records
  static Future<List<AttendanceModel>> getAttendanceRecords(String token, {String? classId}) async {
    try {
      String url = '$_baseUrl/attendance/';
      if (classId != null) {
        url += '?class_id=$classId';
      }

      final response = await http.get(
        Uri.parse(url),
        headers: _getHeaders(),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((item) => AttendanceModel.fromJson(item)).toList();
      } else {
        print('❌ Get attendance error: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('❌ Get attendance error: $e');
      return [];
    }
  }

  // Create attendance record
  static Future<Map<String, dynamic>> createAttendance(String token, Map<String, dynamic> attendanceData) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/attendance/'),
        headers: _getHeaders(),
        body: jsonEncode(attendanceData),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return {'success': true, 'attendance': data};
      } else {
        return _handleError(response);
      }
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
        Uri.parse('$_baseUrl/users/'),
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

  // Test server connection
  static Future<bool> testConnection() async {
    try {
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
}