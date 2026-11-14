import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mymechanic/core/network/api_client.dart';
import 'package:mymechanic/screens/auth/login_screen.dart';
import 'package:mymechanic/screens/auth/register_screen.dart';
import 'package:mymechanic/services/auth_service.dart';

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

  setUp(() {
    storageDriver = FakeSecureStorageDriver();
  });

  Widget createTestWidget(Widget child) {
    return MaterialApp(
      home: child,
    );
  }

  group('LoginScreen Widget Tests', () {
    testWidgets('Renders all login form elements and toggles password visibility', (tester) async {
      final mockClient = MockClient((request) async => http.Response('{}', 200));
      final authService = AuthService.createDefault(
        baseUrl: testBaseUrl,
        client: mockClient,
        storageDriver: storageDriver,
      );

      await tester.pumpWidget(createTestWidget(LoginScreen(authService: authService)));
      await tester.pumpAndSettle();

      // Form elements present
      expect(find.byKey(const Key('login_email_input')), findsOneWidget);
      expect(find.byKey(const Key('login_password_input')), findsOneWidget);
      expect(find.byKey(const Key('login_submit_button')), findsOneWidget);
      expect(find.byKey(const Key('login_register_link')), findsOneWidget);

      // Verify password initially obscured
      final passwordFieldInitial = tester.widget<EditableText>(
        find.descendant(
          of: find.byKey(const Key('login_password_input')),
          matching: find.byType(EditableText),
        ),
      );
      expect(passwordFieldInitial.obscureText, isTrue);

      // Toggle visibility
      await tester.tap(find.byKey(const Key('login_password_visibility_toggle')));
      await tester.pumpAndSettle();

      final passwordFieldRevealed = tester.widget<EditableText>(
        find.descendant(
          of: find.byKey(const Key('login_password_input')),
          matching: find.byType(EditableText),
        ),
      );
      expect(passwordFieldRevealed.obscureText, isFalse);
    });

    testWidgets('Empty submission shows client-side validation errors without network call', (tester) async {
      bool networkCalled = false;
      final mockClient = MockClient((request) async {
        networkCalled = true;
        return http.Response('{}', 200);
      });

      final authService = AuthService.createDefault(
        baseUrl: testBaseUrl,
        client: mockClient,
        storageDriver: storageDriver,
      );

      await tester.pumpWidget(createTestWidget(LoginScreen(authService: authService)));
      await tester.pumpAndSettle();

      // Tap submit with empty fields
      await tester.tap(find.byKey(const Key('login_submit_button')));
      await tester.pumpAndSettle();

      // Client-side validation errors shown
      expect(find.text('Please enter your email address.'), findsOneWidget);
      expect(find.text('Please enter your password.'), findsOneWidget);
      expect(networkCalled, isFalse);
    });

    testWidgets('Successful login triggers callback and displays welcome feedback', (tester) async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'success': true,
            'message': 'Login successful',
            'data': {
              'user': {
                '_id': 'usr_1',
                'name': 'Virat Kohli',
                'email': 'virat@example.com',
                'isActive': true,
              },
              'accessToken': 'acc_token_1',
              'refreshToken': 'ref_token_1',
            },
          }),
          200,
        );
      });

      final authService = AuthService.createDefault(
        baseUrl: testBaseUrl,
        client: mockClient,
        storageDriver: storageDriver,
      );

      bool loginSuccessCalled = false;
      await tester.pumpWidget(
        createTestWidget(
          LoginScreen(
            authService: authService,
            onLoginSuccess: () {
              loginSuccessCalled = true;
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('login_email_input')), 'virat@example.com');
      await tester.enterText(find.byKey(const Key('login_password_input')), 'KohliPass123!');
      await tester.tap(find.byKey(const Key('login_submit_button')));
      await tester.pump(); // Start async login
      await tester.pumpAndSettle();

      expect(loginSuccessCalled, isTrue);
      expect(authService.isAuthenticated, isTrue);
      expect(find.text('Welcome back, Virat Kohli!'), findsOneWidget);
    });

    testWidgets('Failed login displays customer-friendly error banner', (tester) async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'success': false,
            'message': 'Invalid email or password',
            'error': {'code': 'INVALID_CREDENTIALS'},
          }),
          401,
        );
      });

      final authService = AuthService.createDefault(
        baseUrl: testBaseUrl,
        client: mockClient,
        storageDriver: storageDriver,
      );

      await tester.pumpWidget(createTestWidget(LoginScreen(authService: authService)));
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('login_email_input')), 'virat@example.com');
      await tester.enterText(find.byKey(const Key('login_password_input')), 'WrongPassword');
      await tester.tap(find.byKey(const Key('login_submit_button')));
      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('login_error_banner')), findsOneWidget);
      expect(find.textContaining('Invalid email or password'), findsOneWidget);
    });
  });

  group('RegisterScreen Widget Tests', () {
    testWidgets('Renders all registration inputs and validates password match and length', (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1200));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final mockClient = MockClient((request) async => http.Response('{}', 200));
      final authService = AuthService.createDefault(
        baseUrl: testBaseUrl,
        client: mockClient,
        storageDriver: storageDriver,
      );

      await tester.pumpWidget(createTestWidget(RegisterScreen(authService: authService)));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('register_name_input')), findsOneWidget);
      expect(find.byKey(const Key('register_email_input')), findsOneWidget);
      expect(find.byKey(const Key('register_phone_input')), findsOneWidget);
      expect(find.byKey(const Key('register_password_input')), findsOneWidget);
      expect(find.byKey(const Key('register_confirm_password_input')), findsOneWidget);
      expect(find.byKey(const Key('register_submit_button')), findsOneWidget);

      // Enter mismatched passwords
      await tester.enterText(find.byKey(const Key('register_name_input')), 'Ananya');
      await tester.enterText(find.byKey(const Key('register_email_input')), 'ananya@example.com');
      await tester.enterText(find.byKey(const Key('register_password_input')), 'Password123');
      await tester.enterText(find.byKey(const Key('register_confirm_password_input')), 'DifferentPassword');

      await tester.tap(find.byKey(const Key('register_submit_button')));
      await tester.pumpAndSettle();

      expect(find.text('Passwords do not match.'), findsOneWidget);

      // Enter short password (< 8 chars)
      await tester.enterText(find.byKey(const Key('register_password_input')), 'short');
      await tester.enterText(find.byKey(const Key('register_confirm_password_input')), 'short');
      await tester.tap(find.byKey(const Key('register_submit_button')));
      await tester.pumpAndSettle();

      expect(find.text('Password must be at least 8 characters long.'), findsOneWidget);
    });

    testWidgets('Successful registration creates account and triggers completion', (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1200));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'success': true,
            'message': 'Registration successful',
            'data': {
              'user': {
                '_id': 'usr_reg_99',
                'name': 'Karan Singh',
                'email': 'karan@example.com',
                'phone': '+919988776655',
                'isActive': true,
              },
              'accessToken': 'reg_access_token',
              'refreshToken': 'reg_refresh_token',
            },
          }),
          201,
        );
      });

      final authService = AuthService.createDefault(
        baseUrl: testBaseUrl,
        client: mockClient,
        storageDriver: storageDriver,
      );

      bool registerSuccessCalled = false;
      await tester.pumpWidget(
        createTestWidget(
          RegisterScreen(
            authService: authService,
            onRegisterSuccess: () {
              registerSuccessCalled = true;
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('register_name_input')), 'Karan Singh');
      await tester.enterText(find.byKey(const Key('register_email_input')), 'karan@example.com');
      await tester.enterText(find.byKey(const Key('register_phone_input')), '9988776655');
      await tester.enterText(find.byKey(const Key('register_password_input')), 'KaranStrong123!');
      await tester.enterText(find.byKey(const Key('register_confirm_password_input')), 'KaranStrong123!');

      await tester.tap(find.byKey(const Key('register_submit_button')));
      await tester.pump();
      await tester.pumpAndSettle();

      expect(registerSuccessCalled, isTrue);
      expect(authService.isAuthenticated, isTrue);
      expect(authService.currentUser?.name, equals('Karan Singh'));
      expect(find.textContaining('Account created successfully'), findsOneWidget);
    });
  });
}
