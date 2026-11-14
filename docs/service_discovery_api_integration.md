# MyMechanic — Service Discovery API Integration Guide

Phase 3, Step 4.7 connects the MyMechanic Flutter catalog discovery flow directly to the backend Node.js / Express / MongoDB Service Categories and Services REST APIs.

---

## 1. Architecture Overview

The Service Discovery integration follows the established API client and service layer architecture:

```
[ServicesScreen / ServiceDetailSheet]
             │
             ▼
   [ServiceDiscoveryService]
             │ (injects ApiClient)
             ▼
        [ApiClient]
             │ (public request, optional Bearer token if logged in)
             │ (normalizes base URL: /api/v1 prefix)
             ▼
 [Express Discovery Routes]
  ├── /api/v1/service-categories
  └── /api/v1/services
             │
             ▼
  [Controllers & Services]
  ├── ServiceCategoryController / ServiceCategoryService
  └── ServiceController / ServiceService
             │
             ▼
     [MongoDB / Mongoose]
     ├── ServiceCategory model
     └── Service model
```

### Key Principles
1. **Public Catalog Access**: The discovery endpoints are public read endpoints. They do not introduce a login wall and remain accessible to both guest users and authenticated customers.
2. **Standard Envelopes**: Reuses the backend's standard JSON response envelope (`{ success: true, data: { items: [...], pagination: {...} } }`).
3. **Resilient Offline Fallback**: In offline scenarios or test environments, the UI gracefully retains local fallback data while surfacing an honest warning ribbon with a retry button.
4. **Resilient Model Parsing**: Handles both populated category objects (`{ _id, name, icon }`) and raw ObjectId string references on service items.
5. **Brand Color & Icon Mapping**: Maps backend icon identifiers (`build_circle`, `ac_unit`, `battery_charging_full`, `tire_repair`, `local_car_wash`, `checklist`, etc.) to Flutter `IconData` and cohesive design system palette colors.

---

## 2. Backend Endpoints Used

All discovery endpoints are mounted under `/api/v1`:

| HTTP Method | Route | Description | Backend Controller Method | Auth Required |
| :--- | :--- | :--- | :--- | :--- |
| `GET` | `/api/v1/service-categories` | List active service categories (paginated) | `ServiceCategoryController.getCategories` | No (Public) |
| `GET` | `/api/v1/service-categories/:id` | Get category details by ID | `ServiceCategoryController.getCategoryById` | No (Public) |
| `GET` | `/api/v1/services` | List active services with filters | `ServiceController.getServices` | No (Public) |
| `GET` | `/api/v1/services/:id` | Get single service details by ID | `ServiceController.getServiceById` | No (Public) |

### Query Parameters for `GET /api/v1/services`

| Parameter | Type | Example | Description |
| :--- | :--- | :--- | :--- |
| `categoryId` | `string` | `67b8a1...` | Filter services belonging to a specific category |
| `search` | `string` | `AC`, `Periodic` | Case-insensitive title and description regex search |
| `sort` | `string` | `price_asc` | Sort options: `price_asc`, `price_desc`, `rating_desc` |
| `active` | `string` | `true` | Restrict results to active services (`isActive: true`) |
| `page` | `number` | `1` | Page number for pagination |
| `limit` | `number` | `50` | Maximum items per page |

---

## 3. Data Mapping & Schema Alignment

### ServiceCategory Schema Mapping

| Flutter Field (`ServiceCategory`) | Backend Field (`IServiceCategory`) | Type | Description |
| :--- | :--- | :--- | :--- |
| `id` | `_id` | `String` (ObjectId) | Unique category identifier |
| `name` | `name` | `String` | Category display title |
| `description` | `description` | `String` | Category description |
| `icon` | `icon` | `String` -> `IconData` | Mapped from icon string (e.g. `build_circle` -> `Icons.build_circle_outlined`) |
| `tintColor` | — | `Color` | Resolved from design system palette based on icon/name |
| `backgroundColor` | — | `Color` | Soft pastel background color for category icon container |
| `isActive` | `isActive` | `bool` | Whether category is active (default `true`) |
| `sortOrder` | `sortOrder` | `int` | Display ordering priority |

### ServiceItem Schema Mapping

| Flutter Field (`ServiceItem`) | Backend Field (`IService`) | Type | Description |
| :--- | :--- | :--- | :--- |
| `id` | `_id` | `String` (ObjectId) | Unique service identifier |
| `categoryId` | `categoryId` | `String` (ObjectId) | Category identifier (unwrapped if populated) |
| `categoryName` | `categoryId.name` | `String?` | Category title populated from backend |
| `title` | `title` | `String` | Service title |
| `description` | `description` | `String` | Detailed service description |
| `price` | `price` | `double` | Discounted / active customer price |
| `originalPrice` | `originalPrice` | `double` | Original MSRP strike price |
| `durationText` | `durationText` | `String` | Estimated service duration (e.g. "3-4 Hours") |
| `rating` | `rating` | `double` | Average customer rating (0 to 5) |
| `reviewsCount` | `reviewCount` | `int` | Count of verified customer reviews |
| `warrantyPeriod` | `warrantyPeriod` | `String` | Warranty coverage string |
| `includedItems` | `includedItems` | `List<String>` | List of included service checklist items |
| `excludedItems` | `excludedItems` | `List<String>` | List of exclusions |

---

## 4. Documented Backend Gaps

As per the architectural specification:
1. **Dedicated Service Packages Endpoint**:
   - The backend currently implements only the individual `Service` model and does not expose a `/api/v1/service-packages` or `/api/v1/packages` route.
   - **Resolution**: The "Service Packages" tab on `ServicesScreen` continues to use the existing client-side mock packages catalog (`MockData.servicePackages`), preserving full backward compatibility without fabricating an unsupported server contract.

---

## 5. Verification & Testing

- **Flutter Analyze**: 0 issues reported (`flutter analyze`).
- **Flutter Test Suite**: 154/154 tests passing (139 baseline tests + 9 service discovery unit tests + 6 widget tests).
- **Test Coverage**:
  - `test/services/service_discovery_service_test.dart`:
    - Successful category retrieval, parsing, and `sortOrder` sorting.
    - Single category retrieval by ID.
    - Service listing with query filters (`categoryId`, `search`, `sort`).
    - Populated `categoryId` parsing.
    - Single service retrieval by ID.
    - Empty result envelopes handling.
    - HTTP 404, HTTP 500, and malformed HTML responses.
    - Error message mapping via `ServiceDiscoveryService.getErrorMessage`.
  - `test/screens/services_screen_test.dart`:
    - Loading indicator and progress spinner rendering.
    - Successful rendering of real backend categories and service cards.
    - Category filter chip filtering.
    - Search query filtering by title or feature.
    - Empty state with "Show All Services" recovery.
    - Error state with "Unable to Load Services" and "Try Again" recovery.
