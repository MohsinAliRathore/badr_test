class AppException implements Exception {
  const AppException({
    required this.code,
    required this.message,
    this.details,
    this.statusCode,
  });

  final String code;
  final String message;
  final Object? details;
  final int? statusCode;

  bool get isUnauthenticated =>
      code == 'UNAUTHENTICATED' || statusCode == 401;

  bool get isForbidden => code == 'FORBIDDEN' || statusCode == 403;

  bool get isNotFound => code == 'NOT_FOUND' || statusCode == 404;

  bool get isInvalidState =>
      code == 'INVALID_STATE' || code == 'CONFLICT' || statusCode == 409;

  bool get isValidation => code == 'VALIDATION_FAILED' || statusCode == 422;

  bool get isMaintenance => code == 'MAINTENANCE' || statusCode == 503;

  factory AppException.fromJson(
    Map<String, dynamic> json, {
    int? statusCode,
  }) {
    final error = json['error'];
    if (error is Map<String, dynamic>) {
      return AppException(
        code: error['code']?.toString() ?? 'UNKNOWN',
        message: error['message']?.toString() ?? 'Unexpected error',
        details: error['details'],
        statusCode: statusCode,
      );
    }
    return AppException(
      code: json['code']?.toString() ?? 'UNKNOWN',
      message: json['message']?.toString() ?? 'Unexpected error',
      details: json['details'],
      statusCode: statusCode,
    );
  }

  @override
  String toString() => 'AppException($code): $message';
}
