import 'package:flutter/material.dart';
import 'package:edstream_mobile/core/network/api_client.dart';
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
  final bool _isPaid = true;

  final List<Map<String, dynamic>> _breakdown = [
    {'title': 'Tuition Fee', 'amount': '₦120,000'},
    {'title': 'Infrastructure & Development Levy', 'amount': '₦30,000'},
    {'title': 'ICT & Science Laboratory Fee', 'amount': '₦20,000'},
    {'title': 'Library, Sports & Club Dues', 'amount': '₦15,000'},
  ];

  @override
  void initState() {
    super.initState();
    _fetchSchoolFees();
  }

  Future<void> _fetchSchoolFees() async {
    const cacheKey = 'student_school_fees';
    try {
      await ApiClient.instance.get(
        'student/my-payments',
        cacheLocally: true,
        cacheKey: cacheKey,
      );
    } catch (_) {}
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
                      '₦185,000',
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
        title: Text('School Fees & Payments', style: AppTypography.headlineSmall),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          const SyncStatusBanner(itemNoun: 'payment record'),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Invoice Card
                  Container(
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      gradient: AppColors.heroCardGradient,
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: AppColors.shadowMd,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'First Term 2026/2027',
                              style: AppTypography.titleSmall.copyWith(color: Colors.white70),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: _isPaid
                                    ? AppColors.success.withValues(alpha: 0.25)
                                    : AppColors.warning.withValues(alpha: 0.25),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                _isPaid ? 'PAID IN FULL' : 'PENDING',
                                style: AppTypography.labelSmall.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          '₦185,000.00',
                          style: AppTypography.displayMedium.copyWith(color: Colors.white),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Invoice Reference: INV-2026-EDS-0824',
                          style: AppTypography.bodySmall.copyWith(color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  Text('Fee Breakdown', style: AppTypography.titleLarge),
                  const SizedBox(height: 12),

                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: AppColors.shadowCard,
                    ),
                    child: ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _breakdown.length,
                      separatorBuilder: (context, index) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final item = _breakdown[index];
                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
                          title: Text(item['title'] as String, style: AppTypography.titleSmall),
                          trailing: Text(
                            item['amount'] as String,
                            style: AppTypography.titleMedium.copyWith(
                              fontWeight: FontWeight.w600,
                              color: AppColors.light,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Payment History
                  Text('Receipts & Transactions', style: AppTypography.titleLarge),
                  const SizedBox(height: 12),

                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: AppColors.shadowCard,
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.success.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.receipt_long_rounded,
                            color: AppColors.success,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Paystack Online Transfer', style: AppTypography.titleSmall),
                              Text('Ref: pstk_883019284 • 12 Oct 2026', style: AppTypography.bodySmall),
                            ],
                          ),
                        ),
                        Text(
                          '₦185,000',
                          style: AppTypography.labelLarge.copyWith(color: AppColors.success),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  if (!_isPaid)
                    PrimaryButton(
                      text: 'Pay Fees via Paystack',
                      onPressed: _showPaymentModal,
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
