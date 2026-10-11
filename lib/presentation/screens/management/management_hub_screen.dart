import 'package:flutter/material.dart';
import 'package:edstream_mobile/core/network/api_client.dart';
import 'package:edstream_mobile/core/storage/local_cache_store.dart';
import 'package:edstream_mobile/core/theme/app_colors.dart';
import 'package:edstream_mobile/core/theme/app_typography.dart';
import 'package:edstream_mobile/core/widgets/sync_status_banner.dart';
import 'package:edstream_mobile/presentation/screens/common/complaints_screen.dart';
import 'package:edstream_mobile/presentation/screens/common/notifications_center_screen.dart';
import 'package:edstream_mobile/presentation/screens/common/profile_settings_screen.dart';
import 'package:edstream_mobile/presentation/screens/management/expenses_approval_screen.dart';
import 'package:edstream_mobile/presentation/screens/management/fees_management_screen.dart';
import 'package:edstream_mobile/presentation/screens/management/staff_directory_screen.dart';
import 'package:edstream_mobile/presentation/screens/teacher/assessment_summary_screen.dart';
import 'package:edstream_mobile/presentation/screens/teacher/master_results_screen.dart';
import 'package:edstream_mobile/presentation/screens/teacher/student_roster_screen.dart';

class ManagementHubScreen extends StatefulWidget {
  final String role; // 'director', 'principal', 'head-mistress', 'finance-officer', 'exam-officer'

  const ManagementHubScreen({
    super.key,
    this.role = 'principal',
  });

  @override
  State<ManagementHubScreen> createState() => _ManagementHubScreenState();
}

class _ManagementHubScreenState extends State<ManagementHubScreen> {
  bool _isLoading = true;
  int _totalStudents = 1420;
  int _activeStudents = 1385;
  int _totalStaff = 86;
  int _activeStaff = 82;
  String _totalFees = '₦18,450,000';
  String _totalExpenses = '₦4,280,000';

  @override
  void initState() {
    super.initState();
    _fetchSchoolOverview();
  }

  Future<void> _fetchSchoolOverview() async {
    const cacheKey = 'management_school_overview_cache';
    final cached = LocalCacheStore.instance.getJson(cacheKey);
    if (cached is Map) {
      _applyOverviewData(cached);
    }

    try {
      final res = await ApiClient.instance.get(
        'schools/dashboard/overview',
        cacheLocally: true,
        cacheKey: cacheKey,
      );

      if (res is Map && mounted) {
        _applyOverviewData(res);
      }
    } catch (_) {} finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _applyOverviewData(Map data) {
    final summary = data['summary'] as Map?;
    if (summary != null) {
      setState(() {
        _totalStudents = (summary['totalStudents'] as num?)?.toInt() ?? _totalStudents;
        _activeStudents = (summary['activeStudents'] as num?)?.toInt() ?? _activeStudents;
        _totalStaff = (summary['totalStaffs'] as num?)?.toInt() ?? _totalStaff;
        _activeStaff = (summary['activeStaffs'] as num?)?.toInt() ?? _activeStaff;
      });
      final feesVal = summary['totalFeesGenerated'] ?? data['totalFeesGenerated'];
      if (feesVal != null) {
        _totalFees = '₦${_formatCurrency((feesVal as num).toDouble())}';
      }
      final expVal = summary['totalExpenses'] ?? data['totalExpenses'];
      if (expVal != null) {
        _totalExpenses = '₦${_formatCurrency((expVal as num).toDouble())}';
      }
    } else {
      if (data['totalFeesGenerated'] != null) {
        _totalFees = '₦${_formatCurrency((data['totalFeesGenerated'] as num).toDouble())}';
      }
      if (data['totalExpenses'] != null) {
        _totalExpenses = '₦${_formatCurrency((data['totalExpenses'] as num).toDouble())}';
      }
    }
  }

  String _formatCurrency(double val) {
    return val.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
        );
  }

  String get _roleTitle {
    switch (widget.role.toLowerCase()) {
      case 'director':
        return 'Director General';
      case 'head-mistress':
        return 'Head Mistress';
      case 'finance-officer':
        return 'Finance Controller';
      case 'exam-officer':
        return 'Chief Examination Officer';
      default:
        return 'School Principal';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'School Management Hub',
          style: AppTypography.titleLarge.copyWith(color: AppColors.light, fontWeight: FontWeight.w700),
        ),
        backgroundColor: AppColors.surface,
        elevation: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: AppColors.light),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: AppColors.light),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const NotificationsCenterScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: AppColors.light),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProfileSettingsScreen()),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SyncStatusBanner(),
            if (_isLoading) const LinearProgressIndicator(color: AppColors.primary, minHeight: 2),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _fetchSchoolOverview,
                color: AppColors.primary,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLeadershipBanner(),
                      const SizedBox(height: 20),
                      Text('Campus Analytics & Metrics', style: AppTypography.titleMedium.copyWith(color: AppColors.light, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 12),
                      _buildMetricsGrid(),
                      const SizedBox(height: 24),
                      Text('Administrative Modules', style: AppTypography.titleMedium.copyWith(color: AppColors.light, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 14),
                      _buildModulesGrid(),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLeadershipBanner() {
    return Container(
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
                  _roleTitle.toUpperCase(),
                  style: AppTypography.labelSmall.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
              const CircleAvatar(
                backgroundColor: Colors.white24,
                child: Icon(Icons.account_balance_rounded, color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'EdStream Executive Console',
            style: AppTypography.headlineMedium.copyWith(color: Colors.white),
          ),
          const SizedBox(height: 4),
          Text(
            'Session 2024/2025 • Term 3 (Active)',
            style: AppTypography.bodyMedium.copyWith(
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricsGrid() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.4,
      children: [
        _buildMetricCard(
          title: 'Total Students',
          value: '$_totalStudents',
          subtitle: '$_activeStudents Active',
          icon: Icons.school_rounded,
          color: AppColors.primary,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => StudentRosterScreen(
                  classId: 'all',
                  className: 'All Campus Students',
                  studentsCount: _totalStudents,
                ),
              ),
            );
          },
        ),
        _buildMetricCard(
          title: 'Total Staff',
          value: '$_totalStaff',
          subtitle: '$_activeStaff Active',
          icon: Icons.badge_rounded,
          color: AppColors.secondary,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const StaffDirectoryScreen()),
            );
          },
        ),
        _buildMetricCard(
          title: 'Fees Collected',
          value: _totalFees,
          subtitle: 'Term 3 Collections',
          icon: Icons.payments_rounded,
          color: AppColors.success,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const FeesManagementScreen()),
            );
          },
        ),
        _buildMetricCard(
          title: 'Expenditures',
          value: _totalExpenses,
          subtitle: 'Approved Expenses',
          icon: Icons.receipt_long_rounded,
          color: const Color(0xFFF59E0B),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ExpensesApprovalScreen()),
            );
          },
        ),
      ],
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
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
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(title, style: AppTypography.labelSmall.copyWith(color: AppColors.color2Light)),
                    Icon(icon, size: 18, color: color),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  value,
                  style: AppTypography.titleMedium.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.dark,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  subtitle,
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.color2Light,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModulesGrid() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 14,
      mainAxisSpacing: 14,
      childAspectRatio: 1.25,
      children: [
        _buildModuleTile(
          icon: Icons.groups_2_rounded,
          title: 'Staff Directory',
          subtitle: 'Roles, Contacts & Status',
          color: AppColors.primary,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const StaffDirectoryScreen()),
            );
          },
        ),
        _buildModuleTile(
          icon: Icons.receipt_long_rounded,
          title: 'Expenses Desk',
          subtitle: 'Approve & Reject Logs',
          color: const Color(0xFFEF4444),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ExpensesApprovalScreen()),
            );
          },
        ),
        _buildModuleTile(
          icon: Icons.credit_card_rounded,
          title: 'School Fees Hub',
          subtitle: 'Billing & Ledger',
          color: AppColors.success,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const FeesManagementScreen()),
            );
          },
        ),
        _buildModuleTile(
          icon: Icons.analytics_rounded,
          title: 'Master Results',
          subtitle: 'Class Rankings & Report',
          color: AppColors.secondary,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const MasterResultsScreen()),
            );
          },
        ),
        _buildModuleTile(
          icon: Icons.assessment_rounded,
          title: 'Assessments',
          subtitle: 'Submission Summaries',
          color: const Color(0xFF0EA5E9),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AssessmentSummaryScreen()),
            );
          },
        ),
        _buildModuleTile(
          icon: Icons.feedback_outlined,
          title: 'Complaints Desk',
          subtitle: 'Resolve Grievances',
          color: const Color(0xFFF59E0B),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ComplaintsScreen(isStudent: false)),
            );
          },
        ),
      ],
    );
  }

  Widget _buildModuleTile({
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
}
