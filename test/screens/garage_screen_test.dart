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
import 'package:mymechanic/services/auth_service.dart';
import 'package:mymechanic/services/vehicle_service.dart';
import 'package:mymechanic/widgets/vehicle/vehicle_form_sheet.dart';

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
    initialMockVehicles = List<Vehicle>.from(MockData.vehicles);
  });

  tearDown(() {
    MockData.vehicles = List<Vehicle>.from(initialMockVehicles);
    MockData.vehiclesNotifier.value = List<Vehicle>.from(initialMockVehicles);
  });

  Widget createTestWidget(Widget child) {
    return MaterialApp(
      home: child,
    );
  }

  void configurePhoneSize(WidgetTester tester) {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  }

  group('GarageScreen - Authenticated Vehicle Management', () {
    testWidgets('Authenticated user loads vehicles from backend and displays them', (tester) async {
      configurePhoneSize(tester);

      final mockClient = MockClient((request) async {
        if (request.url.path == '/api/v1/vehicles' && request.method == 'GET') {
          return http.Response(
            jsonEncode({
              'success': true,
              'message': 'Vehicles fetched',
              'data': {
                'items': [
                  {
                    '_id': 'veh_backend_101',
                    'userId': 'usr_123',
                    'make': 'Hyundai',
                    'model': 'Creta',
                    'variant': 'SX (O)',
                    'registrationNumber': 'KA01MJ5050',
                    'fuelType': 'Petrol',
                    'year': 2022,
                    'isActive': true,
                  },
                ],
                'pagination': {'page': 1, 'limit': 10, 'total': 1, 'pages': 1},
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
      authService.authStatusNotifier.value = AuthStatus.authenticated;

      final vehicleService = VehicleService(
        apiClient: ApiClient(baseUrl: testBaseUrl, client: mockClient),
      );

      await tester.pumpWidget(
        createTestWidget(
          GarageScreen(
            authService: authService,
            vehicleService: vehicleService,
          ),
        ),
      );

      // Initial loading state
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Loading your garage...'), findsOneWidget);

      await tester.pumpAndSettle();

      // Verified loaded state
      expect(find.text('Hyundai Creta'), findsOneWidget);
      expect(find.text('KA01MJ5050'), findsOneWidget);
      expect(find.text('ACTIVE VEHICLE'), findsOneWidget);
      expect(find.text('YOUR SAVED VEHICLES (1)'), findsOneWidget);
    });

    testWidgets('Authenticated user with no vehicles sees clean empty state', (tester) async {
      configurePhoneSize(tester);

      final mockClient = MockClient((request) async {
        if (request.url.path == '/api/v1/vehicles' && request.method == 'GET') {
          return http.Response(
            jsonEncode({
              'success': true,
              'message': 'Vehicles fetched',
              'data': {
                'items': [],
                'pagination': {'page': 1, 'limit': 10, 'total': 0, 'pages': 0},
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
      authService.authStatusNotifier.value = AuthStatus.authenticated;

      final vehicleService = VehicleService(
        apiClient: ApiClient(baseUrl: testBaseUrl, client: mockClient),
      );

      await tester.pumpWidget(
        createTestWidget(
          GarageScreen(
            authService: authService,
            vehicleService: vehicleService,
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('No Vehicles in Garage'), findsOneWidget);
      expect(find.text('Add Your First Car'), findsOneWidget);
    });

    testWidgets('Shows error state with retry button on API failure, and retrying loads vehicles', (tester) async {
      configurePhoneSize(tester);
      int requestCount = 0;

      final mockClient = MockClient((request) async {
        requestCount++;
        if (requestCount == 1) {
          return http.Response(
            jsonEncode({'success': false, 'message': 'Internal Server Error'}),
            500,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response(
          jsonEncode({
            'success': true,
            'message': 'Vehicles fetched',
            'data': {
              'items': [
                {
                  '_id': 'veh_retry_1',
                  'userId': 'usr_123',
                  'make': 'Tata',
                  'model': 'Harrier',
                  'variant': 'XZ+',
                  'registrationNumber': 'MH12AB1234',
                  'fuelType': 'Diesel',
                  'year': 2021,
                  'isActive': true,
                },
              ],
            },
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final authService = AuthService.createDefault(
        baseUrl: testBaseUrl,
        client: mockClient,
        storageDriver: storageDriver,
      );
      authService.authStatusNotifier.value = AuthStatus.authenticated;

      final vehicleService = VehicleService(
        apiClient: ApiClient(baseUrl: testBaseUrl, client: mockClient),
      );

      await tester.pumpWidget(
        createTestWidget(
          GarageScreen(
            authService: authService,
            vehicleService: vehicleService,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Error UI
      expect(find.text('Unable to Load Garage'), findsOneWidget);
      expect(find.text('Server error while updating garage. Please try again later.'), findsOneWidget);
      expect(find.text('Try Again'), findsOneWidget);

      // Tap Retry
      await tester.tap(find.text('Try Again'));
      await tester.pumpAndSettle();

      expect(find.text('Tata Harrier'), findsOneWidget);
      expect(find.text('MH12AB1234'), findsOneWidget);
    });

    testWidgets('Authenticated delete removes vehicle after confirmation', (tester) async {
      configurePhoneSize(tester);
      bool deleteCalled = false;

      final mockClient = MockClient((request) async {
        if (request.url.path == '/api/v1/vehicles' && request.method == 'GET') {
          return http.Response(
            jsonEncode({
              'success': true,
              'data': {
                'items': [
                  {
                    '_id': 'veh_del_1',
                    'make': 'Maruti Suzuki',
                    'model': 'Swift',
                    'variant': 'ZXi',
                    'registrationNumber': 'DL01AB1111',
                    'fuelType': 'Petrol',
                    'year': 2020,
                    'isActive': true,
                  },
                  {
                    '_id': 'veh_del_2',
                    'make': 'Honda',
                    'model': 'Amaze',
                    'variant': 'VX',
                    'registrationNumber': 'DL01CD2222',
                    'fuelType': 'Diesel',
                    'year': 2019,
                    'isActive': false,
                  },
                ],
              },
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        if (request.url.path == '/api/v1/vehicles/veh_del_2' && request.method == 'DELETE') {
          deleteCalled = true;
          return http.Response(
            jsonEncode({'success': true, 'message': 'Vehicle deleted'}),
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
      authService.authStatusNotifier.value = AuthStatus.authenticated;

      final vehicleService = VehicleService(
        apiClient: ApiClient(baseUrl: testBaseUrl, client: mockClient),
      );

      await tester.pumpWidget(
        createTestWidget(
          GarageScreen(
            authService: authService,
            vehicleService: vehicleService,
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Honda Amaze'), findsOneWidget);

      // Find the delete button for Amaze (second vehicle card)
      final deleteButtons = find.byTooltip('Delete Vehicle');
      expect(deleteButtons, findsNWidgets(2));

      await tester.tap(deleteButtons.at(1));
      await tester.pumpAndSettle();

      // Confirmation dialog
      expect(find.text('Remove Vehicle?'), findsOneWidget);
      expect(find.text('Delete'), findsOneWidget);

      // Confirm delete
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      expect(deleteCalled, isTrue);
      expect(find.text('Honda Amaze'), findsNothing);
      expect(find.text('Maruti Suzuki Swift'), findsOneWidget);
    });

    testWidgets('Authenticated set active vehicle triggers backend API and updates badge', (tester) async {
      configurePhoneSize(tester);
      bool setActiveCalled = false;

      final mockClient = MockClient((request) async {
        if (request.url.path == '/api/v1/vehicles' && request.method == 'GET') {
          return http.Response(
            jsonEncode({
              'success': true,
              'data': {
                'items': [
                  {
                    '_id': 'veh_act_1',
                    'make': 'Maruti Suzuki',
                    'model': 'Baleno',
                    'variant': 'Alpha',
                    'registrationNumber': 'KA01AA1000',
                    'fuelType': 'Petrol',
                    'year': 2021,
                    'isActive': true,
                  },
                  {
                    '_id': 'veh_act_2',
                    'make': 'Kia',
                    'model': 'Seltos',
                    'variant': 'GTX',
                    'registrationNumber': 'KA01BB2000',
                    'fuelType': 'Diesel',
                    'year': 2022,
                    'isActive': false,
                  },
                ],
              },
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        if (request.url.path == '/api/v1/vehicles/veh_act_2/active' && request.method == 'PATCH') {
          setActiveCalled = true;
          return http.Response(
            jsonEncode({
              'success': true,
              'message': 'Active vehicle updated',
              'data': {
                '_id': 'veh_act_2',
                'make': 'Kia',
                'model': 'Seltos',
                'variant': 'GTX',
                'registrationNumber': 'KA01BB2000',
                'fuelType': 'Diesel',
                'year': 2022,
                'isActive': true,
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
      authService.authStatusNotifier.value = AuthStatus.authenticated;

      final vehicleService = VehicleService(
        apiClient: ApiClient(baseUrl: testBaseUrl, client: mockClient),
      );

      await tester.pumpWidget(
        createTestWidget(
          GarageScreen(
            authService: authService,
            vehicleService: vehicleService,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap 'Set as Active Vehicle' button on the Kia Seltos
      final setActiveBtn = find.text('Set as Active Vehicle');
      expect(setActiveBtn, findsOneWidget);
      await tester.tap(setActiveBtn);
      await tester.pumpAndSettle();

      expect(setActiveCalled, isTrue);
      expect(find.text('Active vehicle set to Kia Seltos'), findsOneWidget);
    });
  });

  group('GarageScreen - Guest Mode', () {
    testWidgets('Guest mode renders local mock vehicles and operates without backend calls', (tester) async {
      configurePhoneSize(tester);

      bool apiCalled = false;
      final mockClient = MockClient((request) async {
        apiCalled = true;
        return http.Response('{}', 200);
      });
      final authService = AuthService.createDefault(
        baseUrl: testBaseUrl,
        client: mockClient,
        storageDriver: storageDriver,
      );
      // Unauthenticated / guest
      authService.authStatusNotifier.value = AuthStatus.unauthenticated;

      await tester.pumpWidget(
        createTestWidget(
          GarageScreen(
            authService: authService,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // No backend API was called
      expect(apiCalled, isFalse);
      // Mock data vehicles rendered
      expect(find.byType(ListView), findsOneWidget);
      expect(find.text('Hyundai Creta'), findsOneWidget);
    });
  });

  group('VehicleFormSheet - Validation & Submission', () {
    testWidgets('Validates required fields and prevents empty submission', (tester) async {
      configurePhoneSize(tester);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (ctx) => ElevatedButton(
                onPressed: () {
                  VehicleFormSheet.show(
                    context: ctx,
                    onSave: (v) {},
                  );
                },
                child: const Text('Open Sheet'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Sheet'));
      await tester.pumpAndSettle();

      // Tap 'Add Vehicle' without filling required model and reg number
      await tester.tap(find.text('Add Vehicle'));
      await tester.pumpAndSettle();

      expect(find.text('Please enter the car model'), findsOneWidget);
      expect(find.text('Registration number cannot be blank'), findsOneWidget);
    });

    testWidgets('Handles onSaveAsync and prevents duplicate submissions while loading', (tester) async {
      configurePhoneSize(tester);
      final completer = Completer<void>();
      int submitCallCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (ctx) => ElevatedButton(
                onPressed: () {
                  VehicleFormSheet.show(
                    context: ctx,
                    onSaveAsync: (v) async {
                      submitCallCount++;
                      await completer.future;
                    },
                  );
                },
                child: const Text('Open Sheet'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Sheet'));
      await tester.pumpAndSettle();

      // Enter valid model and registration number via TextFormField with matching hintText
      final textFields = find.byType(TextFormField);
      // TextField 0: Model
      await tester.enterText(textFields.at(0), 'Verna');
      // TextField 1: Variant
      // TextField 2: Registration Number
      await tester.enterText(textFields.at(2), 'DL01AA1234');

      // Submit once
      await tester.tap(find.text('Add Vehicle'));
      await tester.pump(); // Start submission

      // Spinner should be visible
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(submitCallCount, equals(1));

      // Attempt second tap while in-flight
      await tester.tap(find.byType(ElevatedButton).last, warnIfMissed: false);
      await tester.pump();

      // Count remains 1
      expect(submitCallCount, equals(1));

      // Complete async save
      completer.complete();
      await tester.pumpAndSettle();

      // Sheet dismissed
      expect(find.text('Add New Vehicle'), findsNothing);
    });
  });
}
