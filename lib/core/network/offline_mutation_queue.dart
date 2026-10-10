import 'package:flutter/foundation.dart';
import 'package:edstream_mobile/core/network/pending_mutation.dart';
import 'package:edstream_mobile/core/storage/local_cache_store.dart';

/// Persistent queue for actions performed while offline.
/// Notifies listeners whenever mutations are enqueued, synced, or removed.
class OfflineMutationQueue extends ChangeNotifier {
  OfflineMutationQueue._();
  static final OfflineMutationQueue instance = OfflineMutationQueue._();

  static const String _queueKey = 'edstream_offline_mutation_queue';
  final List<PendingMutation> _mutations = [];

  bool _isInitialized = false;

  Future<void> init() async {
    if (_isInitialized) return;
    await LocalCacheStore.instance.init();
    final rawList = LocalCacheStore.instance.getJson(_queueKey);
    if (rawList is List) {
      _mutations.clear();
      for (final item in rawList) {
        if (item is Map) {
          _mutations.add(PendingMutation.fromMap(Map<String, dynamic>.from(item)));
        }
      }
    }
    _isInitialized = true;
    notifyListeners();
  }

  String generateLocalId(String feature) {
    return 'mut-$feature-${DateTime.now().millisecondsSinceEpoch}';
  }

  Future<void> enqueue(PendingMutation mutation) async {
    await init();
    _mutations.add(mutation);
    await _persist();
    notifyListeners();
  }

  Future<void> remove(String localId) async {
    await init();
    _mutations.removeWhere((m) => m.localId == localId);
    await _persist();
    notifyListeners();
  }

  List<PendingMutation> getAll({String? feature}) {
    if (feature == null) {
      return List.unmodifiable(_mutations);
    }
    return _mutations.where((m) => m.feature == feature).toList();
  }

  int count({String? feature}) {
    if (feature == null) {
      return _mutations.length;
    }
    return _mutations.where((m) => m.feature == feature).length;
  }

  Future<void> clear() async {
    _mutations.clear();
    await _persist();
    notifyListeners();
  }

  Future<void> _persist() async {
    final list = _mutations.map((m) => m.toMap()).toList();
    await LocalCacheStore.instance.setJson(_queueKey, list);
  }
}
