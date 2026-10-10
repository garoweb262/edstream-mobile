import 'package:flutter/material.dart';
import 'package:edstream_mobile/core/constants/app_constants.dart';
import 'package:edstream_mobile/core/network/api_client.dart';
import 'package:edstream_mobile/core/network/api_exception.dart';
import 'package:edstream_mobile/core/storage/local_cache_store.dart';
import 'package:edstream_mobile/core/theme/app_colors.dart';
import 'package:edstream_mobile/core/theme/app_typography.dart';
import 'package:edstream_mobile/core/widgets/sync_status_banner.dart';
import 'package:edstream_mobile/presentation/screens/auth/forgot_password_screen.dart';
import 'package:edstream_mobile/presentation/screens/auth/update_password_screen.dart';
import 'package:edstream_mobile/presentation/screens/student/student_home_screen.dart';
import 'package:edstream_mobile/presentation/screens/teacher/teacher_home_screen.dart';
import 'package:edstream_mobile/presentation/widgets/custom_text_field.dart';
import 'package:edstream_mobile/presentation/widgets/primary_button.dart';
import 'package:edstream_mobile/presentation/widgets/role_tab_selector.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();

  UserRole _selectedRole = UserRole.teacher;

  // Controllers
  final _teacherEmailController = TextEditingController();
  final _studentIdentifierController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _rememberMe = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _teacherEmailController.dispose();
    _studentIdentifierController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleRoleChanged(UserRole role) {
    if (_selectedRole == role) return;
    setState(() {
      _selectedRole = role;
      _formKey.currentState?.reset();
    });
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final isTeacher = _selectedRole == UserRole.teacher;
    final endpoint = isTeacher ? 'staff/login' : 'student/login';
    final studentIdentifier = _studentIdentifierController.text.trim();
    final payload = isTeacher
        ? {
            'email': _teacherEmailController.text.trim(),
            'password': _passwordController.text,
          }
        : {
            'email': studentIdentifier,
            'registrationNumber': studentIdentifier,
            'password': _passwordController.text,
          };

    try {
      final response = await ApiClient.instance.post(endpoint, body: payload);

      if (!mounted) return;
      setState(() => _isLoading = false);

      final token = response['token'] as String?;
      if (token != null) {
        ApiClient.instance.setAuthToken(token);
      }

      final roleStr = isTeacher ? AppConstants.roleTeacher : AppConstants.roleStudent;
      await LocalCacheStore.instance.setString(AppConstants.roleKey, roleStr);

      final userData = isTeacher ? response['staffMember'] : response['student'];
      if (userData != null) {
        await LocalCacheStore.instance.setJson(AppConstants.userProfileKey, userData);
        if (isTeacher) {
          final schoolId = userData['schoolId'] as String?;
          if (schoolId != null) {
            await LocalCacheStore.instance.setString('schoolId', schoolId);
          }
          // Fetch settings in background
          ApiClient.instance.get('school-settings/', cacheLocally: true).then((res) {
            if (res is Map && res['data'] is Map) {
              final noOfCa = res['data']['noOfCa'] as int? ?? 2;
              LocalCacheStore.instance.setInt('school_settings_noOfCa', noOfCa);
            }
          }).catchError((_) {});

          ApiClient.instance.get('staff/last-term-session', cacheLocally: true).then((res) {
            if (res is Map) {
              final term = res['lastTerm']?['name'] ?? res['lastTerm']?['term'];
              final session = res['lastSession']?['session'];
              if (term != null) LocalCacheStore.instance.setString('current_term', term.toString());
              if (session != null) LocalCacheStore.instance.setString('current_session', session.toString());
            }
          }).catchError((_) {});
        }
      }

      if (!mounted) return;

      final passwordUpdateRequired = response['passwordUpdateRequired'] == true;
      if (passwordUpdateRequired) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => UpdatePasswordScreen(role: _selectedRole, isForced: true),
          ),
        );
        return;
      }

      if (isTeacher) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const TeacherHomeScreen()),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const StudentHomeScreen()),
        );
      }
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);

      if (e.isNetworkError) {
        // Offline check: see if cached session exists
        final cachedRole = LocalCacheStore.instance.getString(AppConstants.roleKey);
        final cachedUser = LocalCacheStore.instance.getJson(AppConstants.userProfileKey);

        if (cachedUser != null &&
            cachedRole == (isTeacher ? AppConstants.roleTeacher : AppConstants.roleStudent)) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Offline Login: Restoring your cached session.'),
              backgroundColor: AppColors.primary,
            ),
          );
          if (isTeacher) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const TeacherHomeScreen()),
            );
          } else {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const StudentHomeScreen()),
            );
          }
          return;
        }
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message),
          backgroundColor: AppColors.danger,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Login failed: $e'), backgroundColor: AppColors.danger),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isTeacher = _selectedRole == UserRole.teacher;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Sync / Offline banner
            const SyncStatusBanner(),

            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Brand Logo
                        Container(
                          width: 80,
                          height: 80,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withValues(alpha: 0.25),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Image.asset(
                            'assets/logo/loader-logo.png',
                            errorBuilder: (context, error, stackTrace) => Container(
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: AppColors.primaryGradient,
                              ),
                              child: const Icon(
                                Icons.auto_stories_rounded,
                                size: 36,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Brand Title & Tagline
                        Text(
                          'EDSTREAM',
                          style: AppTypography.headlineLarge.copyWith(
                            letterSpacing: 2.0,
                            fontWeight: FontWeight.w800,
                            color: AppColors.light,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Smart School Management & Portal',
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.color2Light,
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Role Segmented Tab Switcher
                        RoleTabSelector(
                          selectedRole: _selectedRole,
                          onRoleChanged: _handleRoleChanged,
                        ),
                        const SizedBox(height: 20),

                        // Main Card Form
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
                              // Role-specific Header
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    isTeacher ? 'Teacher Login' : 'Student Login',
                                    style: AppTypography.titleLarge,
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: (isTeacher ? AppColors.secondary : AppColors.primary)
                                          .withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      isTeacher ? 'STAFF' : 'STUDENT',
                                      style: AppTypography.labelSmall.copyWith(
                                        color: isTeacher ? AppColors.secondary : AppColors.primary,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                isTeacher
                                    ? 'Enter your institutional email & password'
                                    : 'Enter your email or admission reg number',
                                style: AppTypography.bodySmall,
                              ),
                              const SizedBox(height: 20),

                              // Input 1
                              if (isTeacher)
                                CustomTextField(
                                  controller: _teacherEmailController,
                                  labelText: 'Staff Email',
                                  hintText: 'teacher@school.edu.ng',
                                  keyboardType: TextInputType.emailAddress,
                                  prefixIcon: const Icon(Icons.email_outlined, size: 20),
                                  validator: (val) {
                                    if (val == null || val.trim().isEmpty) {
                                      return 'Staff email is required';
                                    }
                                    if (!val.contains('@')) {
                                      return 'Please enter a valid email address';
                                    }
                                    return null;
                                  },
                                )
                              else
                                CustomTextField(
                                  controller: _studentIdentifierController,
                                  labelText: 'Email or Reg Number',
                                  hintText: 'EDS/2026/0491 or student@mail.com',
                                  keyboardType: TextInputType.text,
                                  prefixIcon: const Icon(Icons.badge_outlined, size: 20),
                                  validator: (val) {
                                    if (val == null || val.trim().isEmpty) {
                                      return 'Registration number or email is required';
                                    }
                                    return null;
                                  },
                                ),
                              const SizedBox(height: 18),

                              // Input 2: Password
                              CustomTextField(
                                controller: _passwordController,
                                labelText: 'Password',
                                hintText: 'Enter your password',
                                obscureText: _obscurePassword,
                                prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility_off_outlined
                                        : Icons.visibility_outlined,
                                    size: 20,
                                    color: AppColors.color2Light,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _obscurePassword = !_obscurePassword;
                                    });
                                  },
                                ),
                                validator: (val) {
                                  if (val == null || val.isEmpty) {
                                    return 'Password is required';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 14),

                              // Remember Me & Forgot Password
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: Checkbox(
                                          value: _rememberMe,
                                          activeColor: AppColors.primary,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(5),
                                          ),
                                          onChanged: (val) {
                                            setState(() => _rememberMe = val ?? true);
                                          },
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Remember me',
                                        style: AppTypography.bodySmall.copyWith(
                                          color: AppColors.light,
                                        ),
                                      ),
                                    ],
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => const ForgotPasswordScreen(),
                                        ),
                                      );
                                    },
                                    style: TextButton.styleFrom(
                                      padding: EdgeInsets.zero,
                                      minimumSize: Size.zero,
                                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                    ),
                                    child: Text(
                                      'Forgot password?',
                                      style: AppTypography.bodySmall.copyWith(
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 22),

                              // Submit Button
                              PrimaryButton(
                                text: isTeacher ? 'Sign in as Teacher' : 'Sign in as Student',
                                isLoading: _isLoading,
                                onPressed: _handleLogin,
                                icon: const Icon(Icons.arrow_forward_rounded,
                                    color: Colors.white, size: 18),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Bottom Help
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('Need assistance? ', style: AppTypography.bodySmall),
                            GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => const ForgotPasswordScreen()),
                                );
                              },
                              child: Text(
                                'Contact School Desk',
                                style: AppTypography.bodySmall.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
