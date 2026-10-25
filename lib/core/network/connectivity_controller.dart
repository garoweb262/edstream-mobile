import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:edstream_mobile/core/network/offline_sync_service.dart';

/// Tracks whether the app can reach Edstream. Wi-Fi being on is not enough,
/// so real request results (via [markReachable]) also count. Pending offline
/// changes are sent when the connection comes back, at start-up, and every
/// minute while online.
class ConnectivityController extends ChangeNotifier {
  ConnectivityController._();

  static final ConnectivityController instance = ConnectivityController._();

  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _subscription;
  Timer? _timer;
  bool _started = false;

  bool _isOnline = true;

  bool get isOnline => _isOnline;
  bool get isOffline => !_isOnline;

  /// Call once at app start.
  Future<void> start() async {
    if (_started) return;
    _started = true;
    try {
      _updateStatus(await _connectivity.checkConnectivity());
    } catch (_) {
      _isOnline = true;
    }
    _subscription = _connectivity.onConnectivityChanged.listen(_updateStatus);
    _timer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (_isOnline) OfflineSyncService.instance.flushPendingMutations();
    });
    if (_isOnline) OfflineSyncService.instance.flushPendingMutations();
  }

  void _setOnline(bool value) {
    if (_isOnline == value) return;
    final cameBack = value && !_isOnline;
    _isOnline = value;
    notifyListeners();
    if (cameBack) OfflineSyncService.instance.flushPendingMutations();
  }

  void _updateStatus(List<ConnectivityResult> results) {
    _setOnline(results.any((r) => r != ConnectivityResult.none));
  }

  /// Called by ApiClient after each request: a reply means online, a
  /// network failure means offline.
  void markReachable(bool reachable) => _setOnline(reachable);

  Future<bool> checkConnection() async {
    _updateStatus(await _connectivity.checkConnectivity());
    return _isOnline;
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _timer?.cancel();
    super.dispose();
  }
}
