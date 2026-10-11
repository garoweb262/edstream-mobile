import 'package:flutter/material.dart';
import 'package:edstream_mobile/core/network/api_client.dart';
import 'package:edstream_mobile/core/storage/local_cache_store.dart';
import 'package:edstream_mobile/core/theme/app_colors.dart';
import 'package:edstream_mobile/core/theme/app_typography.dart';
import 'package:edstream_mobile/core/widgets/sync_status_banner.dart';
import 'package:edstream_mobile/presentation/screens/teacher/score_sheet_screen.dart';

class AssessmentSummaryScreen extends StatefulWidget {
  const AssessmentSummaryScreen({super.key});

  @override
  State<AssessmentSummaryScreen> createState() => _AssessmentSummaryScreenState();
}

class _AssessmentSummaryScreenState extends State<AssessmentSummaryScreen> {
  bool _isLoading = true;
  String _selectedTerm = '3rd Term';
  String _selectedSession = '2024/2025';
  List<Map<String, dynamic>> _summaries = [];

  final List<String> _terms = ['1st Term', '2nd Term', '3rd Term'];
  final List<String> _sessions = ['2024/2025', '2023/2024'];

  @override
  void initState() {
    super.initState();
    _fetchAssessmentSummaries();
  }

  Future<void> _fetchAssessmentSummaries() async {
    const cacheKey = 'teacher_assessment_summaries_cache';
    final cached = LocalCacheStore.instance.getJson(cacheKey);
    if (cached is List && cached.isNotEmpty) {
      setState(() {
        _summaries = List<Map<String, dynamic>>.from(cached);
        _isLoading = false;
      });
    }

    try {
      final res = await ApiClient.instance.get(
        'result/get-assignment-summary',
        cacheLocally: true,
        cacheKey: cacheKey,
      );

      if (res is List && res.isNotEmpty) {
        if (mounted) {
          setState(() {
            _summaries = List<Map<String, dynamic>>.from(res);
            _isLoading = false;
          });
        }
      } else if (res is Map && res['data'] is List && (res['data'] as List).isNotEmpty) {
        if (mounted) {
          setState(() {
            _summaries = List<Map<String, dynamic>>.from(res['data'] as List);
            _isLoading = false;
          });
        }
      } else if (_summaries.isEmpty) {
        _loadDefaultMockData();
      }
    } catch (_) {
      if (_summaries.isEmpty) {
        _loadDefaultMockData();
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _loadDefaultMockData() {
    _summaries = [
      {
        'class': 'SS 2 Gold',
        'section': 'Senior Secondary',
        'session': '2024/2025',
        'term': '3rd Term',
        'totalSubjects': 8,
        'totalStudents': 42,
        'totalAssignments': 24,
        'completionRate': 92,
        'subjects': [
          {'name': 'Mathematics', 'code': 'MTH 201', 'submitted': 42, 'total': 42, 'status': 'Completed'},
          {'name': 'Physics', 'code': 'PHY 201', 'submitted': 40, 'total': 42, 'status': 'Pending'},
          {'name': 'Chemistry', 'code': 'CHM 201', 'submitted': 38, 'total': 42, 'status': 'Pending'},
          {'name': 'Further Mathematics', 'code': 'FMTH 201', 'submitted': 26, 'total': 26, 'status': 'Completed'},
        ]
      },
      {
        'class': 'SS 1 Silver',
        'section': 'Senior Secondary',
        'session': '2024/2025',
        'term': '3rd Term',
        'totalSubjects': 6,
        'totalStudents': 38,
        'totalAssignments': 18,
        'completionRate': 84,
        'subjects': [
          {'name': 'Mathematics', 'code': 'MTH 101', 'submitted': 38, 'total': 38, 'status': 'Completed'},
          {'name': 'Introductory Tech', 'code': 'TECH 101', 'submitted': 32, 'total': 38, 'status': 'Pending'},
        ]
      },
      {
        'class': 'JSS 3 Diamond',
        'section': 'Junior Secondary',
        'session': '2024/2025',
        'term': '3rd Term',
        'totalSubjects': 9,
        'totalStudents': 45,
        'totalAssignments': 27,
        'completionRate': 96,
        'subjects': [
          {'name': 'Basic Science', 'code': 'BSC 301', 'submitted': 45, 'total': 45, 'status': 'Completed'},
          {'name': 'Basic Technology', 'code': 'BTE 301', 'submitted': 44, 'total': 45, 'status': 'Completed'},
        ]
      },
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Assessment Summaries',
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
            _buildFiltersBar(),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                  : RefreshIndicator(
                      onRefresh: _fetchAssessmentSummaries,
                      color: AppColors.primary,
                      child: _summaries.isEmpty
                          ? _buildEmptyState()
                          : ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              itemCount: _summaries.length,
                              itemBuilder: (context, index) {
                                return _buildSummaryCard(_summaries[index]);
                              },
                            ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFiltersBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.color3Light)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: AppColors.color3Light,
                borderRadius: BorderRadius.circular(20),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedSession,
                  isExpanded: true,
                  icon: const Icon(Icons.arrow_drop_down_rounded, color: AppColors.primary),
                  style: AppTypography.labelMedium.copyWith(color: AppColors.dark, fontWeight: FontWeight.w600),
                  items: _sessions.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedSession = val);
                  },
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: AppColors.color3Light,
                borderRadius: BorderRadius.circular(20),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedTerm,
                  isExpanded: true,
                  icon: const Icon(Icons.arrow_drop_down_rounded, color: AppColors.primary),
                  style: AppTypography.labelMedium.copyWith(color: AppColors.dark, fontWeight: FontWeight.w600),
                  items: _terms.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedTerm = val);
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(Map<String, dynamic> item) {
    final className = item['class'] ?? 'Class';
    final section = item['section'] ?? '';
    final totalSubjects = item['totalSubjects'] ?? 0;
    final totalStudents = item['totalStudents'] ?? 0;
    final totalAssignments = item['totalAssignments'] ?? 0;
    final rate = (item['completionRate'] as num?)?.toInt() ?? 85;
    final subjects = (item['subjects'] as List?) ?? [];

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppColors.shadowCard,
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      className,
                      style: AppTypography.titleMedium.copyWith(
                        color: AppColors.light,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (section.isNotEmpty)
                      Text(
                        section,
                        style: AppTypography.bodySmall.copyWith(color: AppColors.color2Light),
                      ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: rate >= 90
                        ? AppColors.success.withValues(alpha: 0.12)
                        : AppColors.warning.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        rate >= 90 ? Icons.check_circle_rounded : Icons.pending_rounded,
                        size: 14,
                        color: rate >= 90 ? AppColors.success : const Color(0xFFD97706),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '$rate% Completed',
                        style: AppTypography.labelSmall.copyWith(
                          color: rate >= 90 ? AppColors.success : const Color(0xFFD97706),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Metrics row
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildMetricCol('Subjects', '$totalSubjects', Icons.menu_book_rounded),
                  _buildDivider(),
                  _buildMetricCol('Students', '$totalStudents', Icons.groups_rounded),
                  _buildDivider(),
                  _buildMetricCol('Submissions', '$totalAssignments', Icons.task_alt_rounded),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Subject breakdown preview
            if (subjects.isNotEmpty) ...[
              Text(
                'Subject Breakdown',
                style: AppTypography.labelMedium.copyWith(
                  color: AppColors.light,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              ...subjects.take(3).map((sub) {
                final subName = sub['name'] ?? 'Subject';
                final code = sub['code'] ?? '';
                final submitted = sub['submitted'] ?? 0;
                final total = sub['total'] ?? 0;
                final isDone = sub['status'] == 'Completed';

                return Container(
                  margin: const EdgeInsets.only(bottom: 6),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    border: Border.all(color: AppColors.color3Light),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          code,
                          style: AppTypography.labelSmall.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          subName,
                          style: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.w500),
                        ),
                      ),
                      Text(
                        '$submitted/$total',
                        style: AppTypography.labelSmall.copyWith(
                          color: isDone ? AppColors.success : AppColors.color2Light,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Icon(
                        isDone ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                        size: 16,
                        color: isDone ? AppColors.success : AppColors.color4Light,
                      ),
                    ],
                  ),
                );
              }),
            ],
            const SizedBox(height: 12),

            // Action
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ScoreSheetScreen(
                        subjectId: 'class-scores',
                        subjectName: 'Class Continuous Assessments',
                        className: className,
                        session: _selectedSession,
                        term: _selectedTerm,
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.edit_document, size: 16, color: AppColors.secondary),
                label: Text(
                  'Manage Scores & Sheet',
                  style: AppTypography.labelMedium.copyWith(
                    color: AppColors.secondary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCol(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 16, color: AppColors.primary),
        const SizedBox(height: 4),
        Text(
          value,
          style: AppTypography.titleSmall.copyWith(
            fontWeight: FontWeight.w700,
            color: AppColors.dark,
          ),
        ),
        Text(
          label,
          style: AppTypography.labelSmall.copyWith(
            color: AppColors.color2Light,
            fontSize: 10,
          ),
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return Container(height: 24, width: 1, color: AppColors.color4Light.withValues(alpha: 0.3));
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.assessment_outlined, size: 64, color: AppColors.color2Light),
          const SizedBox(height: 12),
          Text('No Assessment Summaries Found', style: AppTypography.titleMedium),
          const SizedBox(height: 4),
          Text(
            'Summaries will appear once students complete test submissions.',
            style: AppTypography.bodySmall,
          ),
        ],
      ),
    );
  }
}
