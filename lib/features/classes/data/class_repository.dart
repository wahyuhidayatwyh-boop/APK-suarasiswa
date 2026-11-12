import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_response.dart';
import '../../../shared/models/class_model.dart';
import '../../../shared/models/user_model.dart';
import '../../auth/presentation/auth_controller.dart';

abstract class ClassRepository {
  Future<ApiResponse<List<SchoolClassModel>>> getClasses();
  Future<ApiResponse<SchoolClassModel>> addClass({
    required String name,
    required String grade,
    String? description,
  });
  Future<ApiResponse<SchoolClassModel>> updateClass({
    required String id,
    required String name,
    required String grade,
    String? description,
  });
  Future<ApiResponse<bool>> archiveClass(String id);
  Future<ApiResponse<bool>> deleteClass(String id);
  Future<ApiResponse<List<StudentProfileModel>>> getClassStudents(String classId);
  Future<ApiResponse<String>> generateClassCode(String classId);
  Future<ApiResponse<bool>> removeStudentFromClass({required String classId, required String studentId});
  Future<ApiResponse<bool>> studentLeaveClass();
  Future<ApiResponse<StudentProfileModel>> studentSelectClass(String classId);
  Future<ApiResponse<bool>> counselorLeaveSchool();
}

class MockClassRepository implements ClassRepository {
  final Ref _ref;
  final Uuid _uuid = const Uuid();

  final List<SchoolClassModel> _classes = [];
  final Map<String, List<StudentProfileModel>> _classStudents = {};

  MockClassRepository(this._ref) {
    _initDefaults();
  }

  void _initDefaults() {
    // Empty by default - no dummy/starter data
  }

  @override
  Future<ApiResponse<List<SchoolClassModel>>> getClasses() async {
    await Future.delayed(const Duration(milliseconds: 300));
    final schoolId = _ref.read(authControllerProvider).currentSchool?.id ?? 'SCH_001';
    final filtered = _classes.where((c) => c.schoolId == schoolId && c.status == 'ACTIVE').toList();
    return ApiResponse.success(filtered);
  }

  @override
  Future<ApiResponse<SchoolClassModel>> addClass({
    required String name,
    required String grade,
    String? description,
  }) async {
    await Future.delayed(const Duration(milliseconds: 400));
    final schoolId = _ref.read(authControllerProvider).currentSchool?.id ?? 'SCH_001';

    final codePrefix = name.replaceAll(' ', '').toUpperCase();
    final randomSuffix = _uuid.v4().substring(0, 4).toUpperCase();
    final joinCode = '${codePrefix.length > 4 ? codePrefix.substring(0, 4) : codePrefix}-$randomSuffix';

    final newClass = SchoolClassModel(
      id: 'CLS_${_uuid.v4().substring(0, 6)}',
      schoolId: schoolId,
      name: name,
      grade: grade,
      joinCode: joinCode,
      description: description,
      studentCount: 0,
      createdAt: DateTime.now(),
    );

    _classes.add(newClass);
    return ApiResponse.success(newClass);
  }

  @override
  Future<ApiResponse<SchoolClassModel>> updateClass({
    required String id,
    required String name,
    required String grade,
    String? description,
  }) async {
    await Future.delayed(const Duration(milliseconds: 350));
    final index = _classes.indexWhere((c) => c.id == id);
    if (index == -1) return ApiResponse.failure('NOT_FOUND', 'Kelas tidak ditemukan');

    final updated = _classes[index].copyWith(
      name: name,
      grade: grade,
      description: description,
    );
    _classes[index] = updated;
    return ApiResponse.success(updated);
  }

  @override
  Future<ApiResponse<bool>> archiveClass(String id) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final index = _classes.indexWhere((c) => c.id == id);
    if (index != -1) {
      _classes[index] = _classes[index].copyWith(status: 'ARCHIVED');
      return ApiResponse.success(true);
    }
    return ApiResponse.failure('NOT_FOUND', 'Kelas tidak ditemukan');
  }

  @override
  Future<ApiResponse<List<StudentProfileModel>>> getClassStudents(String classId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return ApiResponse.success(_classStudents[classId] ?? []);
  }

  @override
  Future<ApiResponse<String>> generateClassCode(String classId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final index = _classes.indexWhere((c) => c.id == classId);
    if (index == -1) return ApiResponse.failure('NOT_FOUND', 'Kelas tidak ditemukan');

    final newCode = '${_classes[index].grade}-${_uuid.v4().substring(0, 4).toUpperCase()}';
    _classes[index] = _classes[index].copyWith(joinCode: newCode);
    return ApiResponse.success(newCode);
  }

  @override
  Future<ApiResponse<bool>> deleteClass(String id) async {
    return archiveClass(id);
  }

  @override
  Future<ApiResponse<bool>> removeStudentFromClass({required String classId, required String studentId}) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _classStudents[classId]?.removeWhere((s) => s.id == studentId || s.studentId == studentId);
    return ApiResponse.success(true);
  }

  @override
  Future<ApiResponse<bool>> studentLeaveClass() async {
    await Future.delayed(const Duration(milliseconds: 300));
    _ref.read(authControllerProvider.notifier).clearStudentClass();
    return ApiResponse.success(true);
  }

  @override
  Future<ApiResponse<StudentProfileModel>> studentSelectClass(String classId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final cls = _classes.firstWhere(
      (c) => c.id == classId,
      orElse: () => SchoolClassModel(
        id: classId,
        schoolId: 'SCH_001',
        name: 'Kelas Terpilih',
        grade: 'X',
        joinCode: 'KLS-001',
        studentCount: 1,
        createdAt: DateTime.now(),
      ),
    );
    final currentStudent = _ref.read(authControllerProvider).studentProfile;
    if (currentStudent != null) {
      final updated = currentStudent.copyWith(classId: cls.id, className: cls.name);
      _ref.read(authControllerProvider.notifier).updateStudentProfile(updated);
      return ApiResponse.success(updated);
    }
    return ApiResponse.failure('NOT_FOUND', 'Profil siswa tidak ditemukan');
  }

  @override
  Future<ApiResponse<bool>> counselorLeaveSchool() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return ApiResponse.success(true);
  }
}

class ApiClassRepository implements ClassRepository {
  final ApiClient _apiClient;

  ApiClassRepository(this._apiClient);

  @override
  Future<ApiResponse<List<SchoolClassModel>>> getClasses() async {
    return await _apiClient.get<List<SchoolClassModel>>(
      '/api/classes',
      fromJsonT: (data) =>
          (data as List).map((i) => SchoolClassModel.fromJson(i)).toList(),
    );
  }

  @override
  Future<ApiResponse<SchoolClassModel>> addClass({
    required String name,
    required String grade,
    String? description,
  }) async {
    return await _apiClient.post<SchoolClassModel>(
      '/api/classes',
      data: {'name': name, 'grade': grade, 'description': description},
      fromJsonT: (data) => SchoolClassModel.fromJson(data),
    );
  }

  @override
  Future<ApiResponse<SchoolClassModel>> updateClass({
    required String id,
    required String name,
    required String grade,
    String? description,
  }) async {
    return await _apiClient.patch<SchoolClassModel>(
      '/api/classes/$id',
      data: {'name': name, 'grade': grade, 'description': description},
      fromJsonT: (data) => SchoolClassModel.fromJson(data),
    );
  }

  @override
  Future<ApiResponse<bool>> archiveClass(String id) async {
    final res = await _apiClient.delete('/api/classes/$id');
    return ApiResponse.success(res.success);
  }

  @override
  Future<ApiResponse<bool>> deleteClass(String id) async {
    final res = await _apiClient.delete('/api/classes/$id');
    return ApiResponse.success(res.success);
  }

  @override
  Future<ApiResponse<List<StudentProfileModel>>> getClassStudents(String classId) async {
    return await _apiClient.get<List<StudentProfileModel>>(
      '/api/classes/$classId/students',
      fromJsonT: (data) =>
          (data as List).map((i) => StudentProfileModel.fromJson(i)).toList(),
    );
  }

  @override
  Future<ApiResponse<String>> generateClassCode(String classId) async {
    final res = await _apiClient.post<Map<String, dynamic>>('/api/classes/$classId/code');
    if (res.success && res.data != null) {
      return ApiResponse.success(res.data!['join_code'] as String);
    }
    return ApiResponse.failure('ERROR', 'Gagal membuat kode kelas baru');
  }

  @override
  Future<ApiResponse<bool>> removeStudentFromClass({required String classId, required String studentId}) async {
    final res = await _apiClient.delete('/api/classes/$classId/students/$studentId');
    return ApiResponse.success(res.success);
  }

  @override
  Future<ApiResponse<bool>> studentLeaveClass() async {
    final res = await _apiClient.post('/api/students/leave-class');
    return ApiResponse.success(res.success);
  }

  @override
  Future<ApiResponse<StudentProfileModel>> studentSelectClass(String classId) async {
    return await _apiClient.post<StudentProfileModel>(
      '/api/students/select-class',
      data: {'class_id': classId},
      fromJsonT: (data) => StudentProfileModel.fromJson(data),
    );
  }

  @override
  Future<ApiResponse<bool>> counselorLeaveSchool() async {
    final res = await _apiClient.post('/api/schools/leave');
    return ApiResponse.success(res.success);
  }
}

final classRepositoryProvider = Provider<ClassRepository>((ref) {
  final useMock = ref.watch(useMockBackendProvider);
  if (useMock) {
    return MockClassRepository(ref);
  } else {
    return ApiClassRepository(ref.watch(apiClientProvider));
  }
});
