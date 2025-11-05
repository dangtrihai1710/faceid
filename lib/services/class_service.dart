import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/class_model.dart';
import '../models/attendance_model.dart';

class ClassService {
  static const String _classesKey = 'scheduled_classes';
  static const String _attendanceKey = 'attendance_records';

  // Get scheduled classes from local storage
  static Future<List<ClassModel>> getClasses() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final classesJson = prefs.getString(_classesKey) ?? '[]';
      final List<dynamic> classesList = jsonDecode(classesJson);

      return classesList
          .map((json) => ClassModel.fromJson(json))
          .toList()
        ..sort((a, b) => a.startTime.compareTo(b.startTime));
    } catch (e) {
      print('Error getting classes: $e');
      return _getDemoClasses();
    }
  }

  // Get demo classes for testing
  static List<ClassModel> _getDemoClasses() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    return [
      ClassModel(
        id: 'class_1',
        name: 'Lập trình Flutter',
        subject: 'Mobile Development',
        instructor: 'Nguyễn Văn A',
        startTime: today.add(const Duration(hours: 8, minutes: 30)),
        endTime: today.add(const Duration(hours: 10, minutes: 15)),
        room: 'Phòng 201',
        description: 'Học về widgets và state management',
      ),
      ClassModel(
        id: 'class_2',
        name: 'Cơ sở dữ liệu SQL',
        subject: 'Database',
        instructor: 'Trần Thị B',
        startTime: today.add(const Duration(hours: 10, minutes: 30)),
        endTime: today.add(const Duration(hours: 12, minutes: 15)),
        room: 'Phòng 303',
        description: 'SQL queries và database design',
      ),
      ClassModel(
        id: 'class_3',
        name: 'UI/UX Design',
        subject: 'Design',
        instructor: 'Lê Văn C',
        startTime: today.add(const Duration(hours: 13, minutes: 30)),
        endTime: today.add(const Duration(hours: 15, minutes: 15)),
        room: 'Phòng Lab 1',
        description: 'Thiết kế giao diện người dùng',
      ),
      ClassModel(
        id: 'class_4',
        name: 'Python cho Data Science',
        subject: 'Programming',
        instructor: 'Phạm Thị D',
        startTime: today.add(const Duration(days: 1, hours: 8, minutes: 30)),
        endTime: today.add(const Duration(days: 1, hours: 10, minutes: 15)),
        room: 'Phòng 405',
        description: 'Python, Pandas, NumPy',
      ),
      ClassModel(
        id: 'class_5',
        name: 'React Development',
        subject: 'Web Development',
        instructor: 'Hoàng Văn E',
        startTime: today.add(const Duration(days: 1, hours: 14, minutes: 0)),
        endTime: today.add(const Duration(days: 1, hours: 15, minutes: 45)),
        room: 'Phòng Lab 2',
        description: 'React hooks và state management',
      ),
    ];
  }

  // Get upcoming classes
  static Future<List<ClassModel>> getUpcomingClasses() async {
    try {
      final classes = await getClasses();
      final now = DateTime.now();
      return classes
          .where((cls) => cls.isUpcoming || cls.isOngoing)
          .take(5)
          .toList();
    } catch (e) {
      print('Error getting upcoming classes: $e');
      return [];
    }
  }

  // Get today's classes
  static Future<List<ClassModel>> getTodayClasses() async {
    try {
      final classes = await getClasses();
      return classes.where((cls) => cls.isToday).toList();
    } catch (e) {
      print('Error getting today classes: $e');
      return [];
    }
  }

  // Save classes to local storage
  static Future<void> saveClasses(List<ClassModel> classes) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final classesJson = jsonEncode(classes.map((c) => c.toJson()).toList());
      await prefs.setString(_classesKey, classesJson);
      print('Classes saved successfully');
    } catch (e) {
      print('Error saving classes: $e');
      throw Exception('Lỗi khi lưu danh sách lớp học');
    }
  }

  // Get attendance records for a user
  static Future<List<AttendanceModel>> getAttendanceRecords(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final attendanceJson = prefs.getString(_attendanceKey) ?? '[]';
      final List<dynamic> attendanceList = jsonDecode(attendanceJson);

      return attendanceList
          .map((json) => AttendanceModel.fromJson(json))
          .where((record) => record.userId == userId)
          .toList()
        ..sort((a, b) => b.checkInTime.compareTo(a.checkInTime));
    } catch (e) {
      print('Error getting attendance records: $e');
      return _getDemoAttendanceRecords(userId);
    }
  }

  // Get demo attendance records
  static List<AttendanceModel> _getDemoAttendanceRecords(String userId) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    return [
      AttendanceModel(
        id: 'att_1',
        classId: 'class_1',
        userId: userId,
        checkInTime: today.subtract(const Duration(days: 1, hours: 1)),
        checkOutTime: today.subtract(const Duration(days: 1, hours: -1)),
        status: AttendanceStatus.present,
        latitude: 10.8425,
        longitude: 106.7821,
      ),
      AttendanceModel(
        id: 'att_2',
        classId: 'class_2',
        userId: userId,
        checkInTime: today.subtract(const Duration(days: 1, hours: 4)),
        checkOutTime: today.subtract(const Duration(days: 1, hours: 2)),
        status: AttendanceStatus.late,
        latitude: 10.8425,
        longitude: 106.7821,
      ),
      AttendanceModel(
        id: 'att_3',
        classId: 'class_3',
        userId: userId,
        checkInTime: today.subtract(const Duration(days: 2, hours: 2)),
        status: AttendanceStatus.excused,
        latitude: 10.8425,
        longitude: 106.7821,
        notes: 'Đi công tác',
      ),
    ];
  }

  // Save attendance record
  static Future<void> saveAttendanceRecord(AttendanceModel attendance) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final attendanceJson = prefs.getString(_attendanceKey) ?? '[]';
      final List<dynamic> attendanceList = jsonDecode(attendanceJson);

      attendanceList.add(attendance.toJson());

      await prefs.setString(_attendanceKey, jsonEncode(attendanceList));
      print('Attendance record saved successfully');
    } catch (e) {
      print('Error saving attendance record: $e');
      throw Exception('Lỗi khi lưu bản ghi điểm danh');
    }
  }

  // Get attendance statistics
  static Future<Map<String, int>> getAttendanceStats(String userId) async {
    try {
      final records = await getAttendanceRecords(userId);
      final stats = <String, int>{
        'present': 0,
        'late': 0,
        'absent': 0,
        'excused': 0,
        'total': 0,
      };

      for (final record in records) {
        stats['total'] = (stats['total'] ?? 0) + 1;
        switch (record.status) {
          case AttendanceStatus.present:
            stats['present'] = (stats['present'] ?? 0) + 1;
            break;
          case AttendanceStatus.late:
            stats['late'] = (stats['late'] ?? 0) + 1;
            break;
          case AttendanceStatus.absent:
            stats['absent'] = (stats['absent'] ?? 0) + 1;
            break;
          case AttendanceStatus.excused:
            stats['excused'] = (stats['excused'] ?? 0) + 1;
            break;
          case AttendanceStatus.unknown:
            break;
        }
      }

      return stats;
    } catch (e) {
      print('Error getting attendance stats: $e');
      return {
        'present': 0,
        'late': 0,
        'absent': 0,
        'excused': 0,
        'total': 0,
      };
    }
  }

  // Get attendance rate
  static Future<double> getAttendanceRate(String userId) async {
    try {
      final stats = await getAttendanceStats(userId);
      final total = stats['total'] ?? 0;
      final present = (stats['present'] ?? 0) + (stats['late'] ?? 0) + (stats['excused'] ?? 0);

      if (total == 0) return 0.0;
      return (present / total) * 100;
    } catch (e) {
      print('Error calculating attendance rate: $e');
      return 0.0;
    }
  }

  // Update class information
  static Future<void> updateClass(ClassModel classModel) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final classesJson = prefs.getString(_classesKey) ?? '[]';
      final List<dynamic> classesList = jsonDecode(classesJson);

      final index = classesList.indexWhere(
        (classJson) => classJson['id'] == classModel.id,
      );

      if (index != -1) {
        classesList[index] = classModel.toJson();
        await prefs.setString(_classesKey, jsonEncode(classesList));
        print('Class updated successfully');
      } else {
        print('Class not found for update');
      }
    } catch (e) {
      print('Error updating class: $e');
      throw Exception('Lỗi khi cập nhật thông tin lớp học');
    }
  }

  // Get attendance records for a specific class
  static Future<List<AttendanceModel>> getAttendanceRecordsByClass(String classId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final attendanceJson = prefs.getString(_attendanceKey) ?? '[]';
      final List<dynamic> attendanceList = jsonDecode(attendanceJson);

      return attendanceList
          .map((json) => AttendanceModel.fromJson(json))
          .where((attendance) => attendance.classId == classId)
          .toList()
        ..sort((a, b) => b.checkInTime.compareTo(a.checkInTime));
    } catch (e) {
      print('Error getting attendance records for class: $e');
      return [];
    }
  }

  // Get all attendance records (for instructors/reports)
  static Future<List<AttendanceModel>> getAllAttendanceRecords() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final attendanceJson = prefs.getString(_attendanceKey) ?? '[]';
      final List<dynamic> attendanceList = jsonDecode(attendanceJson);

      return attendanceList
          .map((json) => AttendanceModel.fromJson(json))
          .toList()
        ..sort((a, b) => b.checkInTime.compareTo(a.checkInTime));
    } catch (e) {
      print('Error getting all attendance records: $e');
      return [];
    }
  }

  // Get class by ID
  static Future<ClassModel?> getClassById(String classId) async {
    try {
      final classes = await getClasses();
      return classes.firstWhere(
        (cls) => cls.id == classId,
        orElse: () => throw Exception('Class not found'),
      );
    } catch (e) {
      print('Error getting class by ID: $e');
      return null;
    }
  }
}