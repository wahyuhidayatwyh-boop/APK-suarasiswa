import '../utils/date_formatter.dart';

enum ReportType {
  bullying('BULLYING', 'Bullying / Perundungan'),
  konseling('KONSELING', 'Konseling Privat & BK'),
  kritikSaran('KRITIK_SARAN', 'Kritik & Sarana'),
  aspirasi('ASPIRASI', 'Aspirasi Siswa');

  final String value;
  final String label;
  const ReportType(this.value, this.label);

  static ReportType fromString(String? val) {
    final v = val?.toUpperCase();
    if (v == 'KONSELING' || v == 'COUNSELING') return ReportType.konseling;
    if (v == 'KRITIK_SARAN' || v == 'SUGGESTION') return ReportType.kritikSaran;
    if (v == 'ASPIRASI' || v == 'ASPIRATION') return ReportType.aspirasi;
    return ReportType.bullying;
  }
}

enum ReportPriority {
  normal('NORMAL', 'Normal'),
  tinggi('TINGGI', 'Tinggi'),
  urgent('URGENT', 'Mendesak / Urgent');

  final String value;
  final String label;
  const ReportPriority(this.value, this.label);

  static ReportPriority fromString(String? val) {
    final v = val?.toUpperCase();
    if (v == 'TINGGI' || v == 'HIGH') return ReportPriority.tinggi;
    if (v == 'URGENT' || v == 'MENDESAK') return ReportPriority.urgent;
    return ReportPriority.normal;
  }
}

enum ReportStatus {
  submitted('SUBMITTED', 'Laporan Dikirim'),
  underReview('UNDER_REVIEW', 'Sedang Ditinjau'),
  inProgress('IN_PROGRESS', 'Dalam Penanganan'),
  waitingForInfo('WAITING_FOR_INFORMATION', 'Menunggu Info Tambahan'),
  resolved('RESOLVED', 'Selesai'),
  closed('CLOSED', 'Ditutup'),
  transferred('TRANSFERRED', 'Dialihkan');

  final String value;
  final String label;
  const ReportStatus(this.value, this.label);

  static ReportStatus fromString(String? val) {
    final v = val?.toUpperCase();
    switch (v) {
      case 'UNDER_REVIEW':
      case 'INVESTIGATING':
        return ReportStatus.underReview;
      case 'IN_PROGRESS':
      case 'ACTION_TAKEN':
        return ReportStatus.inProgress;
      case 'WAITING_FOR_INFORMATION':
        return ReportStatus.waitingForInfo;
      case 'RESOLVED':
        return ReportStatus.resolved;
      case 'CLOSED':
      case 'REJECTED':
        return ReportStatus.closed;
      case 'TRANSFERRED':
        return ReportStatus.transferred;
      case 'SUBMITTED':
      case 'PENDING':
      default:
        return ReportStatus.submitted;
    }
  }
}

class ReportModel {
  final String id;
  final String schoolId;
  final String studentId;
  final String? studentName;
  final String? className;
  final String reportCode;
  final ReportType type;
  final String category;
  final String description;
  final DateTime incidentDate;
  final String incidentLocation;
  final String reporterType; // KORBAN, SAKSI, PERWAKILAN
  final ReportPriority priority;
  final ReportStatus status;
  final List<String> attachmentUrls;
  final String? internalCounselorNotes;
  final DateTime createdAt;
  final DateTime? resolvedAt;

  ReportModel({
    required this.id,
    required this.schoolId,
    required this.studentId,
    this.studentName,
    this.className,
    required this.reportCode,
    required this.type,
    required this.category,
    required this.description,
    required this.incidentDate,
    required this.incidentLocation,
    this.reporterType = 'KORBAN',
    this.priority = ReportPriority.normal,
    this.status = ReportStatus.submitted,
    this.attachmentUrls = const [],
    this.internalCounselorNotes,
    required this.createdAt,
    this.resolvedAt,
  });

  factory ReportModel.fromJson(Map<String, dynamic> json) {
    return ReportModel(
      id: json['id'] as String? ?? '',
      schoolId: json['school_id'] as String? ?? '',
      studentId: json['student_id'] as String? ?? '',
      studentName: json['student_name'] as String?,
      className: json['class_name'] as String?,
      reportCode: json['report_code'] as String? ?? '',
      type: ReportType.fromString(json['type'] as String?),
      category: json['category'] as String? ?? '',
      description: json['description'] as String? ?? '',
      incidentDate: AppDateFormatter.parseDateTime(json['incident_date']),
      incidentLocation: json['incident_location'] as String? ?? '',
      reporterType: json['reporter_type'] as String? ?? 'KORBAN',
      priority: ReportPriority.fromString(json['priority'] as String?),
      status: ReportStatus.fromString(json['status'] as String?),
      attachmentUrls: (json['attachment_urls'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      internalCounselorNotes: json['internal_counselor_notes'] as String?,
      createdAt: AppDateFormatter.parseDateTime(json['created_at']),
      resolvedAt: AppDateFormatter.tryParseDateTime(json['resolved_at']),
    );
  }

  Map<String, dynamic> toJson({bool includeInternalNotes = false}) {
    final map = <String, dynamic>{
      'id': id,
      'school_id': schoolId,
      'student_id': studentId,
      'student_name': studentName,
      'class_name': className,
      'report_code': reportCode,
      'type': type.value,
      'category': category,
      'description': description,
      'incident_date': incidentDate.toIso8601String(),
      'incident_location': incidentLocation,
      'reporter_type': reporterType,
      'priority': priority.value,
      'status': status.value,
      'attachment_urls': attachmentUrls,
      'created_at': createdAt.toIso8601String(),
      'resolved_at': resolvedAt?.toIso8601String(),
    };
    if (includeInternalNotes) {
      map['internal_counselor_notes'] = internalCounselorNotes;
    }
    return map;
  }

  ReportModel copyWith({
    String? id,
    String? schoolId,
    String? studentId,
    String? studentName,
    String? className,
    String? reportCode,
    ReportType? type,
    String? category,
    String? description,
    DateTime? incidentDate,
    String? incidentLocation,
    String? reporterType,
    ReportPriority? priority,
    ReportStatus? status,
    List<String>? attachmentUrls,
    String? internalCounselorNotes,
    DateTime? createdAt,
    DateTime? resolvedAt,
  }) {
    return ReportModel(
      id: id ?? this.id,
      schoolId: schoolId ?? this.schoolId,
      studentId: studentId ?? this.studentId,
      studentName: studentName ?? this.studentName,
      className: className ?? this.className,
      reportCode: reportCode ?? this.reportCode,
      type: type ?? this.type,
      category: category ?? this.category,
      description: description ?? this.description,
      incidentDate: incidentDate ?? this.incidentDate,
      incidentLocation: incidentLocation ?? this.incidentLocation,
      reporterType: reporterType ?? this.reporterType,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      attachmentUrls: attachmentUrls ?? this.attachmentUrls,
      internalCounselorNotes:
          internalCounselorNotes ?? this.internalCounselorNotes,
      createdAt: createdAt ?? this.createdAt,
      resolvedAt: resolvedAt ?? this.resolvedAt,
    );
  }
}

class ReportMessageModel {
  final String id;
  final String reportId;
  final String schoolId;
  final String senderUserId;
  final String senderName;
  final String senderRole; // STUDENT / COUNSELOR
  final String message;
  final String? attachmentUrl;
  final DateTime createdAt;

  ReportMessageModel({
    required this.id,
    required this.reportId,
    required this.schoolId,
    required this.senderUserId,
    required this.senderName,
    required this.senderRole,
    required this.message,
    this.attachmentUrl,
    required this.createdAt,
  });

  factory ReportMessageModel.fromJson(Map<String, dynamic> json) {
    return ReportMessageModel(
      id: json['id'] as String? ?? '',
      reportId: json['report_id'] as String? ?? '',
      schoolId: json['school_id'] as String? ?? '',
      senderUserId: json['sender_user_id'] as String? ?? '',
      senderName: json['sender_name'] as String? ?? '',
      senderRole: json['sender_role'] as String? ?? 'STUDENT',
      message: json['message'] as String? ?? '',
      attachmentUrl: json['attachment_url'] as String?,
      createdAt: AppDateFormatter.parseDateTime(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'report_id': reportId,
      'school_id': schoolId,
      'sender_user_id': senderUserId,
      'sender_name': senderName,
      'sender_role': senderRole,
      'message': message,
      'attachment_url': attachmentUrl,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

class ReportTimelineModel {
  final String id;
  final String reportId;
  final String title;
  final String description;
  final String status;
  final DateTime timestamp;

  ReportTimelineModel({
    required this.id,
    required this.reportId,
    required this.title,
    required this.description,
    required this.status,
    required this.timestamp,
  });

  factory ReportTimelineModel.fromJson(Map<String, dynamic> json) {
    return ReportTimelineModel(
      id: json['id'] as String? ?? '',
      reportId: json['report_id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      status: json['status'] as String? ?? '',
      timestamp: AppDateFormatter.parseDateTime(json['timestamp'] ?? json['created_at']),
    );
  }
}
