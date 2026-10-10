import 'package:flutter/material.dart';
import 'package:edstream_mobile/core/network/api_client.dart';
import 'package:edstream_mobile/core/network/api_exception.dart';
import 'package:edstream_mobile/core/network/offline_mutation_queue.dart';
import 'package:edstream_mobile/core/network/pending_mutation.dart';
import 'package:edstream_mobile/core/storage/local_cache_store.dart';
import 'package:edstream_mobile/core/theme/app_colors.dart';
import 'package:edstream_mobile/core/theme/app_typography.dart';
import 'package:edstream_mobile/core/widgets/sync_status_banner.dart';
import 'package:edstream_mobile/presentation/widgets/primary_button.dart';

class ScoreSheetScreen extends StatefulWidget {
  const ScoreSheetScreen({
    super.key,
    required this.subjectId,
    required this.subjectName,
    required this.className,
    this.session,
    this.term,
    this.initialNoOfCa,
  });

  final String subjectId;
  final String subjectName;
  final String className;
  final String? session;
  final String? term;
  final int? initialNoOfCa;

  @override
  State<ScoreSheetScreen> createState() => _ScoreSheetScreenState();
}

class _ScoreSheetScreenState extends State<ScoreSheetScreen> {
  bool _isSaving = false;
  bool _isLoadingSettings = false;

  int _noOfCa = 2; // Defaults to 2; dynamically adapts to 2 or 3 based on school settings
  String _session = '2024/2025';
  String _term = '3rd Term';

  String get _formattedSession {
    final s = _session.trim();
    if (s.toLowerCase().contains('session')) return s;
    return '$s Session';
  }

  String get _formattedTerm {
    final t = _term.trim();
    if (t.toLowerCase().contains('term')) return t;
    return '$t Term';
  }

  late List<Map<String, dynamic>> _students;

  @override
  void initState() {
    super.initState();
    _session = widget.session ?? '2024/2025';
    _term = widget.term ?? '3rd Term';
    if (widget.initialNoOfCa != null) {
      _noOfCa = widget.initialNoOfCa!;
    }
    _loadScoreSheet();
    _fetchLiveAssignmentScores();
    _fetchSchoolSettingsAndAcademicPeriod();
  }

  void _loadScoreSheet() {
    // Check cached score sheet first
    final cacheKey = 'scoresheet_${widget.subjectId}';
    final cached = LocalCacheStore.instance.getJson(cacheKey);

    if (cached is List) {
      _students = List<Map<String, dynamic>>.from(cached);
    } else {
      // Default working roster supporting both 2 and 3 CA modes
      _students = [
        {
          'id': 'std-1',
          'name': 'Alex Johnson',
          'regNo': 'EDS/2026/0491',
          'ca1': 16.0,
          'ca2': 18.0,
          'ca3': 14.0,
          'exam': 52.0,
        },
        {
          'id': 'std-2',
          'name': 'Fatima Aliyu',
          'regNo': 'EDS/2026/0492',
          'ca1': 19.0,
          'ca2': 17.5,
          'ca3': 18.0,
          'exam': 56.0,
        },
        {
          'id': 'std-3',
          'name': 'Chinedu Okeke',
          'regNo': 'EDS/2026/0493',
          'ca1': 14.0,
          'ca2': 15.0,
          'ca3': 16.0,
          'exam': 48.0,
        },
        {
          'id': 'std-4',
          'name': 'Zainab Bello',
          'regNo': 'EDS/2026/0494',
          'ca1': 18.0,
          'ca2': 19.0,
          'ca3': 17.0,
          'exam': 58.0,
        },
        {
          'id': 'std-5',
          'name': 'David Adeleke',
          'regNo': 'EDS/2026/0495',
          'ca1': 12.0,
          'ca2': 14.0,
          'ca3': 13.0,
          'exam': 38.0,
        },
      ];
      LocalCacheStore.instance.setJson(cacheKey, _students);
    }
  }

  Future<void> _fetchLiveAssignmentScores() async {
    final cacheKey = 'scoresheet_${widget.subjectId}';
    try {
      final res = await ApiClient.instance.get(
        'result/get-assignment',
        queryParams: {'subjectClass': widget.subjectId},
        cacheLocally: true,
        cacheKey: '${cacheKey}_server',
      );

      if (res is Map && res['data'] is Map) {
        final data = res['data'] as Map;
        final rawStudents = data['students'] as List? ?? [];
        final rawAssignments = data['assignments'] as List? ?? [];

        final List<Map<String, dynamic>> loadedList = [];

        // Build lookup map of existing scores
        final Map<String, Map<String, dynamic>> scoresMap = {};
        for (final item in rawAssignments) {
          if (item is Map) {
            final reg = item['registrationNumber']?.toString();
            final stdId = item['studentId'] is Map
                ? item['studentId']['_id']?.toString()
                : item['studentId']?.toString();
            if (reg != null) scoresMap[reg] = Map<String, dynamic>.from(item);
            if (stdId != null) scoresMap[stdId] = Map<String, dynamic>.from(item);
          }
        }

        if (rawStudents.isNotEmpty) {
          for (final std in rawStudents) {
            if (std is Map) {
              final stdId = std['_id']?.toString() ?? '';
              final reg = std['registrationNumber']?.toString() ?? '';
              final fName = std['firstName'] ?? '';
              final mName = std['middleName'] ?? '';
              final lName = std['lastName'] ?? '';
              final fullName = '$fName $mName $lName'.replaceAll(RegExp(r'\s+'), ' ').trim();

              final score = scoresMap[reg] ?? scoresMap[stdId] ?? {};
              final ca1 = (score['firstCA'] as num?)?.toDouble() ?? 0.0;
              final ca2 = (score['secondCA'] as num?)?.toDouble() ?? 0.0;
              final ca3 = (score['thirdCA'] as num?)?.toDouble() ?? 0.0;
              final exam = (score['exam'] as num?)?.toDouble() ?? 0.0;

              loadedList.add({
                'id': stdId.isNotEmpty ? stdId : reg,
                'name': fullName.isNotEmpty ? fullName : 'Student',
                'regNo': reg,
                'ca1': ca1,
                'ca2': ca2,
                'ca3': ca3,
                'exam': exam,
              });
            }
          }
        } else if (rawAssignments.isNotEmpty) {
          for (final item in rawAssignments) {
            if (item is Map) {
              final stdObj = item['studentId'] as Map? ?? {};
              final stdId = stdObj['_id']?.toString() ?? item['_id']?.toString() ?? '';
              final reg = item['registrationNumber']?.toString() ??
                  stdObj['registrationNumber']?.toString() ??
                  '';
              final fName = stdObj['firstName'] ?? '';
              final mName = stdObj['middleName'] ?? '';
              final lName = stdObj['lastName'] ?? '';
              final fullName = '$fName $mName $lName'.replaceAll(RegExp(r'\s+'), ' ').trim();

              final ca1 = (item['firstCA'] as num?)?.toDouble() ?? 0.0;
              final ca2 = (item['secondCA'] as num?)?.toDouble() ?? 0.0;
              final ca3 = (item['thirdCA'] as num?)?.toDouble() ?? 0.0;
              final exam = (item['exam'] as num?)?.toDouble() ?? 0.0;

              loadedList.add({
                'id': stdId.isNotEmpty ? stdId : reg,
                'name': fullName.isNotEmpty ? fullName : 'Student',
                'regNo': reg,
                'ca1': ca1,
                'ca2': ca2,
                'ca3': ca3,
                'exam': exam,
              });
            }
          }
        }

        if (loadedList.isNotEmpty && mounted) {
          setState(() {
            _students = loadedList;
          });
          LocalCacheStore.instance.setJson(cacheKey, loadedList);
        }
      }
    } catch (_) {}
  }

  Future<void> _fetchSchoolSettingsAndAcademicPeriod() async {
    setState(() => _isLoadingSettings = true);

    // 1. Check local cache first
    final cachedNoOfCa = LocalCacheStore.instance.getInt('school_settings_noOfCa');
    if (cachedNoOfCa != null && widget.initialNoOfCa == null) {
      setState(() => _noOfCa = cachedNoOfCa);
    }
    final cachedSession = LocalCacheStore.instance.getString('current_session');
    final cachedTerm = LocalCacheStore.instance.getString('current_term');
    if (widget.session == null && cachedSession != null) {
      setState(() => _session = cachedSession);
    }
    if (widget.term == null && cachedTerm != null) {
      setState(() => _term = cachedTerm);
    }

    // 2. Fetch fresh School Settings API (/school-settings/)
    try {
      final res = await ApiClient.instance.get('school-settings/', cacheLocally: true);
      if (res is Map && res['data'] is Map) {
        final rawNoOfCa = res['data']['noOfCa'];
        if (rawNoOfCa != null) {
          final parsedNoOfCa = (rawNoOfCa as num).toInt();
          setState(() => _noOfCa = parsedNoOfCa);
          await LocalCacheStore.instance.setInt('school_settings_noOfCa', parsedNoOfCa);
        }
      }
    } catch (_) {
      // 3. Fallback: Check Exam Settings API (/exam-settings)
      try {
        final examRes = await ApiClient.instance.get('exam-settings', cacheLocally: true);
        if (examRes is Map && examRes['data'] is List && examRes['data'].isNotEmpty) {
          final activeSetting = examRes['data'].first;
          if (activeSetting is Map) {
            if (activeSetting['term'] is Map && widget.term == null) {
              final tName = activeSetting['term']['term'] ?? activeSetting['term']['name'];
              if (tName != null) {
                setState(() => _term = tName.toString());
                LocalCacheStore.instance.setString('current_term', tName.toString());
              }
            }
            if (activeSetting['session'] is Map && widget.session == null) {
              final sName = activeSetting['session']['session'];
              if (sName != null) {
                setState(() => _session = sName.toString());
                LocalCacheStore.instance.setString('current_session', sName.toString());
              }
            }
          }
        }
      } catch (_) {}
    }

    // 4. Ensure Academic Period is confirmed from staff/last-term-session
    if (widget.session == null || widget.term == null) {
      try {
        final termRes = await ApiClient.instance.get('staff/last-term-session', cacheLocally: true);
        if (termRes is Map) {
          final tName = termRes['lastTerm']?['name'] ?? termRes['lastTerm']?['term'];
          final sName = termRes['lastSession']?['session'];
          if (tName != null && widget.term == null) {
            setState(() => _term = tName.toString());
            LocalCacheStore.instance.setString('current_term', tName.toString());
          }
          if (sName != null && widget.session == null) {
            setState(() => _session = sName.toString());
            LocalCacheStore.instance.setString('current_session', sName.toString());
          }
        }
      } catch (_) {}
    }

    if (mounted) {
      setState(() => _isLoadingSettings = false);
    }
  }

  double _calculateTotal(Map<String, dynamic> student) {
    final ca1 = (student['ca1'] as num?)?.toDouble() ?? 0.0;
    final ca2 = (student['ca2'] as num?)?.toDouble() ?? 0.0;
    final ca3 = (_noOfCa >= 3) ? ((student['ca3'] as num?)?.toDouble() ?? 0.0) : 0.0;
    final exam = (student['exam'] as num?)?.toDouble() ?? 0.0;
    return ca1 + ca2 + ca3 + exam;
  }

  String _getGrade(double total) {
    if (total >= 70) return 'A';
    if (total >= 60) return 'B';
    if (total >= 50) return 'C';
    if (total >= 45) return 'D';
    if (total >= 40) return 'E';
    return 'F';
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

  Future<void> _saveScoreSheet() async {
    setState(() => _isSaving = true);

    final assignments = _students.map((s) {
      final item = <String, dynamic>{
        'registrationNumber': s['regNo'],
        'firstCA': s['ca1'] ?? 0,
        'secondCA': s['ca2'] ?? 0,
        'exam': s['exam'] ?? 0,
        'term': _term,
        'session': _session,
      };
      if (_noOfCa >= 3) {
        item['thirdCA'] = s['ca3'] ?? 0;
      }
      return item;
    }).toList();

    final payload = {
      'subjectClassId': widget.subjectId,
      'assignments': assignments,
    };

    // Cache locally immediately (Optimistic local save)
    final cacheKey = 'scoresheet_${widget.subjectId}';
    await LocalCacheStore.instance.setJson(cacheKey, _students);

    final path = 'result/add-assignment/${widget.subjectId}';
    try {
      await ApiClient.instance.post(path, body: payload);

      if (!mounted) return;
      setState(() => _isSaving = false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Score Sheet published to server successfully!'),
          backgroundColor: AppColors.success,
        ),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);

      if (e.isNetworkError) {
        // Enqueue offline mutation
        final mutation = PendingMutation(
          localId: OfflineMutationQueue.instance.generateLocalId('scoresheet'),
          feature: 'scoresheet',
          operation: 'saveGrades',
          method: 'POST',
          path: path,
          payload: payload,
          displaySnapshot: {
            'subjectName': widget.subjectName,
            'count': _students.length,
            'session': _session,
            'term': _term,
            'noOfCa': _noOfCa,
          },
          createdAt: DateTime.now(),
        );
        await OfflineMutationQueue.instance.enqueue(mutation);

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Offline: Scores saved locally and queued for cloud sync!'),
            backgroundColor: Color(0xFFD97706),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Saved locally: ${e.message}')),
        );
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Grades saved to local cache.')),
      );
    }
  }

  void _editStudentScore(int index) {
    final student = _students[index];
    final ca1Controller = TextEditingController(text: student['ca1']?.toString() ?? '0');
    final ca2Controller = TextEditingController(text: student['ca2']?.toString() ?? '0');
    final ca3Controller = TextEditingController(text: (student['ca3'] ?? '0').toString());
    final examController = TextEditingController(text: student['exam']?.toString() ?? '0');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (modalContext, setModalState) {
            double currentCa1 = double.tryParse(ca1Controller.text) ?? 0.0;
            double currentCa2 = double.tryParse(ca2Controller.text) ?? 0.0;
            double currentCa3 = (_noOfCa >= 3) ? (double.tryParse(ca3Controller.text) ?? 0.0) : 0.0;
            double currentExam = double.tryParse(examController.text) ?? 0.0;
            double previewTotal = currentCa1 + currentCa2 + currentCa3 + currentExam;
            String previewGrade = _getGrade(previewTotal);
            Color previewGradeColor = _getGradeColor(previewGrade);

            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(student['name'] as String, style: AppTypography.titleLarge),
                            const SizedBox(height: 2),
                            Text(
                              'Reg No: ${student['regNo']} • $_formattedSession ($_formattedTerm)',
                              style: AppTypography.bodySmall.copyWith(color: AppColors.color2Light),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Mode indicator badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.tune_rounded, size: 14, color: AppColors.primary),
                        const SizedBox(width: 6),
                        Text(
                          '$_noOfCa Continuous Assessment Tests Mode',
                          style: AppTypography.labelSmall.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Dynamic CA inputs based on _noOfCa (2 vs 3)
                  if (_noOfCa == 2)
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: ca1Controller,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: const InputDecoration(
                              labelText: '1st CA (20)',
                              hintText: '0 - 20',
                            ),
                            onChanged: (_) => setModalState(() {}),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: ca2Controller,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: const InputDecoration(
                              labelText: '2nd CA (20)',
                              hintText: '0 - 20',
                            ),
                            onChanged: (_) => setModalState(() {}),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: examController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: const InputDecoration(
                              labelText: 'Exam (60)',
                              hintText: '0 - 60',
                            ),
                            onChanged: (_) => setModalState(() {}),
                          ),
                        ),
                      ],
                    )
                  else
                    Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: ca1Controller,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                decoration: const InputDecoration(
                                  labelText: '1st CA (10)',
                                  hintText: '0 - 10',
                                ),
                                onChanged: (_) => setModalState(() {}),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextField(
                                controller: ca2Controller,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                decoration: const InputDecoration(
                                  labelText: '2nd CA (10)',
                                  hintText: '0 - 10',
                                ),
                                onChanged: (_) => setModalState(() {}),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextField(
                                controller: ca3Controller,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                decoration: const InputDecoration(
                                  labelText: '3rd CA (10)',
                                  hintText: '0 - 10',
                                ),
                                onChanged: (_) => setModalState(() {}),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: examController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: const InputDecoration(
                            labelText: 'Terminal Exam (70)',
                            hintText: '0 - 70',
                            prefixIcon: Icon(Icons.school_outlined, size: 20),
                          ),
                          onChanged: (_) => setModalState(() {}),
                        ),
                      ],
                    ),

                  const SizedBox(height: 18),

                  // Real-time Preview Pill
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Calculated Total:', style: AppTypography.titleSmall),
                        Row(
                          children: [
                            Text(
                              '${previewTotal.toStringAsFixed(1)} / 100',
                              style: AppTypography.titleMedium.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: previewGradeColor.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'Grade $previewGrade',
                                style: AppTypography.labelSmall.copyWith(
                                  color: previewGradeColor,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),
                  PrimaryButton(
                    text: 'Update Score',
                    onPressed: () {
                      setState(() {
                        _students[index]['ca1'] = double.tryParse(ca1Controller.text) ?? 0.0;
                        _students[index]['ca2'] = double.tryParse(ca2Controller.text) ?? 0.0;
                        if (_noOfCa >= 3) {
                          _students[index]['ca3'] = double.tryParse(ca3Controller.text) ?? 0.0;
                        }
                        _students[index]['exam'] = double.tryParse(examController.text) ?? 0.0;
                      });
                      Navigator.pop(ctx);
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
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
            Text(widget.subjectName, style: AppTypography.headlineSmall),
            Text(
              '${widget.className} • $_formattedSession • $_formattedTerm',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.color2Light,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          // Switcher toggle for testing or adjusting CA mode manually
          IconButton(
            tooltip: 'Toggle CA Mode (2 vs 3 CAs)',
            icon: Icon(
              _noOfCa == 3 ? Icons.filter_3_rounded : Icons.filter_2_rounded,
              color: AppColors.primary,
            ),
            onPressed: () {
              setState(() {
                _noOfCa = _noOfCa == 2 ? 3 : 2;
              });
              LocalCacheStore.instance.setInt('school_settings_noOfCa', _noOfCa);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Switched to $_noOfCa CA Mode'),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          const SyncStatusBanner(feature: 'scoresheet', itemNoun: 'grade entry'),

          // Prominent Academic Session & Term Header Banner
          Container(
            margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.12)),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.05),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.color3Light,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.calendar_month_rounded,
                              size: 20,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _formattedSession,
                                  style: AppTypography.titleMedium.copyWith(
                                    color: AppColors.light,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: AppColors.primary.withValues(alpha: 0.08),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        _formattedTerm,
                                        style: AppTypography.labelSmall.copyWith(
                                          color: AppColors.primary,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Flexible(
                                      child: Text(
                                        '• Score Sheet',
                                        overflow: TextOverflow.ellipsis,
                                        style: AppTypography.bodySmall.copyWith(
                                          color: AppColors.color2Light,
                                          fontWeight: FontWeight.w500,
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
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: _noOfCa == 3 ? const Color(0xFFFEF3C7) : AppColors.color3Light,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: _isLoadingSettings
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.primary,
                              ),
                            )
                          : Text(
                              '$_noOfCa CAs',
                              style: AppTypography.labelSmall.copyWith(
                                color: _noOfCa == 3 ? const Color(0xFFD97706) : AppColors.primary,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(height: 1),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.people_outline_rounded, size: 15, color: AppColors.color2Light),
                        const SizedBox(width: 5),
                        Text(
                          '${_students.length} Students Enrolled',
                          style: AppTypography.bodySmall.copyWith(color: AppColors.color2Light),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.color3Light,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        _noOfCa == 3
                            ? '3 CAs (30) + Exam (70)'
                            : '2 CAs (40) + Exam (60)',
                        style: AppTypography.labelSmall.copyWith(
                          color: AppColors.color7Light,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Students List
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: _students.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final student = _students[index];
                final total = _calculateTotal(student);
                final grade = _getGrade(total);
                final gradeColor = _getGradeColor(grade);

                return Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(18),
                    onTap: () => _editStudentScore(index),
                    child: Container(
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
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  student['name'] as String,
                                  style: AppTypography.titleMedium.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  student['regNo'] as String,
                                  style: AppTypography.bodySmall,
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: gradeColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              'Grade $grade',
                              style: AppTypography.labelMedium.copyWith(
                                color: gradeColor,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      const Divider(height: 1),
                      const SizedBox(height: 12),

                      // Breakdown Pills Row - Adapts to 2 vs 3 CAs
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildScorePill('CA 1', student['ca1'].toString()),
                          _buildScorePill('CA 2', student['ca2'].toString()),
                          if (_noOfCa >= 3)
                            _buildScorePill('CA 3', (student['ca3'] ?? 0.0).toString()),
                          _buildScorePill('Exam', student['exam'].toString()),
                          _buildScorePill('Total', '${total.toStringAsFixed(1)} / 100', isTotal: true),
                          IconButton(
                            icon: const Icon(Icons.edit_note_rounded, color: AppColors.primary, size: 24),
                            onPressed: () => _editStudentScore(index),
                          ),
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

          // Bottom Publish Button Bar
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -3),
                ),
              ],
            ),
            child: PrimaryButton(
              text: 'Save & Publish Score Sheet',
              isLoading: _isSaving,
              onPressed: _saveScoreSheet,
              icon: const Icon(Icons.cloud_upload_rounded, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScorePill(String label, String value, {bool isTotal = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTypography.labelSmall),
        const SizedBox(height: 2),
        Text(
          value,
          style: AppTypography.bodyMedium.copyWith(
            fontWeight: isTotal ? FontWeight.w700 : FontWeight.w500,
            color: isTotal ? AppColors.primary : AppColors.dark,
          ),
        ),
      ],
    );
  }
}
