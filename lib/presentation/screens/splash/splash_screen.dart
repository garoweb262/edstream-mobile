import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:edstream_mobile/core/constants/app_constants.dart';
import 'package:edstream_mobile/core/network/api_client.dart';
import 'package:edstream_mobile/core/network/offline_mutation_queue.dart';
import 'package:edstream_mobile/core/storage/local_cache_store.dart';
import 'package:edstream_mobile/core/theme/app_colors.dart';
import 'package:edstream_mobile/core/theme/app_typography.dart';
import 'package:edstream_mobile/presentation/screens/onboarding/onboarding_screen.dart';
import 'package:edstream_mobile/presentation/screens/student/student_home_screen.dart';
import 'package:edstream_mobile/presentation/screens/teacher/teacher_home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  static const String _splashBgUrl =
      'https://images.unsplash.com/photo-1523240795612-9a054b0db644?q=80&w=1200&auto=format&fit=crop';

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    _scaleAnimation = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutBack),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeIn),
    );

    _animController.forward();
    _bootstrap();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    // Initialize cache and offline queue
    await LocalCacheStore.instance.init();
    await OfflineMutationQueue.instance.init();

    // Check saved credentials
    final token = await ApiClient.instance.getAuthToken();
    final role = LocalCacheStore.instance.getString(AppConstants.roleKey);

    // Keep splash visible briefly for branding
    await Future.delayed(const Duration(milliseconds: 2200));

    if (!mounted) return;

    if (token != null && token.isNotEmpty) {
      if (role == AppConstants.roleTeacher) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const TeacherHomeScreen()),
        );
        return;
      } else if (role == AppConstants.roleStudent) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const StudentHomeScreen()),
        );
        return;
      }
    }

    // First time or signed out
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const OnboardingScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.dark,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background Unsplash Image with Overlay
          CachedNetworkImage(
            imageUrl: _splashBgUrl,
            fit: BoxFit.cover,
            placeholder: (context, url) => Container(color: AppColors.dark),
            errorWidget: (context, url, error) => Container(color: AppColors.dark),
          ),

          // Rich Gradient Overlay
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.dark.withValues(alpha: 0.75),
                  AppColors.dark.withValues(alpha: 0.95),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),

          // Content
          Center(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Project Brand Emblem / Logo
                      Container(
                        width: 96,
                        height: 96,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.4),
                              blurRadius: 28,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.all(14),
                        child: Image.asset(
                          'assets/logo/loader-logo.png',
                          errorBuilder: (context, error, stackTrace) => Container(
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: AppColors.primaryGradient,
                            ),
                            child: const Icon(
                              Icons.auto_stories_rounded,
                              size: 44,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Brand Name
                      Text(
                        'EDSTREAM',
                        style: AppTypography.displayMedium.copyWith(
                          color: Colors.white,
                          letterSpacing: 3.0,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Tagline
                      Text(
                        'Smart School Management & Learning Platform',
                        textAlign: TextAlign.center,
                        style: AppTypography.bodyMedium.copyWith(
                          color: Colors.white.withValues(alpha: 0.8),
                          letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(height: 48),

                      // Elegant Progress Indicator
                      SizedBox(
                        width: 32,
                        height: 32,
                        child: CircularProgressIndicator(
                          strokeWidth: 3,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white.withValues(alpha: 0.85),
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
