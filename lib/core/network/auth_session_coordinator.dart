import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import 'api_exception.dart';
import 'token_storage_service.dart';

/// Coordinates authentication token lifecycle, concurrent 401 refresh de-duplication,
/// and automated credential revocation on session expiry.
///
/// Phase 3 Step 4.3: Refresh Token Rotation & Authenticated Interceptor.
///
/// Key design features:
/// 1. Single in-flight refresh synchronization prevents duplicate submissions of rotated refresh tokens.
/// 2. Strict eligibility checking guarantees that refresh, login, and registration requests never trigger recursive loops.
/// 3. Validates rotated token payloads before committing to secure storage.
/// 4. Automatic credentials revocation: Clears local tokens on invalid/reused refresh sessions.
/// 5. Zero sensitive credential or token logging.
class AuthSessionCoordinator {
  final TokenStorageService storageService;
  final String _baseUrl;
  final http.Client _client;
  final bool _ownsClient;

  // Synchronization future ensuring multiple concurrent 401s share a single refresh operation
  Future<void>? _inFlightRefresh;

  AuthSessionCoordinator({
    required this.storageService,
    String? baseUrl,
    http.Client? client,
  })  : _baseUrl = ApiConfig.resolveBaseUrl(baseUrl),
        _client = client ?? http.Client(),
        _ownsClient = client == null;

  /// Checks whether an API path is eligible for automated 401 token refresh.
  ///
  /// Prevents infinite recursive loops by disqualifying the refresh endpoint itself
  /// as well as authentication gateway routes (login, register).
  bool isEligibleForRefresh(String path) {
    final clean = path.trim().toLowerCase();
    if (clean.contains('/auth/refresh') ||
        clean == 'auth/refresh' ||
        clean.contains('/auth/login') ||
        clean.contains('/auth/register')) {
      return false;
    }
    return true;
  }

  /// Canonical set of error codes emitted by the backend when a refresh session
  /// is definitively rejected, expired, revoked, or the user account is deactivated.
  ///
  /// Matches the exact backend error codes from [AuthService.refreshTokens] and [verifyRefreshToken]:
  /// - `INVALID_REFRESH_TOKEN`: Bad signature, wrong type, or session not found in DB
  /// - `REFRESH_TOKEN_EXPIRED`: JWT expired or DB session expiration exceeded
  /// - `TOKEN_REUSE_DETECTED`: Revoked session reused; immediate revocation of all sessions
  /// - `UNAUTHORIZED`: Account is deactivated or user no longer exists
  ///
  /// Note: `MISSING_REFRESH_TOKEN` (HTTP 400) is a payload/formatting error and does NOT
  /// indicate an invalid session; stored credentials must be preserved.
  static const Set<String> definitiveRejectionCodes = {
    'INVALID_REFRESH_TOKEN',
    'REFRESH_TOKEN_EXPIRED',
    'TOKEN_REUSE_DETECTED',
    'UNAUTHORIZED',
  };

  /// Evaluates whether an HTTP status and error code from the refresh endpoint
  /// indicate an irrecoverable session invalidation that necessitates credential deletion.
  static bool isDefinitiveSessionRejection(int statusCode, String? errorCode) {
    final code = errorCode?.toUpperCase();

    // 1. Any response carrying a confirmed definitive error code warrants clearing tokens
    if (code != null && definitiveRejectionCodes.contains(code)) {
      return true;
    }

    // 2. HTTP 401 from the refresh endpoint:
    // If the response is HTTP 401 without an explicit error code, it represents a standard
    // backend 401 rejection. If an explicit foreign error code is present (such as proxy
    // or rate-limit codes), it is not considered definitive and credentials are preserved.
    if (statusCode == 401) {
      if (code == null) {
        return true;
      }
      return definitiveRejectionCodes.contains(code);
    }

    // 3. All other status codes (400 without definitive code, 5xx, etc.) do NOT clear credentials
    return false;
  }

  /// Refreshes the session using the stored refresh token.
  ///
  /// Concurrency: If a refresh is already in progress, concurrent callers await
  /// the active operation rather than submitting the same refresh token again.
  /// This prevents the backend's `TOKEN_REUSE_DETECTED` mechanism from revoking
  /// active user sessions.
  Future<void> refreshTokens() async {
    // Share existing in-flight refresh if underway
    if (_inFlightRefresh != null) {
      await _inFlightRefresh;
      return;
    }

    final completer = Completer<void>();
    // Prevent unhandled asynchronous zone error if no concurrent caller was awaiting this future
    completer.future.ignore();
    _inFlightRefresh = completer.future;

    try {
      await _performRefresh();
      completer.complete();
    } catch (e, stack) {
      completer.completeError(e, stack);
      rethrow;
    } finally {
      _inFlightRefresh = null;
    }
  }

  Future<void> _performRefresh() async {
    final currentRefreshToken = await storageService.getRefreshToken();
    if (currentRefreshToken == null || currentRefreshToken.isEmpty) {
      throw const AuthSessionException(
        'Cannot refresh session: No refresh token found in secure storage.',
        errorCode: 'NO_REFRESH_TOKEN',
      );
    }

    final refreshUri = Uri.parse('$_baseUrl/auth/refresh');
    final requestBody = jsonEncode({'refreshToken': currentRefreshToken});

    http.Response response;
    try {
      response = await _client.post(
        refreshUri,
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: requestBody,
      ).timeout(ApiConfig.defaultTimeout);
    } on TimeoutException catch (e, stack) {
      throw ApiTimeoutException(
        'Refresh request timed out.',
        timeout: ApiConfig.defaultTimeout,
        cause: e,
        stackTrace: stack,
      );
    } catch (e, stack) {
      throw NetworkException(
        'Failed to connect to refresh endpoint: $e',
        cause: e,
        stackTrace: stack,
      );
    }

    // Handle non-200 responses
    if (response.statusCode != 200) {
      String? errorCode;
      String? message;

      try {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) {
          message = decoded['message'] as String?;
          if (decoded['error'] is Map) {
            errorCode = decoded['error']['code']?.toString();
          }
          errorCode ??= decoded['code']?.toString();
        }
      } catch (_) {}

      // Invalidate credentials only on confirmed definitive session rejection
      if (isDefinitiveSessionRejection(response.statusCode, errorCode)) {
        try {
          await storageService.clearTokens();
        } catch (_) {}
      }

      throw AuthSessionException(
        message ?? 'Session refresh failed with HTTP ${response.statusCode}.',
        errorCode: errorCode ?? 'REFRESH_FAILED',
      );
    }

    // Parse and validate 200 response
    dynamic decoded;
    try {
      decoded = jsonDecode(response.body);
    } catch (e, stack) {
      throw ApiResponseFormatException(
        'Invalid JSON received from refresh endpoint.',
        rawBody: response.body,
        cause: e,
        stackTrace: stack,
      );
    }

    if (decoded is! Map<String, dynamic> || !decoded.containsKey('data')) {
      throw const AuthSessionException(
        'Invalid refresh response: missing data envelope.',
        errorCode: 'MALFORMED_REFRESH_RESPONSE',
      );
    }

    final data = decoded['data'];
    if (data is! Map<String, dynamic>) {
      throw const AuthSessionException(
        'Invalid refresh response: data payload is not a JSON object.',
        errorCode: 'MALFORMED_REFRESH_RESPONSE',
      );
    }

    final newAccessToken = data['accessToken'] as String?;
    final newRefreshToken = data['refreshToken'] as String?;

    if (newAccessToken == null ||
        newAccessToken.trim().isEmpty ||
        newRefreshToken == null ||
        newRefreshToken.trim().isEmpty) {
      throw const AuthSessionException(
        'Refresh response missing required accessToken or refreshToken.',
        errorCode: 'INCOMPLETE_TOKENS',
      );
    }

    // Persist both rotated tokens together
    await storageService.saveTokens(
      accessToken: newAccessToken,
      refreshToken: newRefreshToken,
    );
  }

  /// Closes underlying HTTP client if internally managed.
  void close() {
    if (_ownsClient) {
      _client.close();
    }
  }
}
