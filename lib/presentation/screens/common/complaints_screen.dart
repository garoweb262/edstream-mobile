import 'package:flutter/material.dart';
import 'package:edstream_mobile/core/constants/app_constants.dart';
import 'package:edstream_mobile/core/network/api_client.dart';
import 'package:edstream_mobile/core/storage/local_cache_store.dart';
import 'package:edstream_mobile/core/theme/app_colors.dart';
import 'package:edstream_mobile/core/theme/app_typography.dart';
import 'package:edstream_mobile/core/widgets/sync_status_banner.dart';
import 'package:edstream_mobile/presentation/widgets/custom_text_field.dart';
import 'package:edstream_mobile/presentation/widgets/primary_button.dart';

class ComplaintsScreen extends StatefulWidget {
  final bool isStudent;

  const ComplaintsScreen({super.key, this.isStudent = false});

  @override
  State<ComplaintsScreen> createState() => _ComplaintsScreenState();
}

class _ComplaintsScreenState extends State<ComplaintsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  List<Map<String, dynamic>> _complaints = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _fetchComplaints();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchComplaints() async {
    final role = LocalCacheStore.instance.getString(AppConstants.roleKey);
    final isStudentRole = widget.isStudent || role == AppConstants.roleStudent;
    final endpoint = isStudentRole ? 'student/complaints' : 'complain/school';
    final cacheKey = 'complaints_cache_${isStudentRole ? "student" : "staff"}';

    final cached = LocalCacheStore.instance.getJson(cacheKey);
    if (cached is List && cached.isNotEmpty) {
      setState(() {
        _complaints = List<Map<String, dynamic>>.from(cached);
        _isLoading = false;
      });
    }

    try {
      final res = await ApiClient.instance.get(endpoint, cacheLocally: true, cacheKey: cacheKey);
      List<dynamic> list = [];
      if (res is List) {
        list = res;
      } else if (res is Map) {
        if (res['data'] is List) {
          list = res['data'];
        } else if (res['data'] is Map && res['data']['complaints'] is List) {
          list = res['data']['complaints'];
        } else if (res['complaints'] is List) {
          list = res['complaints'];
        }
      }

      if (list.isNotEmpty && mounted) {
        setState(() {
          _complaints = List<Map<String, dynamic>>.from(list);
          _isLoading = false;
        });
      }
    } catch (_) {
      // Fallback sample data if endpoint not seeded
      if (_complaints.isEmpty) {
        _complaints = [
          {
            '_id': 'comp-1',
            'subject': 'Laboratory Microscope Malfunction',
            'message': 'Two binocular microscopes in Biology Lab 2 are defective and need immediate servicing before the term practicals.',
            'sendTo': 'School Authority',
            'senderName': 'Dr. Sule Idi',
            'status': 'pending',
            'createdAt': '2026-10-08T14:20:00Z',
            'resolution': null,
          },
          {
            '_id': 'comp-2',
            'subject': 'Smart Board Connectivity in Hall 4',
            'message': 'HDMI projector and smartboard connection keeps dropping during mathematics lectures.',
            'sendTo': 'System Support',
            'senderName': 'Dr. Sule Idi',
            'status': 'resolved',
            'createdAt': '2026-10-02T09:15:00Z',
            'resolution': 'ICT technical team replaced the master cable and updated HDMI firmware.',
          },
          {
            '_id': 'comp-3',
            'subject': 'Whiteboard Marker Replacements',
            'message': 'Department requires extra blue and black erasable marker packs for second half of term.',
            'sendTo': 'School Authority',
            'senderName': 'Dr. Sule Idi',
            'status': 'resolved',
            'createdAt': '2026-09-24T11:00:00Z',
            'resolution': 'Stationery dispatched and signed for at the general staff room.',
          },
        ];
      }
    }

    if (mounted) setState(() => _isLoading = false);
  }

  void _openCreateComplaintModal() {
    final role = LocalCacheStore.instance.getString(AppConstants.roleKey);
    final isStudentRole = widget.isStudent || role == AppConstants.roleStudent;

    final subjectController = TextEditingController();
    final messageController = TextEditingController();
    String sendTo = 'School Authority';
    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (modalContext, setModalState) {
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
                      Text('Submit Grievance / Complaint', style: AppTypography.titleLarge),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Your complaint will be reviewed securely by administrative authorities.',
                    style: AppTypography.bodySmall,
                  ),
                  const SizedBox(height: 16),

                  if (!isStudentRole) ...[
                    Text('Send Complaint To:', style: AppTypography.labelMedium),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.cardBorder),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: sendTo,
                          isExpanded: true,
                          items: const [
                            DropdownMenuItem(
                              value: 'School Authority',
                              child: Text('School Authority (Principal / Director)'),
                            ),
                            DropdownMenuItem(
                              value: 'System Support',
                              child: Text('System Support (Technical / ICT)'),
                            ),
                          ],
                          onChanged: (val) {
                            if (val != null) setModalState(() => sendTo = val);
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                  ],

                  CustomTextField(
                    controller: subjectController,
                    labelText: 'Subject',
                    hintText: 'Brief summary of issue',
                    prefixIcon: const Icon(Icons.title_rounded, size: 20),
                  ),
                  const SizedBox(height: 14),

                  CustomTextField(
                    controller: messageController,
                    labelText: 'Complaint Narrative',
                    hintText: 'Describe details, dates, or affected facilities...',
                    maxLines: 4,
                  ),
                  const SizedBox(height: 20),

                  PrimaryButton(
                    text: 'Submit Complaint',
                    isLoading: isSubmitting,
                    icon: const Icon(Icons.send_rounded, color: Colors.white, size: 18),
                    onPressed: () async {
                      if (subjectController.text.trim().isEmpty ||
                          messageController.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Please fill all fields')),
                        );
                        return;
                      }

                      setModalState(() => isSubmitting = true);
                      final endpoint =
                          isStudentRole ? 'complain/student-to-school' : 'complain/staff-to-school';
                      final payload = {
                        'subject': subjectController.text.trim(),
                        'message': messageController.text.trim(),
                        'complainType': isStudentRole ? 'student-to-school' : 'staff-to-school',
                      };

                      try {
                        await ApiClient.instance.send('POST', endpoint, feature: 'complaints', label: 'Complaint: ${payload['subject']}', body: payload);
                      } catch (e) {
                        setModalState(() => isSubmitting = false);
                        if (mounted) {
                          ApiClient.messengerKey.currentState?.showSnackBar(SnackBar(content: Text('Could not send: $e')));
                        }
                        return;
                      }

                      // Local optimistic append
                      setState(() {
                        _complaints.insert(0, {
                          '_id': 'local-${DateTime.now().millisecondsSinceEpoch}',
                          'subject': subjectController.text.trim(),
                          'message': messageController.text.trim(),
                          'sendTo': sendTo,
                          'status': 'pending',
                          'createdAt': DateTime.now().toIso8601String(),
                        });
                      });

                      if (ctx.mounted) Navigator.pop(ctx);
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Grievance logged successfully. Awaiting review.'),
                            backgroundColor: AppColors.success,
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

  void _showComplaintDetails(Map<String, dynamic> item) {
    final status = (item['status'] ?? 'pending').toString().toLowerCase();
    final isResolved = status == 'resolved';
    final resolution = item['resolution']?.toString();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: (isResolved ? AppColors.success : AppColors.warning)
                          .withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      isResolved ? 'RESOLVED' : 'PENDING REVIEW',
                      style: AppTypography.labelSmall.copyWith(
                        color: isResolved ? AppColors.success : const Color(0xFFD97706),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(item['subject'] ?? 'Complaint Subject', style: AppTypography.titleLarge),
              const SizedBox(height: 4),
              Text(
                'Submitted on ${_formatDate(item['createdAt'])} • Recipient: ${item['sendTo'] ?? "School Desk"}',
                style: AppTypography.bodySmall.copyWith(color: AppColors.color2Light),
              ),
              const SizedBox(height: 14),
              const Divider(height: 1),
              const SizedBox(height: 14),
              Text('Complaint Description:', style: AppTypography.titleSmall),
              const SizedBox(height: 6),
              Text(item['message'] ?? '', style: AppTypography.bodyMedium),
              const SizedBox(height: 18),
              if (resolution != null && resolution.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.success.withValues(alpha: 0.2)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.verified_rounded, size: 18, color: AppColors.success),
                          const SizedBox(width: 6),
                          Text(
                            'Administrative Resolution:',
                            style: AppTypography.titleSmall.copyWith(color: AppColors.success),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(resolution, style: AppTypography.bodySmall),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
              ],
              PrimaryButton(
                text: 'Dismiss',
                onPressed: () => Navigator.pop(ctx),
              ),
            ],
          ),
        );
      },
    );
  }

  String _formatDate(dynamic dateStr) {
    if (dateStr == null) return 'Recent';
    try {
      final dt = DateTime.parse(dateStr.toString());
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (_) {
      return dateStr.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    final pendingList = _complaints
        .where((c) => (c['status'] ?? 'pending').toString().toLowerCase() != 'resolved')
        .toList();
    final resolvedList = _complaints
        .where((c) => (c['status'] ?? '').toString().toLowerCase() == 'resolved')
        .toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Complaints & Grievances', style: AppTypography.headlineSmall),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.color2Light,
          tabs: [
            Tab(text: 'All (${_complaints.length})'),
            Tab(text: 'Pending (${pendingList.length})'),
            Tab(text: 'Resolved (${resolvedList.length})'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add_comment_rounded, color: Colors.white),
        label: const Text('New Complaint', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
        onPressed: _openCreateComplaintModal,
      ),
      body: Column(
        children: [
          const SyncStatusBanner(feature: 'complaints', itemNoun: 'grievance'),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildComplaintsList(_complaints),
                      _buildComplaintsList(pendingList),
                      _buildComplaintsList(resolvedList),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildComplaintsList(List<Map<String, dynamic>> items) {
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_rounded, size: 56, color: AppColors.color2Light.withValues(alpha: 0.5)),
            const SizedBox(height: 12),
            Text('No Complaints in this view', style: AppTypography.titleMedium),
            const SizedBox(height: 4),
            Text(
              'Use the button below to submit a new inquiry.',
              style: AppTypography.bodySmall,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchComplaints,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 80),
        itemCount: items.length,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final c = items[index];
          final isResolved = (c['status'] ?? '').toString().toLowerCase() == 'resolved';

          return Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: AppColors.shadowCard,
              border: Border.all(color: AppColors.cardBorder.withValues(alpha: 0.4)),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () => _showComplaintDetails(c),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: (isResolved ? AppColors.success : AppColors.primary)
                                        .withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(
                                    isResolved ? Icons.check_circle_outline : Icons.help_outline_rounded,
                                    size: 18,
                                    color: isResolved ? AppColors.success : AppColors.primary,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    c['sendTo'] ?? 'School Authority',
                                    style: AppTypography.labelMedium.copyWith(
                                      color: AppColors.color7Light,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: (isResolved ? AppColors.success : AppColors.warning)
                                  .withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              isResolved ? 'Resolved' : 'Pending',
                              style: AppTypography.labelSmall.copyWith(
                                color: isResolved ? AppColors.success : const Color(0xFFD97706),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        c['subject'] ?? 'Grievance',
                        style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        c['message'] ?? '',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.bodySmall.copyWith(color: AppColors.color7Light),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _formatDate(c['createdAt']),
                            style: AppTypography.labelSmall.copyWith(color: AppColors.color2Light),
                          ),
                          Row(
                            children: [
                              Text(
                                'View Thread',
                                style: AppTypography.labelSmall.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Icon(Icons.arrow_forward_ios_rounded, size: 10, color: AppColors.primary),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
