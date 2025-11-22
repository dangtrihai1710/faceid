import 'package:equatable/equatable.dart';

class Class extends Equatable {
  final String id;
  final String name;
  final String code;
  final String? description;
  final String instructorId;
  final String instructorName;
  final String? classType; // Loại lớp: LT, TH, LT+TH
  final int? credits; // Số tín chỉ
  final String? department; // Khoa/Viện
  final String? semester; // Học kỳ: 20241, 20242, etc.
  final String? academicYear; // Năm học: 2024-2025
  final List<String> enrolledStudents;
  final int maxStudents;
  final bool isActive;
  final DateTime startDate;
  final DateTime endDate;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Class({
    required this.id,
    required this.name,
    required this.code,
    this.description,
    required this.instructorId,
    required this.instructorName,
    this.classType,
    this.credits,
    this.department,
    this.semester,
    this.academicYear,
    this.enrolledStudents = const [],
    required this.maxStudents,
    this.isActive = true,
    required this.startDate,
    required this.endDate,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Class.fromJson(Map<String, dynamic> json) {
    return Class(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['name'] ?? '',
      code: json['code'] ?? '',
      description: json['description'],
      instructorId: json['instructor_id'] ?? json['instructorId'] ?? '',
      instructorName: json['instructor_name'] ?? json['instructorName'] ?? '',
      classType: json['class_type'],
      credits: json['credits'],
      department: json['department'],
      semester: json['semester'],
      academicYear: json['academic_year'],
      enrolledStudents: List<String>.from(json['enrolled_students'] ?? json['enrolledStudents'] ?? []),
      maxStudents: json['max_students'] ?? json['maxStudents'] ?? 0,
      isActive: json['is_active'] ?? json['isActive'] ?? true,
      startDate: json['start_date'] != null
          ? DateTime.parse(json['start_date'])
          : DateTime.now(),
      endDate: json['end_date'] != null
          ? DateTime.parse(json['end_date'])
          : DateTime.now().add(const Duration(days: 90)),
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : DateTime.now(),
    );
  }

  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'code': code,
      'description': description,
      'instructor_id': instructorId,
      'instructor_name': instructorName,
      'class_type': classType,
      'credits': credits,
      'department': department,
      'semester': semester,
      'academic_year': academicYear,
      'enrolled_students': enrolledStudents,
      'max_students': maxStudents,
      'is_active': isActive,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  Class copyWith({
    String? id,
    String? name,
    String? code,
    String? description,
    String? instructorId,
    String? instructorName,
    String? classType,
    int? credits,
    String? department,
    String? semester,
    String? academicYear,
    List<String>? enrolledStudents,
    int? maxStudents,
    bool? isActive,
    DateTime? startDate,
    DateTime? endDate,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Class(
      id: id ?? this.id,
      name: name ?? this.name,
      code: code ?? this.code,
      description: description ?? this.description,
      instructorId: instructorId ?? this.instructorId,
      instructorName: instructorName ?? this.instructorName,
      classType: classType ?? this.classType,
      credits: credits ?? this.credits,
      department: department ?? this.department,
      semester: semester ?? this.semester,
      academicYear: academicYear ?? this.academicYear,
      enrolledStudents: enrolledStudents ?? this.enrolledStudents,
      maxStudents: maxStudents ?? this.maxStudents,
      isActive: isActive ?? this.isActive,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  int get enrolledCount => enrolledStudents.length;
  bool get isFull => enrolledCount >= maxStudents;
  double get enrollmentPercentage => maxStudents > 0 ? (enrolledCount / maxStudents) * 100 : 0;

  @override
  List<Object?> get props => [
        id,
        name,
        code,
        description,
        instructorId,
        instructorName,
        classType,
        credits,
        department,
        semester,
        academicYear,
        enrolledStudents,
        maxStudents,
        isActive,
        startDate,
        endDate,
        createdAt,
        updatedAt,
      ];
}

class AttendanceSession extends Equatable {
  final String id;
  final String classId;
  final String className;
  final String instructorId;
  final DateTime startTime;
  final DateTime? endTime;
  final String status; // 'active', 'completed', 'cancelled'
  final String? qrCode;
  final String? shortCode;
  final List<String> checkedInStudents;
  final Map<String, DateTime> attendanceRecords; // studentId -> timestamp
  final DateTime createdAt;

  const AttendanceSession({
    required this.id,
    required this.classId,
    required this.className,
    required this.instructorId,
    required this.startTime,
    this.endTime,
    this.status = 'active',
    this.qrCode,
    this.shortCode,
    this.checkedInStudents = const [],
    this.attendanceRecords = const {},
    required this.createdAt,
  });

  factory AttendanceSession.fromJson(Map<String, dynamic> json) {
    final recordsMap = <String, DateTime>{};
    if (json['attendance_records'] != null) {
      final records = json['attendance_records'] as Map<String, dynamic>;
      records.forEach((key, value) {
        recordsMap[key] = DateTime.parse(value);
      });
    }

    return AttendanceSession(
      id: json['_id'] ?? json['id'] ?? '',
      classId: json['class_id'] ?? '',
      className: json['class_name'] ?? json['className'] ?? '',
      instructorId: json['instructor_id'] ?? '',
      startTime: DateTime.parse(json['start_time']),
      endTime: json['end_time'] != null ? DateTime.parse(json['end_time']) : null,
      status: json['status'] ?? 'active',
      qrCode: json['qr_code'],
      shortCode: json['short_code'],
      checkedInStudents: List<String>.from(json['checked_in_students'] ?? []),
      attendanceRecords: recordsMap,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'class_id': classId,
      'class_name': className,
      'instructor_id': instructorId,
      'start_time': startTime.toIso8601String(),
      'end_time': endTime?.toIso8601String(),
      'status': status,
      'qr_code': qrCode,
      'short_code': shortCode,
      'checked_in_students': checkedInStudents,
      'attendance_records': attendanceRecords.map((key, value) => MapEntry(key, value.toIso8601String())),
      'created_at': createdAt.toIso8601String(),
    };
  }

  bool get isActive => status == 'active';
  bool get isCompleted => status == 'completed';
  bool get isCancelled => status == 'cancelled';
  int get checkedInCount => checkedInStudents.length;

  @override
  List<Object?> get props => [
        id,
        classId,
        className,
        instructorId,
        startTime,
        endTime,
        status,
        qrCode,
        shortCode,
        checkedInStudents,
        attendanceRecords,
        createdAt,
      ];
}

class AttendanceRecord extends Equatable {
  final String id;
  final String studentId;
  final String studentName;
  final String classId;
  final String className;
  final String sessionId;
  final DateTime checkInTime;
  final String status; // 'on_time', 'late', 'absent'
  final String method; // 'face', 'qr', 'code', 'manual'
  final double? confidence; // Face recognition confidence
  final String? location; // GPS location if available
  final Map<String, dynamic>? metadata;

  const AttendanceRecord({
    required this.id,
    required this.studentId,
    required this.studentName,
    required this.classId,
    required this.className,
    required this.sessionId,
    required this.checkInTime,
    required this.status,
    required this.method,
    this.confidence,
    this.location,
    this.metadata,
  });

  factory AttendanceRecord.fromJson(Map<String, dynamic> json) {
    return AttendanceRecord(
      id: json['_id'] ?? json['id'] ?? '',
      studentId: json['student_id'] ?? '',
      studentName: json['student_name'] ?? '',
      classId: json['class_id'] ?? '',
      className: json['class_name'] ?? '',
      sessionId: json['session_id'] ?? '',
      checkInTime: DateTime.parse(json['check_in_time']),
      status: json['status'] ?? '',
      method: json['method'] ?? '',
      confidence: json['confidence']?.toDouble(),
      location: json['location'],
      metadata: json['metadata'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'student_id': studentId,
      'student_name': studentName,
      'class_id': classId,
      'class_name': className,
      'session_id': sessionId,
      'check_in_time': checkInTime.toIso8601String(),
      'status': status,
      'method': method,
      'confidence': confidence,
      'location': location,
      'metadata': metadata,
    };
  }

  bool get isPresent => status != 'absent';
  bool get isOnTime => status == 'on_time';
  bool get isLate => status == 'late';
  bool get isFaceRecognition => method == 'face';

  @override
  List<Object?> get props => [
        id,
        studentId,
        studentName,
        classId,
        className,
        sessionId,
        checkInTime,
        status,
        method,
        confidence,
        location,
        metadata,
      ];
}

class CreateClassRequest extends Equatable {
  final String name;
  final String code;
  final String? description;
  final String room;
  final String schedule;
  final int maxStudents;
  final DateTime startDate;
  final DateTime endDate;

  const CreateClassRequest({
    required this.name,
    required this.code,
    this.description,
    required this.room,
    required this.schedule,
    required this.maxStudents,
    required this.startDate,
    required this.endDate,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'code': code,
      'description': description,
      'room': room,
      'schedule': schedule,
      'max_students': maxStudents,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [
        name,
        code,
        description,
        room,
        schedule,
        maxStudents,
        startDate,
        endDate,
      ];
}

class EnrollStudentsRequest extends Equatable {
  final List<String> studentIds;

  const EnrollStudentsRequest({required this.studentIds});

  Map<String, dynamic> toJson() {
    return {
      'student_ids': studentIds,
    };
  }

  @override
  List<Object?> get props => [studentIds];
}

// ===== NEW MODELS FOR SEPARATE CLASS STRUCTURE =====

// ClassSchedule - Lịch học của lớp (tách riêng)
class ClassSchedule extends Equatable {
  final String id;
  final String classId; // Foreign key to Class
  final int dayOfWeek; // 1-7 (Thứ 2 - Chủ Nhật)
  final String startTime; // "07:00"
  final String endTime; // "09:00"
  final String room;
  final String recurrencePattern; // 'weekly', 'biweekly', 'monthly'
  final DateTime startDate;
  final DateTime endDate;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ClassSchedule({
    required this.id,
    required this.classId,
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
    required this.room,
    this.recurrencePattern = 'weekly',
    required this.startDate,
    required this.endDate,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ClassSchedule.fromJson(Map<String, dynamic> json) {
    return ClassSchedule(
      id: json['_id'] ?? json['id'] ?? '',
      classId: json['class_id'] ?? '',
      dayOfWeek: json['day_of_week'] ?? 1,
      startTime: json['start_time'] ?? '',
      endTime: json['end_time'] ?? '',
      room: json['room'] ?? '',
      recurrencePattern: json['recurrence_pattern'] ?? 'weekly',
      startDate: json['start_date'] != null
          ? DateTime.parse(json['start_date'])
          : DateTime.now(),
      endDate: json['end_date'] != null
          ? DateTime.parse(json['end_date'])
          : DateTime.now().add(const Duration(days: 120)),
      isActive: json['is_active'] ?? true,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'class_id': classId,
      'day_of_week': dayOfWeek,
      'start_time': startTime,
      'end_time': endTime,
      'room': room,
      'recurrence_pattern': recurrencePattern,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate.toIso8601String(),
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // Helper method để lấy tên ngày thứ bằng tiếng Việt
  String getDayNameVietnamese() {
    switch (dayOfWeek) {
      case 1: return 'Thứ Hai';
      case 2: return 'Thứ Ba';
      case 3: return 'Thứ Tư';
      case 4: return 'Thứ Năm';
      case 5: return 'Thứ Sáu';
      case 6: return 'Thứ Bảy';
      case 7: return 'Chủ Nhật';
      default: return 'Unknown';
    }
  }

  // Helper method để format thời gian
  String get formattedTimeRange => '$startTime - $endTime';

  @override
  List<Object?> get props => [
        id,
        classId,
        dayOfWeek,
        startTime,
        endTime,
        room,
        recurrencePattern,
        startDate,
        endDate,
        isActive,
        createdAt,
        updatedAt,
      ];
}

// ClassSession - Buổi học cụ thể
class ClassSession extends Equatable {
  final String id;
  final String classId;
  final String classScheduleId; // Foreign key to ClassSchedule
  final int sessionNumber; // Buổi học thứ: 1, 2, 3...
  final DateTime date;
  final String startTime;
  final String endTime;
  final String room;
  final String? topic;
  final String? description;
  final String status; // 'planned', 'completed', 'cancelled'
  final List<String> materials; // Tài liệu buổi học
  final DateTime createdAt;
  final DateTime updatedAt;

  const ClassSession({
    required this.id,
    required this.classId,
    required this.classScheduleId,
    required this.sessionNumber,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.room,
    this.topic,
    this.description,
    this.status = 'planned',
    this.materials = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  factory ClassSession.fromJson(Map<String, dynamic> json) {
    return ClassSession(
      id: json['_id'] ?? json['id'] ?? '',
      classId: json['class_id'] ?? '',
      classScheduleId: json['class_schedule_id'] ?? '',
      sessionNumber: json['session_number'] ?? 1,
      date: DateTime.parse(json['date']),
      startTime: json['start_time'] ?? '',
      endTime: json['end_time'] ?? '',
      room: json['room'] ?? '',
      topic: json['topic'],
      description: json['description'],
      status: json['status'] ?? 'planned',
      materials: List<String>.from(json['materials'] ?? []),
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'class_id': classId,
      'class_schedule_id': classScheduleId,
      'session_number': sessionNumber,
      'date': date.toIso8601String(),
      'start_time': startTime,
      'end_time': endTime,
      'room': room,
      'topic': topic,
      'description': description,
      'status': status,
      'materials': materials,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // Helper method để format ngày tháng tiếng Việt
  String getFormattedDateVietnamese() {
    final day = date.day;
    final month = date.month;
    final year = date.year;
    final weekday = date.weekday;

    final weekdayNames = ['Thứ Hai', 'Thứ Ba', 'Thứ Tư', 'Thứ Năm', 'Thứ Sáu', 'Thứ Bảy', 'Chủ Nhật'];

    return '$day/${month.toString().padLeft(2, '0')}/$year (${weekdayNames[weekday - 1]})';
  }

  // Getters cho status
  bool get isPlanned => status == 'planned';
  bool get isCompleted => status == 'completed';
  bool get isCancelled => status == 'cancelled';

  @override
  List<Object?> get props => [
        id,
        classId,
        classScheduleId,
        sessionNumber,
        date,
        startTime,
        endTime,
        room,
        topic,
        description,
        status,
        materials,
        createdAt,
        updatedAt,
      ];
}

// AttendanceSummary - Tổng kết điểm danh của sinh viên cho lớp học
class AttendanceSummary extends Equatable {
  final String id;
  final String classId;
  final String studentId;
  final String studentName;
  final int totalSessions;
  final int attendedSessions;
  final int absentSessions;
  final int lateSessions;
  final double attendanceRate; // 0.0 - 1.0
  final DateTime lastAttendedAt;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  const AttendanceSummary({
    required this.id,
    required this.classId,
    required this.studentId,
    required this.studentName,
    required this.totalSessions,
    this.attendedSessions = 0,
    this.absentSessions = 0,
    this.lateSessions = 0,
    this.attendanceRate = 0.0,
    required this.lastAttendedAt,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  factory AttendanceSummary.fromJson(Map<String, dynamic> json) {
    return AttendanceSummary(
      id: json['_id'] ?? json['id'] ?? '',
      classId: json['class_id'] ?? '',
      studentId: json['student_id'] ?? '',
      studentName: json['student_name'] ?? '',
      totalSessions: json['total_sessions'] ?? 0,
      attendedSessions: json['attended_sessions'] ?? 0,
      absentSessions: json['absent_sessions'] ?? 0,
      lateSessions: json['late_sessions'] ?? 0,
      attendanceRate: (json['attendance_rate'] ?? 0.0).toDouble(),
      lastAttendedAt: DateTime.parse(json['last_attended_at'] ?? DateTime.now().toIso8601String()),
      notes: json['notes'],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'class_id': classId,
      'student_id': studentId,
      'student_name': studentName,
      'total_sessions': totalSessions,
      'attended_sessions': attendedSessions,
      'absent_sessions': absentSessions,
      'late_sessions': lateSessions,
      'attendance_rate': attendanceRate,
      'last_attended_at': lastAttendedAt.toIso8601String(),
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // Getters cho thống kê
  int get missedSessions => totalSessions - attendedSessions;
  double get attendancePercentage => totalSessions > 0 ? (attendedSessions / totalSessions) * 100 : 0.0;

  // Get status text
  String getAttendanceStatusText() {
    if (attendancePercentage >= 90) return 'Tốt';
    if (attendancePercentage >= 75) return 'Khá';
    if (attendancePercentage >= 60) return 'Trung bình';
    return 'Yếu';
  }

  // Get color based on attendance rate
  String getAttendanceStatusColor() {
    if (attendancePercentage >= 90) return 'green';
    if (attendancePercentage >= 75) return 'blue';
    if (attendancePercentage >= 60) return 'orange';
    return 'red';
  }

  @override
  List<Object?> get props => [
        id,
        classId,
        studentId,
        studentName,
        totalSessions,
        attendedSessions,
        absentSessions,
        lateSessions,
        attendanceRate,
        lastAttendedAt,
        notes,
        createdAt,
        updatedAt,
      ];
}