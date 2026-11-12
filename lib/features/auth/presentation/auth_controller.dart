import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/network/api_client.dart';
import '../../../core/storage/storage_service.dart';
import '../../../shared/models/school_model.dart';
import '../../../shared/models/user_model.dart';
import '../data/auth_repository.dart';
import '../domain/auth_state.dart';
import 'package:google_sign_in/google_sign_in.dart';

// Providers for dependencies
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('SharedPreferences must be initialized in main');
});

final secureStorageProvider = Provider<FlutterSecureStorage>((ref) {
  return const FlutterSecureStorage();
});

final storageServiceProvider = Provider<StorageService>((ref) {
  return StorageService(
    secureStorage: ref.watch(secureStorageProvider),
    prefs: ref.watch(sharedPreferencesProvider),
  );
});

final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient(storageService: ref.watch(storageServiceProvider));
});

// Configure whether to use Mock or Remote API (false = Real Cloudflare Worker + D1 Database)
final useMockBackendProvider = StateProvider<bool>((ref) => false);

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final useMock = ref.watch(useMockBackendProvider);
  final storage = ref.watch(storageServiceProvider);
  if (useMock) {
    return MockAuthRepository(storage);
  } else {
    return ApiAuthRepository(ref.watch(apiClientProvider), storage);
  }
});

class AuthController extends StateNotifier<AuthState> {
  final AuthRepository _repository;

  AuthController(this._repository) : super(const AuthState());

  Future<void> checkSession() async {
    state = state.copyWith(isLoading: true, clearError: true);
    final response = await _repository.getSession();
    if (response.success && response.data != null) {
      _applySessionData(response.data!);
    } else {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<bool> loginWithGoogle({
    required String googleUid,
    required String email,
    required String name,
    String? photoUrl,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    final response = await _repository.loginWithGoogle(
      googleUid: googleUid,
      email: email,
      name: name,
      photoUrl: photoUrl,
    );

    if (response.success && response.data != null) {
      _applySessionData(response.data!);
      return true;
    } else {
      state = state.copyWith(
        isLoading: false,
        errorMessage: response.error?.message ?? 'Gagal masuk dengan Google.',
      );
      return false;
    }
  }

  Future<bool> createSchool({
    required String schoolName,
    required String counselorName,
    String? nip,
    String? phone,
    String? address,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    final response = await _repository.createSchool(
      schoolName: schoolName,
      counselorName: counselorName,
      nip: nip,
      phone: phone,
      address: address,
    );

    if (response.success && response.data != null) {
      final school = response.data!['school'] != null
          ? SchoolModel.fromJson(response.data!['school'])
          : null;
      final membership = response.data!['membership'] != null
          ? SchoolMembershipModel.fromJson(response.data!['membership'])
          : null;
      final counselor = response.data!['counselor_profile'] != null
          ? CounselorProfileModel.fromJson(response.data!['counselor_profile'])
          : null;

      state = state.copyWith(
        isLoading: false,
        currentSchool: school,
        membership: membership,
        counselorProfile: counselor,
      );
      return true;
    } else {
      state = state.copyWith(
        isLoading: false,
        errorMessage: response.error?.message ?? 'Gagal membuat ruang sekolah.',
      );
      return false;
    }
  }

  Future<bool> joinSchoolAsCounselor({
    required String inviteCode,
    required String counselorName,
    String? nip,
    String? phone,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    final response = await _repository.joinSchoolAsCounselor(
      inviteCode: inviteCode,
      counselorName: counselorName,
      nip: nip,
      phone: phone,
    );

    if (response.success && response.data != null) {
      final school = response.data!['school'] != null
          ? SchoolModel.fromJson(response.data!['school'])
          : null;
      final membership = response.data!['membership'] != null
          ? SchoolMembershipModel.fromJson(response.data!['membership'])
          : null;
      final counselor = response.data!['counselor_profile'] != null
          ? CounselorProfileModel.fromJson(response.data!['counselor_profile'])
          : null;

      state = state.copyWith(
        isLoading: false,
        currentSchool: school,
        membership: membership,
        counselorProfile: counselor,
      );
      return true;
    } else {
      state = state.copyWith(
        isLoading: false,
        errorMessage: response.error?.message ?? 'Gagal bergabung ke sekolah.',
      );
      return false;
    }
  }

  Future<bool> joinSchoolAsStudent({
    required String schoolCode,
    String? classCode,
    required String studentId,
    required String studentName,
    String? phone,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    final response = await _repository.joinSchoolAsStudent(
      schoolCode: schoolCode,
      classCode: classCode,
      studentId: studentId,
      studentName: studentName,
      phone: phone,
    );

    if (response.success && response.data != null) {
      final school = response.data!['school'] != null
          ? SchoolModel.fromJson(response.data!['school'])
          : null;
      final membership = response.data!['membership'] != null
          ? SchoolMembershipModel.fromJson(response.data!['membership'])
          : null;
      final student = response.data!['student_profile'] != null
          ? StudentProfileModel.fromJson(response.data!['student_profile'])
          : null;

      state = state.copyWith(
        isLoading: false,
        currentSchool: school,
        membership: membership,
        studentProfile: student,
      );
      return true;
    } else {
      state = state.copyWith(
        isLoading: false,
        errorMessage: response.error?.message ?? 'Gagal bergabung ke sekolah.',
      );
      return false;
    }
  }

  void updateStudentProfile(StudentProfileModel profile) {
    state = state.copyWith(studentProfile: profile);
  }

  void clearStudentClass() {
    final updated = state.studentProfile?.copyWith(clearClass: true);
    state = state.copyWith(studentProfile: updated);
  }

  Future<void> logout() async {
    try {
      await GoogleSignIn().signOut();
    } catch (_) {}
    await _repository.logout();
    state = const AuthState();
  }

  void _applySessionData(Map<String, dynamic> data) {
    final user = data['user'] != null ? UserModel.fromJson(data['user']) : null;
    final membership = data['membership'] != null
        ? SchoolMembershipModel.fromJson(data['membership'])
        : null;
    final school =
        data['school'] != null ? SchoolModel.fromJson(data['school']) : null;
    final counselor = data['counselor_profile'] != null
        ? CounselorProfileModel.fromJson(data['counselor_profile'])
        : null;
    final student = data['student_profile'] != null
        ? StudentProfileModel.fromJson(data['student_profile'])
        : null;

    state = state.copyWith(
      isLoading: false,
      user: user,
      membership: membership,
      currentSchool: school,
      counselorProfile: counselor,
      studentProfile: student,
    );
  }
}

final authControllerProvider =
    StateNotifierProvider<AuthController, AuthState>((ref) {
  return AuthController(ref.watch(authRepositoryProvider));
});
