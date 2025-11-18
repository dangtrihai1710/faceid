import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../models/class_model.dart';
import '../models/attendance_model.dart';
import 'auth_service.dart';
import 'api_service.dart';

class AdminApiService {
  static const String _adminKey = 'admin_data';
  static const String _adminCredentials = 'admin_credentials';

  // Initialize admin account - Dùng cho local fallback
  static Future<void> initializeAdmin() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Check if admin already exists in local storage
      final adminExists = prefs.containsKey(_adminCredentials);
      if (!adminExists) {
        // Create default admin account locally
        final adminCredentials = {
          'userId': 'admin',
          'password': 'admin123',
          'fullName': 'System Administrator',
          'email': 'admin@faceid.com',
          'role': 'admin',
          'createdAt': DateTime.now().millisecondsSinceEpoch,
        };

        await prefs.setString(_adminCredentials, jsonEncode(adminCredentials));
        print('Admin account initialized: admin/admin123');
      }
    } catch (e) {
      print('Error initializing admin: $e');
    }
  }

  // Admin login - Try FastAPI first, fallback to local
  static Future<Map<String, dynamic>?> adminLogin(String userId, String password) async {
    try {
      print('🔐 Attempting admin login via FastAPI...');

      // Try login via FastAPI first
      final apiResult = await ApiService.login(userId, password, 'admin');

      if (apiResult['success'] == true) {
        print('✅ Admin login successful via FastAPI');
        return apiResult;
      }

      print('⚠️ FastAPI login failed, trying local fallback...');

      // Fallback to local storage
      final prefs = await SharedPreferences.getInstance();
      final adminJson = prefs.getString(_adminCredentials);

      if (adminJson != null) {
        final adminData = jsonDecode(adminJson) as Map<String, dynamic>;

        if (adminData['userId'] == userId && adminData['password'] == password) {
          return {
            'success': true,
            'user': User(
              id: 'admin',
              userId: userId,
              fullName: adminData['fullName'],
              email: adminData['email'],
              role: 'admin',
              token: 'admin_token_${DateTime.now().millisecondsSinceEpoch}',
            ),
          };
        }
      }

      return {'success': false, 'error': 'Tài khoản hoặc mật khẩu không chính xác'};
    } catch (e) {
      print('Error during admin login: $e');
      return {'success': false, 'error': 'Lỗi đăng nhập'};
    }
  }

  // Get all users - Try FastAPI first, fallback to demo data
  static Future<List<User>> getAllUsers(String token, {String? role}) async {
    try {
      print('👥 Getting users from FastAPI...');

      // Set token for API calls
      ApiService.setToken(token);

      // Try to get users from FastAPI
      final apiResult = await ApiService.getAllUsers(token);

      if (apiResult['success'] == true && apiResult['accounts'] != null) {
        final List<dynamic> users = apiResult['accounts'];
        final List<User> allUsers = users.map((userData) => User(
          id: userData['id']?.toString() ?? '',
          userId: userData['username'] ?? userData['user_id'] ?? '',
          email: userData['email'] ?? '',
          fullName: userData['full_name'] ?? userData['fullName'] ?? '',
          role: userData['role'] ?? 'user',
          token: token,
          createdAt: userData['created_at'] != null
              ? DateTime.tryParse(userData['created_at']) ?? DateTime.now()
              : DateTime.now(),
        )).toList();

        print('✅ Got ${allUsers.length} users from FastAPI');
        return role == null ? allUsers : allUsers.where((user) => user.role == role).toList();
      }

      print('⚠️ FastAPI users failed, using demo data...');

      // Fallback to demo data
      final List<User> demoUsers = [
        User(
          id: 'student_001',
          userId: 'SV001',
          fullName: 'Nguyễn Văn Sinh Viên',
          email: 'student1@faceid.com',
          role: 'student',
          token: 'student_token',
          createdAt: DateTime.now(),
        ),
        User(
          id: 'student_002',
          userId: 'SV002',
          fullName: 'Trần Thị Sinh Viên',
          email: 'student2@faceid.com',
          role: 'student',
          token: 'student_token',
          createdAt: DateTime.now(),
        ),
        User(
          id: 'instructor_001',
          userId: 'GV001',
          fullName: 'Trần Thị Giảng Viên',
          email: 'teacher1@faceid.com',
          role: 'instructor',
          token: 'instructor_token',
          createdAt: DateTime.now(),
        ),
        User(
          id: 'instructor_002',
          userId: 'GV002',
          fullName: 'Lê Văn Giảng Viên',
          email: 'teacher2@faceid.com',
          role: 'instructor',
          token: 'instructor_token',
          createdAt: DateTime.now(),
        ),
      ];

      return role == null ? demoUsers : demoUsers.where((user) => user.role == role).toList();
    } catch (e) {
      print('❌ Error getting users: $e');
      return [];
    }
  }

  // Get all students
  static Future<List<User>> getAllStudents(String token) async {
    return await getAllUsers(token, role: 'student');
  }

  // Get all instructors
  static Future<List<User>> getAllInstructors(String token) async {
    return await getAllUsers(token, role: 'instructor');
  }

  // Get all classes - Try FastAPI first, fallback to demo data
  static Future<List<ClassModel>> getAllClasses(String token) async {
    try {
      print('📚 Getting classes from FastAPI...');

      // Set token for API calls
      ApiService.setToken(token);

      // Try to get classes from FastAPI
      final apiClasses = await ApiService.getAllClasses(token);

      if (apiClasses.isNotEmpty) {
        print('✅ Got ${apiClasses.length} classes from FastAPI');
        return apiClasses;
      }

      print('⚠️ FastAPI classes failed, using demo data...');

      // Fallback to demo data
      return [
        ClassModel(
          id: 'class_001',
          name: 'Lập trình Flutter',
          subject: 'Flutter',
          instructor: 'GV001',
          startTime: DateTime.now().subtract(Duration(hours: 2)),
          endTime: DateTime.now(),
          room: 'Phòng A101',
        ),
        ClassModel(
          id: 'class_002',
          name: 'Cơ sở dữ liệu',
          subject: 'Database',
          instructor: 'GV002',
          startTime: DateTime.now().subtract(Duration(hours: 1)),
          endTime: DateTime.now().add(Duration(hours: 1)),
          room: 'Phòng B205',
        ),
      ];
    } catch (e) {
      print('❌ Error getting classes: $e');
      return [];
    }
  }

  // Get attendance records - Try FastAPI first, fallback to demo data
  static Future<List<AttendanceModel>> getAttendanceRecords(String token, {String? classId}) async {
    try {
      print('📊 Getting attendance records from FastAPI...');

      // Set token for API calls
      ApiService.setToken(token);

      // Try to get attendance from FastAPI
      final apiAttendance = await ApiService.getAttendanceRecords(token, classId: classId);

      if (apiAttendance.isNotEmpty) {
        print('✅ Got ${apiAttendance.length} attendance records from FastAPI');
        return apiAttendance;
      }

      print('⚠️ FastAPI attendance failed, using demo data...');

      // Fallback to demo data
      return [
        AttendanceModel(
          id: 'attend_001',
          classId: 'class_001',
          userId: 'SV001',
          checkInTime: DateTime.now().subtract(Duration(days: 1, hours: 2)),
          status: AttendanceStatus.present,
        ),
        AttendanceModel(
          id: 'attend_002',
          classId: 'class_001',
          userId: 'SV002',
          checkInTime: DateTime.now().subtract(Duration(days: 1)),
          status: AttendanceStatus.absent,
        ),
      ];
    } catch (e) {
      print('❌ Error getting attendance records: $e');
      return [];
    }
  }

  // Get system statistics
  static Future<Map<String, dynamic>> getSystemStatistics(String token) async {
    try {
      final students = await getAllStudents(token);
      final instructors = await getAllInstructors(token);
      final classes = await getAllClasses(token);
      final attendance = await getAttendanceRecords(token);

      final today = DateTime.now();
      final todayAttendance = attendance.where((record) {
        return record.checkInTime.year == today.year &&
               record.checkInTime.month == today.month &&
               record.checkInTime.day == today.day;
      }).length;

      return {
        'students': students.length,
        'instructors': instructors.length,
        'classes': classes.length,
        'activeClasses': classes.length,
        'totalAttendance': attendance.length,
        'todayAttendance': todayAttendance,
        'users': students.length + instructors.length,
      };
    } catch (e) {
      print('Error getting system statistics: $e');
      return {
        'students': 2,
        'instructors': 2,
        'classes': 2,
        'activeClasses': 2,
        'totalAttendance': 10,
        'todayAttendance': 3,
        'users': 4,
      };
    }
  }

  // Get database info
  static Future<Map<String, dynamic>> getDatabaseInfo(String token) async {
    return {
      'status': 'connected',
      'type': 'local_testing',
      'lastSync': DateTime.now().toIso8601String(),
    };
  }
}