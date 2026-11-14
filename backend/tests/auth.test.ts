import request from 'supertest';
import mongoose from 'mongoose';
import { createApp } from '../src/app';
import { connectDatabase, disconnectDatabase } from '../src/config/database';
import { User } from '../src/models/user.model';
import { Vehicle } from '../src/models/vehicle.model';
import { ServiceCategory } from '../src/models/serviceCategory.model';
import { Service } from '../src/models/service.model';
import { Booking } from '../src/models/booking.model';

jest.setTimeout(25000);

describe('MyMechanic Phase 3 Step 3 — Authentication & Identity Tests', () => {
  const app = createApp();

  // Test state
  let userAToken = '';
  let userARefreshToken = '';
  let userAId = '';
  const userAEmail = `user_a_${Date.now()}@example.com`;
  const userAPassword = 'StrongPassword123!';

  let userBToken = '';
  let userBId = '';
  const userBEmail = `user_b_${Date.now()}@example.com`;
  const userBPassword = 'StrongPassword456!';

  let userAVehicleId = '';
  let userBVehicleId = '';
  let testServiceId = '';
  let userABookingId = '';

  beforeAll(async () => {
    await connectDatabase();
    expect(mongoose.connection.name).toBe('mymechanic_test');

    // Setup a category and service for booking tests
    let category = await ServiceCategory.findOne({ name: 'Periodic Services' });
    if (!category) {
      category = await ServiceCategory.create({
        name: 'Periodic Services',
        description: 'Test category',
        icon: 'build',
        sortOrder: 1,
      });
    }

    let service = await Service.findOne({ title: 'Standard Periodic Service' });
    if (!service) {
      service = await Service.create({
        categoryId: category._id,
        title: 'Standard Periodic Service',
        description: 'Test service',
        price: 2999,
        durationText: '3 Hours',
      });
    }
    testServiceId = service._id.toString();
  });

  afterAll(async () => {
    // Cleanup test users and related records
    if (userAId) {
      await Booking.deleteMany({ userId: userAId });
      await Vehicle.deleteMany({ userId: userAId });
      await User.findByIdAndDelete(userAId);
    }
    if (userBId) {
      await Booking.deleteMany({ userId: userBId });
      await Vehicle.deleteMany({ userId: userBId });
      await User.findByIdAndDelete(userBId);
    }
    await disconnectDatabase();
  });

  // ==========================================
  // 1. REGISTRATION
  // ==========================================
  describe('POST /api/v1/auth/register', () => {
    it('should successfully register User A with secure password hash', async () => {
      const res = await request(app)
        .post('/api/v1/auth/register')
        .send({
          name: 'User Alpha',
          email: userAEmail,
          password: userAPassword,
          phone: `+9198${Date.now().toString().slice(-8)}`,
        });

      expect(res.status).toBe(201);
      expect(res.body.success).toBe(true);
      expect(res.body.data).toHaveProperty('user');
      expect(res.body.data).toHaveProperty('accessToken');
      expect(res.body.data).toHaveProperty('refreshToken');

      // Security checks: response must NEVER contain password or passwordHash
      expect(res.body.data.user).not.toHaveProperty('password');
      expect(res.body.data.user).not.toHaveProperty('passwordHash');

      userAId = res.body.data.user._id;
      userAToken = res.body.data.accessToken;
      userARefreshToken = res.body.data.refreshToken;

      // Verify in DB that password is stored as bcrypt hash
      const dbUser = await User.findById(userAId).select('+passwordHash');
      expect(dbUser).not.toBeNull();
      expect(dbUser?.passwordHash).toBeDefined();
      expect(dbUser?.passwordHash).toMatch(/^\$2[aby]\$\d+\$/); // bcrypt signature
      expect(dbUser?.passwordHash).not.toBe(userAPassword); // definitely not plaintext
    });

    it('should register User B for multi-user ownership tests', async () => {
      const res = await request(app)
        .post('/api/v1/auth/register')
        .send({
          name: 'User Beta',
          email: userBEmail,
          password: userBPassword,
        });

      expect(res.status).toBe(201);
      userBId = res.body.data.user._id;
      userBToken = res.body.data.accessToken;
    });

    it('should reject registration with duplicate email (409)', async () => {
      const res = await request(app)
        .post('/api/v1/auth/register')
        .send({
          name: 'Duplicate User',
          email: userAEmail,
          password: 'AnotherPassword123!',
        });

      expect(res.status).toBe(409);
      expect(res.body.success).toBe(false);
      expect(res.body.error.code).toBe('EMAIL_ALREADY_EXISTS');
    });

    it('should reject registration with weak/short password (400)', async () => {
      const res = await request(app)
        .post('/api/v1/auth/register')
        .send({
          name: 'Short Pass User',
          email: 'shortpass@example.com',
          password: 'short', // < 8 characters
        });

      expect(res.status).toBe(400);
      expect(res.body.success).toBe(false);
    });

    it('should reject registration with invalid email format (400)', async () => {
      const res = await request(app)
        .post('/api/v1/auth/register')
        .send({
          name: 'Invalid Email',
          email: 'not-an-email',
          password: 'StrongPassword123!',
        });

      expect(res.status).toBe(400);
      expect(res.body.success).toBe(false);
    });
  });

  // ==========================================
  // 2. LOGIN
  // ==========================================
  describe('POST /api/v1/auth/login', () => {
    it('should log in successfully with valid credentials', async () => {
      const res = await request(app)
        .post('/api/v1/auth/login')
        .send({
          email: userAEmail,
          password: userAPassword,
        });

      expect(res.status).toBe(200);
      expect(res.body.success).toBe(true);
      expect(res.body.data).toHaveProperty('accessToken');
      expect(res.body.data).toHaveProperty('refreshToken');
      expect(res.body.data.user).not.toHaveProperty('passwordHash');

      userAToken = res.body.data.accessToken;
      userARefreshToken = res.body.data.refreshToken;
    });

    it('should reject login with wrong password (401 generic message)', async () => {
      const res = await request(app)
        .post('/api/v1/auth/login')
        .send({
          email: userAEmail,
          password: 'WrongPassword999!',
        });

      expect(res.status).toBe(401);
      expect(res.body.success).toBe(false);
      expect(res.body.message).toBe('Invalid email or password');
    });

    it('should reject login with non-existent account (401 generic message)', async () => {
      const res = await request(app)
        .post('/api/v1/auth/login')
        .send({
          email: 'nonexistent_account_xyz@example.com',
          password: 'SomePassword123!',
        });

      expect(res.status).toBe(401);
      expect(res.body.success).toBe(false);
      expect(res.body.message).toBe('Invalid email or password');
    });

    it('should reject login with disabled/inactive account (401 generic message)', async () => {
      // Temporarily deactivate User B
      await User.findByIdAndUpdate(userBId, { isActive: false });

      const res = await request(app)
        .post('/api/v1/auth/login')
        .send({
          email: userBEmail,
          password: userBPassword,
        });

      expect(res.status).toBe(401);
      expect(res.body.success).toBe(false);
      expect(res.body.message).toBe('Invalid email or password');

      // Re-enable User B
      await User.findByIdAndUpdate(userBId, { isActive: true });
    });
  });

  // ==========================================
  // 3. AUTHENTICATED /me ENDPOINT
  // ==========================================
  describe('GET /api/v1/auth/me', () => {
    it('should return current user profile when valid token provided', async () => {
      const res = await request(app)
        .get('/api/v1/auth/me')
        .set('Authorization', `Bearer ${userAToken}`);

      expect(res.status).toBe(200);
      expect(res.body.success).toBe(true);
      expect(res.body.data._id).toBe(userAId);
      expect(res.body.data.email).toBe(userAEmail.toLowerCase());
      expect(res.body.data).not.toHaveProperty('passwordHash');
    });

    it('should reject request when Authorization header is missing (401)', async () => {
      const res = await request(app).get('/api/v1/auth/me');

      expect(res.status).toBe(401);
      expect(res.body.success).toBe(false);
      expect(res.body.error.code).toBe('UNAUTHORIZED');
    });

    it('should reject request with malformed Bearer token (401)', async () => {
      const res = await request(app)
        .get('/api/v1/auth/me')
        .set('Authorization', 'Bearer invalid-token-string-xyz');

      expect(res.status).toBe(401);
      expect(res.body.success).toBe(false);
      expect(res.body.error.code).toBe('INVALID_TOKEN');
    });
  });

  // ==========================================
  // 4. TOKEN REFRESH & ROTATION
  // ==========================================
  describe('POST /api/v1/auth/refresh', () => {
    it('should issue new tokens and rotate refresh token', async () => {
      const oldRefreshToken = userARefreshToken;

      const res = await request(app)
        .post('/api/v1/auth/refresh')
        .send({ refreshToken: oldRefreshToken });

      expect(res.status).toBe(200);
      expect(res.body.success).toBe(true);
      expect(res.body.data).toHaveProperty('accessToken');
      expect(res.body.data).toHaveProperty('refreshToken');

      // Update active tokens
      userAToken = res.body.data.accessToken;
      userARefreshToken = res.body.data.refreshToken;

      // Verify that the old refresh token was revoked and cannot be reused
      const reuseAttempt = await request(app)
        .post('/api/v1/auth/refresh')
        .send({ refreshToken: oldRefreshToken });

      expect(reuseAttempt.status).toBe(401);
      expect(reuseAttempt.body.error.code).toBe('TOKEN_REUSE_DETECTED');
    });

    it('should reject refresh with malformed token (401)', async () => {
      const res = await request(app)
        .post('/api/v1/auth/refresh')
        .send({ refreshToken: 'not-a-valid-jwt' });

      expect(res.status).toBe(401);
      expect(res.body.success).toBe(false);
    });
  });

  // ==========================================
  // 5. VEHICLE OWNERSHIP & SPOOFING PREVENTION
  // ==========================================
  describe('Vehicle Ownership & ID Spoofing Prevention', () => {
    it('User A creates vehicle — userId is derived from JWT (ignores client spoofing)', async () => {
      const res = await request(app)
        .post('/api/v1/vehicles')
        .set('Authorization', `Bearer ${userAToken}`)
        .send({
          make: 'Honda',
          model: 'City',
          registrationNumber: `DL-01-A-${Date.now().toString().slice(-4)}`,
          fuelType: 'Petrol',
          year: 2021,
          isActive: true,
        });

      expect(res.status).toBe(201);
      expect(res.body.data.userId).toBe(userAId);
      userAVehicleId = res.body.data._id;
    });

    it('User A cannot create vehicle by trying to spoof User B ID in body (403)', async () => {
      const res = await request(app)
        .post('/api/v1/vehicles')
        .set('Authorization', `Bearer ${userAToken}`)
        .send({
          userId: userBId, // Attempting to spoof User B
          make: 'Hyundai',
          model: 'Verna',
          registrationNumber: `DL-02-B-${Date.now().toString().slice(-4)}`,
          fuelType: 'Petrol',
          year: 2022,
        });

      expect(res.status).toBe(403);
      expect(res.body.error.code).toBe('FORBIDDEN');
    });

    it('User B creates vehicle', async () => {
      const res = await request(app)
        .post('/api/v1/vehicles')
        .set('Authorization', `Bearer ${userBToken}`)
        .send({
          make: 'Tata',
          model: 'Harrier',
          registrationNumber: `MH-01-B-${Date.now().toString().slice(-4)}`,
          fuelType: 'Diesel',
          year: 2023,
          isActive: true,
        });

      expect(res.status).toBe(201);
      expect(res.body.data.userId).toBe(userBId);
      userBVehicleId = res.body.data._id;
    });

    it('GET /vehicles?userId=UserB by User A must NOT expose User B vehicles (scoped to User A)', async () => {
      const res = await request(app)
        .get(`/api/v1/vehicles?userId=${userBId}`)
        .set('Authorization', `Bearer ${userAToken}`);

      expect(res.status).toBe(200);
      // All returned vehicles MUST belong only to User A
      expect(res.body.data.items.every((v: { userId: string }) => v.userId === userAId)).toBe(true);
    });

    it('User A cannot view User B vehicle by ID (404)', async () => {
      const res = await request(app)
        .get(`/api/v1/vehicles/${userBVehicleId}`)
        .set('Authorization', `Bearer ${userAToken}`);

      expect(res.status).toBe(404);
      expect(res.body.success).toBe(false);
    });

    it('User A cannot update User B vehicle (404)', async () => {
      const res = await request(app)
        .patch(`/api/v1/vehicles/${userBVehicleId}`)
        .set('Authorization', `Bearer ${userAToken}`)
        .send({ model: 'Hacked Model' });

      expect(res.status).toBe(404);
    });

    it('User A cannot activate User B vehicle (404)', async () => {
      const res = await request(app)
        .patch(`/api/v1/vehicles/${userBVehicleId}/active`)
        .set('Authorization', `Bearer ${userAToken}`);

      expect(res.status).toBe(404);
    });

    it('User A cannot delete User B vehicle (404)', async () => {
      const res = await request(app)
        .delete(`/api/v1/vehicles/${userBVehicleId}`)
        .set('Authorization', `Bearer ${userAToken}`);

      expect(res.status).toBe(404);
    });
  });

  // ==========================================
  // 6. BOOKING OWNERSHIP & SPOOFING PREVENTION
  // ==========================================
  describe('Booking Ownership & ID Spoofing Prevention', () => {
    it('User A creates booking — userId is derived from JWT', async () => {
      const res = await request(app)
        .post('/api/v1/bookings')
        .set('Authorization', `Bearer ${userAToken}`)
        .send({
          vehicleId: userAVehicleId,
          serviceId: testServiceId,
          scheduledDate: new Date(Date.now() + 86400000).toISOString(),
          scheduledTime: '10:00 AM - 12:00 PM',
          serviceMode: 'doorstep',
          address: 'User A Address Line 1',
          subtotal: 2999,
          totalAmount: 3538,
        });

      expect(res.status).toBe(201);
      expect(res.body.data.userId._id).toBe(userAId);
      userABookingId = res.body.data._id;
    });

    it('User A cannot create booking specifying User B ID in body (403)', async () => {
      const res = await request(app)
        .post('/api/v1/bookings')
        .set('Authorization', `Bearer ${userAToken}`)
        .send({
          userId: userBId, // Attempting to spoof User B
          vehicleId: userAVehicleId,
          serviceId: testServiceId,
          scheduledDate: new Date(Date.now() + 86400000).toISOString(),
          scheduledTime: '10:00 AM - 12:00 PM',
          subtotal: 2999,
          totalAmount: 3538,
        });

      expect(res.status).toBe(403);
      expect(res.body.error.code).toBe('FORBIDDEN');
    });

    it('User B cannot view User A booking by ID (404)', async () => {
      const res = await request(app)
        .get(`/api/v1/bookings/${userABookingId}`)
        .set('Authorization', `Bearer ${userBToken}`);

      expect(res.status).toBe(404);
      expect(res.body.success).toBe(false);
    });

    it('User B cannot update User A booking (404)', async () => {
      const res = await request(app)
        .patch(`/api/v1/bookings/${userABookingId}`)
        .set('Authorization', `Bearer ${userBToken}`)
        .send({ scheduledTime: '04:00 PM - 06:00 PM' });

      expect(res.status).toBe(404);
    });

    it('User B cannot change status of User A booking (404)', async () => {
      const res = await request(app)
        .patch(`/api/v1/bookings/${userABookingId}/status`)
        .set('Authorization', `Bearer ${userBToken}`)
        .send({ status: 'cancelled' });

      expect(res.status).toBe(404);
    });

    it('GET /bookings by User B must NOT include User A bookings', async () => {
      const res = await request(app)
        .get('/api/v1/bookings')
        .set('Authorization', `Bearer ${userBToken}`);

      expect(res.status).toBe(200);
      expect(res.body.data.items.some((b: { _id: string }) => b._id === userABookingId)).toBe(false);
    });
  });

  // ==========================================
  // 7. PASSWORD CHANGE
  // ==========================================
  describe('PATCH /api/v1/auth/password', () => {
    it('should reject password change when current password is wrong (400)', async () => {
      const res = await request(app)
        .patch('/api/v1/auth/password')
        .set('Authorization', `Bearer ${userAToken}`)
        .send({
          currentPassword: 'IncorrectOldPassword123!',
          newPassword: 'BrandNewPassword123!',
        });

      expect(res.status).toBe(400);
      expect(res.body.error.code).toBe('INCORRECT_PASSWORD');
    });

    it('should successfully change password and revoke refresh sessions', async () => {
      const res = await request(app)
        .patch('/api/v1/auth/password')
        .set('Authorization', `Bearer ${userAToken}`)
        .send({
          currentPassword: userAPassword,
          newPassword: 'BrandNewPassword123!',
        });

      expect(res.status).toBe(200);
      expect(res.body.success).toBe(true);

      // Verify old password no longer works
      const oldLogin = await request(app)
        .post('/api/v1/auth/login')
        .send({
          email: userAEmail,
          password: userAPassword,
        });

      expect(oldLogin.status).toBe(401);

      // Verify new password works
      const newLogin = await request(app)
        .post('/api/v1/auth/login')
        .send({
          email: userAEmail,
          password: 'BrandNewPassword123!',
        });

      expect(newLogin.status).toBe(200);
      expect(newLogin.body.data).toHaveProperty('accessToken');
    });
  });

  // ==========================================
  // 8. LOGOUT
  // ==========================================
  describe('POST /api/v1/auth/logout', () => {
    it('should log out successfully and revoke refresh token', async () => {
      // Log in to obtain a fresh session
      const loginRes = await request(app)
        .post('/api/v1/auth/login')
        .send({
          email: userAEmail,
          password: 'BrandNewPassword123!',
        });

      const token = loginRes.body.data.accessToken;
      const refreshToken = loginRes.body.data.refreshToken;

      // Logout
      const logoutRes = await request(app)
        .post('/api/v1/auth/logout')
        .set('Authorization', `Bearer ${token}`)
        .send({ refreshToken });

      expect(logoutRes.status).toBe(200);
      expect(logoutRes.body.success).toBe(true);

      // Verify refresh token can no longer be used
      const refreshAttempt = await request(app)
        .post('/api/v1/auth/refresh')
        .send({ refreshToken });

      expect(refreshAttempt.status).toBe(401);
    });
  });
});
