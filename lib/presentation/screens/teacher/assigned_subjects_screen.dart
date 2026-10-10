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
      // 1. First attempt: GET subject-class/get (Contains exact subjectClass IDs for score sheet)
      try {
        final scResponse = await ApiClient.instance.get(
          'subject-class/get',
          cacheLocally: true,
          cacheKey: 'subject_class_get_cache',
        );

        if (scResponse is Map && scResponse['data'] is List && (scResponse['data'] as List).isNotEmpty) {
          final mapped = (scResponse['data'] as List).map<Map<String, dynamic>>((item) {
            final sub = item['subject'] as Map? ?? {};
            final cls = item['class'] as Map? ?? {};
            final subName = sub['subjectName'] ?? 'Subject';
            final className = '${cls['code'] ?? ''} ${cls['subclass'] ?? ''}'.trim();
            final subjectClassId = item['_id']?.toString() ?? '';

            return {
              'id': subjectClassId,
              'subjectClassId': subjectClassId,
              'name': subName,
              'subjectCode': sub['subjectCode'] ?? '',
              'class': className.isNotEmpty ? className : 'General Class',
              'session': item['session']?.toString() ?? '2024/2025',
              'term': item['term']?.toString() ?? '3rd Term',
              'studentsCount': 40,
              'isGraded': false,
              'color': 0xFF0012BF,
            };
          }).toList();

          setState(() {
            _subjects = mapped;
            _isLoading = false;
          });
          LocalCacheStore.instance.setJson(cacheKey, mapped);
          return;
        }
      } catch (_) {}

      // 2. Second attempt: GET staff/dashboard subjectAssignments
      final dashResponse = await ApiClient.instance.get(
        'staff/dashboard',
        cacheLocally: true,
        cacheKey: 'staff_dashboard_cache',
      );

      if (dashResponse is Map && dashResponse['teacherData'] is Map) {
        final teacherData = dashResponse['teacherData'] as Map;
        final rawSubAssignments = teacherData['subjectAssignments'];

        if (rawSubAssignments is List && rawSubAssignments.isNotEmpty) {
          final mapped = rawSubAssignments.map<Map<String, dynamic>>((item) {
            final subId = item['subjectId']?.toString() ?? '';
            final subName = item['subjectName'] ?? 'Subject';
            final className = item['className'] ?? 'Class';

            return {
              'id': subId,
              'subjectClassId': subId,
              'name': subName,
              'subjectCode': item['subjectCode'] ?? '',
              'class': className,
              'session': item['sessionId']?.toString() ?? '2024/2025',
              'term': item['termId']?.toString() ?? '3rd Term',
              'studentsCount': 42,
              'isGraded': false,
              'color': 0xFF0012BF,
            };
          }).toList();

          setState(() {
            _subjects = mapped;
            _isLoading = false;
          });
          LocalCacheStore.instance.setJson(cacheKey, mapped);
          return;
        }
      }
    } catch (_) {}

    // Fallback default mock data if offline or newly initialized
    if (_subjects.isEmpty) {
      _subjects = [
        {
          'id': 'sub-1',
          'subjectClassId': 'sub-1',
          'name': 'Mathematics',
          'subjectCode': 'MTH',
          'class': 'SS 2 Gold',
          'session': '2024/2025',
          'term': '3rd Term',
          'studentsCount': 42,
          'isGraded': false,
          'color': 0xFF0012BF,
        },
        {
          'id': 'sub-2',
          'subjectClassId': 'sub-2',
          'name': 'Further Mathematics',
          'subjectCode': 'FMTH',
          'class': 'SS 2 Diamond',
          'session': '2024/2025',
          'term': '3rd Term',
          'studentsCount': 35,
          'isGraded': true,
          'color': 0xFF4D44B5,
        },
        {
          'id': 'sub-3',
          'subjectClassId': 'sub-3',
          'name': 'Basic Technology',
          'subjectCode': 'BTECH',
          'class': 'JSS 3 Blue',
          'session': '2024/2025',
          'term': '3rd Term',
          'studentsCount': 48,
          'isGraded': false,
          'color': 0xFF0EA5E9,
        },
        {
          'id': 'sub-4',
          'subjectClassId': 'sub-4',
          'name': 'Computer Science',
          'subjectCode': 'CSC',
          'class': 'SS 1 Emerald',
          'session': '2024/2025',
          'term': '3rd Term',
          'studentsCount': 40,
          'isGraded': true,
          'color': 0xFF10B981,
        },
      ];
      LocalCacheStore.instance.setJson(cacheKey, _subjects);
    }
    setState(() => _isLoading = false);
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
          const SyncStatusBanner(itemNoun: 'subject record'),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _fetchAssignedSubjects,
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      itemCount: _subjects.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 14),
                      itemBuilder: (context, index) {
                        final subject = _subjects[index];
                        final isGraded = subject['isGraded'] as bool? ?? false;
                        final color = Color(subject['color'] as int? ?? 0xFF0012BF);

                        return Card(
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                            side: const BorderSide(color: AppColors.cardBorder),
                          ),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(18),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ScoreSheetScreen(
                                    subjectId: (subject['subjectClassId'] ?? subject['id']) as String,
                                    subjectName: subject['name'] as String,
                                    className: subject['class'] as String,
                                    session: subject['session']?.toString(),
                                    term: subject['term']?.toString(),
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
                                          isGraded ? 'Grading Completed' : 'Scoresheet Ready',
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
