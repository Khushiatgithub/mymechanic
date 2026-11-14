# MyMechanic Backend API — Phase 3 Step 3

Production-grade REST API backend with secure JWT authentication, token rotation, strict ownership enforcement, and MongoDB persistence for the MyMechanic platform.

---

## 1. Tech Stack

- **Runtime**: Node.js (`v18+` / `v20+` / `v24+`)
- **Language**: TypeScript (`^5.7+`) with `strict: true`
- **Framework**: Express.js (`^4.21+`)
- **Database**: MongoDB with Mongoose ODM (`^8.9+`)
- **Authentication**: JWT (`jsonwebtoken`), Bcrypt (`bcryptjs`), SHA-256 token hashing
- **Security**: Helmet, CORS, Rate Limiting (`express-rate-limit`), 1MB JSON limits, strict ObjectId assertions
- **Logging**: Morgan HTTP logger + structured console logger
- **Testing**: Jest, ts-jest, Supertest
- **Dev Runner**: `tsx` (TypeScript live reload)

---

## 2. Project Architecture

```text
backend/
├── src/
│   ├── config/
│   │   ├── database.ts             # Mongoose connection & lifecycle
│   │   └── env.ts                  # Typesafe environment loader (JWT & bcrypt config)
│   ├── controllers/
│   │   ├── auth.controller.ts      # Register, login, refresh, logout, me, password change
│   │   ├── health.controller.ts    # Diagnostics & DB connectivity
│   │   ├── user.controller.ts      # User profile & management
│   │   ├── vehicle.controller.ts   # Authenticated garage & active car controller
│   │   ├── serviceCategory.controller.ts # Category operations
│   │   ├── service.controller.ts   # Service package operations
│   │   └── booking.controller.ts   # Authenticated booking lifecycle & state machine
│   ├── middleware/
│   │   ├── auth.middleware.ts      # Bearer JWT verification & req.user attachment
│   │   ├── error.middleware.ts     # Centralized error handler & status mapper
│   │   ├── notFound.middleware.ts  # Standardized 404 handler
│   │   └── rateLimit.middleware.ts # Dev-friendly rate limiting for auth endpoints
│   ├── models/
│   │   ├── user.model.ts           # User schema (passwordHash, isActive, lastLoginAt)
│   │   ├── refreshSession.model.ts # SHA-256 hashed refresh tokens for rotation
│   │   ├── vehicle.model.ts        # Vehicle schema & user indexes
│   │   ├── serviceCategory.model.ts# Service category schema & sort indexes
│   │   ├── service.model.ts        # Service schema & text search indexes
│   │   ├── booking.model.ts        # Booking schema & 8-stage tracking enum
│   │   └── index.ts                # Model barrel export
│   ├── routes/
│   │   ├── auth.routes.ts          # /api/v1/auth routes
│   │   ├── health.routes.ts        # /api/v1/health route
│   │   ├── user.routes.ts          # /api/v1/users routes (includes /me)
│   │   ├── vehicle.routes.ts       # /api/v1/vehicles routes (protected)
│   │   ├── serviceCategory.routes.ts # /api/v1/service-categories routes
│   │   ├── service.routes.ts       # /api/v1/services routes
│   │   ├── booking.routes.ts       # /api/v1/bookings routes (protected)
│   │   └── index.ts                # Master API router
│   ├── seed/
│   │   └── seed.ts                 # Idempotent development seed script
│   ├── services/
│   │   ├── auth.service.ts         # Register, login, token rotation & password change
│   │   ├── user.service.ts         # User management & safety checks
│   │   ├── vehicle.service.ts      # Owner-scoped vehicle queries & active toggle
│   │   ├── serviceCategory.service.ts # Category dependency checks
│   │   ├── service.service.ts      # Text search, filter & sorting logic
│   │   └── booking.service.ts      # Owner-scoped bookings & state transition machine
│   ├── types/
│   │   └── express.d.ts            # Type declaration merge for req.user
│   ├── utils/
│   │   ├── auth.util.ts            # Bcrypt, JWT and crypto token hashing helpers
│   │   ├── errors.ts               # Standardized ApiError hierarchies
│   │   ├── logger.util.ts          # Safe development logger
│   │   ├── pagination.util.ts      # Pagination query parser & meta builder
│   │   ├── response.util.ts        # Uniform success/paginated/error envelopes
│   │   └── validation.util.ts      # ObjectId validator & registration normalizer
│   ├── app.ts                      # Express app setup & middleware pipeline
│   └── server.ts                   # HTTP listener & graceful shutdown
├── tests/
│   ├── auth.test.ts                # Auth, token rotation, ownership & spoofing tests (31 tests)
│   ├── crud.test.ts                # Core CRUD integration tests (27 tests)
│   └── health.test.ts              # Health & gateway tests (5 tests)
├── .env.example                    # Environment template
├── .gitignore                      # Git ignore rules
├── jest.config.js                  # Jest test runner configuration
├── package.json                    # Dependencies & npm scripts
├── tsconfig.json                   # TypeScript compiler configuration
└── README.md                       # Complete backend documentation
```

---

## 3. Setup & Running

### Installation
```bash
cd backend
npm install
```

### Environment Configuration
Copy the template environment file:
```bash
cp .env.example .env
```

Configuration variables (`.env`):
```env
PORT=5000
NODE_ENV=development
MONGODB_URI=mongodb://127.0.0.1:27017/mymechanic
API_PREFIX=/api/v1
CORS_ORIGIN=*

# Authentication & Security
JWT_ACCESS_SECRET=replace_with_a_long_random_access_secret_min_32_chars
JWT_ACCESS_EXPIRES_IN=15m
JWT_REFRESH_SECRET=replace_with_a_different_long_random_refresh_secret
JWT_REFRESH_EXPIRES_IN=7d
BCRYPT_SALT_ROUNDS=12
```

### NPM Scripts
| Command | Description |
|---|---|
| `npm run dev` | Starts server in watch mode using `tsx` |
| `npm run build` | Compiles TypeScript into `dist/` with 0 errors |
| `npm start` | Runs the compiled server from `dist/server.js` |
| `npm run seed` | Seeds database with demo users, vehicles, categories, services, and bookings |
| `npm test` | Runs the full Jest & Supertest suite (63/63 tests passing) |

---

## 4. Development Seed Credentials

Run `npm run seed` to populate the database with realistic development data.
All demo accounts are stored using safe bcrypt hashes (`saltRounds: 12`). Plaintext passwords are never committed or stored in MongoDB.

| Name | Email | Password | Role |
|---|---|---|---|
| **Demo User** | `demo@mymechanic.local` | `DemoPassword123!` | Customer |
| **Rahul Sharma** | `rahul.sharma@example.com` | `Password123!` | Customer |
| **Priya Patel** | `priya.patel@example.com` | `Password123!` | Customer |

---

## 5. Authentication Architecture

### 1. Token Strategy
- **Access Token**: Short-lived (`15m`), stateless JWT containing minimal identity (`sub: userId`, `type: 'access'`).
- **Refresh Token**: Long-lived (`7d`) JWT containing (`sub: userId`, `type: 'refresh'`).
- **Refresh Session Storage**: Refresh tokens are hashed using SHA-256 before being stored in the `RefreshSession` collection. Raw refresh tokens are never persisted in the database.
- **Token Rotation**: Each refresh request revokes the previous refresh session and issues a new access token + new refresh token.
- **Reuse Detection**: If a revoked refresh token is reused, all active sessions for that user are immediately invalidated as a security countermeasure (`TOKEN_REUSE_DETECTED`).

### 2. Authorization Header Format
Protected endpoints require the HTTP Bearer header:
```http
Authorization: Bearer <access-token>
```

---

## 6. Endpoints Specification

### Authentication API (`/api/v1/auth`)

#### `POST /api/v1/auth/register` (Rate Limited)
- **Body**:
  ```json
  {
    "name": "Khushi",
    "email": "khushi@example.com",
    "password": "StrongPassword123!",
    "phone": "+919876543210"
  }
  ```
- **Response**: `201 Created`
  ```json
  {
    "success": true,
    "message": "Registration successful",
    "data": {
      "user": { "_id": "...", "name": "Khushi", "email": "khushi@example.com" },
      "accessToken": "eyJhbGciOi...",
      "refreshToken": "eyJhbGciOi..."
    }
  }
  ```
- **Security**: Never returns `password` or `passwordHash`.

#### `POST /api/v1/auth/login` (Rate Limited)
- **Body**:
  ```json
  {
    "email": "khushi@example.com",
    "password": "StrongPassword123!"
  }
  ```
- **Response**: `200 OK` with `user`, `accessToken`, `refreshToken`.
- **Security**: Generic `401 INVALID_CREDENTIALS` on invalid email, wrong password, or inactive account (never leaks whether the account exists).

#### `POST /api/v1/auth/refresh` (Rate Limited)
- **Body**: `{ "refreshToken": "..." }`
- **Response**: `200 OK` with rotated `{ "accessToken": "...", "refreshToken": "..." }`.

#### `GET /api/v1/auth/me` (Protected)
- **Headers**: `Authorization: Bearer <access-token>`
- **Response**: `200 OK` with authenticated user profile.
- **Security**: Identity is derived exclusively from JWT `req.user.id`.

#### `PATCH /api/v1/auth/password` (Protected & Rate Limited)
- **Headers**: `Authorization: Bearer <access-token>`
- **Body**:
  ```json
  {
    "currentPassword": "OldPassword123!",
    "newPassword": "NewPassword456!"
  }
  ```
- **Response**: `200 OK`. Automatically revokes all existing refresh sessions for this user.

#### `POST /api/v1/auth/logout` (Protected)
- **Headers**: `Authorization: Bearer <access-token>`
- **Body**: `{ "refreshToken": "..." }` (optional)
- **Response**: `200 OK`. Revokes the user's refresh session.

---

### Protected vs Public Routes

| Route Group | Path | Access | Security Policy |
|---|---|---|---|
| **Health** | `GET /api/v1/health` | Public | Diagnostics only |
| **Auth** | `POST /api/v1/auth/register`, `/login`, `/refresh` | Public | Rate-limited |
| **Auth** | `GET /api/v1/auth/me`, `POST /logout`, `PATCH /password` | Authenticated | Requires valid Bearer access token |
| **Users Self** | `GET /api/v1/users/me`, `PATCH /api/v1/users/me` | Authenticated | Scoped to `req.user.id` |
| **Vehicles** | `/api/v1/vehicles/*` (All methods) | Authenticated | Strict ownership: scoped to `req.user.id`. Client `userId` spoofing rejected. |
| **Bookings** | `/api/v1/bookings/*` (All methods) | Authenticated | Strict ownership: users can only view, create, edit, or cancel their own bookings. |
| **Services** | `GET /api/v1/services`, `GET /api/v1/services/:id` | Public | Read-only catalog |
| **Categories** | `GET /api/v1/service-categories`, `GET /:id` | Public | Read-only catalog |
| **Catalog Mutations** | `POST/PATCH/DELETE /services`, `/service-categories` | Protected | Restricted for future admin role |

---

## 7. Ownership Security & Spoofing Prevention

1. **User ID Spoofing Eliminated**:
   - `GET /api/v1/vehicles?userId=<another-user>`: The backend ignores any client-supplied `userId` parameter and returns only vehicles belonging to `req.user.id`.
   - `POST /api/v1/vehicles`: The vehicle's `userId` is set directly from `req.user.id`. Providing a conflicting `userId` in the body returns `403 FORBIDDEN`.
   - `POST /api/v1/bookings`: The booking user is derived strictly from `req.user.id`. Providing a conflicting `userId` in the body returns `403 FORBIDDEN`.
2. **Resource Isolation**:
   - Accessing another user's vehicle or booking by guessing/tampering with the ID in the URL returns `404 NOT_FOUND` (preventing resource existence enumeration).
3. **Booking Vehicle Ownership**:
   - When creating a booking, the system verifies that the selected vehicle belongs to the authenticated user. Mismatches return `400 VEHICLE_OWNERSHIP_MISMATCH`.

---

## 8. Current Scope & Future Phases

- **Flutter Application Decoupled**: The Flutter mobile app continues to operate on local mock data (`lib/data/mock_data.dart`) until the upcoming dedicated authentication integration phase.
- **Payment Gateways**: Razorpay / Stripe integration is scheduled for Phase 4.
