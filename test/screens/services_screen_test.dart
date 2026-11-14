import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mymechanic/core/network/api_exception.dart';
import 'package:mymechanic/models/service_category.dart';
import 'package:mymechanic/models/service_item.dart';
import 'package:mymechanic/screens/services/services_screen.dart';
import 'package:mymechanic/services/service_discovery_service.dart';

class FakeServiceDiscoveryService extends ServiceDiscoveryService {
  List<ServiceCategory> categoriesToReturn;
  List<ServiceItem> servicesToReturn;
  Object? errorToThrow;
  Completer<void>? pendingCompleter;
  int getCategoriesCallCount = 0;
  int getServicesCallCount = 0;

  FakeServiceDiscoveryService({
    this.categoriesToReturn = const [],
    this.servicesToReturn = const [],
    this.errorToThrow,
    this.pendingCompleter,
  }) : super(apiClient: ServiceDiscoveryService.instance.apiClient);

  @override
  Future<List<ServiceCategory>> getCategories({
    bool activeOnly = true,
    int page = 1,
    int limit = 50,
  }) async {
    getCategoriesCallCount++;
    if (pendingCompleter != null) {
      await pendingCompleter!.future;
    }
    if (errorToThrow != null) {
      throw errorToThrow!;
    }
    return categoriesToReturn;
  }

  @override
  Future<List<ServiceItem>> getServices({
    String? categoryId,
    String? search,
    String? sort,
    bool activeOnly = true,
    int page = 1,
    int limit = 50,
  }) async {
    getServicesCallCount++;
    if (pendingCompleter != null) {
      await pendingCompleter!.future;
    }
    if (errorToThrow != null) {
      throw errorToThrow!;
    }
    return servicesToReturn;
  }
}

void main() {
  final sampleCategories = [
    const ServiceCategory(
      id: 'cat_periodic',
      name: 'Periodic Services',
      description: 'Scheduled maintenance',
      icon: Icons.build_circle_outlined,
      tintColor: Colors.red,
      backgroundColor: Colors.white,
      sortOrder: 1,
    ),
    const ServiceCategory(
      id: 'cat_ac',
      name: 'AC Service & Repair',
      description: 'Gas refill and cleanup',
      icon: Icons.ac_unit_rounded,
      tintColor: Colors.blue,
      backgroundColor: Colors.white,
      sortOrder: 2,
    ),
  ];

  final sampleServices = [
    const ServiceItem(
      id: 'srv_1',
      categoryId: 'cat_periodic',
      categoryName: 'Periodic Services',
      title: 'Standard Periodic Service',
      description: 'Engine oil replacement and filter check',
      price: 3499,
      originalPrice: 4299,
      durationText: '3-4 Hours',
      rating: 4.8,
      reviewsCount: 120,
      warrantyPeriod: '1000 Kms or 1 Month',
      keyFeatures: ['Castrol Oil', 'Oil Filter'],
      includedItems: ['Castrol Oil', 'Oil Filter'],
    ),
    const ServiceItem(
      id: 'srv_2',
      categoryId: 'cat_ac',
      categoryName: 'AC Service & Repair',
      title: 'Complete AC Service',
      description: 'Condenser wash and refrigerant gas refill',
      price: 1999,
      originalPrice: 2499,
      durationText: '2-3 Hours',
      rating: 4.7,
      reviewsCount: 88,
      warrantyPeriod: '3 Months',
      keyFeatures: ['Gas Top-up', 'Condenser Flush'],
      includedItems: ['Gas Top-up', 'Condenser Flush'],
    ),
  ];

  group('ServicesScreen Widget Tests', () {
    testWidgets('Renders loading spinner initially when fetch is pending', (tester) async {
      final completer = Completer<void>();
      final fakeService = FakeServiceDiscoveryService(
        pendingCompleter: completer,
        categoriesToReturn: sampleCategories,
        servicesToReturn: sampleServices,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: ServicesScreen(
            onNavigateToBookings: () {},
            serviceDiscoveryService: fakeService,
          ),
        ),
      );

      // Immediately should show loading text
      expect(find.text('Loading services...'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Complete fetch
      completer.complete();
      await tester.pumpAndSettle();

      // Loading is dismissed and services appear
      expect(find.text('Loading services...'), findsNothing);
      expect(find.text('Standard Periodic Service'), findsOneWidget);
    });

    testWidgets('Successfully displays backend categories and services', (tester) async {
      final fakeService = FakeServiceDiscoveryService(
        categoriesToReturn: sampleCategories,
        servicesToReturn: sampleServices,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: ServicesScreen(
            onNavigateToBookings: () {},
            serviceDiscoveryService: fakeService,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Category filter chips
      expect(find.text('All Services'), findsOneWidget);
      expect(find.text('Periodic Services'), findsWidgets);
      expect(find.text('AC Service & Repair'), findsWidgets);

      // Service items
      expect(find.text('Standard Periodic Service'), findsOneWidget);
      expect(find.text('Complete AC Service'), findsOneWidget);
      expect(find.text('2 services found'), findsOneWidget);
    });

    testWidgets('Category chip tap filters displayed services to selected category', (tester) async {
      final fakeService = FakeServiceDiscoveryService(
        categoriesToReturn: sampleCategories,
        servicesToReturn: sampleServices,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: ServicesScreen(
            onNavigateToBookings: () {},
            serviceDiscoveryService: fakeService,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap on AC Service & Repair category chip
      final acChip = find.widgetWithText(FilterChip, 'AC Service & Repair');
      expect(acChip, findsOneWidget);
      await tester.tap(acChip);
      await tester.pumpAndSettle();

      // Should show only AC service, not Periodic
      expect(find.text('Complete AC Service'), findsOneWidget);
      expect(find.text('Standard Periodic Service'), findsNothing);
      expect(find.text('1 service found'), findsOneWidget);
    });

    testWidgets('Search query filters services by title or feature', (tester) async {
      final fakeService = FakeServiceDiscoveryService(
        categoriesToReturn: sampleCategories,
        servicesToReturn: sampleServices,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: ServicesScreen(
            onNavigateToBookings: () {},
            serviceDiscoveryService: fakeService,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Enter search text
      await tester.enterText(find.byType(TextField), 'condenser');
      await tester.pumpAndSettle();

      // Only AC service matches condenser
      expect(find.text('Complete AC Service'), findsOneWidget);
      expect(find.text('Standard Periodic Service'), findsNothing);
    });

    testWidgets('Displays empty state and Show All Services button when query matches nothing', (tester) async {
      final fakeService = FakeServiceDiscoveryService(
        categoriesToReturn: sampleCategories,
        servicesToReturn: sampleServices,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: ServicesScreen(
            onNavigateToBookings: () {},
            serviceDiscoveryService: fakeService,
          ),
        ),
      );

      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'nonexistentqueryxyz');
      await tester.pumpAndSettle();

      expect(find.text('No services found'), findsOneWidget);
      expect(find.text('Show All Services'), findsOneWidget);

      // Tap Show All Services
      await tester.tap(find.text('Show All Services'));
      await tester.pumpAndSettle();

      // Both services restored
      expect(find.text('Standard Periodic Service'), findsOneWidget);
      expect(find.text('Complete AC Service'), findsOneWidget);
    });

    testWidgets('Displays error state with Try Again button on API failure and recovers on retry', (tester) async {
      final fakeService = FakeServiceDiscoveryService(
        errorToThrow: const HttpStatusException(statusCode: 500, message: 'Database connection failed'),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: ServicesScreen(
            onNavigateToBookings: () {},
            serviceDiscoveryService: fakeService,
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Unable to Load Services'), findsOneWidget);
      expect(find.text('Server error while loading services. Please try again later.'), findsOneWidget);
      expect(find.text('Try Again'), findsOneWidget);

      // Fix error and tap Try Again
      fakeService.errorToThrow = null;
      fakeService.categoriesToReturn = sampleCategories;
      fakeService.servicesToReturn = sampleServices;

      await tester.tap(find.text('Try Again'));
      await tester.pumpAndSettle();

      expect(find.text('Unable to Load Services'), findsNothing);
      expect(find.text('Standard Periodic Service'), findsOneWidget);
      expect(find.text('Complete AC Service'), findsOneWidget);
    });
  });
}
