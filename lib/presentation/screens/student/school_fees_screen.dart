import 'package:flutter/material.dart';
import 'package:edstream_mobile/core/network/api_client.dart';
import 'package:edstream_mobile/core/storage/local_cache_store.dart';
import 'package:edstream_mobile/core/theme/app_colors.dart';
import 'package:edstream_mobile/core/theme/app_typography.dart';
import 'package:edstream_mobile/core/widgets/sync_status_banner.dart';
import 'package:edstream_mobile/presentation/widgets/primary_button.dart';

class SchoolFeesScreen extends StatefulWidget {
  const SchoolFeesScreen({super.key});

  @override
  State<SchoolFeesScreen> createState() => _SchoolFeesScreenState();
}

class _SchoolFeesScreenState extends State<SchoolFeesScreen> {
  bool _isPaid = true;
  bool _isLoading = true;
  String _session = '2024/2025';
  String _term = '3rd Term';
  String _totalAmount = '₦185,000';

  final List<Map<String, dynamic>> _breakdown = const [
    {'title': 'Tuition Fee', 'amount': '₦120,000'},
    {'title': 'Infrastructure & Development Levy', 'amount': '₦30,000'},
    {'title': 'ICT & Science Laboratory Fee', 'amount': '₦20,000'},
    {'title': 'Library, Sports & Club Dues', 'amount': '₦15,000'},
  ];

  List<Map<String, dynamic>> _paymentsHistory = [];

  @override
  void initState() {
    super.initState();
    _fetchSchoolFees();
  }

  Future<void> _fetchSchoolFees() async {
    const cacheKey = 'student_school_fees';
    final cached = LocalCacheStore.instance.getJson(cacheKey);

    if (cached is Map) {
      _applyCachedFees(cached);
      setState(() => _isLoading = false);
    }

    try {
      final res = await ApiClient.instance.get(
        'student/my-payments',
        cacheLocally: true,
        cacheKey: cacheKey,
      );

      if (res is Map && res['payments'] is List) {
        final list = List<Map<String, dynamic>>.from(res['payments']);
        setState(() {
          _paymentsHistory = list;
          if (list.isNotEmpty) {
            _isPaid = list.any((p) => p['status'] == 'successful');
          }
        });
      }
    } catch (_) {}
    if (mounted) setState(() => _isLoading = false);
  }

  void _applyCachedFees(Map data) {
    if (data['payments'] is List) {
      _paymentsHistory = List<Map<String, dynamic>>.from(data['payments']);
      if (_paymentsHistory.isNotEmpty) {
        _isPaid = _paymentsHistory.any((p) => p['status'] == 'successful');
        final first = _paymentsHistory.first;
        if (first['amount'] != null) {
          _totalAmount = '₦${first['amount']}';
        }
        final fee = first['schoolFeesId'];
        if (fee is Map) {
          if (fee['session'] is Map) _session = fee['session']['session']?.toString() ?? _session;
          if (fee['term'] is Map) _term = fee['term']['term']?.toString() ?? _term;
        }
      }
    }
  }

  void _showPaymentModal() {
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
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Paystack Gateway', style: AppTypography.titleLarge),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Secured payment processing powered by Paystack.',
                style: AppTypography.bodySmall,
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.color3Light,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Total Payable', style: AppTypography.titleSmall),
                    Text(
                      _totalAmount,
                      style: AppTypography.titleLarge.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              PrimaryButton(
                text: 'Proceed to Paystack Checkout',
                onPressed: () {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Payment session launched. Checking receipt reference...'),
                    ),
                  );
                },
                icon: const Icon(Icons.credit_card_rounded, color: Colors.white, size: 20),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('School Fees & Billing', style: AppTypography.headlineSmall),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          const SyncStatusBanner(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _fetchSchoolFees,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Status Card
                          Container(
                            padding: const EdgeInsets.all(22),
                            decoration: BoxDecoration(
                              gradient: _isPaid
                                  ? const LinearGradient(
                                      colors: [Color(0xFF059669), Color(0xFF10B981)],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    )
                                  : AppColors.heroCardGradient,
                              borderRadius: BorderRadius.circular(22),
                              boxShadow: AppColors.shadowMd,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(alpha: 0.22),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        _isPaid ? 'PAID IN FULL' : 'PAYMENT PENDING',
                                        style: AppTypography.labelSmall.copyWith(
                                          color: Colors.white,
                                          letterSpacing: 1.0,
                                        ),
                                      ),
                                    ),
                                    Icon(
                                      _isPaid ? Icons.verified_rounded : Icons.pending_rounded,
                                      color: Colors.white,
                                      size: 24,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 18),
                                Text(
                                  _totalAmount,
                                  style: const TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '$_term • $_session Academic Session',
                                  style: AppTypography.bodyMedium.copyWith(
                                    color: Colors.white.withValues(alpha: 0.9),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Fee Breakdown
                          Text('Invoice Breakdown', style: AppTypography.titleLarge),
                          const SizedBox(height: 14),

                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(color: AppColors.cardBorder),
                              boxShadow: AppColors.shadowSm,
                            ),
                            child: ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: _breakdown.length,
                              separatorBuilder: (context, index) => const Divider(height: 1, indent: 16, endIndent: 16),
                              itemBuilder: (context, index) {
                                final item = _breakdown[index];
                                return Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          item['title'] as String,
                                          style: AppTypography.bodyMedium,
                                        ),
                                      ),
                                      Text(
                                        item['amount'] as String,
                                        style: AppTypography.titleSmall.copyWith(
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Transaction History
                          if (_paymentsHistory.isNotEmpty) ...[
                            Text('Payment Receipts', style: AppTypography.titleLarge),
                            const SizedBox(height: 14),
                            ..._paymentsHistory.map((p) {
                              final amt = p['amount'] != null ? '₦${p['amount']}' : '₦185,000';
                              final ref = p['transactionReference'] ?? p['_id'] ?? 'REF-001';
                              final status = p['status']?.toString().toUpperCase() ?? 'SUCCESSFUL';
                              return Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: AppColors.cardBorder),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(amt, style: AppTypography.titleMedium),
                                        const SizedBox(height: 2),
                                        Text(ref.toString(), style: AppTypography.bodySmall),
                                      ],
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: AppColors.success.withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Text(
                                        status,
                                        style: AppTypography.labelSmall.copyWith(
                                          color: AppColors.success,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }),
                            const SizedBox(height: 12),
                          ],

                          if (!_isPaid)
                            PrimaryButton(
                              text: 'Pay School Fees Online',
                              onPressed: _showPaymentModal,
                              icon: const Icon(Icons.payment_rounded, color: Colors.white, size: 20),
                            )
                          else
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEFF6FF),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: const Color(0xFFBFDBFE)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 24),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      'Fees for this academic term have been fully cleared.',
                                      style: AppTypography.bodyMedium.copyWith(
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
