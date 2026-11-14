import '../core/config/api_config.dart';
import '../core/network/api_client.dart';
import '../models/service_category.dart';
import '../models/service_item.dart';
import 'auth_service.dart';

/// Service managing service discovery and catalog retrieval from the MyMechanic backend.
///
/// Phase 3 Step 4.7: Service Discovery API Integration.
///
/// Architecture & Guarantees:
/// - Reuses existing [ApiClient] and baseUrl normalization.
/// - Connects to backend `/api/v1/service-categories` and `/api/v1/services`.
/// - Public endpoints: accessible by both guests and authenticated users.
/// - Strongly typed models and defensive parsing for resilient error handling.
/// - Surfaces typed [ApiException] hierarchy and friendly user messages.
class ServiceDiscoveryService {
  final ApiClient apiClient;

  ServiceDiscoveryService({required this.apiClient});

  static ServiceDiscoveryService? _instance;

  /// Global access point for the application.
  static ServiceDiscoveryService get instance =>
      _instance ??= ServiceDiscoveryService(apiClient: AuthService.instance.apiClient);

  /// Inject custom service instance for unit and widget tests.
  static set instance(ServiceDiscoveryService service) => _instance = service;

  /// Resets the singleton instance (useful for test isolation).
  static void resetInstance() {
    _instance = null;
  }

  /// Fetches service categories from `GET /api/v1/service-categories`.
  Future<List<ServiceCategory>> getCategories({
    bool activeOnly = true,
    int page = 1,
    int limit = 50,
  }) async {
    final queryParams = <String, dynamic>{
      'active': activeOnly ? 'true' : 'false',
      'page': page,
      'limit': limit,
    };

    final response = await apiClient.get(
      ApiConfig.serviceCategoriesPath,
      queryParameters: queryParams,
    );

    final data = response.data;
    List<dynamic> items = [];

    if (data is Map<String, dynamic> && data['items'] is List) {
      items = data['items'] as List<dynamic>;
    } else if (data is List) {
      items = data;
    } else if (data is Map<String, dynamic> && data['data'] is List) {
      items = data['data'] as List<dynamic>;
    }

    final categories = items
        .whereType<Map<String, dynamic>>()
        .map((json) => ServiceCategory.fromJson(json))
        .toList();

    // Sort by sortOrder ascending
    categories.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    return categories;
  }

  /// Fetches a single service category by ID from `GET /api/v1/service-categories/:id`.
  Future<ServiceCategory> getCategoryById(String id) async {
    final response = await apiClient.get('${ApiConfig.serviceCategoriesPath}/$id');
    final data = response.data;

    if (data is! Map<String, dynamic>) {
      throw ApiResponseFormatException(
        'Malformed category payload received from server.',
        rawBody: response.rawBody?.toString() ?? '',
      );
    }

    // Unwrap if enclosed in an envelope
    final payload = (data['data'] is Map<String, dynamic>)
        ? data['data'] as Map<String, dynamic>
        : data;

    return ServiceCategory.fromJson(payload);
  }

  /// Fetches services list from `GET /api/v1/services`.
  ///
  /// Supports category filtering, search terms, and sort orders:
  /// - `sort`: 'price_asc' | 'price_desc' | 'rating_desc'
  Future<List<ServiceItem>> getServices({
    String? categoryId,
    String? search,
    String? sort,
    bool activeOnly = true,
    int page = 1,
    int limit = 50,
  }) async {
    final queryParams = <String, dynamic>{
      'active': activeOnly ? 'true' : 'false',
      'page': page,
      'limit': limit,
    };

    if (categoryId != null && categoryId.isNotEmpty && categoryId != 'all') {
      queryParams['categoryId'] = categoryId;
    }

    if (search != null && search.trim().isNotEmpty) {
      queryParams['search'] = search.trim();
    }

    if (sort != null && sort.isNotEmpty) {
      queryParams['sort'] = sort;
    }

    final response = await apiClient.get(
      ApiConfig.servicesPath,
      queryParameters: queryParams,
    );

    final data = response.data;
    List<dynamic> items = [];

    if (data is Map<String, dynamic> && data['items'] is List) {
      items = data['items'] as List<dynamic>;
    } else if (data is List) {
      items = data;
    } else if (data is Map<String, dynamic> && data['data'] is List) {
      items = data['data'] as List<dynamic>;
    }

    return items
        .whereType<Map<String, dynamic>>()
        .map((json) => ServiceItem.fromJson(json))
        .toList();
  }

  /// Fetches a single service by ID from `GET /api/v1/services/:id`.
  Future<ServiceItem> getServiceById(String id) async {
    final response = await apiClient.get('${ApiConfig.servicesPath}/$id');
    final data = response.data;

    if (data is! Map<String, dynamic>) {
      throw ApiResponseFormatException(
        'Malformed service payload received from server.',
        rawBody: response.rawBody?.toString() ?? '',
      );
    }

    final payload = (data['data'] is Map<String, dynamic>)
        ? data['data'] as Map<String, dynamic>
        : data;

    return ServiceItem.fromJson(payload);
  }

  /// Maps typed [ApiException] to user-friendly messages.
  static String getErrorMessage(Object error) {
    if (error is HttpStatusException) {
      if (error.statusCode == 404) {
        return 'The requested service or category could not be found.';
      }
      if (error.statusCode == 400) {
        return error.message.isNotEmpty
            ? error.message
            : 'Invalid service request parameters.';
      }
      if (error.statusCode == 401) {
        return 'Please sign in to access this service.';
      }
      if (error.statusCode >= 500) {
        return 'Server error while loading services. Please try again later.';
      }
      return error.message.isNotEmpty
          ? error.message
          : 'Request failed (${error.statusCode}).';
    }

    if (error is NetworkException) {
      return 'Unable to reach MyMechanic servers. Please check your internet connection.';
    }

    if (error is ApiTimeoutException) {
      return 'Request timed out. Please check your connection and try again.';
    }

    if (error is ApiResponseFormatException) {
      return 'Invalid or malformed data received from the server.';
    }

    return 'An unexpected error occurred while loading services.';
  }
}
