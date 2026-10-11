import 'package:flutter/material.dart';
import 'package:edstream_mobile/core/network/api_client.dart';
import 'package:edstream_mobile/core/storage/local_cache_store.dart';
import 'package:edstream_mobile/core/theme/app_colors.dart';
import 'package:edstream_mobile/core/theme/app_typography.dart';
import 'package:edstream_mobile/core/widgets/sync_status_banner.dart';
import 'package:edstream_mobile/presentation/widgets/custom_text_field.dart';
import 'package:edstream_mobile/presentation/widgets/primary_button.dart';

class AcademicCalendarScreen extends StatefulWidget {
  const AcademicCalendarScreen({super.key});

  @override
  State<AcademicCalendarScreen> createState() => _AcademicCalendarScreenState();
}

class _AcademicCalendarScreenState extends State<AcademicCalendarScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;

  List<Map<String, dynamic>> _sessions = [];
  List<Map<String, dynamic>> _terms = [];
  String _activeSessionName = '2024/2025';
  String _activeTermName = '3rd Term';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadCalendarData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadCalendarData() async {
    const sessionKey = 'management_sessions_cache';
    const termKey = 'management_terms_cache';

    final cachedSessions = LocalCacheStore.instance.getJson(sessionKey);
    final cachedTerms = LocalCacheStore.instance.getJson(termKey);

    if (cachedSessions is List) setState(() => _sessions = List<Map<String, dynamic>>.from(cachedSessions));
    if (cachedTerms is List) setState(() => _terms = List<Map<String, dynamic>>.from(cachedTerms));

    try {
      final sRes = await ApiClient.instance.get('session', cacheLocally: true, cacheKey: sessionKey);
      final tRes = await ApiClient.instance.get('term', cacheLocally: true, cacheKey: termKey);
      final activeRes = await ApiClient.instance.get('staff/last-term-session', cacheLocally: true);

      if (activeRes is Map) {
        final lastS = activeRes['lastSession'];
        final lastT = activeRes['lastTerm'];
        if (lastS != null && lastS['session'] != null) {
          _activeSessionName = lastS['session'].toString();
        }
        if (lastT != null && (lastT['name'] != null || lastT['term'] != null)) {
          _activeTermName = (lastT['name'] ?? lastT['term']).toString();
        }
      }

      final rawSessions = sRes is List ? sRes : (sRes is Map ? (sRes['sessions'] ?? sRes['data']) : null);
      if (rawSessions is List) {
        final parsed = List<Map<String, dynamic>>.from(rawSessions.whereType<Map>());
        setState(() => _sessions = parsed);
        LocalCacheStore.instance.setJson(sessionKey, parsed);
      }

      final rawTerms = tRes is List ? tRes : (tRes is Map ? (tRes['terms'] ?? tRes['data']) : null);
      if (rawTerms is List) {
        final parsed = List<Map<String, dynamic>>.from(rawTerms.whereType<Map>());
        setState(() => _terms = parsed);
        LocalCacheStore.instance.setJson(termKey, parsed);
      }
    } catch (_) {
      if (_sessions.isEmpty) _loadMockCalendar();
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _loadMockCalendar() {
    _sessions = [
      {'_id': 'ses-1', 'session': '2024/2025', 'status': 'active'},
      {'_id': 'ses-2', 'session': '2023/2024', 'status': 'completed'},
      {'_id': 'ses-3', 'session': '2022/2023', 'status': 'completed'},
    ];
    _terms = [
      {'_id': 't-1', 'term': '1st Term', 'name': '1st Term', 'status': 'completed'},
      {'_id': 't-2', 'term': '2nd Term', 'name': '2nd Term', 'status': 'completed'},
      {'_id': 't-3', 'term': '3rd Term', 'name': '3rd Term', 'status': 'active'},
    ];
  }

  void _showAddSessionModal() {
    final sessionController = TextEditingController();
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 48,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text('Create Academic Session', style: AppTypography.titleLarge),
              const SizedBox(height: 4),
              Text('Example: 2025/2026', style: AppTypography.bodySmall),
              const SizedBox(height: 16),
              CustomTextField(labelText: 'Academic Session', hintText: 'YYYY/YYYY', controller: sessionController),
              const SizedBox(height: 24),
              PrimaryButton(
                text: 'Create Session',
                isLoading: isSaving,
                onPressed: () async {
                  if (sessionController.text.trim().isEmpty) return;
                  setModalState(() => isSaving = true);
                  try {
                    await ApiClient.instance.post('session/create', body: {
                      'session': sessionController.text.trim(),
                    });
                    if (ctx.mounted) Navigator.pop(ctx);
                    _loadCalendarData();
                  } catch (e) {
                    setModalState(() => isSaving = false);
                    if (ctx.mounted) {
                      ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text('Error: $e')));
                    }
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddTermModal() {
    final termNameController = TextEditingController();
    String? selectedSessionId = _sessions.isNotEmpty ? _sessions.first['_id']?.toString() : null;
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 48,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text('Create Academic Term', style: AppTypography.titleLarge),
              const SizedBox(height: 16),
              CustomTextField(labelText: 'Term Name', hintText: 'e.g. 1st Term, Summer Term', controller: termNameController),
              const SizedBox(height: 12),
              Text('Session', style: AppTypography.labelMedium),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: DropdownButton<String>(
                  isExpanded: true,
                  underline: const SizedBox(),
                  value: selectedSessionId,
                  items: _sessions.map((ses) {
                    return DropdownMenuItem<String>(
                      value: ses['_id']?.toString(),
                      child: Text(ses['session'] ?? 'Session'),
                    );
                  }).toList(),
                  onChanged: (val) => setModalState(() => selectedSessionId = val),
                ),
              ),
              const SizedBox(height: 24),
              PrimaryButton(
                text: 'Create Term',
                isLoading: isSaving,
                onPressed: () async {
                  if (termNameController.text.trim().isEmpty) return;
                  setModalState(() => isSaving = true);
                  try {
                    await ApiClient.instance.post('term', body: {
                      'name': termNameController.text.trim(),
                      'term': termNameController.text.trim(),
                      'session': selectedSessionId,
                    });
                    if (ctx.mounted) Navigator.pop(ctx);
                    _loadCalendarData();
                  } catch (e) {
                    setModalState(() => isSaving = false);
                    if (ctx.mounted) {
                      ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text('Error: $e')));
                    }
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Academic Calendar',
          style: AppTypography.titleLarge.copyWith(color: AppColors.light, fontWeight: FontWeight.w700),
        ),
        backgroundColor: AppColors.surface,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.light),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.color2Light,
          indicatorColor: AppColors.primary,
          indicatorWeight: 3,
          labelStyle: AppTypography.labelMedium.copyWith(fontWeight: FontWeight.w700),
          tabs: const [
            Tab(text: 'Sessions'),
            Tab(text: 'Terms'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        onPressed: () {
          if (_tabController.index == 0) _showAddSessionModal();
          if (_tabController.index == 1) _showAddTermModal();
        },
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SyncStatusBanner(),

            // Active Banner
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0012BF), Color(0xFF4D44B5)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(18),
                boxShadow: AppColors.shadowSm,
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.calendar_month, color: Colors.white),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('CURRENT ACADEMIC PERIOD', style: AppTypography.labelSmall.copyWith(color: Colors.white70)),
                        const SizedBox(height: 2),
                        Text(
                          '$_activeTermName • $_activeSessionName',
                          style: AppTypography.titleMedium.copyWith(color: Colors.white, fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.shade400,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text('LIVE', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800)),
                  ),
                ],
              ),
            ),

            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                  : TabBarView(
                      controller: _tabController,
                      children: [
                        _buildSessionsTab(),
                        _buildTermsTab(),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSessionsTab() {
    return RefreshIndicator(
      onRefresh: _loadCalendarData,
      color: AppColors.primary,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _sessions.length,
        itemBuilder: (context, index) {
          final s = _sessions[index];
          final name = s['session'] ?? 'Session';
          final isActive = name == _activeSessionName || s['status'] == 'active';

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: AppColors.shadowSm,
            ),
            child: Row(
              children: [
                Icon(
                  Icons.event_available,
                  color: isActive ? AppColors.primary : Colors.grey,
                  size: 28,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(name.toString(), style: AppTypography.titleMedium),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isActive ? Colors.green.shade50 : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    isActive ? 'Current Session' : 'Completed',
                    style: TextStyle(
                      color: isActive ? Colors.green.shade800 : Colors.grey.shade600,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildTermsTab() {
    return RefreshIndicator(
      onRefresh: _loadCalendarData,
      color: AppColors.primary,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _terms.length,
        itemBuilder: (context, index) {
          final t = _terms[index];
          final name = t['name'] ?? t['term'] ?? 'Term';
          final isActive = name == _activeTermName || t['status'] == 'active';

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: AppColors.shadowSm,
            ),
            child: Row(
              children: [
                Icon(
                  Icons.timelapse,
                  color: isActive ? AppColors.secondary : Colors.grey,
                  size: 28,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(name.toString(), style: AppTypography.titleMedium),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isActive ? Colors.green.shade50 : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    isActive ? 'Active Term' : 'Concluded',
                    style: TextStyle(
                      color: isActive ? Colors.green.shade800 : Colors.grey.shade600,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
