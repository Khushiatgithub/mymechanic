import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mymechanic/core/network/api_client.dart';
import 'package:mymechanic/models/notification_item.dart';
import 'package:mymechanic/services/auth_service.dart';
import 'package:mymechanic/services/notification_service.dart';

void main() {
  const testBaseUrl = 'https://api.mymechanic.test/api/v1';

  final sampleNotificationJson = {
    '_id': '67b8a1000000000000000777',
    'userId': '67b8a1000000000000000010',
    'title': 'Booking Confirmed!',
    'message': 'Your booking #MM-2026-1234 has been confirmed for 10:30 AM.',
    'category': 'booking',
    'isRead': false,
    'actionRoute': '/bookings',
    'relatedId': '67b8a1000000000000000099',
    'createdAt': '2026-03-01T12:00:00.000Z',
  };

  group('NotificationItem Model', () {
    test('fromJson parses correctly', () {
      final item = NotificationItem.fromJson(sampleNotificationJson);

      expect(item.id, equals('67b8a1000000000000000777'));
      expect(item.title, equals('Booking Confirmed!'));
      expect(item.category, equals(NotificationCategory.booking));
      expect(item.isRead, isFalse);
      expect(item.actionRoute, equals('/bookings'));
    });
  });

  group('NotificationService', () {
    test('getNotifications fetches from API and maps models', () async {
      AuthService.instance.authStatusNotifier.value = AuthStatus.authenticated;

      final mockClient = MockClient((request) async {
        expect(request.url.path, equals('/api/v1/notifications'));
        expect(request.method, equals('GET'));

        return http.Response(
          jsonEncode({
            'success': true,
            'message': 'Notifications retrieved successfully',
            'data': [sampleNotificationJson],
          }),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      });

      final apiClient = ApiClient(baseUrl: testBaseUrl, client: mockClient);
      final service = NotificationService(apiClient: apiClient);

      final notifications = await service.getNotifications();

      expect(notifications.length, equals(1));
      expect(notifications.first.title, equals('Booking Confirmed!'));
    });

    test('markAsRead calls PATCH /notifications/:id/read', () async {
      AuthService.instance.authStatusNotifier.value = AuthStatus.authenticated;

      final mockClient = MockClient((request) async {
        expect(request.url.path, equals('/api/v1/notifications/67b8a1000000000000000777/read'));
        expect(request.method, equals('PATCH'));

        return http.Response(
          jsonEncode({
            'success': true,
            'message': 'Notification marked as read',
            'data': {
              ...sampleNotificationJson,
              'isRead': true,
            },
          }),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      });

      final apiClient = ApiClient(baseUrl: testBaseUrl, client: mockClient);
      final service = NotificationService(apiClient: apiClient);

      await service.markAsRead('67b8a1000000000000000777');
    });

    test('markAllAsRead calls PATCH /notifications/read-all', () async {
      AuthService.instance.authStatusNotifier.value = AuthStatus.authenticated;

      final mockClient = MockClient((request) async {
        expect(request.url.path, equals('/api/v1/notifications/read-all'));
        expect(request.method, equals('PATCH'));

        return http.Response(
          jsonEncode({
            'success': true,
            'message': 'All notifications marked as read',
            'data': {'count': 3},
          }),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      });

      final apiClient = ApiClient(baseUrl: testBaseUrl, client: mockClient);
      final service = NotificationService(apiClient: apiClient);

      await service.markAllAsRead();
    });

    test('deleteNotification calls DELETE /notifications/:id', () async {
      AuthService.instance.authStatusNotifier.value = AuthStatus.authenticated;

      final mockClient = MockClient((request) async {
        expect(request.url.path, equals('/api/v1/notifications/67b8a1000000000000000777'));
        expect(request.method, equals('DELETE'));

        return http.Response(
          jsonEncode({
            'success': true,
            'message': 'Notification deleted successfully',
            'data': null,
          }),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      });

      final apiClient = ApiClient(baseUrl: testBaseUrl, client: mockClient);
      final service = NotificationService(apiClient: apiClient);

      await service.deleteNotification('67b8a1000000000000000777');
    });
  });
}
