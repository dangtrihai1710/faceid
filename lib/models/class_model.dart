class ClassModel {
  final String id;
  final String name;
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

  ClassModel({
    required this.id,
    required this.name,
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
  });

  factory ClassModel.fromJson(Map<String, dynamic> json) {
    return ClassModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      subject: json['subject']?.toString() ?? '',
      instructor: json['instructor']?.toString() ?? '',
      startTime: DateTime.tryParse(json['startTime'].toString()) ?? DateTime.now(),
      endTime: DateTime.tryParse(json['endTime'].toString()) ?? DateTime.now(),
      room: json['room']?.toString() ?? '',
      description: json['description']?.toString(),
      isAttendanceOpen: json['isAttendanceOpen'] ?? false,
      attendanceOpenTime: json['attendanceOpenTime'] != null
          ? DateTime.tryParse(json['attendanceOpenTime'].toString())
          : null,
      attendanceCloseTime: json['attendanceCloseTime'] != null
          ? DateTime.tryParse(json['attendanceCloseTime'].toString())
          : null,
      instructorName: json['instructorName']?.toString(),
      studentCount: json['studentCount'] as int?,
      attendanceCount: json['attendanceCount'] as int?,
      status: json['status']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
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
  }) {
    return ClassModel(
      id: id ?? this.id,
      name: name ?? this.name,
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

  @override
  String toString() {
    return 'ClassModel(id: $id, name: $name, subject: $subject, attendanceOpen: $isAttendanceOpen)';
  }
}