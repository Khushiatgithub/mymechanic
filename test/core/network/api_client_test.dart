import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mymechanic/core/config/api_config.dart';
import 'package:mymechanic/core/network/api_client.dart';

void main() {
  group('ApiConfig & URL Normalization Tests', () {
    test('Default base URL resolves to Android emulator URL when no define is set', () {
      final defaultUrl = ApiConfig.resolveBaseUrl();
      expect(defaultUrl, equals(ApiConfig.androidEmulatorBaseUrl));
      expect(defaultUrl, contains('/api/v1'));
      expect(defaultUrl, startsWith('http://10.0.2.2:5000'));
    });

    test('Normalizes custom URL by appending /api/v1 if missing', () {
      final url = ApiConfig.resolveBaseUrl('http://192.168.1.50:5000');
      expect(url, equals('http://192.168.1.50:5000/api/v1'));
    });

    test('Preserves existing /api/v1 without duplication and strips trailing slashes', () {
      final url1 = ApiConfig.resolveBaseUrl('http://192.168.1.50:5000/api/v1');
      expect(url1, equals('http://192.168.1.50:5000/api/v1'));

      final url2 = ApiConfig.resolveBaseUrl('http://192.168.1.50:5000/api/v1/');
      expect(url2, equals('http://192.168.1.50:5000/api/v1'));
    });

    test('Throws ApiConfigurationException for invalid or malformed URL without falling back to localhost', () {
      expect(
        () => ApiConfig.resolveBaseUrl('ftp://not-supported.org'),
        throwsA(isA<ApiConfigurationException>()),
      );

      expect(
        () => ApiConfig.resolveBaseUrl('not-a-valid-url'),
        throwsA(isA<ApiConfigurationException>()),
      );

      expect(
        () => ApiClient(baseUrl: 'httptypo://invalid'),
        throwsA(isA<ApiConfigurationException>()),
      );
    });
  });

  group('ApiClient Core HTTP Methods & Payloads', () {
    const testBaseUrl = 'http://127.0.0.1:5000/api/v1';

    test('Successful GET parses standard envelope and extracts data', () async {
      final mockClient = MockClient((request) async {
        expect(request.method, equals('GET'));
        expect(request.url.toString(), equals('$testBaseUrl/health'));
        expect(request.headers['Accept'], equals('application/json'));

        return http.Response(
          jsonEncode({
            'success': true,
            'message': 'MyMechanic API is healthy',
            'data': {'environment': 'test', 'status': 'operational'},
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final client = ApiClient(baseUrl: testBaseUrl, client: mockClient);
      final response = await client.get('/health');

      expect(response.statusCode, equals(200));
      expect(response.isSuccessful, isTrue);
      expect(response.message, equals('MyMechanic API is healthy'));
      expect(response.data, isA<Map<String, dynamic>>());
      expect(response.data['environment'], equals('test'));
    });

    test('POST with JSON body correctly sets Content-Type and encodes body', () async {
      final mockClient = MockClient((request) async {
        expect(request.method, equals('POST'));
        expect(request.url.toString(), equals('$testBaseUrl/vehicles'));
        expect(request.headers['Content-Type'], equals('application/json'));
        expect(request.headers['Accept'], equals('application/json'));

        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body['make'], equals('Honda'));
        expect(body['model'], equals('City'));

        return http.Response(
          jsonEncode({
            'success': true,
            'message': 'Vehicle added',
            'data': {'id': 'veh_123', 'make': 'Honda', 'model': 'City'},
          }),
          201,
          headers: {'content-type': 'application/json'},
        );
      });

      final client = ApiClient(baseUrl: testBaseUrl, client: mockClient);
      final response = await client.post(
        '/vehicles',
        body: {'make': 'Honda', 'model': 'City'},
      );

      expect(response.statusCode, equals(201));
      expect(response.isSuccessful, isTrue);
      expect(response.data['id'], equals('veh_123'));
    });

    test('PATCH request safely updates resource', () async {
      final mockClient = MockClient((request) async {
        expect(request.method, equals('PATCH'));
        expect(request.url.toString(), equals('$testBaseUrl/vehicles/veh_123'));
        expect(request.headers['Content-Type'], equals('application/json'));

        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body['isActive'], isTrue);

        return http.Response(
          jsonEncode({
            'success': true,
            'message': 'Vehicle activated',
            'data': {'id': 'veh_123', 'isActive': true},
          }),
          200,
        );
      });

      final client = ApiClient(baseUrl: testBaseUrl, client: mockClient);
      final response = await client.patch(
        'vehicles/veh_123',
        body: {'isActive': true},
      );

      expect(response.statusCode, equals(200));
      expect(response.data['isActive'], isTrue);
    });

    test('DELETE request completes successfully', () async {
      final mockClient = MockClient((request) async {
        expect(request.method, equals('DELETE'));
        expect(request.url.toString(), equals('$testBaseUrl/vehicles/veh_123'));

        return http.Response(
          jsonEncode({
            'success': true,
            'message': 'Vehicle deleted',
            'data': null,
          }),
          200,
        );
      });

      final client = ApiClient(baseUrl: testBaseUrl, client: mockClient);
      final response = await client.delete('/vehicles/veh_123');

      expect(response.statusCode, equals(200));
      expect(response.message, equals('Vehicle deleted'));
    });

    test('Handles relative paths with or without leading slashes and prevents prefix duplication', () async {
      final recordedUrls = <String>[];
      final mockClient = MockClient((request) async {
        recordedUrls.add(request.url.toString());
        return http.Response('{"success": true}', 200);
      });

      final client = ApiClient(baseUrl: testBaseUrl, client: mockClient);

      await client.get('services');
      await client.get('/services');
      await client.get('/api/v1/services');

      for (final url in recordedUrls) {
        expect(url, equals('$testBaseUrl/services'));
      }
    });

    test('Query parameters are safely URL-encoded', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.queryParameters['category'], equals('Periodic Services'));
        expect(request.url.queryParameters['search'], equals('oil & filter'));
        expect(request.url.queryParameters['limit'], equals('10'));

        return http.Response('{"success": true, "data": []}', 200);
      });

      final client = ApiClient(baseUrl: testBaseUrl, client: mockClient);
      final response = await client.get(
        '/services',
        queryParameters: {
          'category': 'Periodic Services',
          'search': 'oil & filter',
          'limit': 10,
        },
      );

      expect(response.statusCode, equals(200));
      expect(response.data, equals([]));
    });

    test('Custom headers override or merge with default headers', () async {
      final mockClient = MockClient((request) async {
        expect(request.headers['Accept'], equals('application/json'));
        expect(request.headers['X-Custom-Client'], equals('MyMechanic-Flutter-Test'));

        return http.Response('{"success": true}', 200);
      });

      final client = ApiClient(baseUrl: testBaseUrl, client: mockClient);
      await client.get('/test', headers: {'X-Custom-Client': 'MyMechanic-Flutter-Test'});
    });
  });

  group('Empty & 204 No Content Responses', () {
    const testBaseUrl = 'http://127.0.0.1:5000/api/v1';

    test('HTTP 204 No Content returns valid ApiResponse with null data without throwing', () async {
      final mockClient = MockClient((request) async {
        return http.Response('', 204);
      });

      final client = ApiClient(baseUrl: testBaseUrl, client: mockClient);
      final response = await client.delete('/bookings/bk_123');

      expect(response.statusCode, equals(204));
      expect(response.isSuccessful, isTrue);
      expect(response.isNoContent, isTrue);
      expect(response.data, isNull);
    });

    test('HTTP 200 with empty body returns valid ApiResponse with null data', () async {
      final mockClient = MockClient((request) async {
        return http.Response('   ', 200);
      });

      final client = ApiClient(baseUrl: testBaseUrl, client: mockClient);
      final response = await client.get('/empty');

      expect(response.statusCode, equals(200));
      expect(response.data, isNull);
    });
  });

  group('Error Handling & Typed Exceptions', () {
    const testBaseUrl = 'http://127.0.0.1:5000/api/v1';

    test('HTTP 400 Bad Request throws HttpStatusException with parsed errorCode', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'success': false,
            'message': 'Invalid input data',
            'error': {'code': 'VALIDATION_FAILED'},
          }),
          400,
        );
      });

      final client = ApiClient(baseUrl: testBaseUrl, client: mockClient);

      expect(
        () => client.post('/users', body: {}),
        throwsA(
          isA<HttpStatusException>()
              .having((e) => e.statusCode, 'statusCode', 400)
              .having((e) => e.errorCode, 'errorCode', 'VALIDATION_FAILED')
              .having((e) => e.message, 'message', 'Invalid input data')
              .having((e) => e.isBadRequest, 'isBadRequest', isTrue)
              .having((e) => e.isClientError, 'isClientError', isTrue),
        ),
      );
    });

    test('HTTP 401 Unauthorized, 403 Forbidden, 404 Not Found, and 409 Conflict getters work', () async {
      final client401 = ApiClient(
        baseUrl: testBaseUrl,
        client: MockClient((r) async => http.Response('{"message": "Unauthorized"}', 401)),
      );
      expect(() => client401.get('/me'), throwsA(isA<HttpStatusException>().having((e) => e.isUnauthorized, 'isUnauthorized', isTrue)));

      final client403 = ApiClient(
        baseUrl: testBaseUrl,
        client: MockClient((r) async => http.Response('{"message": "Forbidden"}', 403)),
      );
      expect(() => client403.get('/admin'), throwsA(isA<HttpStatusException>().having((e) => e.isForbidden, 'isForbidden', isTrue)));

      final client404 = ApiClient(
        baseUrl: testBaseUrl,
        client: MockClient((r) async => http.Response('{"message": "Not Found"}', 404)),
      );
      expect(() => client404.get('/missing'), throwsA(isA<HttpStatusException>().having((e) => e.isNotFound, 'isNotFound', isTrue)));

      final client409 = ApiClient(
        baseUrl: testBaseUrl,
        client: MockClient((r) async => http.Response('{"message": "Already exists"}', 409)),
      );
      expect(() => client409.post('/users', body: {}), throwsA(isA<HttpStatusException>().having((e) => e.isConflict, 'isConflict', isTrue)));
    });

    test('HTTP 500 Internal Server Error sets isServerError to true', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'success': false,
            'message': 'Database query failed',
            'error': {'code': 'INTERNAL_ERROR'},
          }),
          500,
        );
      });

      final client = ApiClient(baseUrl: testBaseUrl, client: mockClient);

      expect(
        () => client.get('/crash'),
        throwsA(
          isA<HttpStatusException>()
              .having((e) => e.statusCode, 'statusCode', 500)
              .having((e) => e.isServerError, 'isServerError', isTrue),
        ),
      );
    });

    test('Non-JSON HTTP error (e.g. HTML 502 Bad Gateway) handles gracefully without crashing json parser', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          '<html><body>502 Bad Gateway</body></html>',
          502,
          headers: {'content-type': 'text/html'},
        );
      });

      final client = ApiClient(baseUrl: testBaseUrl, client: mockClient);

      expect(
        () => client.get('/proxy-error'),
        throwsA(
          isA<HttpStatusException>()
              .having((e) => e.statusCode, 'statusCode', 502)
              .having((e) => e.responseBody, 'responseBody', contains('502 Bad Gateway')),
        ),
      );
    });

    test('Malformed JSON in successful 200 response throws ApiResponseFormatException', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          '{ "unclosed": json string ...',
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final client = ApiClient(baseUrl: testBaseUrl, client: mockClient);

      expect(
        () => client.get('/broken-json'),
        throwsA(
          isA<ApiResponseFormatException>()
              .having((e) => e.rawBody, 'rawBody', contains('unclosed')),
        ),
      );
    });

    test('SocketException and ClientException map to NetworkException', () async {
      final mockClientSocket = MockClient((request) async {
        throw const SocketException('Connection refused');
      });

      final clientSocket = ApiClient(baseUrl: testBaseUrl, client: mockClientSocket);

      expect(
        () => clientSocket.get('/offline'),
        throwsA(
          isA<NetworkException>()
              .having((e) => e.message, 'message', contains('Network connection failed')),
        ),
      );

      final mockClientHttp = MockClient((request) async {
        throw http.ClientException('Failed to connect to host');
      });

      final clientHttp = ApiClient(baseUrl: testBaseUrl, client: mockClientHttp);

      expect(
        () => clientHttp.get('/offline'),
        throwsA(
          isA<NetworkException>()
              .having((e) => e.message, 'message', contains('HTTP client error')),
        ),
      );
    });

    test('Request exceeding timeout throws ApiTimeoutException', () async {
      final mockClient = MockClient((request) async {
        // Complete after 80ms
        await Future.delayed(const Duration(milliseconds: 80));
        return http.Response('{"success": true}', 200);
      });

      final client = ApiClient(
        baseUrl: testBaseUrl,
        client: mockClient,
        defaultTimeout: const Duration(milliseconds: 20),
      );

      expect(
        () => client.get('/slow'),
        throwsA(
          isA<ApiTimeoutException>()
              .having((e) => e.timeout, 'timeout', const Duration(milliseconds: 20)),
        ),
      );
    });
  });

  group('Future Authentication Compatibility & Token Provider', () {
    const testBaseUrl = 'http://127.0.0.1:5000/api/v1';

    test('Injects Bearer token header when TokenProvider returns a non-empty token', () async {
      String? capturedAuthHeader;

      final mockClient = MockClient((request) async {
        capturedAuthHeader = request.headers['Authorization'];
        return http.Response('{"success": true}', 200);
      });

      final client = ApiClient(
        baseUrl: testBaseUrl,
        client: mockClient,
        tokenProvider: () async => 'test-bearer-token-12345',
      );

      await client.get('/auth-test');

      expect(capturedAuthHeader, equals('Bearer test-bearer-token-12345'));
    });

    test('Does NOT attach Authorization header when TokenProvider returns null or empty', () async {
      String? capturedAuthHeader;

      final mockClient = MockClient((request) async {
        capturedAuthHeader = request.headers['Authorization'];
        return http.Response('{"success": true}', 200);
      });

      final clientNull = ApiClient(
        baseUrl: testBaseUrl,
        client: mockClient,
        tokenProvider: () async => null,
      );

      await clientNull.get('/no-token');
      expect(capturedAuthHeader, isNull);

      final clientEmpty = ApiClient(
        baseUrl: testBaseUrl,
        client: mockClient,
        tokenProvider: () async => '   ',
      );

      await clientEmpty.get('/no-token-empty');
      expect(capturedAuthHeader, isNull);
    });

    test('Does NOT attach Authorization header when no TokenProvider is configured', () async {
      String? capturedAuthHeader;

      final mockClient = MockClient((request) async {
        capturedAuthHeader = request.headers['Authorization'];
        return http.Response('{"success": true}', 200);
      });

      final client = ApiClient(baseUrl: testBaseUrl, client: mockClient);
      await client.get('/public');

      expect(capturedAuthHeader, isNull);
    });
  });
}
