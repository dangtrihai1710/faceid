import 'package:flutter/material.dart';

class FaceModel {
  final String id;
  final String userId;
  final String? photoPath;
  final DateTime enrolledAt;
  final bool isActive;
  final String? description;
  final Map<String, dynamic>? faceFeatures; // For storing face recognition features

  FaceModel({
    required this.id,
    required this.userId,
    this.photoPath,
    required this.enrolledAt,
    this.isActive = true,
    this.description,
    this.faceFeatures,
  });

  factory FaceModel.fromJson(Map<String, dynamic> json) {
    return FaceModel(
      id: json['id']?.toString() ?? '',
      userId: json['userId']?.toString() ?? '',
      photoPath: json['photoPath']?.toString(),
      enrolledAt: DateTime.tryParse(json['enrolledAt'].toString()) ?? DateTime.now(),
      isActive: json['isActive'] ?? true,
      description: json['description']?.toString(),
      faceFeatures: json['faceFeatures'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'photoPath': photoPath,
      'enrolledAt': enrolledAt.toIso8601String(),
      'isActive': isActive,
      'description': description,
      'faceFeatures': faceFeatures,
    };
  }

  String get formattedEnrolledAt {
    return '${enrolledAt.day}/${enrolledAt.month}/${enrolledAt.year} ${enrolledAt.hour.toString().padLeft(2, '0')}:${enrolledAt.minute.toString().padLeft(2, '0')}';
  }

  String get statusText {
    return isActive ? 'Đã đăng ký' : 'Đã vô hiệu hóa';
  }

  Color get statusColor {
    return isActive ? Colors.green : Colors.grey;
  }

  @override
  String toString() {
    return 'FaceModel(id: $id, userId: $userId, enrolledAt: $enrolledAt)';
  }
}

enum EnrollmentStep {
  initial,
  capture,
  processing,
  success,
  error,
}

class EnrollmentState {
  final EnrollmentStep step;
  final String? message;
  final String? photoPath;
  final int? currentCapture;
  final int? totalCaptures;

  const EnrollmentState({
    required this.step,
    this.message,
    this.photoPath,
    this.currentCapture,
    this.totalCaptures,
  });

  EnrollmentState copyWith({
    EnrollmentStep? step,
    String? message,
    String? photoPath,
    int? currentCapture,
    int? totalCaptures,
  }) {
    return EnrollmentState(
      step: step ?? this.step,
      message: message ?? this.message,
      photoPath: photoPath ?? this.photoPath,
      currentCapture: currentCapture ?? this.currentCapture,
      totalCaptures: totalCaptures ?? this.totalCaptures,
    );
  }

  @override
  String toString() {
    return 'EnrollmentState(step: $step, message: $message)';
  }
}