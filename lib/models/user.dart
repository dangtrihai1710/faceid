class User {
  final String id;
  final String userId;
  final String email;
  final String fullName;
  final String? phone;
  final String token;
  final String role;
  final bool isActive;  // Thêm thuộc tính isActive
  final String? studentId;  // Thêm thuộc tính studentId cho sinh viên
  final String? classId;  // Support for academic year classes (e.g., "25ABC1")
  final String? academicClassId;  // Academic class like "25ABC1"
  final List<String>? subjectClassIds;  // Subject classes like ["LAPTRINH", "TRIET"]
  final String? avatar;  // Profile avatar URL
  final DateTime? createdAt;
  final DateTime? updatedAt;

  User({
    required this.id,
    required this.userId,
    required this.email,
    required this.fullName,
    this.phone,
    required this.token,
    this.role = 'student',
    this.isActive = true,  // Giá trị mặc định
    this.studentId,
    this.classId,
    this.academicClassId,
    this.subjectClassIds,
    this.avatar,
    this.createdAt,
    this.updatedAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    // Handle subjectClassIds from various possible formats
    List<String>? subjectClassIds;
    if (json['subjectClassIds'] != null) {
      if (json['subjectClassIds'] is List) {
        subjectClassIds = (json['subjectClassIds'] as List).map((e) => e.toString()).toList();
      } else if (json['subjectClassIds'] is String) {
        subjectClassIds = json['subjectClassIds'].toString().split(',');
      }
    } else if (json['subject_class_ids'] != null) {
      if (json['subject_class_ids'] is List) {
        subjectClassIds = (json['subject_class_ids'] as List).map((e) => e.toString()).toList();
      }
    }

    return User(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      userId: json['userId']?.toString() ?? json['user_id']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      fullName: json['fullName']?.toString() ?? json['full_name']?.toString() ?? '',
      phone: json['phone']?.toString(),
      token: json['token']?.toString() ?? '',
      role: json['role']?.toString() ?? 'student',
      isActive: json['isActive'] ?? json['is_active'] ?? true,
      studentId: json['studentId']?.toString() ?? json['student_id'],
      classId: json['classId']?.toString() ?? json['class_id']?.toString(),
      academicClassId: json['academicClassId']?.toString() ?? json['academic_class_id']?.toString(),
      subjectClassIds: subjectClassIds,
      avatar: json['avatar'],
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'email': email,
      'fullName': fullName,
      'phone': phone,
      'token': token,
      'role': role,
      'isActive': isActive,
      'studentId': studentId,
      'classId': classId,
      'academicClassId': academicClassId,
      'subjectClassIds': subjectClassIds,
      'avatar': avatar,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  User copyWith({
    String? id,
    String? userId,
    String? email,
    String? fullName,
    String? phone,
    String? token,
    String? role,
    bool? isActive,
    String? studentId,
    String? classId,
    String? academicClassId,
    List<String>? subjectClassIds,
    String? avatar,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return User(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      phone: phone ?? this.phone,
      token: token ?? this.token,
      role: role ?? this.role,
      isActive: isActive ?? this.isActive,
      studentId: studentId ?? this.studentId,
      classId: classId ?? this.classId,
      academicClassId: academicClassId ?? this.academicClassId,
      subjectClassIds: subjectClassIds ?? this.subjectClassIds,
      avatar: avatar ?? this.avatar,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'User(id: $id, userId: $userId, email: $email, fullName: $fullName)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is User &&
        other.id == id &&
        other.userId == userId &&
        other.email == email;
  }

  @override
  int get hashCode {
    return id.hashCode ^ userId.hashCode ^ email.hashCode;
  }
}