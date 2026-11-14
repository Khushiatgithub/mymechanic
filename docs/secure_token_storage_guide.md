# MyMechanic — Secure Token Storage Guide

Phase 3, Step 4.2 establishes secure local storage and lifecycle management for authentication tokens in the MyMechanic Flutter mobile app.

---

## 1. Where Tokens Are Stored

Tokens are stored using the established [`flutter_secure_storage`](https://pub.dev/packages/flutter_secure_storage) package, backed by platform-native security mechanisms:

- **Android**: Android KeyStore with AES-GCM data encryption and RSA-OAEP key wrapping. Hardware-backed protection (such as TEE or StrongBox) is utilized when supported by the underlying device and chipset; on emulators or devices without hardware keymaster support, Android falls back to software-backed keystore implementations.
- **iOS**: iOS Keychain services with `KeychainAccessibility.first_unlock`.
- **Desktop/Linux/Windows**: Platform secret services (libsecret on Linux, DPAPI on Windows).

> [!IMPORTANT]
> **Android Backup Policy (`android:allowBackup="false"`)**:
> In [`AndroidManifest.xml`](file:///c:/Users/hp/Desktop/mymechanic/android/app/src/main/AndroidManifest.xml), `android:allowBackup="false"` is a deliberate app-wide security configuration. It prevents KeyStore decryption failures caused by restoring data on devices where device-specific keys cannot decrypt backed-up files, and prevents ADB extraction of application data. Developers should note that this affects all application data, not only token storage.

> [!CAUTION]
> Authentication tokens are **NEVER** stored in:
> - `SharedPreferences`
> - Plain text files
> - Source code
> - Logs or debug print statements
> - Analytics events
> - Mock data structures

> [!NOTE]
> Platform Security Model: Secure storage relies on platform-level security mechanisms. It is not "encryption-proof" against a compromised or rooted operating system with kernel-level memory inspection, but it adheres to mobile industry standards for protected credential storage at rest.

---

## 2. Token Storage Service Architecture

The token storage layer consists of three decoupled components:

1. **[`SecureStorageDriver`](file:///c:/Users/hp/Desktop/mymechanic/lib/core/network/secure_storage_driver.dart)**:
   - Low-level key-value interface (`read`, `write`, `delete`, `deleteAll`).
   - Default: `FlutterSecureStorageDriver`.
   - Allows injecting in-memory test doubles without invoking platform channels or hardware keystores during unit tests.

2. **[`TokenStorageService`](file:///c:/Users/hp/Desktop/mymechanic/lib/core/network/token_storage_service.dart)**:
   - High-level token lifecycle manager:
     - `saveAccessToken(String token)`
     - `saveRefreshToken(String token)`
     - `getAccessToken({bool forceRefresh = false})`
     - `getRefreshToken({bool forceRefresh = false})`
     - `deleteAccessToken()`
     - `deleteRefreshToken()`
     - `clearTokens()` (clears both on logout)
   - In-memory synchronization avoids redundant platform channel round-trips during active HTTP calls.
   - Throws typed [`TokenStorageException`](file:///c:/Users/hp/Desktop/mymechanic/lib/core/network/token_storage_service.dart) when operations fail.
   - Diagnostic strings and exception messages **never** include token values.

3. **[`SecureTokenProvider`](file:///c:/Users/hp/Desktop/mymechanic/lib/core/network/token_provider.dart)**:
   - Implements `AuthTokenProvider` and converts into a `TokenProvider` callback.
   - Retrieves the stored access token from `TokenStorageService` and safely passes it to `ApiClient`.
   - Gracefully returns `null` if storage reads fail, preventing crashes on public API endpoints.

---

## 3. How to Use & Inject into `ApiClient`

```dart
import 'package:mymechanic/core/network/api_client.dart';

// 1. Instantiate the token storage service (or inject a custom driver)
final tokenStorage = TokenStorageService();

// 2. Wrap in AuthSessionCoordinator
final coordinator = AuthSessionCoordinator(
  storageService: tokenStorage,
);

// 3. Inject into ApiClient
final apiClient = ApiClient(
  sessionCoordinator: coordinator,
);

// When tokens are saved:
await tokenStorage.saveTokens(
  accessToken: 'jwt.access.token',
  refreshToken: 'jwt.refresh.token',
);

// Any outgoing request will automatically include:
// Authorization: Bearer jwt.access.token
// If the backend returns HTTP 401, ApiClient automatically:
// 1. Invokes coordinator.refreshTokens() using POST /api/v1/auth/refresh
// 2. Rotates both access and refresh tokens into secure storage
// 3. Retries the original request at most once with the new access token
// 4. De-duplicates concurrent 401s so multiple simultaneous requests share 1 refresh call.

// On logout:
await tokenStorage.clearTokens();
```

---

## 4. Current State & What is NOT Yet Implemented

> [!IMPORTANT]
> Step 4.3 establishes the automated authenticated network pipeline. The following are intentionally deferred:
> - **Login / Register / Logout UI**: Screens still use local mock data.
> - **Backend Repository Migration**: Flutter screens have not been connected to live backend endpoints yet.

---

## 5. Token Persistence Atomicity & Rollback Mechanics

Underlying platform key-value stores (Android KeyStore and iOS Keychain) do not provide two-phase transactional atomic commits across multiple keys.
To minimize residual inconsistency during refresh rotation:
1. `TokenStorageService.saveTokens()` writes the new access token first.
2. If writing the refresh token fails, it attempts to roll back the access token to the previous value.
3. In-memory caches are updated only when **both** writes succeed.
4. If a severe platform failure prevents rollback, the coordinator clears credentials on subsequent refresh rejections, preventing infinite retry loops.

---

## 6. Running Automated Tests

To run the offline, deterministic unit tests:

```bash
# Run refresh coordinator & auth interceptor tests (9 tests)
flutter test test/core/network/auth_session_coordinator_test.dart

# Run token storage tests (15 tests)
flutter test test/core/network/token_storage_service_test.dart

# Run API client tests (23 tests)
flutter test test/core/network/api_client_test.dart

# Run full project test suite (80 tests)
flutter test
```
