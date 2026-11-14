# MyMechanic — Vehicle Management API Integration Guide

Phase 3, Step 4.6 connects the MyMechanic Flutter vehicle management UI directly to the authenticated Node.js / Express / MongoDB Vehicle REST APIs.

---

## 1. Architecture Overview

The Vehicle integration builds on the verified Phase 3 authentication infrastructure:

```
[GarageScreen / VehicleFormSheet]
             │
             ▼
      [VehicleService]
             │ (injects AuthService.instance.apiClient)
             ▼
        [ApiClient]
             │ (attaches Bearer access token)
             │ (handles refresh rotation via AuthSessionCoordinator on 401)
             ▼
   [Express Vehicle Routes]
             │ (authenticates Bearer token -> req.user.id)
             ▼
    [Vehicle Controller]
             │
             ▼
    [MongoDB / Mongoose]
```

### Key Principles
1. **Zero Token Duplication**: `VehicleService` delegates all networking to `ApiClient`. It never reads, writes, or inspects raw JWTs.
2. **Server-Enforced Ownership**: The mobile client never passes arbitrary `userId` parameters. Ownership is derived exclusively on the backend from the validated JWT Bearer token payload (`req.user.id`).
3. **Session Resiliency**: Vehicle API failures (network drops, 400, 404, 409, 500) never inadvertently wipe or log out the customer's session.
4. **Guest Mode Compatibility**: Guest browsing remains fully functional with local in-memory fallback, preserving 100% of existing guest flows and Phase 2 test assertions.

---

## 2. Backend Endpoints Used

All vehicle routes are prefixed with `/api/v1/vehicles` and protected by the `authenticate` JWT middleware:

| HTTP Method | Route | Description | Backend Controller Method |
| :--- | :--- | :--- | :--- |
| `GET` | `/api/v1/vehicles` | Fetch all vehicles owned by current user | `VehicleController.getVehicles` |
| `GET` | `/api/v1/vehicles/:id` | Fetch single vehicle by ID | `VehicleController.getVehicleById` |
| `POST` | `/api/v1/vehicles` | Add a new vehicle to user's garage | `VehicleController.createVehicle` |
| `PATCH` | `/api/v1/vehicles/:id` | Update vehicle details | `VehicleController.updateVehicle` |
| `PATCH` | `/api/v1/vehicles/:id/active` | Set vehicle as active/primary | `VehicleController.setActiveVehicle` |
| `DELETE` | `/api/v1/vehicles/:id` | Remove vehicle from garage | `VehicleController.deleteVehicle` |

---

## 3. Data Mapping & Schema Alignment

### Flutter Domain Model to Backend Schema
The Flutter [`Vehicle`](file:///c:/Users/hp/Desktop/mymechanic/lib/models/vehicle.dart) model maps bidirectionally to the Mongoose `Vehicle` schema:

| Flutter Field | Backend Schema Field | Type | Description |
| :--- | :--- | :--- | :--- |
| `id` | `_id` | `String` (ObjectId) | Unique vehicle identifier |
| `userId` | `userId` | `String` (ObjectId) | Owner customer ID (server-derived) |
| `brand` | `make` | `String` | Manufacturer (e.g. "Hyundai", "Maruti Suzuki") |
| `model` | `model` | `String` | Car model name (e.g. "Creta", "Swift") |
| `variant` | `variant` | `String` | Trim / variant (e.g. "SX (O)") |
| `registrationNumber` | `registrationNumber` | `String` | Normalized uppercase Indian license plate |
| `fuelType` | `fuelType` | `String` | "Petrol" \| "Diesel" \| "Electric" \| "CNG" \| "Hybrid" |
| `year` | `year` | `int` | Manufacturing year |
| `isPrimary` | `isActive` | `bool` | Whether vehicle is currently active |

### Backend Envelope Unpacking
The backend returns responses inside standard success/pagination envelopes:
```json
{
  "success": true,
  "message": "Vehicles retrieved successfully",
  "data": {
    "items": [
      {
        "_id": "67b8...",
        "userId": "67b7...",
        "make": "Hyundai",
        "model": "Creta",
        "variant": "SX (O)",
        "registrationNumber": "KA01MJ5050",
        "fuelType": "Petrol",
        "year": 2022,
        "isActive": true
      }
    ],
    "pagination": {
      "page": 1,
      "limit": 10,
      "total": 1,
      "totalPages": 1
    }
  }
}
```

[`VehicleService.getVehicles()`](file:///c:/Users/hp/Desktop/mymechanic/lib/services/vehicle_service.dart) extracts items defensively:
```dart
List<dynamic> items = [];
if (data is Map<String, dynamic> && data['items'] is List) {
  items = data['items'] as List<dynamic>;
} else if (data is List) {
  items = data;
} else if (data is Map<String, dynamic> && data['data'] is List) {
  items = data['data'] as List<dynamic>;
}
```

---

## 4. Error Handling & User-Friendly Messages

Errors are mapped through typed exceptions in [`VehicleService.getErrorMessage()`](file:///c:/Users/hp/Desktop/mymechanic/lib/services/vehicle_service.dart):

| HTTP / Error Condition | Backend Code / Exception | Displayed Message |
| :--- | :--- | :--- |
| `409 Conflict` | `VEHICLE_ALREADY_EXISTS` | *"A vehicle with this registration number already exists in your garage."* |
| `409 Conflict` | `VEHICLE_HAS_ACTIVE_BOOKINGS` | *"Cannot remove vehicle while an active service booking is in progress."* |
| `400 Bad Request` | `VALIDATION_ERROR` | Validation error message from backend |
| `401 Unauthorized` | `AUTHENTICATION_REQUIRED` | *"Please sign in to manage your vehicles."* |
| `403 Forbidden` | `FORBIDDEN` | *"You do not have permission to modify this vehicle."* |
| `404 Not Found` | `NOT_FOUND` | *"Vehicle not found or has already been removed."* |
| `5xx Server Error` | `INTERNAL_SERVER_ERROR` | *"Server error while updating garage. Please try again later."* |
| Connection Drop | `NetworkException` | *"Unable to reach MyMechanic servers. Please check your internet connection."* |
| Timeout | `ApiTimeoutException` | *"Request timed out. Please check your connection and try again."* |

---

## 5. UI Integration & State Handling

### GarageScreen ([lib/screens/garage/garage_screen.dart](file:///c:/Users/hp/Desktop/mymechanic/lib/screens/garage/garage_screen.dart))
1. **Authenticated Users**:
   - Fetches real vehicles on screen load via `VehicleService.getVehicles()`.
   - Shows loading indicator while in-flight.
   - Shows clean empty state ("Add Your First Car") if the garage is empty.
   - Shows error state with a "Try Again" retry button on transient API failures.
   - Add, Edit, Delete, and Set Active operations execute against backend endpoints and update local UI state immediately on success.
   - Syncs changes with `MockData.vehiclesNotifier` so global listeners (Home screen, Booking flow) reflect the active vehicle.
2. **Guest Users**:
   - Continues using local in-memory vehicles from `MockData.vehiclesNotifier`.
   - Does not block guest viewing or browsing.

### VehicleFormSheet ([lib/widgets/vehicle/vehicle_form_sheet.dart](file:///c:/Users/hp/Desktop/mymechanic/lib/widgets/vehicle/vehicle_form_sheet.dart))
- Supports asynchronous submission via `onSaveAsync`.
- Prevents duplicate submissions while an API request is in-flight using `_isSubmitting`.
- Displays inline error banners for business-rule conflicts (e.g. duplicate license plates).

---

## 6. Verification & Automated Tests

All tests are verified via automated suites:
- **`test/services/vehicle_service_test.dart`** (18 tests):
  - Unit tests covering all CRUD endpoints, payloads, headers, Bearer tokens, pagination, and error mappings.
- **`test/screens/garage_screen_test.dart`** (8 tests):
  - Widget tests covering authenticated loading, empty state, API error retry, vehicle deletion confirmation, active vehicle toggle, guest mode isolation, and duplicate submission prevention.
- **`test/widget_test.dart`** (33 tests):
  - Existing app-wide flows, guest vehicle manipulation, and end-to-end integration.

**Results**:
- `flutter analyze`: **0 issues found**
- `flutter test`: **139 / 139 tests passing**
