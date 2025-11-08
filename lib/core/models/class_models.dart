import 'package:equatable/equatable.dart';

class Class extends Equatable {
  final String id;
  final String name;
  final String code;
  final String? description;
  final String instructorId;
  final String instructorName;
  final String room;
  final String schedule;
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
    required this.room,
    required this.schedule,
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
      room: json['room'] ?? '',
      schedule: json['schedule'] ?? '',
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
      'room': room,
      'schedule': schedule,
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
    String? room,
    String? schedule,
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
      room: room ?? this.room,
      schedule: schedule ?? this.schedule,
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
        room,
        schedule,
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