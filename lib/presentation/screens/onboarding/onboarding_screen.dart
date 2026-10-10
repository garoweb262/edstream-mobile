import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:edstream_mobile/core/theme/app_colors.dart';
import 'package:edstream_mobile/core/theme/app_typography.dart';
import 'package:edstream_mobile/presentation/screens/auth/login_screen.dart';
import 'package:edstream_mobile/presentation/widgets/primary_button.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<Map<String, String>> _slides = [
    {
      'imageUrl':
          'https://images.unsplash.com/photo-1523240795612-9a054b0db644?q=80&w=1200&auto=format&fit=crop',
      'title': 'Unified Dual-Role Portal',
      'subtitle':
          'Effortlessly switch between Teacher academic tools and Student learning records in one seamless mobile app.',
    },
    {
      'imageUrl':
          'https://images.unsplash.com/photo-1509062522246-3755977927d7?q=80&w=1200&auto=format&fit=crop',
      'title': 'Continuous Assessment & Grading',
      'subtitle':
          'Instructors can input CA1, CA2, CA3 and terminal exam marks with automatic GPA calculation and broadsheet generation.',
    },
    {
      'imageUrl':
          'https://images.unsplash.com/photo-1427504494785-3a9ca7044f45?q=80&w=1200&auto=format&fit=crop',
      'title': 'Offline-First Reliability',
      'subtitle':
          'No internet? No problem. Record grades, inspect report cards, and automatically sync data once connectivity returns.',
    },
  ];

  void _navigateToLogin() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLastPage = _currentPage == _slides.length - 1;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Carousel View
          PageView.builder(
            controller: _pageController,
            itemCount: _slides.length,
            onPageChanged: (index) => setState(() => _currentPage = index),
            itemBuilder: (context, index) {
              final slide = _slides[index];
              return Column(
                children: [
                  // Image with gradient fade
                  Expanded(
                    flex: 6,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        CachedNetworkImage(
                          imageUrl: slide['imageUrl']!,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(color: AppColors.dark),
                          errorWidget: (context, url, error) => Container(color: AppColors.primary),
                        ),
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.transparent,
                                AppColors.background.withValues(alpha: 0.8),
                                AppColors.background,
                              ],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              stops: const [0.55, 0.85, 1.0],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Texts Container
                  Expanded(
                    flex: 4,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 28),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            slide['title']!,
                            textAlign: TextAlign.center,
                            style: AppTypography.headlineMedium.copyWith(
                              color: AppColors.light,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            slide['subtitle']!,
                            textAlign: TextAlign.center,
                            style: AppTypography.bodyMedium.copyWith(
                              color: AppColors.color2Light,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),

          // Top Skip Button
          Positioned(
            top: MediaQuery.of(context).padding.top + 12,
            right: 20,
            child: TextButton(
              onPressed: _navigateToLogin,
              child: Text(
                'Skip',
                style: AppTypography.labelLarge.copyWith(
                  color: Colors.white,
                  shadows: const [
                    Shadow(color: Colors.black45, blurRadius: 4),
                  ],
                ),
              ),
            ),
          ),

          // Bottom Controls (Dots & Action Button)
          Positioned(
            bottom: MediaQuery.of(context).padding.bottom + 20,
            left: 28,
            right: 28,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Dots Indicator
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    _slides.length,
                    (index) => AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: _currentPage == index ? 24 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: _currentPage == index
                            ? AppColors.primary
                            : AppColors.color1Light,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Button
                PrimaryButton(
                  text: isLastPage ? 'Get Started' : 'Continue',
                  onPressed: () {
                    if (isLastPage) {
                      _navigateToLogin();
                    } else {
                      _pageController.nextPage(
                        duration: const Duration(milliseconds: 350),
                        curve: Curves.easeInOut,
                      );
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
