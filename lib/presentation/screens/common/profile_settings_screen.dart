import 'package:flutter/material.dart';
import 'package:edstream_mobile/core/constants/app_constants.dart';
import 'package:edstream_mobile/core/network/api_client.dart';
import 'package:edstream_mobile/core/network/session.dart';
import 'package:edstream_mobile/core/storage/local_cache_store.dart';
import 'package:edstream_mobile/core/theme/app_colors.dart';
import 'package:edstream_mobile/core/theme/app_typography.dart';
import 'package:edstream_mobile/core/widgets/sync_status_banner.dart';
import 'package:edstream_mobile/presentation/screens/auth/login_screen.dart';
import 'package:edstream_mobile/presentation/widgets/primary_button.dart';

class ProfileSettingsScreen extends StatefulWidget {
  final bool isStudent;

  const ProfileSettingsScreen({
    super.key,
    this.isStudent = false,
  });

  @override
  State<ProfileSettingsScreen> createState() => _ProfileSettingsScreenState();
}

class _ProfileSettingsScreenState extends State<ProfileSettingsScreen> {
  bool _isLoading = true;
  String _fullName = '';
  String _identifier = '';
  String _email = '';
  String _phone = '';
  String _roleName = '';
  String _subDetails = '';

  // Password update controllers
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _isUpdatingPassword = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _loadProfile() {
    final cached = LocalCacheStore.instance.getJson(AppConstants.userProfileKey);
    if (cached is Map) {
      setState(() {
        _fullName = cached['fullName'] ?? cached['name'] ?? (widget.isStudent ? 'Alex Johnson' : 'Dr. Idi Sule');
        _email = cached['email'] ?? '';
        _phone = cached['phoneNumber'] ?? cached['phone'] ?? '+234 801 234 5678';
        if (widget.isStudent) {
          _identifier = cached['registrationNumber'] ?? cached['regNo'] ?? 'EDS/2026/0491';
          _roleName = 'Student';
          _subDetails = cached['className'] ?? 'SS 2 Gold (Senior Secondary)';
        } else {
          _identifier = cached['staffId'] ?? 'STF-0428';
          _roleName = cached['staffType'] ?? 'Teacher';
          _subDetails = 'Department of Sciences & Technology';
        }
      });
    } else {
      setState(() {
        if (widget.isStudent) {
          _fullName = 'Alex Johnson Chukwuma';
          _identifier = 'EDS/2026/0491';
          _email = 'alex.johnson@edstream.edu';
          _phone = '+234 802 345 6789';
          _roleName = 'Student';
          _subDetails = 'SS 2 Gold (Senior Secondary)';
        } else {
          _fullName = 'Dr. Idi Sule';
          _identifier = 'STF-0428';
          _email = 'sulefango1@gmail.com';
          _phone = '+234 803 123 4567';
          _roleName = 'Senior Teacher';
          _subDetails = 'Mathematics & Natural Sciences';
        }
      });
    }
    _fetchLiveProfile();
  }

  Future<void> _fetchLiveProfile() async {
    try {
      final endpoint = widget.isStudent ? 'student/get-student' : 'staff/me';
      final res = await ApiClient.instance.get(endpoint, cacheLocally: true);

      if (res is Map && mounted) {
        final data = res['data'] is Map ? res['data'] : res;
        setState(() {
          final fName = data['firstName'] ?? '';
          final lName = data['lastName'] ?? data['surname'] ?? '';
          final name = '$fName $lName'.trim();
          if (name.isNotEmpty) _fullName = name;
          if (data['email'] != null) _email = data['email'].toString();
          if (data['phoneNumber'] != null) _phone = data['phoneNumber'].toString();
          if (widget.isStudent && data['registrationNumber'] != null) {
            _identifier = data['registrationNumber'].toString();
          } else if (!widget.isStudent && data['staffId'] != null) {
            _identifier = data['staffId'].toString();
          }
        });
      }
    } catch (_) {} finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handlePasswordUpdate() async {
    final current = _currentPasswordController.text.trim();
    final newPass = _newPasswordController.text.trim();
    final confirm = _confirmPasswordController.text.trim();

    if (current.isEmpty || newPass.isEmpty || confirm.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill out all password fields')),
      );
      return;
    }

    if (newPass.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('New password must be at least 6 characters')),
      );
      return;
    }

    if (newPass != confirm) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('New passwords do not match')),
      );
      return;
    }

    setState(() => _isUpdatingPassword = true);

    try {
      final endpoint = widget.isStudent ? 'student/update-password' : 'staff/update-password';
      final payload = widget.isStudent
          ? {'oldPassword': current, 'newPassword': newPass}
          : {'currentPassword': current, 'newPassword': newPass};

      await ApiClient.instance.put(endpoint, body: payload);

      if (mounted) {
        _currentPasswordController.clear();
        _newPasswordController.clear();
        _confirmPasswordController.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: AppColors.success,
            content: Text('Password updated successfully!'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.danger,
            content: Text('Failed to update password: $e'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isUpdatingPassword = false);
    }
  }

  void _handleLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Sign Out', style: AppTypography.titleMedium),
        content: const Text('Are you sure you want to sign out of your account?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sign Out', style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await signOut();
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Profile & Settings',
          style: AppTypography.titleLarge.copyWith(color: AppColors.light, fontWeight: FontWeight.w700),
        ),
        backgroundColor: AppColors.surface,
        elevation: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: AppColors.light),
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SyncStatusBanner(),
            if (_isLoading) const LinearProgressIndicator(color: AppColors.primary, minHeight: 2),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Column(
                  children: [
                    _buildProfileHero(),
                    const SizedBox(height: 20),
                    _buildInfoCard(),
                    const SizedBox(height: 20),
                    _buildPasswordUpdateCard(),
                    const SizedBox(height: 20),
                    _buildPreferencesCard(),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHero() {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: AppColors.heroCardGradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppColors.shadowMd,
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 36,
                backgroundColor: Colors.white24,
                child: Text(
                  _fullName.isNotEmpty ? _fullName[0] : 'U',
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        _roleName.toUpperCase(),
                        style: AppTypography.labelSmall.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _fullName,
                      style: AppTypography.titleLarge.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      _identifier,
                      style: AppTypography.bodySmall.copyWith(
                        color: Colors.white.withValues(alpha: 0.85),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (_subDetails.isNotEmpty) ...[
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _subDetails,
                style: AppTypography.bodySmall.copyWith(color: Colors.white),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppColors.shadowCard,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Account Details', style: AppTypography.titleMedium.copyWith(color: AppColors.light, fontWeight: FontWeight.w700)),
          const SizedBox(height: 14),
          _buildInfoRow(Icons.email_outlined, 'Email Address', _email),
          const Divider(height: 20),
          _buildInfoRow(Icons.phone_outlined, 'Phone Number', _phone),
          const Divider(height: 20),
          _buildInfoRow(
            widget.isStudent ? Icons.badge_outlined : Icons.work_outline_rounded,
            widget.isStudent ? 'Registration Number' : 'Staff Identification ID',
            _identifier,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: AppColors.primary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: AppTypography.labelSmall.copyWith(color: AppColors.color2Light)),
              Text(value.isNotEmpty ? value : 'Not provided', style: AppTypography.titleSmall.copyWith(fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordUpdateCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppColors.shadowCard,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.lock_reset_rounded, color: AppColors.secondary, size: 22),
              const SizedBox(width: 8),
              Text(
                'Security & Password',
                style: AppTypography.titleMedium.copyWith(color: AppColors.light, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _buildPasswordField(
            controller: _currentPasswordController,
            label: 'Current Password',
            obscure: _obscureCurrent,
            onToggle: () => setState(() => _obscureCurrent = !_obscureCurrent),
          ),
          const SizedBox(height: 12),
          _buildPasswordField(
            controller: _newPasswordController,
            label: 'New Password (min 6 characters)',
            obscure: _obscureNew,
            onToggle: () => setState(() => _obscureNew = !_obscureNew),
          ),
          const SizedBox(height: 12),
          _buildPasswordField(
            controller: _confirmPasswordController,
            label: 'Confirm New Password',
            obscure: _obscureConfirm,
            onToggle: () => setState(() => _obscureConfirm = !_obscureConfirm),
          ),
          const SizedBox(height: 18),
          PrimaryButton(
            text: 'Update Password',
            isLoading: _isUpdatingPassword,
            onPressed: _handlePasswordUpdate,
          ),
        ],
      ),
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required bool obscure,
    required VoidCallback onToggle,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: AppTypography.bodySmall.copyWith(color: AppColors.color2Light),
        filled: true,
        fillColor: AppColors.color3Light,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        suffixIcon: IconButton(
          icon: Icon(
            obscure ? Icons.visibility_off_rounded : Icons.visibility_rounded,
            color: AppColors.color2Light,
            size: 20,
          ),
          onPressed: onToggle,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _buildPreferencesCard() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppColors.shadowCard,
      ),
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.sync_rounded, color: AppColors.primary),
            title: Text('Offline Synchronization', style: AppTypography.titleSmall),
            subtitle: Text('Review offline queued actions', style: AppTypography.bodySmall),
            trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Offline cache is synchronized with EdStream cloud.')),
              );
            },
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.delete_outline_rounded, color: AppColors.warning),
            title: Text('Clear Local Storage Cache', style: AppTypography.titleSmall),
            subtitle: Text('Free local storage cache', style: AppTypography.bodySmall),
            onTap: () async {
              await LocalCacheStore.instance.clear();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Local cache cleared successfully!')),
                );
              }
            },
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.logout_rounded, color: AppColors.danger),
            title: Text('Sign Out', style: AppTypography.titleSmall.copyWith(color: AppColors.danger)),
            onTap: _handleLogout,
          ),
        ],
      ),
    );
  }
}
