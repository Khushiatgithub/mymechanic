import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mymechanic/core/network/api_client.dart';
import 'package:mymechanic/models/workshop.dart';
import 'package:mymechanic/services/workshop_service.dart';

void main() {
  const testBaseUrl = 'https://api.mymechanic.test/api/v1';

  final sampleWorkshopJson = {
    '_id': '67b8a1000000000000000888',
    'name': 'My Mechanic Premium Car Service',
    'city': 'Gurugram',
    'area': 'Atul Kataria Chowk',
    'address': 'Old Delhi Road, Atul Kataria Chowk, opposite Air Force Station, Gurugram, Haryana 122015',
    'pincode': '122015',
    'rating': 4.8,
    'reviewsCount': 150,
    'leadMechanic': 'Assigned upon arrival',
    'phone': '+91 88269 91028',
    'operatingHours': '24x7',
    'isDemoSeedData': false,
    'disclaimer': 'Official verified workshop location.',
  };

  group('Workshop Model', () {
    test('fromJson parses correctly with verified workshop metadata', () {
      final workshop = Workshop.fromJson(sampleWorkshopJson);

      expect(workshop.id, equals('67b8a1000000000000000888'));
      expect(workshop.name, equals('My Mechanic Premium Car Service'));
      expect(workshop.area, equals('Atul Kataria Chowk'));
      expect(workshop.city, equals('Gurugram'));
      expect(workshop.rating, equals(4.8));
      expect(workshop.leadMechanic, equals('Assigned upon arrival'));
      expect(workshop.isDemoSeedData, isFalse);
      expect(workshop.disclaimer, contains('verified workshop'));
    });
  });

  group('WorkshopService', () {
    test('getWorkshops fetches from API and parses response', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.path, equals('/api/v1/workshops'));
        expect(request.method, equals('GET'));

        return http.Response(
          jsonEncode({
            'success': true,
            'message': 'Workshops retrieved successfully',
            'data': [sampleWorkshopJson],
          }),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      });

      final apiClient = ApiClient(baseUrl: testBaseUrl, client: mockClient);
      final service = WorkshopService(apiClient: apiClient);

      final hubs = await service.getWorkshops();

      expect(hubs.length, equals(1));
      expect(hubs.first.name, equals('My Mechanic Premium Car Service'));
      expect(hubs.first.isDemoSeedData, isFalse);
    });

    test('getWorkshops falls back to MockData.workshops when network fails', () async {
      final mockClient = MockClient((request) async {
        throw http.ClientException('Network down');
      });

      final apiClient = ApiClient(baseUrl: testBaseUrl, client: mockClient);
      final service = WorkshopService(apiClient: apiClient);

      final hubs = await service.getWorkshops();

      expect(hubs.isNotEmpty, isTrue);
      expect(hubs.any((h) => h.area == 'Atul Kataria Chowk'), isTrue);
    });
  });
}
