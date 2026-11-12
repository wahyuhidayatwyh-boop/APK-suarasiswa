import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../../../core/constants/app_colors.dart';
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

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    // Android identifies the app through its package name and signing SHA-1.
    // Passing the web client ID here makes the Android plugin request an ID
    // token for that client, which results in ApiException: 10 when it is not
    // configured for this Android application.
    clientId: kIsWeb
        ? '723964448592-s3qqu5jhj2bmb8vpc1n5ahg9cbh2gm11.apps.googleusercontent.com'
        : null,
    scopes: ['email', 'profile'],
  );

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
      // Selalu sign-out sesi lokal sebelumnya agar Google memunculkan dialog pemilihan akun
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
      builder: (ctx) => _ModernRoleSelectionSheet(
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
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/welcome');
            }
          },
        ),
        title: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Image.asset('assets/images/logo.png', width: 24, height: 24, fit: BoxFit.contain),
            ),
            const SizedBox(width: 8),
            const Text(
              'SuaraSiswa',
              style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700, fontSize: 16),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            children: [
              const SizedBox(height: 36),

              // ─── Illustration ──────────────────────────────────────
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipOval(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Image.asset('assets/images/logo.png', fit: BoxFit.contain),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // ─── Heading ───────────────────────────────────────────
              const Text(
                'Masuk ke SuaraSiswa',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.5,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Gunakan akun Google Anda untuk masuk dengan aman. Perlindungan data dan privasi siswa terjamin 100%.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.5),
              ),
              const SizedBox(height: 40),

              // ─── Satu Tombol Utama: Lanjutkan dengan Google (Grab Style) ───
              _GoogleButton(isLoading: _isLoading, onPressed: _isLoading ? null : _signInWithGoogle),
              const SizedBox(height: 28),

              // Divider
              Row(
                children: [
                  Expanded(child: Divider(color: AppColors.border.withOpacity(0.8))),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 14),
                    child: Text(
                      'STANDAR KEAMANAN',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textTertiary,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                  Expanded(child: Divider(color: AppColors.border.withOpacity(0.8))),
                ],
              ),
              const SizedBox(height: 20),

              // ─── Security Features ─────────────────────────────────
              _SecurityFeature(
                icon: Icons.shield_outlined,
                title: 'Data Rahasia & Terenkripsi',
                subtitle: 'Aspirasi dan laporan terlindungi dengan standar enkripsi modern',
              ),
              const SizedBox(height: 12),
              _SecurityFeature(
                icon: Icons.visibility_off_outlined,
                title: 'Mode Anonim Aman',
                subtitle: 'Identitas siswa dirahasiakan dan tidak tampak oleh sesama murid',
              ),
              const SizedBox(height: 12),
              _SecurityFeature(
                icon: Icons.verified_user_outlined,
                title: 'Akses Khusus Guru BK Terverifikasi',
                subtitle: 'Hanya staf pendidik yang memiliki wewenang untuk menindaklanjuti',
              ),

              const Spacer(),

              // ─── Legal ────────────────────────────────────────────
              const Text(
                'Dengan masuk, Anda menyetujui Ketentuan Layanan & Kebijakan Privasi SuaraSiswa.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 11, color: AppColors.textTertiary, height: 1.4),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Google Sign-In Button ─────────────────────────────────────────────────────
class _GoogleButton extends StatelessWidget {
  final bool isLoading;
  final VoidCallback? onPressed;

  const _GoogleButton({required this.isLoading, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 15),
          backgroundColor: Colors.white,
          foregroundColor: AppColors.textPrimary,
          elevation: 2,
          shadowColor: Colors.black.withOpacity(0.08),
          side: const BorderSide(color: Color(0xFFE2E8F0), width: 1.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        child: isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2.5, color: AppColors.primary),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Google "G" official colored logo representation
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: const Center(
                      child: Text(
                        'G',
                        style: TextStyle(
                          color: Color(0xFF4285F4),
                          fontWeight: FontWeight.w900,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Lanjutkan dengan Google',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

// ─── Security Feature Row ──────────────────────────────────────────────────────
class _SecurityFeature extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _SecurityFeature({
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
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: const Color(0xFF475569)),
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
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Modern & Simple Role Selection Bottom Sheet ───────────────────────────────
class _ModernRoleSelectionSheet extends StatelessWidget {
  final String userName;
  final String userEmail;
  final String? userPhoto;
  final void Function(String role) onSelectRole;

  const _ModernRoleSelectionSheet({
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
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(24, 16, 24, MediaQuery.of(context).viewInsets.bottom + 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFCBD5E1),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // User info header
          Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: AppColors.lightRed,
                backgroundImage: userPhoto != null ? NetworkImage(userPhoto!) : null,
                child: userPhoto == null
                    ? Text(
                        userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      userName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      userEmail,
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFFECFDF5),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFA7F3D0)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle, size: 12, color: Color(0xFF059669)),
                    SizedBox(width: 4),
                    Text(
                      'Terhubung',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF059669),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),
          const Text(
            'Pilih Peran Anda',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Tentukan hak akses untuk melanjutkan ke aplikasi SuaraSiswa:',
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 18),

          // ─── OPTION 1: SISWA ────────────────────────────────────────
          _ModernRoleCard(
            badgeText: 'Siswa / Murid',
            badgeColor: const Color(0xFF2563EB),
            badgeBg: const Color(0xFFEFF6FF),
            icon: Icons.school_rounded,
            iconColor: const Color(0xFF2563EB),
            iconBg: const Color(0xFFDBEAFE),
            title: 'Daftar sebagai Siswa',
            description: 'Buat laporan pengaduan, sampaikan aspirasi sekolah, dan pantau status penanganan secara rahasia.',
            buttonText: 'Daftar sebagai Siswa',
            isPrimary: true,
            onTap: () => onSelectRole('student'),
          ),

          const SizedBox(height: 14),

          // ─── OPTION 2: GURU ─────────────────────────────────────────
          _ModernRoleCard(
            badgeText: 'Pendidik / Guru BK',
            badgeColor: AppColors.primary,
            badgeBg: AppColors.lightRed,
            icon: Icons.health_and_safety_rounded,
            iconColor: AppColors.primary,
            iconBg: AppColors.lightRed,
            title: 'Daftar sebagai Guru',
            description: 'Kelola ruang sekolah, tangani laporan masuk dari siswa, dan dampingi peserta didik.',
            buttonText: 'Daftar sebagai Guru',
            isPrimary: false,
            onTap: () => onSelectRole('counselor'),
          ),
        ],
      ),
    );
  }
}

class _ModernRoleCard extends StatelessWidget {
  final String badgeText;
  final Color badgeColor;
  final Color badgeBg;
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String title;
  final String description;
  final String buttonText;
  final bool isPrimary;
  final VoidCallback onTap;

  const _ModernRoleCard({
    required this.badgeText,
    required this.badgeColor,
    required this.badgeBg,
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.title,
    required this.description,
    required this.buttonText,
    this.isPrimary = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isPrimary ? const Color(0xFFBFDBFE) : const Color(0xFFE2E8F0),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: isPrimary ? const Color(0xFF2563EB).withOpacity(0.06) : Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: badgeBg,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        badgeText,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: badgeColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            description,
            style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary, height: 1.4),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onTap,
              style: ElevatedButton.styleFrom(
                backgroundColor: isPrimary ? const Color(0xFF2563EB) : AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    buttonText,
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                  ),
                  const SizedBox(width: 6),
                  const Icon(Icons.arrow_forward_rounded, size: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
