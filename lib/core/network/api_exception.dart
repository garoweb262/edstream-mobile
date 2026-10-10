class ApiException implements Exception {
  ApiException({
    required this.message,
    this.statusCode,
    this.data,
    this.isNetworkError = false,
  });

  final String message;
  final int? statusCode;
  final dynamic data;
  final bool isNetworkError;

  @override
  String toString() => message;
}
