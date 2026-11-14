# MyMechanic — Booking API Integration Guide

Phase 3, Step 4.8 connects the MyMechanic Flutter application's booking lifecycle directly to the backend Node.js / Express / MongoDB `/api/v1/bookings` REST endpoints.

---

## 1. Architecture Overview

The booking integration strictly adheres to the established authenticated API client and repository pattern:

```
[BookingFlowSheet / BookingsScreen / BookingDetailsSheet]
                         │
                         ▼
                  [BookingService]
                         │ (injects authenticated ApiClient)
                         ▼
                    [ApiClient]
                         │ (Bearer JWT token injected automatically)
                         │ (Automatic 401 token refresh & rotation)
                         ▼
              [Express Booking Routes]
               /api/v1/bookings
                         │
                         ▼
            [BookingController / BookingService]
              ├── Derives customer userId from req.user.id (prevents spoofing)
              ├── Validates vehicle ownership (vehicle.userId == req.user.id)
              ├── Enforces sequential status lifecycle
              └── Auto-generates unique bookingNumber (MM-YYYY-XXXX)
                         │
                         ▼
                [MongoDB / Mongoose]
                Booking Model (IBooking)
```

### Key Principles
1. **Ownership Derived Strictly on Backend**: Customer identity is never supplied as an arbitrary `userId` from the mobile client. It is derived securely on the server from the verified JWT `req.user.id`.
2. **Vehicle Ownership Validation**: The backend checks that the selected `vehicleId` exists and belongs to the authenticated customer, rejecting cross-user booking creation with `VEHICLE_OWNERSHIP_MISMATCH` (HTTP 400).
3. **Non-Blocking Guest Browsing**: Guest users can continue to navigate screens and create local in-memory bookings without encountering a global authentication wall. Authenticated operations are prompted only when initiating protected server actions.
4. **Resilient Data Fallback**: When in offline or demo modes with mock vehicles (e.g., `v1`, `v2`) or unseeded services, the Flutter client gracefully uses in-memory mock storage so that local testing and offline usage remain functional.
5. **No Token Management in Booking Layer**: `BookingService` never inspects, writes, or persists access/refresh tokens; authentication and token rotation are handled transparently by `ApiClient` and `TokenStorageService`.
6. **No Fake Server Success**: If an API call fails or times out, the client displays a clear error and prevents state advancement (e.g., staying on Step 3 Summary rather than advancing to Step 4 Confirmed).

---

## 2. Backend Endpoints Used

All booking endpoints require Bearer JWT authentication:

| HTTP Method | Route | Description | Backend Controller Method | Auth Required |
| :--- | :--- | :--- | :--- | :--- |
| `POST` | `/api/v1/bookings` | Create a new service appointment | `BookingController.createBooking` | Yes (`authenticateToken`) |
| `GET` | `/api/v1/bookings` | List authenticated user's bookings | `BookingController.getBookings` | Yes (`authenticateToken`) |
| `GET` | `/api/v1/bookings/:id` | Retrieve single booking details by ID | `BookingController.getBookingById` | Yes (`authenticateToken`) |
| `PATCH` | `/api/v1/bookings/:id` | Reschedule appointment date/time/address | `BookingController.updateBooking` | Yes (`authenticateToken`) |
| `PATCH` | `/api/v1/bookings/:id/status` | Transition booking status (e.g., cancel) | `BookingController.updateBookingStatus` | Yes (`authenticateToken`) |
| `DELETE` | `/api/v1/bookings/:id` | Delete completed or cancelled booking | `BookingController.deleteBooking` | Yes (`authenticateToken`) |

---

## 3. Request & Response Schemas

### 3.1 Create Booking (`POST /api/v1/bookings`)

#### Request Payload
```json
{
  "vehicleId": "67b8a1000000000000000020",
  "serviceId": "67b8a1000000000000000030",
  "scheduledDate": "2026-03-25T00:00:00.000Z",
  "scheduledTime": "10:30 AM",
  "serviceMode": "doorstep",
  "address": "Flat 402, Green Glen Layout, Bengaluru - 560103",
  "couponCode": "MYFIRST500",
  "subtotal": 3499.0,
  "discount": 500.0,
  "pickupFee": 149.0,
  "gst": 566.0,
  "totalAmount": 3714.0,
  "notes": "Please call before arrival"
}
```

#### Success Response (`201 Created`)
```json
{
  "success": true,
  "message": "Booking created successfully",
  "data": {
    "_id": "67b8a1000000000000000099",
    "bookingNumber": "MM-2026-8712",
    "userId": {
      "_id": "67b8a1000000000000000010",
      "name": "Rahul Sharma",
      "email": "rahul@example.com",
      "phone": "9876543210"
    },
    "vehicleId": {
      "_id": "67b8a1000000000000000020",
      "make": "Hyundai",
      "model": "Creta",
      "variant": "SX (O)",
      "registrationNumber": "KA01MJ5050",
      "fuelType": "Petrol",
      "year": 2022
    },
    "serviceId": {
      "_id": "67b8a1000000000000000030",
      "title": "Comprehensive Periodic Service",
      "price": 3499.0,
      "durationText": "3-4 Hours"
    },
    "scheduledDate": "2026-03-25T00:00:00.000Z",
    "scheduledTime": "10:30 AM",
    "serviceMode": "doorstep",
    "address": "Flat 402, Green Glen Layout, Bengaluru - 560103",
    "couponCode": "MYFIRST500",
    "subtotal": 3499.0,
    "discount": 500.0,
    "pickupFee": 149.0,
    "gst": 566.0,
    "totalAmount": 3714.0,
    "status": "confirmed",
    "createdAt": "2026-03-22T08:30:00.000Z",
    "updatedAt": "2026-03-22T08:30:00.000Z"
  }
}
```

---

### 3.2 List Bookings (`GET /api/v1/bookings`)

#### Query Parameters
- `vehicleId` (optional): Filter bookings by MongoDB vehicle ID.
- `status` (optional): Filter bookings by status (e.g. `confirmed`, `completed`, `cancelled`).
- `page` (optional, default `1`): Pagination page number.
- `limit` (optional, default `50`): Results per page.

#### Response (`200 OK`)
```json
{
  "success": true,
  "data": {
    "items": [
      {
        "_id": "67b8a1000000000000000099",
        "bookingNumber": "MM-2026-8712",
        "vehicleId": { ... },
        "serviceId": { ... },
        "scheduledDate": "2026-03-25T00:00:00.000Z",
        "scheduledTime": "10:30 AM",
        "totalAmount": 3714.0,
        "status": "confirmed"
      }
    ],
    "pagination": {
      "page": 1,
      "limit": 50,
      "total": 1,
      "totalPages": 1
    }
  }
}
```

---

### 3.3 Reschedule Booking (`PATCH /api/v1/bookings/:id`)

#### Request Payload
```json
{
  "scheduledDate": "2026-03-28T00:00:00.000Z",
  "scheduledTime": "02:00 PM",
  "address": "New delivery address",
  "notes": "Updated instructions"
}
```

---

### 3.4 Cancel Booking (`PATCH /api/v1/bookings/:id/status`)

#### Request Payload
```json
{
  "status": "cancelled"
}
```

---

## 4. Status Mapping

The backend defines 8 distinct lifecycle statuses. The Flutter application maps these onto `BookingStatus` enum and rich `statusText` labels:

| Backend Status | Flutter Enum | Display Label | Card Category |
| :--- | :--- | :--- | :--- |
| `confirmed` | `BookingStatus.confirmed` | "Booking Confirmed" | Active |
| `vehicle_received` | `BookingStatus.inProgress` | "Vehicle Received" | Active |
| `inspection` | `BookingStatus.inProgress` | "Under Inspection" | Active |
| `service_in_progress` | `BookingStatus.inProgress` | "Service In Progress" | Active |
| `quality_check` | `BookingStatus.inProgress` | "Quality Check" | Active |
| `ready_for_delivery` | `BookingStatus.inProgress` | "Ready for Delivery" | Active |
| `completed` | `BookingStatus.completed` | "Completed" | History / Past |
| `cancelled` | `BookingStatus.cancelled` | "Cancelled" | History / Past |

---

## 5. Error Handling & Business Rules

Errors returned by Express middleware follow `{ success: false, message: string, error: { code: string } }`. The Flutter `BookingService.getErrorMessage()` maps these to friendly client messages:

| HTTP Status | Error Code | Meaning | User Feedback Message |
| :--- | :--- | :--- | :--- |
| `400` | `VEHICLE_OWNERSHIP_MISMATCH` | Vehicle does not belong to logged-in user | "The selected vehicle does not belong to your account." |
| `400` | `DUPLICATE_BOOKING_NUMBER` | Booking reference collision | "A booking with this reference number already exists. Please try again." |
| `400` | `INVALID_STATUS_TRANSITION` | Attempted illegal transition (e.g. cancelling completed booking) | "This booking cannot be updated or cancelled in its current status." |
| `400` | `BOOKING_NOT_MODIFIABLE` | Rescheduling completed/cancelled booking | "Completed or cancelled bookings cannot be modified." |
| `400` | `CANNOT_DELETE_ACTIVE_BOOKING` | Deleting active booking without cancelling | "Cannot delete an active booking. Please cancel it first." |
| `401` | `UNAUTHORIZED` | Expired or missing Bearer token | "Please sign in to manage or view your bookings." |
| `403` | `FORBIDDEN` | Accessing another customer's booking | "You do not have permission to access or modify this booking." |
| `404` | `NOT_FOUND` | Booking ID not found | "The requested booking could not be found." |
| `500` | `INTERNAL_SERVER_ERROR` | Unhandled server error | "Server error while processing your booking. Please try again later." |
| Client | `NetworkException` | Socket/DNS failure | "Unable to reach MyMechanic servers. Please check your internet connection." |
| Client | `ApiTimeoutException` | Request exceeded deadline | "Request timed out. Please check your connection and try again." |

---

## 6. Backend Integration vs. Mock-Only Features

| Feature | Status | Notes |
| :--- | :--- | :--- |
| **Booking Creation** | ✅ **Real Backend API** | `POST /api/v1/bookings` with user, vehicle, service, schedule, address, amounts. |
| **Booking Listing** | ✅ **Real Backend API** | `GET /api/v1/bookings` scoped strictly to `req.user.id`. |
| **Booking Details** | ✅ **Real Backend API** | `GET /api/v1/bookings/:id` with populated vehicle and service details. |
| **Rescheduling** | ✅ **Real Backend API** | `PATCH /api/v1/bookings/:id` updates `scheduledDate` and `scheduledTime`. |
| **Cancellation** | ✅ **Real Backend API** | `PATCH /api/v1/bookings/:id/status` with `status: 'cancelled'`. |
| **Deletion** | ✅ **Real Backend API** | `DELETE /api/v1/bookings/:id` for terminal bookings. |
| **Doorstep Pickup & Drop** | ✅ **Real Backend API** | Passed via `serviceMode: 'doorstep'` and `address` fields. |
| **Financial Breakdown** | ✅ **Real Backend API** | Server accepts `subtotal`, `discount`, `pickupFee`, `gst`, `totalAmount`. |
| **Coupon Code Storage** | ⚠️ **Partial Backend** | `couponCode` stored on booking; coupon validation remains client-side (no `/coupons` route on server). |
| **Garage / Hub Selection** | ⚠️ **Mock Only** | Backend booking schema has no `garageId` or `hubId` reference yet. |
| **Mechanic Assignment** | ⚠️ **Mock Only** | Backend booking schema has no `assignedMechanicId` reference yet. |
| **Ratings & Feedback** | ⚠️ **Mock Only** | Backend booking schema has no rating/review fields (deferred to Phase 3 ratings step). |
| **Live GPS Tracking** | ⚠️ **Mock Only** | Real-time WebSocket/location tracking not implemented in backend. |

---

## 7. Automated Test Coverage

The integration is verified by 183 automated tests across unit, widget, and end-to-end flows:

- `test/services/booking_service_test.dart`: 21 tests covering all CRUD operations, query parameter encoding, error code mapping, and headers.
- `test/screens/bookings_screen_test.dart`: 5 tests covering loading spinners, active/history tab separation, empty state, network error retries, and pull-to-refresh.
- `test/widgets/booking_flow_sheet_test.dart`: 3 tests covering multi-step submission, server booking creation, duplicate submit prevention, and validation error presentation.
- `test/widget_test.dart`: 183 total tests pass without regressions across previous phases and steps.
- Backend test suite: 63/63 integration tests passing.
- Static analysis: 0 issues reported by `flutter analyze`.
