import 'package:flutter/material.dart';
import 'package:edstream_mobile/core/network/api_client.dart';
import 'package:edstream_mobile/core/theme/app_colors.dart';
import 'package:edstream_mobile/core/theme/app_typography.dart';
import 'package:edstream_mobile/core/widgets/sync_status_banner.dart';

class TimetableScreen extends StatefulWidget {
  const TimetableScreen({super.key});

  @override
  State<TimetableScreen> createState() => _TimetableScreenState();
}

class _TimetableScreenState extends State<TimetableScreen> {
  int _selectedDay = 0; // 0 = Mon, 1 = Tue, etc.
  bool _isLoading = false;

  final List<String> _days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri'];

  Map<int, List<Map<String, String>>> _schedules = {
    0: [
      {
        'time': '08:00 AM - 08:45 AM',
        'subject': 'Mathematics',
        'teacher': 'Mr. Ahmad Garo',
        'room': 'Block B, Hall 4',
      },
      {
        'time': '08:45 AM - 09:30 AM',
        'subject': 'English Language',
        'teacher': 'Mrs. Chidinma Eze',
        'room': 'Block B, Hall 4',
      },
      {
        'time': '09:30 AM - 10:15 AM',
        'subject': 'Physics',
        'teacher': 'Dr. Bala Mohammed',
        'room': 'Physics Lab',
      },
      {
        'time': '10:15 AM - 10:45 AM',
        'subject': 'Short Break & Refreshments',
        'teacher': 'Campus Cafeteria',
        'room': 'Main Courtyard',
      },
      {
        'time': '10:45 AM - 11:30 AM',
        'subject': 'Chemistry',
        'teacher': 'Mrs. Zainab Umar',
        'room': 'Chemistry Lab',
      },
      {
        'time': '11:30 AM - 12:15 PM',
        'subject': 'Civic Education',
        'teacher': 'Mr. Oluwaseun Davies',
        'room': 'Block B, Hall 4',
      },
    ],
    1: [
      {
        'time': '08:00 AM - 08:45 AM',
        'subject': 'Biology',
        'teacher': 'Mr. Samuel Oladipo',
        'room': 'Biology Lab',
      },
      {
        'time': '08:45 AM - 09:30 AM',
        'subject': 'Economics',
        'teacher': 'Mr. Ibrahim Musa',
        'room': 'Block B, Hall 4',
      },
      {
        'time': '09:30 AM - 10:15 AM',
        'subject': 'Computer Science',
        'teacher': 'Engr. Victor Okafor',
        'room': 'ICT Center',
      },
    ],
    2: [
      {
        'time': '08:00 AM - 08:45 AM',
        'subject': 'Further Mathematics',
        'teacher': 'Mr. Ahmad Garo',
        'room': 'Block B, Hall 4',
      },
      {
        'time': '08:45 AM - 09:30 AM',
        'subject': 'Technical Drawing',
        'teacher': 'Mr. Babatunde Lawal',
        'room': 'Design Studio',
      },
    ],
    3: [
      {
        'time': '08:00 AM - 08:45 AM',
        'subject': 'Agricultural Science',
        'teacher': 'Mrs. Amina Bello',
        'room': 'School Farm',
      },
      {
        'time': '08:45 AM - 09:30 AM',
        'subject': 'Geography',
        'teacher': 'Mr. Danjuma Yakubu',
        'room': 'Block B, Hall 4',
      },
    ],
    4: [
      {
        'time': '08:00 AM - 08:45 AM',
        'subject': 'Sports & Physical Health',
        'teacher': 'Coach Sunday Eze',
        'room': 'Sports Complex',
      },
      {
        'time': '08:45 AM - 09:30 AM',
        'subject': 'Library & Guided Study',
        'teacher': 'Mrs. Grace Adeleke',
        'room': 'Main Library',
      },
    ],
  };

  @override
  void initState() {
    super.initState();
    _fetchTimetable();
  }

  Future<void> _fetchTimetable() async {
    setState(() => _isLoading = true);
    const cacheKey = 'student_timetable_cache';
    try {
      final res = await ApiClient.instance.get(
        'student/my-timetable',
        cacheLocally: true,
        cacheKey: cacheKey,
      );

      if (res is Map && res['data'] is Map) {
        final data = res['data'] as Map;
        final daysList = ['monday', 'tuesday', 'wednesday', 'thursday', 'friday'];
        final Map<int, List<Map<String, String>>> parsed = {};

        for (int i = 0; i < daysList.length; i++) {
          final dayKey = daysList[i];
          final periods = data[dayKey] as List? ?? [];
          if (periods.isNotEmpty) {
            parsed[i] = periods.map<Map<String, String>>((p) {
              return {
                'time': p['time']?.toString() ?? '08:00 AM - 08:45 AM',
                'subject': p['subject']?.toString() ?? 'Subject',
                'teacher': p['teacher']?.toString() ?? 'Teacher',
                'room': p['room']?.toString() ?? 'Classroom',
              };
            }).toList();
          }
        }

        if (parsed.isNotEmpty) {
          setState(() {
            _schedules = parsed;
          });
        }
      }
    } catch (_) {}
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final periods = _schedules[_selectedDay] ?? [];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Weekly Timetable', style: AppTypography.headlineSmall),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          const SyncStatusBanner(),

          // Days Selector
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            color: Colors.white,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(_days.length, (index) {
                final isSelected = _selectedDay == index;
                return GestureDetector(
                  onTap: () => setState(() => _selectedDay = index),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primary : AppColors.color3Light,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      _days[index],
                      style: AppTypography.labelLarge.copyWith(
                        color: isSelected ? Colors.white : AppColors.light,
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),

          // Periods List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _fetchTimetable,
                    child: ListView.separated(
                padding: const EdgeInsets.all(20),
                itemCount: periods.length,
                separatorBuilder: (context, index) => const SizedBox(height: 14),
                itemBuilder: (context, index) {
                  final period = periods[index];
                  final isBreak = (period['subject'] ?? '').contains('Break');

                  return Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: isBreak ? const Color(0xFFFEF3C7) : AppColors.surface,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: isBreak ? null : AppColors.shadowCard,
                      border: isBreak
                          ? Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.3))
                          : null,
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: (isBreak ? const Color(0xFFF59E0B) : AppColors.primary)
                                .withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            isBreak ? Icons.restaurant_rounded : Icons.schedule_rounded,
                            color: isBreak ? const Color(0xFFD97706) : AppColors.primary,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                period['subject'] ?? 'Subject',
                                style: AppTypography.titleMedium.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: isBreak ? const Color(0xFF92400E) : AppColors.light,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${period['teacher']} • ${period['room']}',
                                style: AppTypography.bodySmall,
                              ),
                            ],
                          ),
                        ),
                        Text(
                          (period['time'] ?? '').split(' - ')[0],
                          style: AppTypography.labelSmall.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
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
