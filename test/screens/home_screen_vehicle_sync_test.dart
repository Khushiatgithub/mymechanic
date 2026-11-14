import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mymechanic/core/network/api_client.dart';
import 'package:mymechanic/data/mock_data.dart';
import 'package:mymechanic/models/vehicle.dart';
import 'package:mymechanic/screens/garage/garage_screen.dart';
import 'package:mymechanic/screens/home/home_screen.dart';
import 'package:mymechanic/services/auth_service.dart';
import 'package:mymechanic/services/vehicle_service.dart';

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
  late List<Vehicle> initialMockVehicles;

  setUp(() {
    storageDriver = FakeSecureStorageDriver();
    initialMockVehicles = List<Vehicle>.from(MockData.guestVehicles);
    MockData.resetToGuestVehicles();
  });

  tearDown(() {
    MockData.vehicles = List<Vehicle>.from(initialMockVehicles);
    MockData.vehiclesNotifier.value = List<Vehicle>.from(initialMockVehicles);
  });

  Widget buildSubject({
    required VehicleService vehicleService,
    required AuthService authService,
  }) {
    return MaterialApp(
      home: HomeScreen(
        onNavigateToServices: () {},
        onNavigateToServicesWithCategory: (_) {},
        onNavigateToServicesWithSearch: (_) {},
        onNavigateToBookings: () {},
        vehicleService: vehicleService,
        authService: authService,
      ),
    );
  }

  void configurePhoneSize(WidgetTester tester) {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  }

  group('HomeScreen Vehicle Auto-Synchronization (Phase 3 Step 4.13)', () {
    testWidgets('Guest startup retains the existing guest experience without backend calls', (tester) async {
      configurePhoneSize(tester);

      int getVehiclesCallCount = 0;
      final mockClient = MockClient((request) async {
        if (request.url.path == '/api/v1/vehicles') {
          getVehiclesCallCount++;
        }
        return http.Response('{}', 200);
      });

      final authService = AuthService.createDefault(
        baseUrl: testBaseUrl,
        client: mockClient,
        storageDriver: storageDriver,
      );
      final apiClient = ApiClient(
        baseUrl: testBaseUrl,
        client: mockClient,
        tokenProvider: () async => null,
      );
      final vehicleService = VehicleService(apiClient: apiClient);

      await tester.pumpWidget(buildSubject(
        vehicleService: vehicleService,
        authService: authService,
      ));
      await tester.pumpAndSettle();

      // Guest vehicle from canonical MockData is shown
      expect(find.text('Hyundai Creta'), findsOneWidget);
      expect(find.text('KA 01 MJ 4521'), findsOneWidget);
      expect(getVehiclesCallCount, equals(0));
    });

    testWidgets('Authenticated startup loads vehicles before HomeScreen requires them', (tester) async {
      configurePhoneSize(tester);

      final userVehicle = {
        '_id': 'veh_server_99',
        'userId': 'usr_123',
        'make': 'BMW',
        'model': '3 Series',
        'variant': '330i M Sport',
        'registrationNumber': 'KA05MM9999',
        'fuelType': 'Petrol',
        'year': 2024,
        'isActive': true,
      };

      final mockClient = MockClient((request) async {
        if (request.url.path == '/api/v1/auth/me') {
          return http.Response(
            jsonEncode({
              'id': 'usr_123',
              'name': 'Priya Sharma',
              'email': 'priya@example.com',
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        if (request.url.path == '/api/v1/vehicles' && request.method == 'GET') {
          return http.Response(
            jsonEncode({
              'success': true,
              'data': {
                'items': [userVehicle],
              },
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response('{}', 404);
      });

      // Save valid tokens to simulate active session on launch
      await storageDriver.write(key: 'mymechanic_access_token', value: 'valid_access_token');
      await storageDriver.write(key: 'mymechanic_refresh_token', value: 'valid_refresh_token');

      final authService = AuthService.createDefault(
        baseUrl: testBaseUrl,
        client: mockClient,
        storageDriver: storageDriver,
      );
      final apiClient = ApiClient(
        baseUrl: testBaseUrl,
        client: mockClient,
        tokenProvider: () async => 'valid_access_token',
      );
      final vehicleService = VehicleService(apiClient: apiClient);

      // Startup session restoration verifies authentication
      await authService.initialize();
      expect(authService.isAuthenticated, isTrue);

      await tester.pumpWidget(buildSubject(
        vehicleService: vehicleService,
        authService: authService,
      ));
      await tester.pumpAndSettle();

      // Verified server vehicle is displayed on HomeScreen automatically
      expect(find.text('BMW 3 Series'), findsOneWidget);
      expect(find.text('KA05MM9999'), findsOneWidget);
      expect(find.text('KA 01 MJ 4521'), findsNothing);
    });

    testWidgets('Login triggers vehicle synchronization without opening GarageScreen', (tester) async {
      configurePhoneSize(tester);

      final mockClient = MockClient((request) async {
        if (request.url.path == '/api/v1/auth/login') {
          return http.Response(
            jsonEncode({
              'user': {
                'id': 'usr_456',
                'name': 'Rahul Verma',
                'email': 'rahul@example.com',
              },
              'accessToken': 'rahul_access_token',
              'refreshToken': 'rahul_refresh_token',
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        if (request.url.path == '/api/v1/vehicles' && request.method == 'GET') {
          return http.Response(
            jsonEncode({
              'success': true,
              'data': {
                'items': [
                  {
                    '_id': 'veh_server_audi',
                    'userId': 'usr_456',
                    'make': 'Audi',
                    'model': 'A4',
                    'variant': 'Technology 40 TFSI',
                    'registrationNumber': 'KA03TF8888',
                    'fuelType': 'Petrol',
                    'year': 2023,
                    'isActive': true,
                  },
                ],
              },
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response('{}', 404);
      });

      final authService = AuthService.createDefault(
        baseUrl: testBaseUrl,
        client: mockClient,
        storageDriver: storageDriver,
      );
      final apiClient = ApiClient(
        baseUrl: testBaseUrl,
        client: mockClient,
        tokenProvider: () async => 'rahul_access_token',
      );
      final vehicleService = VehicleService(apiClient: apiClient);

      // Mount HomeScreen in guest mode
      await tester.pumpWidget(buildSubject(
        vehicleService: vehicleService,
        authService: authService,
      ));
      await tester.pumpAndSettle();

      expect(find.text('Hyundai Creta'), findsOneWidget);

      // Simulate customer logging in (e.g. from Profile or Login sheet)
      await authService.login(email: 'rahul@example.com', password: 'password123');
      await tester.pumpAndSettle();

      // HomeScreen must automatically show the newly logged-in user's vehicle
      expect(find.text('Audi A4'), findsOneWidget);
      expect(find.text('KA03TF8888'), findsOneWidget);
      expect(find.text('Hyundai Creta'), findsNothing);
    });

    testWidgets('Logout clears authenticated vehicle state and restores the guest experience', (tester) async {
      configurePhoneSize(tester);

      final mockClient = MockClient((request) async {
        if (request.url.path == '/api/v1/auth/logout') {
          return http.Response(jsonEncode({'success': true}), 200);
        }
        if (request.url.path == '/api/v1/vehicles' && request.method == 'GET') {
          return http.Response(
            jsonEncode({
              'success': true,
              'data': {
                'items': [
                  {
                    '_id': 'veh_server_audi',
                    'userId': 'usr_456',
                    'make': 'Audi',
                    'model': 'A4',
                    'variant': 'Technology 40 TFSI',
                    'registrationNumber': 'KA03TF8888',
                    'fuelType': 'Petrol',
                    'year': 2023,
                    'isActive': true,
                  },
                ],
              },
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response('{}', 404);
      });

      final authService = AuthService.createDefault(
        baseUrl: testBaseUrl,
        client: mockClient,
        storageDriver: storageDriver,
      );
      final apiClient = ApiClient(
        baseUrl: testBaseUrl,
        client: mockClient,
        tokenProvider: () async => 'rahul_access_token',
      );
      final vehicleService = VehicleService(apiClient: apiClient);

      // Simulate authenticated user
      authService.authStatusNotifier.value = AuthStatus.authenticated;
      authService.isAuthenticatedNotifier.value = true;

      await tester.pumpWidget(buildSubject(
        vehicleService: vehicleService,
        authService: authService,
      ));
      await tester.pumpAndSettle();

      expect(find.text('Audi A4'), findsOneWidget);

      // Perform logout
      await authService.logout();
      await tester.pumpAndSettle();

      // Guest vehicles cleanly restored on HomeScreen
      expect(find.text('Hyundai Creta'), findsOneWidget);
      expect(find.text('KA 01 MJ 4521'), findsOneWidget);
      expect(find.text('Audi A4'), findsNothing);
    });

    testWidgets('Vehicle changes made in GarageScreen are reflected on HomeScreen through shared state', (tester) async {
      configurePhoneSize(tester);

      final vehicles = [
        Vehicle(
          id: 'veh_01',
          brand: 'Toyota',
          model: 'Fortuner',
          variant: 'Legender 4x4',
          fuelType: 'Diesel',
          registrationNumber: 'KA04TO9999',
          year: 2023,
          serviceDueStatus: 'Up to date',
          isPrimary: true,
        ),
        Vehicle(
          id: 'veh_02',
          brand: 'Honda',
          model: 'City',
          variant: 'ZX CVT',
          fuelType: 'Petrol',
          registrationNumber: 'KA01HO1234',
          year: 2022,
          serviceDueStatus: 'Due in 15 days',
          isPrimary: false,
        ),
      ];

      final mockClient = MockClient((request) async {
        if (request.url.path == '/api/v1/vehicles' && request.method == 'GET') {
          return http.Response(
            jsonEncode({
              'success': true,
              'data': {
                'items': vehicles.map((v) => v.toBackendJson()..['_id'] = v.id).toList(),
              },
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        if (request.url.path == '/api/v1/vehicles/veh_02/active' && request.method == 'PATCH') {
          return http.Response(
            jsonEncode({
              'success': true,
              'data': vehicles[1].copyWith(isPrimary: true).toBackendJson()..['_id'] = 'veh_02',
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response('{}', 404);
      });

      final authService = AuthService.createDefault(
        baseUrl: testBaseUrl,
        client: mockClient,
        storageDriver: storageDriver,
      );
      final apiClient = ApiClient(
        baseUrl: testBaseUrl,
        client: mockClient,
        tokenProvider: () async => 'test_token',
      );
      final vehicleService = VehicleService(apiClient: apiClient);

      authService.authStatusNotifier.value = AuthStatus.authenticated;
      authService.isAuthenticatedNotifier.value = true;

      await tester.pumpWidget(
        MaterialApp(
          home: HomeScreen(
            onNavigateToServices: () {},
            onNavigateToServicesWithCategory: (_) {},
            onNavigateToServicesWithSearch: (_) {},
            onNavigateToBookings: () {},
            vehicleService: vehicleService,
            authService: authService,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Initially Fortuner is primary
      expect(find.text('Toyota Fortuner'), findsOneWidget);

      // Tap "Manage Garage" to open GarageScreen
      await tester.tap(find.text('Manage Garage'));
      await tester.pumpAndSettle();

      expect(find.byType(GarageScreen), findsOneWidget);

      // In GarageScreen, tap "Set as Active Vehicle" on Honda City
      final setAsActiveFinder = find.text('Set as Active Vehicle');
      expect(setAsActiveFinder, findsOneWidget);
      await tester.tap(setAsActiveFinder);
      await tester.pumpAndSettle();

      // Return to HomeScreen
      final backButton = find.byType(BackButton);
      if (backButton.evaluate().isNotEmpty) {
        await tester.tap(backButton);
        await tester.pumpAndSettle();
      }

      // HomeScreen has reactively updated to Honda City through shared MockData.vehiclesNotifier
      expect(find.text('Honda City'), findsOneWidget);
      expect(find.text('KA01HO1234'), findsOneWidget);
    });

    testWidgets('A failed vehicle request does not crash HomeScreen or block UI', (tester) async {
      configurePhoneSize(tester);

      final mockClient = MockClient((request) async {
        if (request.url.path == '/api/v1/vehicles') {
          return http.Response('{"message":"Internal Server Error"}', 500);
        }
        return http.Response('{}', 404);
      });

      final authService = AuthService.createDefault(
        baseUrl: testBaseUrl,
        client: mockClient,
        storageDriver: storageDriver,
      );
      final apiClient = ApiClient(
        baseUrl: testBaseUrl,
        client: mockClient,
        tokenProvider: () async => 'test_token',
      );
      final vehicleService = VehicleService(apiClient: apiClient);

      authService.authStatusNotifier.value = AuthStatus.authenticated;
      authService.isAuthenticatedNotifier.value = true;

      // Mount HomeScreen while server is throwing 500 error
      await tester.pumpWidget(buildSubject(
        vehicleService: vehicleService,
        authService: authService,
      ));
      await tester.pumpAndSettle();

      // HomeScreen renders safely without crashing
      expect(find.byType(HomeScreen), findsOneWidget);
      expect(find.text('My Vehicle'), findsOneWidget);
    });

    testWidgets('A late response from a previous authenticated session cannot overwrite newer session', (tester) async {
      configurePhoneSize(tester);

      final session1Completer = Completer<http.Response>();

      final mockClient = MockClient((request) async {
        if (request.url.path == '/api/v1/vehicles') {
          if (request.headers['Authorization'] == 'Bearer token_user_1') {
            return session1Completer.future;
          }
          if (request.headers['Authorization'] == 'Bearer token_user_2') {
            return http.Response(
              jsonEncode({
                'success': true,
                'data': {
                  'items': [
                    {
                      '_id': 'veh_user_2',
                      'userId': 'usr_2',
                      'make': 'Porsche',
                      'model': 'Macan',
                      'variant': 'GTS',
                      'registrationNumber': 'KA01PO7777',
                      'fuelType': 'Petrol',
                      'year': 2024,
                      'isActive': true,
                    },
                  ],
                },
              }),
              200,
              headers: {'content-type': 'application/json'},
            );
          }
        }
        return http.Response('{}', 404);
      });

      String currentToken = 'token_user_1';
      final authService = AuthService.createDefault(
        baseUrl: testBaseUrl,
        client: mockClient,
        storageDriver: storageDriver,
      );
      final apiClient = ApiClient(
        baseUrl: testBaseUrl,
        client: mockClient,
        tokenProvider: () async => currentToken,
      );
      final vehicleService = VehicleService(apiClient: apiClient);

      // User 1 logs in
      authService.authStatusNotifier.value = AuthStatus.authenticated;
      authService.isAuthenticatedNotifier.value = true;

      await tester.pumpWidget(buildSubject(
        vehicleService: vehicleService,
        authService: authService,
      ));
      await tester.pump(); // syncUserVehicles for User 1 starts and waits on session1Completer

      // User 1 logs out, User 2 logs in with force sync
      vehicleService.resetVehicles();
      currentToken = 'token_user_2';
      await vehicleService.syncUserVehicles(authService: authService, force: true);
      await tester.pumpAndSettle();

      expect(find.text('Porsche Macan'), findsOneWidget);

      // Now User 1's delayed network response returns late
      session1Completer.complete(
        http.Response(
          jsonEncode({
            'success': true,
            'data': {
              'items': [
                {
                  '_id': 'veh_user_1',
                  'userId': 'usr_1',
                  'make': 'Old Car',
                  'model': 'User 1 Model',
                  'variant': 'Base',
                  'registrationNumber': 'KA01OLD111',
                  'fuelType': 'Petrol',
                  'year': 2018,
                  'isActive': true,
                },
              ],
            },
          }),
          200,
          headers: {'content-type': 'application/json'},
        ),
      );
      await tester.pumpAndSettle();

      // Verify User 1's late response was rejected and Porsche Macan is still shown
      expect(find.text('Porsche Macan'), findsOneWidget);
      expect(find.text('Old Car User 1 Model'), findsNothing);
    });

    testWidgets('Respects existing active-vehicle selection and fallback rules', (tester) async {
      configurePhoneSize(tester);

      // Server returns 2 vehicles, neither marked active
      final mockClient = MockClient((request) async {
        if (request.url.path == '/api/v1/vehicles') {
          return http.Response(
            jsonEncode({
              'success': true,
              'data': {
                'items': [
                  {
                    '_id': 'veh_unmarked_1',
                    'make': 'Mahindra',
                    'model': 'XUV700',
                    'variant': 'AX7 Luxury',
                    'registrationNumber': 'KA05MH7000',
                    'fuelType': 'Diesel',
                    'year': 2023,
                    'isActive': false,
                  },
                  {
                    '_id': 'veh_unmarked_2',
                    'make': 'Kia',
                    'model': 'Seltos',
                    'variant': 'GTX+ Turbo',
                    'registrationNumber': 'KA05KI1234',
                    'fuelType': 'Petrol',
                    'year': 2023,
                    'isActive': false,
                  },
                ],
              },
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response('{}', 404);
      });

      final authService = AuthService.createDefault(
        baseUrl: testBaseUrl,
        client: mockClient,
        storageDriver: storageDriver,
      );
      final apiClient = ApiClient(
        baseUrl: testBaseUrl,
        client: mockClient,
        tokenProvider: () async => 'test_token',
      );
      final vehicleService = VehicleService(apiClient: apiClient);

      authService.authStatusNotifier.value = AuthStatus.authenticated;
      authService.isAuthenticatedNotifier.value = true;

      await tester.pumpWidget(buildSubject(
        vehicleService: vehicleService,
        authService: authService,
      ));
      await tester.pumpAndSettle();

      // Fallback rule picks the first vehicle when neither is marked active
      expect(find.text('Mahindra XUV700'), findsOneWidget);
      expect(find.text('KA05MH7000'), findsOneWidget);
    });
  });
}
