import '../core/config/api_config.dart';
import '../core/network/api_client.dart';
import '../data/mock_data.dart';
import '../models/notification_item.dart';
import 'auth_service.dart';

class NotificationService {
  final ApiClient apiClient;

  NotificationService({required this.apiClient});

  static NotificationService? _instance;

  static NotificationService get instance =>
      _instance ??= NotificationService(apiClient: AuthService.instance.apiClient);

  static set instance(NotificationService service) => _instance = service;

  static void resetInstance() {
    _instance = null;
  }

  /// Fetches notifications for authenticated user from `GET /api/v1/notifications`.
  /// Gracefully falls back to [MockData.notifications] if offline or unauthenticated.
  Future<List<NotificationItem>> getNotifications({String? category}) async {
    if (!AuthService.instance.isAuthenticated) {
      return _filterLocalNotifications(category);
    }

    try {
      final queryParams = <String, dynamic>{};
      if (category != null && category.isNotEmpty && category.toLowerCase() != 'all') {
        queryParams['category'] = category.toLowerCase();
      }

      final response = await apiClient.get(
        ApiConfig.notificationsPath,
        queryParameters: queryParams.isEmpty ? null : queryParams,
      );

      final data = response.data;
      List<dynamic> items = [];
      if (data is List) {
        items = data;
      } else if (data is Map<String, dynamic> && data['data'] is List) {
        items = data['data'] as List;
      }

      final notifications = items
          .whereType<Map<String, dynamic>>()
          .map((json) => NotificationItem.fromJson(json))
          .toList();

      if (notifications.isNotEmpty) {
        MockData.notifications = notifications;
        MockData.notificationsNotifier.value = notifications;
        return notifications;
      }

      return _filterLocalNotifications(category);
    } catch (_) {
      return _filterLocalNotifications(category);
    }
  }

  /// Marks a specific notification as read.
  Future<void> markAsRead(String id) async {
    MockData.markNotificationAsRead(id);

    if (AuthService.instance.isAuthenticated && RegExp(r'^[0-9a-fA-F]{24}$').hasMatch(id)) {
      try {
        await apiClient.patch('${ApiConfig.notificationsPath}/$id/read');
      } catch (_) {}
    }
  }

  /// Marks all notifications as read.
  Future<void> markAllAsRead() async {
    MockData.markAllNotificationsAsRead();

    if (AuthService.instance.isAuthenticated) {
      try {
        await apiClient.patch('${ApiConfig.notificationsPath}/read-all');
      } catch (_) {}
    }
  }

  /// Deletes a notification by ID.
  Future<void> deleteNotification(String id) async {
    MockData.deleteNotification(id);

    if (AuthService.instance.isAuthenticated && RegExp(r'^[0-9a-fA-F]{24}$').hasMatch(id)) {
      try {
        await apiClient.delete('${ApiConfig.notificationsPath}/$id');
      } catch (_) {}
    }
  }

  List<NotificationItem> _filterLocalNotifications(String? category) {
    final list = MockData.notificationsNotifier.value;
    if (category == null || category.isEmpty || category.toLowerCase() == 'all') {
      return list;
    }
    final targetCat = category.toLowerCase();
    return list.where((n) => n.category.name.toLowerCase() == targetCat).toList();
  }
}
