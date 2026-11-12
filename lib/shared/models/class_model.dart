import '../utils/date_formatter.dart';

class SchoolClassModel {
  final String id;
  final String schoolId;
  final String name;
  final String grade;
  final String? joinCode;
  final String? description;
  final String status;
  final int studentCount;
  final DateTime createdAt;

  SchoolClassModel({
    required this.id,
    required this.schoolId,
    required this.name,
    required this.grade,
    this.joinCode,
    this.description,
    this.status = 'ACTIVE',
    this.studentCount = 0,
    required this.createdAt,
  });

  factory SchoolClassModel.fromJson(Map<String, dynamic> json) {
    return SchoolClassModel(
      id: json['id'] as String? ?? '',
      schoolId: json['school_id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      grade: json['grade'] as String? ?? '',
      joinCode: json['join_code'] as String?,
      description: json['description'] as String?,
      status: json['status'] as String? ?? 'ACTIVE',
      studentCount: (json['student_count'] as num?)?.toInt() ?? 0,
      createdAt: AppDateFormatter.parseDateTime(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'school_id': schoolId,
      'name': name,
      'grade': grade,
      'join_code': joinCode,
      'description': description,
      'status': status,
      'student_count': studentCount,
      'created_at': createdAt.toIso8601String(),
    };
  }

  SchoolClassModel copyWith({
    String? id,
    String? schoolId,
    String? name,
    String? grade,
    String? joinCode,
    String? description,
    String? status,
    int? studentCount,
    DateTime? createdAt,
  }) {
    return SchoolClassModel(
      id: id ?? this.id,
      schoolId: schoolId ?? this.schoolId,
      name: name ?? this.name,
      grade: grade ?? this.grade,
      joinCode: joinCode ?? this.joinCode,
      description: description ?? this.description,
      status: status ?? this.status,
      studentCount: studentCount ?? this.studentCount,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
