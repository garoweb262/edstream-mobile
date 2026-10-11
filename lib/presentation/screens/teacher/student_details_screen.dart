import 'package:flutter/material.dart';
import 'package:edstream_mobile/core/network/api_client.dart';
import 'package:edstream_mobile/core/storage/local_cache_store.dart';
import 'package:edstream_mobile/core/theme/app_colors.dart';
import 'package:edstream_mobile/core/theme/app_typography.dart';
import 'package:edstream_mobile/core/widgets/sync_status_banner.dart';

class StudentDetailsScreen extends StatefulWidget {
  const StudentDetailsScreen({
    super.key,
    required this.studentId,
    this.initialStudentData,
  });

  final String studentId;
  final Map<String, dynamic>? initialStudentData;

  @override
  State<StudentDetailsScreen> createState() => _StudentDetailsScreenState();
}

class _StudentDetailsScreenState extends State<StudentDetailsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoadingStudent = true;
  bool _isLoadingResults = false;
  bool _isLoadingHistory = false;

  Map<String, dynamic>? _student;
  List<Map<String, dynamic>> _results = [];
  Map<String, dynamic>? _transferHistoryData;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    if (widget.initialStudentData != null) {
      _student = Map<String, dynamic>.from(widget.initialStudentData!);
      _isLoadingStudent = false;
    }
    _fetchStudentDetails();
    _fetchStudentResults();
    _fetchTransferHistory();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchStudentDetails() async {
    final cacheKey = 'student_details_${widget.studentId}';
    final cached = LocalCacheStore.instance.getJson(cacheKey);
    if (cached is Map<String, dynamic> && _student == null) {
      setState(() {
        _student = cached;
        _isLoadingStudent = false;
      });
    }

    try {
      final res = await ApiClient.instance.get(
        'student',
        queryParams: {'_id': widget.studentId},
        cacheLocally: true,
        cacheKey: cacheKey,
      );

      if (res is Map) {
        if (res['students'] is List && (res['students'] as List).isNotEmpty) {
          setState(() {
            _student = Map<String, dynamic>.from(res['students'][0]);
            _isLoadingStudent = false;
          });
          LocalCacheStore.instance.setJson(cacheKey, _student!);
        } else if (res['data'] is Map) {
          setState(() {
            _student = Map<String, dynamic>.from(res['data']);
            _isLoadingStudent = false;
          });
          LocalCacheStore.instance.setJson(cacheKey, _student!);
        }
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingStudent = false);
    }
  }

  Future<void> _fetchStudentResults() async {
    setState(() => _isLoadingResults = true);
    final cacheKey = 'student_results_${widget.studentId}';
    final cached = LocalCacheStore.instance.getJson(cacheKey);
    if (cached is List) {
      _results = List<Map<String, dynamic>>.from(cached);
    }

    try {
      final res = await ApiClient.instance.get(
        'result/results',
        queryParams: {
          'studentId': widget.studentId,
          'limit': 20,
          'page': 1,
        },
        cacheLocally: true,
        cacheKey: cacheKey,
      );

      if (res is Map && res['data'] is List) {
        final List<Map<String, dynamic>> flattened = [];
        for (var sectionItem in res['data']) {
          if (sectionItem is Map && sectionItem['classes'] is List) {
            for (var classItem in sectionItem['classes']) {
              if (classItem is Map && classItem['results'] is List) {
                for (var r in classItem['results']) {
                  if (r is Map) flattened.add(Map<String, dynamic>.from(r));
                }
              }
            }
          } else if (sectionItem is Map) {
            flattened.add(Map<String, dynamic>.from(sectionItem));
          }
        }
        setState(() {
          _results = flattened;
          _isLoadingResults = false;
        });
        LocalCacheStore.instance.setJson(cacheKey, _results);
      } else {
        setState(() => _isLoadingResults = false);
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingResults = false);
    }
  }

  Future<void> _fetchTransferHistory() async {
    setState(() => _isLoadingHistory = true);
    final cacheKey = 'student_transfer_${widget.studentId}';

    try {
      final res = await ApiClient.instance.get(
        'student/${widget.studentId}/transfer-history',
        cacheLocally: true,
        cacheKey: cacheKey,
      );

      if (res is Map && res['data'] is Map) {
        setState(() {
          _transferHistoryData = Map<String, dynamic>.from(res['data']);
          _isLoadingHistory = false;
        });
      } else {
        setState(() => _isLoadingHistory = false);
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingHistory = false);
    }
  }

  List<dynamic> get _enrollments {
    if (_student != null && _student!['enrollments'] is List) {
      return _student!['enrollments'] as List;
    }
    return [];
  }

  bool get _hasDoubleEnrollment => _enrollments.length > 1;

  String _formatDate(dynamic dateVal) {
    if (dateVal == null) return 'N/A';
    try {
      final dt = DateTime.parse(dateVal.toString());
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (_) {
      return dateVal.toString();
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
    final firstName = _student?['firstName'] ?? '';
    final middleName = _student?['middleName'] ?? '';
    final lastName = _student?['lastName'] ?? '';
    final fullName = '$firstName $middleName $lastName'.trim().isEmpty
        ? (_student?['name'] ?? 'Student Details')
        : '$firstName $middleName $lastName'.trim();
    final regNo = _student?['registrationNumber'] ?? _student?['regNo'] ?? 'N/A';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(fullName, style: AppTypography.headlineSmall),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          indicatorWeight: 3,
          labelStyle: AppTypography.labelMedium.copyWith(fontWeight: FontWeight.w700),
          tabs: const [
            Tab(text: 'Profile Info'),
            Tab(text: 'Enrollments'),
            Tab(text: 'Term Results'),
            Tab(text: 'History & Classes'),
            Tab(text: 'Next of Kin'),
          ],
        ),
      ),
      body: Column(
        children: [
          const SyncStatusBanner(itemNoun: 'student record'),
          // Double Enrollment Alert Banner
          if (_hasDoubleEnrollment)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFF59E0B), width: 1.5),
                boxShadow: AppColors.shadowSm,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.warning_amber_rounded,
                    color: Color(0xFFD97706),
                    size: 26,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Double Enrollment Detected',
                          style: AppTypography.titleSmall.copyWith(
                            color: const Color(0xFF92400E),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'This student is actively enrolled in ${_enrollments.length} sections simultaneously. Verify primary section assignment in the Enrollments tab.',
                          style: AppTypography.bodySmall.copyWith(
                            color: const Color(0xFFB45309),
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: _isLoadingStudent && _student == null
                ? const Center(child: CircularProgressIndicator())
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildInfoTab(regNo),
                      _buildEnrollmentsTab(),
                      _buildResultsTab(),
                      _buildHistoryTab(),
                      _buildNextOfKinTab(),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  // 1. INFO TAB
  Widget _buildInfoTab(String regNo) {
    final s = _student ?? {};
    final className = s['class'] is Map
        ? '${s['class']['code'] ?? ''} ${s['class']['subclass'] ?? ''}'.trim()
        : (s['class']?.toString() ?? 'N/A');
    final sectionName = s['section'] is Map
        ? (s['section']['name'] ?? 'N/A')
        : (s['section']?.toString() ?? 'N/A');

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Profile Header Card
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: AppColors.heroCardGradient,
              borderRadius: BorderRadius.circular(20),
              boxShadow: AppColors.shadowMd,
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 34,
                  backgroundColor: Colors.white24,
                  child: Text(
                    (s['firstName']?.toString().isNotEmpty == true)
                        ? s['firstName'].toString()[0].toUpperCase()
                        : 'S',
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${s['firstName'] ?? ''} ${s['lastName'] ?? ''}'.trim(),
                        style: AppTypography.titleLarge.copyWith(color: Colors.white),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        regNo,
                        style: AppTypography.bodyMedium.copyWith(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.white24,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '$className • $sectionName',
                          style: AppTypography.labelSmall.copyWith(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // Information Details Card
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: AppColors.shadowSm,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Personal & Academic Profile', style: AppTypography.titleMedium),
                const Divider(height: 24),
                _buildInfoRow('First Name', s['firstName']?.toString() ?? 'N/A'),
                _buildInfoRow('Middle Name', s['middleName']?.toString() ?? 'N/A'),
                _buildInfoRow('Last Name', s['lastName']?.toString() ?? 'N/A'),
                _buildInfoRow('Registration No.', regNo),
                _buildInfoRow('Class', className),
                _buildInfoRow('Section', sectionName),
                _buildInfoRow('Gender', s['gender']?.toString().toUpperCase() ?? 'N/A'),
                _buildInfoRow('Email Address', s['email']?.toString() ?? 'N/A'),
                _buildInfoRow('Phone Number', s['phoneNumber']?.toString() ?? 'N/A'),
                _buildInfoRow('City / LGA', s['city']?.toString() ?? 'N/A'),
                _buildInfoRow('State of Origin', s['state']?.toString() ?? 'N/A'),
                _buildInfoRow('Residential Address', s['address']?.toString() ?? 'N/A'),
                _buildInfoRow('Enrolled On', _formatDate(s['createdAt'])),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 2. ENROLLMENTS TAB
  Widget _buildEnrollmentsTab() {
    if (_enrollments.isEmpty) {
      return const Center(
        child: Text('No enrollment records found for this student.'),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _enrollments.length,
      separatorBuilder: (context, index) => const SizedBox(height: 14),
      itemBuilder: (context, index) {
        final en = _enrollments[index] as Map<String, dynamic>;
        final isPrimary = en['isPrimary'] == true;
        final sectionName = en['section'] is Map ? en['section']['name'] : 'N/A';
        final classCode = en['class'] is Map
            ? '${en['class']['code'] ?? ''} ${en['class']['subclass'] ?? ''}'.trim()
            : (en['class']?.toString() ?? 'N/A');
        final sessionName = en['session'] is Map ? en['session']['name'] : 'N/A';
        final status = en['status']?.toString().toUpperCase() ?? 'ACTIVE';

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isPrimary ? const Color(0xFFEFF6FF) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isPrimary ? AppColors.primary.withValues(alpha: 0.3) : AppColors.cardBorder,
              width: isPrimary ? 1.5 : 1.0,
            ),
            boxShadow: AppColors.shadowSm,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: (isPrimary ? AppColors.primary : AppColors.secondary)
                              .withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Icons.school_rounded,
                          size: 20,
                          color: isPrimary ? AppColors.primary : AppColors.secondary,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Enrollment #${index + 1}',
                        style: AppTypography.titleMedium,
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      if (isPrimary)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          margin: const EdgeInsets.only(right: 6),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            'PRIMARY',
                            style: AppTypography.labelSmall.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: status == 'ACTIVE'
                              ? AppColors.success.withValues(alpha: 0.15)
                              : Colors.grey.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          status,
                          style: AppTypography.labelSmall.copyWith(
                            color: status == 'ACTIVE' ? AppColors.success : Colors.grey[700],
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const Divider(height: 20),
              _buildInfoRow('Section', sectionName.toString()),
              _buildInfoRow('Class', classCode.toString()),
              _buildInfoRow('Session', sessionName.toString()),
              _buildInfoRow('Start Date', _formatDate(en['startDate'])),
              if (en['endDate'] != null)
                _buildInfoRow('End Date', _formatDate(en['endDate'])),
              if (en['notes'] != null && en['notes'].toString().isNotEmpty)
                _buildInfoRow('Notes', en['notes'].toString()),
            ],
          ),
        );
      },
    );
  }

  // 3. RESULTS TAB
  Widget _buildResultsTab() {
    if (_isLoadingResults) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_results.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.assignment_turned_in_outlined, size: 48, color: Colors.grey),
            const SizedBox(height: 12),
            Text('No term results published yet', style: AppTypography.titleMedium),
            const SizedBox(height: 4),
            Text(
              'Terminal report sheets will appear here once computed.',
              style: AppTypography.bodySmall,
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _results.length,
      separatorBuilder: (context, index) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final r = _results[index];
        final ref = r['resultReference'] ?? 'REF-#$index';
        final session = r['session'] is Map ? (r['session']['session'] ?? 'Session') : 'Session';
        final term = r['term'] is Map ? (r['term']['term'] ?? 'Term') : 'Term';
        final academic = r['academicInfo'] as Map<String, dynamic>? ?? {};
        final avg = (academic['average'] as num?)?.toDouble() ?? 0.0;
        final pos = (academic['position'] as num?)?.toInt() ?? 0;
        final subjects = r['subjects'] is List ? (r['subjects'] as List) : [];

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: AppColors.shadowSm,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('$term • $session', style: AppTypography.titleMedium),
                      Text(ref.toString(), style: AppTypography.bodySmall),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      pos > 0 ? '$pos${_positionSuffix(pos)} Position' : 'Position N/A',
                      style: AppTypography.labelMedium.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const Divider(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildSummaryPill('Average', '${avg.toStringAsFixed(1)}%'),
                  _buildSummaryPill('Total Marks', '${academic['totalMarks'] ?? 0}'),
                  _buildSummaryPill('Subjects', '${academic['numberOfSubjects'] ?? subjects.length}'),
                ],
              ),
              if (subjects.isNotEmpty) ...[
                const SizedBox(height: 14),
                Text('Subject Scores', style: AppTypography.titleSmall),
                const SizedBox(height: 8),
                ...subjects.map((sub) {
                  final s = sub as Map<String, dynamic>;
                  final sName = s['subjectName'] ?? s['subject'] ?? 'Subject';
                  final total = s['totalScore'] ?? s['total'] ?? 0;
                  final grade = s['grade'] ?? '-';
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(sName.toString(), style: AppTypography.bodyMedium),
                        ),
                        Text(
                          '$total pts ($grade)',
                          style: AppTypography.labelMedium.copyWith(
                            fontWeight: FontWeight.w700,
                            color: grade == 'A' ? AppColors.success : AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ],
          ),
        );
      },
    );
  }

  // 4. HISTORY TAB (Classes Attended & Branch Transfer History)
  Widget _buildHistoryTab() {
    final s = _student ?? {};
    final classesAttended = s['classesAttended'] is List ? (s['classesAttended'] as List) : [];
    final transfers = _transferHistoryData?['transferHistory'] is List
        ? (_transferHistoryData!['transferHistory'] as List)
        : [];
    final currentBranch = _transferHistoryData?['currentBranch'] as Map<String, dynamic>?;

    if (_isLoadingHistory && _transferHistoryData == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Current Branch info
          if (currentBranch != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFBFDBFE)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.business_rounded, color: AppColors.primary, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Current School Branch', style: AppTypography.labelSmall),
                        Text(
                          '${currentBranch['branchName'] ?? 'Main'} (${currentBranch['branchCode'] ?? 'MAIN'})',
                          style: AppTypography.titleSmall.copyWith(color: AppColors.primary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

          // Classes Attended History
          Text('Classes Attended', style: AppTypography.titleMedium),
          const SizedBox(height: 10),
          if (classesAttended.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Text('No prior class attendance records found.'),
            )
          else
            ...classesAttended.map((c) {
              final cMap = c as Map<String, dynamic>;
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: AppColors.shadowSm,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.grade_rounded, color: AppColors.secondary, size: 20),
                        const SizedBox(width: 10),
                        Text(
                          cMap['code']?.toString() ?? 'Class Code',
                          style: AppTypography.titleSmall,
                        ),
                      ],
                    ),
                    Text(
                      _formatDate(cMap['date']),
                      style: AppTypography.bodySmall,
                    ),
                  ],
                ),
              );
            }),

          const SizedBox(height: 20),
          // Branch Transfer History
          Text('Branch Transfer History', style: AppTypography.titleMedium),
          const SizedBox(height: 10),
          if (transfers.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Text('No transfer history recorded for this student.'),
            )
          else
            ...transfers.map((t) {
              final tMap = t as Map<String, dynamic>;
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: AppColors.shadowSm,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Branch Transfer',
                          style: AppTypography.titleSmall.copyWith(color: AppColors.primary),
                        ),
                        Text(
                          _formatDate(tMap['transferredAt'] ?? tMap['effectiveDate']),
                          style: AppTypography.bodySmall,
                        ),
                      ],
                    ),
                    const Divider(height: 16),
                    _buildInfoRow('From Branch', tMap['fromBranchId']?.toString() ?? 'N/A'),
                    _buildInfoRow('To Branch', tMap['toBranchId']?.toString() ?? 'N/A'),
                    _buildInfoRow('Reason', tMap['reason']?.toString() ?? 'N/A'),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  // 5. NEXT OF KIN TAB
  Widget _buildNextOfKinTab() {
    final nok = _student?['nextOfKin'] as Map<String, dynamic>? ?? {};

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: AppColors.shadowSm,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.family_restroom_rounded, color: AppColors.primary, size: 24),
                const SizedBox(width: 10),
                Text('Next of Kin & Guardian Details', style: AppTypography.titleMedium),
              ],
            ),
            const Divider(height: 24),
            _buildInfoRow('Full Name', nok['fullName']?.toString() ?? 'N/A'),
            _buildInfoRow('Relationship', nok['relationship']?.toString() ?? 'N/A'),
            _buildInfoRow('Phone Number', nok['phoneNumber']?.toString() ?? 'N/A'),
            _buildInfoRow('Email Address', nok['email']?.toString() ?? 'N/A'),
            _buildInfoRow('Home Address', nok['address']?.toString() ?? 'N/A'),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryPill(String label, String value) {
    return Column(
      children: [
        Text(value, style: AppTypography.titleMedium.copyWith(color: AppColors.primary)),
        const SizedBox(height: 2),
        Text(label, style: AppTypography.bodySmall),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
