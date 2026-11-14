import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mymechanic/core/network/api_client.dart';

/// In-memory test fake for [SecureStorageDriver].
class FakeSecureStorageDriver implements SecureStorageDriver {
  final Map<String, String> storage = {};
  bool shouldThrowOnRead = false;
  bool shouldThrowOnWrite = false;
  bool shouldThrowOnDelete = false;

  @override
  Future<String?> read({required String key}) async {
    if (shouldThrowOnRead) {
      throw Exception('Simulated platform keystore read failure');
    }
    return storage[key];
  }

  @override
  Future<void> write({required String key, required String value}) async {
    if (shouldThrowOnWrite) {
      throw Exception('Simulated platform keystore write failure');
    }
    storage[key] = value;
  }

  @override
  Future<void> delete({required String key}) async {
    if (shouldThrowOnDelete) {
      throw Exception('Simulated platform keystore delete failure');
    }
    storage.remove(key);
  }

  @override
  Future<void> deleteAll() async {
    if (shouldThrowOnDelete) {
      throw Exception('Simulated platform keystore deleteAll failure');
    }
    storage.clear();
  }
}

void main() {
  late FakeSecureStorageDriver fakeDriver;
  late TokenStorageService storageService;

  setUp(() {
    fakeDriver = FakeSecureStorageDriver();
    storageService = TokenStorageService(driver: fakeDriver);
  });

  group('TokenStorageService Core Operations', () {
    const testAccessToken = 'header.payload_access_123.sig';
    const testRefreshToken = 'header.payload_refresh_456.sig';

    test('Saves and retrieves access token', () async {
      await storageService.saveAccessToken(testAccessToken);

      final retrieved = await storageService.getAccessToken();
      expect(retrieved, equals(testAccessToken));
      expect(fakeDriver.storage[TokenStorageService.keyAccessToken], equals(testAccessToken));

      // Test forceRefresh re-reading directly from driver
      final freshRead = await storageService.getAccessToken(forceRefresh: true);
      expect(freshRead, equals(testAccessToken));
    });

    test('Saves and retrieves refresh token', () async {
      await storageService.saveRefreshToken(testRefreshToken);

      final retrieved = await storageService.getRefreshToken();
      expect(retrieved, equals(testRefreshToken));
      expect(fakeDriver.storage[TokenStorageService.keyRefreshToken], equals(testRefreshToken));

      final freshRead = await storageService.getRefreshToken(forceRefresh: true);
      expect(freshRead, equals(testRefreshToken));
    });

    test('Rejects empty or whitespace tokens with ArgumentError', () async {
      expect(() => storageService.saveAccessToken(''), throwsArgumentError);
      expect(() => storageService.saveAccessToken('   '), throwsArgumentError);
      expect(() => storageService.saveRefreshToken(''), throwsArgumentError);
      expect(() => storageService.saveRefreshToken('   '), throwsArgumentError);
    });

    test('Returns null when no token exists in storage', () async {
      final access = await storageService.getAccessToken();
      final refresh = await storageService.getRefreshToken();

      expect(access, isNull);
      expect(refresh, isNull);
    });

    test('Deleting access token preserves refresh token', () async {
      await storageService.saveAccessToken(testAccessToken);
      await storageService.saveRefreshToken(testRefreshToken);

      await storageService.deleteAccessToken();

      expect(await storageService.getAccessToken(), isNull);
      expect(await storageService.getRefreshToken(), equals(testRefreshToken));
      expect(fakeDriver.storage.containsKey(TokenStorageService.keyAccessToken), isFalse);
      expect(fakeDriver.storage.containsKey(TokenStorageService.keyRefreshToken), isTrue);
    });

    test('Deleting refresh token preserves access token', () async {
      await storageService.saveAccessToken(testAccessToken);
      await storageService.saveRefreshToken(testRefreshToken);

      await storageService.deleteRefreshToken();

      expect(await storageService.getRefreshToken(), isNull);
      expect(await storageService.getAccessToken(), equals(testAccessToken));
      expect(fakeDriver.storage.containsKey(TokenStorageService.keyRefreshToken), isFalse);
      expect(fakeDriver.storage.containsKey(TokenStorageService.keyAccessToken), isTrue);
    });

    test('Clearing both tokens removes access and refresh tokens completely', () async {
      await storageService.saveAccessToken(testAccessToken);
      await storageService.saveRefreshToken(testRefreshToken);

      await storageService.clearTokens();

      expect(await storageService.getAccessToken(), isNull);
      expect(await storageService.getRefreshToken(), isNull);
      expect(fakeDriver.storage.isEmpty, isTrue);
    });
  });

  group('TokenStorageService Error Handling & Security', () {
    const sensitiveSecretToken = 'secret_jwt_signature_xyz_should_never_leak';

    test('Surfaces TokenStorageException when write fails without leaking token value', () async {
      fakeDriver.shouldThrowOnWrite = true;

      try {
        await storageService.saveAccessToken(sensitiveSecretToken);
        fail('Expected TokenStorageException');
      } catch (e) {
        expect(e, isA<TokenStorageException>());
        final errorString = e.toString();
        // Diagnostic string must NEVER include token content
        expect(errorString.contains(sensitiveSecretToken), isFalse);
        expect(errorString, contains('Failed to save access token'));
      }
    });

    test('Surfaces TokenStorageException when read fails', () async {
      fakeDriver.shouldThrowOnRead = true;

      expect(
        () => storageService.getAccessToken(),
        throwsA(isA<TokenStorageException>().having(
          (e) => e.message,
          'message',
          contains('Failed to read access token'),
        )),
      );

      expect(
        () => storageService.getRefreshToken(),
        throwsA(isA<TokenStorageException>().having(
          (e) => e.message,
          'message',
          contains('Failed to read refresh token'),
        )),
      );
    });

    test('Surfaces TokenStorageException when delete fails', () async {
      fakeDriver.shouldThrowOnDelete = true;

      expect(
        () => storageService.deleteAccessToken(),
        throwsA(isA<TokenStorageException>().having(
          (e) => e.message,
          'message',
          contains('Failed to delete access token'),
        )),
      );

      expect(
        () => storageService.deleteRefreshToken(),
        throwsA(isA<TokenStorageException>().having(
          (e) => e.message,
          'message',
          contains('Failed to delete refresh token'),
        )),
      );
    });

    test('Surfaces TokenStorageException when clearTokens fails and invalidates cache', () async {
      fakeDriver.shouldThrowOnDelete = true;

      expect(
        () => storageService.clearTokens(),
        throwsA(isA<TokenStorageException>().having(
          (e) => e.message,
          'message',
          contains('Failed to clear authentication tokens'),
        )),
      );
    });
  });

  group('SecureTokenProvider & ApiClient Integration', () {
    const testBearerToken = 'mock_jwt_access_token_999';

    test('SecureTokenProvider returns stored access token', () async {
      await storageService.saveAccessToken(testBearerToken);

      final tokenProvider = SecureTokenProvider(storageService: storageService);
      final token = await tokenProvider.getAccessToken();

      expect(token, equals(testBearerToken));
      expect(await tokenProvider.toTokenProvider(), equals(testBearerToken));
    });

    test('SecureTokenProvider returns null when no access token exists', () async {
      final tokenProvider = SecureTokenProvider(storageService: storageService);
      final token = await tokenProvider.getAccessToken();

      expect(token, isNull);
      expect(await tokenProvider.toTokenProvider(), isNull);
    });

    test('SecureTokenProvider degrades gracefully to null on storage read failure', () async {
      fakeDriver.shouldThrowOnRead = true;

      final tokenProvider = SecureTokenProvider(storageService: storageService);
      // Must not throw an unhandled exception
      final token = await tokenProvider.getAccessToken();
      expect(token, isNull);
    });

    test('Injects stored access token into ApiClient Bearer header', () async {
      await storageService.saveAccessToken(testBearerToken);

      String? capturedAuthHeader;
      final mockHttpClient = MockClient((request) async {
        capturedAuthHeader = request.headers['Authorization'];
        return http.Response('{"success": true}', 200);
      });

      final secureTokenProvider = SecureTokenProvider(storageService: storageService);

      final apiClient = ApiClient(
        baseUrl: 'http://127.0.0.1:5000/api/v1',
        client: mockHttpClient,
        tokenProvider: secureTokenProvider.toTokenProvider,
      );

      await apiClient.get('/profile');

      expect(capturedAuthHeader, equals('Bearer $testBearerToken'));
    });
  });
}
