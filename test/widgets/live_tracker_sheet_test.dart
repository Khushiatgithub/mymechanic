import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mymechanic/core/network/api_exception.dart';
import 'package:mymechanic/models/booking.dart';
import 'package:mymechanic/services/booking_service.dart';
import 'package:mymechanic/widgets/booking/live_tracker_sheet.dart';

class MockTrackerBookingService extends BookingService {
  Booking? bookingToReturn;
  Object? errorToThrow;
  int getBookingByIdCallCount = 0;
  String? lastRequestedId;

  MockTrackerBookingService({
    this.bookingToReturn,
    this.errorToThrow,
  }) : super(apiClient: BookingService.instance.apiClient);

  @override
  Future<Booking> getBookingById(String id) async {
    getBookingByIdCallCount++;
    lastRequestedId = id;
    if (errorToThrow != null) {
      throw errorToThrow!;
    }
    return bookingToReturn ??
        Booking(
          id: id,
          bookingNumber: 'MM-2026-TEST',
          serviceTitle: 'Full Service',
          vehicleName: 'Hyundai Creta',
          vehicleNumber: 'DL01AB1234',
          workshopName: 'MyMechanic Flagship Hub',
          assignedMechanic: 'Rajesh Kumar',
          dateTime: DateTime(2026, 4, 1),
          timeSlot: '10:00 AM',
          totalAmount: 3999,
          status: BookingStatus.inProgress,
          backendStatus: 'service_in_progress',
        );
  }
}

void main() {
  Widget buildSubject({
    required Booking booking,
    BookingService? bookingService,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: LiveTrackerSheet(
          booking: booking,
          bookingService: bookingService,
        ),
      ),
    );
  }

  group('LiveTrackerSheet - Backend Status & Tracking Stages', () {
    testWidgets('renders stage 0 active when backendStatus is confirmed', (tester) async {
      final booking = Booking(
        id: '67b8a1000000000000000101',
        bookingNumber: 'MM-2026-0101',
        serviceTitle: 'Periodic Maintenance',
        vehicleName: 'Honda City',
        vehicleNumber: 'KA04HH9999',
        workshopName: 'MyMechanic Hub Koramangala',
        assignedMechanic: 'Rajesh Kumar',
        dateTime: DateTime.now(),
        timeSlot: '10:00 AM',
        totalAmount: 2500,
        status: BookingStatus.confirmed,
        backendStatus: 'confirmed',
      );

      await tester.pumpWidget(buildSubject(booking: booking));
      await tester.pumpAndSettle();

      expect(find.text('Live Service Tracker'), findsOneWidget);
      expect(find.text('MM-2026-0101 • Honda City'), findsOneWidget);
      expect(find.text('Booking Confirmed'), findsOneWidget);
      expect(find.text('Vehicle Pickup / Vehicle Received'), findsOneWidget);
      expect(find.text('Inspection Started'), findsOneWidget);
      expect(find.text('Service In Progress'), findsOneWidget);
      expect(find.text('Quality Check'), findsOneWidget);
      expect(find.text('Ready for Delivery'), findsOneWidget);
      expect(find.text('Completed'), findsOneWidget);
    });

    testWidgets('renders stage 3 active when backendStatus is service_in_progress', (tester) async {
      final booking = Booking(
        id: '67b8a1000000000000000102',
        bookingNumber: 'MM-2026-0102',
        serviceTitle: 'Periodic Maintenance',
        vehicleName: 'Honda City',
        vehicleNumber: 'KA04HH9999',
        workshopName: 'MyMechanic Hub Koramangala',
        assignedMechanic: 'Rajesh Kumar',
        dateTime: DateTime.now(),
        timeSlot: '10:00 AM',
        totalAmount: 2500,
        status: BookingStatus.inProgress,
        backendStatus: 'service_in_progress',
      );

      await tester.pumpWidget(buildSubject(booking: booking));
      await tester.pumpAndSettle();

      expect(find.text('Service In Progress'), findsOneWidget);
      expect(find.text('Scheduled maintenance, fluid replacements & repairs underway'), findsOneWidget);
    });

    testWidgets('renders stage 6 active when backendStatus is completed', (tester) async {
      final booking = Booking(
        id: '67b8a1000000000000000103',
        bookingNumber: 'MM-2026-0103',
        serviceTitle: 'Periodic Maintenance',
        vehicleName: 'Honda City',
        vehicleNumber: 'KA04HH9999',
        workshopName: 'MyMechanic Hub Koramangala',
        assignedMechanic: 'Rajesh Kumar',
        dateTime: DateTime.now(),
        timeSlot: '10:00 AM',
        totalAmount: 2500,
        status: BookingStatus.completed,
        backendStatus: 'completed',
      );

      await tester.pumpWidget(buildSubject(booking: booking));
      await tester.pumpAndSettle();

      expect(find.text('Delivered safely back to customer with warranty certificate'), findsOneWidget);
    });

    testWidgets('displays cancelled notice when booking status is cancelled', (tester) async {
      final booking = Booking(
        id: '67b8a1000000000000000104',
        bookingNumber: 'MM-2026-0104',
        serviceTitle: 'Periodic Maintenance',
        vehicleName: 'Honda City',
        vehicleNumber: 'KA04HH9999',
        workshopName: 'MyMechanic Hub Koramangala',
        assignedMechanic: 'Rajesh Kumar',
        dateTime: DateTime.now(),
        timeSlot: '10:00 AM',
        totalAmount: 2500,
        status: BookingStatus.cancelled,
        backendStatus: 'cancelled',
      );

      await tester.pumpWidget(buildSubject(booking: booking));
      await tester.pumpAndSettle();

      expect(find.text('Booking Cancelled'), findsOneWidget);
      expect(find.text('This booking was cancelled and does not have an active service timeline.'), findsOneWidget);
      expect(find.text('Book Again'), findsOneWidget);
      expect(find.text('Service In Progress'), findsNothing);
    });

    testWidgets('refresh button fetches latest status from backend for 24-hex Mongo ID', (tester) async {
      final initialBooking = Booking(
        id: '67b8a1000000000000000105',
        bookingNumber: 'MM-2026-0105',
        serviceTitle: 'Periodic Maintenance',
        vehicleName: 'Honda City',
        vehicleNumber: 'KA04HH9999',
        workshopName: 'MyMechanic Hub Koramangala',
        assignedMechanic: 'Rajesh Kumar',
        dateTime: DateTime.now(),
        timeSlot: '10:00 AM',
        totalAmount: 2500,
        status: BookingStatus.confirmed,
        backendStatus: 'confirmed',
      );

      final updatedBooking = Booking(
        id: '67b8a1000000000000000105',
        bookingNumber: 'MM-2026-0105',
        serviceTitle: 'Periodic Maintenance',
        vehicleName: 'Honda City',
        vehicleNumber: 'KA04HH9999',
        workshopName: 'MyMechanic Hub Koramangala',
        assignedMechanic: 'Rajesh Kumar',
        dateTime: DateTime.now(),
        timeSlot: '10:00 AM',
        totalAmount: 2500,
        status: BookingStatus.inProgress,
        backendStatus: 'quality_check',
      );

      final mockService = MockTrackerBookingService(bookingToReturn: updatedBooking);

      await tester.pumpWidget(buildSubject(
        booking: initialBooking,
        bookingService: mockService,
      ));
      await tester.pumpAndSettle();

      // Tap the refresh icon
      final refreshButton = find.byTooltip('Refresh Status');
      expect(refreshButton, findsOneWidget);

      await tester.tap(refreshButton);
      await tester.pumpAndSettle();

      expect(mockService.getBookingByIdCallCount, equals(1));
      expect(mockService.lastRequestedId, equals('67b8a1000000000000000105'));
      expect(find.text('Supervisor multi-point road test & electronic sensor scan'), findsOneWidget);
    });

    testWidgets('refresh handles network failure gracefully without crashing', (tester) async {
      final initialBooking = Booking(
        id: '67b8a1000000000000000106',
        bookingNumber: 'MM-2026-0106',
        serviceTitle: 'Periodic Maintenance',
        vehicleName: 'Honda City',
        vehicleNumber: 'KA04HH9999',
        workshopName: 'MyMechanic Hub Koramangala',
        assignedMechanic: 'Rajesh Kumar',
        dateTime: DateTime.now(),
        timeSlot: '10:00 AM',
        totalAmount: 2500,
        status: BookingStatus.confirmed,
        backendStatus: 'confirmed',
      );

      final mockService = MockTrackerBookingService(
        errorToThrow: const NetworkException('Network connection failed'),
      );

      await tester.pumpWidget(buildSubject(
        booking: initialBooking,
        bookingService: mockService,
      ));
      await tester.pumpAndSettle();

      final refreshButton = find.byTooltip('Refresh Status');
      await tester.tap(refreshButton);
      await tester.pumpAndSettle();

      expect(mockService.getBookingByIdCallCount, equals(1));
      // App remains intact and still renders original booking info
      expect(find.text('Live Service Tracker'), findsOneWidget);
      expect(find.text('MM-2026-0106 • Honda City'), findsOneWidget);
    });

    testWidgets('mock booking ID does not call backend getBookingById', (tester) async {
      final mockBooking = Booking(
        id: 'b1',
        bookingNumber: 'MM-2026-MOCK1',
        serviceTitle: 'Periodic Maintenance',
        vehicleName: 'Honda City',
        vehicleNumber: 'KA04HH9999',
        workshopName: 'MyMechanic Hub Koramangala',
        assignedMechanic: 'Rajesh Kumar',
        dateTime: DateTime.now(),
        timeSlot: '10:00 AM',
        totalAmount: 2500,
        status: BookingStatus.inProgress,
      );

      final mockService = MockTrackerBookingService();

      await tester.pumpWidget(buildSubject(
        booking: mockBooking,
        bookingService: mockService,
      ));
      await tester.pumpAndSettle();

      final refreshButton = find.byTooltip('Refresh Status');
      await tester.tap(refreshButton);
      await tester.pumpAndSettle();

      expect(mockService.getBookingByIdCallCount, equals(0));
    });
  });
}
