import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mymechanic/core/constants/app_constants.dart';
import 'package:mymechanic/core/theme/app_colors.dart';
import 'package:mymechanic/core/theme/app_theme.dart';
import 'package:mymechanic/data/mock_data.dart';
import 'package:mymechanic/main.dart';
import 'package:mymechanic/models/booking.dart';
import 'package:mymechanic/models/vehicle.dart';
import 'package:mymechanic/services/theme_service.dart';

void main() {
  void resetMockData() {
    MockData.vehicles = [
      Vehicle(
        id: 'v1',
        brand: 'Hyundai',
        model: 'Creta',
        variant: '1.5 SX(O)',
        fuelType: 'Petrol',
        registrationNumber: 'KA 01 MJ 4521',
        year: 2022,
        serviceDueStatus: 'Due in 12 days',
        isPrimary: true,
        lastServiceTitle: 'Standard Periodic Service',
        lastServiceDate: DateTime.now().subtract(const Duration(days: 45)),
        nextServiceTitle: 'Periodic Service',
        nextServiceDueDate: DateTime.now().add(const Duration(days: 12)),
        nextServiceMileage: '30,000 km',
        reminderStatus: 'Due Soon',
      ),
      Vehicle(
        id: 'v2',
        brand: 'Maruti Suzuki',
        model: 'Swift',
        variant: 'ZXi AMT',
        fuelType: 'Petrol',
        registrationNumber: 'DL 03 CA 9812',
        year: 2021,
        serviceDueStatus: 'Due in 5 days',
        isPrimary: false,
        lastServiceTitle: 'Deep Interior Spa & Sanitization',
        lastServiceDate: DateTime.now().subtract(const Duration(days: 12)),
        nextServiceTitle: 'AC Service & Gas Refill',
        nextServiceDueDate: DateTime.now().add(const Duration(days: 5)),
        nextServiceMileage: '25,000 km',
        reminderStatus: 'Due Soon',
      ),
      Vehicle(
        id: 'v3',
        brand: 'Tata',
        model: 'Nexon EV',
        variant: 'Fearless+',
        fuelType: 'Electric',
        registrationNumber: 'MH 02 FE 1109',
        year: 2023,
        serviceDueStatus: 'Up to date',
        isPrimary: false,
        lastServiceTitle: 'Pre-Purchase Used Car 150-Point Inspection',
        lastServiceDate: DateTime.now().subtract(const Duration(days: 90)),
        nextServiceTitle: 'Scheduled Annual Inspection',
        nextServiceDueDate: DateTime.now().add(const Duration(days: 60)),
        nextServiceMileage: '15,000 km',
        reminderStatus: 'Scheduled',
      ),
    ];
    MockData.vehiclesNotifier.value = List.from(MockData.vehicles);

    MockData.bookings = [
      Booking(
        id: 'b1',
        bookingNumber: 'MM-2026-9481',
        serviceTitle: 'Standard Periodic Service',
        serviceDescription: 'Complete 30-point vehicle checkup, engine oil renewal & fluid top-ups',
        vehicleName: 'Hyundai Creta 1.5 SX(O)',
        vehicleNumber: 'KA 01 MJ 4521',
        dateTime: DateTime.now().add(const Duration(days: 1, hours: 3)),
        timeSlot: '10:30 AM',
        servicePrice: 3699,
        pickupFee: 0,
        totalAmount: 3699,
        pickupType: 'Doorstep Pickup & Drop',
        address: 'Flat 402, Green Glen Layout, Bellandur, Bengaluru - 560103',
        status: BookingStatus.inProgress,
        workshopName: 'MyMechanic Flagship Hub, Koramangala',
        assignedMechanic: 'Rajesh Kumar (Senior Certified Tech)',
        packageName: 'Standard Periodic Package',
        warrantyPeriod: '5000 Kms / 3 Months Warranty',
        duration: '4 Hours',
        includedItems: const [
          '100% Fully Synthetic Engine Oil (4L)',
          'OEM Genuine Oil Filter Replacement',
          'Coolant & Wiper Fluid Top-up',
        ],
        checklist: const [
          'Oil drain & filter installation',
          'Coolant & brake fluid inspection',
        ],
      ),
      Booking(
        id: 'b2',
        bookingNumber: 'MM-2026-7832',
        serviceTitle: 'Deep Interior Spa & Sanitization',
        serviceDescription: 'Steam sanitization, wet shampooing, and leather conditioning',
        vehicleName: 'Maruti Suzuki Swift ZXi',
        vehicleNumber: 'DL 03 CA 9812',
        dateTime: DateTime.now().subtract(const Duration(days: 12)),
        timeSlot: '02:00 PM',
        servicePrice: 1599,
        pickupFee: 0,
        totalAmount: 1599,
        pickupType: 'Drop at Workshop',
        status: BookingStatus.completed,
        workshopName: 'MyMechanic Express Center, Indiranagar',
        assignedMechanic: 'Amit Verma (Detailing Lead)',
        warrantyPeriod: '100% Odor-Free Guarantee',
        duration: '3.5 Hours',
        includedItems: const [
          'Deep Carpet & Seat Shampooing',
          'Dashboard Dresser with UV Shield',
        ],
        checklist: const [
          'Complete dry vacuuming',
          'Wet shampoo extraction',
        ],
        isRated: false,
      ),
    ];
    MockData.bookingsNotifier.value = List.from(MockData.bookings);

    MockData.savedAddresses = [
      {
        'tag': 'Home',
        'address': 'Flat 402, Green Glen Layout, Bellandur',
        'city': 'Bengaluru',
        'pincode': '560103',
        'phone': '+91 98765 43210',
        'isDefault': 'true',
      },
      {
        'tag': 'Office',
        'address': 'Embassy TechVillage, Outer Ring Road, Devarabeesanahalli',
        'city': 'Bengaluru',
        'pincode': '560103',
        'phone': '+91 98765 43210',
        'isDefault': 'false',
      },
    ];
    MockData.addressesNotifier.value = List.from(MockData.savedAddresses);
    MockData.favoriteServiceIdsNotifier.value = {};
    MockData.favoritePackageIdsNotifier.value = {};
    MockData.recentlyViewedNotifier.value = [];
  }

  setUp(() {
    resetMockData();
  });

  testWidgets('MyMechanic initial app smoke and navigation test',
      (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const MyMechanicApp());
    expect(find.text(AppConstants.appTagline), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 2500));
    await tester.pumpAndSettle();

    expect(find.text('My Vehicle'), findsOneWidget);
    expect(find.text('Book a Service'), findsOneWidget);
    expect(find.text('Service Packages'), findsOneWidget);
  });

  testWidgets('Periodic Services filter and Local Search work correctly',
      (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const MyMechanicApp());
    await tester.pump(const Duration(milliseconds: 2500));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Services'));
    await tester.pumpAndSettle();

    expect(find.text('Car Services & Repairs'), findsOneWidget);

    await tester.tap(find.text('Periodic Services'));
    await tester.pumpAndSettle();

    expect(find.text('Standard Periodic Service'), findsOneWidget);
    expect(find.text('No services found'), findsNothing);

    await tester.enterText(find.byType(TextField), 'synthetic');
    await tester.pumpAndSettle();

    expect(find.text('Standard Periodic Service'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.close_rounded));
    await tester.pumpAndSettle();
    expect(find.text('Standard Periodic Service'), findsOneWidget);
  });

  testWidgets('Track Live opens 7-stage service timeline',
      (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const MyMechanicApp());
    await tester.pump(const Duration(milliseconds: 2500));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Account'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('My Bookings'));
    await tester.pumpAndSettle();

    expect(find.text('Track Live'), findsWidgets);

    await tester.tap(find.text('Track Live').first);
    await tester.pumpAndSettle();

    expect(find.text('Live Service Tracker'), findsOneWidget);
    expect(find.text('Booking Confirmed'), findsOneWidget);
    expect(find.text('Vehicle Pickup / Vehicle Received'), findsOneWidget);
    expect(find.text('Inspection Started'), findsOneWidget);
    expect(find.text('Service In Progress'), findsWidgets);
    expect(find.text('Quality Check'), findsOneWidget);
    await tester.drag(find.byType(ListView).last, const Offset(0, -300));
    await tester.pumpAndSettle();
    expect(find.text('Ready for Delivery'), findsOneWidget);
    expect(find.text('Completed'), findsWidgets);
  });

  testWidgets('Profile options open interactive sheets',
      (WidgetTester tester) async {
    await tester.pumpWidget(const MyMechanicApp());
    await tester.pump(const Duration(milliseconds: 2500));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Account'));
    await tester.pumpAndSettle();

    expect(find.text('Rohit Sharma'), findsOneWidget);

    await tester.scrollUntilVisible(find.text('MyMechanic Shield'), 100);
    await tester.tap(find.text('MyMechanic Shield'));
    await tester.pumpAndSettle();

    expect(find.text('100% Genuine OEM / OES Spares'), findsOneWidget);

    await tester.tap(find.text('Close'));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(find.text('Help & FAQs'), 100);
    await tester.tap(find.text('Help & FAQs'));
    await tester.pumpAndSettle();

    expect(find.text('How does doorstep car pickup work?'), findsOneWidget);
  });

  // ==========================================
  // PHASE 2 - STEP 1: VEHICLE MANAGEMENT TESTS
  // ==========================================

  testWidgets('Vehicle Management: Viewing vehicles in garage with all details',
      (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const MyMechanicApp());
    await tester.pump(const Duration(milliseconds: 2500));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Account'));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(find.text('My Garage'), 100);
    await tester.tap(find.text('My Garage'));
    await tester.pumpAndSettle();

    expect(find.text('My Garage'), findsWidgets);
    expect(find.text('YOUR SAVED VEHICLES (3)'), findsOneWidget);
    expect(find.text('Hyundai Creta'), findsOneWidget);
    expect(find.text('Maruti Suzuki Swift'), findsOneWidget);
    expect(find.text('Tata Nexon EV'), findsOneWidget);
  });

  testWidgets('Vehicle Management: Adding a vehicle with validation',
      (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 2400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const MyMechanicApp());
    await tester.pump(const Duration(milliseconds: 2500));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Manage Garage'));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();

    expect(find.text('Add New Vehicle'), findsOneWidget);

    await tester.tap(find.widgetWithText(ElevatedButton, 'Add Vehicle'));
    await tester.pumpAndSettle();

    expect(find.text('Please enter the car model'), findsOneWidget);
    expect(find.text('Registration number cannot be blank'), findsOneWidget);

    final modelField = find.byWidgetPredicate(
      (w) => w is TextField && w.decoration?.hintText == 'e.g. Creta, Swift, Nexon, City',
    );
    await tester.enterText(modelField, 'Harrier');

    final regField = find.byWidgetPredicate(
      (w) => w is TextField && w.decoration?.hintText == 'e.g. KA 01 MJ 4521',
    );
    await tester.enterText(regField, 'MH 14 AB 5678');

    await tester.tap(find.widgetWithText(ElevatedButton, 'Add Vehicle'));
    await tester.pumpAndSettle();

    expect(find.text('Maruti Suzuki Harrier'), findsOneWidget);
    expect(find.text('MH 14 AB 5678'), findsOneWidget);
  });

  testWidgets('Vehicle Management: Editing an existing vehicle',
      (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 2400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const MyMechanicApp());
    await tester.pump(const Duration(milliseconds: 2500));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Manage Garage'));
    await tester.pumpAndSettle();

    final editIcons = find.byIcon(Icons.edit_outlined);
    expect(editIcons, findsWidgets);
    await tester.tap(editIcons.at(1));
    await tester.pumpAndSettle();

    expect(find.text('Edit Vehicle'), findsOneWidget);

    final modelField = find.byWidgetPredicate(
      (w) => w is TextField && w.controller?.text == 'Swift',
    );
    await tester.enterText(modelField, 'Swift Sport');

    await tester.tap(find.widgetWithText(ElevatedButton, 'Save Changes'));
    await tester.pumpAndSettle();

    expect(find.text('Maruti Suzuki Swift Sport'), findsOneWidget);
  });

  testWidgets('Vehicle Management: Deleting a vehicle with confirmation dialog',
      (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 2400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const MyMechanicApp());
    await tester.pump(const Duration(milliseconds: 2500));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Manage Garage'));
    await tester.pumpAndSettle();

    final deleteIcons = find.byIcon(Icons.delete_outline_rounded);
    await tester.tap(deleteIcons.at(1));
    await tester.pumpAndSettle();

    expect(find.text('Remove Vehicle?'), findsOneWidget);
    expect(find.text('Delete'), findsOneWidget);

    await tester.tap(find.widgetWithText(ElevatedButton, 'Delete'));
    await tester.pumpAndSettle();

    expect(find.text('YOUR SAVED VEHICLES (2)'), findsOneWidget);
    expect(find.text('Maruti Suzuki Swift'), findsNothing);
  });

  testWidgets('Vehicle Management: Selecting the active vehicle',
      (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 2400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const MyMechanicApp());
    await tester.pump(const Duration(milliseconds: 2500));
    await tester.pumpAndSettle();

    expect(find.text('Hyundai Creta'), findsOneWidget);

    await tester.tap(find.text('Manage Garage'));
    await tester.pumpAndSettle();

    final setActiveButtons = find.text('Set as Active Vehicle');
    await tester.tap(setActiveButtons.first);
    await tester.pumpAndSettle();

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();

    expect(find.text('Maruti Suzuki Swift'), findsOneWidget);
  });

  // ====================================================
  // PHASE 2 - STEP 2: COMPLETE SERVICE BOOKING TESTS
  // ====================================================

  testWidgets('Complete Service Booking Flow: Service, Vehicle, Date, Time, Pickup, Address, Coupon, Price, Confirmation',
      (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const MyMechanicApp());
    await tester.pump(const Duration(milliseconds: 2500));
    await tester.pumpAndSettle();

    // 1. Service Selection: Navigate to Services and tap "Book Now"
    await tester.tap(find.text('Services'));
    await tester.pumpAndSettle();

    expect(find.text('Book Now'), findsWidgets);
    await tester.tap(find.text('Book Now').first);
    await tester.pumpAndSettle();

    // Step 0: Service & Vehicle Selection
    expect(find.text('SELECTED SERVICE'), findsOneWidget);
    expect(find.text('Standard Periodic Service'), findsWidgets);
    expect(find.text('Select Vehicle for this Service: *'), findsOneWidget);

    // 2. Vehicle Selection: Choose Tata Nexon EV
    expect(find.text('Tata Nexon EV (Fearless+)'), findsOneWidget);
    await tester.ensureVisible(find.text('Tata Nexon EV (Fearless+)'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tata Nexon EV (Fearless+)'));
    await tester.pumpAndSettle();

    // Proceed to Step 1: Schedule
    await tester.tap(find.widgetWithText(ElevatedButton, 'Continue'));
    await tester.pumpAndSettle();

    // 3. Date Selection & 4. Time Selection
    expect(find.text('Choose Service Date:'), findsOneWidget);
    expect(find.text('Select Time Slot:'), findsOneWidget);
    expect(find.text('10:30 AM'), findsOneWidget);

    // Pick time slot 02:00 PM
    await tester.ensureVisible(find.text('02:00 PM'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('02:00 PM'));
    await tester.pumpAndSettle();

    // Proceed to Step 2: Pickup/Drop & Address
    await tester.tap(find.widgetWithText(ElevatedButton, 'Continue'));
    await tester.pumpAndSettle();

    // 5. Pickup / Drop selection & 6. Address selection
    expect(find.text('Service Delivery Option:'), findsOneWidget);
    expect(find.text('Doorstep Pickup & Drop'), findsOneWidget);
    expect(find.text('Self Drop at Workshop'), findsOneWidget);
    expect(find.text('Pickup Address: *'), findsOneWidget);

    // Pick saved address: Office
    expect(find.text('Office'), findsOneWidget);
    await tester.ensureVisible(find.text('Office'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Office'));
    await tester.pumpAndSettle();

    // Proceed to Step 3: Summary & Coupon
    await tester.tap(find.widgetWithText(ElevatedButton, 'Continue'));
    await tester.pumpAndSettle();

    // 7. Coupon application & 8. Price calculation
    expect(find.text('Offers & Promo Code'), findsOneWidget);
    expect(find.text('Price Breakdown'), findsOneWidget);

    // Apply Coupon MYFIRST500
    await tester.ensureVisible(find.text('MYFIRST500 (Flat ₹500 OFF)'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('MYFIRST500 (Flat ₹500 OFF)'));
    await tester.pumpAndSettle();

    expect(find.text('Coupon "MYFIRST500" Applied'), findsOneWidget);
    expect(find.text('Final Payable Amount'), findsOneWidget);

    // 9. Booking Confirmation
    await tester.tap(find.widgetWithText(ElevatedButton, 'Confirm Booking'));
    await tester.pumpAndSettle();

    // 10. Verify Confirmation view
    expect(find.text('Booking Confirmed!'), findsOneWidget);
    expect(find.text('View Booking'), findsOneWidget);
    expect(find.text('Go to Home'), findsOneWidget);

    // 11. Tap "View Booking" to open Booking Details Sheet
    await tester.tap(find.widgetWithText(ElevatedButton, 'View Booking'));
    await tester.pumpAndSettle();

    expect(find.text('Booking Details'), findsOneWidget);
    expect(find.text('Tata Nexon EV Fearless+'), findsOneWidget);
    expect(find.text('Track Service'), findsOneWidget);
  });

  testWidgets('Booking Management: New booking appears in Active Bookings, Reschedule, and Cancellation',
      (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const MyMechanicApp());
    await tester.pump(const Duration(milliseconds: 2500));
    await tester.pumpAndSettle();

    // Open Bookings via Account tab
    await tester.tap(find.text('Account'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('My Bookings'));
    await tester.pumpAndSettle();

    // Active Bookings list contains b1
    expect(find.text('Standard Periodic Service'), findsOneWidget);

    // 11. Booking details: Tap booking card to open details
    await tester.tap(find.text('Standard Periodic Service'));
    await tester.pumpAndSettle();

    expect(find.text('Booking Details'), findsOneWidget);
    expect(find.text('MM-2026-9481'), findsWidgets);
    expect(find.text('PRICE BREAKDOWN'), findsOneWidget);

    // 13. Booking rescheduling: Tap Reschedule
    expect(find.text('Reschedule'), findsOneWidget);
    await tester.tap(find.text('Reschedule'));
    await tester.pumpAndSettle();

    expect(find.text('Reschedule Booking'), findsOneWidget);
    expect(find.text('04:00 PM'), findsOneWidget);

    // Select new time slot
    await tester.tap(find.text('04:00 PM'));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(ElevatedButton, 'Confirm Reschedule'));
    await tester.pumpAndSettle();

    // Verify time slot updated
    expect(find.text('04:00 PM'), findsOneWidget);

    // 12. Booking cancellation: Tap Cancel
    expect(find.text('Cancel'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(find.text('Cancel Booking?'), findsOneWidget);
    await tester.tap(find.widgetWithText(ElevatedButton, 'Yes, Cancel'));
    await tester.pumpAndSettle();

    // Verify active count is now 0 and booking moved to history
    expect(find.text('Active (0)'), findsOneWidget);
    expect(find.text('History (2)'), findsOneWidget);
  });

  testWidgets('Address Management: Add new address form during booking flow',
      (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const MyMechanicApp());
    await tester.pump(const Duration(milliseconds: 2500));
    await tester.pumpAndSettle();

    // Open booking flow from Services
    await tester.tap(find.text('Services'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Book Now').first);
    await tester.pumpAndSettle();

    // Step 0 -> Step 1 -> Step 2
    await tester.tap(find.widgetWithText(ElevatedButton, 'Continue'));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(ElevatedButton, 'Continue'));
    await tester.pumpAndSettle();

    expect(find.text('Pickup Address: *'), findsOneWidget);

    // Tap "Add Address"
    await tester.tap(find.text('Add Address'));
    await tester.pumpAndSettle();

    expect(find.text('Add New Address'), findsOneWidget);

    // Fill new address form
    final addrField = find.byWidgetPredicate(
      (w) => w is TextField && w.decoration?.hintText == 'e.g. Flat 301, Brigade Metropolis, Whitefield',
    );
    await tester.enterText(addrField, 'Villa 12, Palm Meadows, Whitefield');

    final pinField = find.byWidgetPredicate(
      (w) => w is TextField && w.decoration?.hintText == 'e.g. 560103',
    );
    await tester.enterText(pinField, '560066');

    // Save Address
    await tester.tap(find.widgetWithText(ElevatedButton, 'Save Address'));
    await tester.pumpAndSettle();

    // Verify new address appears and is selected
    expect(find.text('Villa 12, Palm Meadows, Whitefield, Bengaluru - 560066'), findsOneWidget);
  });

  // =========================================================================
  // PHASE 2 - STEP 3: SERVICE DISCOVERY & DETAILED SERVICE EXPERIENCE TESTS
  // =========================================================================

  testWidgets('Service Discovery: Price and Duration sorting, Category filtering',
      (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const MyMechanicApp());
    await tester.pump(const Duration(milliseconds: 2500));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Services'));
    await tester.pumpAndSettle();

    expect(find.text('Sort & Filter'), findsOneWidget);
    await tester.tap(find.text('Sort & Filter'));
    await tester.pumpAndSettle();

    expect(find.text('Filter & Sort Services'), findsOneWidget);
    expect(find.text('Price: Low to High'), findsOneWidget);

    await tester.tap(find.text('Price: Low to High'));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(ElevatedButton, 'Apply Filters'));
    await tester.pumpAndSettle();

    // Verify low price service appears at top
    expect(find.text('Tubeless Tyre Puncture & Valve Replacement Kit'), findsOneWidget);

    // Change to Price: High to Low
    await tester.tap(find.text('Sort & Filter'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Price: High to Low'));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(ElevatedButton, 'Apply Filters'));
    await tester.pumpAndSettle();

    // Verify high price service appears
    expect(find.text('Comprehensive Master Overhaul Service'), findsOneWidget);

    // Clear filters
    expect(find.text('Clear Filters'), findsOneWidget);
    await tester.tap(find.text('Clear Filters'));
    await tester.pumpAndSettle();
  });

  testWidgets('Detailed Service Details Sheet: Inclusions, Exclusions, Benefits, Process, and FAQ expansion',
      (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 2000));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const MyMechanicApp());
    await tester.pump(const Duration(milliseconds: 2500));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Services'));
    await tester.pumpAndSettle();

    expect(find.text('View Details'), findsWidgets);
    await tester.tap(find.text('View Details').first);
    await tester.pumpAndSettle();

    // Verify sections inside ServiceDetailSheet
    expect(find.text('Overview'), findsOneWidget);
    expect(find.text("What's Included"), findsOneWidget);

    await tester.drag(find.text("What's Included"), const Offset(0, -600));
    await tester.pumpAndSettle();
    expect(find.text("What's Not Included"), findsOneWidget);

    await tester.drag(find.text("What's Not Included"), const Offset(0, -600));
    await tester.pumpAndSettle();
    expect(find.text('Frequently Asked Questions'), findsOneWidget);

    // Tap FAQ question
    final faqFinder = find.text('How often should I book a Standard Periodic Service?');
    expect(faqFinder, findsOneWidget);
    await tester.tap(faqFinder);
    await tester.pumpAndSettle();

    // Verify answer is revealed
    expect(find.textContaining('every 10,000 km or 6 months'), findsOneWidget);

    // Tap Book Now from Service Details
    await tester.tap(find.widgetWithText(ElevatedButton, 'Book Now').last);
    await tester.pumpAndSettle();

    // Verify Booking flow is triggered with this service
    expect(find.text('SELECTED SERVICE'), findsOneWidget);
    expect(find.text('Select Vehicle for this Service: *'), findsOneWidget);
  });

  testWidgets('Service Packages: Tab switching, expansion, and direct booking',
      (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const MyMechanicApp());
    await tester.pump(const Duration(milliseconds: 2500));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Services'));
    await tester.pumpAndSettle();

    // Switch to Packages tab
    expect(find.textContaining('Service Packages'), findsOneWidget);
    await tester.tap(find.textContaining('Service Packages'));
    await tester.pumpAndSettle();

    expect(find.text('Basic Periodic Service'), findsOneWidget);
    expect(find.text('Standard Periodic Service'), findsOneWidget);
    expect(find.text('Comprehensive Master Service'), findsOneWidget);

    // Expand package
    expect(find.text('Tap to View Details'), findsWidgets);
    await tester.tap(find.text('Tap to View Details').first);
    await tester.pumpAndSettle();

    expect(find.text('Hide Checklist'), findsOneWidget);

    // Book package
    expect(find.text('Select Package'), findsWidgets);
    await tester.tap(find.text('Select Package').first);
    await tester.pumpAndSettle();

    // Verify Booking flow opens with Basic Periodic Service
    expect(find.text('SELECTED SERVICE'), findsOneWidget);
    expect(find.text('Basic Periodic Service'), findsWidgets);
  });

  testWidgets('Home Screen: Service Package direct booking',
      (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const MyMechanicApp());
    await tester.pump(const Duration(milliseconds: 2500));
    await tester.pumpAndSettle();

    // Verify Popular Services is removed from Home
    expect(find.text('Popular Services'), findsNothing);

    // Scroll to Service Packages on Home
    await tester.scrollUntilVisible(
      find.text('Select Package').first,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expect(find.text('Select Package'), findsWidgets);

    await tester.tap(find.text('Select Package').first);
    await tester.pumpAndSettle();

    expect(find.text('SELECTED SERVICE'), findsOneWidget);
  });

  // =========================================================================
  // PHASE 2 - STEP 4: SERVICE HISTORY, REMINDERS & ENHANCED TRACKING TESTS
  // =========================================================================

  testWidgets('Phase 2 Step 4: Vehicle service history loads and is vehicle-specific',
      (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    // Provide history for both Creta and Swift
    MockData.bookings = [
      Booking(
        id: 'b1',
        bookingNumber: 'MM-2026-9481',
        serviceTitle: 'Standard Periodic Service',
        serviceDescription: 'Active checkup',
        vehicleName: 'Hyundai Creta 1.5 SX(O)',
        vehicleNumber: 'KA 01 MJ 4521',
        dateTime: DateTime.now().add(const Duration(days: 1)),
        totalAmount: 3699,
        status: BookingStatus.inProgress,
        workshopName: 'Flagship Hub',
        assignedMechanic: 'Rajesh Kumar',
      ),
      Booking(
        id: 'b2',
        bookingNumber: 'MM-2026-7832',
        serviceTitle: 'Deep Interior Spa & Sanitization',
        serviceDescription: 'Wet shampooing',
        vehicleName: 'Maruti Suzuki Swift ZXi',
        vehicleNumber: 'DL 03 CA 9812',
        dateTime: DateTime.now().subtract(const Duration(days: 12)),
        totalAmount: 1599,
        status: BookingStatus.completed,
        workshopName: 'Indiranagar Hub',
        assignedMechanic: 'Amit Verma',
      ),
      Booking(
        id: 'b3',
        bookingNumber: 'MM-2026-5120',
        serviceTitle: 'Standard Periodic Service',
        serviceDescription: 'Completed maintenance',
        vehicleName: 'Hyundai Creta 1.5 SX(O)',
        vehicleNumber: 'KA 01 MJ 4521',
        dateTime: DateTime.now().subtract(const Duration(days: 45)),
        totalAmount: 3487,
        status: BookingStatus.completed,
        workshopName: 'Flagship Hub',
        assignedMechanic: 'Rajesh Kumar',
      ),
    ];
    MockData.bookingsNotifier.value = List.from(MockData.bookings);

    await tester.binding.setSurfaceSize(const Size(800, 2400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const MyMechanicApp());
    await tester.pump(const Duration(milliseconds: 2500));
    await tester.pumpAndSettle();

    // Navigate to Manage Garage
    await tester.tap(find.text('Manage Garage'));
    await tester.pumpAndSettle();

    expect(find.text('My Garage'), findsWidgets);

    // Tap "Service History" quick action on the first vehicle (Creta)
    expect(find.text('Service History'), findsWidgets);
    await tester.tap(find.text('Service History').first);
    await tester.pumpAndSettle();

    // Verify Vehicle Dashboard opened with Creta's specific history
    expect(find.text('Vehicle Dashboard'), findsOneWidget);
    expect(find.text('MM-2026-5120'), findsOneWidget);
    expect(find.text('Standard Periodic Service'), findsWidgets);
    // Swift's booking ID must NOT be present in Creta's history!
    expect(find.text('MM-2026-7832'), findsNothing);
  });

  testWidgets('Phase 2 Step 4: History details open with breakdown and Book Again opens booking flow',
      (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    MockData.bookings = [
      Booking(
        id: 'b2',
        bookingNumber: 'MM-2026-7832',
        serviceTitle: 'Deep Interior Spa & Sanitization',
        serviceDescription: 'Steam sanitization and leather conditioning',
        vehicleName: 'Maruti Suzuki Swift ZXi',
        vehicleNumber: 'DL 03 CA 9812',
        dateTime: DateTime.now().subtract(const Duration(days: 12)),
        servicePrice: 1599,
        totalAmount: 1599,
        pickupType: 'Drop at Workshop',
        status: BookingStatus.completed,
        workshopName: 'MyMechanic Express Center, Indiranagar',
        assignedMechanic: 'Amit Verma (Detailing Lead)',
        warrantyPeriod: '100% Odor-Free Guarantee',
        duration: '3.5 Hours',
        includedItems: const ['Deep Carpet & Seat Shampooing'],
        checklist: const ['Complete dry vacuuming'],
      ),
    ];
    MockData.bookingsNotifier.value = List.from(MockData.bookings);

    await tester.pumpWidget(const MyMechanicApp());
    await tester.pump(const Duration(milliseconds: 2500));
    await tester.pumpAndSettle();

    // Go to Bookings -> History tab via Account -> My Bookings
    await tester.tap(find.text('Account'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('My Bookings'));
    await tester.pumpAndSettle();

    await tester.tap(find.textContaining('History'));
    await tester.pumpAndSettle();

    expect(find.text('Deep Interior Spa & Sanitization'), findsOneWidget);

    // Tap "View Summary" to open BookingDetailsSheet
    await tester.tap(find.text('View Summary'));
    await tester.pumpAndSettle();

    expect(find.text('Booking Details'), findsOneWidget);

    // Tap "View Service Summary" to open ServiceSummarySheet
    expect(find.text('View Service Summary'), findsOneWidget);
    await tester.tap(find.text('View Service Summary'));
    await tester.pumpAndSettle();

    expect(find.text('Service Summary'), findsOneWidget);
    expect(find.text('BOOKING INFORMATION'), findsOneWidget);
    expect(find.text('VEHICLE INFORMATION'), findsOneWidget);
    expect(find.text('SERVICE DETAILS'), findsOneWidget);
    expect(find.text('PRICE BREAKDOWN'), findsWidgets);
    expect(find.text('SERVICE WORK & CHECKLIST'), findsOneWidget);

    // Tap "Book Again" on top sheet
    expect(find.text('Book Again'), findsWidgets);
    await tester.tap(find.text('Book Again').last);
    await tester.pumpAndSettle();

    // Verify Booking flow opened with pre-populated service
    expect(find.text('SELECTED SERVICE'), findsOneWidget);
    expect(find.text('Deep Interior Spa & Sanitization'), findsWidgets);
  });

  testWidgets('Phase 2 Step 4: Upcoming service reminder displays and Book Service works',
      (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 2400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const MyMechanicApp());
    await tester.pump(const Duration(milliseconds: 2500));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Manage Garage'));
    await tester.pumpAndSettle();

    // Check reminder displayed on vehicle card
    expect(find.textContaining('Periodic Service due in 12 days'), findsOneWidget);
    expect(find.text('Due Soon'), findsWidgets);

    // Tap "Book Service" CTA on the card
    expect(find.text('Book Service'), findsWidgets);
    await tester.tap(find.text('Book Service').first);
    await tester.pumpAndSettle();

    // Verify 5-step booking flow opens pre-populated
    expect(find.text('SELECTED SERVICE'), findsOneWidget);
    expect(find.text('Periodic Service'), findsWidgets);
  });

  testWidgets('Phase 2 Step 4: Active booking tracking timeline displays all 7 stages and Cancelled booking shows cancellation banner',
      (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    MockData.bookings = [
      Booking(
        id: 'b1',
        bookingNumber: 'MM-2026-9481',
        serviceTitle: 'Standard Periodic Service',
        vehicleName: 'Hyundai Creta 1.5 SX(O)',
        vehicleNumber: 'KA 01 MJ 4521',
        dateTime: DateTime.now().add(const Duration(days: 1)),
        totalAmount: 3699,
        status: BookingStatus.inProgress,
        workshopName: 'Flagship Hub',
        assignedMechanic: 'Rajesh Kumar',
      ),
      Booking(
        id: 'b4',
        bookingNumber: 'MM-2026-3914',
        serviceTitle: 'Doorstep Car Battery Replacement',
        vehicleName: 'Maruti Suzuki Swift ZXi',
        vehicleNumber: 'DL 03 CA 9812',
        dateTime: DateTime.now().subtract(const Duration(days: 20)),
        totalAmount: 3899,
        status: BookingStatus.cancelled,
        workshopName: 'Indiranagar Center',
        assignedMechanic: 'Vikram Singh',
      ),
    ];
    MockData.bookingsNotifier.value = List.from(MockData.bookings);

    await tester.pumpWidget(const MyMechanicApp());
    await tester.pump(const Duration(milliseconds: 2500));
    await tester.pumpAndSettle();

    // 1. Check Active booking tracking via Account -> My Bookings
    await tester.tap(find.text('Account'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('My Bookings'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Track Live').first);
    await tester.pumpAndSettle();

    expect(find.text('Live Service Tracker'), findsOneWidget);
    expect(find.text('Booking Confirmed'), findsOneWidget);
    expect(find.text('Vehicle Pickup / Vehicle Received'), findsOneWidget);
    expect(find.text('Inspection Started'), findsOneWidget);
    expect(find.text('Service In Progress'), findsWidgets);
    expect(find.text('Quality Check'), findsOneWidget);
    await tester.drag(find.byType(ListView).last, const Offset(0, -300));
    await tester.pumpAndSettle();
    expect(find.text('Ready for Delivery'), findsOneWidget);
    expect(find.text('Completed'), findsWidgets);

    // Close tracker
    await tester.tap(find.byIcon(Icons.close_rounded));
    await tester.pumpAndSettle();

    // 2. Check Cancelled booking in History does NOT show active tracking timeline
    await tester.tap(find.textContaining('History'));
    await tester.pumpAndSettle();

    expect(find.text('Doorstep Car Battery Replacement'), findsOneWidget);
    await tester.tap(find.text('Doorstep Car Battery Replacement'));
    await tester.pumpAndSettle();

    expect(find.text('Booking Details'), findsOneWidget);
    expect(find.text('Cancelled'), findsWidgets);
    expect(find.text('Track Service'), findsNothing); // Cancelled booking must NOT have Track Service action
    expect(find.text('Book Again'), findsOneWidget);
  });

  testWidgets('Phase 2 Step 4: Rating sheet opens, submits rating, prevents duplicate, and shows rated state',
      (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    MockData.bookings = [
      Booking(
        id: 'b2',
        bookingNumber: 'MM-2026-7832',
        serviceTitle: 'Deep Interior Spa & Sanitization',
        vehicleName: 'Maruti Suzuki Swift ZXi',
        vehicleNumber: 'DL 03 CA 9812',
        dateTime: DateTime.now().subtract(const Duration(days: 12)),
        servicePrice: 1599,
        totalAmount: 1599,
        status: BookingStatus.completed,
        workshopName: 'Indiranagar Center',
        assignedMechanic: 'Amit Verma',
        isRated: false,
      ),
    ];
    MockData.bookingsNotifier.value = List.from(MockData.bookings);

    await tester.pumpWidget(const MyMechanicApp());
    await tester.pump(const Duration(milliseconds: 2500));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Account'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('My Bookings'));
    await tester.pumpAndSettle();

    await tester.tap(find.textContaining('History'));
    await tester.pumpAndSettle();

    // Tap completed booking card to open details
    await tester.tap(find.text('Deep Interior Spa & Sanitization'));
    await tester.pumpAndSettle();

    // Tap "Rate Service"
    expect(find.text('Rate Service'), findsOneWidget);
    await tester.tap(find.text('Rate Service'));
    await tester.pumpAndSettle();

    expect(find.text('Rate Your Service'), findsOneWidget);
    expect(find.text('Submit Feedback'), findsOneWidget);

    // Tap category chip
    await tester.tap(find.text('Timeliness'));
    await tester.pumpAndSettle();

    // Tap Submit Feedback
    await tester.tap(find.text('Submit Feedback'));
    await tester.pumpAndSettle();

    // Verify rating confirmed
    expect(find.textContaining('Thank you! Your rating'), findsOneWidget);

    // Test 1: Verify rating state in data model
    final updatedBooking = MockData.bookings.firstWhere((b) => b.id == 'b2');
    expect(updatedBooking.isRated, isTrue);
    expect(updatedBooking.rating, equals(5));

    // Test 2: Verify "Rated ★5" is now displayed instead of "Rate Service" on open details sheet
    expect(find.text('Rated ★5'), findsOneWidget);
    expect(find.text('Rate Service'), findsNothing);

    // Test 3: Tapping "Rated ★5" does NOT reopen the rating sheet
    await tester.tap(find.text('Rated ★5'));
    await tester.pumpAndSettle();
    expect(find.text('Rate Your Service'), findsNothing);
    expect(find.text('Submit Feedback'), findsNothing);

    // Test 4: Duplicate submission logic prevented at data/helper level
    final duplicateResult = MockData.rateBooking(
      'b2',
      1,
      ['Staff Behaviour'],
      'Should not overwrite',
    );
    expect(duplicateResult, isFalse);
    final bookingAfterDuplicateAttempt = MockData.bookings.firstWhere((b) => b.id == 'b2');
    expect(bookingAfterDuplicateAttempt.rating, equals(5));
    expect(bookingAfterDuplicateAttempt.ratingCategories, contains('Timeliness'));
    expect(bookingAfterDuplicateAttempt.ratingFeedback, isNot(equals('Should not overwrite')));

    // Test 5: Service Summary protection
    await tester.tap(find.text('View Service Summary'));
    await tester.pumpAndSettle();
    expect(find.text('Service Summary'), findsOneWidget);
    expect(find.text('Rated ★5'), findsWidgets);

    // Tap rating action in Service Summary - must NOT reopen rating sheet
    await tester.tap(find.text('Rated ★5').last);
    await tester.pumpAndSettle();
    expect(find.text('Rate Your Service'), findsNothing);
  });

  testWidgets('Phase 2 Step 4: Profile Service History opens with vehicle filtering and search',
      (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    MockData.bookings = [
      Booking(
        id: 'b2',
        bookingNumber: 'MM-2026-7832',
        serviceTitle: 'Deep Interior Spa & Sanitization',
        vehicleName: 'Maruti Suzuki Swift ZXi',
        vehicleNumber: 'DL 03 CA 9812',
        dateTime: DateTime.now().subtract(const Duration(days: 12)),
        totalAmount: 1599,
        status: BookingStatus.completed,
        workshopName: 'Indiranagar Hub',
        assignedMechanic: 'Amit Verma',
      ),
      Booking(
        id: 'b3',
        bookingNumber: 'MM-2026-5120',
        serviceTitle: 'Standard Periodic Service',
        vehicleName: 'Hyundai Creta 1.5 SX(O)',
        vehicleNumber: 'KA 01 MJ 4521',
        dateTime: DateTime.now().subtract(const Duration(days: 45)),
        totalAmount: 3487,
        status: BookingStatus.completed,
        workshopName: 'Flagship Hub',
        assignedMechanic: 'Rajesh Kumar',
      ),
    ];
    MockData.bookingsNotifier.value = List.from(MockData.bookings);

    await tester.pumpWidget(const MyMechanicApp());
    await tester.pump(const Duration(milliseconds: 2500));
    await tester.pumpAndSettle();

    // Open Account (Profile) screen
    await tester.tap(find.text('Account'));
    await tester.pumpAndSettle();

    // Scroll to "Service History" menu item
    await tester.scrollUntilVisible(find.text('Service History'), 100);
    await tester.tap(find.text('Service History'));
    await tester.pumpAndSettle();

    // Verify ServiceHistoryScreen opened
    expect(find.text('Service History'), findsWidgets);
    expect(find.text('Deep Interior Spa & Sanitization'), findsOneWidget);
    expect(find.text('Standard Periodic Service'), findsOneWidget);

    // Vehicle Filter: Tap Maruti Suzuki Swift chip
    expect(find.text('Maruti Suzuki Swift'), findsOneWidget);
    await tester.tap(find.text('Maruti Suzuki Swift'));
    await tester.pumpAndSettle();

    // Creta service should now be filtered out
    expect(find.text('Deep Interior Spa & Sanitization'), findsOneWidget);
    expect(find.text('Standard Periodic Service'), findsNothing);

    // Search Filter: Type "Interior"
    await tester.enterText(find.byType(TextField), 'Interior');
    await tester.pumpAndSettle();

    expect(find.text('Deep Interior Spa & Sanitization'), findsOneWidget);

    // Search query with no match shows empty state
    await tester.enterText(find.byType(TextField), 'NonExistentService');
    await tester.pumpAndSettle();

    expect(find.text('No service history yet'), findsOneWidget);
  });

  // =========================================================================
  // PHASE 2 - STEP 5: OFFERS, COUPONS, FAVORITES & CUSTOMER EXPERIENCE TESTS
  // =========================================================================

  test('Phase 2 Step 5: Coupon validation and discount calculations', () {
    // 1. Valid Flat Coupon with Min Order satisfied
    final flatCoupon = MockData.findCoupon('MYFIRST500')!;
    final validFlat = flatCoupon.validate(orderAmount: 3000, category: 'Periodic Services');
    expect(validFlat.isValid, isTrue);
    expect(flatCoupon.calculateDiscount(3000), equals(500.0));

    // 2. Flat Coupon with order below Min Order
    final invalidMinOrder = flatCoupon.validate(orderAmount: 1000, category: 'Periodic Services');
    expect(invalidMinOrder.isValid, isFalse);
    expect(invalidMinOrder.reason, contains('Minimum order value'));

    // 3. Valid Percentage Coupon with Max Discount cap
    final pctCoupon = MockData.findCoupon('COOLCHILL25')!;
    final validPct = pctCoupon.validate(orderAmount: 4000, category: 'AC Service & Repair');
    expect(validPct.isValid, isTrue);
    // 25% of 4000 is 1000, max discount is 750
    expect(pctCoupon.calculateDiscount(4000), equals(750.0));

    // 4. Category-Restricted Coupon (COOLCHILL25 is only for AC Service & Repair)
    final wrongCat = pctCoupon.validate(orderAmount: 2000, category: 'Periodic Services');
    expect(wrongCat.isValid, isFalse);
    expect(wrongCat.reason, contains('AC Service & Repair'));

    // 5. Expired Coupon
    final expiredCoupon = MockData.findCoupon('EXPIRED50')!;
    final expiredRes = expiredCoupon.validate(orderAmount: 2000);
    expect(expiredRes.isValid, isFalse);
    expect(expiredRes.reason, contains('expired'));

    // 6. Max Usage Limit Reached Coupon
    final limitCoupon = MockData.findCoupon('LIMITREACHED')!;
    final limitRes = limitCoupon.validate(orderAmount: 2000);
    expect(limitRes.isValid, isFalse);
    expect(limitRes.reason, contains('Maximum usage limit reached'));

    // 7. Case-insensitive lookup
    expect(MockData.findCoupon('myfirst500'), isNotNull);
    expect(MockData.findCoupon('MyFirst500')?.code, equals('MYFIRST500'));
  });

  test('Phase 2 Step 5: Favorites toggle, duplication prevention, and reactive notifiers', () {
    expect(MockData.isServiceFavorite('srv_periodic_1'), isFalse);

    // Toggle on
    MockData.toggleServiceFavorite('srv_periodic_1');
    expect(MockData.isServiceFavorite('srv_periodic_1'), isTrue);
    expect(MockData.favoriteServiceIdsNotifier.value.contains('srv_periodic_1'), isTrue);

    // Toggle off
    MockData.toggleServiceFavorite('srv_periodic_1');
    expect(MockData.isServiceFavorite('srv_periodic_1'), isFalse);
    expect(MockData.favoriteServiceIdsNotifier.value.contains('srv_periodic_1'), isFalse);

    // Package favorites
    expect(MockData.isPackageFavorite('pkg_basic'), isFalse);
    MockData.togglePackageFavorite('pkg_basic');
    expect(MockData.isPackageFavorite('pkg_basic'), isTrue);
    MockData.togglePackageFavorite('pkg_basic');
    expect(MockData.isPackageFavorite('pkg_basic'), isFalse);
  });

  test('Phase 2 Step 5: Recently viewed deduplication and capped MRU list', () {
    MockData.recentlyViewedNotifier.value = [];

    MockData.addRecentlyViewed('srv_periodic_standard');
    MockData.addRecentlyViewed('srv_wheel_alignment');
    MockData.addRecentlyViewed('srv_periodic_standard'); // Re-viewing moves to head

    expect(MockData.recentlyViewedNotifier.value.first, equals('srv_periodic_standard'));
    expect(MockData.recentlyViewedNotifier.value.length, equals(2)); // No duplicates
  });

  test('Phase 2 Step 5: Notification state and automated booking triggers', () {
    final initialCount = MockData.notifications.length;
    final firstNotification = MockData.notifications.first;

    // Mark as read
    MockData.markNotificationAsRead(firstNotification.id);
    expect(MockData.notifications.firstWhere((n) => n.id == firstNotification.id).isRead, isTrue);

    // Mark all as read
    MockData.markAllNotificationsAsRead();
    expect(MockData.notifications.every((n) => n.isRead), isTrue);

    // Adding booking automatically emits notification
    final testBooking = Booking(
      id: 'b_test_notify',
      bookingNumber: 'MM-TEST-NOTIFY',
      serviceTitle: 'Test Battery Service',
      serviceDescription: 'Testing notification creation',
      vehicleName: 'Hyundai Creta',
      vehicleNumber: 'KA 01 MJ 4521',
      dateTime: DateTime.now().add(const Duration(days: 2)),
      timeSlot: '11:00 AM',
      servicePrice: 1999,
      totalAmount: 1999,
      pickupType: 'Doorstep Pickup & Drop',
      status: BookingStatus.confirmed,
      workshopName: 'Hub Koramangala',
      assignedMechanic: 'Rajesh',
    );
    MockData.addBooking(testBooking);

    expect(MockData.notifications.length, equals(initialCount + 1));
    expect(MockData.notifications.first.title, contains('Booking Confirmed'));
  });

  testWidgets('Phase 2 Step 5: Exclusive Offers section, Offers screen, and Offer Detail sheet',
      (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const MyMechanicApp());
    await tester.pump(const Duration(milliseconds: 2500));
    await tester.pumpAndSettle();

    // Verify Exclusive Offers on Home screen
    expect(find.text('Exclusive Offers'), findsOneWidget);
    expect(find.text('MYFIRST500'), findsOneWidget);

    // Scroll to Exclusive Offers and tap "View All"
    await tester.scrollUntilVisible(
      find.text('Exclusive Offers'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('View All').first);
    await tester.pumpAndSettle();

    // Verify OffersScreen opened
    expect(find.text('Exclusive Offers & Deals'), findsOneWidget);
    expect(find.text('All Deals'), findsOneWidget);
    expect(find.text('COOLCHILL25'), findsOneWidget);

    // Filter by category chip
    await tester.tap(find.text('AC Service & Repair').first);
    await tester.pumpAndSettle();

    expect(find.text('COOLCHILL25'), findsOneWidget);

    // Tap offer card header to open OfferDetailSheet
    await tester.tap(find.text('25% OFF On Car AC Services'));
    await tester.pumpAndSettle();

    expect(find.text('Offer Details'), findsOneWidget);
    expect(find.text('TERMS & CONDITIONS'), findsOneWidget);
    expect(find.text('Apply Offer'), findsWidgets);

    // Tap Apply Offer in detail sheet
    await tester.tap(find.text('Apply Offer').last);
    await tester.pumpAndSettle();

    // Booking flow opens pre-populated
    expect(find.text('SELECTED SERVICE'), findsOneWidget);
  });

  testWidgets('Phase 2 Step 5: Favorites Screen tabs, empty state, and remove action',
      (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    // Initially no favorites
    MockData.favoriteServiceIdsNotifier.value = {};
    MockData.favoritePackageIdsNotifier.value = {};

    await tester.pumpWidget(const MyMechanicApp());
    await tester.pump(const Duration(milliseconds: 2500));
    await tester.pumpAndSettle();

    // Open Account (Profile) screen
    await tester.tap(find.text('Account'));
    await tester.pumpAndSettle();

    // Scroll to Favorites menu item and tap
    await tester.scrollUntilVisible(find.text('Favorites'), 100);
    await tester.tap(find.text('Favorites'));
    await tester.pumpAndSettle();

    // Favorites Screen opened with empty state
    expect(find.text('My Favorites & Wishlist'), findsOneWidget);
    expect(find.text('No favorites yet'), findsOneWidget);
    expect(find.text('Explore Services'), findsOneWidget);

    // Add a favorite programmatically
    MockData.toggleServiceFavorite('srv_periodic_1');
    await tester.pumpAndSettle();

    // Favorite service appears
    expect(find.text('Standard Periodic Service'), findsOneWidget);

    // Remove from favorites via heart action
    await tester.tap(find.byTooltip('Remove from favorites').first);
    await tester.pumpAndSettle();

    // Back to empty state
    expect(find.text('No favorites yet'), findsOneWidget);
  });

  testWidgets('Phase 2 Step 5: Notifications Center with unread counts and mark all read',
      (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const MyMechanicApp());
    await tester.pump(const Duration(milliseconds: 2500));
    await tester.pumpAndSettle();

    // Tap Notifications Bell icon in HomeHeader
    await tester.tap(find.byIcon(Icons.notifications_none_rounded));
    await tester.pumpAndSettle();

    // Notifications Center opened
    expect(find.text('Notifications Center'), findsOneWidget);
    expect(find.text('All'), findsOneWidget);
    expect(find.text('Mark all as read'), findsOneWidget);

    // Tap Mark all as read
    await tester.tap(find.text('Mark all as read'));
    await tester.pumpAndSettle();

    // Unread count should become 0
    expect(MockData.notifications.where((n) => !n.isRead).length, equals(0));
  });

  // =========================================================================
  // PHASE 2 - STEP 6: HOME & NAVIGATION UX POLISH TESTS
  // =========================================================================

  testWidgets('Phase 2 Step 6: Home Screen Primary Service Booking CTA removed and navigation to Services',
      (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 2400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const MyMechanicApp());
    await tester.pump(const Duration(milliseconds: 2500));
    await tester.pumpAndSettle();

    // Verify Primary Service Booking Hero CTA is removed from Home screen
    expect(find.text('EXPRESS CAR CARE'), findsNothing);
    expect(find.text('Schedule Your Next Car Service'), findsNothing);
    expect(find.text('Book Service Now'), findsNothing);

    // Tap "Services" action in "Book a Service" section
    await tester.tap(find.text('Services').first);
    await tester.pumpAndSettle();

    // Navigates directly to Services screen
    expect(find.text('Car Services & Repairs'), findsOneWidget);
  });

  testWidgets('Phase 2 Step 6: Android back navigation PopScope switches back to Home tab',
      (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const MyMechanicApp());
    await tester.pump(const Duration(milliseconds: 2500));
    await tester.pumpAndSettle();

    // Switch to Help tab (Tab 1)
    await tester.tap(find.text('Help'));
    await tester.pumpAndSettle();
    expect(find.text('Help & 24x7 Support'), findsOneWidget);

    // Trigger system back route
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    // Returned to Home tab gracefully without exiting app
    expect(find.text('My Vehicle'), findsOneWidget);
  });

  testWidgets('Phase 2 Step 6: Home search bar navigates to Services screen',
      (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const MyMechanicApp());
    await tester.pump(const Duration(milliseconds: 2500));
    await tester.pumpAndSettle();

    // Tap Home search bar
    await tester.tap(find.byType(TextField));
    await tester.pumpAndSettle();

    // Directly in Services screen with search capability
    expect(find.text('Car Services & Repairs'), findsOneWidget);
    expect(find.text('All Services'), findsOneWidget);
  });

  testWidgets('Phase 2 Step 6: Vehicle selection in booking flow synchronizes active vehicle app-wide',
      (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 2400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    // Initially Creta (v1) is active
    expect(MockData.activeVehicle.id, equals('v1'));

    await tester.pumpWidget(const MyMechanicApp());
    await tester.pump(const Duration(milliseconds: 2500));
    await tester.pumpAndSettle();

    // Tap "Services" action in "Book a Service" section to open Services
    await tester.tap(find.text('Services').first);
    await tester.pumpAndSettle();

    // Tap "Book Now" on first service
    await tester.tap(find.text('Book Now').first);
    await tester.pumpAndSettle();

    // Step 0 shows vehicle list
    expect(find.text('Select Vehicle for this Service: *'), findsOneWidget);
    expect(find.text('Maruti Suzuki Swift (ZXi AMT)'), findsOneWidget);

    // Ensure vehicle item is scrolled into view above sticky footer
    await tester.ensureVisible(find.text('Maruti Suzuki Swift (ZXi AMT)'));
    await tester.pumpAndSettle();

    // Tap on Swift
    await tester.tap(find.text('Maruti Suzuki Swift (ZXi AMT)'));
    await tester.pumpAndSettle();

    // Active vehicle in MockData is immediately synchronized to Swift (v2)
    expect(MockData.activeVehicle.id, equals('v2'));
    expect(MockData.activeVehicle.brand, equals('Maruti Suzuki'));
  });

  testWidgets('Phase 2 Step 7: Dark Theme Redesign and Layered Hierarchy Verification', (WidgetTester tester) async {
    // 1. Verify exact dark palette color hierarchy constants
    expect(AppColors.darkBackground, equals(const Color(0xFF0B0D10)));
    expect(AppColors.darkSurface, equals(const Color(0xFF14171C)));
    expect(AppColors.darkElevatedSurface, equals(const Color(0xFF1B1F26)));
    expect(AppColors.darkInputSurface, equals(const Color(0xFF20242B)));
    expect(AppColors.darkBorder, equals(const Color(0xFF2A2F37)));
    expect(AppColors.darkTextPrimary, equals(const Color(0xFFF5F5F5)));
    expect(AppColors.darkTextSecondary, equals(const Color(0xFFB7BCC5)));
    expect(AppColors.darkTextMuted, equals(const Color(0xFF707782)));
    expect(AppColors.darkBottomNavBg, equals(const Color(0xFF111419)));
    expect(AppColors.darkBottomNavInactive, equals(const Color(0xFF8D949F)));

    // 2. Verify AppTheme.darkTheme adopts the layered architecture
    final dark = AppTheme.darkTheme;
    expect(dark.scaffoldBackgroundColor, equals(const Color(0xFF0B0D10)));
    expect(dark.cardColor, equals(const Color(0xFF14171C)));
    expect(dark.dialogTheme.backgroundColor, equals(const Color(0xFF1B1F26)));
    expect(dark.colorScheme.surface, equals(const Color(0xFF14171C)));
    expect(dark.colorScheme.primary, equals(AppColors.primary));

    // 3. Verify AppTheme.lightTheme is completely unchanged
    final light = AppTheme.lightTheme;
    expect(light.scaffoldBackgroundColor, equals(AppColors.background));
    expect(light.cardColor, equals(AppColors.surface));
    expect(light.colorScheme.primary, equals(AppColors.primary));

    // 4. Verify ThemeService toggling
    ThemeService.instance.setThemeMode(ThemeMode.dark);
    expect(ThemeService.instance.isDarkMode, isTrue);

    ThemeService.instance.setThemeMode(ThemeMode.light);
    expect(ThemeService.instance.isDarkMode, isFalse);
  });
}
