# Customer Experience API Gap Audit & Supported Enhancements

**Phase**: Phase 3 — Step 4.9  
**Platform**: MyMechanic Flutter Mobile App & Node.js/Express Backend  
**Status**: Completed  
**Last Updated**: October 2026  

---

## Executive Summary

Phase 3 Step 4.9 conducts a rigorous, code-level capability audit comparing the MyMechanic Node.js/TypeScript backend against the Flutter mobile customer-experience features:
1. Coupons & Discount Validation
2. Garages / Hubs / Service Centers
3. Mechanic & Technician Assignment
4. Ratings, Reviews & Feedback
5. Live Tracking & Service Progress

Where the backend genuinely provides capabilities (e.g., granular 8-state booking progress tracking via `/api/v1/bookings/:id`), Flutter was connected and enhanced without breaking offline/mock workflows. Where backend support is absent or partial, existing mock/local client behaviors were intentionally preserved without inventing fake endpoints or polluting backend schemas.

---

## Summary Matrix

| Feature | Backend Support | Flutter Status | API Connected? | Remaining Gap |
| :--- | :--- | :--- | :--- | :--- |
| **Coupons** | **B. Partially supported** | Real coupon fields persisted in booking creation; client-side coupon code & discount rule validation; mock promo list | **Partially** (Stores `couponCode` & `discount` on server booking) | No coupon entity model, no server-side coupon validation API (`/coupons/validate`), and `/api/v1/offers` is an empty placeholder route. |
| **Garage / Hub** | **C. Not supported** | Client-side hub selection from `MockData.serviceCenters`; display-only workshop name in UI sheets | **No** (Workshop name is mapped in Flutter client) | No `Garage` or `Hub` model in backend; backend uses "garage" only as personal vehicle storage (`/api/v1/vehicles`); `Booking` model has no `garageId` or `hubId`. |
| **Mechanic Assignment** | **C. Not supported** | Client-side display of assigned technician and rating in `LiveTrackerSheet` and `BookingDetailsSheet` | **No** (Technician names are client-side UI fallbacks) | 0 references to mechanics or technicians in backend models, controllers, services, or routes; no mechanic role or dispatch engine. |
| **Ratings / Feedback** | **B. Partially supported** | In-memory rating submission sheet (`RatingSheet`); persistent across session in `MockData.bookings` | **No** (`Booking` model has no rating fields; `Service` model only has aggregate read-only catalog rating) | No review submission endpoint (`/reviews` or `/bookings/:id/rate`); `Booking` model lacks `rating`, `review`, or `ratedAt` fields; only aggregate `rating` / `reviewCount` exists on `Service`. |
| **Live Tracking** | **B. Partially supported** | `LiveTrackerSheet` dynamically maps 7-stage service progression to backend status strings with pull-to-refresh & polling via `/api/v1/bookings/:id` | **Yes** (Status progression & live refresh connected via `BookingService.getBookingById`) | No WebSockets, SSE, real-time GPS stream, driver coordinates, or live telematics endpoint; updates rely on REST status polling. |

---

## Part A — Backend Capability Audit Details

### 1. Coupons & Discount Validation
- **Classification**: **B. Partially supported**
- **Code Evidence**:
  - `backend/src/models/booking.model.ts`:
    - `couponCode?: string;` is an optional string schema field.
    - `discount: { type: Number, default: 0, min: 0 }` is stored and calculated into `totalAmount`.
  - `backend/src/services/booking.service.ts`:
    - Validates `data.totalAmount === expectedTotal` where `expectedTotal = subtotal - discount + pickupFee + gst`.
  - `backend/src/routes/offer.routes.ts`:
    - Empty router initialized (`Router()`), mounted at `/api/v1/offers` with no routes or controllers registered.
  - **Verdict**: Backend allows recording applied coupons and discounts on a booking, but provides no server-side coupon catalog, expiration checking, minimum order value verification, or single-use validation.

### 2. Garages / Hubs / Service Centers
- **Classification**: **C. Not supported**
- **Code Evidence**:
  - `backend/src/models/`: No `garage.model.ts`, `hub.model.ts`, or `serviceCenter.model.ts`.
  - `backend/src/controllers/vehicle.controller.ts`:
    - Uses the term "garage" purely as a user-facing metaphor for a user's collection of saved personal vehicles (`GET /api/v1/vehicles`).
  - `backend/src/models/booking.model.ts`:
    - `serviceMode`: Enum `['doorstep', 'workshop']`.
    - `address`: String representation of user's doorstep location or workshop destination.
    - No `garageId`, `hubId`, or foreign key reference to any service center entity.
  - **Verdict**: Backend has no multi-garage inventory, hub assignment, or workshop management infrastructure.

### 3. Mechanics / Technician Assignment
- **Classification**: **C. Not supported**
- **Code Evidence**:
  - Searched entire backend codebase for `mechanic`, `technician`, `assignee`, `staff`:
    - Found 0 matches across models, controllers, services, routes, and validation schemas.
  - `UserRole` in `backend/src/models/user.model.ts` only defines `'customer' | 'admin'`. There is no `'mechanic'` or `'technician'` role.
  - `Booking` model contains no `mechanicId`, `technicianId`, `technicianName`, or contact details.
  - **Verdict**: Mechanic assignment and technician dispatch do not exist on the backend.

### 4. Ratings / Reviews / Feedback
- **Classification**: **B. Partially supported**
- **Code Evidence**:
  - `backend/src/models/service.model.ts`:
    - Contains `rating: { type: Number, default: 4.5, min: 1, max: 5 }` and `reviewCount: { type: Number, default: 0, min: 0 }`.
    - These fields are read-only metadata on service items, used for catalog sorting and filtering.
  - `backend/src/models/booking.model.ts`:
    - Contains no rating, review score, review comments, or feedback flags.
  - `backend/src/routes/`:
    - No review, rating, or feedback routes exist.
  - **Verdict**: Customers cannot submit ratings or reviews via any API endpoint. Aggregate ratings on services are static/seeded metadata.

### 5. Tracking / Location / Live Progression
- **Classification**: **B. Partially supported**
- **Code Evidence**:
  - `backend/src/models/booking.model.ts`:
    - Defines `status`: `['confirmed', 'vehicle_received', 'inspection', 'service_in_progress', 'quality_check', 'ready_for_delivery', 'completed', 'cancelled']`.
    - Defines valid status transitions in `backend/src/services/booking.service.ts`:
      - `confirmed` -> `vehicle_received` -> `inspection` -> `service_in_progress` -> `quality_check` -> `ready_for_delivery` -> `completed`.
      - `cancelled` allowed from `confirmed`, `vehicle_received`, `inspection`.
  - Routes: `GET /api/v1/bookings/:id` fetches current booking state with authenticated ownership enforcement.
  - Real-time/Telemetry: No WebSockets (no `ws` or `socket.io`), no Server-Sent Events (SSE), no GPS coordinate fields (`latitude`, `longitude`, `liveLocation`), and no tracking session IDs.
  - **Verdict**: Discrete lifecycle status tracking is fully supported via REST API, but continuous GPS tracking and socket streams do not exist.

---

## Part B — Flutter Implementation Audit Details

### 1. Coupons (`CouponSheet`, `BookingFlowSheet`)
- **Current State**:
  - Flutter renders available promo codes via `CouponSheet` with discounts (e.g., `FIRST50`, `WINTER200`, `EXPERT100`).
  - Validation is performed client-side against the subtotal and discount rules.
  - In `BookingFlowSheet`, when a coupon is selected, `couponCode`, `discount`, and recalculation of `totalAmount` are passed directly into `BookingService.createBooking(...)`.
  - Real server bookings persist `couponCode` and `discount` to MongoDB.
- **Handling**: Client-side discount validation preserved; booking creation passes genuine coupon fields to the backend.

### 2. Garages / Hubs (`SelectGarageSheet`)
- **Current State**:
  - Allows customers choosing "Self Drop to Service Center" to select among verified hubs (`MockData.serviceCenters`).
  - Selected hub's name and address are stored in the booking's `address` and `workshopName`.
  - For server bookings, the chosen workshop name and address are passed in the `address` field of `createBooking`.
- **Handling**: Kept working locally; no fake `garageId` added to server payload.

### 3. Mechanic Assignment (`LiveTrackerSheet`, `BookingDetailsSheet`)
- **Current State**:
  - Displays assigned mechanic card (e.g., "Rajesh Kumar", 4.9 rating, verified badge, Call/Message buttons).
  - When a booking is created or fetched from the backend, `assignedMechanic` is populated with a fallback default ("Rajesh Kumar - Master Technician") so UI layouts render smoothly without null assertions.
- **Handling**: Preserved as client-side UI fallback; documented as an unsupported backend feature.

### 4. Ratings / Feedback (`RatingSheet`, `BookingDetailsSheet`)
- **Current State**:
  - Completed bookings display a "Rate Service" button in `BookingDetailsSheet`.
  - Opening `RatingSheet` allows selecting 1-5 stars, multi-selecting tag pills ("Punctual", "Transparent Pricing"), and writing review feedback.
  - Submissions update the local booking model in `MockData.bookings`.
- **Handling**: Preserved locally; no fabricated `/reviews` endpoint created.

### 5. Live Tracking (`LiveTrackerSheet`)
- **Current State Prior to Step 4.9**:
  - Static display using mock stage index calculations.
- **Enhancement in Step 4.9**:
  - Converted `LiveTrackerSheet` to `StatefulWidget`.
  - Dynamically computes timeline stage (0 to 6) based on `backendStatus`:
    - `confirmed` -> Stage 0: Booking Confirmed
    - `vehicle_received` -> Stage 1: Vehicle Pickup / Received
    - `inspection` -> Stage 2: Inspection Started
    - `service_in_progress` -> Stage 3: Service In Progress
    - `quality_check` -> Stage 4: Quality Check
    - `ready_for_delivery` -> Stage 5: Ready for Delivery
    - `completed` -> Stage 6: Completed
  - Added pull-to-refresh (`RefreshIndicator`) and explicit header refresh button (`IconButton(Icons.refresh_rounded)`).
  - Queries `BookingService.getBookingById(id)` for real 24-character hex MongoDB ObjectIds.
  - Distinguishes cancelled bookings and displays a clear cancellation banner with a "Book Again" action.
  - Gracefully recovers from network exceptions without disrupting the user view.

---

## Verification Results

- **Flutter Analyze**: 0 issues
- **Flutter Tests**: 190/190 passing (183 baseline + 7 new widget tests for `LiveTrackerSheet`)
- **Backend Tests**: 63/63 passing
- **No breaking changes** introduced to authentication, vehicle integration, service discovery, or booking integration.
