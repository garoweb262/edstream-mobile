import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Local persistent caching engine for Edstream Mobile.
/// Saves and restores offline snapshots of academic records, rosters, and invoices.
class LocalCacheStore {
  LocalCacheStore._();
  static final LocalCacheStore instance = LocalCacheStore._();

  SharedPreferences? _prefs;

  Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  SharedPreferences get _requirePrefs {
    if (_prefs == null) {
      throw StateError('LocalCacheStore has not been initialized. Call init() first.');
    }
    return _prefs!;
  }

  Future<bool> setJson(String key, dynamic data) async {
    await init();
    final jsonStr = jsonEncode({
      'timestamp': DateTime.now().toIso8601String(),
      'data': data,
    });
    return _requirePrefs.setString(key, jsonStr);
  }

  dynamic getJson(String key) {
    if (_prefs == null) return null;
    final jsonStr = _prefs!.getString(key);
    if (jsonStr == null) return null;
    try {
      final decoded = jsonDecode(jsonStr) as Map<String, dynamic>;
      return decoded['data'];
    } catch (_) {
      return null;
    }
  }

  DateTime? getCacheTime(String key) {
    if (_prefs == null) return null;
    final jsonStr = _prefs!.getString(key);
    if (jsonStr == null) return null;
    try {
      final decoded = jsonDecode(jsonStr) as Map<String, dynamic>;
      return DateTime.parse(decoded['timestamp'] as String);
    } catch (_) {
      return null;
    }
  }

  Future<bool> setString(String key, String value) async {
    await init();
    return _requirePrefs.setString(key, value);
  }

  String? getString(String key) {
    return _prefs?.getString(key);
  }

  Future<bool> setInt(String key, int value) async {
    await init();
    return _requirePrefs.setInt(key, value);
  }

  int? getInt(String key) {
    return _prefs?.getInt(key);
  }

  Future<bool> remove(String key) async {
    await init();
    return _requirePrefs.remove(key);
  }

  /// Removes every stored key except those [keep] says to keep.
  Future<void> removeAllExcept(bool Function(String key) keep) async {
    await init();
    for (final key in _requirePrefs.getKeys().toList()) {
      if (!keep(key)) await _requirePrefs.remove(key);
    }
  }

  Future<bool> clearAll() async {
    await init();
    return _requirePrefs.clear();
  }

  Future<bool> clear() => clearAll();
}
