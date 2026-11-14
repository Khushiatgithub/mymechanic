import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mymechanic/core/network/api_exception.dart';
import 'package:mymechanic/data/mock_data.dart';
import 'package:mymechanic/models/booking.dart';
import 'package:mymechanic/screens/bookings/bookings_screen.dart';
import 'package:mymechanic/services/auth_service.dart';
import 'package:mymechanic/services/booking_service.dart';

class FakeBookingService extends BookingService {
  List<Booking> bookingsToReturn;
  Object? errorToThrow;
  Completer<void>? pendingCompleter;
  int getBookingsCallCount = 0;
  int cancelBookingCallCount = 0;
  int rescheduleBookingCallCount = 0;

  FakeBookingService({
    this.bookingsToReturn = const [],
    this.errorToThrow,
    this.pendingCompleter,
  }) : super(apiClient: BookingService.instance.apiClient);

  @override
  Future<List<Booking>> getBookings({
    String? vehicleId,
    String? status,
    int page = 1,
    int limit = 50,
  }) async {
    getBookingsCallCount++;
    if (pendingCompleter != null) {
      await pendingCompleter!.future;
    }
    if (errorToThrow != null) {
      throw errorToThrow!;
    }
    return bookingsToReturn;
  }

  @override
  Future<Booking> cancelBooking(String id) async {
    cancelBookingCallCount++;
    final match = bookingsToReturn.firstWhere((b) => b.id == id);
    return match.copyWith(status: BookingStatus.cancelled);
  }

  @override
  Future<Booking> rescheduleBooking(
    String id, {
    required DateTime scheduledDate,
    required String scheduledTime,
    String? address,
    String? notes,
  }) async {
    rescheduleBookingCallCount++;
    final match = bookingsToReturn.firstWhere((b) => b.id == id);
    return match.copyWith(dateTime: scheduledDate, timeSlot: scheduledTime);
  }
}

void main() {
  final activeBooking = Booking(
    id: '67b8a1000000000000000001',
    bookingNumber: 'MM-2026-1001',
    serviceTitle: 'Brake Disc Replacement',
    vehicleName: 'Hyundai Creta SX (O)',
    vehicleNumber: 'KA01MJ5050',
    dateTime: DateTime(2026, 3, 20),
    timeSlot: '10:30 AM',
    totalAmount: 4500,
    status: BookingStatus.confirmed,
    workshopName: 'MyMechanic Flagship Hub',
    assignedMechanic: 'Rajesh Kumar',
    backendStatus: 'confirmed',
  );

  final pastBooking = Booking(
    id: '67b8a1000000000000000002',
    bookingNumber: 'MM-2026-1002',
    serviceTitle: 'Full Car Spa & Polish',
    vehicleName: 'Tata Nexon EV',
    vehicleNumber: 'KA05EV1234',
    dateTime: DateTime(2026, 2, 10),
    timeSlot: '02:00 PM',
    totalAmount: 1800,
    status: BookingStatus.completed,
    workshopName: 'MyMechanic Koramangala Hub',
    assignedMechanic: 'Suresh Patil',
    backendStatus: 'completed',
  );

  Widget createSubject({
    BookingService? bookingService,
    VoidCallback? onExploreServices,
  }) {
    return MaterialApp(
      home: BookingsScreen(
        bookingService: bookingService,
        onExploreServices: onExploreServices ?? () {},
      ),
    );
  }

  group('BookingsScreen - API Integration & States', () {
    testWidgets('shows loading indicator while fetching server bookings', (tester) async {
      final completer = Completer<void>();
      final fakeService = FakeBookingService(pendingCompleter: completer);

      await tester.pumpWidget(createSubject(bookingService: fakeService));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Loading bookings...'), findsOneWidget);

      completer.complete();
      await tester.pumpAndSettle();

      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('renders active and past bookings from server into respective tabs', (tester) async {
      final fakeService = FakeBookingService(
        bookingsToReturn: [activeBooking, pastBooking],
      );

      await tester.pumpWidget(createSubject(bookingService: fakeService));
      await tester.pumpAndSettle();

      // Active tab
      expect(find.text('Active (1)'), findsOneWidget);
      expect(find.text('History (1)'), findsOneWidget);
      expect(find.text('MM-2026-1001'), findsOneWidget);
      expect(find.text('Brake Disc Replacement'), findsOneWidget);
      expect(find.textContaining('Hyundai Creta SX (O)'), findsOneWidget);

      // Switch to History tab
      await tester.tap(find.text('History (1)'));
      await tester.pumpAndSettle();

      expect(find.text('MM-2026-1002'), findsOneWidget);
      expect(find.text('Full Car Spa & Polish'), findsOneWidget);
      expect(find.textContaining('Tata Nexon EV'), findsOneWidget);
    });

    testWidgets('shows empty state when server returns 0 bookings', (tester) async {
      var exploreClicked = false;
      final fakeService = FakeBookingService(bookingsToReturn: []);

      await tester.pumpWidget(createSubject(
        bookingService: fakeService,
        onExploreServices: () => exploreClicked = true,
      ));
      await tester.pumpAndSettle();

      expect(find.text('No Active Bookings'), findsOneWidget);
      expect(find.text('Explore Services'), findsOneWidget);

      await tester.tap(find.text('Explore Services'));
      await tester.pump();

      expect(exploreClicked, isTrue);
    });

    testWidgets('shows error state with retry button on network failure', (tester) async {
      final fakeService = FakeBookingService(
        errorToThrow: NetworkException('Connection refused'),
      );

      await tester.pumpWidget(createSubject(bookingService: fakeService));
      await tester.pumpAndSettle();

      expect(find.text('Unable to Load Bookings'), findsOneWidget);
      expect(find.text('Try Again'), findsOneWidget);

      // Tap retry with success
      fakeService.errorToThrow = null;
      fakeService.bookingsToReturn = [activeBooking];

      await tester.tap(find.text('Try Again'));
      await tester.pumpAndSettle();

      expect(find.text('Unable to Load Bookings'), findsNothing);
      expect(find.text('MM-2026-1001'), findsOneWidget);
      expect(fakeService.getBookingsCallCount, equals(2));
    });

    testWidgets('pull to refresh triggers booking reload', (tester) async {
      final fakeService = FakeBookingService(bookingsToReturn: [activeBooking]);

      await tester.pumpWidget(createSubject(bookingService: fakeService));
      await tester.pumpAndSettle();

      expect(fakeService.getBookingsCallCount, equals(1));

      // Trigger pull down
      await tester.fling(find.text('MM-2026-1001'), const Offset(0, 300), 1000);
      await tester.pumpAndSettle();

      expect(fakeService.getBookingsCallCount, equals(2));
    });

    testWidgets('auth state change automatically reloads bookings', (tester) async {
      final fakeService = FakeBookingService(bookingsToReturn: [activeBooking]);

      await tester.pumpWidget(createSubject(bookingService: fakeService));
      await tester.pumpAndSettle();

      expect(fakeService.getBookingsCallCount, equals(1));

      // Trigger auth state notification (e.g. login event)
      AuthService.instance.isAuthenticatedNotifier.value = true;
      await tester.pumpAndSettle();

      expect(fakeService.getBookingsCallCount, equals(2));

      // Trigger logout notification
      AuthService.instance.isAuthenticatedNotifier.value = false;
      await tester.pumpAndSettle();

      // Reset for subsequent tests
      AuthService.instance.isAuthenticatedNotifier.value = false;
    });

    testWidgets('MockData.bookingsNotifier updates reload server bookings when authenticated', (tester) async {
      AuthService.instance.isAuthenticatedNotifier.value = true;
      final fakeService = FakeBookingService(bookingsToReturn: [activeBooking]);

      await tester.pumpWidget(createSubject(bookingService: fakeService));
      await tester.pumpAndSettle();

      expect(find.text('MM-2026-1001'), findsOneWidget);
      expect(fakeService.getBookingsCallCount, equals(1));

      // Simulate a new booking created elsewhere in the app (e.g. BookingFlowSheet)
      final newCreatedBooking = Booking(
        id: '67b8a1000000000000000099',
        bookingNumber: 'MM-2026-9999',
        serviceTitle: 'Brake Fluid Flush',
        vehicleName: 'Hyundai Creta SX (O)',
        vehicleNumber: 'KA01MJ5050',
        dateTime: DateTime(2026, 4, 1),
        timeSlot: '11:00 AM',
        totalAmount: 1200,
        status: BookingStatus.confirmed,
        workshopName: 'MyMechanic Flagship Hub',
        assignedMechanic: 'Rajesh Kumar',
        backendStatus: 'confirmed',
      );

      fakeService.bookingsToReturn = [newCreatedBooking, activeBooking];
      MockData.addBooking(newCreatedBooking);
      await tester.pumpAndSettle();

      // BookingsScreen has automatically refreshed from server without manual pull-to-refresh
      expect(fakeService.getBookingsCallCount, equals(2));
      expect(find.text('MM-2026-9999'), findsOneWidget);

      AuthService.instance.isAuthenticatedNotifier.value = false;
    });

    testWidgets('Late response from previous session cannot overwrite logged-out state', (tester) async {
      final delayedCompleter = Completer<void>();
      final fakeService = FakeBookingService(
        bookingsToReturn: [activeBooking],
        pendingCompleter: delayedCompleter,
      );

      // Start authenticated
      AuthService.instance.isAuthenticatedNotifier.value = true;

      await tester.pumpWidget(createSubject(bookingService: fakeService));
      await tester.pump(); // request in flight

      // User logs out while request is still pending
      AuthService.instance.isAuthenticatedNotifier.value = false;
      await tester.pump(const Duration(milliseconds: 100));

      // Now complete the delayed response
      delayedCompleter.complete();
      await tester.pumpAndSettle();

      // Stale response must not populate server bookings in logged-out state
      expect(find.text('MM-2026-1001'), findsNothing);

      // Reset
      AuthService.instance.isAuthenticatedNotifier.value = false;
    });

    testWidgets('Logout purges customer-added bookings and restores canonical guest bookings', (tester) async {
      // Simulate customer creating a private booking during session
      final privateCustomerBooking = Booking(
        id: 'cust_private_1',
        bookingNumber: 'MM-CUST-PRIVATE',
        serviceTitle: 'VIP Custom Tuning',
        vehicleName: 'Custom Car',
        vehicleNumber: 'KA99VIP1111',
        dateTime: DateTime.now(),
        timeSlot: '04:00 PM',
        totalAmount: 9999,
        status: BookingStatus.confirmed,
        workshopName: 'Custom Hub',
        assignedMechanic: 'Lead Tuner',
      );

      MockData.addBooking(privateCustomerBooking);
      expect(MockData.bookings.any((b) => b.bookingNumber == 'MM-CUST-PRIVATE'), isTrue);

      // Simulate logout
      MockData.resetAllToGuest();

      // Customer-specific booking is completely wiped and guest bookings are restored
      expect(MockData.bookings.any((b) => b.bookingNumber == 'MM-CUST-PRIVATE'), isFalse);
      expect(MockData.bookings.any((b) => b.bookingNumber == 'MM-2026-9481'), isTrue);
    });
  });
}
