import 'package:flutter/material.dart';
import 'package:edstream_mobile/core/network/connectivity_controller.dart';
import 'package:edstream_mobile/core/network/offline_mutation_queue.dart';
import 'package:edstream_mobile/core/network/offline_sync_service.dart';
import 'package:edstream_mobile/core/theme/app_colors.dart';
import 'package:edstream_mobile/core/theme/app_typography.dart';

/// Shows an informative banner at the top of screens when offline
/// or when local mutations are waiting to sync to the server.
class SyncStatusBanner extends StatelessWidget {
  const SyncStatusBanner({
    super.key,
    this.feature,
    this.itemNoun = 'change',
  });

  final String? feature;
  final String itemNoun;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([
        ConnectivityController.instance,
        OfflineMutationQueue.instance,
        OfflineSyncService.instance,
      ]),
      builder: (context, _) {
        final isOffline = ConnectivityController.instance.isOffline;
        final isSyncing = OfflineSyncService.instance.isSyncing;
        final pendingCount = OfflineMutationQueue.instance.count(feature: feature);

        if (!isOffline && !isSyncing && pendingCount == 0) {
          return const SizedBox.shrink();
        }

        Color bgColor;
        Color fgColor;
        Widget icon;
        String text;

        if (isSyncing) {
          bgColor = const Color(0xFFEFF6FF); // Light Blue
          fgColor = AppColors.primary;
          icon = const SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          );
          text = 'Syncing records with Edstream Cloud...';
        } else if (isOffline) {
          bgColor = const Color(0xFFFFFBEB); // Light Amber
          fgColor = const Color(0xFFD97706); // Dark Amber
          icon = const Icon(Icons.wifi_off_rounded, size: 16, color: Color(0xFFD97706));
          final countText = pendingCount > 0
              ? ' · $pendingCount $itemNoun${pendingCount == 1 ? '' : 's'} pending'
              : '';
          text = 'Offline Mode — showing cached records$countText';
        } else {
          bgColor = const Color(0xFFF0FDF4); // Light Green
          fgColor = const Color(0xFF16A34A);
          icon = const Icon(Icons.sync_rounded, size: 16, color: Color(0xFF16A34A));
          text = '$pendingCount $itemNoun${pendingCount == 1 ? '' : 's'} ready to sync';
        }

        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
          decoration: BoxDecoration(
            color: bgColor,
            border: Border(
              bottom: BorderSide(color: fgColor.withValues(alpha: 0.2), width: 1),
            ),
          ),
          child: Row(
            children: [
              icon,
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  text,
                  style: AppTypography.labelMedium.copyWith(
                    color: fgColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (!isOffline && !isSyncing && pendingCount > 0)
                GestureDetector(
                  onTap: () => OfflineSyncService.instance.flushPendingMutations(),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: fgColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Sync Now',
                      style: AppTypography.labelSmall.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
