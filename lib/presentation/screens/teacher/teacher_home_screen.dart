import 'package:flutter/material.dart';
import 'package:edstream_mobile/core/constants/app_constants.dart';
import 'package:edstream_mobile/core/network/api_client.dart';
import 'package:edstream_mobile/core/storage/local_cache_store.dart';
import 'package:edstream_mobile/core/theme/app_colors.dart';
import 'package:edstream_mobile/core/theme/app_typography.dart';
import 'package:edstream_mobile/core/widgets/sync_status_banner.dart';
import 'package:edstream_mobile/presentation/screens/auth/login_screen.dart';
import 'package:edstream_mobile/presentation/screens/auth/update_password_screen.dart';
import 'package:edstream_mobile/presentation/screens/teacher/assigned_classes_screen.dart';
import 'package:edstream_mobile/presentation/screens/teacher/assigned_subjects_screen.dart';
import 'package:edstream_mobile/presentation/screens/teacher/score_sheet_screen.dart';

class TeacherHomeScreen extends StatefulWidget {
  const TeacherHomeScreen({super.key});

  @override
  State<TeacherHomeScreen> createState() => _TeacherHomeScreenState();
}

class _TeacherHomeScreenState extends State<TeacherHomeScreen> {
  int _currentIndex = 0;
  String _teacherName = 'Instructor';
  String _teacherEmail = '';

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  void _loadProfile() {
    final cached = LocalCacheStore.instance.getJson(AppConstants.userProfileKey);
    if (cached is Map) {
      setState(() {
        _teacherName = cached['fullName'] ?? cached['name'] ?? 'Instructor';
        _teacherEmail = cached['email'] ?? '';
      });
    }
  }

  void _handleLogout() async {
    ApiClient.instance.setAuthToken(null);
    await LocalCacheStore.instance.remove(AppConstants.tokenKey);
    await LocalCacheStore.instance.remove(AppConstants.roleKey);
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            const SyncStatusBanner(),
            Expanded(
              child: IndexedStack(
                index: _currentIndex,
                children: [
                  _buildDashboardTab(),
                  const AssignedSubjectsScreen(),
                  const AssignedClassesScreen(),
                  _buildSettingsTab(),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_rounded),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.menu_book_rounded),
            label: 'Subjects',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.groups_rounded),
            label: 'Classes',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_rounded),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Bar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Edstream Portal', style: AppTypography.headlineSmall),
                  Text('Active Term 2026 / 2027', style: AppTypography.bodySmall),
                ],
              ),
              IconButton(
                onPressed: _handleLogout,
                icon: const Icon(Icons.logout_rounded, color: AppColors.danger),
                tooltip: 'Sign Out',
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Welcome Hero Card
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              gradient: AppColors.heroCardGradient,
              borderRadius: BorderRadius.circular(22),
              boxShadow: AppColors.shadowMd,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.22),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'STAFF PORTAL',
                        style: AppTypography.labelSmall.copyWith(
                          color: Colors.white,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ),
                    const CircleAvatar(
                      backgroundColor: Colors.white24,
                      child: Icon(Icons.co_present_rounded, color: Colors.white),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'Welcome, $_teacherName',
                  style: AppTypography.headlineMedium.copyWith(color: Colors.white),
                ),
                const SizedBox(height: 4),
                Text(
                  _teacherEmail.isNotEmpty ? _teacherEmail : 'Department of Sciences & Tech',
                  style: AppTypography.bodyMedium.copyWith(
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Stats Overview
          Row(
            children: [
              Expanded(
                child: _buildMetricTile(
                  title: 'Classes',
                  count: '3',
                  subtitle: 'Assigned',
                  icon: Icons.groups_rounded,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricTile(
                  title: 'Subjects',
                  count: '4',
                  subtitle: 'Taught',
                  icon: Icons.menu_book_rounded,
                  color: AppColors.secondary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricTile(
                  title: 'Score Sheets',
                  count: '2',
                  subtitle: 'Pending',
                  icon: Icons.assignment_late_rounded,
                  color: const Color(0xFFF59E0B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Quick Operations Title
          Text('Academic Operations', style: AppTypography.titleLarge),
          const SizedBox(height: 14),

          // Action Grid
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
            childAspectRatio: 1.25,
            children: [
              _buildActionCard(
                icon: Icons.menu_book_rounded,
                title: 'Assigned Subjects',
                subtitle: 'Grade & Score Sheet',
                color: AppColors.primary,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AssignedSubjectsScreen()),
                  );
                },
              ),
              _buildActionCard(
                icon: Icons.groups_rounded,
                title: 'Assigned Classes',
                subtitle: 'Roster & Profiles',
                color: AppColors.secondary,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AssignedClassesScreen()),
                  );
                },
              ),
              _buildActionCard(
                icon: Icons.edit_note_rounded,
                title: 'Quick Score Sheet',
                subtitle: 'Mathematics SS 2',
                color: const Color(0xFF0EA5E9),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ScoreSheetScreen(
                        subjectId: 'sub-1',
                        subjectName: 'Mathematics',
                        className: 'SS 2 Gold',
                      ),
                    ),
                  );
                },
              ),
              _buildActionCard(
                icon: Icons.lock_reset_rounded,
                title: 'Security Settings',
                subtitle: 'Update Password',
                color: const Color(0xFF10B981),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const UpdatePasswordScreen(
                        role: UserRole.teacher,
                        isForced: false,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricTile({
    required String title,
    required String count,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppColors.shadowCard,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 10),
          Text(count, style: AppTypography.headlineMedium.copyWith(color: AppColors.light)),
          Text(subtitle, style: AppTypography.labelSmall),
        ],
      ),
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: AppColors.shadowCard,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: color, size: 22),
                ),
                const Spacer(),
                Text(
                  title,
                  style: AppTypography.titleSmall.copyWith(fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: AppTypography.bodySmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          CircleAvatar(
            radius: 40,
            backgroundColor: AppColors.primary.withValues(alpha: 0.15),
            child: Text(
              _teacherName.isNotEmpty ? _teacherName[0] : 'T',
              style: AppTypography.displayMedium.copyWith(color: AppColors.primary),
            ),
          ),
          const SizedBox(height: 14),
          Text(_teacherName, style: AppTypography.headlineSmall),
          Text(_teacherEmail, style: AppTypography.bodySmall),
          const SizedBox(height: 24),

          Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(18),
              boxShadow: AppColors.shadowCard,
            ),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.lock_outline_rounded, color: AppColors.primary),
                  title: Text('Change Password', style: AppTypography.titleSmall),
                  trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const UpdatePasswordScreen(
                          role: UserRole.teacher,
                          isForced: false,
                        ),
                      ),
                    );
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.sync_rounded, color: AppColors.secondary),
                  title: Text('Sync Offline Data', style: AppTypography.titleSmall),
                  trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Checking offline synchronization queue...')),
                    );
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
          ),
        ],
      ),
    );
  }
}
