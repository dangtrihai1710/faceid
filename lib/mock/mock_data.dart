import 'mock_models.dart';

class MockData {
  // Mock Users
  static final User studentUser = User(
    name: "Nguyễn Văn An",
    role: "student",
    email: "an.nv@student.edu.vn",
    id: "ST2024001",
    department: "Công nghệ thông tin",
    avatar: "👨‍🎓",
  );

  static final User teacherUser = User(
    name: "Trần Thị Bình",
    role: "teacher",
    email: "binh.tt@teacher.edu.vn",
    id: "TC2024001",
    department: "Công nghệ thông tin",
    avatar: "👩‍🏫",
  );

  // Mock Classes for Students
  static final List<ClassModel> studentClasses = [
    ClassModel(
      id: "CLASS001",
      subject: "Phát triển ứng dụng di động",
      room: "A203",
      time: "8:00 - 9:30",
      status: "upcoming",
      teacher: "ThS. Trần Thị Bình",
      students: [],
      day: "Thứ Hai",
    ),
    ClassModel(
      id: "CLASS002",
      subject: "Cấu trúc dữ liệu và giải thuật",
      room: "B105",
      time: "10:00 - 11:30",
      status: "attended",
      teacher: "PGS. TS. Lê Văn Cường",
      students: [],
      day: "Thứ Hai",
    ),
    ClassModel(
      id: "CLASS003",
      subject: "Lập trình hướng đối tượng",
      room: "C301",
      time: "13:30 - 15:00",
      status: "missed",
      teacher: "TS. Phạm Thị Dung",
      students: [],
      day: "Thứ Ba",
    ),
    ClassModel(
      id: "CLASS004",
      subject: "Cơ sở dữ liệu",
      room: "D204",
      time: "15:30 - 17:00",
      status: "attended",
      teacher: "ThS. Hoàng Văn Em",
      students: [],
      day: "Thứ Ba",
    ),
    ClassModel(
      id: "CLASS005",
      subject: "Mạng máy tính",
      room: "A203",
      time: "8:00 - 9:30",
      status: "upcoming",
      teacher: "TS. Nguyễn Thị Phương",
      students: [],
      day: "Thứ Tư",
    ),
  ];

  // Mock Classes for Teachers
  static final List<ClassModel> teacherClasses = [
    ClassModel(
      id: "CLASS001",
      subject: "Phát triển ứng dụng di động",
      room: "A203",
      time: "8:00 - 9:30",
      status: "ongoing",
      teacher: "ThS. Trần Thị Bình",
      students: ["ST2024001", "ST2024002", "ST2024003", "ST2024004", "ST2024005"],
      day: "Thứ Hai",
    ),
    ClassModel(
      id: "CLASS006",
      subject: "Lập trình Java",
      room: "B205",
      time: "10:00 - 11:30",
      status: "upcoming",
      teacher: "ThS. Trần Thị Bình",
      students: ["ST2024006", "ST2024007", "ST2024008", "ST2024009"],
      day: "Thứ Hai",
    ),
    ClassModel(
      id: "CLASS007",
      subject: "Tích hợp hệ thống",
      room: "C302",
      time: "13:30 - 15:00",
      status: "upcoming",
      teacher: "ThS. Trần Thị Bình",
      students: ["ST2024010", "ST2024011", "ST2024012", "ST2024013", "ST2024014"],
      day: "Thứ Tư",
    ),
    ClassModel(
      id: "CLASS008",
      subject: "Thực tập doanh nghiệp",
      room: "Lab A1",
      time: "15:30 - 17:00",
      status: "upcoming",
      teacher: "ThS. Trần Thị Bình",
      students: ["ST2024015", "ST2024016", "ST2024017", "ST2024018"],
      day: "Thứ Năm",
    ),
  ];

  // Mock Attendance Records
  static final List<AttendanceRecord> attendanceRecords = [
    AttendanceRecord(
      id: "ATT001",
      classId: "CLASS002",
      studentId: "ST2024001",
      timestamp: DateTime.now().subtract(Duration(hours: 2)),
      isPresent: true,
      status: "on_time",
    ),
    AttendanceRecord(
      id: "ATT002",
      classId: "CLASS004",
      studentId: "ST2024001",
      timestamp: DateTime.now().subtract(Duration(days: 1)),
      isPresent: true,
      status: "late",
    ),
    AttendanceRecord(
      id: "ATT003",
      classId: "CLASS003",
      studentId: "ST2024001",
      timestamp: DateTime.now().subtract(Duration(days: 2)),
      isPresent: false,
      status: "absent",
    ),
  ];

  // Mock Attendance Stats
  static final AttendanceStats studentStats = AttendanceStats(
    totalClasses: 20,
    attendedClasses: 16,
    missedClasses: 3,
    lateClasses: 1,
    attendanceRate: 80.0,
  );

  static final AttendanceStats teacherStats = AttendanceStats(
    totalClasses: 15,
    attendedClasses: 15,
    missedClasses: 0,
    lateClasses: 0,
    attendanceRate: 100.0,
  );

  // Helper methods
  static User getCurrentUser(String role) {
    return role == 'student' ? studentUser : teacherUser;
  }

  static List<ClassModel> getClassesForUser(String role) {
    return role == 'student' ? studentClasses : teacherClasses;
  }

  static List<ClassModel> getTodayClasses(String role) {
    final allClasses = getClassesForUser(role);
    final today = DateTime.now().weekday;

    // Map weekday to Vietnamese day names
    final dayMap = {
      1: "Thứ Hai",
      2: "Thứ Ba",
      3: "Thứ Tư",
      4: "Thứ Năm",
      5: "Thứ Sáu",
      6: "Thứ Bảy",
      7: "Chủ Nhật",
    };

    final todayName = dayMap[today] ?? "Thứ Hai";
    return allClasses.where((classItem) => classItem.day == todayName).toList();
  }

  static String getCurrentClassTime() {
    final now = DateTime.now();
    final hour = now.hour;

    if (hour >= 7 && hour < 9) {
      return "8:00 - 9:30";
    } else if (hour >= 9 && hour < 11) {
      return "10:00 - 11:30";
    } else if (hour >= 13 && hour < 15) {
      return "13:30 - 15:00";
    } else if (hour >= 15 && hour < 17) {
      return "15:30 - 17:00";
    }
    return "8:00 - 9:30"; // Default
  }
}