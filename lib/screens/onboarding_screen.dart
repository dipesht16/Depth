import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/app_settings.dart';
import 'home_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  late AnimationController _logoController;
  late Animation<double> _logoScale;
  late Animation<double> _logoFade;

  static const _pages = [
    _OnboardingPage(
      icon: Icons.layers_rounded,
      title: 'Create iOS-Style\nWallpapers on Android',
      subtitle:
          'Transform your photos into stunning depth effect wallpapers with a floating clock.',
      gradient: [Color(0xFFFFD700), Color(0xFFFF8C00)],
    ),
    _OnboardingPage(
      icon: Icons.photo_library_rounded,
      title: 'Select Any Photo',
      subtitle:
          'Choose from your gallery or take a new photo. Any image works.',
      gradient: [Color(0xFF64B5F6), Color(0xFF1565C0)],
    ),
    _OnboardingPage(
      icon: Icons.auto_awesome_rounded,
      title: 'AI-Powered\nSubject Detection',
      subtitle:
          'Our smart algorithm automatically isolates the subject to create the depth effect.',
      gradient: [Color(0xFFA5D6A7), Color(0xFF2E7D32)],
    ),
    _OnboardingPage(
      icon: Icons.tune_rounded,
      title: 'Customize Everything',
      subtitle:
          'Style your clock with fonts, colors, effects, transforms & date display.',
      gradient: [Color(0xFFCE93D8), Color(0xFF6A1B9A)],
    ),
  ];

  @override
  void initState() {
    super.initState();
    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _logoScale = Tween<double>(begin: 0.5, end: 1.0).animate(
        CurvedAnimation(parent: _logoController, curve: Curves.elasticOut));
    _logoFade = CurvedAnimation(
        parent: _logoController, curve: const Interval(0.0, 0.5));
    _logoController.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _logoController.dispose();
    super.dispose();
  }

  void _next() {
    HapticFeedback.selectionClick();
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeInOut);
    } else {
      _finish();
    }
  }

  Future<void> _finish() async {
    final settings = await AppSettings.load();
    await settings.copyWith(hasSeenOnboarding: true).save();
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
        (_) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            // Skip button
            Align(
              alignment: Alignment.topRight,
              child: TextButton(
                onPressed: _finish,
                child: const Text('Skip',
                    style: TextStyle(color: Color(0xFFB0B0B0))),
              ),
            ),

            // Page content
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (i) => setState(() => _currentPage = i),
                itemCount: _pages.length,
                itemBuilder: (_, index) =>
                    _buildPage(_pages[index], index == 0),
              ),
            ),

            // Dot indicators + buttons
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: Row(
                children: [
                  // Dots
                  Row(
                    children: List.generate(
                      _pages.length,
                      (i) => AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        width: i == _currentPage ? 20 : 8,
                        height: 8,
                        margin: const EdgeInsets.only(right: 6),
                        decoration: BoxDecoration(
                          color: i == _currentPage
                              ? const Color(0xFFFFD700)
                              : const Color(0xFF424242),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                  const Spacer(),
                  // Next / Get Started button
                  GestureDetector(
                    onTap: _next,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFD700),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Row(
                        children: [
                          Text(
                            _currentPage == _pages.length - 1
                                ? 'Get Started'
                                : 'Next',
                            style: const TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Icon(Icons.arrow_forward_rounded,
                              color: Colors.black, size: 18),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPage(_OnboardingPage page, bool isFirst) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon with gradient glow
          ScaleTransition(
            scale: isFirst ? _logoScale : const AlwaysStoppedAnimation(1.0),
            child: FadeTransition(
              opacity: isFirst ? _logoFade : const AlwaysStoppedAnimation(1.0),
              child: Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: page.gradient,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: page.gradient.first.withValues(alpha: 0.35),
                      blurRadius: 30,
                      spreadRadius: 8,
                    )
                  ],
                ),
                child: Icon(page.icon, color: Colors.white, size: 50),
              ),
            ),
          ),
          const SizedBox(height: 40),
          Text(
            page.title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.bold,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            page.subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFFB0B0B0),
              fontSize: 15,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}

class _OnboardingPage {
  final IconData icon;
  final String title;
  final String subtitle;
  final List<Color> gradient;
  const _OnboardingPage(
      {required this.icon,
      required this.title,
      required this.subtitle,
      required this.gradient});
}
