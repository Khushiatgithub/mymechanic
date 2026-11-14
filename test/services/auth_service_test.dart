import 'dart:async';
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mymechanic/core/network/api_client.dart';
import 'package:mymechanic/models/auth_user.dart';
import 'package:mymechanic/services/auth_service.dart';

class FakeSecureStorageDriver implements SecureStorageDriver {
  final Map<String, String> storage = {};

  @override
  Future<String?> read({required String key}) async => storage[key];

  @override
  Future<void> write({required String key, required String value}) async {
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
  const testBaseUrl = 'https://api.mymechanic.test/api/v1';

  late FakeSecureStorageDriver storageDriver;

  setUp(() {
    storageDriver = FakeSecureStorageDriver();
  });

  group('AuthService Registration', () {
    test('Successful registration persists token pair and updates reactive user state', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.path, endsWith('/auth/register'));
        expect(request.method, equals('POST'));

        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body['name'], equals('Aarav Mehta'));
        expect(body['email'], equals('aarav.mehta@example.com'));
        expect(body['password'], equals('StrongPass123!'));
        expect(body['phone'], equals('+919876543210'));

        return http.Response(
          jsonEncode({
            'success': true,
            'message': 'Registration successful',
            'data': {
              'user': {
                '_id': 'usr_aarav_123',
                'name': 'Aarav Mehta',
                'email': 'aarav.mehta@example.com',
                'phone': '+919876543210',
                'isActive': true,
                'createdAt': '2026-10-22T10:00:00.000Z',
              },
              'accessToken': 'jwt_access_token_123',
              'refreshToken': 'jwt_refresh_token_123',
            },
          }),
          201,
        );
      });

      final authService = AuthService.createDefault(
        baseUrl: testBaseUrl,
        client: mockClient,
        storageDriver: storageDriver,
      );

      final user = await authService.register(
        name: 'Aarav Mehta',
        email: 'aarav.mehta@example.com',
        password: 'StrongPass123!',
        phone: '+919876543210',
      );

      // Verify user model parsed correctly
      expect(user.id, equals('usr_aarav_123'));
      expect(user.name, equals('Aarav Mehta'));
      expect(user.email, equals('aarav.mehta@example.com'));
      expect(user.phone, equals('+919876543210'));
      expect(user.isActive, isTrue);

      // Verify reactive notifiers
      expect(authService.isAuthenticated, isTrue);
      expect(authService.currentUser?.id, equals('usr_aarav_123'));

      // Verify token persistence
      expect(await storageDriver.read(key: TokenStorageService.keyAccessToken), equals('jwt_access_token_123'));
      expect(await storageDriver.read(key: TokenStorageService.keyRefreshToken), equals('jwt_refresh_token_123'));
    });

    test('Client-side validation rejects invalid name, email, short password, or bad phone', () async {
      final mockClient = MockClient((request) async => http.Response('{}', 200));
      final authService = AuthService.createDefault(
        baseUrl: testBaseUrl,
        client: mockClient,
        storageDriver: storageDriver,
      );

      // Empty name
      expect(
        () => authService.register(name: '   ', email: 'a@b.com', password: 'password123'),
        throwsA(isA<AuthValidationException>().having((e) => e.field, 'field', 'name')),
      );

      // Invalid email
      expect(
        () => authService.register(name: 'Valid Name', email: 'invalid-email', password: 'password123'),
        throwsA(isA<AuthValidationException>().having((e) => e.field, 'field', 'email')),
      );

      // Short password (< 8 chars)
      expect(
        () => authService.register(name: 'Valid Name', email: 'test@example.com', password: '12345'),
        throwsA(isA<AuthValidationException>().having((e) => e.field, 'field', 'password')),
      );

      // Invalid phone format
      expect(
        () => authService.register(name: 'Valid Name', email: 'test@example.com', password: 'password123', phone: '123'),
        throwsA(isA<AuthValidationException>().having((e) => e.field, 'field', 'phone')),
      );

      // No tokens should be persisted on validation failure
      expect(await storageDriver.read(key: TokenStorageService.keyAccessToken), isNull);
    });

    test('Duplicate email conflict (409) throws HttpStatusException and preserves storage', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'success': false,
            'message': 'An account with this email address already exists.',
            'error': {'code': 'EMAIL_ALREADY_EXISTS'},
          }),
          409,
        );
      });

      final authService = AuthService.createDefault(
        baseUrl: testBaseUrl,
        client: mockClient,
        storageDriver: storageDriver,
      );

      await expectLater(
        authService.register(
          name: 'Existing User',
          email: 'duplicate@example.com',
          password: 'password123',
        ),
        throwsA(
          isA<HttpStatusException>()
              .having((e) => e.statusCode, 'statusCode', 409)
              .having((e) => e.errorCode, 'errorCode', 'EMAIL_ALREADY_EXISTS'),
        ),
      );

      expect(authService.isAuthenticated, isFalse);
      expect(await storageDriver.read(key: TokenStorageService.keyAccessToken), isNull);
    });
  });

  group('AuthService Login', () {
    test('Successful login stores verified token pair and notifies listeners', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.path, endsWith('/auth/login'));
        expect(request.method, equals('POST'));

        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body['email'], equals('rohit.sharma@example.com'));
        expect(body['password'], equals('Secret123!'));

        return http.Response(
          jsonEncode({
            'success': true,
            'message': 'Login successful',
            'data': {
              'user': {
                '_id': 'usr_rohit_001',
                'name': 'Rohit Sharma',
                'email': 'rohit.sharma@example.com',
                'phone': '+919876543210',
                'isActive': true,
              },
              'accessToken': 'login_access_token_abc',
              'refreshToken': 'login_refresh_token_xyz',
            },
          }),
          200,
        );
      });

      final authService = AuthService.createDefault(
        baseUrl: testBaseUrl,
        client: mockClient,
        storageDriver: storageDriver,
      );

      final user = await authService.login(
        email: 'rohit.sharma@example.com',
        password: 'Secret123!',
      );

      expect(user.id, equals('usr_rohit_001'));
      expect(user.name, equals('Rohit Sharma'));
      expect(authService.isAuthenticated, isTrue);

      expect(await storageDriver.read(key: TokenStorageService.keyAccessToken), equals('login_access_token_abc'));
      expect(await storageDriver.read(key: TokenStorageService.keyRefreshToken), equals('login_refresh_token_xyz'));
    });

    test('Failed login (401 INVALID_CREDENTIALS) does NOT persist tokens', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'success': false,
            'message': 'Invalid email or password',
            'error': {'code': 'INVALID_CREDENTIALS'},
          }),
          401,
        );
      });

      final authService = AuthService.createDefault(
        baseUrl: testBaseUrl,
        client: mockClient,
        storageDriver: storageDriver,
      );

      await expectLater(
        authService.login(
          email: 'rohit.sharma@example.com',
          password: 'WrongPassword!',
        ),
        throwsA(
          isA<HttpStatusException>()
              .having((e) => e.statusCode, 'statusCode', 401)
              .having((e) => e.errorCode, 'errorCode', 'INVALID_CREDENTIALS'),
        ),
      );

      expect(authService.isAuthenticated, isFalse);
      expect(authService.currentUser, isNull);
      expect(await storageDriver.read(key: TokenStorageService.keyAccessToken), isNull);
      expect(await storageDriver.read(key: TokenStorageService.keyRefreshToken), isNull);
    });
  });

  group('AuthService Profile & Session Lifecycle', () {
    test('getCurrentUser retrieves authenticated profile from /auth/me', () async {
      await storageDriver.write(key: TokenStorageService.keyAccessToken, value: 'valid_access_token');

      final mockClient = MockClient((request) async {
        expect(request.url.path, endsWith('/auth/me'));
        expect(request.headers['authorization'], equals('Bearer valid_access_token'));

        return http.Response(
          jsonEncode({
            'success': true,
            'data': {
              '_id': 'usr_me_789',
              'name': 'Priya Patel',
              'email': 'priya.patel@example.com',
              'phone': '+919811122233',
              'isActive': true,
            },
          }),
          200,
        );
      });

      final authService = AuthService.createDefault(
        baseUrl: testBaseUrl,
        client: mockClient,
        storageDriver: storageDriver,
      );

      final user = await authService.getCurrentUser();
      expect(user.id, equals('usr_me_789'));
      expect(user.name, equals('Priya Patel'));
      expect(authService.currentUser?.name, equals('Priya Patel'));
      expect(authService.isAuthenticated, isTrue);
    });

    test('Logout submits refreshToken to backend and purges local credentials', () async {
      await storageDriver.write(key: TokenStorageService.keyAccessToken, value: 'active_access_token');
      await storageDriver.write(key: TokenStorageService.keyRefreshToken, value: 'active_refresh_token');

      bool logoutEndpointCalled = false;
      final mockClient = MockClient((request) async {
        if (request.url.path.endsWith('/auth/logout')) {
          logoutEndpointCalled = true;
          expect(request.method, equals('POST'));
          final body = jsonDecode(request.body) as Map<String, dynamic>;
          expect(body['refreshToken'], equals('active_refresh_token'));

          return http.Response(
            jsonEncode({'success': true, 'message': 'Logged out successfully'}),
            200,
          );
        }
        return http.Response('Not Found', 404);
      });

      final authService = AuthService.createDefault(
        baseUrl: testBaseUrl,
        client: mockClient,
        storageDriver: storageDriver,
      );

      // Pre-populate state
      authService.currentUserNotifier.value = const AuthUser(
        id: '1',
        name: 'Test',
        email: 't@t.com',
      );
      authService.isAuthenticatedNotifier.value = true;

      final result = await authService.logout();

      expect(logoutEndpointCalled, isTrue);
      expect(result.serverRevoked, isTrue);
      expect(result.serverError, isNull);
      expect(authService.isAuthenticated, isFalse);
      expect(authService.currentUser, isNull);
      expect(await storageDriver.read(key: TokenStorageService.keyAccessToken), isNull);
      expect(await storageDriver.read(key: TokenStorageService.keyRefreshToken), isNull);
    });

    test('Logout when server encounters network error STILL purges local credentials and reports serverRevoked=false', () async {
      await storageDriver.write(key: TokenStorageService.keyAccessToken, value: 'active_access_token');
      await storageDriver.write(key: TokenStorageService.keyRefreshToken, value: 'active_refresh_token');

      final mockClient = MockClient((request) async {
        throw http.ClientException('Network outage');
      });

      final authService = AuthService.createDefault(
        baseUrl: testBaseUrl,
        client: mockClient,
        storageDriver: storageDriver,
      );

      // Pre-populate state
      authService.currentUserNotifier.value = const AuthUser(
        id: '1',
        name: 'Test',
        email: 't@t.com',
      );
      authService.isAuthenticatedNotifier.value = true;

      final result = await authService.logout();

      // Remote failed, but local session is GUARANTEED to be cleared
      expect(result.serverRevoked, isFalse);
      expect(result.serverError, contains('Unable to connect'));
      expect(authService.isAuthenticated, isFalse);
      expect(authService.currentUser, isNull);
      expect(await storageDriver.read(key: TokenStorageService.keyAccessToken), isNull);
      expect(await storageDriver.read(key: TokenStorageService.keyRefreshToken), isNull);
    });

    test('initialize preserves session on transient network error without wiping stored credentials', () async {
      await storageDriver.write(key: TokenStorageService.keyAccessToken, value: 'saved_access_token');
      await storageDriver.write(key: TokenStorageService.keyRefreshToken, value: 'saved_refresh_token');

      final mockClient = MockClient((request) async {
        throw http.ClientException('Network unreachable');
      });

      final authService = AuthService.createDefault(
        baseUrl: testBaseUrl,
        client: mockClient,
        storageDriver: storageDriver,
      );

      final initialized = await authService.initialize();

      // Identity unverified due to network outage:
      // Stored credentials preserved, but not prematurely authenticated!
      expect(initialized, isFalse);
      expect(authService.isAuthenticated, isFalse);
      expect(authService.authStatus, equals(AuthStatus.offline));
      expect(authService.isOfflineSession, isTrue);
      expect(authService.currentUser, isNull);
      expect(await storageDriver.read(key: TokenStorageService.keyAccessToken), equals('saved_access_token'));
      expect(await storageDriver.read(key: TokenStorageService.keyRefreshToken), equals('saved_refresh_token'));
    });
  });

  group('AuthService Session Restoration Lifecycle (Phase 3 Step 4.5)', () {
    test('First startup with no stored tokens cleanly defaults to guest mode', () async {
      final mockClient = MockClient((request) async {
        fail('No network calls should be made when no tokens exist');
      });

      final authService = AuthService.createDefault(
        baseUrl: testBaseUrl,
        client: mockClient,
        storageDriver: storageDriver,
      );

      expect(authService.isInitializing, isFalse);
      expect(authService.authStatus, equals(AuthStatus.unauthenticated));
      expect(authService.isGuest, isTrue);

      final restored = await authService.initialize();

      expect(restored, isFalse);
      expect(authService.isAuthenticated, isFalse);
      expect(authService.authStatus, equals(AuthStatus.unauthenticated));
      expect(authService.currentUser, isNull);
      expect(authService.isInitializing, isFalse);
    });

    test('Successful session restoration hydrates customer profile and updates notifiers', () async {
      await storageDriver.write(key: TokenStorageService.keyAccessToken, value: 'valid_access_token');
      await storageDriver.write(key: TokenStorageService.keyRefreshToken, value: 'valid_refresh_token');

      final mockClient = MockClient((request) async {
        expect(request.url.path, endsWith('/auth/me'));
        expect(request.headers['Authorization'], equals('Bearer valid_access_token'));

        return http.Response(
          jsonEncode({
            'success': true,
            'data': {
              '_id': 'usr_restore_123',
              'name': 'Priya Patel',
              'email': 'priya.patel@example.com',
              'phone': '+919876543211',
              'isActive': true,
              'createdAt': '2026-10-22T08:00:00.000Z',
            },
          }),
          200,
        );
      });

      final authService = AuthService.createDefault(
        baseUrl: testBaseUrl,
        client: mockClient,
        storageDriver: storageDriver,
      );

      final restored = await authService.initialize();

      expect(restored, isTrue);
      expect(authService.isAuthenticated, isTrue);
      expect(authService.authStatus, equals(AuthStatus.authenticated));
      expect(authService.currentUser?.id, equals('usr_restore_123'));
      expect(authService.currentUser?.name, equals('Priya Patel'));
      expect(authService.currentUser?.email, equals('priya.patel@example.com'));
      expect(authService.isInitializing, isFalse);
    });

    test('Expired access token on startup automatically refreshes and restores session', () async {
      await storageDriver.write(key: TokenStorageService.keyAccessToken, value: 'expired_access_token');
      await storageDriver.write(key: TokenStorageService.keyRefreshToken, value: 'valid_refresh_token');

      var refreshCalled = false;
      var meCallCount = 0;

      final mockClient = MockClient((request) async {
        if (request.url.path.endsWith('/auth/me')) {
          meCallCount++;
          if (request.headers['Authorization'] == 'Bearer expired_access_token') {
            return http.Response(
              jsonEncode({
                'success': false,
                'error': {'code': 'INVALID_ACCESS_TOKEN', 'message': 'Token expired'},
              }),
              401,
            );
          } else if (request.headers['Authorization'] == 'Bearer rotated_access_token') {
            return http.Response(
              jsonEncode({
                'success': true,
                'data': {
                  '_id': 'usr_refreshed_456',
                  'name': 'Rahul Verma',
                  'email': 'rahul.verma@example.com',
                },
              }),
              200,
            );
          }
        }

        if (request.url.path.endsWith('/auth/refresh')) {
          refreshCalled = true;
          final body = jsonDecode(request.body) as Map<String, dynamic>;
          expect(body['refreshToken'], equals('valid_refresh_token'));

          return http.Response(
            jsonEncode({
              'success': true,
              'data': {
                'accessToken': 'rotated_access_token',
                'refreshToken': 'rotated_refresh_token',
              },
            }),
            200,
          );
        }

        fail('Unexpected request: ${request.url}');
      });

      final authService = AuthService.createDefault(
        baseUrl: testBaseUrl,
        client: mockClient,
        storageDriver: storageDriver,
      );

      final restored = await authService.initialize();

      expect(restored, isTrue);
      expect(refreshCalled, isTrue);
      expect(meCallCount, equals(2));
      expect(authService.isAuthenticated, isTrue);
      expect(authService.authStatus, equals(AuthStatus.authenticated));
      expect(authService.currentUser?.id, equals('usr_refreshed_456'));
      expect(await storageDriver.read(key: TokenStorageService.keyAccessToken), equals('rotated_access_token'));
      expect(await storageDriver.read(key: TokenStorageService.keyRefreshToken), equals('rotated_refresh_token'));
    });

    test('Definitively invalid refresh session purges credentials and returns to guest mode', () async {
      await storageDriver.write(key: TokenStorageService.keyAccessToken, value: 'expired_access_token');
      await storageDriver.write(key: TokenStorageService.keyRefreshToken, value: 'revoked_refresh_token');

      final mockClient = MockClient((request) async {
        if (request.url.path.endsWith('/auth/me')) {
          return http.Response(
            jsonEncode({
              'success': false,
              'error': {'code': 'INVALID_ACCESS_TOKEN', 'message': 'Token expired'},
            }),
            401,
          );
        }

        if (request.url.path.endsWith('/auth/refresh')) {
          return http.Response(
            jsonEncode({
              'success': false,
              'error': {'code': 'INVALID_REFRESH_TOKEN', 'message': 'Refresh session revoked'},
            }),
            401,
          );
        }

        fail('Unexpected request: ${request.url}');
      });

      final authService = AuthService.createDefault(
        baseUrl: testBaseUrl,
        client: mockClient,
        storageDriver: storageDriver,
      );

      final restored = await authService.initialize();

      expect(restored, isFalse);
      expect(authService.isAuthenticated, isFalse);
      expect(authService.authStatus, equals(AuthStatus.unauthenticated));
      expect(authService.isGuest, isTrue);
      expect(authService.currentUser, isNull);
      // Credentials must be cleanly wiped
      expect(await storageDriver.read(key: TokenStorageService.keyAccessToken), isNull);
      expect(await storageDriver.read(key: TokenStorageService.keyRefreshToken), isNull);
      expect(authService.isInitializing, isFalse);
    });

    test('Backend 5xx error preserves stored credentials in offline state without premature authenticated status', () async {
      await storageDriver.write(key: TokenStorageService.keyAccessToken, value: 'persisted_access_token');
      await storageDriver.write(key: TokenStorageService.keyRefreshToken, value: 'persisted_refresh_token');

      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'success': false,
            'error': {'code': 'INTERNAL_ERROR', 'message': 'Database connection pool exhausted'},
          }),
          500,
        );
      });

      final authService = AuthService.createDefault(
        baseUrl: testBaseUrl,
        client: mockClient,
        storageDriver: storageDriver,
      );

      final restored = await authService.initialize();

      // Credentials preserved, but identity unverified -> offline state
      expect(restored, isFalse);
      expect(authService.isAuthenticated, isFalse);
      expect(authService.authStatus, equals(AuthStatus.offline));
      expect(authService.isOfflineSession, isTrue);
      expect(authService.currentUser, isNull);
      expect(await storageDriver.read(key: TokenStorageService.keyAccessToken), equals('persisted_access_token'));
      expect(await storageDriver.read(key: TokenStorageService.keyRefreshToken), equals('persisted_refresh_token'));
    });

    test('Concurrent initialize calls share a single in-flight operation without duplicating network requests', () async {
      await storageDriver.write(key: TokenStorageService.keyAccessToken, value: 'shared_token');
      await storageDriver.write(key: TokenStorageService.keyRefreshToken, value: 'shared_refresh');

      var meCallCount = 0;

      final mockClient = MockClient((request) async {
        meCallCount++;
        // Small delay to simulate network latency
        await Future.delayed(const Duration(milliseconds: 20));
        return http.Response(
          jsonEncode({
            'success': true,
            'data': {
              '_id': 'usr_concurrent_1',
              'name': 'Concurrent User',
              'email': 'concurrent@example.com',
            },
          }),
          200,
        );
      });

      final authService = AuthService.createDefault(
        baseUrl: testBaseUrl,
        client: mockClient,
        storageDriver: storageDriver,
      );

      // Trigger multiple concurrent initializations
      final results = await Future.wait([
        authService.initialize(),
        authService.initialize(),
        authService.initialize(),
      ]);

      expect(meCallCount, equals(1));
      expect(results, equals([true, true, true]));
      expect(authService.isAuthenticated, isTrue);
      expect(authService.currentUser?.name, equals('Concurrent User'));
    });

    test('Logout racing with slow initialization discards stale restoration and stays signed out', () async {
      await storageDriver.write(key: TokenStorageService.keyAccessToken, value: 'slow_token');
      await storageDriver.write(key: TokenStorageService.keyRefreshToken, value: 'slow_refresh');

      final slowCompleter = Completer<http.Response>();

      final mockClient = MockClient((request) async {
        if (request.url.path.endsWith('/auth/me')) {
          return slowCompleter.future;
        }
        if (request.url.path.endsWith('/auth/logout')) {
          return http.Response(jsonEncode({'success': true}), 200);
        }
        fail('Unexpected request: ${request.url}');
      });

      final authService = AuthService.createDefault(
        baseUrl: testBaseUrl,
        client: mockClient,
        storageDriver: storageDriver,
      );

      // 1. Start slow initialization
      final initFuture = authService.initialize();

      // 2. While initialize is waiting, user explicitly logs out
      await authService.logout();

      expect(authService.isAuthenticated, isFalse);
      expect(authService.currentUser, isNull);

      // 3. Slow /auth/me finally arrives with old profile
      slowCompleter.complete(http.Response(
        jsonEncode({
          'success': true,
          'data': {
            '_id': 'usr_stale_999',
            'name': 'Stale User',
            'email': 'stale@example.com',
          },
        }),
        200,
      ));

      await initFuture;

      // 4. Must NOT have overwritten the logout state!
      expect(authService.isAuthenticated, isFalse);
      expect(authService.currentUser, isNull);
      expect(await storageDriver.read(key: TokenStorageService.keyAccessToken), isNull);
    });

    test('Login racing with slow initialization preserves newer login credentials', () async {
      await storageDriver.write(key: TokenStorageService.keyAccessToken, value: 'old_token');
      await storageDriver.write(key: TokenStorageService.keyRefreshToken, value: 'old_refresh');

      final slowCompleter = Completer<http.Response>();

      final mockClient = MockClient((request) async {
        if (request.url.path.endsWith('/auth/me')) {
          return slowCompleter.future;
        }
        if (request.url.path.endsWith('/auth/login')) {
          return http.Response(
            jsonEncode({
              'success': true,
              'data': {
                'user': {
                  '_id': 'usr_new_login_888',
                  'name': 'New Logged In User',
                  'email': 'newlogin@example.com',
                },
                'accessToken': 'new_access_token_888',
                'refreshToken': 'new_refresh_token_888',
              },
            }),
            200,
          );
        }
        fail('Unexpected request: ${request.url}');
      });

      final authService = AuthService.createDefault(
        baseUrl: testBaseUrl,
        client: mockClient,
        storageDriver: storageDriver,
      );

      // 1. Start slow initialization
      final initFuture = authService.initialize();

      // 2. User logs in with new credentials while initialize is waiting
      await authService.login(email: 'newlogin@example.com', password: 'Password123!');
      expect(authService.currentUser?.email, equals('newlogin@example.com'));

      // 3. Stale initialize /auth/me completes
      slowCompleter.complete(http.Response(
        jsonEncode({
          'success': true,
          'data': {
            '_id': 'usr_old_111',
            'name': 'Old User',
            'email': 'old@example.com',
          },
        }),
        200,
      ));

      await initFuture;

      // 4. Newer login user is preserved
      expect(authService.currentUser?.id, equals('usr_new_login_888'));
      expect(authService.currentUser?.email, equals('newlogin@example.com'));
      expect(await storageDriver.read(key: TokenStorageService.keyAccessToken), equals('new_access_token_888'));
    });
  });

  group('AuthService Error Messages', () {
    test('Converts exceptions to safe customer-facing messages without leaking secrets', () {
      expect(
        AuthService.getErrorMessage(const AuthValidationException('Custom message')),
        equals('Custom message'),
      );

      expect(
        AuthService.getErrorMessage(const HttpStatusException(
          statusCode: 401,
          errorCode: 'INVALID_CREDENTIALS',
          message: 'Backend raw error',
        )),
        contains('Invalid email or password'),
      );

      expect(
        AuthService.getErrorMessage(const HttpStatusException(
          statusCode: 409,
          errorCode: 'EMAIL_ALREADY_EXISTS',
          message: 'Backend duplicate error',
        )),
        contains('already exists'),
      );

      expect(
        AuthService.getErrorMessage(const HttpStatusException(
          statusCode: 429,
          message: 'Too many requests',
        )),
        contains('15 minutes'),
      );

      expect(
        AuthService.getErrorMessage(const NetworkException('Socket failed')),
        contains('Unable to connect'),
      );

      expect(
        AuthService.getErrorMessage(const ApiTimeoutException('Timeout', timeout: Duration(seconds: 15))),
        contains('timed out'),
      );
    });
  });
}
