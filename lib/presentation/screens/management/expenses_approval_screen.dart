import 'package:flutter/material.dart';
import 'package:edstream_mobile/core/network/api_client.dart';
import 'package:edstream_mobile/core/storage/local_cache_store.dart';
import 'package:edstream_mobile/core/theme/app_colors.dart';
import 'package:edstream_mobile/core/theme/app_typography.dart';
import 'package:edstream_mobile/core/widgets/sync_status_banner.dart';
import 'package:edstream_mobile/presentation/widgets/primary_button.dart';

class ExpensesApprovalScreen extends StatefulWidget {
  const ExpensesApprovalScreen({super.key});

  @override
  State<ExpensesApprovalScreen> createState() => _ExpensesApprovalScreenState();
}

class _ExpensesApprovalScreenState extends State<ExpensesApprovalScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  List<Map<String, dynamic>> _expenses = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _fetchExpenses();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchExpenses() async {
    const cacheKey = 'management_expenses_cache';
    final cached = LocalCacheStore.instance.getJson(cacheKey);
    if (cached is List && cached.isNotEmpty) {
      setState(() {
        _expenses = List<Map<String, dynamic>>.from(cached);
        _isLoading = false;
      });
    }

    try {
      final res = await ApiClient.instance.get(
        'expenses',
        cacheLocally: true,
        cacheKey: cacheKey,
      );

      final rawList = res is List
          ? res
          : (res is Map ? (res['expenses'] ?? res['data']) : null);

      if (rawList is List && rawList.isNotEmpty) {
        final mapped = rawList.map<Map<String, dynamic>>((e) {
          if (e is Map) {
            final amt = (e['amountSpent'] as num?)?.toDouble() ??
                (e['amount'] as num?)?.toDouble() ??
                0.0;
            return {
              ...Map<String, dynamic>.from(e),
              'amount': amt,
              'reason': e['reason'] ?? '',
              'status': e['status'] ?? 'pending',
            };
          }
          return {};
        }).where((e) => e.isNotEmpty).toList();

        if (mounted) {
          setState(() {
            _expenses = mapped;
            _isLoading = false;
          });
        }
        LocalCacheStore.instance.setJson(cacheKey, mapped);
      } else if (_expenses.isEmpty) {
        _loadDefaultMockExpenses();
      }
    } catch (_) {
      if (_expenses.isEmpty) {
        _loadDefaultMockExpenses();
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _loadDefaultMockExpenses() {
    // No made-up records: an empty list shows the screen's empty state.
    _expenses = [];
  }

  List<Map<String, dynamic>> _getFilteredList(String status) {
    if (status == 'all') return _expenses;
    return _expenses.where((e) => (e['status'] ?? '').toString().toLowerCase() == status).toList();
  }

  void _showApprovalBottomSheet(Map<String, dynamic> item, bool isApprove) {
    final noteController = TextEditingController();
    bool isSubmitting = false;

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
                  Row(
                    children: [
                      Icon(
                        isApprove ? Icons.check_circle_rounded : Icons.cancel_rounded,
                        color: isApprove ? AppColors.success : AppColors.danger,
                        size: 24,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        isApprove ? 'Authorize Expenditure' : 'Reject Expense Request',
                        style: AppTypography.titleMedium.copyWith(
                          color: AppColors.light,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.color3Light,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '₦${_formatAmount((item['amount'] as num).toDouble())}',
                          style: AppTypography.titleLarge.copyWith(
                            color: isApprove ? AppColors.success : AppColors.danger,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item['reason'] ?? '',
                          style: AppTypography.bodySmall.copyWith(color: AppColors.dark),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text('Audit Commentary / Note', style: AppTypography.labelMedium),
                  const SizedBox(height: 6),
                  TextField(
                    controller: noteController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: isApprove
                          ? 'Enter approval code or remarks...'
                          : 'Provide specific reason for rejection...',
                      hintStyle: AppTypography.bodySmall.copyWith(color: AppColors.color2Light),
                      filled: true,
                      fillColor: AppColors.color3Light,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  PrimaryButton(
                    text: isApprove ? 'Confirm Approval' : 'Confirm Rejection',
                    color: isApprove ? AppColors.success : AppColors.danger,
                    isLoading: isSubmitting,
                    onPressed: () async {
                      setModalState(() => isSubmitting = true);
                      try {
                        final expenseId = item['_id']?.toString() ?? '';
                        final endpoint = isApprove ? 'expenses/approve/$expenseId' : 'expenses/reject/$expenseId';
                        await ApiClient.instance.send('PATCH', endpoint,
                            feature: 'expenses', label: isApprove ? 'Approve expense' : 'Reject expense', body: {
                          'note': noteController.text.trim(),
                        });
                      } catch (e) {
                        setModalState(() => isSubmitting = false);
                        if (modalCtx.mounted) {
                          ScaffoldMessenger.of(modalCtx).showSnackBar(SnackBar(content: Text('Could not update: $e')));
                        }
                        return;
                      }

                      setState(() {
                        item['status'] = isApprove ? 'approved' : 'rejected';
                        item['approvedBy'] = 'You (Executive)';
                        item['note'] = noteController.text.trim();
                      });

                      if (modalCtx.mounted) Navigator.pop(modalCtx);
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            backgroundColor: isApprove ? AppColors.success : AppColors.danger,
                            content: Text(
                              isApprove ? 'Expense request approved!' : 'Expense request rejected.',
                            ),
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

  void _showNewExpenseModal() async {
    // Expenses are filed against the current session/term and a section.
    Map? current;
    List<Map> sections = [];
    try {
      final res = await ApiClient.instance.get('staff/last-term-session');
      if (res is Map) current = res;
    } catch (_) {}
    try {
      final res = await ApiClient.instance.get('section', queryParams: {'limit': 100});
      final list = res is Map ? (res['sections'] ?? res['data']) : null;
      if (list is List) sections = list.whereType<Map>().toList();
    } catch (_) {}
    if (!mounted) return;
    final sessionId = current?['lastSession']?['_id']?.toString();
    final termId = current?['lastTerm']?['_id']?.toString();
    final periodLabel = '${current?['lastSession']?['session'] ?? ''} · ${current?['lastTerm']?['term'] ?? ''} term';
    String? sectionId = sections.isNotEmpty ? sections.first['_id']?.toString() : null;
    final reasonController = TextEditingController();
    final amountController = TextEditingController();
    bool isSubmitting = false;

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
                    'Request New Expense',
                    style: AppTypography.titleLarge.copyWith(color: AppColors.light, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 14),
                  Text('Expenditure Narrative / Reason', style: AppTypography.labelMedium),
                  const SizedBox(height: 6),
                  TextField(
                    controller: reasonController,
                    decoration: InputDecoration(
                      hintText: 'e.g. Science Lab Reagents for Term 3',
                      filled: true,
                      fillColor: AppColors.color3Light,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text('Amount (₦)', style: AppTypography.labelMedium),
                  const SizedBox(height: 6),
                  TextField(
                    controller: amountController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: 'e.g. 250000',
                      prefixText: '₦ ',
                      filled: true,
                      fillColor: AppColors.color3Light,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text('Section', style: AppTypography.labelMedium),
                  DropdownButton<String>(
                    isExpanded: true,
                    value: sectionId,
                    hint: const Text('Choose section'),
                    items: sections
                        .map((sec) => DropdownMenuItem<String>(value: sec['_id']?.toString(), child: Text(sec['name']?.toString() ?? 'Section')))
                        .toList(),
                    onChanged: (v) => setModalState(() => sectionId = v),
                  ),
                  Text('For $periodLabel', style: AppTypography.labelSmall),
                  const SizedBox(height: 18),
                  PrimaryButton(
                    text: 'Submit Request',
                    isLoading: isSubmitting,
                    onPressed: () async {
                      final reason = reasonController.text.trim();
                      final amt = double.tryParse(amountController.text.trim()) ?? 0.0;
                      if (reason.isEmpty || amt <= 0) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Please enter a valid reason and amount')),
                        );
                        return;
                      }

                      if (sessionId == null || termId == null || sectionId == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('No current session/term or section found. Connect once to load them.')),
                        );
                        return;
                      }
                      setModalState(() => isSubmitting = true);
                      try {
                        await ApiClient.instance.send('POST', 'expenses', feature: 'expenses', label: 'Expense: $reason', body: {
                          'reason': reason,
                          'amountSpent': amt,
                          'session': sessionId,
                          'term': termId,
                          'section': sectionId,
                        });
                      } catch (e) {
                        setModalState(() => isSubmitting = false);
                        if (modalCtx.mounted) {
                          ScaffoldMessenger.of(modalCtx).showSnackBar(SnackBar(content: Text('Could not submit: $e')));
                        }
                        return;
                      }

                      setState(() {
                        _expenses.insert(0, {
                          '_id': 'exp-${DateTime.now().millisecondsSinceEpoch}',
                          'reason': reason,
                          'amount': amt,
                          'session': current?['lastSession']?['session'] ?? '',
                          'term': current?['lastTerm']?['term'] ?? '',
                          'section': sections.where((x) => x['_id']?.toString() == sectionId).map((x) => x['name']).firstOrNull ?? '',
                          'requestedBy': 'You',
                          'status': 'pending',
                          'createdAt': DateTime.now().toIso8601String(),
                        });
                      });

                      if (modalCtx.mounted) Navigator.pop(modalCtx);
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            backgroundColor: AppColors.success,
                            content: Text('Expense request submitted successfully!'),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Expenses Desk',
          style: AppTypography.titleLarge.copyWith(color: AppColors.light, fontWeight: FontWeight.w700),
        ),
        backgroundColor: AppColors.surface,
        elevation: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: AppColors.light),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.color2Light,
          indicatorColor: AppColors.primary,
          indicatorWeight: 3,
          labelStyle: AppTypography.labelMedium.copyWith(fontWeight: FontWeight.w700),
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'Pending'),
            Tab(text: 'Approved'),
            Tab(text: 'Rejected'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showNewExpenseModal,
        backgroundColor: AppColors.secondary,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: Text(
          'Request Expense',
          style: AppTypography.labelMedium.copyWith(color: Colors.white, fontWeight: FontWeight.w700),
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
                        _buildExpensesList('all'),
                        _buildExpensesList('pending'),
                        _buildExpensesList('approved'),
                        _buildExpensesList('rejected'),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpensesList(String filter) {
    final list = _getFilteredList(filter);

    return RefreshIndicator(
      onRefresh: _fetchExpenses,
      color: AppColors.primary,
      child: list.isEmpty
          ? _buildEmptyState(filter)
          : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              itemCount: list.length,
              itemBuilder: (context, index) {
                return _buildExpenseCard(list[index]);
              },
            ),
    );
  }

  Widget _buildExpenseCard(Map<String, dynamic> item) {
    final reason = item['reason'] ?? '';
    final amount = (item['amount'] as num?)?.toDouble() ?? 0.0;
    final status = (item['status'] ?? 'pending').toString().toLowerCase();
    final session = item['session'] ?? '2024/2025';
    final term = item['term'] ?? '3rd Term';
    final section = item['section'] ?? '';
    final requestedBy = item['requestedBy'] ?? 'Staff';
    final approvedBy = item['approvedBy'];
    final note = item['note'];

    final isPending = status == 'pending';
    final isApproved = status == 'approved';

    Color statusColor;
    if (isApproved) {
      statusColor = AppColors.success;
    } else if (isPending) {
      statusColor = const Color(0xFFF59E0B);
    } else {
      statusColor = AppColors.danger;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppColors.shadowCard,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '₦${_formatAmount(amount)}',
                  style: AppTypography.titleLarge.copyWith(
                    fontWeight: FontWeight.w800,
                    color: isApproved ? AppColors.danger : (isPending ? const Color(0xFFF59E0B) : AppColors.color2Light),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircleAvatar(radius: 4, backgroundColor: statusColor),
                      const SizedBox(width: 6),
                      Text(
                        status.toUpperCase(),
                        style: AppTypography.labelSmall.copyWith(
                          color: statusColor,
                          fontWeight: FontWeight.w800,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              reason,
              style: AppTypography.titleSmall.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.dark,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.person_outline, size: 14, color: AppColors.color2Light),
                const SizedBox(width: 4),
                Text('Req: $requestedBy', style: AppTypography.bodySmall.copyWith(fontSize: 11)),
                const SizedBox(width: 12),
                Icon(Icons.calendar_today_outlined, size: 14, color: AppColors.color2Light),
                const SizedBox(width: 4),
                Text('$session • $term', style: AppTypography.bodySmall.copyWith(fontSize: 11)),
              ],
            ),
            if (section.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                'Section: $section',
                style: AppTypography.labelSmall.copyWith(color: AppColors.color4Light, fontSize: 11),
              ),
            ],
            if (approvedBy != null || note != null) ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.color3Light,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (approvedBy != null)
                      Text(
                        'Audit Authority: $approvedBy',
                        style: AppTypography.labelSmall.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.light,
                        ),
                      ),
                    if (note != null && note.isNotEmpty)
                      Text(
                        'Note: $note',
                        style: AppTypography.bodySmall.copyWith(color: AppColors.dark, fontSize: 11),
                      ),
                  ],
                ),
              ),
            ],
            if (isPending) ...[
              const SizedBox(height: 14),
              const Divider(height: 1),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton.icon(
                    onPressed: () => _showApprovalBottomSheet(item, false),
                    icon: const Icon(Icons.close_rounded, size: 16, color: AppColors.danger),
                    label: Text(
                      'Reject',
                      style: AppTypography.labelMedium.copyWith(color: AppColors.danger, fontWeight: FontWeight.w700),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.danger),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton.icon(
                    onPressed: () => _showApprovalBottomSheet(item, true),
                    icon: const Icon(Icons.check_rounded, size: 16, color: Colors.white),
                    label: Text(
                      'Approve',
                      style: AppTypography.labelMedium.copyWith(color: Colors.white, fontWeight: FontWeight.w700),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatAmount(double val) {
    return val.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
        );
  }

  Widget _buildEmptyState(String filter) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.receipt_long_outlined, size: 64, color: AppColors.color2Light),
          const SizedBox(height: 12),
          Text('No $filter Expenses', style: AppTypography.titleMedium),
          const SizedBox(height: 4),
          Text(
            'New requests will appear here for audit review.',
            style: AppTypography.bodySmall,
          ),
        ],
      ),
    );
  }
}
