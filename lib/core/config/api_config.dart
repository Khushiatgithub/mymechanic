import '../network/api_exception.dart';

/// API Configuration for MyMechanic Backend.
///
/// Phase 3 Step 4.1: Flutter API Client Foundation.
///
/// Supports build-time configuration via `--dart-define=API_BASE_URL=...`
/// with sensible Android emulator defaults, consistent `/api/v1` prefix
/// normalization, and strict validation that prevents silent fallback on invalid URLs.
///
/// NOTE: The Flutter application continues to use mock data for local in-memory
/// operations until Phase 3 backend migration steps connect specific features.
class ApiConfig {
  ApiConfig._();

  /// Default API port configured in backend `.env`
  static const int port = 5000;

  /// API route prefix
  static const String apiPrefix = '/api/v1';

  /// Build-time define override: `--dart-define=API_BASE_URL=http://...`
  static const String definedBaseUrl = String.fromEnvironment('API_BASE_URL');

  /// Base URL for Android Emulator (`10.0.2.2` maps to host `127.0.0.1`)
  ///
  /// IMPORTANT: `10.0.2.2` ONLY works inside the Android emulator!
  /// It does NOT work on physical Android phones (e.g., Samsung Galaxy A17 5G).
  static const String androidEmulatorBaseUrl =
      'http://10.0.2.2:$port$apiPrefix';

  /// Example base URL for physical Android device testing over local Wi-Fi LAN
  /// Replace with your computer's actual reachable local IP (e.g. `192.168.1.X`).
  ///
  /// Requires:
  /// 1. Backend listening on reachable interface (e.g. `0.0.0.0` or LAN IP).
  /// 2. Computer and phone connected to the same Wi-Fi network.
  /// 3. Windows Firewall permitting inbound TCP connections on port 5000.
  static const String physicalDeviceBaseUrl =
      'http://192.168.1.100:$port$apiPrefix';

  /// Base URL for web / desktop testing
  static const String localHostBaseUrl =
      'http://127.0.0.1:$port$apiPrefix';

  /// Health check endpoint path
  static const String healthEndpoint = '/health';

  /// Resource paths
  static const String usersPath = '/users';
  static const String vehiclesPath = '/vehicles';
  static const String servicesPath = '/services';
  static const String serviceCategoriesPath = '/service-categories';
  static const String bookingsPath = '/bookings';
  static const String offersPath = '/offers';
  static const String workshopsPath = '/workshops';
  static const String notificationsPath = '/notifications';
  static const String authPath = '/auth';

  /// Request timeout durations
  static const Duration connectTimeout = Duration(seconds: 10);
  static const Duration receiveTimeout = Duration(seconds: 15);
  static const Duration defaultTimeout = Duration(seconds: 15);

  /// Resolves and normalizes the effective API base URL.
  ///
  /// Precedence:
  /// 1. [customUrl] if provided and non-empty.
  /// 2. `--dart-define=API_BASE_URL` if passed at build-time.
  /// 3. Fallback to [androidEmulatorBaseUrl] for local development.
  ///
  /// Safety rules:
  /// - If an explicit URL is provided (either via [customUrl] or [definedBaseUrl])
  ///   and it is malformed, throws [ApiConfigurationException].
  ///   **Never silently falls back to localhost.**
  /// - Normalizes trailing slashes and ensures the [apiPrefix] (`/api/v1`)
  ///   is present without accidental duplication (e.g., `/api/v1/api/v1`).
  static String resolveBaseUrl([String? customUrl]) {
    final candidate = (customUrl != null && customUrl.trim().isNotEmpty)
        ? customUrl.trim()
        : (definedBaseUrl.trim().isNotEmpty ? definedBaseUrl.trim() : null);

    if (candidate == null) {
      return androidEmulatorBaseUrl;
    }

    final uri = Uri.tryParse(candidate);
    final isValid = uri != null &&
        (uri.scheme == 'http' || uri.scheme == 'https') &&
        uri.host.isNotEmpty;

    if (!isValid) {
      throw ApiConfigurationException(
        'Invalid API_BASE_URL: "$candidate". Expected a valid HTTP or HTTPS URL (e.g. "http://10.0.2.2:5000" or "http://192.168.1.50:5000").',
      );
    }

    // Strip trailing slashes
    var normalized = candidate.replaceAll(RegExp(r'/+$'), '');

    // Handle apiPrefix idempotently
    if (normalized.endsWith(apiPrefix)) {
      return normalized;
    }

    if (!normalized.contains(apiPrefix)) {
      normalized = '$normalized$apiPrefix';
    }

    return normalized;
  }

  /// The active base URL for the current build/run session.
  static String get baseUrl => resolveBaseUrl();
}
