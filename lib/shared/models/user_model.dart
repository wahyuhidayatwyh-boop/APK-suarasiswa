import '../utils/date_formatter.dart';

enum UserRole {
  student('STUDENT'),
  counselor('COUNSELOR');

  final String value;
  const UserRole(this.value);

  static UserRole fromString(String? val) {
    if (val?.toUpperCase() == 'COUNSELOR') return UserRole.counselor;
    return UserRole.student;
  }
}

class UserModel {
  final String id;
  final String googleUid;
  final String email;
  final String name;
  final String? photoUrl;
  final String authProvider;
  final String status;
  final DateTime createdAt;

  UserModel({
    required this.id,
    required this.googleUid,
    required this.email,
    required this.name,
    this.photoUrl,
    this.authProvider = 'GOOGLE',
    this.status = 'ACTIVE',
    required this.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String? ?? '',
      googleUid: json['google_uid'] as String? ?? '',
      email: json['email'] as String? ?? '',
      name: json['name'] as String? ?? '',
      photoUrl: json['photo_url'] as String?,
      authProvider: json['auth_provider'] as String? ?? 'GOOGLE',
      status: json['status'] as String? ?? 'ACTIVE',
      createdAt: AppDateFormatter.parseDateTime(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'google_uid': googleUid,
      'email': email,
      'name': name,
      'photo_url': photoUrl,
      'auth_provider': authProvider,
      'status': status,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

class SchoolMembershipModel {
  final String id;
  final String schoolId;
  final String userId;
  final UserRole role;
  final bool isOwner;
  final String status;
  final DateTime joinedAt;

  SchoolMembershipModel({
    required this.id,
    required this.schoolId,
    required this.userId,
    required this.role,
    this.isOwner = false,
    this.status = 'ACTIVE',
    required this.joinedAt,
  });

  factory SchoolMembershipModel.fromJson(Map<String, dynamic> json) {
    return SchoolMembershipModel(
      id: json['id'] as String? ?? '',
      schoolId: json['school_id'] as String? ?? '',
      userId: json['user_id'] as String? ?? '',
      role: UserRole.fromString(json['role'] as String?),
      isOwner: json['is_owner'] == 1 || json['is_owner'] == true,
      status: json['status'] as String? ?? 'ACTIVE',
      joinedAt: AppDateFormatter.parseDateTime(json['joined_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'school_id': schoolId,
      'user_id': userId,
      'role': role.value,
      'is_owner': isOwner,
      'status': status,
      'joined_at': joinedAt.toIso8601String(),
    };
  }
}

class CounselorProfileModel {
  final String id;
  final String userId;
  final String schoolId;
  final String name;
  final String? employeeId;
  final String? phone;
  final String? photoUrl;

  CounselorProfileModel({
    required this.id,
    required this.userId,
    required this.schoolId,
    required this.name,
    this.employeeId,
    this.phone,
    this.photoUrl,
  });

  factory CounselorProfileModel.fromJson(Map<String, dynamic> json) {
    return CounselorProfileModel(
      id: json['id'] as String? ?? '',
      userId: json['user_id'] as String? ?? '',
      schoolId: json['school_id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      employeeId: json['employee_id'] as String?,
      phone: json['phone'] as String?,
      photoUrl: json['photo_url'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'school_id': schoolId,
      'name': name,
      'employee_id': employeeId,
      'phone': phone,
      'photo_url': photoUrl,
    };
  }
}

class StudentProfileModel {
  final String id;
  final String userId;
  final String schoolId;
  final String? classId;
  final String? className;
  final String studentId; // NIS
  final String name;
  final String? phone;

  StudentProfileModel({
    required this.id,
    required this.userId,
    required this.schoolId,
    this.classId,
    this.className,
    required this.studentId,
    required this.name,
    this.phone,
  });

  bool get hasClass => classId != null && classId!.isNotEmpty;

  StudentProfileModel copyWith({
    String? id,
    String? userId,
    String? schoolId,
    String? classId,
    String? className,
    String? studentId,
    String? name,
    String? phone,
    bool clearClass = false,
  }) {
    return StudentProfileModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      schoolId: schoolId ?? this.schoolId,
      classId: clearClass ? null : (classId ?? this.classId),
      className: clearClass ? null : (className ?? this.className),
      studentId: studentId ?? this.studentId,
      name: name ?? this.name,
      phone: phone ?? this.phone,
    );
  }

  factory StudentProfileModel.fromJson(Map<String, dynamic> json) {
    return StudentProfileModel(
      id: json['id'] as String? ?? '',
      userId: json['user_id'] as String? ?? '',
      schoolId: json['school_id'] as String? ?? '',
      classId: json['class_id'] as String?,
      className: json['class_name'] as String?,
      studentId: json['student_id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      phone: json['phone'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'school_id': schoolId,
      'class_id': classId,
      'class_name': className,
      'student_id': studentId,
      'name': name,
      'phone': phone,
    };
  }
}
