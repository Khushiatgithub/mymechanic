/// Token Provider interface, callback, and secure storage adapter.
///
/// Phase 3 Step 4.2: Secure Token Storage.
///
/// Enables seamless injection of secure access tokens into [ApiClient]
/// without coupling network callers to concrete platform Keystores.
library;

import 'token_storage_service.dart';

/// Function callback signature for retrieving an access token asynchronously.
///
/// Returns null or an empty string when the user is not authenticated.
typedef TokenProvider = Future<String?> Function();

/// Optional interface contract for token providers.
abstract interface class AuthTokenProvider {
  /// Retrieves the active Bearer access token, or null if unauthenticated.
  Future<String?> getAccessToken();
}

/// Production implementation of [AuthTokenProvider] backed by [TokenStorageService].
///
/// Automatically retrieves the stored JWT Bearer access token from encrypted
/// platform storage. Can be passed directly or via [toTokenProvider] into [ApiClient].
class SecureTokenProvider implements AuthTokenProvider {
  final TokenStorageService _storageService;

  SecureTokenProvider({TokenStorageService? storageService})
      : _storageService = storageService ?? TokenStorageService();

  @override
  Future<String?> getAccessToken() async {
    try {
      return await _storageService.getAccessToken();
    } catch (_) {
      // In the event of a storage read error, gracefully return null
      // so unauthenticated endpoints still function normally.
      return null;
    }
  }

  /// Convenience getter returning the [TokenProvider] function callback.
  TokenProvider get toTokenProvider => getAccessToken;
}
