import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../auth_controller.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  final List<Map<String, String>> _slides = const [
    {
      'title': 'Perundungan Bukan Candaan',
      'desc':
          'Tindakan yang menyakiti sesama meninggalkan bekas nyata. Mari bangun kebiasaan saling menjaga di lingkungan sekolah.',
      'image': 'assets/images/onb1.png',
    },
    {
      'title': 'Kamu Tidak Pernah Sendiri',
      'desc':
          'Ceritakan apa yang kamu alami tanpa rasa takut. Guru BK siap mendengarkan, melindungi, dan mendampingi langkahmu.',
      'image': 'assets/images/onb2.png',
    },
    {
      'title': 'Setiap Suara Sangat Berarti',
      'desc':
          'Keberanianmu melapor dan bersuara adalah awal terciptanya sekolah yang aman, inklusif, dan ramah bagi semua.',
      'image': 'assets/images/onb3.png',
    },
  ];

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
    );
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    );
    _fadeController.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _completeOnboarding() async {
    final storage = ref.read(storageServiceProvider);
    await storage.setOnboardingCompleted(true);
    if (mounted) context.go('/welcome');
  }

  void _onPageChanged(int index) {
    setState(() => _currentPage = index);
    _fadeController.reset();
    _fadeController.forward();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Image.asset(
                'assets/images/logo.png',
                width: 24,
                height: 24,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              'SuaraSiswa',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
            ),
          ],
        ),
        actions: [
          if (_currentPage < _slides.length - 1)
            TextButton(
              onPressed: _completeOnboarding,
              child: const Text(
                'Lewati',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: Stack(
        children: [
          // Background Imagery
          PageView.builder(
            controller: _pageController,
            itemCount: _slides.length,
            onPageChanged: _onPageChanged,
            itemBuilder: (context, index) {
              return Image.asset(
                _slides[index]['image']!,
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
              );
            },
          ),

          // Top Subtle Gradient Scrim
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 120,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.65),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // Bottom Scrim Gradient for Readability
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: const Alignment(0, -0.2),
                  colors: [
                    Colors.black.withOpacity(0.92),
                    Colors.black.withOpacity(0.70),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.45, 1.0],
                ),
              ),
            ),
          ),

          // Bottom Narrative Content
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Slide Title
                      Text(
                        _slides[_currentPage]['title']!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          height: 1.25,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Slide Description
                      Text(
                        _slides[_currentPage]['desc']!,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.82),
                          fontSize: 14,
                          height: 1.5,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      const SizedBox(height: 28),

                      // Indicators & Counter Row
                      Row(
                        children: [
                          ...List.generate(_slides.length, (index) {
                            final isActive = index == _currentPage;
                            return AnimatedContainer(
                              duration: const Duration(milliseconds: 250),
                              curve: Curves.easeInOut,
                              margin: const EdgeInsets.only(right: 6),
                              width: isActive ? 24 : 7,
                              height: 7,
                              decoration: BoxDecoration(
                                color: isActive
                                    ? AppColors.primary
                                    : Colors.white.withOpacity(0.35),
                                borderRadius: BorderRadius.circular(4),
                              ),
                            );
                          }),
                          const Spacer(),
                          Text(
                            '${_currentPage + 1} / ${_slides.length}',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.55),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Primary Navigation Action
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: () {
                            if (_currentPage < _slides.length - 1) {
                              _pageController.nextPage(
                                duration: const Duration(milliseconds: 350),
                                curve: Curves.easeInOutCubic,
                              );
                            } else {
                              _completeOnboarding();
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            _currentPage == _slides.length - 1
                                ? 'Mulai Sekarang'
                                : 'Lanjut',
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Secondary Shortcut
                      Center(
                        child: TextButton(
                          onPressed: _completeOnboarding,
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.white.withOpacity(0.75),
                          ),
                          child: const Text(
                            'Sudah memiliki akun? Masuk langsung',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
