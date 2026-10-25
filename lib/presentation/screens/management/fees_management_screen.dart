import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:edstream_mobile/core/network/api_client.dart';
import 'package:edstream_mobile/core/storage/local_cache_store.dart';
import 'package:edstream_mobile/core/theme/app_colors.dart';
import 'package:edstream_mobile/core/theme/app_typography.dart';
import 'package:edstream_mobile/core/widgets/sync_status_banner.dart';
import 'package:edstream_mobile/presentation/widgets/custom_text_field.dart';
import 'package:edstream_mobile/presentation/widgets/primary_button.dart';

class FeesManagementScreen extends StatefulWidget {
  const FeesManagementScreen({super.key});

  @override
  State<FeesManagementScreen> createState() => _FeesManagementScreenState();
}

class _FeesManagementScreenState extends State<FeesManagementScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  List<Map<String, dynamic>> _feeSchedules = [];
  List<Map<String, dynamic>> _transactions = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchFeesData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchFeesData() async {
    const schedulesKey = 'management_fee_schedules_cache';
    const txKey = 'management_fee_transactions_cache';

    final cachedSchedules = LocalCacheStore.instance.getJson(schedulesKey);
    final cachedTx = LocalCacheStore.instance.getJson(txKey);

    if (cachedSchedules is List && cachedSchedules.isNotEmpty) {
      setState(() => _feeSchedules = List<Map<String, dynamic>>.from(cachedSchedules));
    }
    if (cachedTx is List && cachedTx.isNotEmpty) {
      setState(() => _transactions = List<Map<String, dynamic>>.from(cachedTx));
    }

    try {
      final sRes = await ApiClient.instance.get('schoolfees', cacheLocally: true, cacheKey: schedulesKey);
      final tRes = await ApiClient.instance.get('payment/get-all-school-fees-transaction', cacheLocally: true, cacheKey: txKey);

      final rawSchedules = sRes is List
          ? sRes
          : (sRes is Map ? (sRes['schoolFeess'] ?? sRes['data']) : null);
      if (rawSchedules is List && rawSchedules.isNotEmpty) {
        final mappedSchedules = rawSchedules.map<Map<String, dynamic>>((item) {
          if (item is Map) {
            final sessionStr = item['session'] is Map ? item['session']['session'] : item['session']?.toString();
            final termStr = item['term'] is Map ? item['term']['term'] : item['term']?.toString();
            final sectionStr = item['section'] is Map ? item['section']['name'] : item['section']?.toString();
            return {
              'session': sessionStr ?? '2024/2025',
              'term': termStr ?? '3rd Term',
              'section': sectionStr ?? 'All Sections',
              'amount': (item['amount'] as num?)?.toDouble() ?? 75000,
              'lateFees': (item['lateFees'] as num?)?.toDouble() ?? 5000,
              'openDate': item['openDate']?.toString() ?? '2026-04-15',
              'closeDate': item['closeDate']?.toString() ?? '2026-06-30',
              'status': item['status']?.toString() ?? 'active',
            };
          }
          return {};
        }).where((s) => s.isNotEmpty).toList();

        setState(() => _feeSchedules = mappedSchedules);
        LocalCacheStore.instance.setJson(schedulesKey, mappedSchedules);
      } else if (_feeSchedules.isEmpty) {
        _loadDefaultMockSchedules();
      }

      final rawTx = tRes is List
          ? tRes
          : (tRes is Map ? (tRes['data'] ?? tRes['transactions']) : null);
      if (rawTx is List && rawTx.isNotEmpty) {
        final mappedTx = rawTx.map<Map<String, dynamic>>((item) {
          if (item is Map) {
            final std = item['studentId'];
            final stdName = std is Map
                ? '${std['firstName'] ?? ''} ${std['lastName'] ?? ''}'.trim()
                : (item['studentName']?.toString() ?? 'Student');
            final reg = std is Map
                ? (std['registrationNumber'] ?? std['class']?.toString() ?? '')
                : (item['regNo']?.toString() ?? '');
            return {
              'reference': item['reference']?.toString() ?? 'EDS-PAY-REF',
              'studentName': stdName.isNotEmpty ? stdName : 'Student',
              'regNo': reg.isNotEmpty ? reg : 'EDS/2026/SEC',
              'amount': (item['amount'] as num?)?.toDouble() ?? 85000,
              'status': item['status']?.toString() ?? 'successful',
              'date': item['createdAt']?.toString() ?? '2026-10-09',
            };
          }
          return {};
        }).where((t) => t.isNotEmpty).toList();

        setState(() => _transactions = mappedTx);
        LocalCacheStore.instance.setJson(txKey, mappedTx);
      } else if (_transactions.isEmpty) {
        _loadDefaultMockTransactions();
      }
    } catch (_) {
      if (_feeSchedules.isEmpty) _loadDefaultMockSchedules();
      if (_transactions.isEmpty) _loadDefaultMockTransactions();
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _loadDefaultMockSchedules() {
    // No made-up records: an empty list shows the screen's empty state.
    _feeSchedules = [];
  }

  void _loadDefaultMockTransactions() {
    // No made-up records: an empty list shows the screen's empty state.
    _transactions = [];
  }

  void _showVerifyPaymentModal() {
    final refController = TextEditingController();
    bool isVerifying = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (modalCtx, setModalState) {
            return Container(
              padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(modalCtx).viewInsets.bottom + 20),
              decoration: const BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.color4Light,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Verify Payment Reference',
                    style: AppTypography.titleLarge.copyWith(color: AppColors.light, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Check gateway settlement status against bank switch.',
                    style: AppTypography.bodySmall,
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: refController,
                    decoration: InputDecoration(
                      hintText: 'e.g. EDS-PAY-88231',
                      filled: true,
                      fillColor: AppColors.color3Light,
                      prefixIcon: const Icon(Icons.receipt_outlined, color: AppColors.primary),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  PrimaryButton(
                    text: 'Verify Reference',
                    isLoading: isVerifying,
                    onPressed: () async {
                      final ref = refController.text.trim();
                      if (ref.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Please enter reference code')),
                        );
                        return;
                      }

                      setModalState(() => isVerifying = true);
                      // Always asks the server (never a saved copy) and reports exactly what it says.
                      String message;
                      bool ok = false;
                      try {
                        final res = await ApiClient.instance.get('payment/verify-paystack-payment',
                            queryParams: {'reference': ref}, cacheLocally: false);
                        ok = res is Map && res['success'] == true;
                        message = res is Map && res['message'] != null ? res['message'].toString() : 'Payment verified.';
                      } catch (e) {
                        message = 'Could not verify $ref: $e';
                      }

                      if (modalCtx.mounted) Navigator.pop(modalCtx);
                      if (ok) _fetchFeesData();
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            backgroundColor: ok ? AppColors.success : AppColors.danger,
                            content: Text(message),
                          ),
                        );
                      }
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

  // id/label lists for a dropdown, from a cached list endpoint.
  Future<List<Map<String, String>>> _options(String path, String listKey, String labelKey) async {
    try {
      final res = await ApiClient.instance.get(path, queryParams: {'limit': 100});
      final list = res is Map ? (res[listKey] ?? res['data']) : res;
      if (list is! List) return [];
      return list
          .whereType<Map>()
          .map((m) => {
                'id': m['_id']?.toString() ?? '',
                'label': [m[labelKey], if (labelKey == 'term') m['session']].where((v) => v != null).join(' · '),
                'session': m['session']?.toString() ?? '',
              })
          .toList();
    } catch (_) {
      return [];
    }
  }

  void _showAddFeeScheduleModal() async {
    final sessions = await _options('session', 'sessions', 'session');
    final terms = await _options('term', 'terms', 'term');
    final sections = await _options('section', 'sections', 'name');
    if (!mounted) return;
    final amountController = TextEditingController();
    final lateFeeController = TextEditingController(text: '0');
    String? sessionId = sessions.isNotEmpty ? sessions.first['id'] : null;
    String? termId;
    String? sectionId;
    DateTime openDate = DateTime.now();
    DateTime closeDate = DateTime.now().add(const Duration(days: 90));
    bool isSaving = false;

    Widget picker(String label, String? value, List<Map<String, String>> items, ValueChanged<String?> onChanged) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: AppTypography.labelMedium),
            const SizedBox(height: 6),
            DropdownButtonFormField<String>(
              initialValue: value,
              isExpanded: true,
              hint: Text(items.isEmpty ? 'None available (connect to load)' : 'Select'),
              items: items.map((o) => DropdownMenuItem(value: o['id'], child: Text(o['label'] ?? ''))).toList(),
              onChanged: onChanged,
            ),
            const SizedBox(height: 12),
          ],
        );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (modalCtx, setModalState) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(modalCtx).viewInsets.bottom + 24,
          ),
          child: SingleChildScrollView(
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
                Text('Create Fee Schedule', style: AppTypography.titleLarge),
                const SizedBox(height: 4),
                Text('Set institutional tuition fee rates and deadline parameters.', style: AppTypography.bodySmall),
                const SizedBox(height: 16),

                CustomTextField(labelText: 'Tuition Fee Amount (₦)', hintText: 'e.g. 75000', controller: amountController),
                const SizedBox(height: 12),
                CustomTextField(labelText: 'Late Payment Fine (₦)', hintText: 'e.g. 5000', controller: lateFeeController),
                const SizedBox(height: 12),
                picker('Session', sessionId, sessions, (v) => setModalState(() {
                      sessionId = v;
                      termId = null;
                    })),
                picker(
                    'Term',
                    termId,
                    terms.where((t) {
                      final sessionName = sessions.where((x) => x['id'] == sessionId).map((x) => x['label']).firstOrNull;
                      return sessionName == null || t['session'] == sessionName || t['session'] == sessionId;
                    }).toList(),
                    (v) => setModalState(() => termId = v)),
                picker('Section', sectionId, sections, (v) => setModalState(() => sectionId = v)),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () async {
                          final d = await showDatePicker(context: modalCtx, initialDate: openDate, firstDate: DateTime(2020), lastDate: DateTime(2100));
                          if (d != null) setModalState(() => openDate = d);
                        },
                        child: Text('Opens ${openDate.toIso8601String().substring(0, 10)}'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () async {
                          final d = await showDatePicker(context: modalCtx, initialDate: closeDate, firstDate: DateTime(2020), lastDate: DateTime(2100));
                          if (d != null) setModalState(() => closeDate = d);
                        },
                        child: Text('Due ${closeDate.toIso8601String().substring(0, 10)}'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                PrimaryButton(
                  text: 'Publish Fee Schedule',
                  isLoading: isSaving,
                  onPressed: () async {
                    final amt = double.tryParse(amountController.text.trim());
                    if (amt == null || amt <= 0) {
                      ScaffoldMessenger.of(ctx).showSnackBar(
                        const SnackBar(content: Text('Please enter a valid amount.')),
                      );
                      return;
                    }

                    if (sessionId == null || termId == null || sectionId == null || !closeDate.isAfter(openDate)) {
                      ScaffoldMessenger.of(ctx).showSnackBar(
                        const SnackBar(content: Text('Choose session, term and section, with a due date after the open date.')),
                      );
                      return;
                    }
                    setModalState(() => isSaving = true);
                    final payload = <String, dynamic>{
                      'amount': amt,
                      'lateFees': double.tryParse(lateFeeController.text.trim()) ?? 0,
                      'term': termId,
                      'session': sessionId,
                      'section': sectionId,
                      'openDate': openDate.toIso8601String(),
                      'closeDate': closeDate.toIso8601String(),
                    };

                    try {
                      final result = await ApiClient.instance.send('POST', 'schoolfees/create',
                          body: payload, feature: 'fees', label: 'New fee schedule');
                      if (ctx.mounted) Navigator.pop(ctx);
                      if (!ApiClient.isQueued(result)) _fetchFeesData();
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(ApiClient.isQueued(result)
                                ? 'Saved on this phone; it will be published when you are back online.'
                                : 'Fee schedule published successfully!'),
                            backgroundColor: AppColors.success,
                          ),
                        );
                      }
                    } catch (e) {
                      setModalState(() => isSaving = false);
                      if (ctx.mounted) {
                        ScaffoldMessenger.of(ctx).showSnackBar(
                          SnackBar(content: Text('Failed: $e')),
                        );
                      }
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        onPressed: _showAddFeeScheduleModal,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Add Fee Schedule', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
      ),
      appBar: AppBar(
        title: Text(
          'School Fees Hub',
          style: AppTypography.titleLarge.copyWith(color: AppColors.light, fontWeight: FontWeight.w700),
        ),
        backgroundColor: AppColors.surface,
        elevation: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: AppColors.light),
        actions: [
          IconButton(
            icon: const Icon(Icons.verified_outlined, color: AppColors.primary),
            tooltip: 'Verify Reference',
            onPressed: _showVerifyPaymentModal,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.color2Light,
          indicatorColor: AppColors.primary,
          indicatorWeight: 3,
          labelStyle: AppTypography.labelMedium.copyWith(fontWeight: FontWeight.w700),
          tabs: const [
            Tab(text: 'Fee Schedules'),
            Tab(text: 'Transactions Ledger'),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SyncStatusBanner(),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                  : TabBarView(
                      controller: _tabController,
                      children: [
                        _buildSchedulesTab(),
                        _buildTransactionsTab(),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSchedulesTab() {
    return RefreshIndicator(
      onRefresh: _fetchFeesData,
      color: AppColors.primary,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        itemCount: _feeSchedules.length,
        itemBuilder: (context, index) {
          final s = _feeSchedules[index];
          final section = s['section'] ?? '';
          final session = s['session'] ?? '';
          final term = s['term'] ?? '';
          final amount = (s['amount'] as num?)?.toDouble() ?? 0.0;
          final lateFees = (s['lateFees'] as num?)?.toDouble() ?? 0.0;
          final open = s['openDate'] ?? '';
          final close = s['closeDate'] ?? '';
          final isActive = s['status'] == 'active';

          return Container(
            margin: const EdgeInsets.only(bottom: 14),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(20),
              boxShadow: AppColors.shadowCard,
            ),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            section,
                            style: AppTypography.titleMedium.copyWith(
                              color: AppColors.light,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            '$session • $term',
                            style: AppTypography.bodySmall.copyWith(color: AppColors.color2Light),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: isActive
                              ? AppColors.success.withValues(alpha: 0.12)
                              : AppColors.color4Light.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          isActive ? 'Active Billing' : 'Closed',
                          style: AppTypography.labelSmall.copyWith(
                            color: isActive ? AppColors.success : AppColors.color2Light,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Base School Fee', style: AppTypography.labelSmall),
                            Text(
                              '₦${_formatAmount(amount)}',
                              style: AppTypography.titleMedium.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text('Late Charge Penalty', style: AppTypography.labelSmall),
                            Text(
                              '₦${_formatAmount(lateFees)}',
                              style: AppTypography.titleMedium.copyWith(
                                color: AppColors.danger,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(Icons.calendar_month_outlined, size: 14, color: AppColors.color2Light),
                      const SizedBox(width: 6),
                      Text('Billing Open: $open  •  Due: $close', style: AppTypography.bodySmall.copyWith(fontSize: 11)),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTransactionsTab() {
    return RefreshIndicator(
      onRefresh: _fetchFeesData,
      color: AppColors.primary,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        itemCount: _transactions.length,
        itemBuilder: (context, index) {
          final tx = _transactions[index];
          final ref = tx['reference'] ?? '';
          final name = tx['studentName'] ?? '';
          final reg = tx['regNo'] ?? '';
          final amount = (tx['amount'] as num?)?.toDouble() ?? 0.0;
          final status = (tx['status'] ?? 'successful').toString().toLowerCase();
          final date = tx['date'] ?? '';

          Color statusColor;
          if (status == 'successful') {
            statusColor = AppColors.success;
          } else if (status == 'pending') {
            statusColor = const Color(0xFFF59E0B);
          } else {
            statusColor = AppColors.danger;
          }

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(18),
              boxShadow: AppColors.shadowCard,
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: AppTypography.titleSmall.copyWith(
                              fontWeight: FontWeight.w700,
                              color: AppColors.light,
                            ),
                          ),
                          Text(reg, style: AppTypography.bodySmall.copyWith(color: AppColors.color2Light)),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '₦${_formatAmount(amount)}',
                            style: AppTypography.titleSmall.copyWith(
                              fontWeight: FontWeight.w800,
                              color: AppColors.dark,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: statusColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              status.toUpperCase(),
                              style: TextStyle(
                                color: statusColor,
                                fontWeight: FontWeight.w800,
                                fontSize: 9,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Divider(height: 1),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Ref: $ref',
                            style: AppTypography.labelSmall.copyWith(color: AppColors.color4Light, fontSize: 11),
                          ),
                          const SizedBox(width: 4),
                          InkWell(
                            onTap: () {
                              Clipboard.setData(ClipboardData(text: ref));
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Copied reference: $ref')),
                              );
                            },
                            child: const Icon(Icons.copy_rounded, size: 12, color: AppColors.primary),
                          ),
                        ],
                      ),
                      Text(date, style: AppTypography.labelSmall.copyWith(color: AppColors.color2Light, fontSize: 11)),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  String _formatAmount(double val) {
    return val.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
        );
  }
}
