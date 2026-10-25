import 'package:flutter/foundation.dart';
import 'package:edstream_mobile/core/network/api_client.dart';
import 'package:edstream_mobile/core/network/api_exception.dart';
import 'package:edstream_mobile/core/network/offline_mutation_queue.dart';

/// Sends changes saved while offline, oldest first.
/// - Network failure: stop and try again later (order is kept).
/// - Server rejection (e.g. validation): mark that change failed and carry
///   on, so one bad change never blocks the rest.
class OfflineSyncService extends ChangeNotifier {
  OfflineSyncService._();
  static final OfflineSyncService instance = OfflineSyncService._();

  bool _isSyncing = false;
  DateTime? _lastSyncTime;
  int _syncedCount = 0;

  bool get isSyncing => _isSyncing;
  DateTime? get lastSyncTime => _lastSyncTime;
  int get syncedCount => _syncedCount;

  Future<void> flushPendingMutations() async {
    if (_isSyncing) return;

    final queue = OfflineMutationQueue.instance;
    await queue.init();
    final mutations = queue.getAll().where((m) => !m.isFailed).toList();
    if (mutations.isEmpty) return;

    _isSyncing = true;
    notifyListeners();

    try {
      for (final mutation in mutations) {
        try {
          await ApiClient.instance.replay(mutation.method, mutation.path, mutation.payload);
          await queue.remove(mutation.localId);
          _syncedCount++;
        } on ApiException catch (e) {
          if (e.isNetworkError || e.statusCode == 401) break;
          await queue.markFailed(mutation.localId, e.message);
        } catch (e) {
          debugPrint('Failed to sync mutation ${mutation.localId}: $e');
          break;
        }
      }
      _lastSyncTime = DateTime.now();
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }
}
