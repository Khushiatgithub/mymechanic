import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mymechanic/core/network/api_client.dart';
import 'package:mymechanic/services/service_discovery_service.dart';

void main() {
  group('ServiceDiscoveryService Unit Tests', () {
    const testBaseUrl = 'https://api.mymechanic.test/api/v1';

    test('getCategories: successfully fetches, parses, and sorts categories by sortOrder', () async {
      final mockClient = MockClient((request) async {
        expect(request.method, 'GET');
        expect(request.url.path, '/api/v1/service-categories');
        expect(request.url.queryParameters['active'], 'true');

        final responseBody = {
          'success': true,
          'data': {
            'items': [
              {
                '_id': 'cat_2',
                'name': 'AC Service & Repair',
                'description': 'Cooling diagnostics & gas refill',
                'icon': 'ac_unit',
                'sortOrder': 2,
                'isActive': true,
              },
              {
                '_id': 'cat_1',
                'name': 'Periodic Services',
                'description': 'Scheduled engine oil & filter checkup',
                'icon': 'build_circle',
                'sortOrder': 1,
                'isActive': true,
              },
            ],
            'pagination': {'page': 1, 'limit': 50, 'total': 2, 'totalPages': 1},
          },
        };
        return http.Response(jsonEncode(responseBody), 200, headers: {'content-type': 'application/json'});
      });

      final apiClient = ApiClient(baseUrl: testBaseUrl, client: mockClient);
      final service = ServiceDiscoveryService(apiClient: apiClient);

      final categories = await service.getCategories();

      expect(categories.length, 2);
      expect(categories[0].id, 'cat_1'); // sorted by sortOrder 1
      expect(categories[0].name, 'Periodic Services');
      expect(categories[1].id, 'cat_2'); // sortOrder 2
      expect(categories[1].name, 'AC Service & Repair');
    });

    test('getCategoryById: successfully retrieves single category', () async {
      final mockClient = MockClient((request) async {
        expect(request.method, 'GET');
        expect(request.url.path, '/api/v1/service-categories/cat_1');

        final responseBody = {
          'success': true,
          'data': {
            '_id': 'cat_1',
            'name': 'Periodic Services',
            'description': 'Scheduled maintenance',
            'icon': 'build_circle',
            'isActive': true,
            'sortOrder': 1,
          },
        };
        return http.Response(jsonEncode(responseBody), 200, headers: {'content-type': 'application/json'});
      });

      final apiClient = ApiClient(baseUrl: testBaseUrl, client: mockClient);
      final service = ServiceDiscoveryService(apiClient: apiClient);

      final category = await service.getCategoryById('cat_1');
      expect(category.id, 'cat_1');
      expect(category.name, 'Periodic Services');
      expect(category.description, 'Scheduled maintenance');
    });

    test('getServices: successfully parses populated categoryId and query filters', () async {
      String? capturedCategoryId;
      String? capturedSearch;
      String? capturedSort;

      final mockClient = MockClient((request) async {
        expect(request.method, 'GET');
        expect(request.url.path, '/api/v1/services');
        capturedCategoryId = request.url.queryParameters['categoryId'];
        capturedSearch = request.url.queryParameters['search'];
        capturedSort = request.url.queryParameters['sort'];

        final responseBody = {
          'success': true,
          'data': {
            'items': [
              {
                '_id': 'srv_1',
                'categoryId': {
                  '_id': 'cat_1',
                  'name': 'Periodic Services',
                  'icon': 'build_circle',
                },
                'title': 'Standard Periodic Service',
                'description': 'Engine oil and multi-point check',
                'price': 3499,
                'originalPrice': 4299,
                'durationText': '3-4 Hours',
                'rating': 4.8,
                'reviewCount': 120,
                'isActive': true,
                'warrantyPeriod': '1000 Kms or 1 Month',
                'includedItems': ['Castrol Engine Oil', 'Oil Filter'],
                'excludedItems': ['Wiper blades'],
              },
            ],
            'pagination': {'page': 1, 'limit': 50, 'total': 1, 'totalPages': 1},
          },
        };
        return http.Response(jsonEncode(responseBody), 200, headers: {'content-type': 'application/json'});
      });

      final apiClient = ApiClient(baseUrl: testBaseUrl, client: mockClient);
      final service = ServiceDiscoveryService(apiClient: apiClient);

      final items = await service.getServices(
        categoryId: 'cat_1',
        search: 'Standard',
        sort: 'price_asc',
      );

      expect(capturedCategoryId, 'cat_1');
      expect(capturedSearch, 'Standard');
      expect(capturedSort, 'price_asc');
      expect(items.length, 1);
      expect(items[0].id, 'srv_1');
      expect(items[0].categoryId, 'cat_1');
      expect(items[0].categoryName, 'Periodic Services');
      expect(items[0].price, 3499.0);
      expect(items[0].originalPrice, 4299.0);
      expect(items[0].durationText, '3-4 Hours');
      expect(items[0].rating, 4.8);
      expect(items[0].reviewsCount, 120);
      expect(items[0].includedItems, contains('Castrol Engine Oil'));
      expect(items[0].excludedItems, contains('Wiper blades'));
    });

    test('getServiceById: successfully retrieves single service by ID', () async {
      final mockClient = MockClient((request) async {
        expect(request.method, 'GET');
        expect(request.url.path, '/api/v1/services/srv_1');

        final responseBody = {
          'success': true,
          'data': {
            '_id': 'srv_1',
            'categoryId': 'cat_1',
            'title': 'Standard Periodic Service',
            'description': 'Full inspection',
            'price': 2999,
            'originalPrice': 3499,
            'durationText': '3 Hours',
            'rating': 4.9,
            'reviewCount': 85,
            'warrantyPeriod': '6 Months',
          },
        };
        return http.Response(jsonEncode(responseBody), 200, headers: {'content-type': 'application/json'});
      });

      final apiClient = ApiClient(baseUrl: testBaseUrl, client: mockClient);
      final service = ServiceDiscoveryService(apiClient: apiClient);

      final srv = await service.getServiceById('srv_1');
      expect(srv.id, 'srv_1');
      expect(srv.title, 'Standard Periodic Service');
      expect(srv.price, 2999.0);
    });

    test('handles empty results gracefully', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'success': true,
            'data': {'items': [], 'pagination': {'total': 0}},
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final apiClient = ApiClient(baseUrl: testBaseUrl, client: mockClient);
      final service = ServiceDiscoveryService(apiClient: apiClient);

      final categories = await service.getCategories();
      final services = await service.getServices();

      expect(categories, isEmpty);
      expect(services, isEmpty);
    });

    test('handles 404 Not Found error properly', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({'success': false, 'message': 'Service not found'}),
          404,
          headers: {'content-type': 'application/json'},
        );
      });

      final apiClient = ApiClient(baseUrl: testBaseUrl, client: mockClient);
      final service = ServiceDiscoveryService(apiClient: apiClient);

      expect(
        () => service.getServiceById('non_existent'),
        throwsA(isA<HttpStatusException>().having((e) => e.statusCode, 'statusCode', 404)),
      );
    });

    test('handles 500 Internal Server Error properly', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({'success': false, 'message': 'Internal database error'}),
          500,
          headers: {'content-type': 'application/json'},
        );
      });

      final apiClient = ApiClient(baseUrl: testBaseUrl, client: mockClient);
      final service = ServiceDiscoveryService(apiClient: apiClient);

      expect(
        () => service.getServices(),
        throwsA(isA<HttpStatusException>().having((e) => e.statusCode, 'statusCode', 500)),
      );
    });

    test('handles malformed non-JSON response payload', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          '<html><head><title>502 Bad Gateway</title></head><body>Bad Gateway</body></html>',
          502,
          headers: {'content-type': 'text/html'},
        );
      });

      final apiClient = ApiClient(baseUrl: testBaseUrl, client: mockClient);
      final service = ServiceDiscoveryService(apiClient: apiClient);

      expect(
        () => service.getServices(),
        throwsA(isA<HttpStatusException>().having((e) => e.statusCode, 'statusCode', 502)),
      );
    });

    test('ServiceDiscoveryService.getErrorMessage maps errors to user-friendly text', () {
      expect(
        ServiceDiscoveryService.getErrorMessage(const HttpStatusException(statusCode: 404, message: 'Not found')),
        'The requested service or category could not be found.',
      );
      expect(
        ServiceDiscoveryService.getErrorMessage(const HttpStatusException(statusCode: 500, message: 'Database failed')),
        'Server error while loading services. Please try again later.',
      );
      expect(
        ServiceDiscoveryService.getErrorMessage(const NetworkException('Connection refused')),
        'Unable to reach MyMechanic servers. Please check your internet connection.',
      );
      expect(
        ServiceDiscoveryService.getErrorMessage(const ApiTimeoutException('Timed out', timeout: Duration(seconds: 5))),
        'Request timed out. Please check your connection and try again.',
      );
      expect(
        ServiceDiscoveryService.getErrorMessage(const ApiResponseFormatException('Invalid JSON', rawBody: '{')),
        'Invalid or malformed data received from the server.',
      );
      expect(
        ServiceDiscoveryService.getErrorMessage(Exception('Generic issue')),
        'An unexpected error occurred while loading services.',
      );
    });
  });
}
