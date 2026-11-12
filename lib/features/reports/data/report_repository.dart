import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_response.dart';
import '../../../shared/models/report_model.dart';
import '../../auth/presentation/auth_controller.dart';

abstract class ReportRepository {
  Future<ApiResponse<List<ReportModel>>> getReports({String? status, String? type});
  Future<ApiResponse<ReportModel>> getReportDetail(String reportId);
  Future<ApiResponse<ReportModel>> createReport({
    required ReportType type,
    required String category,
    required String description,
    required DateTime incidentDate,
    required String incidentLocation,
    required String reporterType,
    required ReportPriority priority,
    List<String> attachmentUrls,
  });
  Future<ApiResponse<ReportModel>> updateReportStatus({
    required String reportId,
    required ReportStatus status,
    String? followupNote,
  });
  Future<ApiResponse<ReportModel>> updateReportPriority({
    required String reportId,
    required ReportPriority priority,
  });
  Future<ApiResponse<ReportModel>> updateInternalNotes({
    required String reportId,
    required String internalNotes,
  });
  Future<ApiResponse<List<ReportMessageModel>>> getMessages(String reportId);
  Future<ApiResponse<ReportMessageModel>> sendMessage({
    required String reportId,
    required String message,
    String? attachmentUrl,
  });
  Future<ApiResponse<List<ReportTimelineModel>>> getTimeline(String reportId);
  Future<ApiResponse<bool>> deleteReport(String reportId);
  Future<ApiResponse<bool>> deleteAllReports();
}

class MockReportRepository implements ReportRepository {
  final Ref _ref;
  final Uuid _uuid = const Uuid();

  final List<ReportModel> _reports = [];
  final Map<String, List<ReportMessageModel>> _messages = {};
  final Map<String, List<ReportTimelineModel>> _timelines = {};

  MockReportRepository(this._ref) {
    _initSampleData();
  }

  void _initSampleData() {
    // Empty by default - no dummy reports, messages or timelines
  }

  @override
  Future<ApiResponse<List<ReportModel>>> getReports({String? status, String? type}) async {
    await Future.delayed(const Duration(milliseconds: 400));
    final authState = _ref.read(authControllerProvider);

    var list = List<ReportModel>.from(_reports);

    // Multi-tenant isolation filter
    final schoolId = authState.currentSchool?.id ?? 'SCH_001';
    list = list.where((r) => r.schoolId == schoolId).toList();

    // If student, filter only student's reports
    if (authState.isStudent && authState.studentProfile != null) {
      list = list.where((r) => r.studentId == authState.studentProfile!.studentId).toList();
    }

    if (status != null && status.isNotEmpty) {
      list = list.where((r) => r.status.value == status).toList();
    }
    if (type != null && type.isNotEmpty) {
      list = list.where((r) => r.type.value == type).toList();
    }

    // Sort newest first
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return ApiResponse.success(list);
  }

  @override
  Future<ApiResponse<ReportModel>> getReportDetail(String reportId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final report = _reports.firstWhere(
      (r) => r.id == reportId,
      orElse: () => throw Exception('Laporan tidak ditemukan'),
    );
    return ApiResponse.success(report);
  }

  @override
  Future<ApiResponse<ReportModel>> createReport({
    required ReportType type,
    required String category,
    required String description,
    required DateTime incidentDate,
    required String incidentLocation,
    required String reporterType,
    required ReportPriority priority,
    List<String> attachmentUrls = const [],
  }) async {
    await Future.delayed(const Duration(milliseconds: 600));
    final authState = _ref.read(authControllerProvider);

    final schoolId = authState.currentSchool?.id ?? 'SCH_001';
    final studentId = authState.studentProfile?.studentId ?? '12345';
    final studentName = authState.studentProfile?.name ?? authState.user?.name ?? 'Siswa';
    final className = authState.studentProfile?.className ?? 'Kelas';

    final now = DateTime.now();
    final dateStr =
        '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
    final reportCode = 'RPT-$dateStr-${(_reports.length + 1).toString().padLeft(4, '0')}';

    final newReport = ReportModel(
      id: 'RPT_${_uuid.v4().substring(0, 8)}',
      schoolId: schoolId,
      studentId: studentId,
      studentName: studentName,
      className: className,
      reportCode: reportCode,
      type: type,
      category: category,
      description: description,
      incidentDate: incidentDate,
      incidentLocation: incidentLocation,
      reporterType: reporterType,
      priority: priority,
      status: ReportStatus.submitted,
      attachmentUrls: attachmentUrls,
      createdAt: now,
    );

    _reports.insert(0, newReport);

    _timelines[newReport.id] = [
      ReportTimelineModel(
        id: 'TL_${_uuid.v4().substring(0, 6)}',
        reportId: newReport.id,
        title: 'Laporan Diterima Sistem',
        description: 'Laporan Anda berhasil dikirim ke Guru BK secara rahasia.',
        status: 'SUBMITTED',
        timestamp: now,
      ),
    ];

    return ApiResponse.success(newReport);
  }

  @override
  Future<ApiResponse<ReportModel>> updateReportStatus({
    required String reportId,
    required ReportStatus status,
    String? followupNote,
  }) async {
    await Future.delayed(const Duration(milliseconds: 400));
    final index = _reports.indexWhere((r) => r.id == reportId);
    if (index == -1) return ApiResponse.failure('NOT_FOUND', 'Laporan tidak ditemukan');

    final updated = _reports[index].copyWith(
      status: status,
      resolvedAt: status == ReportStatus.resolved ? DateTime.now() : null,
    );
    _reports[index] = updated;

    final tlList = _timelines[reportId] ?? [];
    tlList.add(
      ReportTimelineModel(
        id: 'TL_${_uuid.v4().substring(0, 6)}',
        reportId: reportId,
        title: 'Status: ${status.label}',
        description: followupNote ?? 'Status laporan telah diperbarui oleh Guru BK.',
        status: status.value,
        timestamp: DateTime.now(),
      ),
    );
    _timelines[reportId] = tlList;

    return ApiResponse.success(updated);
  }

  @override
  Future<ApiResponse<ReportModel>> updateReportPriority({
    required String reportId,
    required ReportPriority priority,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final index = _reports.indexWhere((r) => r.id == reportId);
    if (index == -1) return ApiResponse.failure('NOT_FOUND', 'Laporan tidak ditemukan');

    final updated = _reports[index].copyWith(priority: priority);
    _reports[index] = updated;
    return ApiResponse.success(updated);
  }

  @override
  Future<ApiResponse<ReportModel>> updateInternalNotes({
    required String reportId,
    required String internalNotes,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final index = _reports.indexWhere((r) => r.id == reportId);
    if (index == -1) return ApiResponse.failure('NOT_FOUND', 'Laporan tidak ditemukan');

    final updated = _reports[index].copyWith(internalCounselorNotes: internalNotes);
    _reports[index] = updated;
    return ApiResponse.success(updated);
  }

  @override
  Future<ApiResponse<List<ReportMessageModel>>> getMessages(String reportId) async {
    await Future.delayed(const Duration(milliseconds: 250));
    return ApiResponse.success(_messages[reportId] ?? []);
  }

  @override
  Future<ApiResponse<ReportMessageModel>> sendMessage({
    required String reportId,
    required String message,
    String? attachmentUrl,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final authState = _ref.read(authControllerProvider);

    final msg = ReportMessageModel(
      id: 'MSG_${_uuid.v4().substring(0, 8)}',
      reportId: reportId,
      schoolId: authState.currentSchool?.id ?? 'SCH_001',
      senderUserId: authState.user?.id ?? 'USR',
      senderName: authState.isCounselor
          ? (authState.counselorProfile?.name ?? authState.user?.name ?? 'Guru BK')
          : (authState.studentProfile?.name ?? authState.user?.name ?? 'Siswa'),
      senderRole: authState.isCounselor ? 'COUNSELOR' : 'STUDENT',
      message: message,
      attachmentUrl: attachmentUrl,
      createdAt: DateTime.now(),
    );

    final list = _messages[reportId] ?? [];
    list.add(msg);
    _messages[reportId] = list;

    return ApiResponse.success(msg);
  }

  @override
  Future<ApiResponse<List<ReportTimelineModel>>> getTimeline(String reportId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return ApiResponse.success(_timelines[reportId] ?? []);
  }

  @override
  Future<ApiResponse<bool>> deleteReport(String reportId) async {
    _reports.removeWhere((r) => r.id == reportId);
    return ApiResponse.success(true);
  }

  @override
  Future<ApiResponse<bool>> deleteAllReports() async {
    _reports.clear();
    return ApiResponse.success(true);
  }
}

class ApiReportRepository implements ReportRepository {
  final ApiClient _apiClient;

  ApiReportRepository(this._apiClient);

  @override
  Future<ApiResponse<List<ReportModel>>> getReports({String? status, String? type}) async {
    final query = <String, dynamic>{};
    if (status != null) query['status'] = status;
    if (type != null) query['type'] = type;

    return await _apiClient.get<List<ReportModel>>(
      '/api/reports',
      queryParameters: query,
      fromJsonT: (data) =>
          (data as List).map((item) => ReportModel.fromJson(item)).toList(),
    );
  }

  @override
  Future<ApiResponse<ReportModel>> getReportDetail(String reportId) async {
    return await _apiClient.get<ReportModel>(
      '/api/reports/$reportId',
      fromJsonT: (data) => ReportModel.fromJson(data),
    );
  }

  @override
  Future<ApiResponse<ReportModel>> createReport({
    required ReportType type,
    required String category,
    required String description,
    required DateTime incidentDate,
    required String incidentLocation,
    required String reporterType,
    required ReportPriority priority,
    List<String> attachmentUrls = const [],
  }) async {
    return await _apiClient.post<ReportModel>(
      '/api/reports',
      data: {
        'type': type.value,
        'category': category,
        'description': description,
        'incident_date': incidentDate.toIso8601String(),
        'incident_location': incidentLocation,
        'reporter_type': reporterType,
        'priority': priority.value,
        'attachment_urls': attachmentUrls,
      },
      fromJsonT: (data) => ReportModel.fromJson(data),
    );
  }

  @override
  Future<ApiResponse<ReportModel>> updateReportStatus({
    required String reportId,
    required ReportStatus status,
    String? followupNote,
  }) async {
    return await _apiClient.patch<ReportModel>(
      '/api/reports/$reportId/status',
      data: {'status': status.value, 'note': followupNote},
      fromJsonT: (data) => ReportModel.fromJson(data),
    );
  }

  @override
  Future<ApiResponse<ReportModel>> updateReportPriority({
    required String reportId,
    required ReportPriority priority,
  }) async {
    return await _apiClient.patch<ReportModel>(
      '/api/reports/$reportId/priority',
      data: {'priority': priority.value},
      fromJsonT: (data) => ReportModel.fromJson(data),
    );
  }

  @override
  Future<ApiResponse<ReportModel>> updateInternalNotes({
    required String reportId,
    required String internalNotes,
  }) async {
    return await _apiClient.patch<ReportModel>(
      '/api/reports/$reportId/followups',
      data: {'internal_notes': internalNotes},
      fromJsonT: (data) => ReportModel.fromJson(data),
    );
  }

  @override
  Future<ApiResponse<List<ReportMessageModel>>> getMessages(String reportId) async {
    return await _apiClient.get<List<ReportMessageModel>>(
      '/api/reports/$reportId/messages',
      fromJsonT: (data) =>
          (data as List).map((item) => ReportMessageModel.fromJson(item)).toList(),
    );
  }

  @override
  Future<ApiResponse<ReportMessageModel>> sendMessage({
    required String reportId,
    required String message,
    String? attachmentUrl,
  }) async {
    return await _apiClient.post<ReportMessageModel>(
      '/api/reports/$reportId/messages',
      data: {'message': message, 'attachment_url': attachmentUrl},
      fromJsonT: (data) => ReportMessageModel.fromJson(data),
    );
  }

  @override
  Future<ApiResponse<List<ReportTimelineModel>>> getTimeline(String reportId) async {
    return await _apiClient.get<List<ReportTimelineModel>>(
      '/api/reports/$reportId/timeline',
      fromJsonT: (data) =>
          (data as List).map((item) => ReportTimelineModel.fromJson(item)).toList(),
    );
  }

  @override
  Future<ApiResponse<bool>> deleteReport(String reportId) async {
    return await _apiClient.delete<bool>(
      '/api/reports/$reportId',
      fromJsonT: (_) => true,
    );
  }

  @override
  Future<ApiResponse<bool>> deleteAllReports() async {
    return await _apiClient.delete<bool>(
      '/api/reports',
      fromJsonT: (_) => true,
    );
  }
}

final reportRepositoryProvider = Provider<ReportRepository>((ref) {
  final useMock = ref.watch(useMockBackendProvider);
  if (useMock) {
    return MockReportRepository(ref);
  } else {
    return ApiReportRepository(ref.watch(apiClientProvider));
  }
});
