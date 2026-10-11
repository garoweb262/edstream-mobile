import 'package:flutter/material.dart';
import 'package:edstream_mobile/core/theme/app_colors.dart';
import 'package:edstream_mobile/core/theme/app_typography.dart';
import 'package:edstream_mobile/presentation/widgets/primary_button.dart';

class ReportCardViewScreen extends StatelessWidget {
  final String studentName;
  final String regNumber;
  final String className;
  final String session;
  final String term;
  final double average;
  final int? position;
  final int totalStudents;
  final List<Map<String, dynamic>>? subjects;

  const ReportCardViewScreen({
    super.key,
    required this.studentName,
    required this.regNumber,
    required this.className,
    this.session = '2024/2025',
    this.term = '3rd Term',
    this.average = 84.8,
    this.position = 2,
    this.totalStudents = 38,
    this.subjects,
  });

  @override
  Widget build(BuildContext context) {
    final list = subjects ?? [
      {
        'subject': 'Mathematics',
        'ca1': 16.0,
        'ca2': 18.0,
        'ca3': 0.0,
        'exam': 54.0,
        'total': 88.0,
        'grade': 'A',
        'remark': 'Outstanding',
      },
      {
        'subject': 'English Language',
        'ca1': 15.0,
        'ca2': 17.0,
        'ca3': 0.0,
        'exam': 51.0,
        'total': 83.0,
        'grade': 'A',
        'remark': 'Very Good',
      },
      {
        'subject': 'Physics',
        'ca1': 17.0,
        'ca2': 18.0,
        'ca3': 0.0,
        'exam': 52.0,
        'total': 87.0,
        'grade': 'A',
        'remark': 'Excellent',
      },
      {
        'subject': 'Chemistry',
        'ca1': 14.0,
        'ca2': 15.0,
        'ca3': 0.0,
        'exam': 48.0,
        'total': 77.0,
        'grade': 'B',
        'remark': 'Good',
      },
      {
        'subject': 'Biology',
        'ca1': 15.0,
        'ca2': 16.0,
        'ca3': 0.0,
        'exam': 49.0,
        'total': 80.0,
        'grade': 'A',
        'remark': 'Very Good',
      },
      {
        'subject': 'Civic Education',
        'ca1': 18.0,
        'ca2': 19.0,
        'ca3': 0.0,
        'exam': 56.0,
        'total': 93.0,
        'grade': 'A',
        'remark': 'Exemplary',
      },
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Official Report Card', style: AppTypography.headlineSmall),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            tooltip: 'Share Report Card',
            icon: const Icon(Icons.share_outlined, color: AppColors.primary),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Report Card PDF prepared for sharing!'),
                  backgroundColor: AppColors.primary,
                ),
              );
            },
          ),
          IconButton(
            tooltip: 'Print Report Card',
            icon: const Icon(Icons.print_outlined, color: AppColors.primary),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Sending document to printer...'),
                  backgroundColor: AppColors.success,
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Column(
          children: [
            // Official Report Card Sheet Container
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: AppColors.shadowCard,
                border: Border.all(color: AppColors.color1Light.withValues(alpha: 0.5)),
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // School Letterhead Header
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        padding: const EdgeInsets.all(8),
                        child: Image.asset(
                          'assets/logo/loader-logo.png',
                          errorBuilder: (context, error, stackTrace) => const Icon(
                            Icons.school_rounded,
                            size: 36,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'EDSTREAM ACADEMY',
                              style: AppTypography.titleLarge.copyWith(
                                fontWeight: FontWeight.w800,
                                color: AppColors.primary,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Motto: Excellence in Knowledge & Character',
                              style: AppTypography.labelSmall.copyWith(
                                color: AppColors.color2Light,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Plot 14, Academic Way, Abuja • info@edstream.ng',
                              style: AppTypography.bodySmall.copyWith(
                                fontSize: 11,
                                color: AppColors.dark,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),
                  const Divider(height: 1, thickness: 1.5, color: AppColors.primary),
                  const SizedBox(height: 4),
                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'TERMINAL REPORT SHEET • $term $session',
                        style: AppTypography.labelMedium.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Student Meta Grid
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.cardBorder),
                    ),
                    child: Column(
                      children: [
                        _buildMetaRow('Student Name:', studentName, 'Reg. No:', regNumber),
                        const SizedBox(height: 8),
                        _buildMetaRow('Class:', className, 'Academic Period:', '$term, $session'),
                        const SizedBox(height: 8),
                        _buildMetaRow(
                          'Average Score:',
                          '${average.toStringAsFixed(1)}%',
                          'Position in Class:',
                          position != null ? '$position of $totalStudents' : 'Graded',
                          highlightLeft: true,
                          highlightRight: true,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 18),
                  Text('ACADEMIC PERFORMANCE SUMMARY', style: AppTypography.titleSmall),
                  const SizedBox(height: 10),

                  // Subject Breakdown Table Header
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    child: Row(
                      children: [
                        const Expanded(
                          flex: 3,
                          child: Text(
                            'Subject',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        _buildHeaderCell('CA', flex: 1),
                        _buildHeaderCell('Exam', flex: 1),
                        _buildHeaderCell('Total', flex: 1),
                        _buildHeaderCell('Grd', flex: 1),
                        _buildHeaderCell('Remark', flex: 2),
                      ],
                    ),
                  ),

                  // Subject Rows
                  ...list.asMap().entries.map((entry) {
                    final idx = entry.key;
                    final sub = entry.value;
                    final isEven = idx % 2 == 0;
                    final caTotal = (sub['ca1'] as num? ?? 0.0) +
                        (sub['ca2'] as num? ?? 0.0) +
                        (sub['ca3'] as num? ?? 0.0);
                    final exam = (sub['exam'] as num? ?? 0.0).toDouble();
                    final total = (sub['total'] as num? ?? (caTotal + exam)).toDouble();
                    final grade = sub['grade']?.toString() ?? 'A';
                    final remark = sub['remark']?.toString() ?? 'Good';

                    return Container(
                      decoration: BoxDecoration(
                        color: isEven ? Colors.white : AppColors.background.withValues(alpha: 0.5),
                        border: const Border(
                          bottom: BorderSide(color: Color(0xFFE2E8F0), width: 0.8),
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: Text(
                              sub['subject']?.toString() ?? 'Subject',
                              style: AppTypography.bodySmall.copyWith(
                                fontWeight: FontWeight.w600,
                                color: AppColors.dark,
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 1,
                            child: Text(
                              caTotal.toStringAsFixed(0),
                              textAlign: TextAlign.center,
                              style: AppTypography.bodySmall,
                            ),
                          ),
                          Expanded(
                            flex: 1,
                            child: Text(
                              exam.toStringAsFixed(0),
                              textAlign: TextAlign.center,
                              style: AppTypography.bodySmall,
                            ),
                          ),
                          Expanded(
                            flex: 1,
                            child: Text(
                              total.toStringAsFixed(0),
                              textAlign: TextAlign.center,
                              style: AppTypography.bodySmall.copyWith(
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 1,
                            child: Text(
                              grade,
                              textAlign: TextAlign.center,
                              style: AppTypography.bodySmall.copyWith(
                                fontWeight: FontWeight.w800,
                                color: _getGradeColor(grade),
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              remark,
                              textAlign: TextAlign.center,
                              style: AppTypography.labelSmall.copyWith(
                                color: AppColors.color7Light,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),

                  const SizedBox(height: 18),

                  // Affective & Behavioral Traits Matrix
                  Text('BEHAVIORAL & PSYCHOMOTOR EVALUATION', style: AppTypography.titleSmall),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.cardBorder),
                    ),
                    child: Column(
                      children: [
                        _buildTraitRow('Punctuality & Regularity', '5 / 5 (Excellent)'),
                        const SizedBox(height: 6),
                        _buildTraitRow('Attentiveness & Class Participation', '5 / 5 (Excellent)'),
                        const SizedBox(height: 6),
                        _buildTraitRow('Politeness & Respect for Staff', '4 / 5 (Very Good)'),
                        const SizedBox(height: 6),
                        _buildTraitRow('Leadership & Team Cooperation', '5 / 5 (Excellent)'),
                        const SizedBox(height: 6),
                        _buildTraitRow('Neatness & Personal Hygiene', '5 / 5 (Excellent)'),
                      ],
                    ),
                  ),

                  const SizedBox(height: 18),

                  // Remarks and Signatures Block
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.cardBorder),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Form Master Remarks:', style: AppTypography.labelMedium),
                        const SizedBox(height: 2),
                        Text(
                          'An exceptionally brilliant and disciplined student. Maintains high academic focus and demonstrates leadership qualities in class.',
                          style: AppTypography.bodySmall.copyWith(fontStyle: FontStyle.italic),
                        ),
                        const SizedBox(height: 14),
                        Text('Principal Evaluation:', style: AppTypography.labelMedium),
                        const SizedBox(height: 2),
                        Text(
                          'Outstanding performance. Approved for promotion to the next academic tier with commendation.',
                          style: AppTypography.bodySmall.copyWith(fontStyle: FontStyle.italic),
                        ),
                        const SizedBox(height: 18),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('DR. SULE IDI',
                                    style: AppTypography.titleSmall.copyWith(color: AppColors.primary)),
                                Text('Class Form Master', style: AppTypography.labelSmall),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                border: Border.all(color: AppColors.success, width: 1.5),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'OFFICIAL SEAL • PASSED',
                                style: AppTypography.labelSmall.copyWith(
                                  color: AppColors.success,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Download & Share CTAs
            Row(
              children: [
                Expanded(
                  child: PrimaryButton(
                    text: 'Download PDF',
                    icon: const Icon(Icons.picture_as_pdf_rounded, color: Colors.white, size: 18),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Report Card PDF downloaded to device.'),
                          backgroundColor: AppColors.success,
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: const BorderSide(color: AppColors.primary, width: 1.5),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                    ),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Report Card link copied to clipboard.'),
                          backgroundColor: AppColors.primary,
                        ),
                      );
                    },
                    icon: const Icon(Icons.copy_rounded, color: AppColors.primary, size: 18),
                    label: Text(
                      'Copy Link',
                      style: AppTypography.labelMedium.copyWith(color: AppColors.primary),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildMetaRow(
    String label1,
    String val1,
    String label2,
    String val2, {
    bool highlightLeft = false,
    bool highlightRight = false,
  }) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label1, style: AppTypography.labelSmall.copyWith(color: AppColors.color2Light)),
              const SizedBox(height: 1),
              Text(
                val1,
                style: AppTypography.bodySmall.copyWith(
                  fontWeight: FontWeight.w700,
                  color: highlightLeft ? AppColors.primary : AppColors.dark,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label2, style: AppTypography.labelSmall.copyWith(color: AppColors.color2Light)),
              const SizedBox(height: 1),
              Text(
                val2,
                style: AppTypography.bodySmall.copyWith(
                  fontWeight: FontWeight.w700,
                  color: highlightRight ? AppColors.success : AppColors.dark,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTraitRow(String trait, String score) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(trait, style: AppTypography.bodySmall),
        Text(
          score,
          style: AppTypography.bodySmall.copyWith(
            fontWeight: FontWeight.w700,
            color: AppColors.primary,
          ),
        ),
      ],
    );
  }

  Widget _buildHeaderCell(String label, {required int flex}) {
    return Expanded(
      flex: flex,
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }

  Color _getGradeColor(String grade) {
    switch (grade) {
      case 'A':
        return AppColors.success;
      case 'B':
        return AppColors.primary;
      case 'C':
        return const Color(0xFFF59E0B);
      case 'D':
        return AppColors.secondary;
      default:
        return AppColors.danger;
    }
  }
}
