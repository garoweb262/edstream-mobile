import 'package:flutter/foundation.dart';
import 'package:edstream_mobile/core/network/api_client.dart';
import 'package:edstream_mobile/core/network/offline_mutation_queue.dart';

/// Service responsible for flushing offline mutations when the app returns online.
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
    final mutations = queue.getAll();
    if (mutations.isEmpty) return;

    _isSyncing = true;
    notifyListeners();

    try {
      for (final mutation in mutations) {
        try {
          if (mutation.method == 'POST') {
            await ApiClient.instance.post(mutation.path, body: mutation.payload);
          } else if (mutation.method == 'PUT') {
            await ApiClient.instance.put(mutation.path, body: mutation.payload);
          } else if (mutation.method == 'DELETE') {
            await ApiClient.instance.delete(mutation.path);
          }
          // Remove on success
          await queue.remove(mutation.localId);
          _syncedCount++;
        } catch (e) {
          debugPrint('Failed to sync mutation ${mutation.localId}: $e');
          // If network is down again, abort batch
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
