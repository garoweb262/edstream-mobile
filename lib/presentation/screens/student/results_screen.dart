import 'package:flutter/material.dart';
import 'package:edstream_mobile/core/network/api_client.dart';
import 'package:edstream_mobile/core/theme/app_colors.dart';
import 'package:edstream_mobile/core/theme/app_typography.dart';
import 'package:edstream_mobile/core/widgets/sync_status_banner.dart';

class ResultsScreen extends StatefulWidget {
  const ResultsScreen({super.key});

  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen> {
  int _selectedTerm = 1; // 1 = First, 2 = Second, 3 = Third

  final List<Map<String, dynamic>> _subjects = [
    {
      'subject': 'Mathematics',
      'ca': 35.0,
      'exam': 54.0,
      'total': 89.0,
      'grade': 'A',
      'remark': 'Outstanding',
    },
    {
      'subject': 'English Language',
      'ca': 32.0,
      'exam': 50.0,
      'total': 82.0,
      'grade': 'A',
      'remark': 'Very Good',
    },
    {
      'subject': 'Physics',
      'ca': 34.0,
      'exam': 53.0,
      'total': 87.0,
      'grade': 'A',
      'remark': 'Excellent',
    },
    {
      'subject': 'Chemistry',
      'ca': 28.0,
      'exam': 48.0,
      'total': 76.0,
      'grade': 'B',
      'remark': 'Good',
    },
    {
      'subject': 'Biology',
      'ca': 31.0,
      'exam': 47.0,
      'total': 78.0,
      'grade': 'B',
      'remark': 'Very Good',
    },
    {
      'subject': 'Civic Education',
      'ca': 36.0,
      'exam': 56.0,
      'total': 92.0,
      'grade': 'A',
      'remark': 'Exemplary',
    },
  ];

  @override
  void initState() {
    super.initState();
    _fetchResults();
  }

  Future<void> _fetchResults() async {
    const cacheKey = 'student_terminal_results';
    try {
      await ApiClient.instance.get(
        'student/my-results',
        cacheLocally: true,
        cacheKey: cacheKey,
      );
    } catch (_) {
      // Offline fallback already stored
    }
  }

  Color _getGradeColor(String grade) {
    switch (grade) {
      case 'A':
        return AppColors.success;
      case 'B':
        return AppColors.primary;
      case 'C':
        return const Color(0xFFF59E0B);
      default:
        return AppColors.danger;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Report Card & Results', style: AppTypography.headlineSmall),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          const SyncStatusBanner(),

          // Term Filter Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            color: Colors.white,
            child: Row(
              children: [
                _buildTermChip('1st Term', 1),
                const SizedBox(width: 8),
                _buildTermChip('2nd Term', 2),
                const SizedBox(width: 8),
                _buildTermChip('3rd Term', 3),
              ],
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Summary Banner
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: AppColors.heroCardGradient,
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: AppColors.shadowMd,
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Terminal Summary',
                              style: AppTypography.titleLarge.copyWith(color: Colors.white),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                'Rank: 2nd / 42',
                                style: AppTypography.labelSmall.copyWith(color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildSummaryMetric('Average', '84.0%'),
                            _buildSummaryMetric('Total Marks', '504 / 600'),
                            _buildSummaryMetric('Overall Grade', 'A'),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  Text('Subject Breakdown', style: AppTypography.titleLarge),
                  const SizedBox(height: 14),

                  // Cards List
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _subjects.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final item = _subjects[index];
                      final grade = item['grade'] as String;
                      final gradeColor = _getGradeColor(grade);

                      return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: AppColors.shadowCard,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  item['subject'] as String,
                                  style: AppTypography.titleMedium.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: gradeColor.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    'Grade $grade',
                                    style: AppTypography.labelSmall.copyWith(
                                      color: gradeColor,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            const Divider(height: 1),
                            const SizedBox(height: 10),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                _buildScoreUnit('CA Score', '${item['ca']} / 40'),
                                _buildScoreUnit('Exam Score', '${item['exam']} / 60'),
                                _buildScoreUnit('Total', '${item['total']} / 100', isBold: true),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Instructor Remark: ${item['remark']}',
                              style: AppTypography.bodySmall.copyWith(
                                color: AppColors.color2Light,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTermChip(String label, int term) {
    final isSelected = _selectedTerm == term;
    return GestureDetector(
      onTap: () => setState(() => _selectedTerm = term),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.color3Light,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: AppTypography.labelMedium.copyWith(
            color: isSelected ? Colors.white : AppColors.dark,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryMetric(String title, String val) {
    return Column(
      children: [
        Text(val, style: AppTypography.headlineMedium.copyWith(color: Colors.white)),
        const SizedBox(height: 2),
        Text(
          title,
          style: AppTypography.labelSmall.copyWith(color: Colors.white70),
        ),
      ],
    );
  }

  Widget _buildScoreUnit(String label, String val, {bool isBold = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTypography.labelSmall),
        const SizedBox(height: 2),
        Text(
          val,
          style: AppTypography.bodyMedium.copyWith(
            fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
            color: isBold ? AppColors.primary : AppColors.dark,
          ),
        ),
      ],
    );
  }
}
