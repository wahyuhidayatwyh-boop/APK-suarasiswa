import '../../../shared/models/school_model.dart';
import '../../../shared/models/user_model.dart';

class AuthState {
  final UserModel? user;
  final SchoolMembershipModel? membership;
  final SchoolModel? currentSchool;
  final CounselorProfileModel? counselorProfile;
  final StudentProfileModel? studentProfile;
  final bool isLoading;
  final String? errorMessage;

  const AuthState({
    this.user,
    this.membership,
    this.currentSchool,
    this.counselorProfile,
    this.studentProfile,
    this.isLoading = false,
    this.errorMessage,
  });

  bool get isAuthenticated => user != null;
  bool get hasSchool => currentSchool != null && membership != null;
  bool get isCounselor => membership?.role == UserRole.counselor;
  bool get isStudent => membership?.role == UserRole.student;
  bool get isOwner => membership?.isOwner ?? false;

  AuthState copyWith({
    UserModel? user,
    SchoolMembershipModel? membership,
    SchoolModel? currentSchool,
    CounselorProfileModel? counselorProfile,
    StudentProfileModel? studentProfile,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
    bool clearSession = false,
  }) {
    if (clearSession) {
      return const AuthState();
    }
    return AuthState(
      user: user ?? this.user,
      membership: membership ?? this.membership,
      currentSchool: currentSchool ?? this.currentSchool,
      counselorProfile: counselorProfile ?? this.counselorProfile,
      studentProfile: studentProfile ?? this.studentProfile,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}
