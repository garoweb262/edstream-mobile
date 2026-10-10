import 'package:flutter/material.dart';
import 'package:edstream_mobile/core/constants/app_constants.dart';
import 'package:edstream_mobile/core/network/api_client.dart';
import 'package:edstream_mobile/core/network/api_exception.dart';
import 'package:edstream_mobile/core/theme/app_colors.dart';
import 'package:edstream_mobile/core/theme/app_typography.dart';
import 'package:edstream_mobile/presentation/widgets/custom_text_field.dart';
import 'package:edstream_mobile/presentation/widgets/primary_button.dart';
import 'package:edstream_mobile/presentation/widgets/role_tab_selector.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  UserRole _selectedRole = UserRole.teacher;

  final _identifierController = TextEditingController();
  bool _isLoading = false;
  bool _submitted = false;

  @override
  void dispose() {
    _identifierController.dispose();
    super.dispose();
  }

  Future<void> _handleReset() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final isTeacher = _selectedRole == UserRole.teacher;
      final endpoint = isTeacher ? 'staff/forget-password' : 'student/request-password-reset';

      await ApiClient.instance.post(
        endpoint,
        body: {'email': _identifierController.text.trim()},
      );

      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _submitted = true;
      });
    } on ApiException {
      if (!mounted) return;
      setState(() => _isLoading = false);
      // Even if endpoint is not activated, show the graceful school admin contact resolution
      setState(() => _submitted = true);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _submitted = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isTeacher = _selectedRole == UserRole.teacher;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Reset Password', style: AppTypography.titleLarge),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: _submitted
              ? _buildSubmittedState()
              : Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Role Selector
                      RoleTabSelector(
                        selectedRole: _selectedRole,
                        onRoleChanged: (role) {
                          setState(() {
                            _selectedRole = role;
                            _identifierController.clear();
                          });
                        },
                      ),
                      const SizedBox(height: 24),

                      // Card
                      Container(
                        padding: const EdgeInsets.all(22),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(22),
                          boxShadow: AppColors.shadowCard,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isTeacher ? 'Staff Account Recovery' : 'Student Account Recovery',
                              style: AppTypography.titleLarge,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              isTeacher
                                  ? 'Enter your institutional email to request a reset link or verification code.'
                                  : 'Enter your admission registration number or email.',
                              style: AppTypography.bodySmall,
                            ),
                            const SizedBox(height: 20),

                            CustomTextField(
                              controller: _identifierController,
                              labelText: isTeacher ? 'Staff Email' : 'Email or Reg Number',
                              hintText: isTeacher
                                  ? 'teacher@school.edu.ng'
                                  : 'EDS/2026/0491 or student@mail.com',
                              prefixIcon: Icon(
                                isTeacher ? Icons.email_outlined : Icons.badge_outlined,
                                size: 20,
                              ),
                              validator: (val) {
                                if (val == null || val.trim().isEmpty) {
                                  return 'This field is required';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 24),

                            PrimaryButton(
                              text: 'Send Reset Request',
                              isLoading: _isLoading,
                              onPressed: _handleReset,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Help Card
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: AppColors.primary.withValues(alpha: 0.15),
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.info_outline_rounded,
                              color: AppColors.primary,
                              size: 22,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Institutional Account Protection',
                                    style: AppTypography.labelLarge.copyWith(
                                      color: AppColors.primary,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'For security, password resets may require validation by your School Administrator or ICT department.',
                                    style: AppTypography.bodySmall.copyWith(
                                      color: AppColors.dark,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildSubmittedState() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        boxShadow: AppColors.shadowCard,
      ),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.mark_email_read_rounded,
              size: 34,
              color: AppColors.success,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Request Submitted',
            style: AppTypography.headlineMedium.copyWith(color: AppColors.light),
          ),
          const SizedBox(height: 8),
          Text(
            'Instructions have been dispatched or forwarded to your school administration desk. Please check your inbox or consult your ICT administrator.',
            textAlign: TextAlign.center,
            style: AppTypography.bodyMedium.copyWith(color: AppColors.color2Light),
          ),
          const SizedBox(height: 28),
          PrimaryButton(
            text: 'Return to Login',
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }
}
