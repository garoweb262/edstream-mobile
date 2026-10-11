import 'package:flutter/material.dart';
import 'package:edstream_mobile/core/network/api_client.dart';
import 'package:edstream_mobile/core/storage/local_cache_store.dart';
import 'package:edstream_mobile/core/theme/app_colors.dart';
import 'package:edstream_mobile/core/theme/app_typography.dart';
import 'package:edstream_mobile/core/widgets/sync_status_banner.dart';
import 'package:edstream_mobile/presentation/screens/common/report_card_view_screen.dart';

class ResultsScreen extends StatefulWidget {
  const ResultsScreen({super.key});

  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen> {
  int _selectedTerm = 3; // 1 = First, 2 = Second, 3 = Third
  bool _isLoading = true;

  double _average = 84.8;
  int _position = 2;
  double _totalMarks = 504.0;
  String _session = '2024/2025';
  String _termName = '3rd Term';

  List<Map<String, dynamic>> _subjects = [
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
    final cached = LocalCacheStore.instance.getJson(cacheKey);

    if (cached is Map) {
      _applyResultData(cached);
      setState(() => _isLoading = false);
    }

    try {
      final res = await ApiClient.instance.get(
        'student/my-results',
        cacheLocally: true,
        cacheKey: cacheKey,
      );

      if (res is List && res.isNotEmpty) {
        _applyResultData(res.first as Map);
      } else if (res is Map && res['data'] is List && (res['data'] as List).isNotEmpty) {
        _applyResultData((res['data'] as List).first as Map);
      } else if (res is Map) {
        _applyResultData(res);
      }
    } catch (_) {}
    if (mounted) setState(() => _isLoading = false);
  }

  void _applyResultData(Map data) {
    final academic = data['academicInfo'] as Map?;
    if (academic != null) {
      _average = (academic['average'] as num?)?.toDouble() ?? _average;
      _position = (academic['position'] as num?)?.toInt() ?? _position;
      _totalMarks = (academic['totalMarks'] as num?)?.toDouble() ?? _totalMarks;
    }

    if (data['session'] is Map) {
      _session = data['session']['session'] ?? _session;
    } else if (data['session'] != null) {
      _session = data['session'].toString();
    }

    if (data['term'] is Map) {
      _termName = data['term']['term'] ?? _termName;
    } else if (data['term'] != null) {
      _termName = data['term'].toString();
    }

    final rawSubs = data['subjects'] as List?;
    if (rawSubs != null && rawSubs.isNotEmpty) {
      final List<Map<String, dynamic>> mapped = [];
      for (final s in rawSubs) {
        if (s is Map) {
          final sName = s['subjectName'] ?? s['subject'] ?? 'Subject';
          final ca1 = (s['ca1'] as num?)?.toDouble() ?? 0.0;
          final ca2 = (s['ca2'] as num?)?.toDouble() ?? 0.0;
          final ca3 = (s['ca3'] as num?)?.toDouble() ?? 0.0;
          final totalCa = (s['totalCa'] as num?)?.toDouble() ?? (ca1 + ca2 + ca3);
          final exam = (s['exam'] as num?)?.toDouble() ?? 0.0;
          final total = (s['totalScore'] as num?)?.toDouble() ?? (s['total'] as num?)?.toDouble() ?? (totalCa + exam);
          final grade = s['grade']?.toString() ?? 'A';
          final remark = s['remark']?.toString() ?? 'Good';

          mapped.add({
            'subject': sName,
            'ca': totalCa,
            'exam': exam,
            'total': total,
            'grade': grade,
            'remark': remark,
          });
        }
      }
      if (mapped.isNotEmpty) {
        setState(() {
          _subjects = mapped;
        });
      }
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

  String _positionSuffix(int position) {
    if (position > 3 && position < 21) return 'th';
    switch (position % 10) {
      case 1:
        return 'st';
      case 2:
        return 'nd';
      case 3:
        return 'rd';
      default:
        return 'th';
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
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _fetchResults,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
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
                                      style: AppTypography.titleMedium.copyWith(color: Colors.white),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.white24,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        '$_termName • $_session',
                                        style: AppTypography.labelSmall.copyWith(color: Colors.white),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 20),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                                  children: [
                                    _buildHeroMetric('Average', '${_average.toStringAsFixed(1)}%'),
                                    Container(width: 1, height: 40, color: Colors.white24),
                                    _buildHeroMetric('Class Position', '$_position${_positionSuffix(_position)}'),
                                    Container(width: 1, height: 40, color: Colors.white24),
                                    _buildHeroMetric('Total Marks', _totalMarks.toInt().toString()),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                InkWell(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => ReportCardViewScreen(
                                          studentName: 'Alex Johnson Chukwuma',
                                          regNumber: 'EDS/2026/0491',
                                          className: 'SS 2 Gold',
                                          session: _session,
                                          term: _termName,
                                          average: _average,
                                          position: _position,
                                          totalStudents: 38,
                                          subjects: _subjects,
                                        ),
                                      ),
                                    );
                                  },
                                  borderRadius: BorderRadius.circular(14),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        const Icon(Icons.description_rounded, size: 18, color: AppColors.primary),
                                        const SizedBox(width: 8),
                                        Text(
                                          'View Official Printable Report Card',
                                          style: AppTypography.labelMedium.copyWith(
                                            color: AppColors.primary,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Subject Grades List
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Subject Breakdown', style: AppTypography.titleLarge),
                              Text('${_subjects.length} Subjects', style: AppTypography.bodySmall),
                            ],
                          ),
                          const SizedBox(height: 14),

                          ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _subjects.length,
                            separatorBuilder: (context, index) => const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final sub = _subjects[index];
                              final gradeColor = _getGradeColor(sub['grade'] as String);

                              return Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(18),
                                  border: Border.all(color: AppColors.cardBorder),
                                  boxShadow: AppColors.shadowSm,
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 48,
                                      height: 48,
                                      decoration: BoxDecoration(
                                        color: gradeColor.withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                      alignment: Alignment.center,
                                      child: Text(
                                        sub['grade'] as String,
                                        style: TextStyle(
                                          fontSize: 22,
                                          fontWeight: FontWeight.w700,
                                          color: gradeColor,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            sub['subject'] as String,
                                            style: AppTypography.titleMedium,
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'CA: ${sub['ca']}  •  Exam: ${sub['exam']}',
                                            style: AppTypography.bodySmall,
                                          ),
                                        ],
                                      ),
                                    ),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          '${sub['total']}%',
                                          style: AppTypography.titleLarge.copyWith(
                                            color: AppColors.primary,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        Text(
                                          sub['remark'] as String,
                                          style: AppTypography.labelSmall.copyWith(
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                      ],
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
          ),
        ],
      ),
    );
  }

  Widget _buildTermChip(String label, int term) {
    final isSelected = _selectedTerm == term;
    return GestureDetector(
      onTap: () => setState(() => _selectedTerm = term),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.grey[100],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: AppTypography.labelMedium.copyWith(
            color: isSelected ? Colors.white : AppColors.textSecondary,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildHeroMetric(String title, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          title,
          style: TextStyle(
            fontSize: 12,
            color: Colors.white.withValues(alpha: 0.8),
          ),
        ),
      ],
    );
  }
}
