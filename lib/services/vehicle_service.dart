import '../core/config/api_config.dart';
import '../core/network/api_client.dart';
import '../data/mock_data.dart';
import '../models/vehicle.dart';
import 'auth_service.dart';

/// Service managing vehicle CRUD operations with the authenticated MyMechanic backend.
///
/// Phase 3 Step 4.6: Vehicle Management API Integration.
/// Phase 3 Step 4.13: Home Screen Vehicle Auto-Synchronization.
///
/// Architecture & Security:
/// - Reuses authenticated [ApiClient] so Bearer tokens are attached and rotated automatically.
/// - Client never sends arbitrary userId; ownership is derived server-side from JWT.
/// - Never clears auth session on vehicle errors; delegates to [AuthSessionCoordinator].
/// - Surfaces typed [ApiException] hierarchy and friendly user messages.
class VehicleService {
  final ApiClient apiClient;

  VehicleService({required this.apiClient});

  static VehicleService? _instance;

  /// Global access point for the application.
  static VehicleService get instance =>
      _instance ??= VehicleService(apiClient: AuthService.instance.apiClient);

  /// Inject custom service instance for unit and widget tests.
  static set instance(VehicleService service) => _instance = service;

  int _syncSequence = 0;
  Future<List<Vehicle>?>? _inFlightSync;
  bool _hasSyncedForCurrentSession = false;

  /// Whether vehicles have been successfully fetched for the current session.
  bool get hasSyncedForCurrentSession => _hasSyncedForCurrentSession;

  /// Synchronizes the authenticated user's vehicles with [MockData.vehiclesNotifier].
  ///
  /// Concurrency & Reliability guarantees:
  /// 1. Deduplicates concurrent in-flight synchronization requests.
  /// 2. Uses sequence tracking to prevent stale responses from overwriting newer sessions.
  /// 3. Catches network and server errors gracefully to prevent crashes or UI blocking.
  /// 4. Respects existing active-vehicle selection and fallback rules.
  /// 5. Automatically updates [MockData.vehicles] and [MockData.vehiclesNotifier].
  Future<List<Vehicle>?> syncUserVehicles({
    AuthService? authService,
    bool force = false,
  }) async {
    final auth = authService ?? AuthService.instance;
    if (!auth.isAuthenticated) {
      return null;
    }

    if (!force && _hasSyncedForCurrentSession) {
      return MockData.vehicles;
    }

    if (!force && _inFlightSync != null) {
      return _inFlightSync;
    }

    final currentSeq = ++_syncSequence;
    final future = _performVehicleSync(currentSeq, auth);
    _inFlightSync = future;

    try {
      return await future;
    } finally {
      if (_inFlightSync == future) {
        _inFlightSync = null;
      }
    }
  }

  Future<List<Vehicle>?> _performVehicleSync(int sequence, AuthService auth) async {
    try {
      final fetched = await getVehicles();

      // Drop stale response if session or sequence changed during network call
      if (sequence != _syncSequence || !auth.isAuthenticated) {
        return null;
      }

      if (fetched.isNotEmpty) {
        // Respect existing active-vehicle selection and fallback rules:
        // 1. If any fetched vehicle is marked primary/active, keep it.
        // 2. If none marked primary, check if current active vehicle exists in fetched list.
        // 3. Fallback to the first vehicle.
        final hasPrimary = fetched.any((v) => v.isPrimary);
        List<Vehicle> resolved = List.from(fetched);
        if (!hasPrimary) {
          final currentActiveId = MockData.activeVehicle.id;
          final matchIdx = resolved.indexWhere((v) => v.id == currentActiveId);
          if (matchIdx != -1) {
            resolved[matchIdx] = resolved[matchIdx].copyWith(isPrimary: true);
          } else {
            resolved[0] = resolved[0].copyWith(isPrimary: true);
          }
        }
        MockData.vehicles = List.from(resolved);
        MockData.vehiclesNotifier.value = List.from(resolved);
        _hasSyncedForCurrentSession = true;
        return resolved;
      } else {
        // Authenticated user has no vehicles registered on server
        MockData.vehicles = [];
        MockData.vehiclesNotifier.value = [];
        _hasSyncedForCurrentSession = true;
        return [];
      }
    } catch (_) {
      // Offline / network failure resilience:
      // Do not crash or block. Preserve existing state.
      return null;
    }
  }

  /// Cancels in-flight synchronization, resets session sync flag, and restores guest vehicles.
  void resetVehicles() {
    _syncSequence++;
    _inFlightSync = null;
    _hasSyncedForCurrentSession = false;
    MockData.resetAllToGuest();
  }

  /// Explicitly marks that the vehicle list has been updated (e.g. from GarageScreen).
  void markSynced() {
    _hasSyncedForCurrentSession = true;
  }

  /// Fetches the authenticated user's vehicles from `GET /api/v1/vehicles`.
  Future<List<Vehicle>> getVehicles() async {
    final response = await apiClient.get(ApiConfig.vehiclesPath);
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
        .map((json) => Vehicle.fromJson(json))
        .toList();
  }

  /// Fetches a single vehicle by ID from `GET /api/v1/vehicles/:id`.
  Future<Vehicle> getVehicleById(String id) async {
    final response = await apiClient.get('${ApiConfig.vehiclesPath}/$id');
    final data = response.data;
    if (data is! Map<String, dynamic>) {
      throw ApiResponseFormatException(
        'Malformed vehicle payload received from server.',
        rawBody: response.rawBody?.toString() ?? '',
      );
    }
    return Vehicle.fromJson(data);
  }

  /// Creates a new vehicle for the authenticated user via `POST /api/v1/vehicles`.
  /// Ownership is derived strictly from the JWT Bearer token on the server.
  Future<Vehicle> createVehicle(Vehicle vehicle) async {
    final response = await apiClient.post(
      ApiConfig.vehiclesPath,
      body: vehicle.toBackendJson(),
    );
    final data = response.data;
    if (data is! Map<String, dynamic>) {
      throw ApiResponseFormatException(
        'Malformed response on vehicle creation.',
        rawBody: response.rawBody?.toString() ?? '',
      );
    }
    return Vehicle.fromJson(data);
  }

  /// Updates an existing vehicle via `PATCH /api/v1/vehicles/:id`.
  Future<Vehicle> updateVehicle(Vehicle vehicle) async {
    final response = await apiClient.patch(
      '${ApiConfig.vehiclesPath}/${vehicle.id}',
      body: vehicle.toBackendJson(),
    );
    final data = response.data;
    if (data is! Map<String, dynamic>) {
      throw ApiResponseFormatException(
        'Malformed response on vehicle update.',
        rawBody: response.rawBody?.toString() ?? '',
      );
    }
    return Vehicle.fromJson(data);
  }

  /// Sets a vehicle as the active vehicle via `PATCH /api/v1/vehicles/:id/active`.
  Future<Vehicle> setActiveVehicle(String id) async {
    final response = await apiClient.patch(
      '${ApiConfig.vehiclesPath}/$id/active',
    );
    final data = response.data;
    if (data is! Map<String, dynamic>) {
      throw ApiResponseFormatException(
        'Malformed response on active vehicle update.',
        rawBody: response.rawBody?.toString() ?? '',
      );
    }
    return Vehicle.fromJson(data);
  }

  /// Deletes a vehicle from the user's garage via `DELETE /api/v1/vehicles/:id`.
  Future<void> deleteVehicle(String id) async {
    await apiClient.delete('${ApiConfig.vehiclesPath}/$id');
  }

  /// Maps typed [ApiException] to user-friendly messages without exposing raw internals.
  static String getErrorMessage(Object error) {
    if (error is HttpStatusException) {
      if (error.statusCode == 409) {
        if (error.errorCode == 'VEHICLE_ALREADY_EXISTS' ||
            error.message.toLowerCase().contains('already exists')) {
          return 'A vehicle with this registration number already exists in your garage.';
        }
        if (error.errorCode == 'VEHICLE_HAS_ACTIVE_BOOKINGS' ||
            error.message.toLowerCase().contains('active booking')) {
          return 'Cannot remove vehicle while an active service booking is in progress.';
        }
        return error.message.isNotEmpty ? error.message : 'A conflict occurred with this vehicle.';
      }
      if (error.statusCode == 400) {
        return error.message.isNotEmpty ? error.message : 'Please check your vehicle details and try again.';
      }
      if (error.statusCode == 401) {
        return 'Please sign in to manage your vehicles.';
      }
      if (error.statusCode == 403) {
        return 'You do not have permission to modify this vehicle.';
      }
      if (error.statusCode == 404) {
        return 'Vehicle not found or has already been removed.';
      }
      if (error.statusCode >= 500) {
        return 'Server error while updating garage. Please try again later.';
      }
      return error.message.isNotEmpty ? error.message : 'Request failed (${error.statusCode}).';
    }

    if (error is NetworkException) {
      return 'Unable to reach MyMechanic servers. Please check your internet connection.';
    }

    if (error is ApiTimeoutException) {
      return 'Request timed out. Please check your connection and try again.';
    }

    if (error is AuthSessionException) {
      return 'Your session has expired. Please log in again.';
    }

    return 'An unexpected error occurred. Please try again.';
  }
}
