import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:edstream_mobile/core/constants/app_constants.dart';
import 'package:edstream_mobile/core/network/api_exception.dart';
import 'package:edstream_mobile/core/storage/local_cache_store.dart';

/// Central HTTP Client for Edstream Cloud Services
/// Configured with base URL https://api.edstream.ng/api/v1/ and automatic bearer authorization.
class ApiClient {
  ApiClient._();
  static final ApiClient instance = ApiClient._();

  static const String baseUrl = 'https://api.edstream.ng/api/v1/';
  static const Duration timeoutDuration = Duration(seconds: 15);

  String? _authToken;

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
    if (customHeaders != null) {
      headers.addAll(customHeaders);
    }
    return headers;
  }

  Uri _resolveUri(String path, [Map<String, dynamic>? queryParams]) {
    final cleanPath = path.startsWith('/') ? path.substring(1) : path;
    final urlStr = '$baseUrl$cleanPath';
    final uri = Uri.parse(urlStr);
    if (queryParams != null && queryParams.isNotEmpty) {
      return uri.replace(
        queryParameters: queryParams.map((k, v) => MapEntry(k, v.toString())),
      );
    }
    return uri;
  }

  /// GET request with optional offline cache fallback
  Future<dynamic> get(
    String path, {
    Map<String, dynamic>? queryParams,
    Map<String, String>? headers,
    bool cacheLocally = false,
    String? cacheKey,
  }) async {
    await getAuthToken();
    final effectiveCacheKey = cacheKey ?? 'cache_get_$path';

    try {
      final uri = _resolveUri(path, queryParams);
      final response = await http
          .get(uri, headers: _buildHeaders(headers))
          .timeout(timeoutDuration);

      return _handleResponse(response, cacheKey: cacheLocally ? effectiveCacheKey : null);
    } on SocketException {
      if (cacheLocally) {
        final cachedData = LocalCacheStore.instance.getJson(effectiveCacheKey);
        if (cachedData != null) return cachedData;
      }
      throw ApiException(
        message: 'No internet connection. Please check your network.',
        isNetworkError: true,
      );
    } on TimeoutException {
      if (cacheLocally) {
        final cachedData = LocalCacheStore.instance.getJson(effectiveCacheKey);
        if (cachedData != null) return cachedData;
      }
      throw ApiException(
        message: 'Server request timed out. Please try again.',
        isNetworkError: true,
      );
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(message: 'Unexpected network error: $e');
    }
  }

  /// POST request
  Future<dynamic> post(
    String path, {
    dynamic body,
    Map<String, String>? headers,
  }) async {
    await getAuthToken();
    try {
      final uri = _resolveUri(path);
      final response = await http
          .post(
            uri,
            headers: _buildHeaders(headers),
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(timeoutDuration);

      return _handleResponse(response);
    } on SocketException {
      throw ApiException(
        message: 'No internet connection. Request queued for offline sync.',
        isNetworkError: true,
      );
    } on TimeoutException {
      throw ApiException(
        message: 'Request timed out. Please try again.',
        isNetworkError: true,
      );
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(message: 'Request failed: $e');
    }
  }

  /// PUT request
  Future<dynamic> put(
    String path, {
    dynamic body,
    Map<String, String>? headers,
  }) async {
    await getAuthToken();
    try {
      final uri = _resolveUri(path);
      final response = await http
          .put(
            uri,
            headers: _buildHeaders(headers),
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(timeoutDuration);

      return _handleResponse(response);
    } on SocketException {
      throw ApiException(
        message: 'No internet connection. Request queued for offline sync.',
        isNetworkError: true,
      );
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(message: 'Request failed: $e');
    }
  }

  /// DELETE request
  Future<dynamic> delete(
    String path, {
    Map<String, String>? headers,
  }) async {
    await getAuthToken();
    try {
      final uri = _resolveUri(path);
      final response = await http
          .delete(uri, headers: _buildHeaders(headers))
          .timeout(timeoutDuration);

      return _handleResponse(response);
    } on SocketException {
      throw ApiException(
        message: 'No internet connection.',
        isNetworkError: true,
      );
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(message: 'Delete failed: $e');
    }
  }

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

    throw ApiException(
      message: errorMessage,
      statusCode: response.statusCode,
      data: decoded,
    );
  }
}
