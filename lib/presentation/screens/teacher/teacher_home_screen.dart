import 'package:flutter/material.dart';
import 'package:edstream_mobile/core/constants/app_constants.dart';
import 'package:edstream_mobile/core/network/api_client.dart';
import 'package:edstream_mobile/core/network/session.dart';
import 'package:edstream_mobile/core/storage/local_cache_store.dart';
import 'package:edstream_mobile/core/theme/app_colors.dart';
import 'package:edstream_mobile/core/theme/app_typography.dart';
import 'package:edstream_mobile/core/widgets/sync_status_banner.dart';
import 'package:edstream_mobile/presentation/screens/auth/login_screen.dart';
import 'package:edstream_mobile/presentation/screens/common/complaints_screen.dart';
import 'package:edstream_mobile/presentation/screens/common/notifications_center_screen.dart';
import 'package:edstream_mobile/presentation/screens/common/profile_settings_screen.dart';
import 'package:edstream_mobile/presentation/screens/management/management_hub_screen.dart';
import 'package:edstream_mobile/presentation/screens/teacher/assessment_summary_screen.dart';
import 'package:edstream_mobile/presentation/screens/teacher/assigned_classes_screen.dart';
import 'package:edstream_mobile/presentation/screens/teacher/assigned_subjects_screen.dart';
import 'package:edstream_mobile/presentation/screens/teacher/master_results_screen.dart';

class TeacherHomeScreen extends StatefulWidget {
  const TeacherHomeScreen({super.key});

  @override
  State<TeacherHomeScreen> createState() => _TeacherHomeScreenState();
}

class _TeacherHomeScreenState extends State<TeacherHomeScreen> {
  int _currentIndex = 0;
  String _teacherName = 'Instructor';
  String _teacherEmail = '';
  String _staffRole = 'Teacher';
  int _totalClasses = 3;
  int _totalSubjects = 4;
  int _totalStudents = 42;
  int _maleCount = 24;
  int _femaleCount = 18;

  @override
  void initState() {
    super.initState();
    _loadProfile();
    _fetchDashboardMetrics();
  }

  void _loadProfile() {
    final cached = LocalCacheStore.instance.getJson(AppConstants.userProfileKey);
    if (cached is Map) {
      setState(() {
        _teacherName = cached['fullName'] ?? cached['name'] ?? 'Instructor';
        _teacherEmail = cached['email'] ?? '';
        _staffRole = cached['staffType'] ?? 'Teacher';
      });
    }
  }

  Future<void> _fetchDashboardMetrics() async {
    try {
      final res = await ApiClient.instance.get(
        'staff/dashboard',
        cacheLocally: true,
        cacheKey: 'staff_dashboard_cache',
      );
      if (res is Map && res['teacherData'] is Map) {
        final td = res['teacherData'] as Map;
        final teacher = td['teacher'] as Map?;
        if (teacher != null) {
          final fName = teacher['firstName'] ?? '';
          final sName = teacher['surname'] ?? '';
          final name = '$fName $sName'.trim();
          if (name.isNotEmpty) _teacherName = name;
          if (teacher['email'] != null) _teacherEmail = teacher['email'].toString();
          if (teacher['staffType'] != null) _staffRole = teacher['staffType'].toString();
        }
        final metrics = td['dashboardMetrics'] as Map?;
        if (metrics != null && mounted) {
          setState(() {
            _totalClasses = (metrics['totalAssignedClasses'] as num?)?.toInt() ?? _totalClasses;
            _totalSubjects = (metrics['totalSubjectsAssigned'] as num?)?.toInt() ?? _totalSubjects;
            _totalStudents = (metrics['totalStudents'] as num?)?.toInt() ?? _totalStudents;
            final genderData = metrics['studentGenderData'] as Map?;
            if (genderData != null) {
              _maleCount = (genderData['male'] as num?)?.toInt() ?? _maleCount;
              _femaleCount = (genderData['female'] as num?)?.toInt() ?? _femaleCount;
            } else {
              _maleCount = (_totalStudents * 0.57).round();
              _femaleCount = _totalStudents - _maleCount;
            }
          });
        }
      }
    } catch (_) {}
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
                  _buildMoreHubTab(),
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
            icon: Icon(Icons.grid_view_rounded),
            label: 'More',
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
                  Text('Hello, $_teacherName 👋', style: AppTypography.titleLarge.copyWith(fontWeight: FontWeight.w700)),
                  Text('EdStream Faculty Portal • 2024/2025', style: AppTypography.bodySmall.copyWith(color: AppColors.color2Light)),
                ],
              ),
              Row(
                children: [
                  IconButton(
                    icon: Stack(
                      children: [
                        const Icon(Icons.notifications_outlined, color: AppColors.light, size: 24),
                        Positioned(
                          right: 0,
                          top: 0,
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: AppColors.danger,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ],
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const NotificationsCenterScreen()),
                      );
                    },
                  ),
                  IconButton(
                    onPressed: _handleLogout,
                    icon: const Icon(Icons.logout_rounded, color: AppColors.danger, size: 22),
                    tooltip: 'Sign Out',
                  ),
                ],
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
                        'STAFF • ${_staffRole.toUpperCase()}',
                        style: AppTypography.labelSmall.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
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
                  _teacherEmail.isNotEmpty ? _teacherEmail : 'Department of Sciences & Technology',
                  style: AppTypography.bodyMedium.copyWith(
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Stats Overview
          Row(
            children: [
              Expanded(
                child: _buildMetricTile(
                  title: 'Classes',
                  count: '$_totalClasses',
                  subtitle: 'Assigned',
                  icon: Icons.groups_rounded,
                  color: AppColors.primary,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const AssignedClassesScreen()),
                    );
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricTile(
                  title: 'Subjects',
                  count: '$_totalSubjects',
                  subtitle: 'Taught',
                  icon: Icons.menu_book_rounded,
                  color: AppColors.secondary,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const AssignedSubjectsScreen()),
                    );
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricTile(
                  title: 'Students',
                  count: '$_totalStudents',
                  subtitle: 'Enrolled',
                  icon: Icons.school_rounded,
                  color: const Color(0xFFF59E0B),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const MasterResultsScreen(),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Gender Demographics Widget (Screen T1 requirement)
          if (_totalStudents > 0) _buildGenderDemographicsCard(),
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
                icon: Icons.edit_note_rounded,
                title: 'Grade Score Sheet',
                subtitle: 'Continuous Assessment',
                color: AppColors.primary,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AssignedSubjectsScreen()),
                  );
                },
              ),
              _buildActionCard(
                icon: Icons.analytics_rounded,
                title: 'Master Results',
                subtitle: 'Rankings & Report Cards',
                color: AppColors.secondary,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const MasterResultsScreen()),
                  );
                },
              ),
              _buildActionCard(
                icon: Icons.assessment_rounded,
                title: 'Assessments',
                subtitle: 'Summary Submission',
                color: const Color(0xFF0EA5E9),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AssessmentSummaryScreen()),
                  );
                },
              ),
              _buildActionCard(
                icon: Icons.campaign_rounded,
                title: 'Broadcast Alerts',
                subtitle: 'Notify Students',
                color: const Color(0xFF10B981),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const NotificationsCenterScreen()),
                  );
                },
              ),
              _buildActionCard(
                icon: Icons.feedback_outlined,
                title: 'Complaints Desk',
                subtitle: 'Submit Grievance',
                color: const Color(0xFFF59E0B),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ComplaintsScreen(isStudent: false)),
                  );
                },
              ),
              _buildActionCard(
                icon: Icons.account_balance_rounded,
                title: 'Management Hub',
                subtitle: 'Director / Principal',
                color: const Color(0xFF8B5CF6),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ManagementHubScreen()),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildGenderDemographicsCard() {
    final malePct = (_maleCount / _totalStudents * 100).round().clamp(1, 99);
    final femalePct = 100 - malePct;

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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Class Demographics',
                style: AppTypography.titleMedium.copyWith(color: AppColors.light, fontWeight: FontWeight.w700),
              ),
              Text(
                '$_totalStudents Total Enrolled',
                style: AppTypography.labelSmall.copyWith(color: AppColors.color2Light),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              // Dual-color progress indicator bar
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Row(
                        children: [
                          Expanded(
                            flex: malePct,
                            child: Container(
                              height: 12,
                              color: AppColors.primary,
                            ),
                          ),
                          Expanded(
                            flex: femalePct,
                            child: Container(
                              height: 12,
                              color: const Color(0xFFEC4899), // Pink
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const CircleAvatar(radius: 5, backgroundColor: AppColors.primary),
                            const SizedBox(width: 6),
                            Text(
                              'Male: $_maleCount ($malePct%)',
                              style: AppTypography.labelMedium.copyWith(fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            const CircleAvatar(radius: 5, backgroundColor: Color(0xFFEC4899)),
                            const SizedBox(width: 6),
                            Text(
                              'Female: $_femaleCount ($femalePct%)',
                              style: AppTypography.labelMedium.copyWith(fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
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
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppColors.shadowCard,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(height: 10),
                Text(count, style: AppTypography.headlineMedium.copyWith(color: AppColors.light)),
                Text(subtitle, style: AppTypography.labelSmall),
              ],
            ),
          ),
        ),
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
                  style: AppTypography.titleSmall.copyWith(fontWeight: FontWeight.w700),
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

  Widget _buildMoreHubTab() {
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
          Text('$_staffRole • $_teacherEmail', style: AppTypography.bodySmall.copyWith(color: AppColors.color2Light)),
          const SizedBox(height: 24),

          Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(20),
              boxShadow: AppColors.shadowCard,
            ),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.person_outline_rounded, color: AppColors.primary),
                  title: Text('Profile & Security', style: AppTypography.titleSmall),
                  subtitle: Text('Manage account details & password', style: AppTypography.bodySmall),
                  trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ProfileSettingsScreen(isStudent: false)),
                    );
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.analytics_outlined, color: AppColors.secondary),
                  title: Text('Master Results Ledger', style: AppTypography.titleSmall),
                  subtitle: Text('Class rankings and report cards', style: AppTypography.bodySmall),
                  trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const MasterResultsScreen()),
                    );
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.assessment_outlined, color: Color(0xFF0EA5E9)),
                  title: Text('Assessment Summaries', style: AppTypography.titleSmall),
                  subtitle: Text('Class submission tracking', style: AppTypography.bodySmall),
                  trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const AssessmentSummaryScreen()),
                    );
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.campaign_outlined, color: Color(0xFF10B981)),
                  title: Text('Broadcast Notifications', style: AppTypography.titleSmall),
                  subtitle: Text('Send alerts to assigned classes', style: AppTypography.bodySmall),
                  trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const NotificationsCenterScreen()),
                    );
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.feedback_outlined, color: Color(0xFFF59E0B)),
                  title: Text('Teacher Complaints Desk', style: AppTypography.titleSmall),
                  subtitle: Text('Submit and view grievances', style: AppTypography.bodySmall),
                  trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ComplaintsScreen(isStudent: false)),
                    );
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.account_balance_outlined, color: Color(0xFF8B5CF6)),
                  title: Text('School Management Hub', style: AppTypography.titleSmall),
                  subtitle: Text('Administrative & leadership console', style: AppTypography.bodySmall),
                  trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ManagementHubScreen()),
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
          const SizedBox(height: 30),
        ],
      ),
    );
  }
}
