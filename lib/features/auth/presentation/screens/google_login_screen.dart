import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../shared/widgets/google_logo.dart';
import '../auth_controller.dart';

/// Halaman "Masuk dengan Google"
/// Menggunakan Google Sign-In asli dengan OAuth Client ID
class GoogleLoginScreen extends ConsumerStatefulWidget {
  const GoogleLoginScreen({super.key});

  @override
  ConsumerState<GoogleLoginScreen> createState() => _GoogleLoginScreenState();
}

class _GoogleLoginScreenState extends ConsumerState<GoogleLoginScreen> {
  bool _isLoading = false;

  /// Ubah ke `false` (atau hapus) jika sudah selesai mengecek tampilan desain.
  static const bool _showDemoButtons = true;

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId: kIsWeb
        ? '723964448592-s3qqu5jhj2bmb8vpc1n5ahg9cbh2gm11.apps.googleusercontent.com'
        : null,
    scopes: ['email', 'profile'],
  );

  // ─── Mode Demo / Pratinjau Desain Tanpa Google OAuth ─────────────────────
  Future<void> _loginAsDemo({required bool isCounselor}) async {
    setState(() => _isLoading = true);
    try {
      final name = isCounselor ? 'Dra. Rahmawati, M.Pd' : 'Budi Prakoso';
      final email = isCounselor
          ? 'counselor.demo@suarasiswa.id'
          : 'student.demo@suarasiswa.id';
      final uid = isCounselor ? 'demo_counselor_999' : 'demo_student_999';

      final success = await ref.read(authControllerProvider.notifier).loginWithGoogle(
            googleUid: uid,
            email: email,
            name: name,
          );

      if (!mounted) return;
      setState(() => _isLoading = false);

      if (success) {
        final authState = ref.read(authControllerProvider);
        if (authState.membership != null) {
          context.go(authState.isCounselor ? '/counselor' : '/student');
        } else {
          context.go(isCounselor ? '/counselor' : '/student');
        }
      } else {
        context.go(isCounselor ? '/counselor' : '/student');
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
        context.go(isCounselor ? '/counselor' : '/student');
      }
    }
  }

  // ─── Direct Login Processing ──────────────────────────────────────────────
  Future<void> _processLoginWithGoogle({
    required String googleUid,
    required String email,
    required String name,
    String? photoUrl,
  }) async {
    setState(() => _isLoading = true);

    try {
      final success = await ref.read(authControllerProvider.notifier).loginWithGoogle(
        googleUid: googleUid,
        email: email,
        name: name,
        photoUrl: photoUrl,
      );

      if (!mounted) return;
      setState(() => _isLoading = false);

      if (success) {
        final authState = ref.read(authControllerProvider);
        if (authState.membership != null) {
          if (authState.isCounselor) {
            context.go('/counselor');
          } else {
            context.go('/student');
          }
        } else {
          _showRoleSelectionSheet(name: name, email: email, photoUrl: photoUrl);
        }
      } else {
        final error = ref.read(authControllerProvider).errorMessage ?? 'Gagal memproses akun.';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error), backgroundColor: AppColors.primary),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.primary),
        );
      }
    }
  }

  // ─── Real Google Sign-In (100% Real Google OAuth) ───────────────────────────
  Future<void> _signInWithGoogle() async {
    setState(() => _isLoading = true);

    try {
      try {
        await _googleSignIn.signOut();
      } catch (_) {}

      final GoogleSignInAccount? account = await _googleSignIn.signIn();

      if (account == null) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      final displayName = account.displayName;
      final name = (displayName != null && displayName.trim().isNotEmpty)
          ? displayName.trim()
          : account.email.split('@')[0];

      await _processLoginWithGoogle(
        googleUid: account.id,
        email: account.email,
        name: name,
        photoUrl: account.photoUrl,
      );
    } catch (e) {
      debugPrint('Google OAuth Error: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        final isAndroidOAuthConfigurationError =
            e.toString().contains('ApiException: 10');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isAndroidOAuthConfigurationError
                  ? 'Login Google belum dikonfigurasi untuk aplikasi Android ini.'
                  : 'Login Google gagal. Silakan coba lagi.',
            ),
            backgroundColor: AppColors.primary,
          ),
        );
      }
    }
  }

  void _showRoleSelectionSheet({
    required String name,
    required String email,
    String? photoUrl,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _RoleSelectionSheet(
        userName: name,
        userEmail: email,
        userPhoto: photoUrl,
        onSelectRole: (role) {
          Navigator.pop(ctx);
          if (role == 'student') {
            context.push('/student/join-school');
          } else if (role == 'counselor') {
            context.push('/counselor/create-school');
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.slate800),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/welcome');
            }
          },
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Image.asset(
                'assets/images/logo.png',
                width: 22,
                height: 22,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              'SuaraSiswa',
              style: TextStyle(
                color: AppColors.slate900,
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
          ],
        ),
        centerTitle: false,
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight,
                ),
                child: IntrinsicHeight(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 20),

                      // Clean Brand Icon Surface
                      Center(
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: AppColors.borderStrong,
                              width: 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.slate900.withOpacity(0.04),
                                blurRadius: 16,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: Padding(
                              padding: const EdgeInsets.all(15),
                              child: Image.asset(
                                'assets/images/logo.png',
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Title & Empathetic Subtitle
                      const Text(
                        'Masuk ke SuaraSiswa',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: AppColors.slate900,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Gunakan akun Google Anda untuk mengakses ruang sekolah. Data laporan dan aspirasi Anda dirahasiakan dan ditangani oleh pihak berwenang.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13.5,
                          color: AppColors.slate600,
                          height: 1.45,
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Google Sign-In Action
                      _OfficialGoogleButton(
                        isLoading: _isLoading,
                        onPressed: _isLoading ? null : _signInWithGoogle,
                      ),

                      // Mode Pratinjau Desain (Bypass untuk cek tampilan UI)
                      if (_showDemoButtons) ...[
                        const SizedBox(height: 18),
                        Row(
                          children: [
                            const Expanded(child: Divider(color: AppColors.border)),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 10),
                              child: Text(
                                'ATAU CEK PRATINJAU DESAIN',
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.slate400,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                            const Expanded(child: Divider(color: AppColors.border)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  side: const BorderSide(color: Color(0xFF93C5FD)),
                                  backgroundColor: const Color(0xFFEFF6FF),
                                ),
                                icon: const Icon(Icons.school_outlined, size: 16, color: Color(0xFF2563EB)),
                                label: const Text(
                                  'Tampilan Siswa',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF1E40AF),
                                  ),
                                ),
                                onPressed: _isLoading ? null : () => _loginAsDemo(isCounselor: false),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  side: const BorderSide(color: Color(0xFFFECACA)),
                                  backgroundColor: const Color(0xFFFEF2F2),
                                ),
                                icon: const Icon(Icons.psychology_outlined, size: 16, color: AppColors.primary),
                                label: const Text(
                                  'Tampilan Guru BK',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primary,
                                  ),
                                ),
                                onPressed: _isLoading ? null : () => _loginAsDemo(isCounselor: true),
                              ),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 32),

                      // Trust Guarantees
                      const Text(
                        'Jaminan Keamanan & Privasi',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.slate800,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 14),

                      const _TrustItem(
                        icon: Icons.lock_outline_rounded,
                        title: 'Kerahasiaan Terjaga',
                        subtitle:
                            'Laporan terlindungi dan hanya dapat ditindaklanjuti oleh Guru BK resmi sekolah.',
                      ),
                      const SizedBox(height: 12),
                      const _TrustItem(
                        icon: Icons.visibility_off_outlined,
                        title: 'Dukungan Anonimitas',
                        subtitle:
                            'Siswa dapat menyampaikan aspirasi tanpa menampilkan identitas publik.',
                      ),
                      const SizedBox(height: 12),
                      const _TrustItem(
                        icon: Icons.domain_verification_outlined,
                        title: 'Terhubung ke Sekolah Resmi',
                        subtitle:
                            'Setiap ruang sekolah dikelola secara mandiri oleh tim pendidik sekolah bersangkutan.',
                      ),

                      const Spacer(),
                      const SizedBox(height: 24),

                      // Legal Footer
                      const Text(
                        'Dengan masuk, Anda menyetujui Ketentuan Layanan serta Kebijakan Privasi SuaraSiswa.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.slate400,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

// ─── Clean Google Sign-In Button (Adhering to Google Guidelines) ───────────────
class _OfficialGoogleButton extends StatelessWidget {
  final bool isLoading;
  final VoidCallback? onPressed;

  const _OfficialGoogleButton({required this.isLoading, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: AppColors.slate900,
          side: const BorderSide(color: AppColors.borderStrong, width: 1.2),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16),
        ),
        child: isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.2,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
              )
            : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  GoogleLogo(size: 20),
                  SizedBox(width: 12),
                  Text(
                    'Lanjutkan dengan Google',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: AppColors.slate900,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

// ─── Trust Item ───────────────────────────────────────────────────────────────
class _TrustItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _TrustItem({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: AppColors.slate100,
            borderRadius: BorderRadius.circular(9),
          ),
          child: Icon(icon, size: 18, color: AppColors.slate700),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.slate800,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.slate600,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Role Selection Bottom Sheet ─────────────────────────────────────────────
class _RoleSelectionSheet extends StatelessWidget {
  final String userName;
  final String userEmail;
  final String? userPhoto;
  final void Function(String role) onSelectRole;

  const _RoleSelectionSheet({
    required this.userName,
    required this.userEmail,
    this.userPhoto,
    required this.onSelectRole,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
        24,
        14,
        24,
        MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag Handle
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.slate300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 18),

          // User Profile Info
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.slate50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.borderStrong),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: AppColors.lightRed,
                  backgroundImage:
                      userPhoto != null ? NetworkImage(userPhoto!) : null,
                  child: userPhoto == null
                      ? Text(
                          userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        userName,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.slate900,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        userEmail,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.slate600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.check_circle_rounded,
                  size: 18,
                  color: AppColors.success,
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),

          const Text(
            'Lanjutkan Sebagai',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.slate900,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Pilih peran Anda untuk mengatur ruang sekolah dan akses layanan:',
            style: TextStyle(
              fontSize: 13,
              color: AppColors.slate600,
            ),
          ),
          const SizedBox(height: 16),

          // Role 1: Siswa
          _SelectableRoleCard(
            title: 'Siswa / Peserta Didik',
            description:
                'Sampaikan pengaduan, kritik, saran, serta aspirasi sekolah secara aman dan rahasia.',
            icon: Icons.school_outlined,
            accentColor: const Color(0xFF2563EB),
            backgroundColor: const Color(0xFFEFF6FF),
            onTap: () => onSelectRole('student'),
          ),
          const SizedBox(height: 12),

          // Role 2: Guru BK
          _SelectableRoleCard(
            title: 'Guru BK / Konselor',
            description:
                'Buat atau kelola ruang sekolah, verifikasi kelas, dan tangani aspirasi maupun laporan siswa.',
            icon: Icons.supervisor_account_outlined,
            accentColor: AppColors.primary,
            backgroundColor: AppColors.lightRed,
            onTap: () => onSelectRole('counselor'),
          ),
        ],
      ),
    );
  }
}

class _SelectableRoleCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final Color accentColor;
  final Color backgroundColor;
  final VoidCallback onTap;

  const _SelectableRoleCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.accentColor,
    required this.backgroundColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.borderStrong),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: backgroundColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: accentColor, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.slate900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.slate600,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Padding(
                padding: EdgeInsets.only(top: 10),
                child: Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: AppColors.slate400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
