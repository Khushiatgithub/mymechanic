# MyMechanic — Flutter API Client Guide

Phase 3, Step 4.1 establishes the production-grade HTTP API client foundation for the MyMechanic Flutter mobile app.

---

## 1. Important Current State Note

> [!NOTE]
> The MyMechanic Flutter application continues to use local in-memory mock data ([`MockData`](file:///c:/Users/hp/Desktop/mymechanic/lib/data/mock_data.dart)).
> Screens, state notifiers, and repositories have **not** yet been migrated to the backend. This step only establishes the reusable networking layer and configuration pipeline.

---

## 2. API Base URL Configuration

The API base URL is resolved through [`ApiConfig.resolveBaseUrl()`](file:///c:/Users/hp/Desktop/mymechanic/lib/core/config/api_config.dart):

1. **Explicit Build-Time Override**: `--dart-define=API_BASE_URL=...`
2. **Default Development Fallback**: `http://10.0.2.2:5000/api/v1` (Android Emulator default)

### Path & Prefix Normalization Rules
- The base URL is always normalized with the `/api/v1` prefix.
- If a developer supplies `http://192.168.1.10:5000`, the client automatically normalizes it to `http://192.168.1.10:5000/api/v1`.
- If a developer supplies `http://192.168.1.10:5000/api/v1/`, trailing slashes and prefix are deduplicated safely to avoid `/api/v1/api/v1`.
- **Strict Validation**: If an invalid URL (e.g. `ftp://...` or `not-a-url`) is explicitly provided, the client throws [`ApiConfigurationException`](file:///c:/Users/hp/Desktop/mymechanic/lib/core/network/api_exception.dart). **It never silently falls back to localhost.**

---

## 3. Running with `--dart-define`

### A. Android Emulator
The Android emulator runs inside a virtual router where `10.0.2.2` aliases the development machine's `127.0.0.1` loopback:

```bash
# Default (no define needed for emulator):
flutter run

# Or explicitly:
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:5000
```

### B. Physical Android Device (e.g. Samsung Galaxy A17 5G)
> [!IMPORTANT]
> `10.0.2.2` and `127.0.0.1` do **NOT** work on a physical phone. A physical device is a separate hardware host on your local network.

To connect a physical phone over local Wi-Fi:
1. Find your development computer's local LAN IPv4 address (e.g. via `ipconfig` on Windows, typically `192.168.1.X`).
2. Ensure both the computer and Samsung phone are connected to the same Wi-Fi network.
3. Ensure the backend server listens on `0.0.0.0` or your LAN interface on port `5000`.
4. Ensure Windows Firewall permits incoming TCP connections on port `5000` from the private network (do not disable the firewall or expose the port to public networks).
5. Run the Flutter app with your LAN address:

```bash
flutter run -d <samsung_device_id> --dart-define=API_BASE_URL=http://192.168.1.50:5000
```

---

## 4. API Client Capabilities

The [`ApiClient`](file:///c:/Users/hp/Desktop/mymechanic/lib/core/network/api_client.dart) class supports:

- **Methods**: `get()`, `post()`, `patch()`, `delete()`
- **Path Resolution**: Accepts relative paths (e.g. `/health`, `services`, `/bookings`) and builds URLs without prefix collision.
- **Request Headers**:
  - `Accept: application/json` always sent.
  - `Content-Type: application/json` automatically attached when a request body is present.
  - Injectable `TokenProvider` callback attaches `Authorization: Bearer <token>` when available (without storing or hardcoding tokens).
- **Responses**:
  - Automatically parses standard backend envelope `{ success, message, data }` into typed [`ApiResponse<T>`](file:///c:/Users/hp/Desktop/mymechanic/lib/core/network/api_response.dart).
  - Handles `HTTP 204 No Content` and empty bodies safely.
- **Error Mapping**:
  - [`HttpStatusException`](file:///c:/Users/hp/Desktop/mymechanic/lib/core/network/api_exception.dart): 4xx and 5xx errors with `statusCode`, `errorCode`, and parsed server error details.
  - Non-JSON error responses (e.g. HTML 502/500 proxy pages) are handled gracefully without JSON parse crashes.
  - [`NetworkException`](file:///c:/Users/hp/Desktop/mymechanic/lib/core/network/api_exception.dart): Connection refused, DNS failure, host unreachable.
  - [`ApiTimeoutException`](file:///c:/Users/hp/Desktop/mymechanic/lib/core/network/api_exception.dart): Configurable per-client and per-request timeout thresholds.
  - [`ApiResponseFormatException`](file:///c:/Users/hp/Desktop/mymechanic/lib/core/network/api_exception.dart): Malformed JSON on 2xx responses.
  - [`ApiConfigurationException`](file:///c:/Users/hp/Desktop/mymechanic/lib/core/network/api_exception.dart): Invalid base URL or JSON encoding issues.
