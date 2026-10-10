import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:edstream_mobile/core/network/offline_sync_service.dart';

/// Monitors device network connectivity status in real time.
/// Triggers offline queue flushing when network is restored.
class ConnectivityController extends ChangeNotifier {
  ConnectivityController._() {
    _init();
  }

  static final ConnectivityController instance = ConnectivityController._();

  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _subscription;

  bool _isOnline = true;
  bool _wasOffline = false;

  bool get isOnline => _isOnline;
  bool get isOffline => !_isOnline;

  Future<void> _init() async {
    try {
      final results = await _connectivity.checkConnectivity();
      _updateStatus(results);
    } catch (_) {
      _isOnline = true;
    }

    _subscription = _connectivity.onConnectivityChanged.listen((results) {
      _updateStatus(results);
    });
  }

  void _updateStatus(List<ConnectivityResult> results) {
    final nowOnline = results.any((r) => r != ConnectivityResult.none);

    // If reconnecting from an offline state, trigger sync
    if (nowOnline && _wasOffline) {
      OfflineSyncService.instance.flushPendingMutations();
    }

    _wasOffline = !nowOnline;
    if (_isOnline != nowOnline) {
      _isOnline = nowOnline;
      notifyListeners();
    }
  }

  Future<bool> checkConnection() async {
    final results = await _connectivity.checkConnectivity();
    _isOnline = results.any((r) => r != ConnectivityResult.none);
    notifyListeners();
    return _isOnline;
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
