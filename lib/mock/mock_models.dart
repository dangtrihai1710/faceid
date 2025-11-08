class User {
  final String name;
  final String role; // 'student' or 'teacher'
  final String email;
  final String id;
  final String department;
  final String avatar;

  User({
    required this.name,
    required this.role,
    required this.email,
    required this.id,
    required this.department,
    required this.avatar,
  });
}

class ClassModel {
  final String id;
  final String subject;
  final String room;
  final String time;
  final String status; // 'attended', 'missed', 'upcoming', 'ongoing'
  final String teacher;
  final List<String> students;
  final String day;

  ClassModel({
    required this.id,
    required this.subject,
    required this.room,
    required this.time,
    required this.status,
    required this.teacher,
    required this.students,
    required this.day,
  });
}

class AttendanceRecord {
  final String id;
  final String classId;
  final String studentId;
  final DateTime timestamp;
  final bool isPresent;
  final String status; // 'on_time', 'late', 'absent'

  AttendanceRecord({
    required this.id,
    required this.classId,
    required this.studentId,
    required this.timestamp,
    required this.isPresent,
    required this.status,
  });
}

class AttendanceStats {
  final int totalClasses;
  final int attendedClasses;
  final int missedClasses;
  final int lateClasses;
  final double attendanceRate;

  AttendanceStats({
    required this.totalClasses,
    required this.attendedClasses,
    required this.missedClasses,
    required this.lateClasses,
    required this.attendanceRate,
  });
}

enum UserRole {
  student,
  teacher,
}

enum AttendanceStatus {
  attended,
  missed,
  upcoming,
  ongoing,
}