import '../core/config/api_config.dart';
import '../core/network/api_client.dart';
import '../models/booking.dart';
import 'auth_service.dart';

/// Service managing booking CRUD and lifecycle operations with the authenticated MyMechanic backend.
///
/// Phase 3 Step 4.8: Booking API Integration.
///
/// Architecture & Security:
/// - Reuses authenticated [ApiClient] (Bearer token injected and refreshed automatically).
/// - Never allows arbitrary client userId; ownership is derived server-side from JWT.
/// - Connects to `/api/v1/bookings` routes.
/// - Strongly typed models and defensive parsing for resilient error handling.
/// - Surfaces typed [ApiException] hierarchy and friendly user messages.
class BookingService {
  final ApiClient apiClient;

  BookingService({required this.apiClient});

  static BookingService? _instance;

  /// Global access point for the application.
  static BookingService get instance =>
      _instance ??= BookingService(apiClient: AuthService.instance.apiClient);

  /// Inject custom service instance for unit and widget tests.
  static set instance(BookingService service) => _instance = service;

  /// Resets the singleton instance (useful for test isolation).
  static void resetInstance() {
    _instance = null;
  }

  /// Fetches bookings for the authenticated customer from `GET /api/v1/bookings`.
  Future<List<Booking>> getBookings({
    String? vehicleId,
    String? status,
    int page = 1,
    int limit = 50,
  }) async {
    final queryParams = <String, dynamic>{
      'page': page,
      'limit': limit,
    };

    if (vehicleId != null && vehicleId.isNotEmpty) {
      queryParams['vehicleId'] = vehicleId;
    }

    if (status != null && status.isNotEmpty) {
      queryParams['status'] = status;
    }

    final response = await apiClient.get(
      ApiConfig.bookingsPath,
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
        .map((json) => Booking.fromJson(json))
        .toList();
  }

  /// Fetches a single booking by ID from `GET /api/v1/bookings/:id`.
  Future<Booking> getBookingById(String id) async {
    final response = await apiClient.get('${ApiConfig.bookingsPath}/$id');
    final data = response.data;

    if (data is! Map<String, dynamic>) {
      throw ApiResponseFormatException(
        'Malformed booking payload received from server.',
        rawBody: response.rawBody?.toString() ?? '',
      );
    }

    final payload = (data['data'] is Map<String, dynamic>)
        ? data['data'] as Map<String, dynamic>
        : data;

    return Booking.fromJson(payload);
  }

  /// Creates a new service booking via `POST /api/v1/bookings`.
  /// Ownership is derived strictly from the JWT Bearer token on the server.
  Future<Booking> createBooking({
    required String vehicleId,
    required String serviceId,
    required DateTime scheduledDate,
    required String scheduledTime,
    String serviceMode = 'doorstep',
    String? address,
    String? couponCode,
    required double subtotal,
    double discount = 0.0,
    double pickupFee = 0.0,
    double gst = 0.0,
    required double totalAmount,
    String? notes,
    String paymentMethod = 'pay_on_delivery',
    String paymentStatus = 'pending',
    String? paymentReference,
    String? workshopId,
    String? workshopName,
    String? assignedMechanic,
  }) async {
    final body = <String, dynamic>{
      'vehicleId': vehicleId,
      'serviceId': serviceId,
      'scheduledDate': scheduledDate.toUtc().toIso8601String(),
      'scheduledTime': scheduledTime,
      'serviceMode': serviceMode,
      if (address != null && address.trim().isNotEmpty) 'address': address.trim(),
      if (couponCode != null && couponCode.trim().isNotEmpty)
        'couponCode': couponCode.trim().toUpperCase(),
      'subtotal': subtotal,
      'discount': discount,
      'pickupFee': pickupFee,
      'gst': gst,
      'totalAmount': totalAmount,
      if (notes != null && notes.trim().isNotEmpty) 'notes': notes.trim(),
      'paymentMethod': paymentMethod,
      'paymentStatus': paymentStatus,
      if (paymentReference != null && paymentReference.trim().isNotEmpty)
        'paymentReference': paymentReference.trim(),
      if (workshopId != null && workshopId.trim().isNotEmpty)
        'workshopId': workshopId.trim(),
      if (workshopName != null && workshopName.trim().isNotEmpty)
        'workshopName': workshopName.trim(),
      if (assignedMechanic != null && assignedMechanic.trim().isNotEmpty)
        'assignedMechanic': assignedMechanic.trim(),
    };

    final response = await apiClient.post(
      ApiConfig.bookingsPath,
      body: body,
    );

    final data = response.data;
    if (data is! Map<String, dynamic>) {
      throw ApiResponseFormatException(
        'Malformed response on booking creation.',
        rawBody: response.rawBody?.toString() ?? '',
      );
    }

    final payload = (data['data'] is Map<String, dynamic>)
        ? data['data'] as Map<String, dynamic>
        : data;

    return Booking.fromJson(payload);
  }

  /// Reschedules an existing booking via `PATCH /api/v1/bookings/:id`.
  Future<Booking> rescheduleBooking(
    String id, {
    required DateTime scheduledDate,
    required String scheduledTime,
    String? address,
    String? notes,
  }) async {
    final body = <String, dynamic>{
      'scheduledDate': scheduledDate.toUtc().toIso8601String(),
      'scheduledTime': scheduledTime,
      if (address != null && address.trim().isNotEmpty) 'address': address.trim(),
      if (notes != null && notes.trim().isNotEmpty) 'notes': notes.trim(),
    };

    final response = await apiClient.patch(
      '${ApiConfig.bookingsPath}/$id',
      body: body,
    );

    final data = response.data;
    if (data is! Map<String, dynamic>) {
      throw ApiResponseFormatException(
        'Malformed response on booking reschedule.',
        rawBody: response.rawBody?.toString() ?? '',
      );
    }

    final payload = (data['data'] is Map<String, dynamic>)
        ? data['data'] as Map<String, dynamic>
        : data;

    return Booking.fromJson(payload);
  }

  /// Cancels an existing booking via `PATCH /api/v1/bookings/:id/status`.
  Future<Booking> cancelBooking(String id) async {
    final response = await apiClient.patch(
      '${ApiConfig.bookingsPath}/$id/status',
      body: {'status': 'cancelled'},
    );

    final data = response.data;
    if (data is! Map<String, dynamic>) {
      throw ApiResponseFormatException(
        'Malformed response on booking cancellation.',
        rawBody: response.rawBody?.toString() ?? '',
      );
    }

    final payload = (data['data'] is Map<String, dynamic>)
        ? data['data'] as Map<String, dynamic>
        : data;

    return Booking.fromJson(payload);
  }

  /// Updates booking status via `PATCH /api/v1/bookings/:id/status`.
  Future<Booking> updateBookingStatus(String id, String status) async {
    final response = await apiClient.patch(
      '${ApiConfig.bookingsPath}/$id/status',
      body: {'status': status},
    );

    final data = response.data;
    if (data is! Map<String, dynamic>) {
      throw ApiResponseFormatException(
        'Malformed response on booking status update.',
        rawBody: response.rawBody?.toString() ?? '',
      );
    }

    final payload = (data['data'] is Map<String, dynamic>)
        ? data['data'] as Map<String, dynamic>
        : data;

    return Booking.fromJson(payload);
  }

  /// Submits rating and feedback for a completed booking via `POST /api/v1/bookings/:id/rating`.
  Future<Booking> submitRating({
    required String bookingId,
    required int rating,
    List<String> ratingCategories = const [],
    String? ratingFeedback,
  }) async {
    final response = await apiClient.post(
      '${ApiConfig.bookingsPath}/$bookingId/rating',
      body: {
        'rating': rating,
        'ratingCategories': ratingCategories,
        if (ratingFeedback != null && ratingFeedback.trim().isNotEmpty)
          'ratingFeedback': ratingFeedback.trim(),
      },
    );

    final data = response.data;
    if (data is! Map<String, dynamic>) {
      throw ApiResponseFormatException(
        'Malformed response on rating submission.',
        rawBody: response.rawBody?.toString() ?? '',
      );
    }

    final payload = (data['data'] is Map<String, dynamic>)
        ? data['data'] as Map<String, dynamic>
        : data;

    return Booking.fromJson(payload);
  }

  /// Updates booking payment status via `POST /api/v1/bookings/:id/payment` (e.g. simulated payment).
  Future<Booking> updatePayment({
    required String bookingId,
    required String paymentStatus,
    String? paymentMethod,
    String? paymentReference,
  }) async {
    final body = <String, dynamic>{
      'paymentStatus': paymentStatus,
    };
    if (paymentMethod != null) {
      body['paymentMethod'] = paymentMethod;
    }
    if (paymentReference != null) {
      body['paymentReference'] = paymentReference;
    }

    final response = await apiClient.post(
      '${ApiConfig.bookingsPath}/$bookingId/payment',
      body: body,
    );

    final data = response.data;
    if (data is! Map<String, dynamic>) {
      throw ApiResponseFormatException(
        'Malformed response on booking payment update.',
        rawBody: response.rawBody?.toString() ?? '',
      );
    }

    final payload = (data['data'] is Map<String, dynamic>)
        ? data['data'] as Map<String, dynamic>
        : data;

    return Booking.fromJson(payload);
  }

  /// Deletes a booking via `DELETE /api/v1/bookings/:id`.
  Future<void> deleteBooking(String id) async {
    await apiClient.delete('${ApiConfig.bookingsPath}/$id');
  }

  /// Maps typed [ApiException] to user-friendly messages.
  static String getErrorMessage(Object error) {
    if (error is HttpStatusException) {
      if (error.statusCode == 400) {
        if (error.errorCode == 'ALREADY_RATED') {
          return 'This service has already been rated.';
        }
        if (error.errorCode == 'BOOKING_NOT_COMPLETED') {
          return 'Only completed services can be rated.';
        }
        if (error.errorCode == 'VEHICLE_OWNERSHIP_MISMATCH' ||
            error.message.contains('Vehicle does not belong')) {
          return 'The selected vehicle does not belong to your account.';
        }
        if (error.errorCode == 'DUPLICATE_BOOKING_NUMBER') {
          return 'A booking with this reference number already exists. Please try again.';
        }
        if (error.errorCode == 'INVALID_STATUS_TRANSITION' ||
            error.message.contains('terminal')) {
          return 'This booking cannot be updated or cancelled in its current status.';
        }
        if (error.errorCode == 'BOOKING_NOT_MODIFIABLE' ||
            error.message.contains('Cannot update booking details')) {
          return 'Completed or cancelled bookings cannot be modified.';
        }
        if (error.errorCode == 'CANNOT_DELETE_ACTIVE_BOOKING') {
          return 'Cannot delete an active booking. Please cancel it first.';
        }
        return error.message.isNotEmpty
            ? error.message
            : 'Invalid booking parameters. Please check details and try again.';
      }
      if (error.statusCode == 401) {
        return 'Please sign in to manage or view your bookings.';
      }
      if (error.statusCode == 403) {
        return 'You do not have permission to access or modify this booking.';
      }
      if (error.statusCode == 404) {
        return 'The requested booking could not be found.';
      }
      if (error.statusCode >= 500) {
        return 'Server error while processing your booking. Please try again later.';
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

    return 'An unexpected error occurred while processing your booking.';
  }
}
