import 'package:flutter/material.dart';
import 'package:edstream_mobile/core/network/api_client.dart';
import 'package:edstream_mobile/core/storage/local_cache_store.dart';
import 'package:edstream_mobile/core/theme/app_colors.dart';
import 'package:edstream_mobile/core/theme/app_typography.dart';
import 'package:edstream_mobile/core/widgets/sync_status_banner.dart';
import 'package:edstream_mobile/presentation/screens/common/report_card_view_screen.dart';

class MasterResultsScreen extends StatefulWidget {
  const MasterResultsScreen({super.key});

  @override
  State<MasterResultsScreen> createState() => _MasterResultsScreenState();
}

class _MasterResultsScreenState extends State<MasterResultsScreen> {
  bool _isLoading = true;
  String _searchQuery = '';
  String _selectedClass = 'SS 2 Gold';
  String _selectedTerm = '3rd Term';
  final String _selectedSession = '2024/2025';

  final List<String> _classes = ['SS 2 Gold', 'SS 1 Silver', 'JSS 3 Diamond'];
  final List<String> _terms = ['1st Term', '2nd Term', '3rd Term'];
  List<Map<String, dynamic>> _results = [];

  @override
  void initState() {
    super.initState();
    _fetchMasterResults();
  }

  Future<void> _fetchMasterResults() async {
    const cacheKey = 'master_results_ledger_cache';
    final cached = LocalCacheStore.instance.getJson(cacheKey);
    if (cached is List && cached.isNotEmpty) {
      setState(() {
        _results = List<Map<String, dynamic>>.from(cached);
        _isLoading = false;
      });
    }

    try {
      final res = await ApiClient.instance.get(
        'result/results',
        cacheLocally: true,
        cacheKey: cacheKey,
      );

      if (res is List && res.isNotEmpty) {
        if (mounted) {
          setState(() {
            _results = List<Map<String, dynamic>>.from(res);
            _isLoading = false;
          });
        }
      } else if (res is Map && res['data'] is List && (res['data'] as List).isNotEmpty) {
        if (mounted) {
          setState(() {
            _results = List<Map<String, dynamic>>.from(res['data'] as List);
            _isLoading = false;
          });
        }
      } else if (_results.isEmpty) {
        _loadDefaultMockResults();
      }
    } catch (_) {
      if (_results.isEmpty) {
        _loadDefaultMockResults();
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _loadDefaultMockResults() {
    _results = [
      {
        'studentName': 'Zainab Ahmed Al-Hassan',
        'regNumber': 'EDS/2026/0412',
        'class': 'SS 2 Gold',
        'session': '2024/2025',
        'term': '3rd Term',
        'average': 89.4,
        'position': 1,
        'totalStudents': 42,
        'grade': 'A',
      },
      {
        'studentName': 'Alex Johnson Chukwuma',
        'regNumber': 'EDS/2026/0491',
        'class': 'SS 2 Gold',
        'session': '2024/2025',
        'term': '3rd Term',
        'average': 84.8,
        'position': 2,
        'totalStudents': 42,
        'grade': 'A',
      },
      {
        'studentName': 'Fatima Umar Sadiq',
        'regNumber': 'EDS/2026/0438',
        'class': 'SS 2 Gold',
        'session': '2024/2025',
        'term': '3rd Term',
        'average': 81.2,
        'position': 3,
        'totalStudents': 42,
        'grade': 'A',
      },
      {
        'studentName': 'David Oluwaseun Adeleke',
        'regNumber': 'EDS/2026/0455',
        'class': 'SS 2 Gold',
        'session': '2024/2025',
        'term': '3rd Term',
        'average': 76.5,
        'position': 4,
        'totalStudents': 42,
        'grade': 'B',
      },
      {
        'studentName': 'Maryam Kabir Mohammed',
        'regNumber': 'EDS/2026/0471',
        'class': 'SS 2 Gold',
        'session': '2024/2025',
        'term': '3rd Term',
        'average': 72.0,
        'position': 5,
        'totalStudents': 42,
        'grade': 'B',
      },
      {
        'studentName': 'Emmanuel Kalu Nnadi',
        'regNumber': 'EDS/2026/0488',
        'class': 'SS 2 Gold',
        'session': '2024/2025',
        'term': '3rd Term',
        'average': 68.3,
        'position': 6,
        'totalStudents': 42,
        'grade': 'C',
      },
    ];
  }

  List<Map<String, dynamic>> get _filteredResults {
    return _results.where((r) {
      final matchesSearch = _searchQuery.isEmpty ||
          (r['studentName']?.toString().toLowerCase().contains(_searchQuery.toLowerCase()) ?? false) ||
          (r['regNumber']?.toString().toLowerCase().contains(_searchQuery.toLowerCase()) ?? false);
      return matchesSearch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredResults;
    final totalGraded = filtered.length;
    final avgScore = filtered.isNotEmpty
        ? (filtered.map((e) => (e['average'] as num?)?.toDouble() ?? 0.0).reduce((a, b) => a + b) / totalGraded)
        : 0.0;
    final topScore = filtered.isNotEmpty
        ? (filtered.map((e) => (e['average'] as num?)?.toDouble() ?? 0.0).reduce((a, b) => a > b ? a : b))
        : 0.0;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Master Results Ledger',
          style: AppTypography.titleLarge.copyWith(color: AppColors.light, fontWeight: FontWeight.w700),
        ),
        backgroundColor: AppColors.surface,
        elevation: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: AppColors.light),
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SyncStatusBanner(),
            _buildSearchAndFilters(),
            _buildMetricsHeader(totalGraded, avgScore, topScore),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                  : RefreshIndicator(
                      onRefresh: _fetchMasterResults,
                      color: AppColors.primary,
                      child: filtered.isEmpty
                          ? _buildEmptyState()
                          : ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              itemCount: filtered.length,
                              itemBuilder: (context, index) {
                                return _buildResultCard(filtered[index]);
                              },
                            ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchAndFilters() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      color: AppColors.surface,
      child: Column(
        children: [
          TextField(
            onChanged: (val) => setState(() => _searchQuery = val),
            decoration: InputDecoration(
              hintText: 'Search by student name or registration number...',
              hintStyle: AppTypography.bodySmall.copyWith(color: AppColors.color2Light),
              prefixIcon: const Icon(Icons.search_rounded, color: AppColors.secondary, size: 20),
              filled: true,
              fillColor: AppColors.color3Light,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(24),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: AppColors.color3Light,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedClass,
                      isExpanded: true,
                      icon: const Icon(Icons.arrow_drop_down_rounded, color: AppColors.primary),
                      style: AppTypography.labelSmall.copyWith(color: AppColors.dark, fontWeight: FontWeight.w600),
                      items: _classes.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedClass = val);
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: AppColors.color3Light,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedTerm,
                      isExpanded: true,
                      icon: const Icon(Icons.arrow_drop_down_rounded, color: AppColors.primary),
                      style: AppTypography.labelSmall.copyWith(color: AppColors.dark, fontWeight: FontWeight.w600),
                      items: _terms.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedTerm = val);
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricsHeader(int total, double avg, double top) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: AppColors.bannerGradient,
        borderRadius: BorderRadius.circular(18),
        boxShadow: AppColors.shadowSm,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildHeroMetric('Students', '$total', Icons.groups_rounded),
          Container(width: 1, height: 28, color: Colors.white24),
          _buildHeroMetric('Class Average', '${avg.toStringAsFixed(1)}%', Icons.analytics_rounded),
          Container(width: 1, height: 28, color: Colors.white24),
          _buildHeroMetric('Top Score', '${top.toStringAsFixed(1)}%', Icons.emoji_events_rounded),
        ],
      ),
    );
  }

  Widget _buildHeroMetric(String title, String value, IconData icon) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: Colors.white70),
            const SizedBox(width: 4),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          title,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.8),
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  Widget _buildResultCard(Map<String, dynamic> item) {
    final name = item['studentName'] ?? 'Student';
    final regNo = item['regNumber'] ?? '';
    final avg = (item['average'] as num?)?.toDouble() ?? 0.0;
    final pos = item['position'] as int?;
    final totalStudents = (item['totalStudents'] as num?)?.toInt() ?? 42;
    final grade = item['grade'] ?? 'A';

    final isTop3 = pos != null && pos <= 3;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: AppColors.shadowCard,
        border: isTop3
            ? Border.all(color: AppColors.warning.withValues(alpha: 0.6), width: 1.2)
            : Border.all(color: AppColors.color3Light),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                // Position badge or avatar
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: isTop3
                        ? const Color(0xFFFEF3C7)
                        : AppColors.primary.withValues(alpha: 0.08),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      pos != null ? '$pos${_getOrdinal(pos)}' : '-',
                      style: AppTypography.titleSmall.copyWith(
                        color: isTop3 ? const Color(0xFFB45309) : AppColors.primary,
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: AppTypography.titleSmall.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.light,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        regNo,
                        style: AppTypography.bodySmall.copyWith(color: AppColors.color2Light),
                      ),
                    ],
                  ),
                ),
                // Terminal Average
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${avg.toStringAsFixed(1)}%',
                      style: AppTypography.titleMedium.copyWith(
                        color: avg >= 75 ? AppColors.success : AppColors.primary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: avg >= 75
                            ? AppColors.success.withValues(alpha: 0.12)
                            : AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'Grade $grade',
                        style: AppTypography.labelSmall.copyWith(
                          color: avg >= 75 ? AppColors.success : AppColors.primary,
                          fontWeight: FontWeight.w700,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 8),

            // Action: View Official Report Card
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Class: $_selectedClass',
                  style: AppTypography.labelSmall.copyWith(color: AppColors.color2Light),
                ),
                InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ReportCardViewScreen(
                          studentName: name,
                          regNumber: regNo,
                          className: _selectedClass,
                          session: _selectedSession,
                          term: _selectedTerm,
                          average: avg,
                          position: pos,
                          totalStudents: totalStudents,
                        ),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.visibility_rounded, size: 16, color: AppColors.secondary),
                        const SizedBox(width: 4),
                        Text(
                          'View Report Card',
                          style: AppTypography.labelMedium.copyWith(
                            color: AppColors.secondary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _getOrdinal(int n) {
    if (n >= 11 && n <= 13) return 'th';
    switch (n % 10) {
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

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off_rounded, size: 64, color: AppColors.color2Light),
          const SizedBox(height: 12),
          Text('No Student Results Found', style: AppTypography.titleMedium),
          const SizedBox(height: 4),
          Text(
            'Try adjusting your search query or filters.',
            style: AppTypography.bodySmall,
          ),
        ],
      ),
    );
  }
}
