import 'package:flutter/material.dart';
import 'package:edstream_mobile/core/network/api_client.dart';
import 'package:edstream_mobile/core/storage/local_cache_store.dart';
import 'package:edstream_mobile/core/theme/app_colors.dart';
import 'package:edstream_mobile/core/theme/app_typography.dart';
import 'package:edstream_mobile/core/widgets/sync_status_banner.dart';
import 'package:edstream_mobile/presentation/screens/teacher/score_sheet_screen.dart';

class AssignedSubjectsScreen extends StatefulWidget {
  const AssignedSubjectsScreen({super.key});

  @override
  State<AssignedSubjectsScreen> createState() => _AssignedSubjectsScreenState();
}

class _AssignedSubjectsScreenState extends State<AssignedSubjectsScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _subjects = [];

  @override
  void initState() {
    super.initState();
    _fetchAssignedSubjects();
  }

  Future<void> _fetchAssignedSubjects() async {
    const cacheKey = 'teacher_assigned_subjects';
    final cached = LocalCacheStore.instance.getJson(cacheKey);

    if (cached is List) {
      setState(() {
        _subjects = List<Map<String, dynamic>>.from(cached);
        _isLoading = false;
      });
    }

    try {
      final response = await ApiClient.instance.get(
        'staff/assigned-subjects',
        cacheLocally: true,
        cacheKey: cacheKey,
      );

      if (response is List) {
        setState(() {
          _subjects = List<Map<String, dynamic>>.from(response);
          _isLoading = false;
        });
      }
    } catch (_) {
      // Fallback default mock data if new institution or offline
      if (_subjects.isEmpty) {
        _subjects = [
          {
            'id': 'sub-1',
            'name': 'Mathematics',
            'class': 'SS 2 Gold',
            'studentsCount': 42,
            'isGraded': false,
            'color': 0xFF0012BF,
          },
          {
            'id': 'sub-2',
            'name': 'Further Mathematics',
            'class': 'SS 2 Diamond',
            'studentsCount': 35,
            'isGraded': true,
            'color': 0xFF4D44B5,
          },
          {
            'id': 'sub-3',
            'name': 'Basic Technology',
            'class': 'JSS 3 Blue',
            'studentsCount': 48,
            'isGraded': false,
            'color': 0xFF0EA5E9,
          },
          {
            'id': 'sub-4',
            'name': 'Computer Science',
            'class': 'SS 1 Emerald',
            'studentsCount': 40,
            'isGraded': true,
            'color': 0xFF10B981,
          },
        ];
        LocalCacheStore.instance.setJson(cacheKey, _subjects);
      }
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Assigned Subjects', style: AppTypography.headlineSmall),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          const SyncStatusBanner(feature: 'scoresheet', itemNoun: 'grade sheet'),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _fetchAssignedSubjects,
                    child: ListView.separated(
                      padding: const EdgeInsets.all(20),
                      itemCount: _subjects.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 14),
                      itemBuilder: (context, index) {
                        final subject = _subjects[index];
                        final isGraded = subject['isGraded'] == true;
                        final color = Color(subject['color'] as int? ?? 0xFF0012BF);

                        return Container(
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: AppColors.shadowCard,
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(20),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => ScoreSheetScreen(
                                      subjectId: subject['id'] ?? 'sub-$index',
                                      subjectName: subject['name'] ?? 'Subject',
                                      className: subject['class'] ?? 'Class',
                                    ),
                                  ),
                                );
                              },
                              child: Padding(
                                padding: const EdgeInsets.all(18),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(10),
                                          decoration: BoxDecoration(
                                            color: color.withValues(alpha: 0.12),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Icon(Icons.menu_book_rounded, color: color, size: 22),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: (isGraded ? AppColors.success : const Color(0xFFF59E0B))
                                                .withValues(alpha: 0.12),
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          child: Text(
                                            isGraded ? 'Grading Completed' : 'Grading Pending',
                                            style: AppTypography.labelSmall.copyWith(
                                              color: isGraded ? AppColors.success : const Color(0xFFD97706),
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 14),
                                    Text(
                                      subject['name'] as String,
                                      style: AppTypography.titleLarge,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${subject['class']} • ${subject['studentsCount']} Registered Students',
                                      style: AppTypography.bodySmall,
                                    ),
                                    const SizedBox(height: 16),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'Open Score Sheet',
                                          style: AppTypography.labelMedium.copyWith(
                                            color: AppColors.primary,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const Icon(Icons.arrow_forward_ios_rounded,
                                            size: 14, color: AppColors.primary),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
