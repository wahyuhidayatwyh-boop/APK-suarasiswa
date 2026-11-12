class ApiEndpoints {
  ApiEndpoints._();

  // Base URL (Configurable via environment or remote setting)
  // For local development with wrangler: http://10.0.2.2:8787 (Android emulator) or http://localhost:8787
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://suara-siswa-backend.wahyuhidayat-wyh.workers.dev',
  );

  // Auth
  static const String authGoogle = '/api/auth/google';
  static const String authLogin = '/api/auth/login';
  static const String authRefresh = '/api/auth/refresh';
  static const String authLogout = '/api/auth/logout';
  static const String authMe = '/api/auth/me';

  // Schools
  static const String schools = '/api/schools';
  static const String schoolCurrent = '/api/schools/current';
  static const String schoolJoin = '/api/schools/join';
  static const String schoolFind = '/api/schools/find';

  // Classes
  static const String classes = '/api/classes';
  static String classDetail(String id) => '/api/classes/$id';
  static String classStudents(String id) => '/api/classes/$id/students';

  // Students
  static const String studentJoin = '/api/students/join';
  static const String studentMe = '/api/students/me';

  // Counselors
  static const String counselors = '/api/counselors';
  static const String counselorInvites = '/api/counselors/invites';
  static const String counselorJoin = '/api/counselors/join';

  // Reports
  static const String reports = '/api/reports';
  static String reportDetail(String id) => '/api/reports/$id';
  static String reportStatus(String id) => '/api/reports/$id/status';
  static String reportPriority(String id) => '/api/reports/$id/priority';
  static String reportTimeline(String id) => '/api/reports/$id/timeline';
  static String reportFollowups(String id) => '/api/reports/$id/followups';

  // Messages / Chat
  static String reportMessages(String reportId) =>
      '/api/reports/$reportId/messages';

  // Contents
  static const String contents = '/api/contents';
  static String contentDetail(String id) => '/api/contents/$id';
  static String contentPublish(String id) => '/api/contents/$id/publish';
  static String contentUnpublish(String id) => '/api/contents/$id/unpublish';

  // Uploads
  static const String uploads = '/api/uploads';
  static String attachment(String id) => '/api/attachments/$id';

  // Notifications
  static const String notifications = '/api/notifications';
  static String notificationRead(String id) => '/api/notifications/$id/read';
  static const String notificationReadAll = '/api/notifications/read-all';
  static String notificationDetail(String id) => '/api/notifications/$id';

  // Devices
  static const String deviceRegister = '/api/devices/register';
  static String deviceDelete(String id) => '/api/devices/$id';

  // Membership & Leave
  static String classStudent(String classId, String studentId) =>
      '/api/classes/$classId/students/$studentId';
  static const String studentLeaveClass = '/api/students/leave-class';
  static const String schoolLeave = '/api/schools/leave';
}
