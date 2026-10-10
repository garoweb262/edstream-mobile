import 'package:flutter/material.dart';
import 'package:edstream_mobile/core/theme/app_colors.dart';
import 'package:edstream_mobile/core/theme/app_typography.dart';
import 'package:edstream_mobile/presentation/screens/auth/login_screen.dart';
import 'package:edstream_mobile/presentation/widgets/primary_button.dart';

class PasswordSuccessScreen extends StatelessWidget {
  const PasswordSuccessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(24),
                boxShadow: AppColors.shadowCard,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 76,
                    height: 76,
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_circle_rounded,
                      size: 46,
                      color: AppColors.success,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Password Updated!',
                    textAlign: TextAlign.center,
                    style: AppTypography.headlineMedium.copyWith(
                      color: AppColors.light,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Your security credentials have been successfully updated. Please sign in with your new password.',
                    textAlign: TextAlign.center,
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.color2Light,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 32),
                  PrimaryButton(
                    text: 'Sign In Now',
                    onPressed: () {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                        (route) => false,
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
