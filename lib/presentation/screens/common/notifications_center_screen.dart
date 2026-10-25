import 'package:flutter/material.dart';
import 'package:edstream_mobile/core/constants/app_constants.dart';
import 'package:edstream_mobile/core/network/api_client.dart';
import 'package:edstream_mobile/core/storage/local_cache_store.dart';
import 'package:edstream_mobile/core/theme/app_colors.dart';
import 'package:edstream_mobile/core/theme/app_typography.dart';
import 'package:edstream_mobile/core/widgets/sync_status_banner.dart';
import 'package:edstream_mobile/presentation/widgets/custom_text_field.dart';
import 'package:edstream_mobile/presentation/widgets/primary_button.dart';

class NotificationsCenterScreen extends StatefulWidget {
  final bool isStudent;

  const NotificationsCenterScreen({super.key, this.isStudent = false});

  @override
  State<NotificationsCenterScreen> createState() => _NotificationsCenterScreenState();
}

class _NotificationsCenterScreenState extends State<NotificationsCenterScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  List<Map<String, dynamic>> _allNotifications = [];
  List<Map<String, dynamic>> _mentions = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchNotifications();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchNotifications() async {
    final role = LocalCacheStore.instance.getString(AppConstants.roleKey);
    final isStudentRole = widget.isStudent || role == AppConstants.roleStudent;
    final endpoint = isStudentRole ? 'student/my-notifications' : 'notification';
    const cacheKey = 'notifications_stream_cache';

    final cached = LocalCacheStore.instance.getJson(cacheKey);
    if (cached is List && cached.isNotEmpty) {
      _applyData(cached);
      setState(() => _isLoading = false);
    }

    try {
      final res = await ApiClient.instance.get(endpoint, cacheLocally: true, cacheKey: cacheKey);
      List<dynamic> list = [];
      if (res is List) {
        list = res;
      } else if (res is Map) {
        if (res['data'] is List) {
          list = res['data'];
        } else if (res['data'] is Map && res['data']['notifications'] is List) {
          list = res['data']['notifications'];
        } else if (res['notifications'] is List) {
          list = res['notifications'];
        }
      }

      if (list.isNotEmpty && mounted) {
        _applyData(list);
      }
    } catch (_) {
      // Nothing cached and no connection: show the empty state.
      if (_allNotifications.isEmpty) {
        final mockList = <Map<String, dynamic>>[];
        _applyData(mockList);
      }
    }

    if (mounted) setState(() => _isLoading = false);
  }

  void _applyData(List list) {
    final parsed = list.map<Map<String, dynamic>>((item) {
      if (item is Map) {
        final title = item['header'] ?? item['title'] ?? 'Notification';
        final message = item['message'] ?? '';
        final sender = item['from'] is Map
            ? '${item['from']['firstName'] ?? ''} ${item['from']['surname'] ?? ''}'.trim()
            : (item['from']?.toString() ?? item['sender'] ?? 'Administration');
        final audience = item['notificationType'] ?? item['audience'] ?? 'General';
        return {
          ...Map<String, dynamic>.from(item),
          'title': title,
          'message': message,
          'sender': sender.isNotEmpty ? sender : 'Administration',
          'audience': audience,
        };
      }
      return {};
    }).where((item) => item.isNotEmpty).toList();

    setState(() {
      _allNotifications = parsed;
      _mentions = parsed.where((n) => n['isMention'] == true).toList();
    });
  }

  void _openComposeModal() {
    final titleController = TextEditingController();
    final messageController = TextEditingController();
    String audience = 'teacher-to-students';
    String targetClass = 'All Assigned Classes';
    bool isSending = false;

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
                      Text('Broadcast Announcement', style: AppTypography.titleLarge),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Send notices directly to students or class parents.',
                    style: AppTypography.bodySmall,
                  ),
                  const SizedBox(height: 16),

                  Text('Target Audience:', style: AppTypography.labelMedium),
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
                        value: audience,
                        isExpanded: true,
                        items: const [
                          DropdownMenuItem(
                            value: 'teacher-to-students',
                            child: Text('Teacher to Students & Guardians'),
                          ),
                          DropdownMenuItem(
                            value: 'school-to-teachers',
                            child: Text('Departmental Staff Notice'),
                          ),
                          DropdownMenuItem(
                            value: 'school-to-both',
                            child: Text('General School Notice'),
                          ),
                        ],
                        onChanged: (val) {
                          if (val != null) setModalState(() => audience = val);
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  Text('Target Class:', style: AppTypography.labelMedium),
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
                        value: targetClass,
                        isExpanded: true,
                        items: const [
                          DropdownMenuItem(value: 'All Assigned Classes', child: Text('All Assigned Classes')),
                          DropdownMenuItem(value: 'SS 2 Gold', child: Text('SS 2 Gold (Form Class)')),
                          DropdownMenuItem(value: 'SS 2 Diamond', child: Text('SS 2 Diamond')),
                          DropdownMenuItem(value: 'JSS 3 Blue', child: Text('JSS 3 Blue')),
                        ],
                        onChanged: (val) {
                          if (val != null) setModalState(() => targetClass = val);
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  CustomTextField(
                    controller: titleController,
                    labelText: 'Notification Title',
                    hintText: 'e.g. Test Schedule / Project Submission',
                    prefixIcon: const Icon(Icons.campaign_outlined, size: 20),
                  ),
                  const SizedBox(height: 14),

                  CustomTextField(
                    controller: messageController,
                    labelText: 'Announcement Body',
                    hintText: 'Write announcement text...',
                    maxLines: 4,
                  ),
                  const SizedBox(height: 20),

                  PrimaryButton(
                    text: 'Broadcast Message',
                    isLoading: isSending,
                    icon: const Icon(Icons.send_rounded, color: Colors.white, size: 18),
                    onPressed: () async {
                      if (titleController.text.trim().isEmpty ||
                          messageController.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Please fill all fields')),
                        );
                        return;
                      }

                      setModalState(() => isSending = true);
                      final payload = {
                        'header': titleController.text.trim(),
                        'title': titleController.text.trim(),
                        'message': messageController.text.trim(),
                        'notificationType': audience,
                        'targetClass': targetClass != 'All Assigned Classes' ? targetClass : null,
                      };

                      try {
                        await ApiClient.instance.send('POST', 'notification', feature: 'notifications', label: 'notifications update', body: payload);
                      } catch (_) {}

                      // Local optimistic insertion
                      setState(() {
                        _allNotifications.insert(0, {
                          '_id': 'notif-${DateTime.now().millisecondsSinceEpoch}',
                          'title': titleController.text.trim(),
                          'message': messageController.text.trim(),
                          'audience': audience,
                          'sender': 'You (Form Master)',
                          'isRead': false,
                          'isMention': false,
                          'createdAt': DateTime.now().toIso8601String(),
                        });
                      });

                      if (ctx.mounted) Navigator.pop(ctx);
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Broadcast dispatched to students successfully.'),
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

  void _showNotificationDetail(Map<String, dynamic> notif) {
    setState(() => notif['isRead'] = true);

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
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      notif['audience'] ?? 'ANNOUNCEMENT',
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(notif['title'] ?? 'Notification', style: AppTypography.titleLarge),
              const SizedBox(height: 4),
              Text(
                'Sender: ${notif['sender'] ?? "School Desk"} • ${_formatTime(notif['createdAt'])}',
                style: AppTypography.bodySmall.copyWith(color: AppColors.color2Light),
              ),
              const SizedBox(height: 14),
              const Divider(height: 1),
              const SizedBox(height: 14),
              Text(
                notif['message'] ?? '',
                style: AppTypography.bodyMedium.copyWith(height: 1.5),
              ),
              const SizedBox(height: 24),
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

  String _formatTime(dynamic dateStr) {
    if (dateStr == null) return 'Recent';
    try {
      final dt = DateTime.parse(dateStr.toString());
      return '${dt.day}/${dt.month}/${dt.year} at ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return dateStr.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    final role = LocalCacheStore.instance.getString(AppConstants.roleKey);
    final isTeacher = role == AppConstants.roleTeacher;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Communications Center', style: AppTypography.headlineSmall),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            tooltip: 'Mark All Read',
            icon: const Icon(Icons.done_all_rounded, color: AppColors.primary),
            onPressed: () {
              setState(() {
                for (var n in _allNotifications) {
                  n['isRead'] = true;
                }
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('All notifications marked as read')),
              );
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.color2Light,
          tabs: [
            Tab(text: 'All (${_allNotifications.length})'),
            Tab(text: 'Mentions (${_mentions.length})'),
          ],
        ),
      ),
      floatingActionButton: isTeacher
          ? FloatingActionButton.extended(
              backgroundColor: AppColors.primary,
              icon: const Icon(Icons.campaign_rounded, color: Colors.white),
              label: const Text(
                'New Broadcast',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
              ),
              onPressed: _openComposeModal,
            )
          : null,
      body: Column(
        children: [
          const SyncStatusBanner(feature: 'notifications', itemNoun: 'alert'),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildNotificationList(_allNotifications),
                      _buildNotificationList(_mentions),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationList(List<Map<String, dynamic>> items) {
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.notifications_none_rounded,
                size: 56, color: AppColors.color2Light.withValues(alpha: 0.5)),
            const SizedBox(height: 12),
            Text('No Notifications', style: AppTypography.titleMedium),
            const SizedBox(height: 4),
            Text('You are all caught up!', style: AppTypography.bodySmall),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchNotifications,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 80),
        itemCount: items.length,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final notif = items[index];
          final isRead = notif['isRead'] == true;

          return Container(
            decoration: BoxDecoration(
              color: isRead ? Colors.white : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(16),
              boxShadow: AppColors.shadowCard,
              border: Border.all(
                color: isRead
                    ? AppColors.cardBorder.withValues(alpha: 0.4)
                    : AppColors.primary.withValues(alpha: 0.3),
                width: isRead ? 1 : 1.5,
              ),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () => _showNotificationDetail(notif),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: (isRead ? AppColors.color2Light : AppColors.primary)
                              .withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.notifications_active_rounded,
                          size: 20,
                          color: isRead ? AppColors.color2Light : AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    notif['title'] ?? 'Notice',
                                    style: AppTypography.titleMedium.copyWith(
                                      fontWeight: isRead ? FontWeight.w600 : FontWeight.w800,
                                      color: isRead ? AppColors.dark : AppColors.primary,
                                    ),
                                  ),
                                ),
                                if (!isRead)
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: const BoxDecoration(
                                      color: AppColors.danger,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              notif['message'] ?? '',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.bodySmall.copyWith(
                                color: AppColors.color7Light,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  notif['sender'] ?? 'School Desk',
                                  style: AppTypography.labelSmall.copyWith(
                                    color: AppColors.color2Light,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  _formatTime(notif['createdAt']),
                                  style: AppTypography.labelSmall.copyWith(
                                    color: AppColors.color2Light,
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
              ),
            ),
          );
        },
      ),
    );
  }
}
