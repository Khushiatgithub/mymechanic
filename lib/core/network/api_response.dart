/// Generic API Response container for the MyMechanic API client.
///
/// Phase 3 Step 4.1: Flutter API Client Foundation.
library;

/// Represents a successful or parsed response from the MyMechanic backend.
class ApiResponse<T> {
  /// The HTTP status code of the response (e.g. 200, 201, 204).
  final int statusCode;

  /// The parsed response data payload (typically the contents of the `data`
  /// field from the backend's standard `{ success, message, data }` envelope).
  final T? data;

  /// Optional human-readable message returned by the server envelope.
  final String? message;

  /// Whether the operation succeeded from an API level.
  final bool success;

  /// The response HTTP headers.
  final Map<String, String> headers;

  /// The complete parsed JSON map/list or raw body object.
  final dynamic rawBody;

  const ApiResponse({
    required this.statusCode,
    this.data,
    this.message,
    this.success = true,
    this.headers = const {},
    this.rawBody,
  });

  /// True if the response status code is in the 2xx success range.
  bool get isSuccessful => statusCode >= 200 && statusCode < 300;

  /// True if this was an empty 204 No Content response.
  bool get isNoContent => statusCode == 204;

  @override
  String toString() =>
      'ApiResponse<$T>(statusCode: $statusCode, success: $success, message: $message, data: $data)';
}
