import request from 'supertest';
import mongoose from 'mongoose';
import { createApp } from '../src/app';
import { connectDatabase, disconnectDatabase } from '../src/config/database';
import { generateAccessToken } from '../src/utils/auth.util';
import { Offer } from '../src/models/offer.model';
import { Workshop } from '../src/models/workshop.model';

jest.setTimeout(25000);

describe('MyMechanic Phase 3 Step 2 & 3 — CRUD Integration Tests', () => {
  const app = createApp();

  let testUserId = '';
  let testUserToken = '';
  let secondUserId = '';
  let secondUserToken = '';
  let testVehicleId = '';
  let testSecondVehicleId = '';
  let testCategoryId = '';
  let testServiceId = '';
  let testBookingId = '';

  beforeAll(async () => {
    await connectDatabase();
    expect(mongoose.connection.name).toBe('mymechanic_test');
  });

  afterAll(async () => {
    await disconnectDatabase();
  });

  // ==========================================
  // 1. USERS API
  // ==========================================
  describe('Users API — /api/v1/users', () => {
    it('POST /users — should create a new user with valid payload', async () => {
      const uniqueSuffix = Date.now().toString().slice(-6);
      const res = await request(app)
        .post('/api/v1/users')
        .send({
          name: 'Test Customer',
          email: `testcustomer_${uniqueSuffix}@example.com`,
          phone: `+9190000${uniqueSuffix}`,
          profileImage: 'https://example.com/avatar.jpg',
        });

      expect(res.status).toBe(201);
      expect(res.body.success).toBe(true);
      expect(res.body.data).toHaveProperty('_id');
      expect(res.body.data.name).toBe('Test Customer');
      testUserId = res.body.data._id;
      testUserToken = generateAccessToken(testUserId);
    });

    it('POST /users — should reject invalid user request (missing name or invalid phone)', async () => {
      const res = await request(app)
        .post('/api/v1/users')
        .send({
          email: 'noname@example.com',
          phone: '123', // invalid phone length
        });

      expect(res.status).toBe(400);
      expect(res.body.success).toBe(false);
      expect(res.body.error).toHaveProperty('code');
    });

    it('POST /users — should create second user for ownership mismatch test', async () => {
      const uniqueSuffix = (Date.now() + 1).toString().slice(-6);
      const res = await request(app)
        .post('/api/v1/users')
        .send({
          name: 'Second Customer',
          email: `secondcustomer_${uniqueSuffix}@example.com`,
          phone: `+9191000${uniqueSuffix}`,
        });

      expect(res.status).toBe(201);
      secondUserId = res.body.data._id;
      secondUserToken = generateAccessToken(secondUserId);
    });

    it('GET /users — should list users with pagination metadata', async () => {
      const res = await request(app).get('/api/v1/users?page=1&limit=10');

      expect(res.status).toBe(200);
      expect(res.body.success).toBe(true);
      expect(res.body.data).toHaveProperty('items');
      expect(res.body.data).toHaveProperty('pagination');
      expect(res.body.data.pagination.page).toBe(1);
      expect(res.body.data.pagination.limit).toBe(10);
      expect(Array.isArray(res.body.data.items)).toBe(true);
    });

    it('GET /users/:id — should retrieve single user by ID', async () => {
      const res = await request(app).get(`/api/v1/users/${testUserId}`);

      expect(res.status).toBe(200);
      expect(res.body.success).toBe(true);
      expect(res.body.data._id).toBe(testUserId);
      expect(res.body.data.name).toBe('Test Customer');
    });

    it('PATCH /users/:id — should update safe user profile fields', async () => {
      const res = await request(app)
        .patch(`/api/v1/users/${testUserId}`)
        .send({
          name: 'Updated Customer Name',
        });

      expect(res.status).toBe(200);
      expect(res.body.success).toBe(true);
      expect(res.body.data.name).toBe('Updated Customer Name');
    });
  });

  // ==========================================
  // 2. VEHICLES API (Protected by Auth)
  // ==========================================
  describe('Vehicles API — /api/v1/vehicles', () => {
    it('POST /vehicles — should create a vehicle for authenticated user', async () => {
      const uniqueSuffix = Date.now().toString().slice(-4);
      const res = await request(app)
        .post('/api/v1/vehicles')
        .set('Authorization', `Bearer ${testUserToken}`)
        .send({
          make: 'Honda',
          model: 'City',
          variant: 'ZX CVT',
          registrationNumber: `DL-03-TC-${uniqueSuffix}`,
          fuelType: 'Petrol',
          year: 2021,
          isActive: true,
        });

      expect(res.status).toBe(201);
      expect(res.body.success).toBe(true);
      expect(res.body.data).toHaveProperty('_id');
      expect(res.body.data.userId).toBe(testUserId);
      expect(res.body.data.isActive).toBe(true);
      testVehicleId = res.body.data._id;
    });

    it('POST /vehicles — should create a second vehicle for the same user', async () => {
      const uniqueSuffix = (Date.now() + 5).toString().slice(-4);
      const res = await request(app)
        .post('/api/v1/vehicles')
        .set('Authorization', `Bearer ${testUserToken}`)
        .send({
          make: 'Maruti Suzuki',
          model: 'Baleno',
          registrationNumber: `HR-26-TC-${uniqueSuffix}`,
          fuelType: 'Petrol',
          year: 2020,
          isActive: false,
        });

      expect(res.status).toBe(201);
      expect(res.body.data.isActive).toBe(false);
      testSecondVehicleId = res.body.data._id;
    });

    it('POST /vehicles — should reject invalid fuel type or year', async () => {
      const res = await request(app)
        .post('/api/v1/vehicles')
        .set('Authorization', `Bearer ${testUserToken}`)
        .send({
          make: 'Honda',
          model: 'City',
          registrationNumber: 'DL-01-XX-9999',
          fuelType: 'Kerosene', // invalid fuel
          year: 1980, // out of range
        });

      expect(res.status).toBe(400);
      expect(res.body.success).toBe(false);
    });

    it('GET /vehicles — should list vehicles belonging to user', async () => {
      const res = await request(app)
        .get(`/api/v1/vehicles`)
        .set('Authorization', `Bearer ${testUserToken}`);

      expect(res.status).toBe(200);
      expect(res.body.success).toBe(true);
      expect(res.body.data.items.length).toBeGreaterThanOrEqual(2);
      expect(res.body.data.items.every((v: { userId: string }) => v.userId === testUserId)).toBe(true);
    });

    it('PATCH /vehicles/:id/active — should switch active vehicle and deactivate previous', async () => {
      const res = await request(app)
        .patch(`/api/v1/vehicles/${testSecondVehicleId}/active`)
        .set('Authorization', `Bearer ${testUserToken}`);

      expect(res.status).toBe(200);
      expect(res.body.data._id).toBe(testSecondVehicleId);
      expect(res.body.data.isActive).toBe(true);

      // Verify first vehicle was deactivated
      const firstCheck = await request(app)
        .get(`/api/v1/vehicles/${testVehicleId}`)
        .set('Authorization', `Bearer ${testUserToken}`);
      expect(firstCheck.body.data.isActive).toBe(false);

      // Switch back for upcoming tests
      await request(app)
        .patch(`/api/v1/vehicles/${testVehicleId}/active`)
        .set('Authorization', `Bearer ${testUserToken}`);
    });
  });

  // ==========================================
  // 3. SERVICE CATEGORIES API
  // ==========================================
  describe('Service Categories API — /api/v1/service-categories', () => {
    it('POST /service-categories — should create a new category', async () => {
      const uniqueName = `Suspension & Brakes ${Date.now()}`;
      const res = await request(app)
        .post('/api/v1/service-categories')
        .send({
          name: uniqueName,
          description: 'Shock absorbers, brake pads, discs and suspension overhaul',
          icon: 'car_repair',
          sortOrder: 10,
        });

      expect(res.status).toBe(201);
      expect(res.body.success).toBe(true);
      expect(res.body.data.name).toBe(uniqueName);
      testCategoryId = res.body.data._id;
    });

    it('GET /service-categories — should list active categories ordered by sortOrder', async () => {
      const res = await request(app).get('/api/v1/service-categories?active=true');

      expect(res.status).toBe(200);
      expect(res.body.success).toBe(true);
      expect(Array.isArray(res.body.data.items)).toBe(true);
      expect(res.body.data.items.length).toBeGreaterThan(0);
    });

    it('GET /service-categories/:id — should retrieve category by ID', async () => {
      const res = await request(app).get(`/api/v1/service-categories/${testCategoryId}`);

      expect(res.status).toBe(200);
      expect(res.body.data._id).toBe(testCategoryId);
    });
  });

  // ==========================================
  // 4. SERVICES API
  // ==========================================
  describe('Services API — /api/v1/services', () => {
    it('POST /services — should create a service under category', async () => {
      const uniqueTitle = `Front Brake Pad Overhaul ${Date.now()}`;
      const res = await request(app)
        .post('/api/v1/services')
        .send({
          categoryId: testCategoryId,
          title: uniqueTitle,
          description: 'OEM brake pad installation with caliper greasing and disc inspection',
          price: 1799,
          originalPrice: 2299,
          durationText: '1-2 Hours',
          rating: 4.8,
          includedItems: ['Brake Pad Set', 'Caliper Pin Greasing', 'Brake Fluid Top-up'],
        });

      expect(res.status).toBe(201);
      expect(res.body.success).toBe(true);
      expect(res.body.data.title).toBe(uniqueTitle);
      expect(res.body.data.price).toBe(1799);
      testServiceId = res.body.data._id;
    });

    it('POST /services — should reject service with nonexistent category', async () => {
      const fakeCategoryId = new mongoose.Types.ObjectId().toString();
      const res = await request(app)
        .post('/api/v1/services')
        .send({
          categoryId: fakeCategoryId,
          title: 'Fake Service',
          description: 'Should fail',
          price: 500,
        });

      expect(res.status).toBe(404);
      expect(res.body.success).toBe(false);
    });

    it('GET /services — should support category filtering and search', async () => {
      // Filter by category
      const catRes = await request(app).get(`/api/v1/services?categoryId=${testCategoryId}`);
      expect(catRes.status).toBe(200);
      expect(catRes.body.data.items.length).toBeGreaterThanOrEqual(1);

      // Search keyword
      const searchRes = await request(app).get('/api/v1/services?search=Brake');
      expect(searchRes.status).toBe(200);
      expect(searchRes.body.data.items.length).toBeGreaterThanOrEqual(1);
    });

    it('GET /services/:id — should retrieve service with populated category details', async () => {
      const res = await request(app).get(`/api/v1/services/${testServiceId}`);

      expect(res.status).toBe(200);
      expect(res.body.data._id).toBe(testServiceId);
      expect(res.body.data).toHaveProperty('categoryId');
      expect(res.body.data.categoryId).toHaveProperty('name');
    });
  });

  // ==========================================
  // 5. BOOKINGS API & STATUS WORKFLOW (Protected by Auth)
  // ==========================================
  describe('Bookings API — /api/v1/bookings', () => {
    it('POST /bookings — should reject vehicle ownership mismatch', async () => {
      // secondUser attempts to book testVehicleId (which belongs to testUserId)
      const res = await request(app)
        .post('/api/v1/bookings')
        .set('Authorization', `Bearer ${secondUserToken}`)
        .send({
          vehicleId: testVehicleId, // belongs to testUserId!
          serviceId: testServiceId,
          scheduledDate: new Date(Date.now() + 86400000).toISOString(),
          scheduledTime: '10:00 AM - 12:00 PM',
          serviceMode: 'doorstep',
          address: 'Test Address Line 1',
          subtotal: 1799,
          totalAmount: 2122,
        });

      expect(res.status).toBe(400);
      expect(res.body.success).toBe(false);
      expect(res.body.error.code).toBe('VEHICLE_OWNERSHIP_MISMATCH');
    });

    it('POST /bookings — should create a valid booking and auto-generate bookingNumber', async () => {
      const res = await request(app)
        .post('/api/v1/bookings')
        .set('Authorization', `Bearer ${testUserToken}`)
        .send({
          vehicleId: testVehicleId,
          serviceId: testServiceId,
          scheduledDate: new Date(Date.now() + 86400000).toISOString(),
          scheduledTime: '10:00 AM - 12:00 PM',
          serviceMode: 'doorstep',
          address: '42 MG Road, Sector 14, Gurgaon',
          subtotal: 1799,
          discount: 100,
          pickupFee: 0,
          gst: 305,
          totalAmount: 2004,
          notes: 'Customer requested front wheel inspection',
        });

      expect(res.status).toBe(201);
      expect(res.body.success).toBe(true);
      expect(res.body.data).toHaveProperty('bookingNumber');
      expect(res.body.data.bookingNumber).toMatch(/^MM-\d{4}-[A-Z0-9]+$/);
      expect(res.body.data.status).toBe('confirmed');
      testBookingId = res.body.data._id;
    });

    it('GET /bookings — should list bookings for authenticated user', async () => {
      const res = await request(app)
        .get('/api/v1/bookings')
        .set('Authorization', `Bearer ${testUserToken}`);

      expect(res.status).toBe(200);
      expect(res.body.data.items.length).toBeGreaterThanOrEqual(1);
      expect(res.body.data.items[0].userId._id).toBe(testUserId);
    });

    it('PATCH /bookings/:id/status — should transition status sequentially', async () => {
      // confirmed -> vehicle_received
      const res1 = await request(app)
        .patch(`/api/v1/bookings/${testBookingId}/status`)
        .set('Authorization', `Bearer ${testUserToken}`)
        .send({ status: 'vehicle_received' });

      expect(res1.status).toBe(200);
      expect(res1.body.data.status).toBe('vehicle_received');

      // vehicle_received -> service_in_progress
      const res2 = await request(app)
        .patch(`/api/v1/bookings/${testBookingId}/status`)
        .set('Authorization', `Bearer ${testUserToken}`)
        .send({ status: 'service_in_progress' });

      expect(res2.status).toBe(200);
      expect(res2.body.data.status).toBe('service_in_progress');

      // service_in_progress -> completed
      const res3 = await request(app)
        .patch(`/api/v1/bookings/${testBookingId}/status`)
        .set('Authorization', `Bearer ${testUserToken}`)
        .send({ status: 'completed' });

      expect(res3.status).toBe(200);
      expect(res3.body.data.status).toBe('completed');
    });

    it('PATCH /bookings/:id/status — should reject invalid transitions on terminal completed booking', async () => {
      // Attempting to reopen or cancel a completed booking must fail
      const res = await request(app)
        .patch(`/api/v1/bookings/${testBookingId}/status`)
        .set('Authorization', `Bearer ${testUserToken}`)
        .send({ status: 'cancelled' });

      expect(res.status).toBe(400);
      expect(res.body.success).toBe(false);
      expect(res.body.error.code).toBe('INVALID_STATUS_TRANSITION');
    });

    it('POST /bookings/:id/rating — should submit rating and feedback for completed booking', async () => {
      const res = await request(app)
        .post(`/api/v1/bookings/${testBookingId}/rating`)
        .set('Authorization', `Bearer ${testUserToken}`)
        .send({
          rating: 5,
          ratingCategories: ['Service Quality', 'Timeliness'],
          ratingFeedback: 'Excellent service and on-time vehicle handover!',
        });

      expect(res.status).toBe(200);
      expect(res.body.success).toBe(true);
      expect(res.body.data.isRated).toBe(true);
      expect(res.body.data.rating).toBe(5);
      expect(res.body.data.ratingCategories).toEqual(['Service Quality', 'Timeliness']);
      expect(res.body.data.ratingFeedback).toBe('Excellent service and on-time vehicle handover!');
      expect(res.body.data).toHaveProperty('ratedAt');
    });

    it('POST /bookings/:id/rating — should reject duplicate rating on already-rated booking', async () => {
      const res = await request(app)
        .post(`/api/v1/bookings/${testBookingId}/rating`)
        .set('Authorization', `Bearer ${testUserToken}`)
        .send({
          rating: 4,
          ratingCategories: ['Staff Behaviour'],
        });

      expect(res.status).toBe(400);
      expect(res.body.success).toBe(false);
      expect(res.body.error.code).toBe('ALREADY_RATED');
    });

    it('POST /bookings/:id/rating — should reject rating out of bounds', async () => {
      // Create a fresh booking to test validation failure
      const createRes = await request(app)
        .post('/api/v1/bookings')
        .set('Authorization', `Bearer ${testUserToken}`)
        .send({
          vehicleId: testVehicleId,
          serviceId: testServiceId,
          scheduledDate: new Date().toISOString(),
          scheduledTime: '11:00 AM - 01:00 PM',
          serviceMode: 'workshop',
          subtotal: 1000,
          totalAmount: 1180,
        });
      const freshBookingId = createRes.body.data._id;

      // Rating on uncompleted booking fails
      const uncompletedRes = await request(app)
        .post(`/api/v1/bookings/${freshBookingId}/rating`)
        .set('Authorization', `Bearer ${testUserToken}`)
        .send({ rating: 5 });
      expect(uncompletedRes.status).toBe(400);
      expect(uncompletedRes.body.error.code).toBe('BOOKING_NOT_COMPLETED');

      // Complete the booking
      await request(app)
        .patch(`/api/v1/bookings/${freshBookingId}/status`)
        .set('Authorization', `Bearer ${testUserToken}`)
        .send({ status: 'completed' });

      // Rating 0 or 6 must fail validation
      const outOfBoundsRes = await request(app)
        .post(`/api/v1/bookings/${freshBookingId}/rating`)
        .set('Authorization', `Bearer ${testUserToken}`)
        .send({ rating: 6 });
      expect(outOfBoundsRes.status).toBe(400);
      expect(outOfBoundsRes.body.error.code).toBe('VALIDATION_ERROR');
    });

    it('POST /bookings/:id/payment — should simulate online payment update', async () => {
      const res = await request(app)
        .post(`/api/v1/bookings/${testBookingId}/payment`)
        .set('Authorization', `Bearer ${testUserToken}`)
        .send({
          paymentMethod: 'online_upi',
          paymentStatus: 'paid',
          paymentReference: 'DEMO-UPI-TXN-12345',
        });

      expect(res.status).toBe(200);
      expect(res.body.success).toBe(true);
      expect(res.body.data.paymentMethod).toBe('online_upi');
      expect(res.body.data.paymentStatus).toBe('paid');
      expect(res.body.data.paymentReference).toBe('DEMO-UPI-TXN-12345');
      expect(res.body.data).toHaveProperty('paidAt');
    });

    it('POST /bookings/:id/payment — should reject invalid payment status', async () => {
      const res = await request(app)
        .post(`/api/v1/bookings/${testBookingId}/payment`)
        .set('Authorization', `Bearer ${testUserToken}`)
        .send({
          paymentStatus: 'unknown_status_xyz',
        });

      expect(res.status).toBe(400);
      expect(res.body.success).toBe(false);
      expect(res.body.error.code).toBe('VALIDATION_ERROR');
    });
  });

  // ==========================================
  // 6. OFFERS & COUPONS API
  // ==========================================
  describe('Offers API — /api/v1/offers', () => {
    beforeAll(async () => {
      // Seed test offers
      await Offer.deleteMany({});
      await Offer.create([
        {
          code: 'TESTFLAT500',
          title: 'Flat 500 Off',
          description: 'Flat 500 discount for test',
          discountType: 'flat',
          discountValue: 500,
          minOrderValue: 1500,
          expiryDate: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000),
          terms: ['Valid for orders >= 1500'],
          isActive: true,
        },
        {
          code: 'TESTPERCENT20',
          title: '20% Off AC Services',
          description: '20% off up to 400 for AC services',
          discountType: 'percentage',
          discountValue: 20,
          maxDiscount: 400,
          minOrderValue: 1000,
          eligibleCategory: 'AC Service & Repair',
          expiryDate: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000),
          terms: ['AC Service only'],
          isActive: true,
        },
        {
          code: 'TESTEXPIRED',
          title: 'Expired Offer',
          description: 'Expired test offer',
          discountType: 'flat',
          discountValue: 100,
          minOrderValue: 500,
          expiryDate: new Date(Date.now() - 5 * 24 * 60 * 60 * 1000),
          terms: ['Expired'],
          isActive: true,
        },
      ]);
    });

    it('GET /offers — should list active and non-expired offers', async () => {
      const res = await request(app).get('/api/v1/offers');

      expect(res.status).toBe(200);
      expect(res.body.success).toBe(true);
      expect(Array.isArray(res.body.data)).toBe(true);
      expect(res.body.data.length).toBe(2); // EXPIRED is excluded
      const codes = res.body.data.map((o: { code: string }) => o.code);
      expect(codes).toContain('TESTFLAT500');
      expect(codes).toContain('TESTPERCENT20');
      expect(codes).not.toContain('TESTEXPIRED');
    });

    it('POST /offers/validate — should successfully validate flat discount coupon', async () => {
      const res = await request(app)
        .post('/api/v1/offers/validate')
        .send({
          code: 'testflat500',
          orderAmount: 2000,
        });

      expect(res.status).toBe(200);
      expect(res.body.success).toBe(true);
      expect(res.body.data.valid).toBe(true);
      expect(res.body.data.discountAmount).toBe(500);
      expect(res.body.data.finalAmount).toBe(1500);
    });

    it('POST /offers/validate — should successfully validate percentage discount with cap', async () => {
      const res = await request(app)
        .post('/api/v1/offers/validate')
        .send({
          code: 'TESTPERCENT20',
          orderAmount: 3000, // 20% of 3000 = 600, capped at maxDiscount 400
          category: 'AC Service & Repair',
        });

      expect(res.status).toBe(200);
      expect(res.body.success).toBe(true);
      expect(res.body.data.discountAmount).toBe(400);
      expect(res.body.data.finalAmount).toBe(2600);
    });

    it('POST /offers/validate — should reject coupon when min order value is not met', async () => {
      const res = await request(app)
        .post('/api/v1/offers/validate')
        .send({
          code: 'TESTFLAT500',
          orderAmount: 1000, // min is 1500
        });

      expect(res.status).toBe(400);
      expect(res.body.success).toBe(false);
      expect(res.body.error.code).toBe('MIN_ORDER_VALUE_NOT_MET');
    });

    it('POST /offers/validate — should reject coupon when category does not match', async () => {
      const res = await request(app)
        .post('/api/v1/offers/validate')
        .send({
          code: 'TESTPERCENT20',
          orderAmount: 1500,
          category: 'Batteries',
        });

      expect(res.status).toBe(400);
      expect(res.body.success).toBe(false);
      expect(res.body.error.code).toBe('CATEGORY_NOT_ELIGIBLE');
    });

    it('POST /offers/validate — should reject expired coupon', async () => {
      const res = await request(app)
        .post('/api/v1/offers/validate')
        .send({
          code: 'TESTEXPIRED',
          orderAmount: 1000,
        });

      expect(res.status).toBe(400);
      expect(res.body.success).toBe(false);
      expect(res.body.error.code).toBe('COUPON_EXPIRED');
    });

    it('POST /offers/validate — should return 404 for unknown coupon code', async () => {
      const res = await request(app)
        .post('/api/v1/offers/validate')
        .send({
          code: 'INVALIDCODE999',
          orderAmount: 1000,
        });

      expect(res.status).toBe(404);
      expect(res.body.success).toBe(false);
      expect(res.body.error.code).toBe('NOT_FOUND');
    });
  });

  // ==========================================
  // 6.5. WORKSHOPS & HUBS API
  // ==========================================
  describe('Workshops & Hubs API', () => {
    let testWorkshopId = '';

    beforeAll(async () => {
      const workshop = await Workshop.create({
        name: 'My Mechanic Premium Car Service',
        city: 'Gurugram',
        area: 'Atul Kataria Chowk',
        address: 'Old Delhi Road, Atul Kataria Chowk, opposite Air Force Station, Gurugram, Haryana 122015',
        pincode: '122015',
        rating: 4.8,
        reviewsCount: 150,
        leadMechanic: 'Assigned upon arrival',
        phone: '+91 88269 91028',
        operatingHours: '24x7',
        isDemoSeedData: false,
        disclaimer: 'Official verified workshop location.',
        latitude: 28.491111,
        longitude: 77.0562498,
        isActive: true,
      });
      testWorkshopId = workshop._id.toString();
    });

    afterAll(async () => {
      await Workshop.deleteMany({ city: 'Gurugram' });
    });

    it('GET /workshops — should return list of active workshops', async () => {
      const res = await request(app).get('/api/v1/workshops');

      expect(res.status).toBe(200);
      expect(res.body.success).toBe(true);
      expect(Array.isArray(res.body.data)).toBe(true);
      expect(res.body.data.length).toBeGreaterThan(0);
      expect(res.body.data[0].disclaimer).toBeDefined();
    });

    it('GET /workshops?area=Atul Kataria Chowk — should filter workshops by area', async () => {
      const res = await request(app).get('/api/v1/workshops?area=Atul Kataria Chowk');

      expect(res.status).toBe(200);
      expect(res.body.success).toBe(true);
      expect(res.body.data.length).toBeGreaterThan(0);
      expect(res.body.data[0].area).toBe('Atul Kataria Chowk');
    });

    it('GET /workshops/:id — should return single workshop', async () => {
      const res = await request(app).get(`/api/v1/workshops/${testWorkshopId}`);

      expect(res.status).toBe(200);
      expect(res.body.success).toBe(true);
      expect(res.body.data._id).toBe(testWorkshopId);
      expect(res.body.data.name).toBe('My Mechanic Premium Car Service');
    });
  });

  // ==========================================
  // 6.6. IN-APP NOTIFICATIONS API
  // ==========================================
  describe('In-App Notifications API — /api/v1/notifications', () => {
    let testNotificationId = '';

    it('GET /notifications — should retrieve auto-generated notifications for user', async () => {
      const res = await request(app)
        .get('/api/v1/notifications')
        .set('Authorization', `Bearer ${testUserToken}`);

      expect(res.status).toBe(200);
      expect(res.body.success).toBe(true);
      expect(Array.isArray(res.body.data)).toBe(true);
      expect(res.body.data.length).toBeGreaterThan(0);

      // Verify notification triggered by previous booking lifecycle events
      testNotificationId = res.body.data[0]._id;
      expect(res.body.data[0].userId).toBe(testUserId);
      expect(res.body.data[0].title).toBeDefined();
    });

    it('PATCH /notifications/:id/read — should mark notification as read', async () => {
      const res = await request(app)
        .patch(`/api/v1/notifications/${testNotificationId}/read`)
        .set('Authorization', `Bearer ${testUserToken}`);

      expect(res.status).toBe(200);
      expect(res.body.success).toBe(true);
      expect(res.body.data.isRead).toBe(true);
    });

    it('PATCH /notifications/read-all — should mark all notifications as read', async () => {
      const res = await request(app)
        .patch('/api/v1/notifications/read-all')
        .set('Authorization', `Bearer ${testUserToken}`);

      expect(res.status).toBe(200);
      expect(res.body.success).toBe(true);
      expect(res.body.data).toHaveProperty('count');
    });

    it('DELETE /notifications/:id — should delete notification', async () => {
      const res = await request(app)
        .delete(`/api/v1/notifications/${testNotificationId}`)
        .set('Authorization', `Bearer ${testUserToken}`);

      expect(res.status).toBe(200);
      expect(res.body.success).toBe(true);
    });

    it('GET /notifications — should reject unauthenticated request with 401', async () => {
      const res = await request(app).get('/api/v1/notifications');
      expect(res.status).toBe(401);
    });
  });

  // ==========================================
  // 7. ERRORS, VALIDATIONS & EDGE CASES
  // ==========================================
  describe('Errors & Edge Cases', () => {
    it('should return 400 INVALID_ID for malformed MongoDB ObjectId', async () => {
      const res = await request(app).get('/api/v1/users/not-a-valid-id-123');

      expect(res.status).toBe(400);
      expect(res.body.success).toBe(false);
      expect(res.body.error.code).toBe('INVALID_ID');
    });

    it('should return 404 NOT_FOUND for non-existent valid 24-character ObjectId', async () => {
      const nonExistentId = new mongoose.Types.ObjectId().toString();
      const res = await request(app).get(`/api/v1/users/${nonExistentId}`);

      expect(res.status).toBe(404);
      expect(res.body.success).toBe(false);
      expect(res.body.error.code).toBe('NOT_FOUND');
    });

    it('DELETE /service-categories/:id — should return 409 CATEGORY_IN_USE when category has services', async () => {
      const res = await request(app).delete(`/api/v1/service-categories/${testCategoryId}`);

      expect(res.status).toBe(409);
      expect(res.body.success).toBe(false);
      expect(res.body.error.code).toBe('CATEGORY_IN_USE');
    });

    it('should return 404 for unknown API path', async () => {
      const res = await request(app).get('/api/v1/random-route-path-unknown');

      expect(res.status).toBe(404);
      expect(res.body.success).toBe(false);
      expect(res.body.error.code).toBe('NOT_FOUND');
    });
  });
});
