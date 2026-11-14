import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mymechanic/core/network/api_exception.dart';
import 'package:mymechanic/models/booking.dart';
import 'package:mymechanic/models/vehicle.dart';
import 'package:mymechanic/services/booking_service.dart';
import 'package:mymechanic/widgets/booking/booking_flow_sheet.dart';

class MockBookingFlowService extends BookingService {
  Booking? createdBookingToReturn;
  Object? errorToThrow;
  Completer<void>? pendingCompleter;
  int createBookingCallCount = 0;

  MockBookingFlowService({
    this.createdBookingToReturn,
    this.errorToThrow,
    this.pendingCompleter,
  }) : super(apiClient: BookingService.instance.apiClient);

  @override
  Future<Booking> createBooking({
    required String vehicleId,
    required String serviceId,
    required DateTime scheduledDate,
    required String scheduledTime,
    String serviceMode = 'doorstep',
    String? address,
    String? couponCode,
    required double subtotal,
    double discount = 0.0,
    double pickupFee = 0.0,
    double gst = 0.0,
    required double totalAmount,
    String? notes,
    String paymentMethod = 'pay_on_delivery',
    String paymentStatus = 'pending',
    String? paymentReference,
    String? workshopId,
    String? workshopName,
    String? assignedMechanic,
  }) async {
    createBookingCallCount++;
    if (pendingCompleter != null) {
      await pendingCompleter!.future;
    }
    if (errorToThrow != null) {
      throw errorToThrow!;
    }
    return createdBookingToReturn ??
        Booking(
          id: '67b8a1000000000000000999',
          bookingNumber: 'MM-2026-9999',
          serviceTitle: 'Engine Tuneup',
          vehicleName: 'Honda City ZX',
          vehicleNumber: 'KA04HH9999',
          dateTime: scheduledDate,
          timeSlot: scheduledTime,
          totalAmount: totalAmount,
          status: BookingStatus.confirmed,
          workshopName: 'MyMechanic Flagship Hub',
          assignedMechanic: 'Rajesh Kumar',
          backendStatus: 'confirmed',
        );
  }
}

void main() {
  final testVehicle = Vehicle(
    id: '67b8a1000000000000000020',
    userId: '67b8a1000000000000000010',
    brand: 'Honda',
    model: 'City',
    variant: 'ZX',
    registrationNumber: 'KA04HH9999',
    fuelType: 'Petrol',
    year: 2022,
    serviceDueStatus: 'Good',
  );

  Widget createSubject({required BookingService bookingService, void Function(Booking)? onConfirmed}) {
    return MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () {
              BookingFlowSheet.show(
                context: context,
                serviceId: '67b8a1000000000000000030',
                serviceTitle: 'Engine Tuneup',
                price: 2999,
                initialVehicle: testVehicle,
                bookingService: bookingService,
                onBookingConfirmed: onConfirmed,
              );
            },
            child: const Text('Open Booking Flow'),
          ),
        ),
      ),
    );
  }

  group('BookingFlowSheet - API Flow', () {
    testWidgets('creates server booking and transitions to Confirmed step', (tester) async {
      Booking? confirmedBooking;
      final mockService = MockBookingFlowService();

      await tester.pumpWidget(createSubject(
        bookingService: mockService,
        onConfirmed: (b) => confirmedBooking = b,
      ));

      // Open sheet
      await tester.tap(find.text('Open Booking Flow'));
      await tester.pumpAndSettle();

      expect(find.text('Book a Service'), findsOneWidget);
      expect(find.text('Service'), findsWidgets);

      // Step 0 -> Step 1 (Schedule)
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      expect(find.text('Schedule'), findsWidgets);

      // Step 1 -> Step 2 (Pickup)
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      expect(find.text('Pickup'), findsWidgets);

      // Step 2 -> Step 3 (Summary)
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      expect(find.text('Summary'), findsWidgets);
      expect(find.text('Confirm Booking'), findsOneWidget);

      // Confirm Booking
      await tester.tap(find.text('Confirm Booking'));
      await tester.pumpAndSettle();

      expect(mockService.createBookingCallCount, equals(1));
      expect(confirmedBooking, isNotNull);
      expect(confirmedBooking!.bookingNumber, equals('MM-2026-9999'));

      // Check step 4 confirmation screen
      expect(find.text('Booking Confirmed!'), findsOneWidget);
      expect(find.text('Booking ID: MM-2026-9999'), findsOneWidget);
    });

    testWidgets('handles server error without advancing to confirmed step', (tester) async {
      final mockService = MockBookingFlowService(
        errorToThrow: HttpStatusException(
          statusCode: 400,
          message: 'Vehicle does not belong to user',
          errorCode: 'VEHICLE_OWNERSHIP_MISMATCH',
        ),
      );

      await tester.pumpWidget(createSubject(bookingService: mockService));

      await tester.tap(find.text('Open Booking Flow'));
      await tester.pumpAndSettle();

      // Navigate to Step 3
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      expect(find.text('Confirm Booking'), findsOneWidget);

      // Tap Confirm Booking
      await tester.tap(find.text('Confirm Booking'));
      await tester.pumpAndSettle();

      expect(mockService.createBookingCallCount, equals(1));

      // Error message in SnackBar
      expect(find.text('The selected vehicle does not belong to your account.'), findsOneWidget);

      // Still on step 3 (not confirmed)
      expect(find.text('Booking Confirmed!'), findsNothing);
      expect(find.text('Confirm Booking'), findsOneWidget);
    });

    testWidgets('prevents duplicate submissions while async create is in flight', (tester) async {
      final completer = Completer<void>();
      final mockService = MockBookingFlowService(pendingCompleter: completer);

      await tester.pumpWidget(createSubject(bookingService: mockService));

      await tester.tap(find.text('Open Booking Flow'));
      await tester.pumpAndSettle();

      // Navigate to Step 3
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      // Tap Confirm Booking
      await tester.tap(find.text('Confirm Booking'));
      await tester.pump(); // Render in-flight state

      // Indicator should be visible
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Try tapping again while in-flight
      await tester.tap(find.byType(CircularProgressIndicator));
      await tester.pump();

      // Completer finishes
      completer.complete();
      await tester.pumpAndSettle();

      // Call count must remain 1
      expect(mockService.createBookingCallCount, equals(1));
      expect(find.text('Booking Confirmed!'), findsOneWidget);
    });
  });
}
