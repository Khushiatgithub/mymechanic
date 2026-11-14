import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mymechanic/core/network/api_client.dart';
import 'package:mymechanic/models/vehicle.dart';
import 'package:mymechanic/services/vehicle_service.dart';

void main() {
  const testBaseUrl = 'https://api.mymechanic.test/api/v1';

  group('VehicleService - API Operations', () {
    test('getVehicles returns list of Vehicle models when response contains items array', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.path, equals('/api/v1/vehicles'));
        expect(request.method, equals('GET'));
        expect(request.headers['Authorization'], equals('Bearer test_access_token'));

        return http.Response(
          jsonEncode({
            'success': true,
            'message': 'Vehicles fetched successfully',
            'data': {
              'items': [
                {
                  '_id': 'veh_001',
                  'userId': 'usr_123',
                  'make': 'Hyundai',
                  'model': 'Creta',
                  'variant': 'SX (O)',
                  'registrationNumber': 'KA01MJ5050',
                  'fuelType': 'Petrol',
                  'year': 2022,
                  'isActive': true,
                  'createdAt': '2026-01-10T10:00:00.000Z',
                  'updatedAt': '2026-01-10T10:00:00.000Z',
                },
                {
                  '_id': 'veh_002',
                  'userId': 'usr_123',
                  'make': 'Tata',
                  'model': 'Nexon EV',
                  'variant': 'Empowered Plus',
                  'registrationNumber': 'KA05EV1234',
                  'fuelType': 'Electric',
                  'year': 2023,
                  'isActive': false,
                  'createdAt': '2026-01-12T10:00:00.000Z',
                  'updatedAt': '2026-01-12T10:00:00.000Z',
                },
              ],
              'pagination': {
                'page': 1,
                'limit': 10,
                'total': 2,
                'pages': 1,
              },
            },
          }),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      });

      final apiClient = ApiClient(
        baseUrl: testBaseUrl,
        client: mockClient,
        tokenProvider: () async => 'test_access_token',
      );
      final service = VehicleService(apiClient: apiClient);

      final vehicles = await service.getVehicles();

      expect(vehicles.length, equals(2));
      expect(vehicles[0].id, equals('veh_001'));
      expect(vehicles[0].brand, equals('Hyundai'));
      expect(vehicles[0].model, equals('Creta'));
      expect(vehicles[0].variant, equals('SX (O)'));
      expect(vehicles[0].registrationNumber, equals('KA01MJ5050'));
      expect(vehicles[0].fuelType, equals('Petrol'));
      expect(vehicles[0].year, equals(2022));
      expect(vehicles[0].isPrimary, isTrue);

      expect(vehicles[1].id, equals('veh_002'));
      expect(vehicles[1].brand, equals('Tata'));
      expect(vehicles[1].isPrimary, isFalse);
    });

    test('getVehicles returns empty list when user has no registered vehicles', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'success': true,
            'message': 'Vehicles fetched successfully',
            'data': {
              'items': [],
              'pagination': {'page': 1, 'limit': 10, 'total': 0, 'pages': 0},
            },
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final apiClient = ApiClient(
        baseUrl: testBaseUrl,
        client: mockClient,
        tokenProvider: () async => 'test_access_token',
      );
      final service = VehicleService(apiClient: apiClient);

      final vehicles = await service.getVehicles();
      expect(vehicles, isEmpty);
    });

    test('getVehicleById returns single vehicle on success', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.path, equals('/api/v1/vehicles/veh_001'));
        expect(request.method, equals('GET'));

        return http.Response(
          jsonEncode({
            'success': true,
            'message': 'Vehicle fetched successfully',
            'data': {
              '_id': 'veh_001',
              'userId': 'usr_123',
              'make': 'Hyundai',
              'model': 'Creta',
              'variant': 'SX (O)',
              'registrationNumber': 'KA01MJ5050',
              'fuelType': 'Petrol',
              'year': 2022,
              'isActive': true,
            },
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final apiClient = ApiClient(
        baseUrl: testBaseUrl,
        client: mockClient,
        tokenProvider: () async => 'test_access_token',
      );
      final service = VehicleService(apiClient: apiClient);

      final vehicle = await service.getVehicleById('veh_001');
      expect(vehicle.id, equals('veh_001'));
      expect(vehicle.brand, equals('Hyundai'));
      expect(vehicle.registrationNumber, equals('KA01MJ5050'));
    });

    test('createVehicle sends expected backend payload schema and returns created model', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.path, equals('/api/v1/vehicles'));
        expect(request.method, equals('POST'));

        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body['make'], equals('Honda'));
        expect(body['model'], equals('City'));
        expect(body['variant'], equals('ZX'));
        expect(body['registrationNumber'], equals('KA03HA9999'));
        expect(body['fuelType'], equals('Petrol'));
        expect(body['year'], equals(2023));
        expect(body['isActive'], isTrue);
        // Client must never send arbitrary userId
        expect(body.containsKey('userId'), isFalse);

        return http.Response(
          jsonEncode({
            'success': true,
            'message': 'Vehicle created successfully',
            'data': {
              '_id': 'veh_new_123',
              'userId': 'usr_from_jwt',
              'make': 'Honda',
              'model': 'City',
              'variant': 'ZX',
              'registrationNumber': 'KA03HA9999',
              'fuelType': 'Petrol',
              'year': 2023,
              'isActive': true,
            },
          }),
          201,
          headers: {'content-type': 'application/json'},
        );
      });

      final apiClient = ApiClient(
        baseUrl: testBaseUrl,
        client: mockClient,
        tokenProvider: () async => 'test_access_token',
      );
      final service = VehicleService(apiClient: apiClient);

      const newVehicle = Vehicle(
        id: '',
        brand: 'Honda',
        model: 'City',
        variant: 'ZX',
        registrationNumber: 'ka03ha9999',
        fuelType: 'Petrol',
        year: 2023,
        serviceDueStatus: 'Up to date',
        isPrimary: true,
      );

      final created = await service.createVehicle(newVehicle);
      expect(created.id, equals('veh_new_123'));
      expect(created.brand, equals('Honda'));
      expect(created.model, equals('City'));
      expect(created.registrationNumber, equals('KA03HA9999'));
      expect(created.isPrimary, isTrue);
    });

    test('updateVehicle sends PATCH request and returns updated model', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.path, equals('/api/v1/vehicles/veh_001'));
        expect(request.method, equals('PATCH'));

        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body['make'], equals('Hyundai'));
        expect(body['model'], equals('Creta Facelift'));

        return http.Response(
          jsonEncode({
            'success': true,
            'message': 'Vehicle updated successfully',
            'data': {
              '_id': 'veh_001',
              'userId': 'usr_123',
              'make': 'Hyundai',
              'model': 'Creta Facelift',
              'variant': 'SX (O)',
              'registrationNumber': 'KA01MJ5050',
              'fuelType': 'Petrol',
              'year': 2024,
              'isActive': true,
            },
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final apiClient = ApiClient(
        baseUrl: testBaseUrl,
        client: mockClient,
        tokenProvider: () async => 'test_access_token',
      );
      final service = VehicleService(apiClient: apiClient);

      const vehicleToUpdate = Vehicle(
        id: 'veh_001',
        brand: 'Hyundai',
        model: 'Creta Facelift',
        variant: 'SX (O)',
        registrationNumber: 'KA01MJ5050',
        fuelType: 'Petrol',
        year: 2024,
        serviceDueStatus: 'Up to date',
        isPrimary: true,
      );

      final updated = await service.updateVehicle(vehicleToUpdate);
      expect(updated.id, equals('veh_001'));
      expect(updated.model, equals('Creta Facelift'));
      expect(updated.year, equals(2024));
    });

    test('setActiveVehicle calls /:id/active endpoint and returns updated vehicle', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.path, equals('/api/v1/vehicles/veh_002/active'));
        expect(request.method, equals('PATCH'));

        return http.Response(
          jsonEncode({
            'success': true,
            'message': 'Active vehicle updated successfully',
            'data': {
              '_id': 'veh_002',
              'userId': 'usr_123',
              'make': 'Tata',
              'model': 'Nexon EV',
              'variant': 'Empowered Plus',
              'registrationNumber': 'KA05EV1234',
              'fuelType': 'Electric',
              'year': 2023,
              'isActive': true,
            },
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final apiClient = ApiClient(
        baseUrl: testBaseUrl,
        client: mockClient,
        tokenProvider: () async => 'test_access_token',
      );
      final service = VehicleService(apiClient: apiClient);

      final active = await service.setActiveVehicle('veh_002');
      expect(active.id, equals('veh_002'));
      expect(active.isPrimary, isTrue);
    });

    test('deleteVehicle calls DELETE /api/v1/vehicles/:id', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.path, equals('/api/v1/vehicles/veh_002'));
        expect(request.method, equals('DELETE'));

        return http.Response(
          jsonEncode({
            'success': true,
            'message': 'Vehicle deleted successfully',
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final apiClient = ApiClient(
        baseUrl: testBaseUrl,
        client: mockClient,
        tokenProvider: () async => 'test_access_token',
      );
      final service = VehicleService(apiClient: apiClient);

      await expectLater(service.deleteVehicle('veh_002'), completes);
    });
  });

  group('VehicleService - Error Handling & Error Message Mapping', () {
    test('Throws HttpStatusException with 409 VEHICLE_ALREADY_EXISTS and maps message cleanly', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'success': false,
            'message': 'Vehicle with this registration number already exists',
            'error': {'code': 'VEHICLE_ALREADY_EXISTS'},
          }),
          409,
          headers: {'content-type': 'application/json'},
        );
      });

      final apiClient = ApiClient(baseUrl: testBaseUrl, client: mockClient);
      final service = VehicleService(apiClient: apiClient);

      const vehicle = Vehicle(
        id: '',
        brand: 'Honda',
        model: 'City',
        variant: 'ZX',
        registrationNumber: 'KA01MJ5050',
        fuelType: 'Petrol',
        year: 2022,
        serviceDueStatus: 'Up to date',
      );

      try {
        await service.createVehicle(vehicle);
        fail('Should throw HttpStatusException');
      } catch (e) {
        expect(e, isA<HttpStatusException>());
        final errorMsg = VehicleService.getErrorMessage(e);
        expect(errorMsg, equals('A vehicle with this registration number already exists in your garage.'));
      }
    });

    test('Throws HttpStatusException with 409 VEHICLE_HAS_ACTIVE_BOOKINGS on delete and maps message cleanly', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'success': false,
            'message': 'Cannot delete vehicle with active bookings',
            'error': {'code': 'VEHICLE_HAS_ACTIVE_BOOKINGS'},
          }),
          409,
          headers: {'content-type': 'application/json'},
        );
      });

      final apiClient = ApiClient(baseUrl: testBaseUrl, client: mockClient);
      final service = VehicleService(apiClient: apiClient);

      try {
        await service.deleteVehicle('veh_001');
        fail('Should throw HttpStatusException');
      } catch (e) {
        expect(e, isA<HttpStatusException>());
        final errorMsg = VehicleService.getErrorMessage(e);
        expect(errorMsg, equals('Cannot remove vehicle while an active service booking is in progress.'));
      }
    });

    test('Throws HttpStatusException with 400 validation error and maps message cleanly', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'success': false,
            'message': 'Invalid registration number format',
            'errorCode': 'VALIDATION_ERROR',
          }),
          400,
          headers: {'content-type': 'application/json'},
        );
      });

      final apiClient = ApiClient(baseUrl: testBaseUrl, client: mockClient);
      final service = VehicleService(apiClient: apiClient);

      try {
        await service.createVehicle(const Vehicle(
          id: '',
          brand: 'Honda',
          model: 'City',
          variant: 'ZX',
          registrationNumber: 'BAD',
          fuelType: 'Petrol',
          year: 2022,
          serviceDueStatus: 'Up to date',
        ));
        fail('Should throw HttpStatusException');
      } catch (e) {
        expect(e, isA<HttpStatusException>());
        final errorMsg = VehicleService.getErrorMessage(e);
        expect(errorMsg, equals('Invalid registration number format'));
      }
    });

    test('Throws HttpStatusException with 401 unauthorized and maps message cleanly', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'success': false,
            'message': 'Authentication required',
          }),
          401,
          headers: {'content-type': 'application/json'},
        );
      });

      final apiClient = ApiClient(baseUrl: testBaseUrl, client: mockClient);
      final service = VehicleService(apiClient: apiClient);

      try {
        await service.getVehicles();
        fail('Should throw HttpStatusException');
      } catch (e) {
        expect(e, isA<HttpStatusException>());
        final errorMsg = VehicleService.getErrorMessage(e);
        expect(errorMsg, equals('Please sign in to manage your vehicles.'));
      }
    });

    test('Throws HttpStatusException with 403 forbidden and maps message cleanly', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'success': false,
            'message': 'Forbidden',
          }),
          403,
          headers: {'content-type': 'application/json'},
        );
      });

      final apiClient = ApiClient(baseUrl: testBaseUrl, client: mockClient);
      final service = VehicleService(apiClient: apiClient);

      try {
        await service.deleteVehicle('veh_not_owned');
        fail('Should throw HttpStatusException');
      } catch (e) {
        expect(e, isA<HttpStatusException>());
        final errorMsg = VehicleService.getErrorMessage(e);
        expect(errorMsg, equals('You do not have permission to modify this vehicle.'));
      }
    });

    test('Throws HttpStatusException with 404 not found and maps message cleanly', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'success': false,
            'message': 'Vehicle not found',
          }),
          404,
          headers: {'content-type': 'application/json'},
        );
      });

      final apiClient = ApiClient(baseUrl: testBaseUrl, client: mockClient);
      final service = VehicleService(apiClient: apiClient);

      try {
        await service.getVehicleById('veh_999');
        fail('Should throw HttpStatusException');
      } catch (e) {
        expect(e, isA<HttpStatusException>());
        final errorMsg = VehicleService.getErrorMessage(e);
        expect(errorMsg, equals('Vehicle not found or has already been removed.'));
      }
    });

    test('Throws HttpStatusException with 500 server error and maps message cleanly', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'success': false,
            'message': 'Internal Server Error',
          }),
          500,
          headers: {'content-type': 'application/json'},
        );
      });

      final apiClient = ApiClient(baseUrl: testBaseUrl, client: mockClient);
      final service = VehicleService(apiClient: apiClient);

      try {
        await service.getVehicles();
        fail('Should throw HttpStatusException');
      } catch (e) {
        expect(e, isA<HttpStatusException>());
        final errorMsg = VehicleService.getErrorMessage(e);
        expect(errorMsg, equals('Server error while updating garage. Please try again later.'));
      }
    });

    test('Maps NetworkException cleanly', () {
      const netEx = NetworkException('Socket failed', cause: SocketException('Failed host lookup'));
      expect(
        VehicleService.getErrorMessage(netEx),
        equals('Unable to reach MyMechanic servers. Please check your internet connection.'),
      );
    });

    test('Maps ApiTimeoutException cleanly', () {
      const timeoutEx = ApiTimeoutException(
        'Timeout',
        timeout: Duration(seconds: 15),
      );
      expect(
        VehicleService.getErrorMessage(timeoutEx),
        equals('Request timed out. Please check your connection and try again.'),
      );
    });

    test('Maps AuthSessionException cleanly', () {
      const sessionEx = AuthSessionException('Expired');
      expect(
        VehicleService.getErrorMessage(sessionEx),
        equals('Your session has expired. Please log in again.'),
      );
    });

    test('Throws ApiResponseFormatException when response data is not a Map', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'success': true,
            'data': 'invalid_string',
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final apiClient = ApiClient(baseUrl: testBaseUrl, client: mockClient);
      final service = VehicleService(apiClient: apiClient);

      expect(
        () => service.getVehicleById('veh_001'),
        throwsA(isA<ApiResponseFormatException>()),
      );
    });
  });
}
