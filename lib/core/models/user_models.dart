import 'package:equatable/equatable.dart';

class User extends Equatable {
  final String id;
  final String userCode;
  final String fullName;
  final String email;
  final String role;
  final String? department;
  final String? avatar;
  final bool isActive;
  final DateTime? lastLogin;
  final DateTime createdAt;
  final DateTime updatedAt;

  const User({
    required this.id,
    required this.userCode,
    required this.fullName,
    required this.email,
    required this.role,
    this.department,
    this.avatar,
    this.isActive = true,
    this.lastLogin,
    required this.createdAt,
    required this.updatedAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    // Handle both backend and local field name variations
    final userId = json['_id'] ?? json['id'] ?? json['userId'] ?? '';
    final userCode = json['user_id'] ?? json['userCode'] ?? json['userId'] ?? '';
    final fullName = json['full_name'] ?? json['fullName'] ?? '';
    final email = json['email'] ?? '';
    final role = json['role'] ?? '';
    final isActive = json['is_active'] ?? json['isActive'] ?? true;

    DateTime createdAt = DateTime.now();
    try {
      if (json['created_at'] != null) {
        createdAt = DateTime.parse(json['created_at']);
      } else if (json['createdAt'] != null) {
        createdAt = DateTime.parse(json['createdAt']);
      }
    } catch (e) {
      createdAt = DateTime.now();
    }

    DateTime updatedAt = DateTime.now();
    try {
      if (json['updated_at'] != null) {
        updatedAt = DateTime.parse(json['updated_at']);
      } else if (json['updatedAt'] != null) {
        updatedAt = DateTime.parse(json['updatedAt']);
      }
    } catch (e) {
      updatedAt = DateTime.now();
    }

    return User(
      id: userId,
      userCode: userCode,
      fullName: fullName,
      email: email,
      role: role,
      department: json['department'],
      avatar: json['avatar'],
      isActive: isActive,
      lastLogin: json['last_login'] != null
          ? DateTime.parse(json['last_login'])
          : null,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userCode,
      'full_name': fullName,
      'email': email,
      'role': role,
      'department': department,
      'avatar': avatar,
      'is_active': isActive,
      'last_login': lastLogin?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  User copyWith({
    String? id,
    String? userCode,
    String? fullName,
    String? email,
    String? role,
    String? department,
    String? avatar,
    bool? isActive,
    DateTime? lastLogin,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return User(
      id: id ?? this.id,
      userCode: userCode ?? this.userCode,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      role: role ?? this.role,
      department: department ?? this.department,
      avatar: avatar ?? this.avatar,
      isActive: isActive ?? this.isActive,
      lastLogin: lastLogin ?? this.lastLogin,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  bool get isAdmin => role.toLowerCase() == 'admin';
  bool get isInstructor => role.toLowerCase() == 'instructor' || role.toLowerCase() == 'teacher';
  bool get isStudent => role.toLowerCase() == 'student';

  @override
  List<Object?> get props => [
        id,
        userCode,
        fullName,
        email,
        role,
        department,
        avatar,
        isActive,
        lastLogin,
        createdAt,
        updatedAt,
      ];
}

class LoginRequest extends Equatable {
  final String userCode;
  final String password;

  const LoginRequest({
    required this.userCode,
    required this.password,
  });

  Map<String, dynamic> toJson() {
    return {
      'user_id': userCode,
      'password': password,
    };
  }

  @override
  List<Object?> get props => [userCode, password];
}

class LoginResponse extends Equatable {
  final User user;
  final String accessToken;
  final String refreshToken;
  final DateTime expiresAt;

  const LoginResponse({
    required this.user,
    required this.accessToken,
    required this.refreshToken,
    required this.expiresAt,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    // Handle backend response structure: {access_token: "...", token_type: "...", user: {...}}
    final accessToken = json['access_token'] ?? '';
    final userData = json['user'] ?? json['data'] ?? {};

    // Create a mock user data structure that matches User.fromJson expectations
    final userMap = userData is Map<String, dynamic>
        ? {
            'id': userData['userId'] ?? userData['id'] ?? '',
            'user_id': userData['userId'] ?? userData['user_id'] ?? '',
            'full_name': userData['fullName'] ?? userData['full_name'] ?? '',
            'email': userData['email'] ?? '',
            'role': userData['role'] ?? '',
            'is_active': userData['isActive'] ?? userData['is_active'] ?? true,
            'created_at': userData['createdAt'] ?? userData['created_at'],
            'updated_at': userData['updatedAt'] ?? userData['updated_at'],
          }
        : <String, dynamic>{};

    return LoginResponse(
      user: User.fromJson(userMap),
      accessToken: accessToken,
      refreshToken: json['refresh_token'] ?? '',
      expiresAt: json['expires_at'] != null
          ? DateTime.parse(json['expires_at'])
          : DateTime.now().add(const Duration(hours: 24)),
    );
  }

  @override
  List<Object?> get props => [user, accessToken, refreshToken, expiresAt];
}

class ChangePasswordRequest extends Equatable {
  final String currentPassword;
  final String newPassword;

  const ChangePasswordRequest({
    required this.currentPassword,
    required this.newPassword,
  });

  Map<String, dynamic> toJson() {
    return {
      'current_password': currentPassword,
      'new_password': newPassword,
    };
  }

  @override
  List<Object?> get props => [currentPassword, newPassword];
}

class DemoAccount extends Equatable {
  final String userCode;
  final String password;
  final String role;
  final String fullName;
  final String description;

  const DemoAccount({
    required this.userCode,
    required this.password,
    required this.role,
    required this.fullName,
    required this.description,
  });

  factory DemoAccount.fromJson(Map<String, dynamic> json) {
    return DemoAccount(
      userCode: json['user_id'] ?? '',
      password: json['password'] ?? '',
      role: json['role'] ?? '',
      fullName: json['full_name'] ?? '',
      description: json['description'] ?? '',
    );
  }

  @override
  List<Object?> get props => [userCode, password, role, fullName, description];
}

class AttendanceStats extends Equatable {
  final int totalClasses;
  final int attendedClasses;
  final int missedClasses;
  final int lateClasses;
  final double attendanceRate;

  const AttendanceStats({
    required this.totalClasses,
    required this.attendedClasses,
    required this.missedClasses,
    required this.lateClasses,
    required this.attendanceRate,
  });

  @override
  List<Object?> get props => [
        totalClasses,
        attendedClasses,
        missedClasses,
        lateClasses,
        attendanceRate,
      ];
}