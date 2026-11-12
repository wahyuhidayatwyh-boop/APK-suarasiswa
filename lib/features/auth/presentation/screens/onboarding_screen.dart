import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../shared/widgets/app_button.dart';
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

  final List<Map<String, dynamic>> _slides = [
    {
      'title': 'Bullying Bukan Bercanda',
      'desc': 'Perlakuan yang menyakiti bukan hal sepele. Setiap kata dan tindakan memiliki dampak nyata bagi sesama.',
      'image': 'assets/images/onb1.png',
      'badge': 'Peduli Sesama',
    },
    {
      'title': 'Kamu Tidak Sendiri',
      'desc': 'Ceritakan apa yang terjadi secara aman. Guru BK siap mendengarkan, melindungi, dan mendampingi.',
      'image': 'assets/images/onb2.png',
      'badge': 'Privasi Terjaga',
    },
    {
      'title': 'Suaramu Sangat Berarti',
      'desc': 'Laporkan perundungan dan sampaikan aspirasimu demi sekolah yang aman dan ramah bagi semua.',
      'image': 'assets/images/onb3.png',
      'badge': 'Berani Bicara',
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
    _fadeController = AnimationController(vsync: this, duration: const Duration(milliseconds: 350));
    _fadeAnimation = CurvedAnimation(parent: _fadeController, curve: Curves.easeIn);
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
        systemOverlayStyle: SystemUiOverlayStyle.light,
        title: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Image.asset('assets/images/logo.png', width: 26, height: 26, fit: BoxFit.contain),
            ),
            const SizedBox(width: 8),
            const Text(
              'SuaraSiswa',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15),
            ),
          ],
        ),
        actions: [
          if (_currentPage < _slides.length - 1)
            TextButton(
              onPressed: _completeOnboarding,
              child: const Text('Lewati', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
            ),
          const SizedBox(width: 4),
        ],
      ),
      body: Stack(
        children: [
          // Full screen photos
          PageView.builder(
            controller: _pageController,
            itemCount: _slides.length,
            onPageChanged: _onPageChanged,
            itemBuilder: (context, index) {
              return Image.asset(
                _slides[index]['image'] as String,
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
              );
            },
          ),

          // Top gradient
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: const Alignment(0, -0.2),
                  colors: [Colors.black.withOpacity(0.6), Colors.transparent],
                ),
              ),
            ),
          ),

          // Bottom gradient
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.center,
                  colors: [Colors.black.withOpacity(0.97), Colors.black.withOpacity(0.65), Colors.transparent],
                  stops: const [0.0, 0.4, 1.0],
                ),
              ),
            ),
          ),

          // Bottom content
          Positioned(
            left: 0, right: 0, bottom: 0,
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
                      // Badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.verified_user_rounded, size: 12, color: Colors.white),
                            const SizedBox(width: 5),
                            Text(
                              _slides[_currentPage]['badge'] as String,
                              style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Title
                      Text(
                        _slides[_currentPage]['title'] as String,
                        style: const TextStyle(
                          color: Colors.white, fontSize: 26, fontWeight: FontWeight.w800,
                          height: 1.2, letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Desc
                      Text(
                        _slides[_currentPage]['desc'] as String,
                        style: TextStyle(color: Colors.white.withOpacity(0.78), fontSize: 14, height: 1.5),
                      ),
                      const SizedBox(height: 24),

                      // Dots + page counter row
                      Row(
                        children: [
                          ...List.generate(_slides.length, (index) {
                            final isActive = index == _currentPage;
                            return AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                              margin: const EdgeInsets.only(right: 6),
                              width: isActive ? 28 : 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: isActive ? AppColors.primary : Colors.white.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(4),
                              ),
                            );
                          }),
                          const Spacer(),
                          Text(
                            '${_currentPage + 1} / ${_slides.length}',
                            style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // CTA button
                      AppButton(
                        text: _currentPage == _slides.length - 1 ? 'Mulai Sekarang' : 'Lanjut',
                        onPressed: () {
                          if (_currentPage < _slides.length - 1) {
                            _pageController.nextPage(
                              duration: const Duration(milliseconds: 400),
                              curve: Curves.easeInOut,
                            );
                          } else {
                            _completeOnboarding();
                          }
                        },
                      ),
                      const SizedBox(height: 12),

                      // Sudah punya akun
                      Center(
                        child: TextButton(
                          onPressed: _completeOnboarding,
                          child: Text(
                            'Sudah punya akun? Masuk di sini',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.7),
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
