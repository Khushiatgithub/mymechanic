import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mymechanic/core/constants/app_constants.dart';
import 'package:mymechanic/screens/main_navigation_screen.dart';
import 'package:mymechanic/screens/splash/splash_screen.dart';
import 'package:mymechanic/services/auth_service.dart';

import '../services/auth_service_test.dart';

void main() {
  late FakeSecureStorageDriver storageDriver;

  setUp(() {
    storageDriver = FakeSecureStorageDriver();
    final mockClient = MockClient((request) async {
      return http.Response(jsonEncode({'success': false}), 400);
    });
    AuthService.instance = AuthService.createDefault(
      baseUrl: 'https://api.mymechanic.test/api/v1',
      client: mockClient,
      storageDriver: storageDriver,
    );
  });

  testWidgets('SplashScreen triggers session initialization and navigates to MainNavigationScreen', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: SplashScreen(),
      ),
    );

    // Initial splash frame
    expect(find.byType(SplashScreen), findsOneWidget);
    expect(find.textContaining('Mechanic', findRichText: true), findsWidgets);
    expect(find.text(AppConstants.appTagline), findsOneWidget);

    // Forward through animation and splash delay
    await tester.pump(const Duration(milliseconds: 1400));
    await tester.pump(const Duration(milliseconds: 700)); // Total > 2000ms
    await tester.pumpAndSettle();

    // Verify navigation smoothly arrived at MainNavigationScreen (guest mode)
    expect(find.byType(MainNavigationScreen), findsOneWidget);
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Help'), findsOneWidget);
    expect(find.text('GoStore'), findsOneWidget);
    expect(find.text('My Vehicles'), findsOneWidget);
    expect(find.text('Account'), findsOneWidget);
  });
}
