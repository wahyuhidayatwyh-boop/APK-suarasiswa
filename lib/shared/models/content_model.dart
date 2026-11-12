import '../utils/date_formatter.dart';

enum ContentType {
  banner('banner', 'Banner Beranda'),
  poster('poster', 'Poster Edukasi'),
  education('education', 'Materi Edukasi'),
  announcement('announcement', 'Pengumuman'),
  counseling('counseling', 'Tips BK');

  final String value;
  final String label;
  const ContentType(this.value, this.label);

  static ContentType fromString(String? val) {
    switch (val) {
      case 'BANNER':
      case 'banner':
        return ContentType.banner;
      case 'POSTER':
      case 'poster':
        return ContentType.poster;
      case 'ANNOUNCEMENT':
      case 'announcement':
        return ContentType.announcement;
      case 'COUNSELING':
      case 'counseling':
        return ContentType.counseling;
      default:
        return ContentType.education;
    }
  }
}

enum ContentStatus {
  draft('draft', 'Draft'),
  published('published', 'Diterbitkan'),
  archived('archived', 'Diarsipkan');

  final String value;
  final String label;
  const ContentStatus(this.value, this.label);

  static ContentStatus fromString(String? val) {
    if (val == 'DRAFT' || val == 'draft') return ContentStatus.draft;
    if (val == 'ARCHIVED' || val == 'archived') return ContentStatus.archived;
    return ContentStatus.published;
  }
}

class ContentModel {
  final String id;
  final String schoolId;
  final String createdBy;
  final ContentType type;
  final String title;
  final String shortDescription;
  final String? body;
  final String? imageUrl;
  final ContentStatus status;
  final int sortOrder;
  final DateTime createdAt;

  ContentModel({
    required this.id,
    required this.schoolId,
    required this.createdBy,
    required this.type,
    required this.title,
    required this.shortDescription,
    this.body,
    this.imageUrl,
    this.status = ContentStatus.published,
    this.sortOrder = 0,
    required this.createdAt,
  });

  factory ContentModel.fromJson(Map<String, dynamic> json) {
    return ContentModel(
      id: json['id'] as String? ?? '',
      schoolId: json['school_id'] as String? ?? '',
      createdBy: (json['created_by'] ?? json['author_id']) as String? ?? '',
      type: ContentType.fromString(json['type'] as String?),
      title: json['title'] as String? ?? '',
      shortDescription: json['short_description'] as String? ?? '',
      body: json['body'] as String?,
      imageUrl: json['image_url'] as String?,
      status: ContentStatus.fromString(json['status'] as String?),
      sortOrder: (json['sort_order'] as num?)?.toInt() ?? 0,
      createdAt: AppDateFormatter.parseDateTime(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'school_id': schoolId,
      'created_by': createdBy,
      'type': type.value,
      'title': title,
      'short_description': shortDescription,
      'body': body,
      'image_url': imageUrl,
      'status': status.value,
      'sort_order': sortOrder,
      'created_at': createdAt.toIso8601String(),
    };
  }

  ContentModel copyWith({
    String? id,
    String? schoolId,
    String? createdBy,
    ContentType? type,
    String? title,
    String? shortDescription,
    String? body,
    String? imageUrl,
    ContentStatus? status,
    int? sortOrder,
    DateTime? createdAt,
  }) {
    return ContentModel(
      id: id ?? this.id,
      schoolId: schoolId ?? this.schoolId,
      createdBy: createdBy ?? this.createdBy,
      type: type ?? this.type,
      title: title ?? this.title,
      shortDescription: shortDescription ?? this.shortDescription,
      body: body ?? this.body,
      imageUrl: imageUrl ?? this.imageUrl,
      status: status ?? this.status,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
