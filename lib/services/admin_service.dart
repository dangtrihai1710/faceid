import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../models/class_model.dart';
import 'auth_service.dart';

class AdminService {
  static const String _adminKey = 'admin_data';
  static const String _studentsKey = 'students_data';
  static const String _instructorsKey = 'instructors_data';
  static const String _classesKey = 'classes_data';
  static const String _adminCredentials = 'admin_credentials';

  // Initialize admin account
  static Future<void> initializeAdmin() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Check if admin already exists
      final adminExists = prefs.containsKey(_adminCredentials);
      if (!adminExists) {
        // Create default admin account
        final adminCredentials = {
          'username': 'admin',
          'password': 'admin123',
          'fullName': 'System Administrator',
          'email': 'admin@faceid.com',
          'role': 'admin',
          'createdAt': DateTime.now().millisecondsSinceEpoch,
        };

        await prefs.setString(_adminCredentials, jsonEncode(adminCredentials));

        // Initialize empty data structures
        await prefs.setString(_studentsKey, jsonEncode([]));
        await prefs.setString(_instructorsKey, jsonEncode([]));
        await prefs.setString(_classesKey, jsonEncode([]));

        print('Admin account initialized: admin/admin123');
      }
    } catch (e) {
      print('Error initializing admin: $e');
    }
  }

  // Admin login
  static Future<Map<String, dynamic>?> adminLogin(String username, String password) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final adminJson = prefs.getString(_adminCredentials);

      if (adminJson != null) {
        final adminData = jsonDecode(adminJson) as Map<String, dynamic>;

        if (adminData['username'] == username && adminData['password'] == password) {
          return {
            'success': true,
            'user': User(
              id: 'admin',
              username: username,
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

  // Get all students
  static Future<List<User>> getAllStudents() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final studentsJson = prefs.getString(_studentsKey) ?? '[]';
      final studentsList = jsonDecode(studentsJson) as List;

      return studentsList.map((data) => User(
        id: data['id'],
        username: data['username'],
        fullName: data['fullName'],
        email: data['email'],
        role: 'student',
        token: data['token'] ?? '',
      )).toList();
    } catch (e) {
      print('Error getting students: $e');
      return [];
    }
  }

  // Get all instructors
  static Future<List<User>> getAllInstructors() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final instructorsJson = prefs.getString(_instructorsKey) ?? '[]';
      final instructorsList = jsonDecode(instructorsJson) as List;

      return instructorsList.map((data) => User(
        id: data['id'],
        username: data['username'],
        fullName: data['fullName'],
        email: data['email'],
        role: 'instructor',
        token: data['token'] ?? '',
      )).toList();
    } catch (e) {
      print('Error getting instructors: $e');
      return [];
    }
  }

  // Get all classes
  static Future<List<ClassModel>> getAllClasses() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final classesJson = prefs.getString(_classesKey) ?? '[]';
      final classesList = jsonDecode(classesJson) as List;

      return classesList.map((data) => ClassModel(
        id: data['id'],
        name: data['name'],
        subject: data['subject'] ?? 'General',
        instructor: data['instructor'] ?? data['instructorName'] ?? 'Unknown',
        startTime: data['startTime'] != null
            ? DateTime.tryParse(data['startTime']) ?? DateTime.now()
            : DateTime.now(),
        endTime: data['endTime'] != null
            ? DateTime.tryParse(data['endTime']) ?? DateTime.now().add(const Duration(hours: 2))
            : DateTime.now().add(const Duration(hours: 2)),
        room: data['room'],
        instructorName: data['instructorName'],
        studentCount: data['studentCount'],
        attendanceCount: data['attendanceCount'],
        isAttendanceOpen: data['isAttendanceOpen'] ?? false,
        status: data['status'],
      )).toList();
    } catch (e) {
      print('Error getting classes: $e');
      return [];
    }
  }

  // Add student
  static Future<bool> addStudent(User student, String password) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final studentsJson = prefs.getString(_studentsKey) ?? '[]';
      final studentsList = jsonDecode(studentsJson) as List;

      // Check if username already exists
      final existingStudent = studentsList.firstWhere(
        (s) => s['username'] == student.username,
        orElse: () => null,
      );

      if (existingStudent != null) {
        return false; // Username already exists
      }

      // Add new student
      final newStudent = {
        'id': student.id,
        'username': student.username,
        'password': password,
        'fullName': student.fullName,
        'email': student.email,
        'role': 'student',
        'token': student.token,
        'createdAt': DateTime.now().millisecondsSinceEpoch,
      };

      studentsList.add(newStudent);
      await prefs.setString(_studentsKey, jsonEncode(studentsList));

      // Also add to AuthService for regular login
      await AuthService.saveUserCredentials(student.username, password, 'student');

      return true;
    } catch (e) {
      print('Error adding student: $e');
      return false;
    }
  }

  // Add instructor
  static Future<bool> addInstructor(User instructor, String password) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final instructorsJson = prefs.getString(_instructorsKey) ?? '[]';
      final instructorsList = jsonDecode(instructorsJson) as List;

      // Check if username already exists
      final existingInstructor = instructorsList.firstWhere(
        (i) => i['username'] == instructor.username,
        orElse: () => null,
      );

      if (existingInstructor != null) {
        return false; // Username already exists
      }

      // Add new instructor
      final newInstructor = {
        'id': instructor.id,
        'username': instructor.username,
        'password': password,
        'fullName': instructor.fullName,
        'email': instructor.email,
        'role': 'instructor',
        'token': instructor.token,
        'createdAt': DateTime.now().millisecondsSinceEpoch,
      };

      instructorsList.add(newInstructor);
      await prefs.setString(_instructorsKey, jsonEncode(instructorsList));

      // Also add to AuthService for regular login
      await AuthService.saveUserCredentials(instructor.username, password, 'instructor');

      return true;
    } catch (e) {
      print('Error adding instructor: $e');
      return false;
    }
  }

  // Add class
  static Future<bool> addClass(ClassModel classModel) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final classesJson = prefs.getString(_classesKey) ?? '[]';
      final classesList = jsonDecode(classesJson) as List;

      // Add new class
      final newClass = {
        'id': classModel.id,
        'name': classModel.name,
        'subject': classModel.subject,
        'instructor': classModel.instructor,
        'startTime': classModel.startTime.toIso8601String(),
        'endTime': classModel.endTime.toIso8601String(),
        'room': classModel.room,
        'description': classModel.description,
        'isAttendanceOpen': classModel.isAttendanceOpen,
        'attendanceOpenTime': classModel.attendanceOpenTime?.toIso8601String(),
        'attendanceCloseTime': classModel.attendanceCloseTime?.toIso8601String(),
        'instructorName': classModel.instructorName ?? classModel.instructor,
        'studentCount': classModel.studentCount ?? 0,
        'attendanceCount': classModel.attendanceCount ?? 0,
        'status': classModel.status ?? 'upcoming',
        'createdAt': DateTime.now().millisecondsSinceEpoch,
      };

      classesList.add(newClass);
      await prefs.setString(_classesKey, jsonEncode(classesList));

      return true;
    } catch (e) {
      print('Error adding class: $e');
      return false;
    }
  }

  // Update student
  static Future<bool> updateStudent(User student, {String? password}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final studentsJson = prefs.getString(_studentsKey) ?? '[]';
      final studentsList = jsonDecode(studentsJson) as List;

      // Find and update student
      for (int i = 0; i < studentsList.length; i++) {
        if (studentsList[i]['id'] == student.id) {
          studentsList[i]['fullName'] = student.fullName;
          studentsList[i]['email'] = student.email;
          if (password != null) {
            studentsList[i]['password'] = password;
          }
          break;
        }
      }

      await prefs.setString(_studentsKey, jsonEncode(studentsList));
      return true;
    } catch (e) {
      print('Error updating student: $e');
      return false;
    }
  }

  // Update instructor
  static Future<bool> updateInstructor(User instructor, {String? password}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final instructorsJson = prefs.getString(_instructorsKey) ?? '[]';
      final instructorsList = jsonDecode(instructorsJson) as List;

      // Find and update instructor
      for (int i = 0; i < instructorsList.length; i++) {
        if (instructorsList[i]['id'] == instructor.id) {
          instructorsList[i]['fullName'] = instructor.fullName;
          instructorsList[i]['email'] = instructor.email;
          if (password != null) {
            instructorsList[i]['password'] = password;
          }
          break;
        }
      }

      await prefs.setString(_instructorsKey, jsonEncode(instructorsList));
      return true;
    } catch (e) {
      print('Error updating instructor: $e');
      return false;
    }
  }

  // Update class
  static Future<bool> updateClass(ClassModel classModel) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final classesJson = prefs.getString(_classesKey) ?? '[]';
      final classesList = jsonDecode(classesJson) as List;

      // Find and update class
      for (int i = 0; i < classesList.length; i++) {
        if (classesList[i]['id'] == classModel.id) {
          classesList[i] = {
            'id': classModel.id,
            'name': classModel.name,
            'subject': classModel.subject,
            'instructor': classModel.instructor,
            'startTime': classModel.startTime.toIso8601String(),
            'endTime': classModel.endTime.toIso8601String(),
            'room': classModel.room,
            'description': classModel.description,
            'isAttendanceOpen': classModel.isAttendanceOpen,
            'attendanceOpenTime': classModel.attendanceOpenTime?.toIso8601String(),
            'attendanceCloseTime': classModel.attendanceCloseTime?.toIso8601String(),
            'instructorName': classModel.instructorName ?? classModel.instructor,
            'studentCount': classModel.studentCount ?? 0,
            'attendanceCount': classModel.attendanceCount ?? 0,
            'status': classModel.status ?? 'upcoming',
            'createdAt': classesList[i]['createdAt'],
          };
          break;
        }
      }

      await prefs.setString(_classesKey, jsonEncode(classesList));
      return true;
    } catch (e) {
      print('Error updating class: $e');
      return false;
    }
  }

  // Delete student
  static Future<bool> deleteStudent(String studentId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final studentsJson = prefs.getString(_studentsKey) ?? '[]';
      final studentsList = jsonDecode(studentsJson) as List;

      studentsList.removeWhere((s) => s['id'] == studentId);
      await prefs.setString(_studentsKey, jsonEncode(studentsList));

      return true;
    } catch (e) {
      print('Error deleting student: $e');
      return false;
    }
  }

  // Delete instructor
  static Future<bool> deleteInstructor(String instructorId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final instructorsJson = prefs.getString(_instructorsKey) ?? '[]';
      final instructorsList = jsonDecode(instructorsJson) as List;

      instructorsList.removeWhere((i) => i['id'] == instructorId);
      await prefs.setString(_instructorsKey, jsonEncode(instructorsList));

      return true;
    } catch (e) {
      print('Error deleting instructor: $e');
      return false;
    }
  }

  // Delete class
  static Future<bool> deleteClass(String classId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final classesJson = prefs.getString(_classesKey) ?? '[]';
      final classesList = jsonDecode(classesJson) as List;

      classesList.removeWhere((c) => c['id'] == classId);
      await prefs.setString(_classesKey, jsonEncode(classesList));

      return true;
    } catch (e) {
      print('Error deleting class: $e');
      return false;
    }
  }

  // Get system statistics
  static Future<Map<String, int>> getSystemStatistics() async {
    try {
      final students = await getAllStudents();
      final instructors = await getAllInstructors();
      final classes = await getAllClasses();

      return {
        'students': students.length,
        'instructors': instructors.length,
        'classes': classes.length,
        'activeClasses': classes.where((c) => c.isAttendanceOpen).length,
      };
    } catch (e) {
      print('Error getting statistics: $e');
      return {
        'students': 0,
        'instructors': 0,
        'classes': 0,
        'activeClasses': 0,
      };
    }
  }

  // Check if admin exists
  static Future<bool> adminExists() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.containsKey(_adminCredentials);
    } catch (e) {
      print('Error checking admin exists: $e');
      return false;
    }
  }
}