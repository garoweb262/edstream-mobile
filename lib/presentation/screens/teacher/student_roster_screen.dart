import 'package:flutter/material.dart';
import 'package:edstream_mobile/core/theme/app_colors.dart';
import 'package:edstream_mobile/core/theme/app_typography.dart';

class StudentRosterScreen extends StatefulWidget {
  const StudentRosterScreen({
    super.key,
    required this.className,
    required this.studentsCount,
  });

  final String className;
  final int studentsCount;

  @override
  State<StudentRosterScreen> createState() => _StudentRosterScreenState();
}

class _StudentRosterScreenState extends State<StudentRosterScreen> {
  final TextEditingController _searchController = TextEditingController();

  final List<Map<String, dynamic>> _allStudents = [
    {
      'name': 'Alex Johnson',
      'regNo': 'EDS/2026/0491',
      'gender': 'Male',
      'parent': 'Mr. Michael Johnson',
      'phone': '+234 803 123 4567',
      'status': 'Active',
    },
    {
      'name': 'Fatima Aliyu',
      'regNo': 'EDS/2026/0492',
      'gender': 'Female',
      'parent': 'Dr. Usman Aliyu',
      'phone': '+234 802 987 6543',
      'status': 'Active',
    },
    {
      'name': 'Chinedu Okeke',
      'regNo': 'EDS/2026/0493',
      'gender': 'Male',
      'parent': 'Mrs. Ngozi Okeke',
      'phone': '+234 814 555 1212',
      'status': 'Active',
    },
    {
      'name': 'Zainab Bello',
      'regNo': 'EDS/2026/0494',
      'gender': 'Female',
      'parent': 'Alhaji Ibrahim Bello',
      'phone': '+234 805 777 8899',
      'status': 'Active',
    },
    {
      'name': 'David Adeleke',
      'regNo': 'EDS/2026/0495',
      'gender': 'Male',
      'parent': 'Chief Deji Adeleke',
      'phone': '+234 809 333 4455',
      'status': 'Active',
    },
    {
      'name': 'Mary Sani',
      'regNo': 'EDS/2026/0496',
      'gender': 'Female',
      'parent': 'Mrs. Grace Sani',
      'phone': '+234 803 888 2211',
      'status': 'Active',
    },
  ];

  late List<Map<String, dynamic>> _filteredStudents;

  @override
  void initState() {
    super.initState();
    _filteredStudents = _allStudents;
  }

  void _filter(String query) {
    if (query.trim().isEmpty) {
      setState(() => _filteredStudents = _allStudents);
      return;
    }
    final q = query.toLowerCase();
    setState(() {
      _filteredStudents = _allStudents.where((s) {
        final name = (s['name'] as String).toLowerCase();
        final reg = (s['regNo'] as String).toLowerCase();
        return name.contains(q) || reg.contains(q);
      }).toList();
    });
  }

  void _showStudentProfile(Map<String, dynamic> student) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                    child: Text(
                      student['name'].toString().substring(0, 1),
                      style: AppTypography.headlineMedium.copyWith(color: AppColors.primary),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(student['name'] as String, style: AppTypography.titleLarge),
                        Text(student['regNo'] as String, style: AppTypography.bodySmall),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Divider(),
              const SizedBox(height: 12),
              _buildProfileRow('Class', widget.className),
              _buildProfileRow('Gender', student['gender'] as String),
              _buildProfileRow('Parent / Guardian', student['parent'] as String),
              _buildProfileRow('Guardian Contact', student['phone'] as String),
              _buildProfileRow('Enrolment Status', student['status'] as String,
                  isHighlighted: true),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Widget _buildProfileRow(String label, String value, {bool isHighlighted = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTypography.labelMedium),
          Text(
            value,
            style: AppTypography.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
              color: isHighlighted ? AppColors.success : AppColors.dark,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${widget.className} Roster', style: AppTypography.headlineSmall),
            Text('${_filteredStudents.length} Students', style: AppTypography.bodySmall),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // Search Field
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
            child: TextField(
              controller: _searchController,
              onChanged: _filter,
              style: AppTypography.input,
              decoration: InputDecoration(
                hintText: 'Search student name or reg number...',
                prefixIcon: const Icon(Icons.search_rounded, size: 20),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          _filter('');
                        },
                      )
                    : null,
              ),
            ),
          ),

          // List
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: _filteredStudents.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final student = _filteredStudents[index];

                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: AppColors.shadowCard,
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 22,
                        backgroundColor: AppColors.color1Light.withValues(alpha: 0.5),
                        child: Text(
                          student['name'].toString().substring(0, 1),
                          style: AppTypography.titleMedium.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(student['name'] as String, style: AppTypography.titleSmall),
                            const SizedBox(height: 2),
                            Text(student['regNo'] as String, style: AppTypography.bodySmall),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.info_outline_rounded,
                            color: AppColors.primary, size: 22),
                        onPressed: () => _showStudentProfile(student),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
