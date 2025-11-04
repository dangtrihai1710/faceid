import 'package:flutter/material.dart';

class AttendanceModel {
  final String id;
  final String classId;
  final String userId;
  final DateTime checkInTime;
  final DateTime? checkOutTime;
  final String? photoPath;
  final double? latitude;
  final double? longitude;
  final AttendanceStatus status;
  final String? notes;

  AttendanceModel({
    required this.id,
    required this.classId,
    required this.userId,
    required this.checkInTime,
    this.checkOutTime,
    this.photoPath,
    this.latitude,
    this.longitude,
    required this.status,
    this.notes,
  });

  factory AttendanceModel.fromJson(Map<String, dynamic> json) {
    return AttendanceModel(
      id: json['id']?.toString() ?? '',
      classId: json['classId']?.toString() ?? '',
      userId: json['userId']?.toString() ?? '',
      checkInTime: DateTime.tryParse(json['checkInTime'].toString()) ?? DateTime.now(),
      checkOutTime: json['checkOutTime'] != null
          ? DateTime.tryParse(json['checkOutTime'].toString())
          : null,
      photoPath: json['photoPath']?.toString(),
      latitude: json['latitude']?.toDouble(),
      longitude: json['longitude']?.toDouble(),
      status: AttendanceStatus.values.firstWhere(
        (s) => s.toString() == 'AttendanceStatus.${json['status']}',
        orElse: () => AttendanceStatus.unknown,
      ),
      notes: json['notes']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'classId': classId,
      'userId': userId,
      'checkInTime': checkInTime.toIso8601String(),
      'checkOutTime': checkOutTime?.toIso8601String(),
      'photoPath': photoPath,
      'latitude': latitude,
      'longitude': longitude,
      'status': status.toString().split('.').last,
      'notes': notes,
    };
  }

  String get statusText {
    switch (status) {
      case AttendanceStatus.present:
        return 'Có mặt';
      case AttendanceStatus.late:
        return 'Đi muộn';
      case AttendanceStatus.absent:
        return 'Vắng mặt';
      case AttendanceStatus.excused:
        return 'Có phép';
      case AttendanceStatus.unknown:
      default:
        return 'Chưa xác định';
    }
  }

  Color get statusColor {
    switch (status) {
      case AttendanceStatus.present:
        return const Color(0xFF4CAF50); // Green
      case AttendanceStatus.late:
        return const Color(0xFFFF9800); // Orange
      case AttendanceStatus.absent:
        return const Color(0xFFF44336); // Red
      case AttendanceStatus.excused:
        return const Color(0xFF2196F3); // Blue
      case AttendanceStatus.unknown:
      default:
        return const Color(0xFF9E9E9E); // Grey
    }
  }

  Duration? get duration {
    if (checkOutTime == null) return null;
    return checkOutTime!.difference(checkInTime);
  }

  String get formattedCheckInTime {
    return '${checkInTime.hour.toString().padLeft(2, '0')}:${checkInTime.minute.toString().padLeft(2, '0')}';
  }

  String? get formattedCheckOutTime {
    if (checkOutTime == null) return null;
    return '${checkOutTime!.hour.toString().padLeft(2, '0')}:${checkOutTime!.minute.toString().padLeft(2, '0')}';
  }

  @override
  String toString() {
    return 'AttendanceModel(id: $id, status: $status, checkInTime: $checkInTime)';
  }
}

enum AttendanceStatus {
  present,
  late,
  absent,
  excused,
  unknown,
}