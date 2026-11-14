import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mymechanic/core/network/api_exception.dart';
import 'package:mymechanic/models/booking.dart';
import 'package:mymechanic/models/vehicle.dart';
import 'package:mymechanic/services/auth_service.dart';
import 'package:mymechanic/services/booking_service.dart';
import 'package:mymechanic/services/vehicle_service.dart';
import 'package:mymechanic/widgets/booking/booking_details_sheet.dart';

class MockHardenedBookingService extends BookingService {
  Completer<Booking>? rescheduleCompleter;
  Completer<Booking>? cancelCompleter;
  int rescheduleCallCount = 0;
  int cancelCallCount = 0;

  MockHardenedBookingService() : super(apiClient: AuthService.instance.apiClient);

  @override
  Future<Booking> rescheduleBooking(
    String id, {
    required DateTime scheduledDate,
    required String scheduledTime,
    String? address,
    String? notes,
  }) async {
    rescheduleCallCount++;
    if (rescheduleCompleter != null) {
      return await rescheduleCompleter!.future;
    }
    return Booking(
      id: id,
      bookingNumber: 'MM-2026-RSCH',
      serviceTitle: 'Engine Diagnostics',
      vehicleName: 'Honda City',
      vehicleNumber: 'KA04HH9999',
      workshopName: 'MyMechanic Flagship Hub',
      assignedMechanic: 'Rajesh Kumar',
      dateTime: scheduledDate,
      timeSlot: scheduledTime,
      totalAmount: 2999,
      status: BookingStatus.confirmed,
      backendStatus: 'confirmed',
    );
  }

  @override
  Future<Booking> cancelBooking(String id) async {
    cancelCallCount++;
    if (cancelCompleter != null) {
      return await cancelCompleter!.future;
    }
    return Booking(
      id: id,
      bookingNumber: 'MM-2026-CNCL',
      serviceTitle: 'Engine Diagnostics',
      vehicleName: 'Honda City',
      vehicleNumber: 'KA04HH9999',
      workshopName: 'MyMechanic Flagship Hub',
      assignedMechanic: 'Rajesh Kumar',
      dateTime: DateTime.now(),
      timeSlot: '10:00 AM',
      totalAmount: 2999,
      status: BookingStatus.cancelled,
      backendStatus: 'cancelled',
    );
  }
}

void main() {
  group('Integration Hardening — Double Submission Protection', () {
    testWidgets('reschedule booking prevents duplicate taps while request is in flight', (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1400));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final mockService = MockHardenedBookingService();
      mockService.rescheduleCompleter = Completer<Booking>();

      final booking = Booking(
        id: '67b8a1000000000000000201',
        bookingNumber: 'MM-2026-201',
        serviceTitle: 'Engine Diagnostics',
        vehicleName: 'Honda City',
        vehicleNumber: 'KA04HH9999',
        workshopName: 'MyMechanic Flagship Hub',
        assignedMechanic: 'Rajesh Kumar',
        dateTime: DateTime.now().add(const Duration(days: 2)),
        timeSlot: '10:00 AM',
        totalAmount: 2999,
        status: BookingStatus.confirmed,
        backendStatus: 'confirmed',
      );

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (ctx) => ElevatedButton(
              onPressed: () {
                BookingDetailsSheet.show(
                  context: ctx,
                  booking: booking,
                  bookingService: mockService,
                );
              },
              child: const Text('Open Details'),
            ),
          ),
        ),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open Details'));
      await tester.pumpAndSettle();

      // Open reschedule modal
      final rescheduleBtn = find.text('Reschedule');
      expect(rescheduleBtn, findsOneWidget);
      await tester.tap(rescheduleBtn);
      await tester.pumpAndSettle();

      final confirmBtn = find.widgetWithText(ElevatedButton, 'Confirm Reschedule');
      expect(confirmBtn, findsOneWidget);

      // First tap begins async request
      await tester.tap(confirmBtn);
      await tester.pump(); // Render in-flight state

      // The button is now disabled (onPressed is null) with CircularProgressIndicator
      final inFlightBtn = tester.widget<ElevatedButton>(find.byType(ElevatedButton).last);
      expect(inFlightBtn.onPressed, isNull);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Attempt immediate rapid second tap to the in-flight button
      await tester.tap(find.byType(ElevatedButton).last, warnIfMissed: false);
      await tester.pump();

      // Call count must strictly remain 1
      expect(mockService.rescheduleCallCount, equals(1));

      // Complete the pending request
      mockService.rescheduleCompleter!.complete(Booking(
        id: booking.id,
        bookingNumber: booking.bookingNumber,
        serviceTitle: booking.serviceTitle,
        vehicleName: booking.vehicleName,
        vehicleNumber: booking.vehicleNumber,
        workshopName: booking.workshopName,
        assignedMechanic: booking.assignedMechanic,
        dateTime: DateTime.now().add(const Duration(days: 3)),
        timeSlot: '12:00 PM',
        totalAmount: booking.totalAmount,
        status: BookingStatus.confirmed,
        backendStatus: 'confirmed',
      ));
      await tester.pumpAndSettle();

      expect(mockService.rescheduleCallCount, equals(1));
    });

    testWidgets('cancel booking prevents duplicate taps while request is in flight', (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1400));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final mockService = MockHardenedBookingService();
      mockService.cancelCompleter = Completer<Booking>();

      final booking = Booking(
        id: '67b8a1000000000000000202',
        bookingNumber: 'MM-2026-202',
        serviceTitle: 'Engine Diagnostics',
        vehicleName: 'Honda City',
        vehicleNumber: 'KA04HH9999',
        workshopName: 'MyMechanic Flagship Hub',
        assignedMechanic: 'Rajesh Kumar',
        dateTime: DateTime.now().add(const Duration(days: 2)),
        timeSlot: '10:00 AM',
        totalAmount: 2999,
        status: BookingStatus.confirmed,
        backendStatus: 'confirmed',
      );

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (ctx) => ElevatedButton(
              onPressed: () {
                BookingDetailsSheet.show(
                  context: ctx,
                  booking: booking,
                  bookingService: mockService,
                );
              },
              child: const Text('Open Details'),
            ),
          ),
        ),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open Details'));
      await tester.pumpAndSettle();

      // Open cancel dialog
      final cancelPromptBtn = find.widgetWithText(OutlinedButton, 'Cancel');
      expect(cancelPromptBtn, findsOneWidget);
      await tester.tap(cancelPromptBtn);
      await tester.pumpAndSettle();

      // The dialog confirm button
      final dialogCancelBtn = find.widgetWithText(ElevatedButton, 'Yes, Cancel');
      expect(dialogCancelBtn, findsOneWidget);

      // First tap starts cancellation
      await tester.tap(dialogCancelBtn);
      await tester.pump();

      // Button is disabled with CircularProgressIndicator
      final inFlightCancelBtn = tester.widget<ElevatedButton>(find.byType(ElevatedButton).last);
      expect(inFlightCancelBtn.onPressed, isNull);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Attempt rapid second tap to the in-flight button
      await tester.tap(find.byType(ElevatedButton).last, warnIfMissed: false);
      await tester.pump();

      expect(mockService.cancelCallCount, equals(1));

      // Finish cancellation
      mockService.cancelCompleter!.complete(Booking(
        id: booking.id,
        bookingNumber: booking.bookingNumber,
        serviceTitle: booking.serviceTitle,
        vehicleName: booking.vehicleName,
        vehicleNumber: booking.vehicleNumber,
        workshopName: booking.workshopName,
        assignedMechanic: booking.assignedMechanic,
        dateTime: booking.dateTime,
        timeSlot: booking.timeSlot,
        totalAmount: booking.totalAmount,
        status: BookingStatus.cancelled,
        backendStatus: 'cancelled',
      ));
      await tester.pumpAndSettle();

      expect(mockService.cancelCallCount, equals(1));
    });
  });

  group('Integration Hardening — Status & Error Contracts', () {
    test('maps all 8 backend statuses to valid BookingStatus without exceptions', () {
      final statuses = [
        'confirmed',
        'vehicle_received',
        'inspection',
        'service_in_progress',
        'quality_check',
        'ready_for_delivery',
        'completed',
        'cancelled',
      ];

      for (final s in statuses) {
        final json = {
          '_id': '67b8a1000000000000000301',
          'bookingNumber': 'MM-2026-STATUS',
          'serviceTitle': 'Periodic Service',
          'vehicleName': 'Creta',
          'vehicleNumber': 'DL01AB1234',
          'status': s,
          'totalAmount': 1999,
        };
        final b = Booking.fromJson(json);
        expect(b.backendStatus, equals(s));
        expect(b.status, isNotNull);
        expect(b.statusText, isNotEmpty);
      }
    });

    test('vehicle ownership mismatch error maps to user-friendly message', () {
      const error = HttpStatusException(
        statusCode: 400,
        errorCode: 'VEHICLE_OWNERSHIP_MISMATCH',
        message: 'Vehicle does not belong to the booking user.',
      );
      final msg = BookingService.getErrorMessage(error);
      expect(msg, equals('The selected vehicle does not belong to your account.'));
      expect(msg.contains('Exception'), isFalse);
    });

    test('internal server error 500 hides raw database and stack traces', () {
      const error = HttpStatusException(
        statusCode: 500,
        errorCode: 'INTERNAL_SERVER_ERROR',
        message: 'MongoError: connection pool destroyed at /app/node_modules/mongodb',
      );
      final msg = BookingService.getErrorMessage(error);
      expect(msg, equals('Server error while processing your booking. Please try again later.'));
      expect(msg.contains('MongoError'), isFalse);
      expect(msg.contains('node_modules'), isFalse);

      final authMsg = AuthService.getErrorMessage(error);
      expect(authMsg, equals('The server encountered an error. Please try again later.'));

      final vehicleMsg = VehicleService.getErrorMessage(error);
      expect(vehicleMsg, equals('Server error while updating garage. Please try again later.'));
    });

    test('vehicle model toBackendJson formats make and isActive correctly', () {
      final vehicle = Vehicle(
        id: '67b8a1000000000000000401',
        brand: 'Tata',
        model: 'Nexon',
        variant: 'XZ+',
        fuelType: 'Diesel',
        registrationNumber: 'MH 02 CD 5678',
        year: 2023,
        serviceDueStatus: 'Up to date',
        isPrimary: true,
      );

      final payload = vehicle.toBackendJson();
      expect(payload['make'], equals('Tata'));
      expect(payload['model'], equals('Nexon'));
      expect(payload['registrationNumber'], equals('MH 02 CD 5678'));
      expect(payload['isActive'], isTrue);
      expect(payload.containsKey('brand'), isFalse);
      expect(payload.containsKey('isPrimary'), isFalse);
    });
  });
}
