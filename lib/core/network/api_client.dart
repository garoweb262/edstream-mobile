import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:edstream_mobile/core/constants/app_constants.dart';
import 'package:edstream_mobile/core/network/api_exception.dart';
import 'package:edstream_mobile/core/network/connectivity_controller.dart';
import 'package:edstream_mobile/core/network/offline_mutation_queue.dart';
import 'package:edstream_mobile/core/network/pending_mutation.dart';
import 'package:edstream_mobile/core/storage/local_cache_store.dart';

/// Central HTTP client for Edstream.
///
/// - Every GET is cached (per path + query) so screens keep working offline;
///   offline answers carry `_offline: true` and `_cachedAt`.
/// - [send] performs a write, and when the device is offline it queues the
///   write to be replayed by OfflineSyncService, returning `{'_queued': true}`.
/// - The server address can be changed at build time with
///   `--dart-define=API_URL=https://.../api/v1/`.
class ApiClient {
  ApiClient._();
  static final ApiClient instance = ApiClient._();

  static const String baseUrl = String.fromEnvironment('API_URL', defaultValue: 'https://api.edstream.ng/api/v1/');
  static const Duration timeoutDuration = Duration(seconds: 15);

  String? _authToken;

  /// App-wide messenger (set on MaterialApp) used to say a change was saved offline.
  static final GlobalKey<ScaffoldMessengerState> messengerKey = GlobalKey<ScaffoldMessengerState>();

  void setAuthToken(String? token) {
    _authToken = token;
    if (token != null) {
      LocalCacheStore.instance.setString(AppConstants.tokenKey, token);
    } else {
      LocalCacheStore.instance.remove(AppConstants.tokenKey);
    }
  }

  Future<String?> getAuthToken() async {
    if (_authToken != null) return _authToken;
    await LocalCacheStore.instance.init();
    _authToken = LocalCacheStore.instance.getString(AppConstants.tokenKey);
    return _authToken;
  }

  Map<String, String> _buildHeaders(Map<String, String>? customHeaders) {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (_authToken != null && _authToken!.isNotEmpty) {
      headers['Authorization'] = 'Bearer $_authToken';
    }
    if (customHeaders != null) headers.addAll(customHeaders);
    return headers;
  }

  /// Lets tests point the client elsewhere (e.g. an unreachable server).
  @visibleForTesting
  static String? baseUrlOverride;

  Uri _resolveUri(String path, [Map<String, dynamic>? queryParams]) {
    final cleanPath = path.startsWith('/') ? path.substring(1) : path;
    final base = baseUrlOverride ?? baseUrl;
    final root = base.endsWith('/') ? base : '$base/';
    final uri = Uri.parse('$root$cleanPath');
    if (queryParams != null && queryParams.isNotEmpty) {
      return uri.replace(queryParameters: queryParams.map((k, v) => MapEntry(k, v.toString())));
    }
    return uri;
  }

  /// Cache key for a GET: path plus sorted query, so different filters
  /// never overwrite each other.
  static String cacheKeyFor(String path, [Map<String, dynamic>? queryParams]) {
    final clean = path.startsWith('/') ? path.substring(1) : path;
    if (queryParams == null || queryParams.isEmpty) return 'cache_get_$clean';
    final keys = queryParams.keys.toList()..sort();
    return 'cache_get_$clean?${keys.map((k) => '$k=${queryParams[k]}').join('&')}';
  }

  static bool _isNetworkFailure(Object e) =>
      e is SocketException || e is TimeoutException || e is http.ClientException || e is HandshakeException;

  Future<http.Response> _request(String method, Uri uri, Map<String, String> headers, dynamic body) {
    final encoded = body != null ? jsonEncode(body) : null;
    switch (method) {
      case 'GET':
        return http.get(uri, headers: headers);
      case 'POST':
        return http.post(uri, headers: headers, body: encoded);
      case 'PUT':
        return http.put(uri, headers: headers, body: encoded);
      case 'PATCH':
        return http.patch(uri, headers: headers, body: encoded);
      case 'DELETE':
        return http.delete(uri, headers: headers, body: encoded);
    }
    throw ArgumentError('Unsupported method $method');
  }

  /// Sends one request and decodes it. Throws ApiException; network
  /// failures have `isNetworkError: true`.
  Future<dynamic> _send(
    String method,
    String path, {
    dynamic body,
    Map<String, dynamic>? queryParams,
    Map<String, String>? headers,
    String? cacheKey,
  }) async {
    await getAuthToken();
    try {
      final response = await _request(method, _resolveUri(path, queryParams), _buildHeaders(headers), body)
          .timeout(timeoutDuration);
      ConnectivityController.instance.markReachable(true);
      return _handleResponse(response, cacheKey: cacheKey);
    } catch (e) {
      if (e is ApiException) rethrow;
      if (_isNetworkFailure(e)) {
        ConnectivityController.instance.markReachable(false);
        throw ApiException(
          message: e is TimeoutException
              ? 'The server took too long to answer. Please try again.'
              : 'No internet connection. Please check your network.',
          isNetworkError: true,
        );
      }
      throw ApiException(message: 'Request failed: $e');
    }
  }

  /// GET with offline fallback. Pass `cacheLocally: false` for data that
  /// must never come from an old copy (e.g. payment verification).
  Future<dynamic> get(
    String path, {
    Map<String, dynamic>? queryParams,
    Map<String, String>? headers,
    bool cacheLocally = true,
    String? cacheKey,
  }) async {
    final key = cacheKey ?? cacheKeyFor(path, queryParams);
    try {
      return await _send('GET', path, queryParams: queryParams, headers: headers, cacheKey: cacheLocally ? key : null);
    } on ApiException catch (e) {
      if (e.isNetworkError && cacheLocally) {
        final cached = LocalCacheStore.instance.getJson(key);
        if (cached != null) {
          if (cached is Map) {
            return {
              ...Map<String, dynamic>.from(cached),
              '_offline': true,
              '_cachedAt': LocalCacheStore.instance.getCacheTime(key)?.toIso8601String(),
            };
          }
          return cached;
        }
      }
      rethrow;
    }
  }

  Future<dynamic> post(String path, {dynamic body, Map<String, String>? headers}) =>
      _send('POST', path, body: body, headers: headers);

  Future<dynamic> put(String path, {dynamic body, Map<String, String>? headers}) =>
      _send('PUT', path, body: body, headers: headers);

  Future<dynamic> patch(String path, {dynamic body, Map<String, String>? headers}) =>
      _send('PATCH', path, body: body, headers: headers);

  Future<dynamic> delete(String path, {Map<String, String>? headers}) => _send('DELETE', path, headers: headers);

  /// Replays a queued change (used by OfflineSyncService).
  Future<dynamic> replay(String method, String path, Map<String, dynamic>? body) => _send(method, path, body: body);

  /// A write that survives being offline: sent now when possible, otherwise
  /// saved and sent automatically later. Returns the server reply, or
  /// `{'_queued': true}` when it was saved for later. Server rejections
  /// (4xx/5xx) are thrown as usual.
  Future<dynamic> send(
    String method,
    String path, {
    Map<String, dynamic>? body,
    required String feature,
    required String label,
  }) async {
    try {
      return await _send(method, path, body: body);
    } on ApiException catch (e) {
      if (!e.isNetworkError) rethrow;
      await OfflineMutationQueue.instance.enqueue(PendingMutation(
        localId: OfflineMutationQueue.instance.generateLocalId(feature),
        feature: feature,
        operation: label,
        method: method,
        path: path,
        payload: body,
        displaySnapshot: {'label': label},
        createdAt: DateTime.now(),
      ));
      _notify('You are offline. "$label" is saved on this phone and will be sent automatically.');
      return {'_queued': true};
    }
  }

  static void _notify(String text) {
    try {
      messengerKey.currentState?.showSnackBar(SnackBar(content: Text(text)));
    } catch (_) {
      // No UI (e.g. background or tests): nothing to show.
    }
  }

  static bool isQueued(dynamic result) => result is Map && result['_queued'] == true;
  static bool isOffline(dynamic result) => result is Map && result['_offline'] == true;

  dynamic _handleResponse(http.Response response, {String? cacheKey}) {
    dynamic decoded;
    if (response.body.isNotEmpty) {
      try {
        decoded = jsonDecode(response.body);
      } catch (_) {
        decoded = response.body;
      }
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (cacheKey != null && decoded != null) {
        LocalCacheStore.instance.setJson(cacheKey, decoded);
      }
      return decoded;
    }

    String errorMessage = 'Server error (${response.statusCode})';
    if (decoded is Map && decoded['message'] != null) {
      errorMessage = decoded['message'].toString();
    }
    throw ApiException(message: errorMessage, statusCode: response.statusCode, data: decoded);
  }
}
