import '../utils/date_formatter.dart';

class NotificationModel {
  final String id;
  final String userId;
  final String schoolId;
  final String title;
  final String body;
  final String type; // REPORT_UPDATE, NEW_MESSAGE, FOLLOWUP, ANNOUNCEMENT
  final String? referenceId;
  final bool isRead;
  final DateTime createdAt;

  NotificationModel({
    required this.id,
    required this.userId,
    required this.schoolId,
    required this.title,
    required this.body,
    required this.type,
    this.referenceId,
    this.isRead = false,
    required this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] as String? ?? '',
      userId: json['user_id'] as String? ?? '',
      schoolId: json['school_id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? '',
      type: json['type'] as String? ?? 'REPORT_UPDATE',
      referenceId: json['reference_id'] as String?,
      isRead: json['is_read'] == 1 || json['is_read'] == true,
      createdAt: AppDateFormatter.parseDateTime(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'school_id': schoolId,
      'title': title,
      'body': body,
      'type': type,
      'reference_id': referenceId,
      'is_read': isRead,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
