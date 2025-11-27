enum AttendanceStatus {
  present,
  absent,
  late,
  excused,
  unknown,
}

class AttendanceModel {
  final String id;
  final String classId;
  final String studentId;
  final DateTime timestamp;
  final AttendanceStatus status;
  final String method; // faceid, qr_code, manual
  final String? location;
  final Map<String, dynamic>? verificationData;
  final DateTime checkInTime;
  final DateTime? checkOutTime;
  final String? notes;

  AttendanceModel({
    required this.id,
    required this.classId,
    required this.studentId,
    required this.timestamp,
    required this.status,
    required this.method,
    this.location,
    this.verificationData,
    required this.checkInTime,
    this.checkOutTime,
    this.notes,
  });

  factory AttendanceModel.fromJson(Map<String, dynamic> json) {
    return AttendanceModel(
      id: json['_id'] ?? json['id'] ?? '',
      classId: json['class_id'] ?? '',
      studentId: json['student_id'] ?? '',
      timestamp: DateTime.parse(json['timestamp'] ?? DateTime.now().toIso8601String()),
      status: _parseStatus(json['status'] ?? 'present'),
      method: json['method'] ?? 'manual',
      location: json['location'],
      verificationData: json['verification_data'],
      checkInTime: DateTime.parse(json['check_in_time'] ?? json['timestamp'] ?? DateTime.now().toIso8601String()),
      checkOutTime: json['check_out_time'] != null ? DateTime.parse(json['check_out_time']) : null,
      notes: json['notes'],
    );
  }

  static AttendanceStatus _parseStatus(String status) {
    switch (status.toLowerCase()) {
      case 'present':
        return AttendanceStatus.present;
      case 'absent':
        return AttendanceStatus.absent;
      case 'late':
        return AttendanceStatus.late;
      case 'excused':
        return AttendanceStatus.excused;
      default:
        return AttendanceStatus.present;
    }
  }

  String get statusText {
    switch (status) {
      case AttendanceStatus.present:
        return 'Có mặt';
      case AttendanceStatus.absent:
        return 'Vắng mặt';
      case AttendanceStatus.late:
        return 'Đi muộn';
      case AttendanceStatus.excused:
        return 'Có phép';
      case AttendanceStatus.unknown:
        return 'Chưa xác định';
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'class_id': classId,
      'student_id': studentId,
      'timestamp': timestamp.toIso8601String(),
      'status': status.name,
      'method': method,
      'location': location,
      'verification_data': verificationData,
      'check_in_time': checkInTime.toIso8601String(),
      'check_out_time': checkOutTime?.toIso8601String(),
      'notes': notes,
    };
  }

  // Additional getters for admin screen compatibility
  String get userId => studentId; // Alias for studentId

  String get formattedCheckInTime {
    return '${checkInTime.hour.toString().padLeft(2, '0')}:${checkInTime.minute.toString().padLeft(2, '0')}';
  }

  String get statusColor {
    switch (status) {
      case AttendanceStatus.present:
        return 'green';
      case AttendanceStatus.absent:
        return 'red';
      case AttendanceStatus.late:
        return 'orange';
      case AttendanceStatus.excused:
        return 'blue';
      case AttendanceStatus.unknown:
        return 'grey';
    }
  }
}