/// Typed API Exception hierarchy for the MyMechanic API client.
///
/// Phase 3 Step 4.1: Flutter API Client Foundation.
///
/// All network, HTTP, formatting, and configuration errors are mapped
/// to specific typed subclasses to avoid swallowing errors or returning
/// misleading states.
library;

/// Base exception for all API-related errors.
abstract class ApiException implements Exception {
  final String message;
  final Object? cause;
  final StackTrace? stackTrace;

  const ApiException(this.message, {this.cause, this.stackTrace});

  @override
  String toString() => '$runtimeType: $message';
}

/// Thrown when the server returns a non-2xx HTTP status code.
class HttpStatusException extends ApiException {
  /// The HTTP response status code (e.g. 400, 401, 403, 404, 409, 500).
  final int statusCode;

  /// Optional machine-readable error code parsed from the server response
  /// (e.g. 'NOT_FOUND', 'INVALID_CREDENTIALS', 'DUPLICATE_EMAIL').
  final String? errorCode;

  /// The parsed response body (if JSON) or raw response text.
  final dynamic responseBody;

  const HttpStatusException({
    required this.statusCode,
    required String message,
    this.errorCode,
    this.responseBody,
    Object? cause,
    StackTrace? stackTrace,
  }) : super(message, cause: cause, stackTrace: stackTrace);

  /// 4xx client error
  bool get isClientError => statusCode >= 400 && statusCode < 500;

  /// 5xx server error
  bool get isServerError => statusCode >= 500 && statusCode < 600;

  /// 400 Bad Request
  bool get isBadRequest => statusCode == 400;

  /// 401 Unauthorized
  bool get isUnauthorized => statusCode == 401;

  /// 403 Forbidden
  bool get isForbidden => statusCode == 403;

  /// 404 Not Found
  bool get isNotFound => statusCode == 404;

  /// 409 Conflict
  bool get isConflict => statusCode == 409;

  @override
  String toString() {
    final codePart = errorCode != null ? ' [$errorCode]' : '';
    return 'HttpStatusException ($statusCode)$codePart: $message';
  }
}

/// Thrown when a network-level or connection failure occurs (e.g. host unreachable,
/// connection refused, DNS lookup failed, TLS handshake failed).
class NetworkException extends ApiException {
  const NetworkException(super.message, {super.cause, super.stackTrace});
}

/// Thrown when an HTTP request exceeds the specified timeout duration.
class ApiTimeoutException extends ApiException {
  /// The timeout threshold that was exceeded.
  final Duration timeout;

  const ApiTimeoutException(
    super.message, {
    required this.timeout,
    super.cause,
    super.stackTrace,
  });

  @override
  String toString() => 'ApiTimeoutException (${timeout.inSeconds}s): $message';
}

/// Thrown when a 2xx response has an invalid or malformed format (e.g. invalid JSON).
class ApiResponseFormatException extends ApiException {
  /// The raw unparseable response string received from the server.
  final String rawBody;

  const ApiResponseFormatException(
    super.message, {
    required this.rawBody,
    super.cause,
    super.stackTrace,
  });
}

/// Thrown when the base URL, path, or request configuration is invalid.
class ApiConfigurationException extends ApiException {
  const ApiConfigurationException(super.message, {super.cause, super.stackTrace});
}

/// Thrown when an authentication session error occurs (e.g. refresh token expired,
/// token reuse detected, session revoked, or unauthenticated session cannot be refreshed).
class AuthSessionException extends ApiException {
  /// Optional machine-readable error code (e.g. 'TOKEN_REUSE_DETECTED', 'REFRESH_TOKEN_EXPIRED', 'NO_REFRESH_TOKEN').
  final String? errorCode;

  const AuthSessionException(
    super.message, {
    this.errorCode,
    super.cause,
    super.stackTrace,
  });

  @override
  String toString() {
    final codePart = errorCode != null ? ' [$errorCode]' : '';
    return 'AuthSessionException$codePart: $message';
  }
}
