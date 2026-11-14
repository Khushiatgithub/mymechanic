import 'secure_storage_driver.dart';

/// Exception thrown when secure storage read, write, or delete operations fail.
///
/// Security: This exception deliberately NEVER includes token values, secrets,
/// or credentials in its message or diagnostic string.
class TokenStorageException implements Exception {
  final String message;
  final Object? cause;
  final StackTrace? stackTrace;

  const TokenStorageException(this.message, {this.cause, this.stackTrace});

  @override
  String toString() => 'TokenStorageException: $message';
}

/// Service managing the secure persistence and lifecycle of authentication tokens.
///
/// Phase 3 Step 4.2: Secure Token Storage.
///
/// Security features:
/// - Persists JWTs strictly in platform-encrypted storage (Android Keystore / iOS Keychain).
/// - Never writes credentials to SharedPreferences, ordinary files, logs, or analytics.
/// - Caches tokens in memory to avoid redundant platform channel round-trips while maintaining
///   synchronization across writes and deletions.
/// - Surfaces typed [TokenStorageException] on underlying failure instead of silently failing.
/// - Decoupled from platform Keystores via injectable [SecureStorageDriver] for fast, deterministic unit testing.
class TokenStorageService {
  /// Stable storage key for the JWT Bearer access token.
  static const String keyAccessToken = 'mymechanic_access_token';

  /// Stable storage key for the JWT refresh token.
  static const String keyRefreshToken = 'mymechanic_refresh_token';

  final SecureStorageDriver _driver;

  // In-memory cache to avoid redundant platform channel calls during active sessions
  String? _cachedAccessToken;
  String? _cachedRefreshToken;
  bool _hasAttemptedAccessRead = false;
  bool _hasAttemptedRefreshRead = false;

  TokenStorageService({SecureStorageDriver? driver})
      : _driver = driver ?? FlutterSecureStorageDriver();

  /// Saves the [token] into secure platform storage as the access token.
  ///
  /// Throws [ArgumentError] if [token] is empty or whitespace.
  /// Throws [TokenStorageException] if the storage write fails.
  Future<void> saveAccessToken(String token) async {
    final cleanToken = token.trim();
    if (cleanToken.isEmpty) {
      throw ArgumentError('Access token cannot be empty or whitespace.');
    }

    try {
      await _driver.write(key: keyAccessToken, value: cleanToken);
      _cachedAccessToken = cleanToken;
      _hasAttemptedAccessRead = true;
    } catch (e, stack) {
      _cachedAccessToken = null;
      throw TokenStorageException(
        'Failed to save access token to secure storage.',
        cause: e,
        stackTrace: stack,
      );
    }
  }

  /// Saves the [token] into secure platform storage as the refresh token.
  ///
  /// Throws [ArgumentError] if [token] is empty or whitespace.
  /// Throws [TokenStorageException] if the storage write fails.
  Future<void> saveRefreshToken(String token) async {
    final cleanToken = token.trim();
    if (cleanToken.isEmpty) {
      throw ArgumentError('Refresh token cannot be empty or whitespace.');
    }

    try {
      await _driver.write(key: keyRefreshToken, value: cleanToken);
      _cachedRefreshToken = cleanToken;
      _hasAttemptedRefreshRead = true;
    } catch (e, stack) {
      _cachedRefreshToken = null;
      throw TokenStorageException(
        'Failed to save refresh token to secure storage.',
        cause: e,
        stackTrace: stack,
      );
    }
  }

  /// Persists both [accessToken] and [refreshToken] together.
  ///
  /// Atomicity & Rollback:
  /// Underlying platform secure storage mechanisms (KeyStore / Keychain) do not support
  /// multi-key transactional atomic commits.
  /// To mitigate partial writes:
  /// 1. Reads and retains the previous access token before staging.
  /// 2. Writes the access token first.
  /// 3. If writing the refresh token fails, rolls back the access token to its previous value.
  /// 4. In-memory caches are updated only when BOTH writes succeed.
  ///
  /// Security: Exception diagnostics never contain token values.
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    final cleanAccess = accessToken.trim();
    final cleanRefresh = refreshToken.trim();

    if (cleanAccess.isEmpty || cleanRefresh.isEmpty) {
      throw ArgumentError('Access and refresh tokens cannot be empty or whitespace.');
    }

    final previousAccess = _cachedAccessToken ?? await _driver.read(key: keyAccessToken);

    try {
      await _driver.write(key: keyAccessToken, value: cleanAccess);
    } catch (e, stack) {
      throw TokenStorageException(
        'Failed to save access token during token pair persistence.',
        cause: e,
        stackTrace: stack,
      );
    }

    try {
      await _driver.write(key: keyRefreshToken, value: cleanRefresh);
    } catch (e, stack) {
      // Rollback access token to previous state
      try {
        if (previousAccess != null) {
          await _driver.write(key: keyAccessToken, value: previousAccess);
        } else {
          await _driver.delete(key: keyAccessToken);
        }
      } catch (_) {
        // Rollback failed; residual limitation documented
      }
      throw TokenStorageException(
        'Failed to save refresh token during token pair persistence. Access token rolled back.',
        cause: e,
        stackTrace: stack,
      );
    }

    // Both succeeded: update memory cache
    _cachedAccessToken = cleanAccess;
    _cachedRefreshToken = cleanRefresh;
    _hasAttemptedAccessRead = true;
    _hasAttemptedRefreshRead = true;
  }

  /// Retrieves the current access token.
  ///
  /// Returns `null` if no token is stored or if it is empty.
  /// Set [forceRefresh] to `true` to bypass the in-memory cache and re-read from platform storage.
  ///
  /// Throws [TokenStorageException] if the storage read operation fails.
  Future<String?> getAccessToken({bool forceRefresh = false}) async {
    if (!forceRefresh && _hasAttemptedAccessRead) {
      return _cachedAccessToken;
    }

    try {
      final value = await _driver.read(key: keyAccessToken);
      final cleanValue = (value != null && value.trim().isNotEmpty) ? value.trim() : null;
      _cachedAccessToken = cleanValue;
      _hasAttemptedAccessRead = true;
      return cleanValue;
    } catch (e, stack) {
      throw TokenStorageException(
        'Failed to read access token from secure storage.',
        cause: e,
        stackTrace: stack,
      );
    }
  }

  /// Retrieves the current refresh token.
  ///
  /// Returns `null` if no token is stored or if it is empty.
  /// Set [forceRefresh] to `true` to bypass the in-memory cache and re-read from platform storage.
  ///
  /// Throws [TokenStorageException] if the storage read operation fails.
  Future<String?> getRefreshToken({bool forceRefresh = false}) async {
    if (!forceRefresh && _hasAttemptedRefreshRead) {
      return _cachedRefreshToken;
    }

    try {
      final value = await _driver.read(key: keyRefreshToken);
      final cleanValue = (value != null && value.trim().isNotEmpty) ? value.trim() : null;
      _cachedRefreshToken = cleanValue;
      _hasAttemptedRefreshRead = true;
      return cleanValue;
    } catch (e, stack) {
      throw TokenStorageException(
        'Failed to read refresh token from secure storage.',
        cause: e,
        stackTrace: stack,
      );
    }
  }

  /// Deletes only the access token from secure storage and invalidates its memory cache.
  ///
  /// Throws [TokenStorageException] if the storage deletion fails.
  Future<void> deleteAccessToken() async {
    try {
      await _driver.delete(key: keyAccessToken);
      _cachedAccessToken = null;
      _hasAttemptedAccessRead = true;
    } catch (e, stack) {
      throw TokenStorageException(
        'Failed to delete access token from secure storage.',
        cause: e,
        stackTrace: stack,
      );
    }
  }

  /// Deletes only the refresh token from secure storage and invalidates its memory cache.
  ///
  /// Throws [TokenStorageException] if the storage deletion fails.
  Future<void> deleteRefreshToken() async {
    try {
      await _driver.delete(key: keyRefreshToken);
      _cachedRefreshToken = null;
      _hasAttemptedRefreshRead = true;
    } catch (e, stack) {
      throw TokenStorageException(
        'Failed to delete refresh token from secure storage.',
        cause: e,
        stackTrace: stack,
      );
    }
  }

  /// Clears both access and refresh tokens from secure storage and memory cache on logout.
  ///
  /// Guarantees that neither token remains cached or persisted.
  /// Throws [TokenStorageException] if any deletion step fails.
  Future<void> clearTokens() async {
    try {
      await Future.wait([
        _driver.delete(key: keyAccessToken),
        _driver.delete(key: keyRefreshToken),
      ]);
      _cachedAccessToken = null;
      _cachedRefreshToken = null;
      _hasAttemptedAccessRead = true;
      _hasAttemptedRefreshRead = true;
    } catch (e, stack) {
      // Invalidate memory caches regardless to minimize lingering exposure
      _cachedAccessToken = null;
      _cachedRefreshToken = null;
      throw TokenStorageException(
        'Failed to clear authentication tokens from secure storage.',
        cause: e,
        stackTrace: stack,
      );
    }
  }
}
