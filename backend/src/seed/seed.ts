import { connectDatabase, disconnectDatabase } from '../config/database';
import { User } from '../models/user.model';
import { Vehicle } from '../models/vehicle.model';
import { ServiceCategory } from '../models/serviceCategory.model';
import { Service } from '../models/service.model';
import { Booking } from '../models/booking.model';
import { Offer } from '../models/offer.model';
import { Workshop } from '../models/workshop.model';
import { logger } from '../utils/logger.util';
import { hashPassword } from '../utils/auth.util';

export async function runSeed(): Promise<void> {
  try {
    logger.info('==================================================');
    logger.info('  Starting MyMechanic Seed Script (Idempotent)    ');
    logger.info('==================================================');

    await connectDatabase();

    // 1. Seed Users (Upsert by email) with safe bcrypt password hashes
    const defaultPasswordHash = await hashPassword('Password123!');
    const demoPasswordHash = await hashPassword('DemoPassword123!');

    const usersData = [
      {
        name: 'Demo User',
        email: 'demo@mymechanic.local',
        phone: '+919999988888',
        passwordHash: demoPasswordHash,
        profileImage: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&w=200&q=80',
      },
      {
        name: 'Rahul Sharma',
        email: 'rahul.sharma@example.com',
        phone: '+919876543210',
        passwordHash: defaultPasswordHash,
        profileImage: 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?auto=format&fit=crop&w=200&q=80',
      },
      {
        name: 'Priya Patel',
        email: 'priya.patel@example.com',
        phone: '+919812345678',
        passwordHash: defaultPasswordHash,
        profileImage: 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?auto=format&fit=crop&w=200&q=80',
      },
    ];

    const usersMap: Record<string, string> = {};
    for (const u of usersData) {
      let user = await User.findOne({ email: u.email });
      if (!user) {
        user = await User.create(u);
        logger.info(`[User] Created: ${u.name} (${u.email})`);
      } else {
        user.name = u.name;
        user.phone = u.phone;
        user.passwordHash = u.passwordHash;
        user.profileImage = u.profileImage;
        user.isActive = true;
        await user.save();
        logger.info(`[User] Updated: ${u.name} (${u.email})`);
      }
      usersMap[u.name] = user._id.toString();
    }

    // 2. Seed Vehicles (Upsert by userId + registrationNumber)
    const vehiclesData = [
      {
        userName: 'Rahul Sharma',
        make: 'Hyundai',
        model: 'Creta',
        variant: 'SX (O) 1.5 Petrol',
        registrationNumber: 'DL-01-AB-1234',
        fuelType: 'Petrol',
        year: 2022,
        isActive: true,
      },
      {
        userName: 'Rahul Sharma',
        make: 'Maruti Suzuki',
        model: 'Swift',
        variant: 'ZXi AMT',
        registrationNumber: 'DL-04-CD-5678',
        fuelType: 'Diesel',
        year: 2020,
        isActive: false,
      },
      {
        userName: 'Priya Patel',
        make: 'Tata',
        model: 'Nexon EV',
        variant: 'Max Empowered+',
        registrationNumber: 'MH-02-EF-9012',
        fuelType: 'Electric',
        year: 2023,
        isActive: true,
      },
    ];

    const vehiclesMap: Record<string, string> = {};
    for (const v of vehiclesData) {
      const userId = usersMap[v.userName];
      let vehicle = await Vehicle.findOne({
        userId,
        registrationNumber: v.registrationNumber,
      });

      if (!vehicle) {
        vehicle = await Vehicle.create({
          userId,
          make: v.make,
          model: v.model,
          variant: v.variant,
          registrationNumber: v.registrationNumber,
          fuelType: v.fuelType,
          year: v.year,
          isActive: v.isActive,
        });
        logger.info(`[Vehicle] Created: ${v.make} ${v.model} (${v.registrationNumber})`);
      } else {
        vehicle.make = v.make;
        vehicle.set('model', v.model);
        vehicle.variant = v.variant;
        vehicle.fuelType = v.fuelType as 'Petrol' | 'Diesel' | 'Electric' | 'CNG' | 'Hybrid';
        vehicle.year = v.year;
        vehicle.isActive = v.isActive;
        await vehicle.save();
        logger.info(`[Vehicle] Updated: ${v.make} ${v.model} (${v.registrationNumber})`);
      }
      vehiclesMap[v.registrationNumber] = vehicle._id.toString();
    }

    // 3. Seed Service Categories (Upsert by name)
    const categoriesData = [
      {
        name: 'Periodic Services',
        description: 'Scheduled maintenance, oil change, filters, fluid top-up & comprehensive inspections',
        icon: 'build_circle',
        sortOrder: 1,
      },
      {
        name: 'AC Service & Repair',
        description: 'Gas refill, condenser cleaning, cooling coil diagnosis & cabin air sanitization',
        icon: 'ac_unit',
        sortOrder: 2,
      },
      {
        name: 'Batteries',
        description: 'Jumpstart, terminal cleanup, battery testing and genuine doorstep replacements',
        icon: 'battery_charging_full',
        sortOrder: 3,
      },
      {
        name: 'Tyres & Wheel Care',
        description: '3D computerized wheel alignment, wheel balancing, rotation & puncture repair',
        icon: 'tire_repair',
        sortOrder: 4,
      },
      {
        name: 'Denting & Painting',
        description: 'Paint booth restoration, scratch removal, panel repairs and grade-A clear coat',
        icon: 'format_paint',
        sortOrder: 5,
      },
      {
        name: 'Car Spa & Cleaning',
        description: 'Deep interior vacuuming, foam wash, wax polishing and ceramic protection',
        icon: 'local_car_wash',
        sortOrder: 6,
      },
      {
        name: 'Inspections',
        description: 'Pre-purchase checkups, roadworthiness diagnostics and computerized engine scan',
        icon: 'checklist',
        sortOrder: 7,
      },
      {
        name: 'Windshield & Lights',
        description: 'Door glass replacement, windshield installation, headlight restoration & illumination repair',
        icon: 'lightbulb',
        sortOrder: 8,
      },
    ];

    const categoriesMap: Record<string, string> = {};
    for (const c of categoriesData) {
      let category = await ServiceCategory.findOne({ name: c.name });
      if (!category) {
        category = await ServiceCategory.create({
          name: c.name,
          description: c.description,
          icon: c.icon,
          sortOrder: c.sortOrder,
          isActive: true,
        });
        logger.info(`[Category] Created: ${c.name}`);
      } else {
        category.description = c.description;
        category.icon = c.icon;
        category.sortOrder = c.sortOrder;
        category.isActive = true;
        await category.save();
        logger.info(`[Category] Updated: ${c.name}`);
      }
      categoriesMap[c.name] = category._id.toString();
    }

    // 4. Seed Services (Upsert by title)
    const servicesData = [
      {
        categoryName: 'Periodic Services',
        title: 'Standard Periodic Service',
        description: 'Essential preventive servicing recommended every 10,000 km or 12 months for smooth engine performance.',
        price: 3499,
        originalPrice: 4299,
        durationText: '3-4 Hours',
        rating: 4.8,
        reviewCount: 240,
        warrantyPeriod: '1000 Kms or 1 Month',
        includedItems: [
          'Engine Oil Replacement (Castrol / Shell)',
          'Oil Filter Replacement (Genuine OEM)',
          'Air Filter Cleaning',
          'Coolant & Wiper Fluid Top-up',
          'Battery Water Check & Terminal Grease',
          '50-Point Safety Checkup',
        ],
        excludedItems: ['AC Filter Replacement', 'Wheel Balancing Weights'],
      },
      {
        categoryName: 'Periodic Services',
        title: 'Comprehensive Service Package',
        description: 'Full bumper-to-bumper car rejuvenation for complete peace of mind, improved fuel economy and safety.',
        price: 5999,
        originalPrice: 7499,
        durationText: '5-6 Hours',
        rating: 4.9,
        reviewCount: 185,
        warrantyPeriod: '5000 Kms or 6 Months',
        includedItems: [
          '100% Synthetic Engine Oil',
          'Oil, Air & Fuel Filter Replacement',
          'Cabin AC Filter Replacement',
          'All 4 Brake Pads Cleaning & Caliper Greasing',
          'Coolant Drain & Refill',
          'Front & Rear Wheel Balancing',
          'Deep Interior Vacuum & Dashboard Polish',
          '60-Point Diagnostic Scan',
        ],
        excludedItems: ['Brake Pad Replacement if worn out'],
      },
      {
        categoryName: 'AC Service & Repair',
        title: 'Complete AC Service',
        description: 'High-performance AC cleaning, leak check and precision gas refilling for ice-cold cooling.',
        price: 1999,
        originalPrice: 2499,
        durationText: '2-3 Hours',
        rating: 4.7,
        reviewCount: 120,
        warrantyPeriod: '3 Months Cooling Warranty',
        includedItems: [
          'AC Gas Refill (R134a up to 400g)',
          'AC Filter Cleaning & Sanitization',
          'Condenser Jet Wash & Dirt Removal',
          'Cooling Coil Inspection',
          'AC Vent Anti-Bacterial Fogging',
        ],
        excludedItems: ['Compressor Repair or Replacement'],
      },
      {
        categoryName: 'Tyres & Wheel Care',
        title: 'Wheel Alignment & 4-Wheel Balancing',
        description: 'Computerized laser calibration to eliminate steering vibrations, uneven tyre wear and pulling.',
        price: 899,
        originalPrice: 1199,
        durationText: '1-2 Hours',
        rating: 4.8,
        reviewCount: 95,
        warrantyPeriod: '1000 Kms Warranty',
        includedItems: [
          '3D Computerized Laser Wheel Alignment',
          'All 4 Wheels Dynamic Balancing',
          'Weight Inclusions (up to 100g total)',
          'Tyre Rotation & Tread Depth Analysis',
        ],
        excludedItems: ['Tyre Replacement'],
      },
      {
        categoryName: 'Car Spa & Cleaning',
        title: 'Deep Ceramic Shield Spa',
        description: 'Intense exterior foam bath, paint de-contamination, machine glaze polish and interior steam sanitization.',
        price: 3899,
        originalPrice: 4999,
        durationText: '4-5 Hours',
        rating: 4.9,
        reviewCount: 78,
        warrantyPeriod: '6 Months Glaze Protection',
        includedItems: [
          'pH-Neutral Exterior Foam Wash & Undercarriage Spray',
          'Clay Bar Paint Decontamination',
          'Machine Glaze Compound & Mirror Polish',
          'Ceramic Protective Sealant Coat',
          'Complete Interior Deep Vacuuming & Upholstery Steam Clean',
        ],
        excludedItems: ['Dent Repairs'],
      },
      {
        categoryName: 'Inspections',
        title: 'Car Inspection / Diagnostics',
        description: 'Comprehensive computer diagnostics, ECU system scan, and multi-point vehicle safety evaluation. Website-listed starting price from ₹499; final quote varies by vehicle make and condition.',
        price: 499,
        originalPrice: 499,
        durationText: '1-2 Hours',
        rating: 4.8,
        reviewCount: 320,
        warrantyPeriod: 'Applicable Service Conditions / 30 Days Warranty',
        includedItems: [
          'Complete OBD-II Diagnostic Scan',
          'Battery & Alternator Output Check',
          'Brake & Suspension Visual Inspection',
          'Fluid Condition & Leak Analysis',
        ],
        excludedItems: [
          'Major mechanical repairs or part replacements',
          'Final quote subject to vehicle make, model, and diagnostic findings',
        ],
      },
      {
        categoryName: 'Windshield & Lights',
        title: 'Door Glass Replacement',
        description: 'Factory-grade OEM/OES door glass replacement with precision fitting and regulator calibration. Website-listed starting price from ₹850; final quote depends on car segment and glass specifications.',
        price: 850,
        originalPrice: 850,
        durationText: '2 Hours',
        rating: 4.8,
        reviewCount: 210,
        warrantyPeriod: 'Applicable Service Conditions / 30 Days Warranty',
        includedItems: [
          '100% Genuine OEM/OES Door Glass Unit',
          'Professional Removal & Safe Installation',
          'Channel Weatherstrip Realignment',
          'Vacuuming of Glass Debris Inside Door Cavity',
        ],
        excludedItems: [
          'Power window motor replacement if defective',
          'Final quote subject to vehicle make, model, and glass variant',
        ],
      },
    ];

    const servicesMap: Record<string, string> = {};
    for (const s of servicesData) {
      const categoryId = categoriesMap[s.categoryName];
      let service = await Service.findOne({ title: s.title });
      if (!service) {
        service = await Service.create({
          categoryId,
          title: s.title,
          description: s.description,
          price: s.price,
          originalPrice: s.originalPrice,
          durationText: s.durationText,
          rating: s.rating,
          reviewCount: s.reviewCount,
          warrantyPeriod: s.warrantyPeriod,
          includedItems: s.includedItems,
          excludedItems: s.excludedItems,
          isActive: true,
        });
        logger.info(`[Service] Created: ${s.title} (₹${s.price})`);
      } else {
        service.categoryId = categoryId as any;
        service.description = s.description;
        service.price = s.price;
        service.originalPrice = s.originalPrice;
        service.durationText = s.durationText;
        service.rating = s.rating;
        service.reviewCount = s.reviewCount;
        service.warrantyPeriod = s.warrantyPeriod;
        service.includedItems = s.includedItems;
        service.excludedItems = s.excludedItems;
        service.isActive = true;
        await service.save();
        logger.info(`[Service] Updated: ${s.title}`);
      }
      servicesMap[s.title] = service._id.toString();
    }

    // 5. Seed Bookings (Upsert by bookingNumber)
    const bookingsData = [
      {
        bookingNumber: 'MM-2026-7842',
        userName: 'Rahul Sharma',
        vehicleReg: 'DL-01-AB-1234',
        serviceTitle: 'Standard Periodic Service',
        scheduledDate: new Date(Date.now() + 24 * 60 * 60 * 1000), // Tomorrow
        scheduledTime: '10:00 AM - 12:00 PM',
        serviceMode: 'doorstep' as const,
        address: 'B-42 Green Park Extension, New Delhi - 110016',
        couponCode: 'MYFIRST200',
        subtotal: 3499,
        discount: 200,
        pickupFee: 0,
        gst: 593,
        totalAmount: 3892,
        status: 'service_in_progress' as const,
        notes: 'Please check rear brake squeaking sound during inspection.',
      },
      {
        bookingNumber: 'MM-2026-5120',
        userName: 'Rahul Sharma',
        vehicleReg: 'DL-01-AB-1234',
        serviceTitle: 'Complete AC Service',
        scheduledDate: new Date(Date.now() - 14 * 24 * 60 * 60 * 1000), // 14 days ago
        scheduledTime: '02:00 PM - 04:00 PM',
        serviceMode: 'workshop' as const,
        subtotal: 1999,
        discount: 0,
        pickupFee: 0,
        gst: 359,
        totalAmount: 2358,
        status: 'completed' as const,
        notes: 'AC cooling restored to optimal temperature.',
      },
      {
        bookingNumber: 'MM-2026-9031',
        userName: 'Priya Patel',
        vehicleReg: 'MH-02-EF-9012',
        serviceTitle: 'Wheel Alignment & 4-Wheel Balancing',
        scheduledDate: new Date(Date.now() + 3 * 24 * 60 * 60 * 1000), // In 3 days
        scheduledTime: '11:00 AM - 01:00 PM',
        serviceMode: 'workshop' as const,
        subtotal: 899,
        discount: 0,
        pickupFee: 0,
        gst: 161,
        totalAmount: 1060,
        status: 'confirmed' as const,
        notes: 'Check front right tire balance.',
      },
    ];

    for (const b of bookingsData) {
      const userId = usersMap[b.userName];
      const vehicleId = vehiclesMap[b.vehicleReg];
      const serviceId = servicesMap[b.serviceTitle];

      let booking = await Booking.findOne({ bookingNumber: b.bookingNumber });
      if (!booking) {
        booking = await Booking.create({
          userId,
          vehicleId,
          serviceId,
          bookingNumber: b.bookingNumber,
          scheduledDate: b.scheduledDate,
          scheduledTime: b.scheduledTime,
          serviceMode: b.serviceMode,
          address: b.address,
          couponCode: b.couponCode,
          subtotal: b.subtotal,
          discount: b.discount,
          pickupFee: b.pickupFee,
          gst: b.gst,
          totalAmount: b.totalAmount,
          status: b.status,
          notes: b.notes,
        });
        logger.info(`[Booking] Created: ${b.bookingNumber} (${b.status})`);
      } else {
        booking.scheduledDate = b.scheduledDate;
        booking.scheduledTime = b.scheduledTime;
        booking.status = b.status;
        await booking.save();
        logger.info(`[Booking] Updated: ${b.bookingNumber} (${b.status})`);
      }
    }

    // 6. Seed Offers / Coupons (Upsert by code)
    const offersData = [
      {
        code: 'MYFIRST500',
        title: 'First Service Discount',
        description: 'Flat ₹500 off on your first car service appointment.',
        discountType: 'flat' as const,
        discountValue: 500,
        minOrderValue: 1499,
        expiryDate: new Date(Date.now() + 60 * 24 * 60 * 60 * 1000),
        terms: [
          'Valid for orders ₹1,499 and above.',
          'Applicable on all periodic and general service packages.',
          'One-time use per customer.',
        ],
        isActive: true,
      },
      {
        code: 'COOLCHILL25',
        title: 'Summer AC Chill 25%',
        description: '25% discount up to ₹750 on car air conditioning services.',
        discountType: 'percentage' as const,
        discountValue: 25,
        maxDiscount: 750,
        minOrderValue: 1999,
        expiryDate: new Date(Date.now() + 45 * 24 * 60 * 60 * 1000),
        eligibleCategory: 'AC Service & Repair',
        terms: [
          'Valid only on AC Service & Repair category.',
          'Maximum discount ₹750.',
          'Minimum order value ₹1,999.',
        ],
        isActive: true,
      },
      {
        code: 'PERIODIC300',
        title: 'Periodic Maintenance Saver',
        description: 'Flat ₹300 off on scheduled periodic maintenance.',
        discountType: 'flat' as const,
        discountValue: 300,
        minOrderValue: 2500,
        expiryDate: new Date(Date.now() + 45 * 24 * 60 * 60 * 1000),
        eligibleCategory: 'Periodic Services',
        terms: [
          'Valid only for Periodic Services category.',
          'Minimum order value ₹2,500.',
        ],
        isActive: true,
      },
      {
        code: 'SPASPECIAL',
        title: 'Car Spa & Detailing 20%',
        description: '20% discount up to ₹400 on car wash and interior sanitization.',
        discountType: 'percentage' as const,
        discountValue: 20,
        maxDiscount: 400,
        minOrderValue: 999,
        expiryDate: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000),
        eligibleCategory: 'Car Spa & Detailing',
        terms: [
          'Valid only on Car Spa & Detailing category.',
          'Maximum discount ₹400.',
          'Minimum order value ₹999.',
        ],
        isActive: true,
      },
      {
        code: 'BATTERY200',
        title: 'Battery Replacement Deal',
        description: 'Flat ₹200 off on OEM vehicle battery replacement.',
        discountType: 'flat' as const,
        discountValue: 200,
        minOrderValue: 2500,
        expiryDate: new Date(Date.now() + 45 * 24 * 60 * 60 * 1000),
        eligibleCategory: 'Batteries',
        terms: [
          'Valid on Batteries category.',
          'Minimum order value ₹2,500.',
        ],
        isActive: true,
      },
      {
        code: 'SEASONAL15',
        title: 'Festive Season Savings',
        description: '15% discount up to ₹600 on all repairs & maintenance.',
        discountType: 'percentage' as const,
        discountValue: 15,
        maxDiscount: 600,
        minOrderValue: 1800,
        expiryDate: new Date(Date.now() + 60 * 24 * 60 * 60 * 1000),
        terms: [
          'Maximum discount ₹600.',
          'Minimum order value ₹1,800.',
        ],
        isActive: true,
      },
      {
        code: 'BIGSAVER10',
        title: 'Big Saver 10%',
        description: '10% off up to ₹1,000 on orders over ₹3,000.',
        discountType: 'percentage' as const,
        discountValue: 10,
        maxDiscount: 1000,
        minOrderValue: 3000,
        expiryDate: new Date(Date.now() + 90 * 24 * 60 * 60 * 1000),
        terms: [
          'Maximum discount ₹1,000.',
          'Minimum order value ₹3,000.',
        ],
        isActive: true,
      },
    ];

    for (const o of offersData) {
      let offer = await Offer.findOne({ code: o.code });
      if (!offer) {
        offer = await Offer.create(o);
        logger.info(`[Offer] Created: ${o.code} (${o.title})`);
      } else {
        offer.title = o.title;
        offer.description = o.description;
        offer.discountType = o.discountType;
        offer.discountValue = o.discountValue;
        offer.maxDiscount = o.maxDiscount;
        offer.minOrderValue = o.minOrderValue;
        offer.expiryDate = o.expiryDate;
        offer.eligibleCategory = o.eligibleCategory;
        offer.terms = o.terms;
        offer.isActive = o.isActive;
        await offer.save();
        logger.info(`[Offer] Updated: ${o.code} (${o.title})`);
      }
    }

    // 7. Seed Official Verified Workshop (My Mechanic Premium Car Service, Gurugram)
    // Safely deactivate legacy demo Bangalore workshops so they never appear in customer-facing queries
    await Workshop.updateMany(
      {
        name: {
          $in: [
            'MyMechanic Flagship Hub, Koramangala',
            'MyMechanic Express Center, Indiranagar',
            'MyMechanic Tech Hub, Whitefield',
          ],
        },
      },
      { $set: { isActive: false, isDemoSeedData: true } }
    );

    const workshopsData = [
      {
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
      },
    ];

    for (const w of workshopsData) {
      let workshop = await Workshop.findOne({ name: w.name });
      if (!workshop) {
        workshop = await Workshop.create(w);
        logger.info(`[Workshop] Created: ${w.name} [Official Verified]`);
      } else {
        workshop.city = w.city;
        workshop.area = w.area;
        workshop.address = w.address;
        workshop.pincode = w.pincode;
        workshop.rating = w.rating;
        workshop.reviewsCount = w.reviewsCount;
        workshop.leadMechanic = w.leadMechanic;
        workshop.phone = w.phone;
        workshop.operatingHours = w.operatingHours;
        workshop.isDemoSeedData = w.isDemoSeedData;
        workshop.disclaimer = w.disclaimer;
        workshop.latitude = w.latitude;
        workshop.longitude = w.longitude;
        workshop.isActive = w.isActive;
        await workshop.save();
        logger.info(`[Workshop] Updated: ${w.name} [Official Verified]`);
      }
    }

    logger.info('==================================================');
    logger.info('  MyMechanic Database Seed Completed Successfully ');
    logger.info('==================================================');
  } catch (error) {
    logger.error('Failed to run seed script:', error);
    process.exit(1);
  } finally {
    await disconnectDatabase();
  }
}

if (require.main === module) {
  runSeed();
}
