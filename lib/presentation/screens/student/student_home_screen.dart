import 'package:flutter/material.dart';
import 'package:edstream_mobile/core/constants/app_constants.dart';
import 'package:edstream_mobile/core/network/api_client.dart';
import 'package:edstream_mobile/core/storage/local_cache_store.dart';
import 'package:edstream_mobile/core/theme/app_colors.dart';
import 'package:edstream_mobile/core/theme/app_typography.dart';
import 'package:edstream_mobile/core/widgets/sync_status_banner.dart';
import 'package:edstream_mobile/presentation/screens/auth/login_screen.dart';
import 'package:edstream_mobile/presentation/screens/auth/update_password_screen.dart';
import 'package:edstream_mobile/presentation/screens/student/results_screen.dart';
import 'package:edstream_mobile/presentation/screens/student/school_fees_screen.dart';
import 'package:edstream_mobile/presentation/screens/student/timetable_screen.dart';

class StudentHomeScreen extends StatefulWidget {
  const StudentHomeScreen({super.key});

  @override
  State<StudentHomeScreen> createState() => _StudentHomeScreenState();
}

class _StudentHomeScreenState extends State<StudentHomeScreen> {
  int _currentIndex = 0;
  String _studentName = 'Alex Johnson';
  String _regNumber = 'EDS/2026/0491';
  String _className = 'SS 2 Gold';
  bool _hasDoubleEnrollment = false;
  int _enrollmentCount = 1;

  @override
  void initState() {
    super.initState();
    _loadProfile();
    _fetchLiveStudentProfile();
  }

  void _loadProfile() {
    final cached = LocalCacheStore.instance.getJson(AppConstants.userProfileKey);
    if (cached is Map) {
      setState(() {
        _studentName = cached['fullName'] ?? cached['name'] ?? 'Alex Johnson';
        _regNumber = cached['registrationNumber'] ?? cached['regNo'] ?? 'EDS/2026/0491';
        _className = cached['className'] ?? cached['class'] ?? 'SS 2 Gold';
      });
    }
  }

  Future<void> _fetchLiveStudentProfile() async {
    try {
      final res = await ApiClient.instance.get('student/get-student', cacheLocally: true);
      if (res is Map && res['data'] is Map) {
        final d = res['data'] as Map;
        final fName = d['firstName'] ?? '';
        final lName = d['lastName'] ?? '';
        final fullName = '$fName $lName'.trim();
        final reg = d['registrationNumber']?.toString() ?? _regNumber;
        final cls = d['class'] is Map
            ? '${d['class']['code'] ?? ''} ${d['class']['subclass'] ?? ''}'.trim()
            : _className;

        final enrollments = d['enrollments'] as List? ?? [];

        if (mounted) {
          setState(() {
            if (fullName.isNotEmpty) _studentName = fullName;
            _regNumber = reg;
            if (cls.isNotEmpty) _className = cls;
            _enrollmentCount = enrollments.length;
            _hasDoubleEnrollment = enrollments.length > 1;
          });
        }
      }
    } catch (_) {}
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
                  const ResultsScreen(),
                  const SchoolFeesScreen(),
                  _buildProfileTab(),
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
            icon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.grade_rounded),
            label: 'Results',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.credit_card_rounded),
            label: 'Fees',
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
          // Top Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Student Space', style: AppTypography.headlineSmall),
                  Text('Edstream Academic Portal', style: AppTypography.bodySmall),
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

          // Student Identity Card
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              gradient: AppColors.bannerGradient,
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
                        color: Colors.white.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'STUDENT',
                        style: AppTypography.labelSmall.copyWith(
                          color: Colors.white,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.success.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          const CircleAvatar(radius: 4, backgroundColor: AppColors.success),
                          const SizedBox(width: 6),
                          Text(
                            'Fees Cleared',
                            style: AppTypography.labelSmall.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Text(
                  _studentName,
                  style: AppTypography.headlineMedium.copyWith(color: Colors.white),
                ),
                const SizedBox(height: 4),
                Text(
                  'Reg No: $_regNumber • $_className',
                  style: AppTypography.bodyMedium.copyWith(
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),
          ),
          if (_hasDoubleEnrollment) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFF59E0B)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, color: Color(0xFFD97706), size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Double Enrollment Notice: You are actively registered across $_enrollmentCount sections.',
                      style: AppTypography.labelMedium.copyWith(
                        color: const Color(0xFF92400E),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 24),

          // Performance Quick Metrics
          Row(
            children: [
              Expanded(
                child: _buildMetricTile(
                  title: 'Average',
                  value: '84.0%',
                  label: '1st Term',
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricTile(
                  title: 'Attendance',
                  value: '98%',
                  label: 'Present',
                  color: AppColors.success,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricTile(
                  title: 'Class Rank',
                  value: '2nd',
                  label: 'Out of 42',
                  color: const Color(0xFFF59E0B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Academic Modules
          Text('Academic Modules', style: AppTypography.titleLarge),
          const SizedBox(height: 14),

          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
            childAspectRatio: 1.25,
            children: [
              _buildModuleCard(
                icon: Icons.grade_rounded,
                title: 'Term Results',
                subtitle: 'Report Card & GPA',
                color: AppColors.primary,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ResultsScreen()),
                  );
                },
              ),
              _buildModuleCard(
                icon: Icons.account_balance_wallet_rounded,
                title: 'School Fees',
                subtitle: 'Invoices & Receipts',
                color: const Color(0xFFF59E0B),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SchoolFeesScreen()),
                  );
                },
              ),
              _buildModuleCard(
                icon: Icons.calendar_month_rounded,
                title: 'Timetable',
                subtitle: 'Daily Periods',
                color: const Color(0xFF8B5CF6),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const TimetableScreen()),
                  );
                },
              ),
              _buildModuleCard(
                icon: Icons.lock_reset_rounded,
                title: 'Password',
                subtitle: 'Security Update',
                color: const Color(0xFF10B981),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const UpdatePasswordScreen(
                        role: UserRole.student,
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
    required String value,
    required String label,
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
          Text(title, style: AppTypography.labelSmall),
          const SizedBox(height: 6),
          Text(
            value,
            style: AppTypography.headlineMedium.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(label, style: AppTypography.bodySmall),
        ],
      ),
    );
  }

  Widget _buildModuleCard({
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

  Widget _buildProfileTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          CircleAvatar(
            radius: 40,
            backgroundColor: AppColors.primary.withValues(alpha: 0.15),
            child: Text(
              _studentName.isNotEmpty ? _studentName[0] : 'S',
              style: AppTypography.displayMedium.copyWith(color: AppColors.primary),
            ),
          ),
          const SizedBox(height: 14),
          Text(_studentName, style: AppTypography.headlineSmall),
          Text('Reg No: $_regNumber', style: AppTypography.bodySmall),
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
                          role: UserRole.student,
                          isForced: false,
                        ),
                      ),
                    );
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.receipt_long_rounded, color: AppColors.secondary),
                  title: Text('View Invoices & Receipts', style: AppTypography.titleSmall),
                  trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SchoolFeesScreen()),
                    );
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.logout_rounded, color: AppColors.danger),
                  title: Text('Sign Out',
                      style: AppTypography.titleSmall.copyWith(color: AppColors.danger)),
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
