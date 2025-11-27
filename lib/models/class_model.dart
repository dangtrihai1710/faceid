class ClassModel {
  final String id;
  final String name;
  final String classType;  // "academic" or "subject"
  final String subject;
  final String instructor;
  final DateTime startTime;
  final DateTime endTime;
  final String room;
  final String? description;
  final bool isAttendanceOpen;
  final DateTime? attendanceOpenTime;
  final DateTime? attendanceCloseTime;

  // Additional fields for admin compatibility
  final String? instructorName;
  final int? studentCount;
  final int? attendanceCount;
  final String? status;
  final List<String>? studentIds; // List of enrolled student IDs
  final int? maxStudents; // Maximum capacity

  // Academic year specific fields
  final int? academicYear;
  final String? classCode;
  final int? classSequence;

  // Schedule information
  final Map<String, dynamic>? schedule;

  // Additional properties for admin screen compatibility
  final String? courseCode;
  final bool? isActive;
  final String? code;
  final String? instructorId;
  final String? department;
  final String? semester;
  final String? academicYearFull;
  final DateTime? startDate;
  final DateTime? endDate;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  ClassModel({
    required this.id,
    required this.name,
    this.classType = 'subject',
    required this.subject,
    required this.instructor,
    required this.startTime,
    required this.endTime,
    required this.room,
    this.description,
    this.isAttendanceOpen = false,
    this.attendanceOpenTime,
    this.attendanceCloseTime,
    this.instructorName,
    this.studentCount,
    this.attendanceCount,
    this.status,
    this.studentIds,
    this.maxStudents,
    this.academicYear,
    this.classCode,
    this.classSequence,
          this.schedule,
    this.courseCode,
    this.isActive,
    this.code,
    this.instructorId,
    this.department,
    this.semester,
    this.academicYearFull,
    this.startDate,
    this.endDate,
    this.createdAt,
    this.updatedAt,
  });

  factory ClassModel.fromJson(Map<String, dynamic> json) {
    return ClassModel(
      id: json['classId']?.toString() ?? json['_id']?.toString() ?? json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      classType: json['classType']?.toString() ?? json['class_type']?.toString() ?? 'subject',
      subject: json['subject']?.toString() ?? json['subjectCode']?.toString() ?? json['subject_code']?.toString() ?? '',
      instructor: json['instructor']?.toString() ?? json['instructorId']?.toString() ?? json['instructor_id']?.toString() ?? '',
      startTime: json['startTime'] != null
          ? (DateTime.tryParse(json['startTime'].toString()) ?? DateTime.now())
          : DateTime.now(),
      endTime: json['endTime'] != null
          ? (DateTime.tryParse(json['endTime'].toString()) ?? DateTime.now().add(const Duration(hours: 2)))
          : DateTime.now().add(const Duration(hours: 2)),
      room: json['room']?.toString() ?? '',
      description: json['description']?.toString(),
      isAttendanceOpen: json['isAttendanceOpen'] ?? json['is_attendance_open'] ?? false,
      attendanceOpenTime: json['attendanceOpenTime'] != null
          ? DateTime.tryParse(json['attendanceOpenTime'].toString())
          : null,
      attendanceCloseTime: json['attendanceCloseTime'] != null
          ? DateTime.tryParse(json['attendanceCloseTime'].toString())
          : null,
      instructorName: json['instructorName']?.toString() ?? json['instructor_name']?.toString(),
      studentCount: json['studentCount'] ?? json['currentStudents'] as int?,
      attendanceCount: json['attendanceCount'] as int?,
      status: json['status']?.toString(),
      studentIds: (json['studentIds'] as List<dynamic>? ?? json['student_ids'] as List<dynamic>?)?.map((e) => e.toString()).toList(),
      maxStudents: json['maxStudents'] as int?,
      academicYear: json['academicYear'] ?? json['academic_year'] as int?,
      classCode: json['classCode']?.toString() ?? json['class_code']?.toString(),
      classSequence: json['classSequence'] ?? json['class_sequence'] as int?,
      schedule: json['schedule'] as Map<String, dynamic>?,
      courseCode: json['courseCode']?.toString() ?? json['course_code']?.toString(),
      isActive: json['isActive'] ?? json['is_active'] as bool?,
      code: json['code']?.toString(),
      instructorId: json['instructorId']?.toString() ?? json['instructor_id']?.toString(),
      department: json['department']?.toString(),
      semester: json['semester']?.toString(),
      academicYearFull: json['academicYear']?.toString() ?? json['academic_year']?.toString(),
      startDate: json['startDate'] != null ? DateTime.tryParse(json['startDate'].toString()) : null,
      endDate: json['endDate'] != null ? DateTime.tryParse(json['endDate'].toString()) : null,
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt'].toString()) : null,
      updatedAt: json['updatedAt'] != null ? DateTime.tryParse(json['updatedAt'].toString()) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'classType': classType,
      'subject': subject,
      'instructor': instructor,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime.toIso8601String(),
      'room': room,
      'description': description,
      'isAttendanceOpen': isAttendanceOpen,
      'attendanceOpenTime': attendanceOpenTime?.toIso8601String(),
      'attendanceCloseTime': attendanceCloseTime?.toIso8601String(),
      'instructorName': instructorName,
      'studentCount': studentCount,
      'attendanceCount': attendanceCount,
      'status': status,
      'studentIds': studentIds,
      'maxStudents': maxStudents,
      'academicYear': academicYear,
      'classCode': classCode,
      'classSequence': classSequence,
      'schedule': schedule,
      'courseCode': courseCode,
      'isActive': isActive,
      'code': code,
      'instructorId': instructorId,
      'department': department,
      'semester': semester,
      'academic_year_full': academicYearFull,
      'startDate': startDate?.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  bool get isToday {
    final now = DateTime.now();
    return startTime.day == now.day &&
           startTime.month == now.month &&
           startTime.year == now.year;
  }

  bool get isUpcoming {
    return startTime.isAfter(DateTime.now());
  }

  bool get isOngoing {
    final now = DateTime.now();
    return now.isAfter(startTime) && now.isBefore(endTime);
  }

  bool get isCompleted {
    return endTime.isBefore(DateTime.now());
  }

  bool get isPast {
    return endTime.isBefore(DateTime.now());
  }

  String get statusText {
    if (isAttendanceOpen) return 'Đang điểm danh';
    if (isOngoing) return 'Đang diễn ra';
    if (isUpcoming && isToday) return 'Sắp diễn ra';
    if (isUpcoming) return 'Sắp tới';
    return 'Đã kết thúc';
  }

  String get timeRange {
    return '${_formatTime(startTime)} - ${_formatTime(endTime)}';
  }

  String get attendanceStatusText {
    if (isAttendanceOpen) {
      return 'Mở điểm danh';
    } else if (isOngoing) {
      return 'Chưa mở điểm danh';
    } else if (isCompleted) {
      return 'Đã đóng điểm danh';
    } else {
      return 'Chưa bắt đầu';
    }
  }

  bool get canOpenAttendance {
    return isOngoing && !isAttendanceOpen;
  }

  bool get canCloseAttendance {
    return isAttendanceOpen;
  }

  ClassModel copyWith({
    String? id,
    String? name,
    String? classType,
    String? subject,
    String? instructor,
    DateTime? startTime,
    DateTime? endTime,
    String? room,
    String? description,
    bool? isAttendanceOpen,
    DateTime? attendanceOpenTime,
    DateTime? attendanceCloseTime,
    String? instructorName,
    int? studentCount,
    int? attendanceCount,
    String? status,
    List<String>? studentIds,
    int? maxStudents,
    int? academicYear,
    String? classCode,
    int? classSequence,
    Map<String, dynamic>? schedule,
    String? courseCode,
    bool? isActive,
    String? code,
    String? instructorId,
    String? department,
    String? semester,
    String? academicYearFull,
    DateTime? startDate,
    DateTime? endDate,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ClassModel(
      id: id ?? this.id,
      name: name ?? this.name,
      classType: classType ?? this.classType,
      subject: subject ?? this.subject,
      instructor: instructor ?? this.instructor,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      room: room ?? this.room,
      description: description ?? this.description,
      isAttendanceOpen: isAttendanceOpen ?? this.isAttendanceOpen,
      attendanceOpenTime: attendanceOpenTime ?? this.attendanceOpenTime,
      attendanceCloseTime: attendanceCloseTime ?? this.attendanceCloseTime,
      instructorName: instructorName ?? this.instructorName,
      studentCount: studentCount ?? this.studentCount,
      attendanceCount: attendanceCount ?? this.attendanceCount,
      status: status ?? this.status,
      studentIds: studentIds ?? this.studentIds,
      maxStudents: maxStudents ?? this.maxStudents,
      academicYear: academicYear ?? this.academicYear,
      classCode: classCode ?? this.classCode,
      classSequence: classSequence ?? this.classSequence,
      schedule: schedule ?? this.schedule,
    courseCode: courseCode ?? this.courseCode,
    isActive: isActive ?? this.isActive,
    code: code ?? this.code,
    instructorId: instructorId ?? this.instructorId,
    department: department ?? this.department,
    semester: semester ?? this.semester,
    academicYearFull: academicYearFull ?? this.academicYearFull,
    startDate: startDate ?? this.startDate,
    endDate: endDate ?? this.endDate,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  // Additional getters for admin compatibility
  String get displayInstructorName => instructorName ?? instructor;
  int get displayStudentCount => studentCount ?? 0;
  int get displayAttendanceCount => attendanceCount ?? 0;
  String get displayStatus => status ?? (isCompleted ? 'completed' : isOngoing ? 'ongoing' : 'upcoming');

  // Two-tier class structure getters
  String get displayName {
    if (classType == 'academic') {
      return name;  // Already in format like "25ABC1"
    } else {
      return '$name - $subject';  // e.g., "Lập trình - LAP101"
    }
  }

  bool get isAcademicClass => classType == 'academic';
  bool get isSubjectClass => classType == 'subject';

  String get formattedClassName {
    if (isAcademicClass && academicYear != null && classCode != null && classSequence != null) {
      return '$academicYear$classCode$classSequence';  // e.g., "25ABC1"
    }
    return name;
  }

  @override
  String toString() {
    return 'ClassModel(id: $id, name: $name, classType: $classType, subject: $subject, attendanceOpen: $isAttendanceOpen)';
  }
}