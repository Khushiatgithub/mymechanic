import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import 'api_exception.dart';
import 'api_response.dart';
import 'auth_session_coordinator.dart';
import 'token_provider.dart';

export 'api_exception.dart';
export 'api_response.dart';
export 'auth_session_coordinator.dart';
export 'secure_storage_driver.dart';
export 'token_provider.dart';
export 'token_storage_service.dart';

/// Reusable HTTP API client for the MyMechanic application.
///
/// Phase 3 Step 4.3: Refresh Token Rotation & Authenticated Interceptor.
///
/// Features:
/// - Supports standard REST operations: GET, POST, PATCH, DELETE.
/// - Safe relative path construction and query parameter encoding.
/// - Strict build-time URL resolution with no silent fallback to localhost.
/// - Standard headers: `Accept: application/json`, and `Content-Type: application/json` for bodies.
/// - Safe JSON encoding/decoding, handling HTTP 204 No Content and non-JSON server error pages.
/// - Strongly-typed exception mapping ([HttpStatusException], [NetworkException], [ApiTimeoutException], [ApiResponseFormatException], [ApiConfigurationException], [AuthSessionException]).
/// - Future-proof authentication hook via injectable [TokenProvider] and [AuthSessionCoordinator].
/// - Transparent HTTP 401 interception: Automatically triggers refresh-token rotation and retries the original request at most once.
/// - De-duplicated concurrent refresh execution to prevent multiple submissions of rotated tokens.
/// - Injectable [http.Client] for seamless unit testing with mock transports.
class ApiClient {
  final String _baseUrl;
  final http.Client _client;
  final bool _ownsClient;
  final TokenProvider? _tokenProvider;
  final AuthSessionCoordinator? _sessionCoordinator;
  final Duration _defaultTimeout;

  ApiClient({
    String? baseUrl,
    http.Client? client,
    TokenProvider? tokenProvider,
    AuthSessionCoordinator? sessionCoordinator,
    Duration? defaultTimeout,
  })  : _baseUrl = ApiConfig.resolveBaseUrl(baseUrl),
        _client = client ?? http.Client(),
        _ownsClient = client == null,
        _sessionCoordinator = sessionCoordinator,
        _tokenProvider = tokenProvider ?? sessionCoordinator?.storageService.getAccessToken,
        _defaultTimeout = defaultTimeout ?? ApiConfig.defaultTimeout;

  /// The resolved base URL used by this client instance.
  String get baseUrl => _baseUrl;

  /// Default timeout duration for requests.
  Duration get defaultTimeout => _defaultTimeout;

  /// Optional session coordinator managing token refresh lifecycle.
  AuthSessionCoordinator? get sessionCoordinator => _sessionCoordinator;

  // ===========================================================================
  // Public HTTP Methods
  // ===========================================================================

  /// Sends an HTTP GET request.
  Future<ApiResponse<dynamic>> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
    Duration? timeout,
  }) {
    return _executeWithAuthRetry(
      method: 'GET',
      path: path,
      queryParameters: queryParameters,
      headers: headers,
      timeout: timeout,
    );
  }

  /// Sends an HTTP POST request.
  Future<ApiResponse<dynamic>> post(
    String path, {
    Object? body,
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
    Duration? timeout,
  }) {
    return _executeWithAuthRetry(
      method: 'POST',
      path: path,
      body: body,
      queryParameters: queryParameters,
      headers: headers,
      timeout: timeout,
    );
  }

  /// Sends an HTTP PATCH request.
  Future<ApiResponse<dynamic>> patch(
    String path, {
    Object? body,
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
    Duration? timeout,
  }) {
    return _executeWithAuthRetry(
      method: 'PATCH',
      path: path,
      body: body,
      queryParameters: queryParameters,
      headers: headers,
      timeout: timeout,
    );
  }

  /// Sends an HTTP DELETE request.
  Future<ApiResponse<dynamic>> delete(
    String path, {
    Object? body,
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
    Duration? timeout,
  }) {
    return _executeWithAuthRetry(
      method: 'DELETE',
      path: path,
      body: body,
      queryParameters: queryParameters,
      headers: headers,
      timeout: timeout,
    );
  }

  /// Closes the underlying HTTP client if this instance created it.
  void close() {
    if (_ownsClient) {
      _client.close();
    }
    _sessionCoordinator?.close();
  }

  // ===========================================================================
  // Internal Execution & Auth Interceptor
  // ===========================================================================

  /// Executes an HTTP request with automatic 401 refresh-and-retry handling.
  Future<ApiResponse<dynamic>> _executeWithAuthRetry({
    required String method,
    required String path,
    Object? body,
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
    Duration? timeout,
    bool isRetry = false,
  }) async {
    final uri = _buildUri(path, queryParameters);
    final hasBody = body != null;
    final requestHeaders = await _buildHeaders(
      headers: headers,
      hasJsonBody: hasBody,
    );
    final effectiveTimeout = timeout ?? _defaultTimeout;
    final encodedBody = hasBody ? _encodeBody(body) : null;

    http.Response response;
    try {
      switch (method) {
        case 'GET':
          response = await _client.get(uri, headers: requestHeaders).timeout(effectiveTimeout);
          break;
        case 'POST':
          response = await _client
              .post(uri, headers: requestHeaders, body: encodedBody)
              .timeout(effectiveTimeout);
          break;
        case 'PATCH':
          response = await _client
              .patch(uri, headers: requestHeaders, body: encodedBody)
              .timeout(effectiveTimeout);
          break;
        case 'DELETE':
          response = await _client
              .delete(uri, headers: requestHeaders, body: encodedBody)
              .timeout(effectiveTimeout);
          break;
        default:
          throw ApiConfigurationException('Unsupported HTTP method: $method');
      }
    } on TimeoutException catch (e, stack) {
      throw ApiTimeoutException(
        'Request timed out after ${effectiveTimeout.inSeconds}s: $method $uri',
        timeout: effectiveTimeout,
        cause: e,
        stackTrace: stack,
      );
    } on SocketException catch (e, stack) {
      throw NetworkException(
        'Network connection failed. Unable to reach server at ${uri.host}:${uri.port}.',
        cause: e,
        stackTrace: stack,
      );
    } on http.ClientException catch (e, stack) {
      throw NetworkException(
        'HTTP client error: ${e.message}',
        cause: e,
        stackTrace: stack,
      );
    } on ApiException {
      rethrow;
    } catch (e, stack) {
      throw NetworkException(
        'Network request failed: $e',
        cause: e,
        stackTrace: stack,
      );
    }

    // Intercept HTTP 401 for automated refresh and single retry
    final coordinator = _sessionCoordinator;
    if (response.statusCode == 401 &&
        !isRetry &&
        coordinator != null &&
        coordinator.isEligibleForRefresh(path)) {
      // Trigger coordinated session refresh
      await coordinator.refreshTokens();

      // Retry original request at most once with newly stored access token
      return _executeWithAuthRetry(
        method: method,
        path: path,
        body: body,
        queryParameters: queryParameters,
        headers: headers,
        timeout: timeout,
        isRetry: true,
      );
    }

    return _processResponse(response, method: method, uri: uri);
  }

  /// Safely resolves the relative path against the normalized base URL
  /// and applies query parameter encoding.
  Uri _buildUri(String path, Map<String, dynamic>? queryParameters) {
    var cleanPath = path.trim();

    // Strip leading slash
    if (cleanPath.startsWith('/')) {
      cleanPath = cleanPath.substring(1);
    }

    // Guard against accidental duplication of apiPrefix if the caller
    // included 'api/v1/...' in the path
    final apiPrefixWithoutSlash = ApiConfig.apiPrefix.replaceAll(RegExp(r'^/+'), '');
    if (cleanPath.startsWith('$apiPrefixWithoutSlash/')) {
      cleanPath = cleanPath.substring(apiPrefixWithoutSlash.length + 1);
    } else if (cleanPath == apiPrefixWithoutSlash) {
      cleanPath = '';
    }

    final fullUrlString = cleanPath.isEmpty ? _baseUrl : '$_baseUrl/$cleanPath';
    final parsedUri = Uri.parse(fullUrlString);

    if (queryParameters == null || queryParameters.isEmpty) {
      return parsedUri;
    }

    // Convert query parameter values safely to Strings
    final stringParams = <String, String>{};
    for (final entry in queryParameters.entries) {
      if (entry.value != null) {
        stringParams[entry.key] = entry.value.toString();
      }
    }

    return parsedUri.replace(queryParameters: stringParams);
  }

  /// Builds the request headers, injecting Authorization if available.
  Future<Map<String, String>> _buildHeaders({
    Map<String, String>? headers,
    bool hasJsonBody = false,
  }) async {
    final map = <String, String>{
      'Accept': 'application/json',
    };

    if (hasJsonBody) {
      map['Content-Type'] = 'application/json';
    }

    // Optional Bearer token injection
    if (_tokenProvider != null) {
      try {
        final token = await _tokenProvider();
        if (token != null && token.trim().isNotEmpty) {
          map['Authorization'] = 'Bearer ${token.trim()}';
        }
      } catch (_) {
        // Do not crash or log sensitive token retrieval failures
      }
    }

    // Custom headers override defaults (preserves explicitly supplied Authorization headers)
    if (headers != null && headers.isNotEmpty) {
      map.addAll(headers);
    }

    return map;
  }

  /// Safely encodes a request body into JSON.
  String _encodeBody(Object body) {
    if (body is String) {
      return body;
    }
    try {
      return jsonEncode(body);
    } catch (e, stack) {
      throw ApiConfigurationException(
        'Failed to encode request body to JSON: $e',
        cause: e,
        stackTrace: stack,
      );
    }
  }

  /// Processes the [http.Response] into an [ApiResponse] or throws a typed [ApiException].
  ApiResponse<dynamic> _processResponse(
    http.Response response, {
    required String method,
    required Uri uri,
  }) {
    final statusCode = response.statusCode;
    final bodyString = response.body.trim();

    // 1. Handle HTTP 204 No Content or empty successful bodies
    if (statusCode == 204 || (statusCode >= 200 && statusCode < 300 && bodyString.isEmpty)) {
      return ApiResponse<dynamic>(
        statusCode: statusCode,
        success: true,
        data: null,
        headers: response.headers,
        rawBody: '',
      );
    }

    // 2. Handle Successful Responses (2xx)
    if (statusCode >= 200 && statusCode < 300) {
      dynamic decoded;
      try {
        decoded = jsonDecode(response.body);
      } catch (e, stack) {
        throw ApiResponseFormatException(
          'Failed to parse successful $statusCode JSON response for $method $uri.',
          rawBody: response.body,
          cause: e,
          stackTrace: stack,
        );
      }

      if (decoded is Map<String, dynamic>) {
        final success = decoded['success'] as bool? ?? true;
        final message = decoded['message'] as String?;
        // Extract standard data envelope or fallback to complete map
        final data = decoded.containsKey('data') ? decoded['data'] : decoded;

        return ApiResponse<dynamic>(
          statusCode: statusCode,
          success: success,
          message: message,
          data: data,
          headers: response.headers,
          rawBody: decoded,
        );
      }

      return ApiResponse<dynamic>(
        statusCode: statusCode,
        success: true,
        data: decoded,
        headers: response.headers,
        rawBody: decoded,
      );
    }

    // 3. Handle Error Responses (4xx, 5xx)
    String? message;
    String? errorCode;
    dynamic errorBody;

    if (bodyString.isNotEmpty) {
      try {
        final decoded = jsonDecode(response.body);
        errorBody = decoded;

        if (decoded is Map<String, dynamic>) {
          message = decoded['message'] as String?;
          if (decoded['error'] is Map) {
            final errorMap = decoded['error'] as Map;
            errorCode = errorMap['code']?.toString();
            message ??= errorMap['message']?.toString();
          } else if (decoded['error'] is String) {
            errorCode = decoded['error'] as String?;
          }
          errorCode ??= decoded['code']?.toString();
        }
      } catch (_) {
        // Non-JSON error response (e.g. HTML 502/500 proxy gateway response)
        errorBody = response.body;
      }
    }

    // Fallback safe message without exposing sensitive internals
    message ??= 'HTTP $statusCode: ${response.reasonPhrase ?? 'Request failed'}';

    throw HttpStatusException(
      statusCode: statusCode,
      message: message,
      errorCode: errorCode,
      responseBody: errorBody,
    );
  }
}
