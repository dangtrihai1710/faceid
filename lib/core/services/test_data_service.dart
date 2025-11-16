import 'dart:math';
import 'package:flutter/foundation.dart';
import '../models/class_models.dart';

class TestDataService {
  static final List<Class> _testClasses = [
    Class(
      id: 'class_001',
      name: 'Lập trình Flutter Nâng cao',
      code: 'FLUTTER001',
      description: 'Khóa học phát triển ứng dụng di động với Flutter',
      instructorId: 'GV001',
      instructorName: 'Nguyễn Văn A',
      room: 'Phòng A301',
      schedule: 'Thứ 2,4,6 (7:00 - 9:00)',
      enrolledStudents: ['SV001', 'SV002', 'SV003', 'SV004', 'SV005'],
      maxStudents: 30,
      isActive: true,
      startDate: DateTime.now().subtract(const Duration(days: 30)),
      endDate: DateTime.now().add(const Duration(days: 60)),
      createdAt: DateTime.now().subtract(const Duration(days: 35)),
      updatedAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
    Class(
      id: 'class_002',
      name: 'Phát triển Web với React',
      code: 'REACT001',
      description: 'Khóa học phát triển web frontend với React.js',
      instructorId: 'GV002',
      instructorName: 'Trần Thị B',
      room: 'Phòng B205',
      schedule: 'Thứ 3,5 (14:00 - 16:30)',
      enrolledStudents: ['SV006', 'SV007', 'SV008', 'SV009', 'SV010', 'SV011'],
      maxStudents: 25,
      isActive: true,
      startDate: DateTime.now().subtract(const Duration(days: 20)),
      endDate: DateTime.now().add(const Duration(days: 70)),
      createdAt: DateTime.now().subtract(const Duration(days: 25)),
      updatedAt: DateTime.now().subtract(const Duration(days: 2)),
    ),
    Class(
      id: 'class_003',
      name: 'Machine Learning cơ bản',
      code: 'ML001',
      description: 'Khóa học học máy và trí tuệ nhân tạo',
      instructorId: 'GV003',
      instructorName: 'Lê Văn C',
      room: 'Phòng C102',
      schedule: 'Thứ 7 (8:00 - 12:00)',
      enrolledStudents: ['SV012', 'SV013', 'SV014', 'SV015'],
      maxStudents: 20,
      isActive: true,
      startDate: DateTime.now().subtract(const Duration(days: 10)),
      endDate: DateTime.now().add(const Duration(days: 80)),
      createdAt: DateTime.now().subtract(const Duration(days: 15)),
      updatedAt: DateTime.now().subtract(const Duration(days: 3)),
    ),
    Class(
      id: 'class_004',
      name: 'Database và SQL',
      code: 'DB001',
      description: 'Khóa học quản lý cơ sở dữ liệu và SQL',
      instructorId: 'GV004',
      instructorName: 'Phạm Thị D',
      room: 'Phòng D401',
      schedule: 'Thứ 2,3,4,5 (10:00 - 11:30)',
      enrolledStudents: ['SV016', 'SV017', 'SV018', 'SV019', 'SV020', 'SV021', 'SV022'],
      maxStudents: 35,
      isActive: true,
      startDate: DateTime.now().subtract(const Duration(days: 40)),
      endDate: DateTime.now().add(const Duration(days: 50)),
      createdAt: DateTime.now().subtract(const Duration(days: 45)),
      updatedAt: DateTime.now().subtract(const Duration(days: 5)),
    ),
    Class(
      id: 'class_005',
      name: 'DevOps và CI/CD',
      code: 'DEVOPS001',
      description: 'Khóa học vận hành và tích hợp liên tục',
      instructorId: 'GV005',
      instructorName: 'Hoàng Văn E',
      room: 'Phòng Lab 1',
      schedule: 'Thứ 6,7 (18:00 - 21:00)',
      enrolledStudents: ['SV023', 'SV024', 'SV025'],
      maxStudents: 15,
      isActive: true,
      startDate: DateTime.now().subtract(const Duration(days: 5)),
      endDate: DateTime.now().add(const Duration(days: 85)),
      createdAt: DateTime.now().subtract(const Duration(days: 10)),
      updatedAt: DateTime.now(),
    ),
  ];

  static final List<Map<String, dynamic>> _testStudents = [
    {
      'id': 'SV001',
      'name': 'Nguyễn Hoàng Anh',
      'email': 'anh.sv001@university.edu.vn',
      'face_data': 'face_encoding_001',
    },
    {
      'id': 'SV002',
      'name': 'Trần Thị Mai',
      'email': 'mai.sv002@university.edu.vn',
      'face_data': 'face_encoding_002',
    },
    {
      'id': 'SV003',
      'name': 'Lê Văn Nam',
      'email': 'nam.sv003@university.edu.vn',
      'face_data': 'face_encoding_003',
    },
    {
      'id': 'SV004',
      'name': 'Phạm Thị Lan',
      'email': 'lan.sv004@university.edu.vn',
      'face_data': 'face_encoding_004',
    },
    {
      'id': 'SV005',
      'name': 'Vũ Đức Hùng',
      'email': 'hung.sv005@university.edu.vn',
      'face_data': 'face_encoding_005',
    },
    {
      'id': 'SV006',
      'name': 'Đỗ Thu Hà',
      'email': 'ha.sv006@university.edu.vn',
      'face_data': 'face_encoding_006',
    },
    {
      'id': 'SV007',
      'name': 'Bùi Minh Chiến',
      'email': 'chien.sv007@university.edu.vn',
      'face_data': 'face_encoding_007',
    },
    {
      'id': 'SV008',
      'name': 'Cao Thị Dung',
      'email': 'dung.sv008@university.edu.vn',
      'face_data': 'face_encoding_008',
    },
    {
      'id': 'SV009',
      'name': 'Đặng Văn Giáp',
      'email': 'giap.sv009@university.edu.vn',
      'face_data': 'face_encoding_009',
    },
    {
      'id': 'SV010',
      'name': 'Dương Thị Hương',
      'email': 'huong.sv010@university.edu.vn',
      'face_data': 'face_encoding_010',
    },
    {
      'id': 'SV011',
      'name': 'Gia Văn Ích',
      'email': 'ich.sv011@university.edu.vn',
      'face_data': 'face_encoding_011',
    },
    {
      'id': 'SV012',
      'name': 'Hà Văn Khánh',
      'email': 'khanh.sv012@university.edu.vn',
      'face_data': 'face_encoding_012',
    },
    {
      'id': 'SV013',
      'name': 'Hoàng Thị Linh',
      'email': 'linh.sv013@university.edu.vn',
      'face_data': 'face_encoding_013',
    },
    {
      'id': 'SV014',
      'name': 'Lý Văn Mạnh',
      'email': 'manh.sv014@university.edu.vn',
      'face_data': 'face_encoding_014',
    },
    {
      'id': 'SV015',
      'name': 'Mạc Thị Ngọc',
      'email': 'ngoc.sv015@university.edu.vn',
      'face_data': 'face_encoding_015',
    },
    {
      'id': 'SV016',
      'name': 'Ngô Văn Phát',
      'email': 'phat.sv016@university.edu.vn',
      'face_data': 'face_encoding_016',
    },
    {
      'id': 'SV017',
      'name': 'Phan Thị Quỳnh',
      'email': 'quynh.sv017@university.edu.vn',
      'face_data': 'face_encoding_017',
    },
    {
      'id': 'SV018',
      'name': 'Quách Văn Rồng',
      'email': 'rong.sv018@university.edu.vn',
      'face_data': 'face_encoding_018',
    },
    {
      'id': 'SV019',
      'name': 'Sơn Thị Sen',
      'email': 'sen.sv019@university.edu.vn',
      'face_data': 'face_encoding_019',
    },
    {
      'id': 'SV020',
      'name': 'Tạ Văn Tài',
      'email': 'tai.sv020@university.edu.vn',
      'face_data': 'face_encoding_020',
    },
    {
      'id': 'SV021',
      'name': 'Tô Thị Uyên',
      'email': 'uyen.sv021@university.edu.vn',
      'face_data': 'face_encoding_021',
    },
    {
      'id': 'SV022',
      'name': 'Vũ Văn Vinh',
      'email': 'vinh.sv022@university.edu.vn',
      'face_data': 'face_encoding_022',
    },
    {
      'id': 'SV023',
      'name': 'Xuân Thị Xuân',
      'email': 'xuan.sv023@university.edu.vn',
      'face_data': 'face_encoding_023',
    },
    {
      'id': 'SV024',
      'name': 'Yên Văn Yên',
      'email': 'yen.sv024@university.edu.vn',
      'face_data': 'face_encoding_024',
    },
    {
      'id': 'SV025',
      'name': 'Ánh Thị Ánh',
      'email': 'anh.sv025@university.edu.vn',
      'face_data': 'face_encoding_025',
    },
  ];

  static final Random _random = Random();

  // Get all test classes
  static List<Class> getTestClasses() {
    return List.from(_testClasses);
  }

  // Get test class by ID
  static Class? getTestClassById(String classId) {
    try {
      return _testClasses.firstWhere((class_) => class_.id == classId);
    } catch (e) {
      return null;
    }
  }

  // Get classes for instructor
  static List<Class> getClassesForInstructor(String instructorId) {
    return _testClasses
        .where((class_) => class_.instructorId == instructorId)
        .toList();
  }

  // Get classes for student
  static List<Class> getClassesForStudent(String studentId) {
    return _testClasses
        .where((class_) => class_.enrolledStudents.contains(studentId))
        .toList();
  }

  // Get all test students
  static List<Map<String, dynamic>> getTestStudents() {
    return List.from(_testStudents);
  }

  // Get student by ID
  static Map<String, dynamic>? getStudentById(String studentId) {
    try {
      return _testStudents.firstWhere((student) => student['id'] == studentId);
    } catch (e) {
      return null;
    }
  }

  // Get students in a class
  static List<Map<String, dynamic>> getStudentsInClass(String classId) {
    final classInfo = getTestClassById(classId);
    if (classInfo == null) return [];

    return _testStudents
        .where((student) => classInfo.enrolledStudents.contains(student['id']))
        .toList();
  }

  // Generate a random attendance session for testing
  static AttendanceSession generateTestSession(String classId) {
    final classInfo = getTestClassById(classId);
    if (classInfo == null) {
      throw Exception('Class not found: $classId');
    }

    final sessionId = 'session_${DateTime.now().millisecondsSinceEpoch}';
    final timestamp = DateTime.now();

    // Generate QR code and short code
    final qrCode = _generateRandomString(12);
    final shortCode = _generateRandomString(6).toUpperCase();

    return AttendanceSession(
      id: sessionId,
      classId: classId,
      className: classInfo.name,
      instructorId: classInfo.instructorId,
      startTime: timestamp,
      status: 'active',
      qrCode: qrCode,
      shortCode: shortCode,
      checkedInStudents: [],
      attendanceRecords: {},
      createdAt: timestamp,
    );
  }

  // Generate test attendance record
  static AttendanceRecord generateTestAttendanceRecord({
    required String sessionId,
    required String studentId,
    required String classId,
    required String className,
  }) {
    final student = getStudentById(studentId);
    if (student == null) {
      throw Exception('Student not found: $studentId');
    }

    final timestamp = DateTime.now();

    // Random status for testing
    final statuses = ['on_time', 'late'];
    final status = statuses[_random.nextInt(statuses.length)];

    // Random confidence between 0.85 and 0.99
    final confidence = 0.85 + _random.nextDouble() * 0.14;

    return AttendanceRecord(
      id: 'record_${DateTime.now().millisecondsSinceEpoch}_${_random.nextInt(1000)}',
      studentId: studentId,
      studentName: student['name'],
      classId: classId,
      className: className,
      sessionId: sessionId,
      checkInTime: timestamp,
      status: status,
      method: 'face',
      confidence: confidence,
      location: 'Campus Main Building',
      metadata: {
        'device': 'mobile_app',
        'camera_quality': 'high',
        'lighting_condition': _random.nextBool() ? 'good' : 'moderate',
      },
    );
  }

  // Simulate face recognition (for testing)
  static Map<String, dynamic>? simulateFaceRecognition() {
    if (_random.nextDouble() > 0.1) { // 90% success rate for testing
      final student = _testStudents[_random.nextInt(_testStudents.length)];
      return {
        'success': true,
        'student_id': student['id'],
        'student_name': student['name'],
        'confidence': 0.85 + _random.nextDouble() * 0.14,
        'face_data': student['face_data'],
      };
    }
    return {
      'success': false,
      'message': _random.nextBool()
          ? 'Không nhận diện được khuôn mặt'
          : 'Khuôn mặt không có trong cơ sở dữ liệu',
    };
  }

  // Generate random string for QR codes and short codes
  static String _generateRandomString(int length) {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    return String.fromCharCodes(
      Iterable.generate(length, (_) => chars.codeUnitAt(_random.nextInt(chars.length))),
    );
  }

  // Initialize test data (call this when app starts for testing)
  static Future<void> initializeTestData() async {
    // In a real app, this would save data to local database or backend
    if (kDebugMode) {
      print('Test data initialized with ${_testClasses.length} classes and ${_testStudents.length} students');
    }
  }

  // Clear test data
  static void clearTestData() {
    // In a real app, this would clear local database
    if (kDebugMode) {
      print('Test data cleared');
    }
  }
}