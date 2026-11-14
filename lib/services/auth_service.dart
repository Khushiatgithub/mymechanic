import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../core/network/api_client.dart';
import '../models/auth_user.dart';

/// Exception thrown for client-side authentication validation failures.
class AuthValidationException implements Exception {
  final String message;
  final String? field;

  const AuthValidationException(this.message, {this.field});

  @override
  String toString() => message;
}

/// Result of an intentional user logout operation.
class LogoutResult {
  /// Whether the backend server confirmed session revocation.
  final bool serverRevoked;

  /// Optional error description if the server-side revocation request failed.
  final String? serverError;

  const LogoutResult({
    required this.serverRevoked,
    this.serverError,
  });
}

/// Represents the customer authentication and session verification state.
enum AuthStatus {
  /// Guest: No credentials exist or session was definitively rejected.
  unauthenticated,

  /// Restoration pending: Verification with backend is currently in progress.
  restoring,

  /// Restoration pending / offline: Credentials exist locally, but identity could not
  /// currently be verified with the server due to a network outage, timeout, or server error.
  /// Stored credentials are preserved, while app operates safely in guest browsing mode.
  offline,

  /// Authenticated: Server has successfully verified credentials and customer identity.
  authenticated,
}

/// Authentication service managing customer registration, login, profile retrieval,
/// and secure session lifecycle.
///
/// Phase 3 Step 4.5: Session Restoration & Lifecycle Reliability.
///
/// Architecture & Security:
/// 1. Reuses [ApiClient] with automated [AuthSessionCoordinator] refresh interception.
/// 2. Persists rotated tokens strictly in hardware/keystore-backed [TokenStorageService].
/// 3. Never logs credentials, passwords, or tokens.
/// 4. Provides reactive state via [currentUserNotifier], [isAuthenticatedNotifier],
///    and [authStatusNotifier].
class AuthService {
  final ApiClient apiClient;
  final TokenStorageService storageService;
  final AuthSessionCoordinator? sessionCoordinator;

  final ValueNotifier<AuthUser?> currentUserNotifier = ValueNotifier<AuthUser?>(null);
  final ValueNotifier<bool> isAuthenticatedNotifier = ValueNotifier<bool>(false);
  final ValueNotifier<bool> isInitializingNotifier = ValueNotifier<bool>(false);
  final ValueNotifier<AuthStatus> authStatusNotifier = ValueNotifier<AuthStatus>(AuthStatus.unauthenticated);

  AuthUser? get currentUser => currentUserNotifier.value;
  bool get isAuthenticated => authStatus == AuthStatus.authenticated;
  bool get isInitializing => isInitializingNotifier.value;
  AuthStatus get authStatus => authStatusNotifier.value;
  bool get isGuest => authStatus == AuthStatus.unauthenticated;
  bool get isOfflineSession => authStatus == AuthStatus.offline;

  Future<bool>? _inFlightInitialization;
  int _actionSequence = 0;

  static AuthService? _instance;

  /// Global access point for the application.
  static AuthService get instance => _instance ??= createDefault();

  /// Inject custom service instance for unit and widget tests.
  static set instance(AuthService service) => _instance = service;

  AuthService({
    required this.apiClient,
    required this.storageService,
    this.sessionCoordinator,
  });

  /// Factory creating standard production or testing AuthService with full stack dependencies.
  static AuthService createDefault({
    String? baseUrl,
    http.Client? client,
    SecureStorageDriver? storageDriver,
  }) {
    final storageService = TokenStorageService(driver: storageDriver);
    final coordinator = AuthSessionCoordinator(
      storageService: storageService,
      baseUrl: baseUrl,
      client: client,
    );
    final tokenProvider = SecureTokenProvider(storageService: storageService);
    final apiClient = ApiClient(
      baseUrl: baseUrl,
      client: client,
      tokenProvider: tokenProvider.toTokenProvider,
      sessionCoordinator: coordinator,
    );

    return AuthService(
      apiClient: apiClient,
      storageService: storageService,
      sessionCoordinator: coordinator,
    );
  }

  void _setAuthStatus(AuthStatus status, {AuthUser? user, int? sequence}) {
    if (sequence != null && sequence != _actionSequence) return;
    if (status == AuthStatus.authenticated) {
      if (user != null) {
        currentUserNotifier.value = user;
      }
    } else {
      currentUserNotifier.value = null;
    }
    isAuthenticatedNotifier.value = (status == AuthStatus.authenticated);
    authStatusNotifier.value = status;
  }

  /// Initializes the service by inspecting stored tokens and verifying the user profile.
  ///
  /// Concurrency & Safety:
  /// - Deduplicates concurrent calls via [_inFlightInitialization].
  /// - Guards against race conditions (e.g. login/logout while initialization is in flight)
  ///   using sequence generation tracking [_actionSequence].
  /// - Offline safety: If tokens exist but the server is unreachable (network, timeout, 5xx),
  ///   credentials are preserved while status becomes [AuthStatus.offline].
  ///   The app does NOT prematurely treat an unverified session as authenticated.
  /// - Definitive failure: If the refresh token is rejected, invalid credentials are wiped.
  Future<bool> initialize() async {
    if (_inFlightInitialization != null) {
      return _inFlightInitialization!;
    }
    final future = _performInitialization();
    _inFlightInitialization = future;
    try {
      return await future;
    } finally {
      _inFlightInitialization = null;
    }
  }

  Future<bool> _performInitialization() async {
    final startSeq = ++_actionSequence;
    isInitializingNotifier.value = true;
    _setAuthStatus(AuthStatus.restoring, sequence: startSeq);

    try {
      final token = await storageService.getAccessToken();
      final refresh = await storageService.getRefreshToken();
      if ((token == null || token.isEmpty) && (refresh == null || refresh.isEmpty)) {
        _setAuthStatus(AuthStatus.unauthenticated, sequence: startSeq);
        return false;
      }

      // Stored credentials exist, but user is NOT yet authenticated until verified by server
      try {
        final user = await getCurrentUser(actionSequence: startSeq);
        _setAuthStatus(AuthStatus.authenticated, user: user, sequence: startSeq);
        return true;
      } on NetworkException {
        // Network outage: credentials preserved, identity unverified -> offline state
        _setAuthStatus(AuthStatus.offline, sequence: startSeq);
        return false;
      } on ApiTimeoutException {
        // Network timeout: credentials preserved, identity unverified -> offline state
        _setAuthStatus(AuthStatus.offline, sequence: startSeq);
        return false;
      } on HttpStatusException catch (e) {
        if (e.statusCode >= 500) {
          // Server error: credentials preserved, identity unverified -> offline state
          _setAuthStatus(AuthStatus.offline, sequence: startSeq);
          return false;
        }
        // Non-5xx client failure not caught by coordinator
        _setAuthStatus(AuthStatus.unauthenticated, sequence: startSeq);
        return false;
      } on AuthSessionException {
        // Session definitively invalid: Reset state and purge tokens
        if (startSeq == _actionSequence) {
          await storageService.clearTokens();
          _setAuthStatus(AuthStatus.unauthenticated, sequence: startSeq);
        }
        return false;
      } catch (_) {
        _setAuthStatus(AuthStatus.offline, sequence: startSeq);
        return false;
      }
    } finally {
      if (startSeq == _actionSequence) {
        isInitializingNotifier.value = false;
      }
    }
  }

  /// Registers a new customer with the backend.
  ///
  /// Required fields: [name], [email], [password] (>= 8 chars).
  /// Optional field: [phone] (10-15 digits).
  Future<AuthUser> register({
    required String name,
    required String email,
    required String password,
    String? phone,
  }) async {
    final startSeq = ++_actionSequence;
    final cleanName = name.trim();
    final cleanEmail = email.trim().toLowerCase();
    final cleanPhone = phone?.trim();

    // Client-side validation matching backend rules
    if (cleanName.isEmpty) {
      throw const AuthValidationException('Full name is required.', field: 'name');
    }
    if (cleanName.length > 100) {
      throw const AuthValidationException('Name cannot exceed 100 characters.', field: 'name');
    }
    if (cleanEmail.isEmpty || !_isValidEmail(cleanEmail)) {
      throw const AuthValidationException('Please provide a valid email address.', field: 'email');
    }
    if (password.length < 8) {
      throw const AuthValidationException('Password must be at least 8 characters long.', field: 'password');
    }
    if (cleanPhone != null && cleanPhone.isNotEmpty && !_isValidPhone(cleanPhone)) {
      throw const AuthValidationException('Please provide a valid phone number (10-15 digits).', field: 'phone');
    }

    final payload = <String, dynamic>{
      'name': cleanName,
      'email': cleanEmail,
      'password': password,
      if (cleanPhone != null && cleanPhone.isNotEmpty) 'phone': cleanPhone,
    };

    final response = await apiClient.post('/auth/register', body: payload);

    final data = response.data;
    if (data is! Map<String, dynamic>) {
      throw const AuthSessionException('Malformed registration response payload.', errorCode: 'MALFORMED_RESPONSE');
    }

    final userMap = data['user'] as Map<String, dynamic>?;
    final accessToken = data['accessToken'] as String?;
    final refreshToken = data['refreshToken'] as String?;

    if (userMap == null ||
        accessToken == null ||
        accessToken.trim().isEmpty ||
        refreshToken == null ||
        refreshToken.trim().isEmpty) {
      throw const AuthSessionException('Incomplete registration authentication payload.', errorCode: 'INCOMPLETE_PAYLOAD');
    }

    // Persist session tokens only after rigorous response validation
    await storageService.saveTokens(
      accessToken: accessToken,
      refreshToken: refreshToken,
    );

    final user = AuthUser.fromJson(userMap);
    _setAuthStatus(AuthStatus.authenticated, user: user, sequence: startSeq);
    return user;
  }

  /// Logs in an existing customer using [email] and [password].
  Future<AuthUser> login({
    required String email,
    required String password,
  }) async {
    final startSeq = ++_actionSequence;
    final cleanEmail = email.trim().toLowerCase();

    if (cleanEmail.isEmpty || !_isValidEmail(cleanEmail)) {
      throw const AuthValidationException('Please enter a valid email address.', field: 'email');
    }
    if (password.isEmpty) {
      throw const AuthValidationException('Password is required.', field: 'password');
    }

    final response = await apiClient.post(
      '/auth/login',
      body: {
        'email': cleanEmail,
        'password': password,
      },
    );

    final data = response.data;
    if (data is! Map<String, dynamic>) {
      throw const AuthSessionException('Malformed login response payload.', errorCode: 'MALFORMED_RESPONSE');
    }

    final userMap = data['user'] as Map<String, dynamic>?;
    final accessToken = data['accessToken'] as String?;
    final refreshToken = data['refreshToken'] as String?;

    if (userMap == null ||
        accessToken == null ||
        accessToken.trim().isEmpty ||
        refreshToken == null ||
        refreshToken.trim().isEmpty) {
      throw const AuthSessionException('Incomplete login response payload.', errorCode: 'INCOMPLETE_PAYLOAD');
    }

    // Persist verified session credentials
    await storageService.saveTokens(
      accessToken: accessToken,
      refreshToken: refreshToken,
    );

    final user = AuthUser.fromJson(userMap);
    _setAuthStatus(AuthStatus.authenticated, user: user, sequence: startSeq);
    return user;
  }

  /// Retrieves the current authenticated user profile from `/auth/me`.
  Future<AuthUser> getCurrentUser({int? actionSequence}) async {
    final response = await apiClient.get('/auth/me');

    final data = response.data;
    if (data is! Map<String, dynamic>) {
      throw const AuthSessionException('Invalid profile response payload.', errorCode: 'MALFORMED_RESPONSE');
    }

    final user = AuthUser.fromJson(data);
    _setAuthStatus(AuthStatus.authenticated, user: user, sequence: actionSequence);
    return user;
  }

  /// Logs out the user.
  ///
  /// Safe logout contract:
  /// 1. Attempts remote refresh-token revocation via `POST /auth/logout` first.
  /// 2. ALWAYS clears local credentials and resets reactive user state upon confirmation,
  ///    even if the remote revocation encounters an outage or server error.
  /// 3. Returns a [LogoutResult] so the UI can communicate an honest status to the customer:
  ///    whether server-side revocation was confirmed or if local session clearing completed
  ///    with an unconfirmed remote revocation.
  Future<LogoutResult> logout() async {
    final startSeq = ++_actionSequence;
    final refreshToken = await storageService.getRefreshToken();
    bool serverRevoked = false;
    String? serverError;

    try {
      await apiClient.post(
        '/auth/logout',
        body: refreshToken != null ? {'refreshToken': refreshToken} : null,
      );
      serverRevoked = true;
    } catch (e) {
      serverRevoked = false;
      serverError = getErrorMessage(e);
    } finally {
      // Local session is ALWAYS cleared when logout is confirmed by the customer
      await storageService.clearTokens();
      _setAuthStatus(AuthStatus.unauthenticated, sequence: startSeq);
    }

    return LogoutResult(
      serverRevoked: serverRevoked,
      serverError: serverError,
    );
  }

  /// Clears stored credentials locally without sending an API logout request.
  /// Useful for offline or client-initiated resets.
  Future<void> clearLocalSession() async {
    _actionSequence++;
    await storageService.clearTokens();
    _setAuthStatus(AuthStatus.unauthenticated);
  }

  /// Converts any thrown exception into a safe, customer-friendly error message.
  static String getErrorMessage(Object error) {
    if (error is AuthValidationException) {
      return error.message;
    }

    if (error is HttpStatusException) {
      if (error.statusCode == 401) {
        if (error.errorCode == 'INVALID_CREDENTIALS') {
          return 'Invalid email or password. Please check your credentials and try again.';
        }
        return 'Authentication failed. Please check your credentials.';
      }
      if (error.statusCode == 409) {
        if (error.errorCode == 'EMAIL_ALREADY_EXISTS') {
          return 'An account with this email address already exists. Please log in instead.';
        }
        if (error.errorCode == 'PHONE_ALREADY_EXISTS') {
          return 'An account with this phone number already exists.';
        }
        return error.message.isNotEmpty ? error.message : 'An account with this detail already exists.';
      }
      if (error.statusCode == 400) {
        return error.message.isNotEmpty ? error.message : 'Please check the information you entered.';
      }
      if (error.statusCode == 429) {
        return 'Too many attempts. Please wait 15 minutes before trying again.';
      }
      if (error.statusCode >= 500) {
        return 'The server encountered an error. Please try again later.';
      }
      return error.message.isNotEmpty ? error.message : 'An error occurred (${error.statusCode}).';
    }

    if (error is NetworkException) {
      return 'Unable to connect to MyMechanic servers. Please check your internet connection.';
    }

    if (error is ApiTimeoutException) {
      return 'Connection timed out. Please check your connection and try again.';
    }

    if (error is AuthSessionException) {
      return 'Your session has expired. Please log in again.';
    }

    return 'An unexpected error occurred. Please try again later.';
  }

  static bool _isValidEmail(String email) {
    final emailRegex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
    return emailRegex.hasMatch(email);
  }

  static bool _isValidPhone(String phone) {
    final phoneRegex = RegExp(r'^\+?[0-9]{10,15}$');
    return phoneRegex.hasMatch(phone.replaceAll(RegExp(r'[-\s]'), ''));
  }
}
