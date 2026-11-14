import '../core/config/api_config.dart';
import '../core/network/api_client.dart';
import '../data/mock_data.dart';
import '../models/workshop.dart';
import 'auth_service.dart';

class WorkshopService {
  final ApiClient apiClient;

  WorkshopService({required this.apiClient});

  static WorkshopService? _instance;

  static WorkshopService get instance =>
      _instance ??= WorkshopService(apiClient: AuthService.instance.apiClient);

  static set instance(WorkshopService service) => _instance = service;

  static void resetInstance() {
    _instance = null;
  }

  /// Fetches Bangalore workshop hubs from `GET /api/v1/workshops`.
  /// Gracefully falls back to [MockData.workshops] on network or format error.
  Future<List<Workshop>> getWorkshops({String? city, String? area}) async {
    try {
      final queryParams = <String, dynamic>{};
      if (city != null && city.isNotEmpty) {
        queryParams['city'] = city;
      }
      if (area != null && area.isNotEmpty) {
        queryParams['area'] = area;
      }

      final response = await apiClient.get(
        ApiConfig.workshopsPath,
        queryParameters: queryParams.isEmpty ? null : queryParams,
      );

      final data = response.data;
      if (data is List) {
        return data
            .whereType<Map<String, dynamic>>()
            .map((item) => Workshop.fromJson(item))
            .toList();
      }
      if (data is Map<String, dynamic> && data['data'] is List) {
        final list = data['data'] as List;
        return list
            .whereType<Map<String, dynamic>>()
            .map((item) => Workshop.fromJson(item))
            .toList();
      }

      return _filterFallbackWorkshops(city: city, area: area);
    } catch (_) {
      return _filterFallbackWorkshops(city: city, area: area);
    }
  }

  /// Offline / fallback helper using [MockData.workshops].
  List<Workshop> _filterFallbackWorkshops({String? city, String? area}) {
    var items = List<Workshop>.from(MockData.workshops);
    if (city != null && city.isNotEmpty) {
      items = items
          .where((w) => w.city.toLowerCase() == city.toLowerCase())
          .toList();
    }
    if (area != null && area.isNotEmpty) {
      items = items
          .where((w) => w.area.toLowerCase() == area.toLowerCase())
          .toList();
    }
    return items;
  }
}
