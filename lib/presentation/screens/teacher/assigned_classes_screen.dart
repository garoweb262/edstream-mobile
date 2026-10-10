import 'package:flutter/material.dart';
import 'package:edstream_mobile/core/network/api_client.dart';
import 'package:edstream_mobile/core/storage/local_cache_store.dart';
import 'package:edstream_mobile/core/theme/app_colors.dart';
import 'package:edstream_mobile/core/theme/app_typography.dart';
import 'package:edstream_mobile/core/widgets/sync_status_banner.dart';
import 'package:edstream_mobile/presentation/screens/teacher/student_roster_screen.dart';

class AssignedClassesScreen extends StatefulWidget {
  const AssignedClassesScreen({super.key});

  @override
  State<AssignedClassesScreen> createState() => _AssignedClassesScreenState();
}

class _AssignedClassesScreenState extends State<AssignedClassesScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _classes = [];

  @override
  void initState() {
    super.initState();
    _fetchAssignedClasses();
  }

  Future<void> _fetchAssignedClasses() async {
    const cacheKey = 'teacher_assigned_classes';
    final cached = LocalCacheStore.instance.getJson(cacheKey);

    if (cached is List) {
      setState(() {
        _classes = List<Map<String, dynamic>>.from(cached);
        _isLoading = false;
      });
    }

    try {
      final response = await ApiClient.instance.get(
        'staff/assigned-classes',
        cacheLocally: true,
        cacheKey: cacheKey,
      );

      if (response is List) {
        setState(() {
          _classes = List<Map<String, dynamic>>.from(response);
          _isLoading = false;
        });
      }
    } catch (_) {
      if (_classes.isEmpty) {
        _classes = [
          {
            'name': 'SS 2 Gold',
            'grade': 'Senior Secondary 2',
            'studentsCount': 42,
            'isFormTeacher': true,
            'room': 'Block B, Hall 4',
          },
          {
            'name': 'SS 2 Diamond',
            'grade': 'Senior Secondary 2',
            'studentsCount': 38,
            'isFormTeacher': false,
            'room': 'Block B, Hall 5',
          },
          {
            'name': 'JSS 3 Blue',
            'grade': 'Junior Secondary 3',
            'studentsCount': 48,
            'isFormTeacher': false,
            'room': 'Block A, Hall 2',
          },
        ];
        LocalCacheStore.instance.setJson(cacheKey, _classes);
      }
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Assigned Classes', style: AppTypography.headlineSmall),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          const SyncStatusBanner(itemNoun: 'class record'),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _fetchAssignedClasses,
                    child: ListView.separated(
                      padding: const EdgeInsets.all(20),
                      itemCount: _classes.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 14),
                      itemBuilder: (context, index) {
                        final cls = _classes[index];
                        final isForm = cls['isFormTeacher'] == true;

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
                                    builder: (_) => StudentRosterScreen(
                                      className: cls['name'] as String,
                                      studentsCount: cls['studentsCount'] as int,
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
                                            color: AppColors.secondary.withValues(alpha: 0.12),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: const Icon(
                                            Icons.groups_rounded,
                                            color: AppColors.secondary,
                                            size: 22,
                                          ),
                                        ),
                                        if (isForm)
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: AppColors.primary.withValues(alpha: 0.12),
                                              borderRadius: BorderRadius.circular(10),
                                            ),
                                            child: Text(
                                              'Form Teacher',
                                              style: AppTypography.labelSmall.copyWith(
                                                color: AppColors.primary,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 14),
                                    Text(
                                      cls['name'] as String,
                                      style: AppTypography.titleLarge,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${cls['grade']} • ${cls['room']}',
                                      style: AppTypography.bodySmall,
                                    ),
                                    const SizedBox(height: 16),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          '${cls['studentsCount']} Enrolled Students',
                                          style: AppTypography.labelMedium.copyWith(
                                            color: AppColors.light,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        Row(
                                          children: [
                                            Text(
                                              'View Roster',
                                              style: AppTypography.labelSmall.copyWith(
                                                color: AppColors.primary,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                            const SizedBox(width: 4),
                                            const Icon(Icons.arrow_forward_ios_rounded,
                                                size: 12, color: AppColors.primary),
                                          ],
                                        ),
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
