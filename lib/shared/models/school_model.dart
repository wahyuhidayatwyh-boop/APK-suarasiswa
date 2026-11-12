import '../utils/date_formatter.dart';

class SchoolModel {
  final String id;
  final String name;
  final String schoolCode;
  final String? logoUrl;
  final String? address;
  final String? description;
  final String ownerUserId;
  final String status;
  final DateTime createdAt;

  SchoolModel({
    required this.id,
    required this.name,
    required this.schoolCode,
    this.logoUrl,
    this.address,
    this.description,
    required this.ownerUserId,
    this.status = 'ACTIVE',
    required this.createdAt,
  });

  factory SchoolModel.fromJson(Map<String, dynamic> json) {
    return SchoolModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      schoolCode: json['school_code'] as String? ?? '',
      logoUrl: json['logo_url'] as String?,
      address: json['address'] as String?,
      description: json['description'] as String?,
      ownerUserId: json['owner_user_id'] as String? ?? '',
      status: json['status'] as String? ?? 'ACTIVE',
      createdAt: AppDateFormatter.parseDateTime(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'school_code': schoolCode,
      'logo_url': logoUrl,
      'address': address,
      'description': description,
      'owner_user_id': ownerUserId,
      'status': status,
      'created_at': createdAt.toIso8601String(),
    };
  }

  SchoolModel copyWith({
    String? id,
    String? name,
    String? schoolCode,
    String? logoUrl,
    String? address,
    String? description,
    String? ownerUserId,
    String? status,
    DateTime? createdAt,
  }) {
    return SchoolModel(
      id: id ?? this.id,
      name: name ?? this.name,
      schoolCode: schoolCode ?? this.schoolCode,
      logoUrl: logoUrl ?? this.logoUrl,
      address: address ?? this.address,
      description: description ?? this.description,
      ownerUserId: ownerUserId ?? this.ownerUserId,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
