import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../shared/widgets/google_logo.dart';

class WelcomeScreen extends ConsumerWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark);
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // ─── Photo Header with Subtle Vignette ────────────────────────────
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: size.height * 0.46,
            child: ShaderMask(
              shaderCallback: (Rect bounds) {
                return const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black,
                    Colors.black,
                    Color(0xD9000000),
                    Color(0x66000000),
                    Colors.transparent,
                  ],
                  stops: [0.0, 0.50, 0.72, 0.88, 1.0],
                ).createShader(bounds);
              },
              blendMode: BlendMode.dstIn,
              child: Image.asset(
                'assets/images/login.png',
                fit: BoxFit.cover,
                alignment: const Alignment(0, -0.15),
              ),
            ),
          ),

          // ─── Main Content ────────────────────────────────────────────────
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: IntrinsicHeight(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const SizedBox(height: 12),

                            // Top Brand Minimal Header
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  width: 38,
                                  height: 38,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: AppColors.borderStrong,
                                      width: 1,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.06),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: Padding(
                                      padding: const EdgeInsets.all(6),
                                      child: Image.asset(
                                        'assets/images/logo.png',
                                        fit: BoxFit.contain,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                RichText(
                                  text: const TextSpan(
                                    text: 'Suara',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.slate900,
                                      letterSpacing: -0.4,
                                    ),
                                    children: [
                                      TextSpan(
                                        text: 'Siswa',
                                        style: TextStyle(color: AppColors.primary),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),

                            // Space to let the photo hero breathe
                            SizedBox(height: size.height * 0.22),

                            // Headline and Description
                            const Text(
                              'Ruang Aman Suara & Aspirasi Sekolah',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                color: AppColors.slate900,
                                letterSpacing: -0.5,
                                height: 1.25,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Platform kolaborasi antara siswa dan Guru BK untuk pencegahan perundungan dan pelayanan konseling yang aman.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w400,
                                color: AppColors.slate600,
                                height: 1.45,
                              ),
                            ),
                            const SizedBox(height: 24),

                            // Interactive Role Cards (Tapping either opens login)
                            _RoleHighlightCard(
                              icon: Icons.school_outlined,
                              iconColor: const Color(0xFF2563EB),
                              iconBg: const Color(0xFFEFF6FF),
                              title: 'Untuk Siswa',
                              subtitle:
                                  'Sampaikan laporan dan aspirasi secara terarah dan terjaga kerahasiaannya.',
                              onTap: () => context.push('/login'),
                            ),
                            const SizedBox(height: 10),
                            _RoleHighlightCard(
                              icon: Icons.supervisor_account_outlined,
                              iconColor: AppColors.primary,
                              iconBg: AppColors.lightRed,
                              title: 'Untuk Guru BK',
                              subtitle:
                                  'Kelola ruang sekolah, tindak lanjuti laporan, dan dampingi peserta didik.',
                              onTap: () => context.push('/login'),
                            ),

                            const Spacer(),
                            const SizedBox(height: 24),

                            // Primary Google Sign-In Button
                            _GoogleSignInButton(
                              onPressed: () => context.push('/login'),
                            ),
                            const SizedBox(height: 12),

                            // Legal Privacy Notice
                            const Text(
                              'Dengan melanjutkan, Anda menyetujui Ketentuan Layanan serta Kebijakan Privasi SuaraSiswa.',
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
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _RoleHighlightCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _RoleHighlightCard({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.title,
    required this.subtitle,
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
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.slate50,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.borderStrong),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 20, color: iconColor),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.slate900,
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
              const SizedBox(width: 8),
              const Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: AppColors.slate400,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GoogleSignInButton extends StatelessWidget {
  final VoidCallback onPressed;
  const _GoogleSignInButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.slate900,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            GoogleLogo(size: 20),
            SizedBox(width: 12),
            Text(
              'Lanjutkan dengan Google',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 15,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
