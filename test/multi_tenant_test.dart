import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:suara_siswa/features/auth/presentation/auth_controller.dart';
import 'package:suara_siswa/features/reports/data/report_repository.dart';
import 'package:suara_siswa/features/classes/data/class_repository.dart';
import 'package:suara_siswa/shared/models/report_model.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ProviderContainer container;
  late SharedPreferences prefs;

  setUp(() async {
    FlutterSecureStorage.setMockInitialValues({});
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();

    container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        useMockBackendProvider.overrideWith((ref) => true),
      ],
    );
  });

  tearDown(() {
    container.dispose();
  });

  group('Multi-Tenant SaaS Onboarding & Isolation Tests', () {
    test('Counselor can login with Google and self-create school space (Owner role)', () async {
      final authController = container.read(authControllerProvider.notifier);

      // 1. Login with Google
      final loggedIn = await authController.loginWithGoogle(
        googleUid: 'google_uid_bambang_999',
        email: 'bambang.bk@smkn1.sch.id',
        name: 'Drs. Bambang Wijaya, M.Pd',
      );
      expect(loggedIn, isTrue);

      final stateAfterLogin = container.read(authControllerProvider);
      expect(stateAfterLogin.isAuthenticated, isTrue);
      expect(stateAfterLogin.hasSchool, isFalse);

      // 2. Self-service School Creation
      final schoolCreated = await authController.createSchool(
        schoolName: 'SMK Negeri 1 Jakarta',
        counselorName: 'Drs. Bambang Wijaya, M.Pd',
        nip: '198205122008011005',
        phone: '081234567890',
        address: 'Jl. Budi Utomo No. 7, Jakarta Pusat',
      );
      expect(schoolCreated, isTrue);

      final stateAfterSchool = container.read(authControllerProvider);
      expect(stateAfterSchool.hasSchool, isTrue);
      expect(stateAfterSchool.isCounselor, isTrue);
      expect(stateAfterSchool.isOwner, isTrue);
      expect(stateAfterSchool.currentSchool?.schoolCode, isNotEmpty);
      expect(stateAfterSchool.currentSchool?.schoolCode, startsWith('SMK-'));
    });

    test('Student can join school using valid school code, class code, and NIS', () async {
      final authController = container.read(authControllerProvider.notifier);

      // 1. Student login with Google
      await authController.loginWithGoogle(
        googleUid: 'google_student_fauzi_777',
        email: 'fauzi.student@gmail.com',
        name: 'Ahmad Fauzi',
      );

      // 2. Join school
      final joined = await authController.joinSchoolAsStudent(
        schoolCode: 'SMK-TN82',
        classCode: 'RPL1-82KD',
        studentId: '12345',
        studentName: 'Ahmad Fauzi',
        phone: '085712345678',
      );
      expect(joined, isTrue);

      final state = container.read(authControllerProvider);
      expect(state.hasSchool, isTrue);
      expect(state.isStudent, isTrue);
      expect(state.isCounselor, isFalse);
      expect(state.studentProfile?.studentId, equals('12345'));
    });

    test('Student cannot join school with invalid school code', () async {
      final authController = container.read(authControllerProvider.notifier);

      await authController.loginWithGoogle(
        googleUid: 'google_student_fake',
        email: 'fake@gmail.com',
        name: 'Siswa Palsu',
      );

      final joined = await authController.joinSchoolAsStudent(
        schoolCode: 'INVALID-CODE-999',
        classCode: 'RPL1-82KD',
        studentId: '99999',
        studentName: 'Siswa Palsu',
      );
      expect(joined, isFalse);

      final state = container.read(authControllerProvider);
      expect(state.hasSchool, isFalse);
      expect(state.errorMessage, contains('tidak ditemukan'));
    });

    test('Report creation generates secure code and isolated status', () async {
      final authController = container.read(authControllerProvider.notifier);
      await authController.loginWithGoogle(
        googleUid: 'google_student_test',
        email: 'student@test.com',
        name: 'Pelapor Test',
      );
      await authController.joinSchoolAsStudent(
        schoolCode: 'SMK-TN82',
        classCode: 'RPL1-82KD',
        studentId: '12345',
        studentName: 'Pelapor Test',
      );

      final reportRepo = container.read(reportRepositoryProvider);
      final res = await reportRepo.createReport(
        type: ReportType.bullying,
        category: 'Verbal',
        description: 'Tindakan intimidasi verbal berulang di kelas.',
        incidentDate: DateTime.now(),
        incidentLocation: 'Kelas XI RPL 1',
        reporterType: 'KORBAN',
        priority: ReportPriority.urgent,
      );

      expect(res.success, isTrue);
      expect(res.data?.reportCode, startsWith('RPT-'));
      expect(res.data?.status, equals(ReportStatus.submitted));
      expect(res.data?.priority, equals(ReportPriority.urgent));
    });

    test('Private chat is isolated to report messages', () async {
      final reportRepo = container.read(reportRepositoryProvider);

      final msgRes = await reportRepo.sendMessage(
        reportId: 'RPT_001',
        message: 'Halo Guru BK, saya membutuhkan pendampingan.',
      );
      expect(msgRes.success, isTrue);

      final listRes = await reportRepo.getMessages('RPT_001');
      expect(listRes.success, isTrue);
      expect(listRes.data!.any((m) => m.message.contains('pendampingan')), isTrue);
    });

    test('Counselor internal notes are not exposed in standard student view', () async {
      final reportRepo = container.read(reportRepositoryProvider);

      final created = await reportRepo.createReport(
        type: ReportType.bullying,
        category: 'Verbal',
        description: 'Test laporan untuk catatan internal.',
        incidentDate: DateTime.now(),
        incidentLocation: 'Kelas XI RPL 1',
        reporterType: 'KORBAN',
        priority: ReportPriority.normal,
      );
      final rptId = created.data!.id;

      final updateRes = await reportRepo.updateInternalNotes(
        reportId: rptId,
        internalNotes: 'Catatan rahasia wali kelas.',
      );
      expect(updateRes.success, isTrue);

      final report = (await reportRepo.getReportDetail(rptId)).data!;
      // When exported to JSON for student (includeInternalNotes = false)
      final studentJson = report.toJson(includeInternalNotes: false);
      expect(studentJson.containsKey('internal_counselor_notes'), isFalse);
    });

    test('Student joins school without class code, then selects class and can leave class safely', () async {
      final authController = container.read(authControllerProvider.notifier);
      await authController.loginWithGoogle(
        googleUid: 'google_student_fresh_99',
        email: 'fresh@student.sch.id',
        name: 'Siswa Baru Bersih',
      );

      final joined = await authController.joinSchoolAsStudent(
        schoolCode: 'SMK-TN82',
        studentId: '99123',
        studentName: 'Siswa Baru Bersih',
      );
      expect(joined, isTrue);

      final state = container.read(authControllerProvider);
      expect(state.studentProfile?.hasClass, isFalse);
      expect(state.studentProfile?.classId, isNull);

      // Student selects class
      final classRepo = container.read(classRepositoryProvider);
      final selectRes = await classRepo.studentSelectClass('CLS_TEST_01');
      expect(selectRes.success, isTrue);

      final stateWithClass = container.read(authControllerProvider);
      expect(stateWithClass.studentProfile?.hasClass, isTrue);

      // Student leaves class
      final leaveRes = await classRepo.studentLeaveClass();
      expect(leaveRes.success, isTrue);

      final stateAfterLeave = container.read(authControllerProvider);
      expect(stateAfterLeave.studentProfile?.hasClass, isFalse);
      expect(stateAfterLeave.hasSchool, isTrue); // School membership is strictly preserved
    });
  });
}
