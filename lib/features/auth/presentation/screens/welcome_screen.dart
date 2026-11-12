import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';

class WelcomeScreen extends ConsumerWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark);
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // ─── 1. Natural Photo Header with Soft Feathering to White ─────
          // Photo is shifted up to center the faces, and white boundary is lowered so faces are completely clear
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: screenHeight * 0.52,
            child: ShaderMask(
              shaderCallback: (Rect bounds) {
                return const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black,
                    Colors.black,
                    Color(0xD9000000), // starts gentle fade near bottom
                    Color(0x55000000), // soft transition
                    Colors.transparent, // fully transparent white right above badge
                  ],
                  stops: [0.0, 0.62, 0.80, 0.93, 1.0],
                ).createShader(bounds);
              },
              blendMode: BlendMode.dstIn,
              child: Image.asset(
                'assets/images/login.png',
                fit: BoxFit.cover,
                alignment: const Alignment(0, 0.25), // elevates photo to center student & counselor faces
              ),
            ),
          ),

          // ─── 2. Foreground UI Elements ────────────────────────────────
          SafeArea(
            child: Column(
              children: [
                // Top Branding Area: Logo + App Name + Subtitle (compact to avoid overlapping faces)
                SizedBox(
                  height: screenHeight * 0.28,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Circular Logo
                      Container(
                        width: 58,
                        height: 58,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.08),
                              blurRadius: 14,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: ClipOval(
                          child: Padding(
                            padding: const EdgeInsets.all(9),
                            child: Image.asset('assets/images/logo.png', fit: BoxFit.contain),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Title
                      RichText(
                        text: const TextSpan(
                          text: 'Suara',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                            letterSpacing: -0.5,
                          ),
                          children: [
                            TextSpan(
                              text: 'Siswa',
                              style: TextStyle(color: AppColors.primary),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 3),

                      // Subtitle
                      const Text(
                        'Platform aspirasi & perlindungan siswa',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),

                // Space for faces to be visible without any text obstruction
                SizedBox(height: screenHeight * 0.16),

                // Bottom Area: Starts right below the natural fade
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
                    child: Column(
                      children: [
                        // Verification Badge: positioned right under the photo fade
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                          decoration: BoxDecoration(
                            color: AppColors.lightRed,
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(color: AppColors.redBorder),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.verified_user_rounded, size: 14, color: AppColors.primary),
                              SizedBox(width: 6),
                              Text(
                                'Terverifikasi Guru BK & Aman',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Role Cards
                        _RoleCard(
                          icon: Icons.school_outlined,
                          iconColor: AppColors.primary,
                          iconBg: AppColors.lightRed,
                          title: 'Guru BK',
                          subtitle: 'Kelola laporan, buat ruang sekolah & pantau aspirasi siswa',
                        ),
                        const SizedBox(height: 10),
                        _RoleCard(
                          icon: Icons.people_alt_outlined,
                          iconColor: AppColors.info,
                          iconBg: AppColors.infoLight,
                          title: 'Siswa',
                          subtitle: 'Sampaikan laporan, aspirasi & kendala secara aman & rahasia',
                        ),

                        const Spacer(),

                        // Google Sign-In Button
                        _GoogleSignInButton(onPressed: () => context.push('/login')),
                        const SizedBox(height: 12),

                        // Legal Disclaimer
                        const Text(
                          'Dengan masuk, kamu menyetujui Ketentuan Layanan & Kebijakan Privasi SuaraSiswa.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 11, color: AppColors.textTertiary, height: 1.4),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor, iconBg;
  final String title, subtitle;

  const _RoleCard({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, size: 20, color: iconColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.3),
                ),
              ],
            ),
          ),
        ],
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
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 15),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          elevation: 0,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 22,
              height: 22,
              decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
              child: const Center(
                child: Text('G', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.w900, fontSize: 14)),
              ),
            ),
            const SizedBox(width: 10),
            const Text('Masuk dengan Google', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
          ],
        ),
      ),
    );
  }
}
