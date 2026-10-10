import 'package:flutter/material.dart';
import 'package:edstream_mobile/core/constants/app_constants.dart';
import 'package:edstream_mobile/core/network/api_client.dart';
import 'package:edstream_mobile/core/network/api_exception.dart';
import 'package:edstream_mobile/core/network/offline_mutation_queue.dart';
import 'package:edstream_mobile/core/network/pending_mutation.dart';
import 'package:edstream_mobile/core/theme/app_colors.dart';
import 'package:edstream_mobile/core/theme/app_typography.dart';
import 'package:edstream_mobile/presentation/screens/auth/password_success_screen.dart';
import 'package:edstream_mobile/presentation/widgets/custom_text_field.dart';
import 'package:edstream_mobile/presentation/widgets/primary_button.dart';

class UpdatePasswordScreen extends StatefulWidget {
  const UpdatePasswordScreen({
    super.key,
    required this.role,
    this.isForced = true,
  });

  final UserRole role;
  final bool isForced;

  @override
  State<UpdatePasswordScreen> createState() => _UpdatePasswordScreenState();
}

class _UpdatePasswordScreenState extends State<UpdatePasswordScreen> {
  final _formKey = GlobalKey<FormState>();

  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleUpdate() async {
    if (!_formKey.currentState!.validate()) return;

    if (_newPasswordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('New passwords do not match')),
      );
      return;
    }

    setState(() => _isLoading = true);

    final isTeacher = widget.role == UserRole.teacher;
    final endpoint = isTeacher ? 'staff/update-password' : 'student/update-password';
    final payload = {
      'currentPassword': _currentPasswordController.text,
      'oldPassword': _currentPasswordController.text, // for student compatibility
      'newPassword': _newPasswordController.text,
    };

    try {
      await ApiClient.instance.put(endpoint, body: payload);

      if (!mounted) return;
      setState(() => _isLoading = false);

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const PasswordSuccessScreen()),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);

      if (e.isNetworkError) {
        // Queue mutation offline!
        final mutation = PendingMutation(
          localId: OfflineMutationQueue.instance.generateLocalId('password'),
          feature: 'profile',
          operation: 'updatePassword',
          method: 'PUT',
          path: endpoint,
          payload: payload,
          displaySnapshot: {'updated': true},
          createdAt: DateTime.now(),
        );
        await OfflineMutationQueue.instance.enqueue(mutation);

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Offline mode: Password update queued to sync.')),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const PasswordSuccessScreen()),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message)),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Update Password', style: AppTypography.titleLarge),
        leading: widget.isForced
            ? null
            : IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                onPressed: () => Navigator.pop(context),
              ),
        automaticallyImplyLeading: !widget.isForced,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (widget.isForced) ...[
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFF59E0B)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.shield_outlined, color: Color(0xFFD97706), size: 24),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'First Login Security: Please update your temporary password before proceeding.',
                            style: AppTypography.bodySmall.copyWith(
                              color: const Color(0xFF92400E),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

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
                        'Change Security Password',
                        style: AppTypography.titleLarge,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Choose a secure password with at least 6 characters.',
                        style: AppTypography.bodySmall,
                      ),
                      const SizedBox(height: 20),

                      // Current Password
                      CustomTextField(
                        controller: _currentPasswordController,
                        labelText: 'Current Password',
                        hintText: 'Enter current password',
                        obscureText: _obscureCurrent,
                        prefixIcon: const Icon(Icons.lock_clock_outlined, size: 20),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureCurrent
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            size: 20,
                            color: AppColors.color2Light,
                          ),
                          onPressed: () => setState(() => _obscureCurrent = !_obscureCurrent),
                        ),
                        validator: (val) {
                          if (val == null || val.isEmpty) return 'Current password is required';
                          return null;
                        },
                      ),
                      const SizedBox(height: 18),

                      // New Password
                      CustomTextField(
                        controller: _newPasswordController,
                        labelText: 'New Password',
                        hintText: 'Enter new password',
                        obscureText: _obscureNew,
                        prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureNew
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            size: 20,
                            color: AppColors.color2Light,
                          ),
                          onPressed: () => setState(() => _obscureNew = !_obscureNew),
                        ),
                        validator: (val) {
                          if (val == null || val.length < 6) {
                            return 'Password must be at least 6 characters';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 18),

                      // Confirm New Password
                      CustomTextField(
                        controller: _confirmPasswordController,
                        labelText: 'Confirm New Password',
                        hintText: 'Re-enter new password',
                        obscureText: _obscureConfirm,
                        prefixIcon: const Icon(Icons.lock_reset_rounded, size: 20),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureConfirm
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            size: 20,
                            color: AppColors.color2Light,
                          ),
                          onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                        ),
                        validator: (val) {
                          if (val == null || val.isEmpty) return 'Please confirm your password';
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),

                      PrimaryButton(
                        text: 'Update Password',
                        isLoading: _isLoading,
                        onPressed: _handleUpdate,
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
}
