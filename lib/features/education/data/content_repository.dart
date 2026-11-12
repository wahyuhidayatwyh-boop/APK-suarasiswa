import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_response.dart';
import '../../../shared/models/content_model.dart';
import '../../auth/presentation/auth_controller.dart';

abstract class ContentRepository {
  Future<ApiResponse<List<ContentModel>>> getContents({ContentType? type, ContentStatus? status});
  Future<ApiResponse<ContentModel>> getContentDetail(String id);
  Future<ApiResponse<ContentModel>> createContent({
    required ContentType type,
    required String title,
    required String shortDescription,
    String? body,
    String? imageUrl,
    ContentStatus status,
  });
  Future<ApiResponse<ContentModel>> updateContent({
    required String id,
    required String title,
    required String shortDescription,
    String? body,
    String? imageUrl,
  });
  Future<ApiResponse<ContentModel>> updateStatus({
    required String id,
    required ContentStatus status,
  });
  Future<ApiResponse<bool>> deleteContent(String id);
}

class MockContentRepository implements ContentRepository {
  final Ref _ref;
  final Uuid _uuid = const Uuid();

  final List<ContentModel> _contents = [];

  MockContentRepository(this._ref) {
    _initDefaults();
  }

  void _initDefaults() {
    final now = DateTime.now();

    _contents.addAll([
      ContentModel(
        id: 'CNT_001',
        schoolId: 'SCH_001',
        createdBy: 'USR_COUNSELOR',
        type: ContentType.banner,
        title: 'Stop Perundungan, Ciptakan Lingkungan Aman!',
        shortDescription: 'Setiap siswa berhak belajar dengan tenang tanpa rasa takut.',
        body: 'Mari bersama-sama saling menjaga, menghormati perbedaan, dan berani melapor jika melihat teman tertindas.',
        status: ContentStatus.published,
        sortOrder: 1,
        createdAt: now.subtract(const Duration(days: 10)),
      ),
      ContentModel(
        id: 'CNT_002',
        schoolId: 'SCH_001',
        createdBy: 'USR_COUNSELOR',
        type: ContentType.education,
        title: 'Kenali Bullying & Jenis-Jenisnya',
        shortDescription: 'Memahami perbedaan antara bercanda biasa dan tindakan perundungan nyata.',
        body: '''
Perundungan (bullying) adalah perilaku agresif yang dilakukan secara sengaja dan berulang-ulang, di mana terdapat ketimpangan kuasa antara pelaku dan korban.

Berikut adalah jenis-jenis perundungan yang sering terjadi:
1. Bullying Fisik: Memukul, menendang, mendorong, atau merusak barang pribadi.
2. Bullying Verbal: Mengejek, memanggil dengan julukan merendahkan, menghina fisik atau keluarga.
3. Bullying Sosial/Pengucilan: Mengabaikan dengan sengaja, menyebarkan rumor jahat, memboikot pergaulan.
4. Cyberbullying: Mengintimidasi melalui pesan media sosial, menyebarkan foto atau video aib tanpa izin.

Jika kamu atau temanmu mengalaminya, ingatlah bahwa kamu TIDAK bersalah dan kamu TIDAK sendiri. Segera laporkan melalui SuaraSiswa ke Guru BK!
''',
        status: ContentStatus.published,
        sortOrder: 2,
        createdAt: now.subtract(const Duration(days: 8)),
      ),
      ContentModel(
        id: 'CNT_003',
        schoolId: 'SCH_001',
        createdBy: 'USR_COUNSELOR',
        type: ContentType.education,
        title: 'Cara Membantu Teman yang Mengalami Perundungan',
        shortDescription: 'Jangan jadi penonton pasif (bystander). Jadilah sahabat yang melindungi.',
        body: '''
Ketika melihat teman dirundung:
1. Jangan ikut menertawakan atau membagikan konten perundungan.
2. Ajak temanmu menjauh dari pelaku secara tenang.
3. Dengarkan ceritanya tanpa menghakimi atau meremehkan perasaannya.
4. Bantu laporkan kejadian tersebut melalui aplikasi SuaraSiswa secara rahasia sebagai Saksi.
''',
        status: ContentStatus.published,
        sortOrder: 3,
        createdAt: now.subtract(const Duration(days: 6)),
      ),
      ContentModel(
        id: 'CNT_004',
        schoolId: 'SCH_001',
        createdBy: 'USR_COUNSELOR',
        type: ContentType.announcement,
        title: 'Jadwal Konseling Tatap Muka Terbuka Ruang BK',
        shortDescription: 'Ruang BK buka setiap hari Senin-Jumat pukul 07.30 - 15.30 WIB.',
        body: 'Pintu ruang BK selalu terbuka untuk konsultasi belajar, karir masa depan, maupun masalah pribadi.',
        status: ContentStatus.published,
        sortOrder: 4,
        createdAt: now.subtract(const Duration(days: 3)),
      ),
    ]);
  }

  @override
  Future<ApiResponse<List<ContentModel>>> getContents({ContentType? type, ContentStatus? status}) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final schoolId = _ref.read(authControllerProvider).currentSchool?.id ?? 'SCH_001';

    var list = _contents.where((c) => c.schoolId == schoolId).toList();

    // If student, only show published
    if (_ref.read(authControllerProvider).isStudent) {
      list = list.where((c) => c.status == ContentStatus.published).toList();
    } else if (status != null) {
      list = list.where((c) => c.status == status).toList();
    }

    if (type != null) {
      list = list.where((c) => c.type == type).toList();
    }

    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return ApiResponse.success(list);
  }

  @override
  Future<ApiResponse<ContentModel>> getContentDetail(String id) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final content = _contents.firstWhere(
      (c) => c.id == id,
      orElse: () => throw Exception('Konten tidak ditemukan'),
    );
    return ApiResponse.success(content);
  }

  @override
  Future<ApiResponse<ContentModel>> createContent({
    required ContentType type,
    required String title,
    required String shortDescription,
    String? body,
    String? imageUrl,
    ContentStatus status = ContentStatus.published,
  }) async {
    await Future.delayed(const Duration(milliseconds: 400));
    final auth = _ref.read(authControllerProvider);

    final newContent = ContentModel(
      id: 'CNT_${_uuid.v4().substring(0, 8)}',
      schoolId: auth.currentSchool?.id ?? 'SCH_001',
      createdBy: auth.user?.id ?? 'USR',
      type: type,
      title: title,
      shortDescription: shortDescription,
      body: body,
      imageUrl: imageUrl,
      status: status,
      createdAt: DateTime.now(),
    );

    _contents.insert(0, newContent);
    return ApiResponse.success(newContent);
  }

  @override
  Future<ApiResponse<ContentModel>> updateContent({
    required String id,
    required String title,
    required String shortDescription,
    String? body,
    String? imageUrl,
  }) async {
    await Future.delayed(const Duration(milliseconds: 350));
    final index = _contents.indexWhere((c) => c.id == id);
    if (index == -1) return ApiResponse.failure('NOT_FOUND', 'Konten tidak ditemukan');

    final updated = _contents[index].copyWith(
      title: title,
      shortDescription: shortDescription,
      body: body,
      imageUrl: imageUrl,
    );
    _contents[index] = updated;
    return ApiResponse.success(updated);
  }

  @override
  Future<ApiResponse<ContentModel>> updateStatus({
    required String id,
    required ContentStatus status,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final index = _contents.indexWhere((c) => c.id == id);
    if (index == -1) return ApiResponse.failure('NOT_FOUND', 'Konten tidak ditemukan');

    final updated = _contents[index].copyWith(status: status);
    _contents[index] = updated;
    return ApiResponse.success(updated);
  }

  @override
  Future<ApiResponse<bool>> deleteContent(String id) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _contents.removeWhere((c) => c.id == id);
    return ApiResponse.success(true);
  }
}

class ApiContentRepository implements ContentRepository {
  final ApiClient _apiClient;

  ApiContentRepository(this._apiClient);

  @override
  Future<ApiResponse<List<ContentModel>>> getContents({ContentType? type, ContentStatus? status}) async {
    final query = <String, dynamic>{};
    if (type != null) query['type'] = type.value;
    if (status != null) query['status'] = status.value;

    return await _apiClient.get<List<ContentModel>>(
      '/api/contents',
      queryParameters: query,
      fromJsonT: (data) =>
          (data as List).map((i) => ContentModel.fromJson(i)).toList(),
    );
  }

  @override
  Future<ApiResponse<ContentModel>> getContentDetail(String id) async {
    return await _apiClient.get<ContentModel>(
      '/api/contents/$id',
      fromJsonT: (data) => ContentModel.fromJson(data),
    );
  }

  @override
  Future<ApiResponse<ContentModel>> createContent({
    required ContentType type,
    required String title,
    required String shortDescription,
    String? body,
    String? imageUrl,
    ContentStatus status = ContentStatus.published,
  }) async {
    return await _apiClient.post<ContentModel>(
      '/api/contents',
      data: {
        'type': type.value,
        'title': title,
        'short_description': shortDescription,
        'body': body,
        'image_url': imageUrl,
        'status': status.value,
      },
      fromJsonT: (data) => ContentModel.fromJson(data),
    );
  }

  @override
  Future<ApiResponse<ContentModel>> updateContent({
    required String id,
    required String title,
    required String shortDescription,
    String? body,
    String? imageUrl,
  }) async {
    return await _apiClient.patch<ContentModel>(
      '/api/contents/$id',
      data: {
        'title': title,
        'short_description': shortDescription,
        'body': body,
        'image_url': imageUrl,
      },
      fromJsonT: (data) => ContentModel.fromJson(data),
    );
  }

  @override
  Future<ApiResponse<ContentModel>> updateStatus({
    required String id,
    required ContentStatus status,
  }) async {
    return await _apiClient.patch<ContentModel>(
      '/api/contents/$id/status',
      data: {'status': status.value},
      fromJsonT: (data) => ContentModel.fromJson(data),
    );
  }

  @override
  Future<ApiResponse<bool>> deleteContent(String id) async {
    final res = await _apiClient.delete('/api/contents/$id');
    return ApiResponse.success(res.success);
  }
}

final contentRepositoryProvider = Provider<ContentRepository>((ref) {
  final useMock = ref.watch(useMockBackendProvider);
  if (useMock) {
    return MockContentRepository(ref);
  } else {
    return ApiContentRepository(ref.watch(apiClientProvider));
  }
});
