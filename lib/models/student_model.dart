import 'user.dart';

class StudentModel {
  final String id;
  final String userId;
  final String fullName;
  final String email;
  final String? phone;
  final String? avatar;
  final String? studentId;
  final String role;

  StudentModel({
    required this.id,
    required this.userId,
    required this.fullName,
    required this.email,
    this.phone,
    this.avatar,
    this.studentId,
    this.role = 'student',
  });

  factory StudentModel.fromJson(Map<String, dynamic> json) {
    return StudentModel(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? json['userId']?.toString() ?? '',
      fullName: json['full_name'] ?? json['fullName'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'],
      avatar: json['avatar'],
      studentId: json['student_id'] ?? json['studentId'],
      role: json['role'] ?? 'student',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'full_name': fullName,
      'email': email,
      'phone': phone,
      'avatar': avatar,
      'student_id': studentId,
      'role': role,
    };
  }

  // Create from User model
  factory StudentModel.fromUser(User user) {
    return StudentModel(
      id: user.id,
      userId: user.userId,
      fullName: user.fullName,
      email: user.email,
      phone: user.phone,
      avatar: user.avatar,
      studentId: user.studentId,
      role: user.role,
    );
  }

  // Convert to User model
  User toUser() {
    return User(
      id: id,
      userId: userId,
      email: email,
      fullName: fullName,
      phone: phone,
      token: '',
      role: role,
      studentId: studentId,
      avatar: avatar,
    );
  }

  @override
  String toString() {
    return 'StudentModel(userId: $userId, fullName: $fullName, email: $email, role: $role)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is StudentModel && other.userId == userId;
  }

  @override
  int get hashCode => userId.hashCode;
}