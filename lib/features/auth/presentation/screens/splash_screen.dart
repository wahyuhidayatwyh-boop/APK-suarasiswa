import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../auth_controller.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _entryController;
  late AnimationController _floatController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _floatAnimation;

  @override
  void initState() {
    super.initState();
    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    )..repeat(reverse: true);

    _fadeAnimation = CurvedAnimation(
      parent: _entryController,
      curve: Curves.easeOut,
    );
    _scaleAnimation = Tween<double>(begin: 0.90, end: 1.0).animate(
      CurvedAnimation(
        parent: _entryController,
        curve: Curves.easeOutBack,
      ),
    );
    _floatAnimation = Tween<double>(begin: -5.0, end: 5.0).animate(
      CurvedAnimation(
        parent: _floatController,
        curve: Curves.easeInOutSine,
      ),
    );

    _entryController.forward();
    _checkInitialRoute();
  }

  Future<void> _checkInitialRoute() async {
    await Future.delayed(const Duration(milliseconds: 1800));
    if (!mounted) return;

    final storage = ref.read(storageServiceProvider);
    final isOnboardingDone = storage.isOnboardingCompleted();

    if (!isOnboardingDone) {
      context.go('/onboarding');
      return;
    }

    // Check user session
    await ref.read(authControllerProvider.notifier).checkSession();
    if (!mounted) return;

    final authState = ref.read(authControllerProvider);
    if (!authState.isAuthenticated) {
      context.go('/welcome');
    } else if (!authState.hasSchool) {
      context.go('/welcome');
    } else if (authState.isCounselor) {
      context.go('/counselor');
    } else {
      context.go('/student');
    }
  }

  @override
  void dispose() {
    _entryController.dispose();
    _floatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // ─── Subtle Theme Decorative Background Elements ─────────────────
          // Top-right soft brand gradient orb
          Positioned(
            top: -50,
            right: -50,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.primary.withOpacity(0.08),
                    AppColors.primary.withOpacity(0.0),
                  ],
                ),
              ),
            ),
          ),
          // Bottom-left soft blue gradient orb
          Positioned(
            bottom: -40,
            left: -40,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF2563EB).withOpacity(0.06),
                    const Color(0xFF2563EB).withOpacity(0.0),
                  ],
                ),
              ),
            ),
          ),
          // Floating subtle decorative shapes
          Positioned(
            top: size.height * 0.20,
            left: size.width * 0.14,
            child: AnimatedBuilder(
              animation: _floatAnimation,
              builder: (context, child) => Transform.translate(
                offset: Offset(0, _floatAnimation.value * 0.7),
                child: child,
              ),
              child: Container(
                width: 9,
                height: 9,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.22),
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
          Positioned(
            top: size.height * 0.32,
            right: size.width * 0.15,
            child: AnimatedBuilder(
              animation: _floatAnimation,
              builder: (context, child) => Transform.translate(
                offset: Offset(0, -_floatAnimation.value * 0.6),
                child: child,
              ),
              child: Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: AppColors.primary.withOpacity(0.2),
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: size.height * 0.26,
            left: size.width * 0.16,
            child: AnimatedBuilder(
              animation: _floatAnimation,
              builder: (context, child) => Transform.translate(
                offset: Offset(0, -_floatAnimation.value * 0.5),
                child: child,
              ),
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: const Color(0xFF3B82F6).withOpacity(0.25),
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
          Positioned(
            bottom: size.height * 0.22,
            right: size.width * 0.20,
            child: AnimatedBuilder(
              animation: _floatAnimation,
              builder: (context, child) => Transform.translate(
                offset: Offset(0, _floatAnimation.value * 0.6),
                child: child,
              ),
              child: Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),

          // ─── Main Center Content ─────────────────────────────────────────
          Center(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Floating Brand Logo Container
                      AnimatedBuilder(
                        animation: _floatAnimation,
                        builder: (context, child) => Transform.translate(
                          offset: Offset(0, _floatAnimation.value),
                          child: child,
                        ),
                        child: Container(
                          width: 88,
                          height: 88,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: const Color(0xFFE2E8F0),
                              width: 1.2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withOpacity(0.12),
                                blurRadius: 24,
                                offset: const Offset(0, 8),
                              ),
                              BoxShadow(
                                color: Colors.black.withOpacity(0.04),
                                blurRadius: 10,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(24),
                            child: Padding(
                              padding: const EdgeInsets.all(14),
                              child: Image.asset(
                                'assets/images/logo.png',
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),

                      // Brand Name "SuaraSiswa"
                      RichText(
                        text: const TextSpan(
                          text: 'Suara',
                          style: TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.w800,
                            color: AppColors.slate900,
                            letterSpacing: -0.6,
                          ),
                          children: [
                            TextSpan(
                              text: 'Siswa',
                              style: TextStyle(color: AppColors.primary),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Tagline (EXACTLY 2 LINES)
                      const Text(
                        'Berani bersuara,\nbersama mencari solusi.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w500,
                          color: AppColors.slate600,
                          height: 1.5,
                          letterSpacing: 0.1,
                        ),
                      ),
                      const SizedBox(height: 44),

                      // Elegant Loading Indicator
                      const SizedBox(
                        width: 26,
                        height: 26,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.6,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(AppColors.primary),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ─── Bottom Footer ───────────────────────────────────────────────
          Positioned(
            bottom: 24,
            left: 0,
            right: 0,
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: const Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.verified_user_rounded,
                      size: 13,
                      color: AppColors.slate400,
                    ),
                    SizedBox(width: 5),
                    Text(
                      'Aman • Terverifikasi • Rahasia',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: AppColors.slate400,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
