import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mymechanic/core/network/api_client.dart';

/// In-memory test fake for [SecureStorageDriver].
class FakeSecureStorageDriver implements SecureStorageDriver {
  final Map<String, String> storage = {};
  bool throwOnRefreshTokenWrite = false;

  @override
  Future<String?> read({required String key}) async => storage[key];

  @override
  Future<void> write({required String key, required String value}) async {
    if (key == TokenStorageService.keyRefreshToken && throwOnRefreshTokenWrite) {
      throw Exception('Simulated KeyStore failure during refresh token write');
    }
    storage[key] = value;
  }

  @override
  Future<void> delete({required String key}) async {
    storage.remove(key);
  }

  @override
  Future<void> deleteAll() async {
    storage.clear();
  }
}

void main() {
  const testBaseUrl = 'http://127.0.0.1:5000/api/v1';
  late FakeSecureStorageDriver fakeDriver;
  late TokenStorageService storageService;

  setUp(() {
    fakeDriver = FakeSecureStorageDriver();
    storageService = TokenStorageService(driver: fakeDriver);
  });

  group('Authenticated Requests & Unauthenticated Fallback', () {
    test('Stored access token is attached as Authorization Bearer header', () async {
      await storageService.saveTokens(
        accessToken: 'valid_access_token_abc',
        refreshToken: 'valid_refresh_token_def',
      );

      String? capturedAuthHeader;
      final mockClient = MockClient((request) async {
        capturedAuthHeader = request.headers['Authorization'];
        return http.Response('{"success": true, "data": {"id": "user_1"}}', 200);
      });

      final coordinator = AuthSessionCoordinator(
        storageService: storageService,
        baseUrl: testBaseUrl,
        client: mockClient,
      );

      final apiClient = ApiClient(
        baseUrl: testBaseUrl,
        client: mockClient,
        sessionCoordinator: coordinator,
      );

      final response = await apiClient.get('/users/me');

      expect(response.statusCode, equals(200));
      expect(capturedAuthHeader, equals('Bearer valid_access_token_abc'));
    });

    test('Missing token permits unauthenticated requests without Authorization header', () async {
      String? capturedAuthHeader;
      final mockClient = MockClient((request) async {
        capturedAuthHeader = request.headers['Authorization'];
        return http.Response('{"success": true, "message": "healthy"}', 200);
      });

      final coordinator = AuthSessionCoordinator(
        storageService: storageService,
        baseUrl: testBaseUrl,
        client: mockClient,
      );

      final apiClient = ApiClient(
        baseUrl: testBaseUrl,
        client: mockClient,
        sessionCoordinator: coordinator,
      );

      final response = await apiClient.get('/health');

      expect(response.statusCode, equals(200));
      expect(capturedAuthHeader, isNull);
    });
  });

  group('Automated 401 Refresh & Single Retry Flow', () {
    test('401 triggers one refresh, rotates both tokens, and retries original request successfully', () async {
      await storageService.saveTokens(
        accessToken: 'expired_access_token',
        refreshToken: 'valid_refresh_token_old',
      );

      int protectedCallCount = 0;
      int refreshCallCount = 0;
      final capturedHeaders = <String?>[];

      final mockClient = MockClient((request) async {
        if (request.url.path.contains('/users/me')) {
          protectedCallCount++;
          capturedHeaders.add(request.headers['Authorization']);

          // First call receives 401 expired token
          if (protectedCallCount == 1) {
            return http.Response(
              jsonEncode({
                'success': false,
                'message': 'Token has expired',
                'error': {'code': 'TOKEN_EXPIRED'},
              }),
              401,
            );
          }

          // Retried call with new token succeeds
          return http.Response(
            jsonEncode({
              'success': true,
              'data': {'id': 'user_123', 'name': 'Verified User'},
            }),
            200,
          );
        }

        if (request.url.path.contains('/auth/refresh')) {
          refreshCallCount++;
          final body = jsonDecode(request.body) as Map<String, dynamic>;
          expect(body['refreshToken'], equals('valid_refresh_token_old'));

          return http.Response(
            jsonEncode({
              'success': true,
              'message': 'Tokens refreshed successfully',
              'data': {
                'accessToken': 'fresh_rotated_access_token',
                'refreshToken': 'fresh_rotated_refresh_token',
              },
            }),
            200,
          );
        }

        return http.Response('Not Found', 404);
      });

      final coordinator = AuthSessionCoordinator(
        storageService: storageService,
        baseUrl: testBaseUrl,
        client: mockClient,
      );

      final apiClient = ApiClient(
        baseUrl: testBaseUrl,
        client: mockClient,
        sessionCoordinator: coordinator,
      );

      final response = await apiClient.get('/users/me');

      // Assertions
      expect(response.statusCode, equals(200));
      expect(response.data['name'], equals('Verified User'));
      expect(protectedCallCount, equals(2)); // Original 401 + 1 retry
      expect(refreshCallCount, equals(1));   // Exactly 1 refresh

      // Verify token progression in headers
      expect(capturedHeaders[0], equals('Bearer expired_access_token'));
      expect(capturedHeaders[1], equals('Bearer fresh_rotated_access_token'));

      // Verify storage holds the newly rotated pair
      expect(await storageService.getAccessToken(), equals('fresh_rotated_access_token'));
      expect(await storageService.getRefreshToken(), equals('fresh_rotated_refresh_token'));
    });

    test('Refresh endpoint failure (401 invalid refresh session) clears local credentials and surfaces AuthSessionException', () async {
      await storageService.saveTokens(
        accessToken: 'expired_access_token',
        refreshToken: 'invalid_refresh_token',
      );

      final mockClient = MockClient((request) async {
        if (request.url.path.contains('/users/me')) {
          return http.Response('{"message": "Unauthorized"}', 401);
        }

        if (request.url.path.contains('/auth/refresh')) {
          return http.Response(
            jsonEncode({
              'success': false,
              'message': 'Invalid refresh session. Please log in again.',
              'error': {'code': 'INVALID_REFRESH_TOKEN'},
            }),
            401,
          );
        }

        return http.Response('Not Found', 404);
      });

      final coordinator = AuthSessionCoordinator(
        storageService: storageService,
        baseUrl: testBaseUrl,
        client: mockClient,
      );

      final apiClient = ApiClient(
        baseUrl: testBaseUrl,
        client: mockClient,
        sessionCoordinator: coordinator,
      );

      await expectLater(
        apiClient.get('/users/me'),
        throwsA(
          isA<AuthSessionException>()
              .having((e) => e.errorCode, 'errorCode', 'INVALID_REFRESH_TOKEN')
              .having((e) => e.message, 'message', contains('Invalid refresh session')),
        ),
      );

      // Verify credentials were wiped on definitive 401 session rejection
      expect(await storageService.getAccessToken(), isNull);
      expect(await storageService.getRefreshToken(), isNull);
    });

    test('Temporary network outage during refresh surfaces NetworkException without wiping stored credentials', () async {
      await storageService.saveTokens(
        accessToken: 'expired_access_token',
        refreshToken: 'valid_refresh_token_to_preserve',
      );

      final mockClient = MockClient((request) async {
        if (request.url.path.contains('/users/me')) {
          return http.Response('{"message": "Token expired"}', 401);
        }

        if (request.url.path.contains('/auth/refresh')) {
          throw http.ClientException('Network is unreachable');
        }

        return http.Response('Not Found', 404);
      });

      final coordinator = AuthSessionCoordinator(
        storageService: storageService,
        baseUrl: testBaseUrl,
        client: mockClient,
      );

      final apiClient = ApiClient(
        baseUrl: testBaseUrl,
        client: mockClient,
        sessionCoordinator: coordinator,
      );

      await expectLater(
        apiClient.get('/users/me'),
        throwsA(
          isA<NetworkException>().having(
            (e) => e.message,
            'message',
            contains('Network is unreachable'),
          ),
        ),
      );

      // CRITICAL: Credentials must NOT be wiped by a transient network outage
      expect(await storageService.getRefreshToken(), equals('valid_refresh_token_to_preserve'));
      expect(await storageService.getAccessToken(), equals('expired_access_token'));
    });

    test('Temporary 503 Service Unavailable during refresh surfaces AuthSessionException without wiping stored credentials', () async {
      await storageService.saveTokens(
        accessToken: 'expired_access_token',
        refreshToken: 'valid_refresh_token_to_preserve',
      );

      final mockClient = MockClient((request) async {
        if (request.url.path.contains('/users/me')) {
          return http.Response('{"message": "Token expired"}', 401);
        }

        if (request.url.path.contains('/auth/refresh')) {
          return http.Response('Service Temporarily Unavailable', 503);
        }

        return http.Response('Not Found', 404);
      });

      final coordinator = AuthSessionCoordinator(
        storageService: storageService,
        baseUrl: testBaseUrl,
        client: mockClient,
      );

      final apiClient = ApiClient(
        baseUrl: testBaseUrl,
        client: mockClient,
        sessionCoordinator: coordinator,
      );

      await expectLater(
        apiClient.get('/users/me'),
        throwsA(isA<AuthSessionException>()),
      );

      // CRITICAL: 5xx server errors must NOT wipe credentials
      expect(await storageService.getRefreshToken(), equals('valid_refresh_token_to_preserve'));
    });

    test('Non-definitive HTTP 400 response (e.g. validation error or syntax error) does NOT clear credentials', () async {
      await storageService.saveTokens(
        accessToken: 'expired_access_token',
        refreshToken: 'valid_refresh_token_preserved',
      );

      final mockClient = MockClient((request) async {
        if (request.url.path.contains('/users/me')) {
          return http.Response('{"message": "Token expired"}', 401);
        }

        if (request.url.path.contains('/auth/refresh')) {
          return http.Response(
            jsonEncode({
              'success': false,
              'message': 'Invalid request parameters',
              'error': {'code': 'VALIDATION_ERROR'},
            }),
            400,
          );
        }

        return http.Response('Not Found', 404);
      });

      final coordinator = AuthSessionCoordinator(
        storageService: storageService,
        baseUrl: testBaseUrl,
        client: mockClient,
      );

      final apiClient = ApiClient(
        baseUrl: testBaseUrl,
        client: mockClient,
        sessionCoordinator: coordinator,
      );

      await expectLater(
        apiClient.get('/users/me'),
        throwsA(
          isA<AuthSessionException>()
              .having((e) => e.errorCode, 'errorCode', 'VALIDATION_ERROR'),
        ),
      );

      // Generic 400 must NOT wipe stored credentials
      expect(await storageService.getRefreshToken(), equals('valid_refresh_token_preserved'));
      expect(await storageService.getAccessToken(), equals('expired_access_token'));
    });

    test('Definitive HTTP 400 response with TOKEN_REUSE_DETECTED clears credentials and surfaces AuthSessionException', () async {
      await storageService.saveTokens(
        accessToken: 'expired_access_token',
        refreshToken: 'compromised_refresh_token',
      );

      final mockClient = MockClient((request) async {
        if (request.url.path.contains('/users/me')) {
          return http.Response('{"message": "Token expired"}', 401);
        }

        if (request.url.path.contains('/auth/refresh')) {
          return http.Response(
            jsonEncode({
              'success': false,
              'message': 'Refresh token reuse detected. Session terminated.',
              'error': {'code': 'TOKEN_REUSE_DETECTED'},
            }),
            400,
          );
        }

        return http.Response('Not Found', 404);
      });

      final coordinator = AuthSessionCoordinator(
        storageService: storageService,
        baseUrl: testBaseUrl,
        client: mockClient,
      );

      final apiClient = ApiClient(
        baseUrl: testBaseUrl,
        client: mockClient,
        sessionCoordinator: coordinator,
      );

      await expectLater(
        apiClient.get('/users/me'),
        throwsA(
          isA<AuthSessionException>()
              .having((e) => e.errorCode, 'errorCode', 'TOKEN_REUSE_DETECTED'),
        ),
      );

      // Definitive rejection error code on 400 MUST wipe credentials
      expect(await storageService.getRefreshToken(), isNull);
      expect(await storageService.getAccessToken(), isNull);
    });

    test('HTTP 401 with a foreign, non-definitive error code (e.g. PROXY_AUTH_REQUIRED) does NOT clear credentials', () async {
      await storageService.saveTokens(
        accessToken: 'expired_access_token',
        refreshToken: 'valid_refresh_token_preserved',
      );

      final mockClient = MockClient((request) async {
        if (request.url.path.contains('/users/me')) {
          return http.Response('{"message": "Token expired"}', 401);
        }

        if (request.url.path.contains('/auth/refresh')) {
          // Upstream edge/proxy 401 challenge with foreign error code
          return http.Response(
            jsonEncode({
              'success': false,
              'message': 'Corporate proxy authentication challenge',
              'error': {'code': 'PROXY_AUTH_REQUIRED'},
            }),
            401,
          );
        }

        return http.Response('Not Found', 404);
      });

      final coordinator = AuthSessionCoordinator(
        storageService: storageService,
        baseUrl: testBaseUrl,
        client: mockClient,
      );

      final apiClient = ApiClient(
        baseUrl: testBaseUrl,
        client: mockClient,
        sessionCoordinator: coordinator,
      );

      await expectLater(
        apiClient.get('/users/me'),
        throwsA(
          isA<AuthSessionException>()
              .having((e) => e.errorCode, 'errorCode', 'PROXY_AUTH_REQUIRED'),
        ),
      );

      // Foreign 401 must NOT wipe stored credentials
      expect(await storageService.getRefreshToken(), equals('valid_refresh_token_preserved'));
      expect(await storageService.getAccessToken(), equals('expired_access_token'));
    });

    test('HTTP 401 with backend UNAUTHORIZED (e.g. deactivated account) definitively clears credentials', () async {
      await storageService.saveTokens(
        accessToken: 'expired_access_token',
        refreshToken: 'deactivated_user_token',
      );

      final mockClient = MockClient((request) async {
        if (request.url.path.contains('/users/me')) {
          return http.Response('{"message": "Token expired"}', 401);
        }

        if (request.url.path.contains('/auth/refresh')) {
          return http.Response(
            jsonEncode({
              'success': false,
              'message': 'Account is disabled or no longer exists.',
              'error': {'code': 'UNAUTHORIZED'},
            }),
            401,
          );
        }

        return http.Response('Not Found', 404);
      });

      final coordinator = AuthSessionCoordinator(
        storageService: storageService,
        baseUrl: testBaseUrl,
        client: mockClient,
      );

      final apiClient = ApiClient(
        baseUrl: testBaseUrl,
        client: mockClient,
        sessionCoordinator: coordinator,
      );

      await expectLater(
        apiClient.get('/users/me'),
        throwsA(
          isA<AuthSessionException>()
              .having((e) => e.errorCode, 'errorCode', 'UNAUTHORIZED'),
        ),
      );

      // Backend UNAUTHORIZED must clear credentials
      expect(await storageService.getRefreshToken(), isNull);
      expect(await storageService.getAccessToken(), isNull);
    });

    test('HTTP 400 with backend MISSING_REFRESH_TOKEN does NOT clear stored credentials', () async {
      await storageService.saveTokens(
        accessToken: 'expired_access_token',
        refreshToken: 'valid_refresh_token_preserved',
      );

      final mockClient = MockClient((request) async {
        if (request.url.path.contains('/users/me')) {
          return http.Response('{"message": "Token expired"}', 401);
        }

        if (request.url.path.contains('/auth/refresh')) {
          // Backend missing-field error: HTTP 400 MISSING_REFRESH_TOKEN
          return http.Response(
            jsonEncode({
              'success': false,
              'message': 'Refresh token is required.',
              'error': {'code': 'MISSING_REFRESH_TOKEN'},
            }),
            400,
          );
        }

        return http.Response('Not Found', 404);
      });

      final coordinator = AuthSessionCoordinator(
        storageService: storageService,
        baseUrl: testBaseUrl,
        client: mockClient,
      );

      final apiClient = ApiClient(
        baseUrl: testBaseUrl,
        client: mockClient,
        sessionCoordinator: coordinator,
      );

      await expectLater(
        apiClient.get('/users/me'),
        throwsA(
          isA<AuthSessionException>()
              .having((e) => e.errorCode, 'errorCode', 'MISSING_REFRESH_TOKEN'),
        ),
      );

      // MISSING_REFRESH_TOKEN is a request/payload error; MUST NOT wipe stored credentials
      expect(await storageService.getRefreshToken(), equals('valid_refresh_token_preserved'));
      expect(await storageService.getAccessToken(), equals('expired_access_token'));
    });

    test('isDefinitiveSessionRejection accurately discriminates status codes and error codes', () {
      // Exact definitive backend codes emitted for refresh requests
      expect(AuthSessionCoordinator.isDefinitiveSessionRejection(401, 'INVALID_REFRESH_TOKEN'), isTrue);
      expect(AuthSessionCoordinator.isDefinitiveSessionRejection(401, 'REFRESH_TOKEN_EXPIRED'), isTrue);
      expect(AuthSessionCoordinator.isDefinitiveSessionRejection(401, 'TOKEN_REUSE_DETECTED'), isTrue);
      expect(AuthSessionCoordinator.isDefinitiveSessionRejection(401, 'UNAUTHORIZED'), isTrue);

      // Case insensitivity
      expect(AuthSessionCoordinator.isDefinitiveSessionRejection(401, 'invalid_refresh_token'), isTrue);

      // Standard 401 with null error code
      expect(AuthSessionCoordinator.isDefinitiveSessionRejection(401, null), isTrue);

      // Foreign error code on 401 (e.g. proxy, firewall)
      expect(AuthSessionCoordinator.isDefinitiveSessionRejection(401, 'PROXY_AUTH_REQUIRED'), isFalse);
      expect(AuthSessionCoordinator.isDefinitiveSessionRejection(401, 'RATE_LIMIT_EXCEEDED'), isFalse);

      // Definitive code on 400
      expect(AuthSessionCoordinator.isDefinitiveSessionRejection(400, 'INVALID_REFRESH_TOKEN'), isTrue);
      expect(AuthSessionCoordinator.isDefinitiveSessionRejection(400, 'TOKEN_REUSE_DETECTED'), isTrue);

      // Non-definitive codes on 400 (including MISSING_REFRESH_TOKEN and VALIDATION_ERROR)
      expect(AuthSessionCoordinator.isDefinitiveSessionRejection(400, 'MISSING_REFRESH_TOKEN'), isFalse);
      expect(AuthSessionCoordinator.isDefinitiveSessionRejection(400, 'VALIDATION_ERROR'), isFalse);
      expect(AuthSessionCoordinator.isDefinitiveSessionRejection(400, null), isFalse);

      // 5xx and others
      expect(AuthSessionCoordinator.isDefinitiveSessionRejection(500, 'INTERNAL_SERVER_ERROR'), isFalse);
      expect(AuthSessionCoordinator.isDefinitiveSessionRejection(503, null), isFalse);
    });

    test('Repeated 401 after retry does not create an infinite loop and throws HttpStatusException', () async {
      await storageService.saveTokens(
        accessToken: 'access_v1',
        refreshToken: 'refresh_v1',
      );

      int protectedCallCount = 0;
      int refreshCallCount = 0;

      final mockClient = MockClient((request) async {
        if (request.url.path.contains('/admin/restricted')) {
          protectedCallCount++;
          // Server continues to return 401 (e.g. insufficient role or account suspended)
          return http.Response('{"message": "Access denied"}', 401);
        }

        if (request.url.path.contains('/auth/refresh')) {
          refreshCallCount++;
          return http.Response(
            jsonEncode({
              'success': true,
              'data': {
                'accessToken': 'access_v2',
                'refreshToken': 'refresh_v2',
              },
            }),
            200,
          );
        }

        return http.Response('Not Found', 404);
      });

      final coordinator = AuthSessionCoordinator(
        storageService: storageService,
        baseUrl: testBaseUrl,
        client: mockClient,
      );

      final apiClient = ApiClient(
        baseUrl: testBaseUrl,
        client: mockClient,
        sessionCoordinator: coordinator,
      );

      await expectLater(
        apiClient.get('/admin/restricted'),
        throwsA(
          isA<HttpStatusException>().having((e) => e.statusCode, 'statusCode', 401),
        ),
      );

      // Must be called at most twice: initial 401, followed by single retry
      expect(protectedCallCount, equals(2));
      expect(refreshCallCount, equals(1));
    });

    test('Refresh 401 does not recursively refresh when refreshing directly', () async {
      await storageService.saveTokens(
        accessToken: 'access_v1',
        refreshToken: 'revoked_token',
      );

      int refreshAttempts = 0;
      final mockClient = MockClient((request) async {
        if (request.url.path.contains('/auth/refresh')) {
          refreshAttempts++;
          return http.Response(
            jsonEncode({
              'success': false,
              'message': 'Revoked refresh token reuse detected.',
              'error': {'code': 'TOKEN_REUSE_DETECTED'},
            }),
            401,
          );
        }
        return http.Response('Not Found', 404);
      });

      final coordinator = AuthSessionCoordinator(
        storageService: storageService,
        baseUrl: testBaseUrl,
        client: mockClient,
      );

      await expectLater(
        coordinator.refreshTokens(),
        throwsA(
          isA<AuthSessionException>().having((e) => e.errorCode, 'errorCode', 'TOKEN_REUSE_DETECTED'),
        ),
      );

      expect(refreshAttempts, equals(1));
      expect(await storageService.getAccessToken(), isNull);
      expect(await storageService.getRefreshToken(), isNull);
    });

    test('Non-eligible paths (login, register, refresh) do not trigger auto-refresh on 401', () async {
      int refreshCallCount = 0;

      final mockClient = MockClient((request) async {
        if (request.url.path.contains('/auth/login')) {
          return http.Response(
            jsonEncode({
              'success': false,
              'message': 'Invalid email or password',
              'error': {'code': 'INVALID_CREDENTIALS'},
            }),
            401,
          );
        }

        if (request.url.path.contains('/auth/refresh')) {
          refreshCallCount++;
          return http.Response('{"success": true}', 200);
        }

        return http.Response('Not Found', 404);
      });

      final coordinator = AuthSessionCoordinator(
        storageService: storageService,
        baseUrl: testBaseUrl,
        client: mockClient,
      );

      final apiClient = ApiClient(
        baseUrl: testBaseUrl,
        client: mockClient,
        sessionCoordinator: coordinator,
      );

      await expectLater(
        apiClient.post('/auth/login', body: {'email': 'a@b.com', 'password': 'wrong'}),
        throwsA(
          isA<HttpStatusException>().having((e) => e.statusCode, 'statusCode', 401),
        ),
      );

      expect(refreshCallCount, equals(0));
    });
  });

  group('Concurrent 401 Protection & De-duplication', () {
    test('Multiple simultaneous 401 responses share a single refresh operation', () async {
      await storageService.saveTokens(
        accessToken: 'initial_expired_token',
        refreshToken: 'initial_valid_refresh_token',
      );

      int refreshCallCount = 0;
      final endpointsCalled = <String, int>{};

      final mockClient = MockClient((request) async {
        final path = request.url.path;

        if (path.contains('/auth/refresh')) {
          refreshCallCount++;
          // Simulate slight network duration to test concurrent queuing
          await Future.delayed(const Duration(milliseconds: 20));

          return http.Response(
            jsonEncode({
              'success': true,
              'data': {
                'accessToken': 'concurrent_rotated_access',
                'refreshToken': 'concurrent_rotated_refresh',
              },
            }),
            200,
          );
        }

        // Protected endpoints: /orders, /profile, /vehicles
        final authHeader = request.headers['Authorization'];
        endpointsCalled[path] = (endpointsCalled[path] ?? 0) + 1;

        if (authHeader == 'Bearer initial_expired_token') {
          return http.Response('{"message": "Unauthorized"}', 401);
        }

        if (authHeader == 'Bearer concurrent_rotated_access') {
          return http.Response('{"success": true, "data": "success for $path"}', 200);
        }

        return http.Response('Unauthorized', 401);
      });

      final coordinator = AuthSessionCoordinator(
        storageService: storageService,
        baseUrl: testBaseUrl,
        client: mockClient,
      );

      final apiClient = ApiClient(
        baseUrl: testBaseUrl,
        client: mockClient,
        sessionCoordinator: coordinator,
      );

      // Launch 3 simultaneous requests
      final results = await Future.wait([
        apiClient.get('/orders'),
        apiClient.get('/profile'),
        apiClient.get('/vehicles'),
      ]);

      // All 3 succeed
      for (final res in results) {
        expect(res.statusCode, equals(200));
        expect(res.isSuccessful, isTrue);
      }

      // CRITICAL: Refresh must only be executed ONCE across all concurrent requests
      expect(refreshCallCount, equals(1));

      // Each endpoint was invoked twice: initial 401, followed by successful retry
      expect(endpointsCalled['/api/v1/orders'], equals(2));
      expect(endpointsCalled['/api/v1/profile'], equals(2));
      expect(endpointsCalled['/api/v1/vehicles'], equals(2));

      // Active tokens in storage are updated
      expect(await storageService.getAccessToken(), equals('concurrent_rotated_access'));
      expect(await storageService.getRefreshToken(), equals('concurrent_rotated_refresh'));
    });
  });

  group('Token Persistence Failures & Rollback Verification', () {
    test('Storage failure during token pair persistence rolls back access token and does not falsely report success', () async {
      await storageService.saveTokens(
        accessToken: 'initial_access_v1',
        refreshToken: 'initial_refresh_v1',
      );

      // Instruct fake driver to fail when writing refresh token
      fakeDriver.throwOnRefreshTokenWrite = true;

      await expectLater(
        storageService.saveTokens(
          accessToken: 'staged_access_v2',
          refreshToken: 'staged_refresh_v2',
        ),
        throwsA(
          isA<TokenStorageException>().having(
            (e) => e.message,
            'message',
            contains('Access token rolled back'),
          ),
        ),
      );

      // Verify rollback: access token was reverted to initial_access_v1
      expect(fakeDriver.storage[TokenStorageService.keyAccessToken], equals('initial_access_v1'));
      expect(await storageService.getAccessToken(), equals('initial_access_v1'));
    });
  });
}
