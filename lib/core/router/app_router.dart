import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/screens/google_login_screen.dart';
import '../../features/auth/presentation/screens/onboarding_screen.dart';
import '../../features/auth/presentation/screens/splash_screen.dart';
import '../../features/auth/presentation/screens/welcome_screen.dart';
import '../../features/chat/presentation/screens/report_chat_screen.dart';
import '../../features/classes/presentation/screens/counselor_classes_screen.dart';
import '../../features/counselors/presentation/screens/counselor_invites_screen.dart';
import '../../features/counselors/presentation/screens/counselor_main_shell.dart';
import '../../features/education/presentation/screens/counselor_content_screen.dart';
import '../../features/education/presentation/screens/education_detail_screen.dart';
import '../../features/notifications/presentation/screens/notifications_screen.dart';
import '../../features/profile/presentation/screens/settings_info_screen.dart';
import '../../features/reports/presentation/screens/create_report_screen.dart';
import '../../features/reports/presentation/screens/report_detail_screen.dart';
import '../../features/reports/presentation/screens/report_list_screen.dart';
import '../../features/school/presentation/screens/counselor_create_school_screen.dart';
import '../../features/school/presentation/screens/counselor_join_school_screen.dart';
import '../../features/school/presentation/screens/counselor_school_setup_screen.dart';
import '../../features/school/presentation/screens/student_join_school_screen.dart';
import '../../features/students/presentation/screens/student_main_shell.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: '/onboarding',
      builder: (context, state) => const OnboardingScreen(),
    ),
    GoRoute(
      path: '/welcome',
      builder: (context, state) => const WelcomeScreen(),
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) => const GoogleLoginScreen(),
    ),
    // Student Routes
    GoRoute(
      path: '/student',
      builder: (context, state) => const StudentMainShell(),
    ),
    GoRoute(
      path: '/student/join-school',
      builder: (context, state) => const StudentJoinSchoolScreen(),
    ),
    GoRoute(
      path: '/student/create-report',
      builder: (context, state) {
        final initialType = state.uri.queryParameters['type'];
        return CreateReportScreen(initialType: initialType);
      },
    ),
    GoRoute(
      path: '/student/reports',
      builder: (context, state) {
        final initialStatus = state.uri.queryParameters['status'];
        return ReportListScreen(isCounselor: false, initialStatus: initialStatus);
      },
    ),
    GoRoute(
      path: '/student/reports/:id',
      builder: (context, state) {
        final id = state.pathParameters['id'] ?? '';
        return ReportDetailScreen(reportId: id);
      },
    ),
    GoRoute(
      path: '/student/reports/:id/chat',
      builder: (context, state) {
        final id = state.pathParameters['id'] ?? '';
        return ReportChatScreen(reportId: id);
      },
    ),
    // Counselor Routes
    GoRoute(
      path: '/counselor',
      builder: (context, state) => const CounselorMainShell(),
    ),
    GoRoute(
      path: '/counselor/create-school',
      builder: (context, state) => const CounselorCreateSchoolScreen(),
    ),
    GoRoute(
      path: '/counselor/school-setup',
      builder: (context, state) => const CounselorSchoolSetupScreen(),
    ),
    GoRoute(
      path: '/counselor/join-school',
      builder: (context, state) => const CounselorJoinSchoolScreen(),
    ),
    GoRoute(
      path: '/counselor/reports',
      builder: (context, state) {
        final initialStatus = state.uri.queryParameters['status'];
        return ReportListScreen(isCounselor: true, initialStatus: initialStatus);
      },
    ),
    GoRoute(
      path: '/counselor/reports/:id',
      builder: (context, state) {
        final id = state.pathParameters['id'] ?? '';
        return ReportDetailScreen(reportId: id);
      },
    ),
    GoRoute(
      path: '/counselor/reports/:id/chat',
      builder: (context, state) {
        final id = state.pathParameters['id'] ?? '';
        return ReportChatScreen(reportId: id);
      },
    ),
    GoRoute(
      path: '/counselor/classes',
      builder: (context, state) => const CounselorClassesScreen(),
    ),
    GoRoute(
      path: '/counselor/invitations',
      builder: (context, state) => const CounselorInvitesScreen(),
    ),
    GoRoute(
      path: '/counselor/content',
      builder: (context, state) => const CounselorContentScreen(),
    ),
    // Shared Detail Routes
    GoRoute(
      path: '/reports/:id',
      builder: (context, state) {
        final id = state.pathParameters['id'] ?? '';
        return ReportDetailScreen(reportId: id);
      },
    ),
    GoRoute(
      path: '/reports/:id/chat',
      builder: (context, state) {
        final id = state.pathParameters['id'] ?? '';
        return ReportChatScreen(reportId: id);
      },
    ),
    GoRoute(
      path: '/education/:id',
      builder: (context, state) {
        final id = state.pathParameters['id'] ?? '';
        return EducationDetailScreen(contentId: id);
      },
    ),
    GoRoute(
      path: '/notifications',
      builder: (context, state) => const NotificationsScreen(),
    ),
    GoRoute(
      path: '/settings/notifications',
      builder: (context, state) => const SettingsInfoScreen(notifications: true),
    ),
    GoRoute(
      path: '/settings/privacy',
      builder: (context, state) => const SettingsInfoScreen(notifications: false),
    ),
  ],
);
