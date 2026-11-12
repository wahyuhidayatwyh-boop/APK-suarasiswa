import 'dart:convert';
import 'package:uuid/uuid.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_response.dart';
import '../../../core/storage/storage_service.dart';
import '../../../shared/models/school_model.dart';
import '../../../shared/models/user_model.dart';

abstract class AuthRepository {
  Future<ApiResponse<Map<String, dynamic>>> loginWithGoogle({
    required String googleUid,
    required String email,
    required String name,
    String? photoUrl,
  });

  Future<ApiResponse<Map<String, dynamic>>> createSchool({
    required String schoolName,
    required String counselorName,
    String? nip,
    String? phone,
    String? address,
  });

  Future<ApiResponse<Map<String, dynamic>>> joinSchoolAsCounselor({
    required String inviteCode,
    required String counselorName,
    String? nip,
    String? phone,
  });

  Future<ApiResponse<Map<String, dynamic>>> joinSchoolAsStudent({
    required String schoolCode,
    String? classCode,
    required String studentId, // NIS
    required String studentName,
    String? phone,
  });

  Future<ApiResponse<Map<String, dynamic>>> getSession();
  Future<void> logout();
}

class MockAuthRepository implements AuthRepository {
  final StorageService _storageService;
  final Uuid _uuid = const Uuid();

  // In-memory mock database state
  UserModel? _mockUser;
  SchoolModel? _mockSchool;
  SchoolMembershipModel? _mockMembership;
  CounselorProfileModel? _mockCounselorProfile;
  StudentProfileModel? _mockStudentProfile;

  MockAuthRepository(this._storageService) {
    _initDefaults();
  }

  void _initDefaults() {
    // Clean - no pre-populated mock school
  }

  @override
  Future<ApiResponse<Map<String, dynamic>>> loginWithGoogle({
    required String googleUid,
    required String email,
    required String name,
    String? photoUrl,
  }) async {
    await Future.delayed(const Duration(milliseconds: 600));

    final user = UserModel(
      id: 'USR_${_uuid.v4().substring(0, 8)}',
      googleUid: googleUid,
      email: email,
      name: name,
      photoUrl: photoUrl,
      createdAt: DateTime.now(),
    );
    _mockUser = user;

    await _storageService.saveAuthToken('mock_jwt_token_${user.id}');
    await _storageService.saveUserData(jsonEncode(user.toJson()));

    return ApiResponse.success({
      'user': user.toJson(),
      'membership': _mockMembership?.toJson(),
      'school': _mockSchool != null && _mockMembership != null ? _mockSchool!.toJson() : null,
      'counselor_profile': _mockCounselorProfile?.toJson(),
      'student_profile': _mockStudentProfile?.toJson(),
      'token': 'mock_jwt_token_${user.id}',
    });
  }

  @override
  Future<ApiResponse<Map<String, dynamic>>> createSchool({
    required String schoolName,
    required String counselorName,
    String? nip,
    String? phone,
    String? address,
  }) async {
    await Future.delayed(const Duration(milliseconds: 700));

    if (_mockUser == null) {
      return ApiResponse.failure('UNAUTHORIZED', 'Silakan masuk dengan akun Google terlebih dahulu.');
    }

    final schoolId = 'SCH_${_uuid.v4().substring(0, 6).toUpperCase()}';
    // Generate readable school code like SMK-TN82 or SKL-XXXX
    final prefix = schoolName.length >= 3
        ? schoolName.substring(0, 3).toUpperCase().replaceAll(RegExp(r'[^A-Z]'), 'S')
        : 'SCH';
    final randomSuffix = _uuid.v4().substring(0, 4).toUpperCase();
    final schoolCode = '$prefix-$randomSuffix';

    final school = SchoolModel(
      id: schoolId,
      name: schoolName,
      schoolCode: schoolCode,
      address: address,
      ownerUserId: _mockUser!.id,
      createdAt: DateTime.now(),
    );

    final membership = SchoolMembershipModel(
      id: 'MEM_${_uuid.v4().substring(0, 8)}',
      schoolId: school.id,
      userId: _mockUser!.id,
      role: UserRole.counselor,
      isOwner: true,
      status: 'ACTIVE',
      joinedAt: DateTime.now(),
    );

    final counselorProfile = CounselorProfileModel(
      id: 'PRF_${_uuid.v4().substring(0, 8)}',
      userId: _mockUser!.id,
      schoolId: school.id,
      name: counselorName,
      employeeId: nip,
      phone: phone,
    );

    _mockSchool = school;
    _mockMembership = membership;
    _mockCounselorProfile = counselorProfile;

    await _storageService.saveActiveSchoolId(school.id);

    return ApiResponse.success({
      'school': school.toJson(),
      'membership': membership.toJson(),
      'counselor_profile': counselorProfile.toJson(),
    });
  }

  @override
  Future<ApiResponse<Map<String, dynamic>>> joinSchoolAsCounselor({
    required String inviteCode,
    required String counselorName,
    String? nip,
    String? phone,
  }) async {
    await Future.delayed(const Duration(milliseconds: 600));

    if (_mockUser == null) {
      return ApiResponse.failure('UNAUTHORIZED', 'Silakan login Google terlebih dahulu.');
    }

    // Check valid invite code pattern (e.g. BK-SCH001-X92K)
    if (!inviteCode.toUpperCase().startsWith('BK-')) {
      return ApiResponse.failure('INVALID_CODE', 'Kode undangan Guru BK tidak valid atau telah kadaluarsa.');
    }

    final school = _mockSchool ??
        SchoolModel(
          id: 'SCH_001',
          name: 'SMK Teknologi Nusantara',
          schoolCode: 'SMK-TN82',
          ownerUserId: 'USR_OWNER',
          createdAt: DateTime.now(),
        );

    final membership = SchoolMembershipModel(
      id: 'MEM_${_uuid.v4().substring(0, 8)}',
      schoolId: school.id,
      userId: _mockUser!.id,
      role: UserRole.counselor,
      isOwner: false,
      joinedAt: DateTime.now(),
    );

    final profile = CounselorProfileModel(
      id: 'PRF_${_uuid.v4().substring(0, 8)}',
      userId: _mockUser!.id,
      schoolId: school.id,
      name: counselorName,
      employeeId: nip,
      phone: phone,
    );

    _mockSchool = school;
    _mockMembership = membership;
    _mockCounselorProfile = profile;

    await _storageService.saveActiveSchoolId(school.id);

    return ApiResponse.success({
      'school': school.toJson(),
      'membership': membership.toJson(),
      'counselor_profile': profile.toJson(),
    });
  }

  @override
  Future<ApiResponse<Map<String, dynamic>>> joinSchoolAsStudent({
    required String schoolCode,
    String? classCode,
    required String studentId, // NIS
    required String studentName,
    String? phone,
  }) async {
    await Future.delayed(const Duration(milliseconds: 700));

    if (_mockUser == null) {
      return ApiResponse.failure('UNAUTHORIZED', 'Silakan masuk dengan akun Google terlebih dahulu.');
    }

    // Verify school code (accept SMK-TN82 or any current school code)
    if (schoolCode.trim().toUpperCase() != 'SMK-TN82' &&
        (_mockSchool == null || schoolCode.trim().toUpperCase() != _mockSchool!.schoolCode.toUpperCase())) {
      return ApiResponse.failure('SCHOOL_NOT_FOUND', 'Kode sekolah tidak ditemukan. Periksa kembali penulisan kode.');
    }

    final targetSchool = _mockSchool ??
        SchoolModel(
          id: 'SCH_001',
          name: 'SMK Teknologi Nusantara',
          schoolCode: 'SMK-TN82',
          ownerUserId: 'USR_DEMO',
          createdAt: DateTime.now(),
        );

    final membership = SchoolMembershipModel(
      id: 'MEM_${_uuid.v4().substring(0, 8)}',
      schoolId: targetSchool.id,
      userId: _mockUser!.id,
      role: UserRole.student,
      isOwner: false,
      joinedAt: DateTime.now(),
    );

    // Identify class from code if provided, otherwise null
    final classId = (classCode != null && classCode.isNotEmpty)
        ? 'CLS_${classCode.toUpperCase().replaceAll('-', '_')}'
        : null;
    final className = (classCode != null && classCode.isNotEmpty)
        ? (classCode.toUpperCase().contains('RPL') ? 'XI RPL 1' : classCode)
        : null;

    final studentProfile = StudentProfileModel(
      id: 'STU_${_uuid.v4().substring(0, 8)}',
      userId: _mockUser!.id,
      schoolId: targetSchool.id,
      classId: classId,
      className: className,
      studentId: studentId,
      name: studentName,
      phone: phone,
    );

    _mockSchool = targetSchool;
    _mockMembership = membership;
    _mockStudentProfile = studentProfile;

    await _storageService.saveActiveSchoolId(targetSchool.id);

    return ApiResponse.success({
      'school': targetSchool.toJson(),
      'membership': membership.toJson(),
      'student_profile': studentProfile.toJson(),
    });
  }

  @override
  Future<ApiResponse<Map<String, dynamic>>> getSession() async {
    final token = await _storageService.getAuthToken();
    if (token == null) {
      return ApiResponse.failure('NO_SESSION', 'Belum ada sesi aktif');
    }

    final userDataStr = _storageService.getUserData();
    if (userDataStr != null) {
      try {
        _mockUser = UserModel.fromJson(jsonDecode(userDataStr));
      } catch (_) {}
    }

    if (_mockUser == null) {
      return ApiResponse.failure('NO_SESSION', 'Data sesi tidak ditemukan');
    }

    return ApiResponse.success({
      'user': _mockUser?.toJson(),
      'membership': _mockMembership?.toJson(),
      'school': _mockSchool != null && _mockMembership != null ? _mockSchool!.toJson() : null,
      'counselor_profile': _mockCounselorProfile?.toJson(),
      'student_profile': _mockStudentProfile?.toJson(),
    });
  }

  @override
  Future<void> logout() async {
    _mockUser = null;
    _mockMembership = null;
    _mockCounselorProfile = null;
    _mockStudentProfile = null;
    await _storageService.clearAll();
  }
}

class ApiAuthRepository implements AuthRepository {
  final ApiClient _apiClient;
  final StorageService _storageService;

  ApiAuthRepository(this._apiClient, this._storageService);

  @override
  Future<ApiResponse<Map<String, dynamic>>> loginWithGoogle({
    required String googleUid,
    required String email,
    required String name,
    String? photoUrl,
  }) async {
    final res = await _apiClient.post<Map<String, dynamic>>(
      '/api/auth/google',
      data: {
        'google_uid': googleUid,
        'email': email,
        'name': name,
        'photo_url': photoUrl,
      },
    );
    if (res.success && res.data != null) {
      final token = res.data!['token'] as String?;
      if (token != null) await _storageService.saveAuthToken(token);
      final school = res.data!['school'];
      if (school != null && school['id'] != null) {
        await _storageService.saveActiveSchoolId(school['id'] as String);
      }
      final user = res.data!['user'];
      if (user != null) {
        await _storageService.saveUserData(jsonEncode(user));
      }
    }
    return res;
  }

  @override
  Future<ApiResponse<Map<String, dynamic>>> createSchool({
    required String schoolName,
    required String counselorName,
    String? nip,
    String? phone,
    String? address,
  }) async {
    final res = await _apiClient.post<Map<String, dynamic>>(
      '/api/schools',
      data: {
        'school_name': schoolName,
        'counselor_name': counselorName,
        'nip': nip,
        'phone': phone,
        'address': address,
      },
    );
    if (res.success && res.data != null) {
      final school = res.data!['school'];
      if (school != null && school['id'] != null) {
        await _storageService.saveActiveSchoolId(school['id'] as String);
      }
    }
    return res;
  }

  @override
  Future<ApiResponse<Map<String, dynamic>>> joinSchoolAsCounselor({
    required String inviteCode,
    required String counselorName,
    String? nip,
    String? phone,
  }) async {
    final res = await _apiClient.post<Map<String, dynamic>>(
      '/api/counselors/join',
      data: {
        'invite_code': inviteCode,
        'name': counselorName,
        'nip': nip,
        'phone': phone,
      },
    );
    if (res.success && res.data != null) {
      final school = res.data!['school'];
      if (school != null && school['id'] != null) {
        await _storageService.saveActiveSchoolId(school['id'] as String);
      }
    }
    return res;
  }

  @override
  Future<ApiResponse<Map<String, dynamic>>> joinSchoolAsStudent({
    required String schoolCode,
    String? classCode,
    required String studentId,
    required String studentName,
    String? phone,
  }) async {
    final Map<String, dynamic> payload = {
      'school_code': schoolCode,
      'student_id': studentId,
      'student_name': studentName,
      'phone': phone,
    };
    if (classCode != null && classCode.isNotEmpty) {
      payload['class_code'] = classCode;
    }
    final res = await _apiClient.post<Map<String, dynamic>>(
      '/api/students/join',
      data: payload,
    );
    if (res.success && res.data != null) {
      final school = res.data!['school'];
      if (school != null && school['id'] != null) {
        await _storageService.saveActiveSchoolId(school['id'] as String);
      }
    }
    return res;
  }

  @override
  Future<ApiResponse<Map<String, dynamic>>> getSession() async {
    final res = await _apiClient.get<Map<String, dynamic>>('/api/auth/me');
    if (res.success && res.data != null) {
      final school = res.data!['school'];
      if (school != null && school['id'] != null) {
        await _storageService.saveActiveSchoolId(school['id'] as String);
      }
    }
    return res;
  }

  @override
  Future<void> logout() async {
    try {
      await _apiClient.post('/api/auth/logout');
    } catch (_) {}
    await _storageService.clearAll();
  }
}
