import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../models/vehicle.dart';
import '../models/service_category.dart';
import '../models/service_item.dart';
import '../models/service_package.dart';
import '../models/offer.dart';
import '../models/booking.dart';
import '../models/coupon.dart';
import '../models/notification_item.dart';
import '../models/workshop.dart';

class MockData {
  /// Canonical guest vehicles displayed when unauthenticated.
  static List<Vehicle> get guestVehicles => [
    Vehicle(
      id: 'v1',
      brand: 'Hyundai',
      model: 'Creta',
      variant: '1.5 SX(O)',
      fuelType: 'Petrol',
      registrationNumber: 'KA 01 MJ 4521',
      year: 2022,
      serviceDueStatus: 'Due in 12 days',
      isPrimary: true,
      lastServiceTitle: 'Standard Periodic Service',
      lastServiceDate: DateTime.now().subtract(const Duration(days: 45)),
      nextServiceTitle: 'Periodic Service',
      nextServiceDueDate: DateTime.now().add(const Duration(days: 12)),
      nextServiceMileage: '30,000 km',
      reminderStatus: 'Due Soon',
    ),
    Vehicle(
      id: 'v2',
      brand: 'Maruti Suzuki',
      model: 'Swift',
      variant: 'ZXi AMT',
      fuelType: 'Petrol',
      registrationNumber: 'DL 03 CA 9812',
      year: 2021,
      serviceDueStatus: 'Due in 5 days',
      isPrimary: false,
      lastServiceTitle: 'Deep Interior Spa & Sanitization',
      lastServiceDate: DateTime.now().subtract(const Duration(days: 12)),
      nextServiceTitle: 'AC Service & Gas Refill',
      nextServiceDueDate: DateTime.now().add(const Duration(days: 5)),
      nextServiceMileage: '25,000 km',
      reminderStatus: 'Due Soon',
    ),
    Vehicle(
      id: 'v3',
      brand: 'Tata',
      model: 'Nexon EV',
      variant: 'Fearless+',
      fuelType: 'Electric',
      registrationNumber: 'MH 02 FE 1109',
      year: 2023,
      serviceDueStatus: 'Up to date',
      isPrimary: false,
      lastServiceTitle: 'Pre-Purchase Used Car 150-Point Inspection',
      lastServiceDate: DateTime.now().subtract(const Duration(days: 90)),
      nextServiceTitle: 'Scheduled Annual Inspection',
      nextServiceDueDate: DateTime.now().add(const Duration(days: 60)),
      nextServiceMileage: '15,000 km',
      reminderStatus: 'Scheduled',
    ),
  ];

  // Current user's registered vehicles (or guest vehicles when unauthenticated)
  static List<Vehicle> vehicles = List.from(guestVehicles);

  /// Reactive notifier for vehicle changes
  static final ValueNotifier<List<Vehicle>> vehiclesNotifier =
      ValueNotifier<List<Vehicle>>(List.from(vehicles));

  /// Resets vehicle state to the default guest experience and notifies listeners.
  static void resetToGuestVehicles() {
    vehicles = List.from(guestVehicles);
    vehiclesNotifier.value = List.from(vehicles);
  }

  /// Gets the currently selected active vehicle
  static Vehicle get activeVehicle {
    return vehicles.firstWhere(
      (v) => v.isPrimary,
      orElse: () => vehicles.isNotEmpty
          ? vehicles.first
          : const Vehicle(
              id: 'v_default',
              brand: 'Hyundai',
              model: 'Creta',
              variant: '1.5 SX',
              fuelType: 'Petrol',
              registrationNumber: 'KA 01 MJ 4521',
              year: 2022,
              serviceDueStatus: 'Up to date',
              isPrimary: true,
            ),
    );
  }

  /// Sets the active vehicle by id and notifies listeners
  static void setActiveVehicle(String id) {
    for (int i = 0; i < vehicles.length; i++) {
      vehicles[i] = vehicles[i].copyWith(isPrimary: vehicles[i].id == id);
    }
    vehiclesNotifier.value = List.from(vehicles);
  }

  /// Adds a new vehicle to the user's garage
  static void addVehicle(Vehicle vehicle) {
    if (vehicle.isPrimary || vehicles.isEmpty) {
      for (int i = 0; i < vehicles.length; i++) {
        vehicles[i] = vehicles[i].copyWith(isPrimary: false);
      }
    }
    vehicles.add(vehicle);
    vehiclesNotifier.value = List.from(vehicles);
  }

  /// Updates an existing vehicle in the user's garage
  static void updateVehicle(Vehicle updated) {
    final index = vehicles.indexWhere((v) => v.id == updated.id);
    if (index != -1) {
      if (updated.isPrimary) {
        for (int i = 0; i < vehicles.length; i++) {
          vehicles[i] = vehicles[i].copyWith(isPrimary: false);
        }
      }
      vehicles[index] = updated;
      vehiclesNotifier.value = List.from(vehicles);
    }
  }

  /// Deletes a vehicle by id. Returns false if vehicle is the last remaining one.
  static bool deleteVehicle(String id) {
    if (vehicles.length <= 1) {
      return false;
    }
    final toDelete = vehicles.firstWhere((v) => v.id == id, orElse: () => vehicles.first);
    final wasPrimary = toDelete.isPrimary;
    vehicles.removeWhere((v) => v.id == id);
    if (wasPrimary && vehicles.isNotEmpty) {
      vehicles[0] = vehicles[0].copyWith(isPrimary: true);
    }
    vehiclesNotifier.value = List.from(vehicles);
    return true;
  }


  // Core service categories
  static const List<ServiceCategory> categories = [
    ServiceCategory(
      id: 'cat_periodic',
      name: 'Periodic Services',
      description: 'Scheduled maintenance, oil change & checkup',
      icon: Icons.build_circle_outlined,
      tintColor: AppColors.categoryRed,
      backgroundColor: AppColors.categoryRedBg,
      badgeText: 'Most Popular',
    ),
    ServiceCategory(
      id: 'cat_ac',
      name: 'AC Service & Repair',
      description: 'Gas refill, condenser cooling & deep cleanup',
      icon: Icons.ac_unit_rounded,
      tintColor: AppColors.categoryBlue,
      backgroundColor: AppColors.categoryBlueBg,
      badgeText: 'Summer Special',
    ),
    ServiceCategory(
      id: 'cat_brakes',
      name: 'Clutch & Brakes',
      description: 'Disc replacement, pads, fluid bleeding',
      icon: Icons.airline_seat_recline_extra_rounded,
      tintColor: AppColors.categoryRed,
      backgroundColor: AppColors.categoryRedBg,
    ),
    ServiceCategory(
      id: 'cat_engine',
      name: 'Engine Service',
      description: 'Decarbonization, coolant flush & diagnostics',
      icon: Icons.speed_rounded,
      tintColor: AppColors.categoryAmber,
      backgroundColor: AppColors.categoryAmberBg,
    ),
    ServiceCategory(
      id: 'cat_battery',
      name: 'Batteries',
      description: 'Jumpstart, free doorstep check & warranty',
      icon: Icons.battery_charging_full_rounded,
      tintColor: AppColors.categoryAmber,
      backgroundColor: AppColors.categoryAmberBg,
    ),
    ServiceCategory(
      id: 'cat_tyres',
      name: 'Tyres & Wheels',
      description: 'Balancing, alignment & tyre replacements',
      icon: Icons.tire_repair_rounded,
      tintColor: AppColors.categoryGreen,
      backgroundColor: AppColors.categoryGreenBg,
    ),
    ServiceCategory(
      id: 'cat_spa',
      name: 'Car Spa & Detailing',
      description: 'Foam wash, ceramic coat & interior spa',
      icon: Icons.local_car_wash_rounded,
      tintColor: AppColors.categoryTeal,
      backgroundColor: AppColors.categoryTealBg,
    ),
    ServiceCategory(
      id: 'cat_denting',
      name: 'Denting & Painting',
      description: 'Grade-A paint booths & dent removal',
      icon: Icons.format_paint_rounded,
      tintColor: AppColors.categoryPurple,
      backgroundColor: AppColors.categoryPurpleBg,
      badgeText: '100% Match',
    ),
    ServiceCategory(
      id: 'cat_electrical',
      name: 'Electrical',
      description: 'Starter motor, alternator & OBD scan',
      icon: Icons.electric_bolt_rounded,
      tintColor: AppColors.categoryBlue,
      backgroundColor: AppColors.categoryBlueBg,
    ),
    ServiceCategory(
      id: 'cat_inspection',
      name: 'Inspection',
      description: 'Pre-purchase & safety trip checkup',
      icon: Icons.fact_check_outlined,
      tintColor: AppColors.categoryGreen,
      backgroundColor: AppColors.categoryGreenBg,
    ),
    ServiceCategory(
      id: 'cat_lights',
      name: 'Windshield & Lights',
      description: 'OEM glasses, headlight restoration',
      icon: Icons.lightbulb_outline_rounded,
      tintColor: AppColors.categoryBlue,
      backgroundColor: AppColors.categoryBlueBg,
    ),
  ];

  // Complete catalog of individual services across all categories
  static const List<ServiceItem> allServices = [
    // 1. Periodic Services
    ServiceItem(
      id: 'srv_periodic_1',
      categoryId: 'cat_periodic',
      title: 'Standard Periodic Service',
      description: 'Comprehensive 10,000 Kms scheduled maintenance with 100% synthetic engine oil replacement & 50-point diagnostic check.',
      price: 3699,
      originalPrice: 5199,
      durationText: '4 Hours',
      rating: 4.9,
      reviewsCount: 3820,
      warrantyPeriod: '5000 Kms / 3 Months Warranty',
      keyFeatures: [
        '100% Fully Synthetic Engine Oil (4L)',
        'OEM Oil Filter & Air Filter Replacement',
        'Brake Fluid & Radiator Coolant Top-up',
        'Spark Plug & Caliper Cleaning',
        '50-Point Digital Health Scan Report',
        'Free Exterior Foam Wash & Interior Vacuuming',
      ],
      isPopular: true,
      serviceType: 'Periodic Maintenance',
      includedItems: [
        'Engine Oil Replacement (Castrol/Shell Fully Synthetic 4L)',
        'OEM Genuine Oil Filter Replacement',
        'Air Filter Cleaning / Replacement',
        'Coolant & Wiper Fluid Top-up',
        'Brake Pad Inspection & Caliper Greasing',
        'Battery Terminal Inspection & Greasing',
        '50-Point Digital Safety Health Check',
        'Exterior Foam Wash & High-Pressure Underbody Rinse',
      ],
      excludedItems: [
        'Spark plug replacement (charged additionally if worn)',
        'Transmission gear oil change',
        'AC gas refill or cooling coil overhaul',
        'Internal engine valve clearance tuning',
      ],
      benefits: [
        '100% Genuine OEM / OES Spares',
        'Smooth Engine Performance & Mileage Boost',
        'Free Doorstep Pick-up and Drop',
        'Free 5000 Kms / 3 Months Service Warranty',
      ],
      processSteps: [
        'Step 1: Arrival & Initial 50-Point Digital Inspection',
        'Step 2: Engine Oil Drainage & Filter Installation',
        'Step 3: Brake Assembly Cleaning & Caliper Lubrication',
        'Step 4: Quality Road Trial & Exterior Clean Handover',
      ],
      faqs: [
        {
          'q': 'How often should I book a Standard Periodic Service?',
          'a': 'We recommend this service every 10,000 km or 6 months, whichever comes earlier, to preserve engine warranty and mileage.',
        },
        {
          'q': 'Which engine oil grade is used?',
          'a': 'We use high-grade 5W-30 or 5W-40 100% Fully Synthetic Oil matching your vehicle manufacturer specifications.',
        },
        {
          'q': 'Is pickup and drop included in this price?',
          'a': 'Yes, doorstep pickup & drop is available at no extra booking fee across all service hubs.',
        },
      ],
      packageIds: ['pkg_basic', 'pkg_standard', 'pkg_comprehensive'],
    ),
    ServiceItem(
      id: 'srv_periodic_2',
      categoryId: 'cat_periodic',
      title: 'Basic Scheduled Oil & Filter Service',
      description: 'Essential regular lubrication and safety check for daily commuter cars.',
      price: 2199,
      originalPrice: 2999,
      durationText: '2.5 Hours',
      rating: 4.7,
      reviewsCount: 1640,
      warrantyPeriod: '1000 Kms / 1 Month Warranty',
      keyFeatures: [
        'Premium Engine Oil Replacement',
        'Oil Filter Replacement',
        'Air Filter & AC Cabin Filter Cleansing',
        'Coolant & Wiper Fluid Top-up',
        '25-Point Vital Systems Inspection',
      ],
      isPopular: false,
      serviceType: 'Routine Maintenance',
      includedItems: [
        'Semi-Synthetic Engine Oil Replacement (3.5L)',
        'OEM Spec Oil Filter Replacement',
        'Air Filter Cleanout',
        'Windshield Washer & Radiator Coolant Top-up',
        '25-Point Quick Safety Inspection',
      ],
      excludedItems: [
        'Brake caliper dismantling & greasing',
        'AC filter replacement',
        'Wheel alignment & balancing',
      ],
      benefits: [
        'Affordable Routine Upkeep',
        'Prevents Engine Wear',
        'Quick 2.5-Hour Turnaround',
      ],
      processSteps: [
        'Step 1: Fluid Level & Filter Assessment',
        'Step 2: Oil Sump Drainage & Filter Fitting',
        'Step 3: Vital System Checks & Final Handover',
      ],
      faqs: [
        {
          'q': 'When is Basic Service recommended?',
          'a': 'Ideal every 5,000 km or 3 months between major services for high-commute city driving.',
        },
      ],
    ),
    ServiceItem(
      id: 'srv_periodic_3',
      categoryId: 'cat_periodic',
      title: 'Comprehensive Master Overhaul Service',
      description: 'Complete 20,000 Kms bumper-to-bumper factory-grade service with throttle body decarb & brake fluid flush.',
      price: 6499,
      originalPrice: 8999,
      durationText: '6 Hours',
      rating: 4.9,
      reviewsCount: 920,
      warrantyPeriod: '10000 Kms / 6 Months Warranty',
      keyFeatures: [
        'Full Synthetic Oil + Engine Flush',
        'All Filters (Oil, Air, AC Cabin) Replaced',
        'Coolant Replacement & Brake Fluid Bleed',
        'Fuel Injector & Throttle Body Cleaning',
        '3D Wheel Alignment & Balancing Included',
        'Complete Interior Deep Spa & Polish',
      ],
      isPopular: true,
      serviceType: 'Master Service',
      includedItems: [
        'Castrol EDGE Fully Synthetic Engine Oil',
        'OEM Oil Filter, Air Filter, & PM2.5 AC Filter',
        'Coolant Flush & Complete Refill',
        'Hydraulic Brake Fluid Flush & Line Bleed',
        'Electronic Throttle Body Decarbonization',
        'Front & Rear Brake Overhaul',
        '3D Laser Alignment & Dynamic Balancing (4 Wheels)',
        'Interior Deep Spa & 3M Machine Polish',
      ],
      excludedItems: [
        'Clutch plate or flywheel replacement',
        'Suspension strut replacement',
      ],
      benefits: [
        'Restores Factory Engine Bite & Mileage',
        'Comprehensive 10,000 Kms Peace of Mind',
        'Full Detail Polish Included',
      ],
      processSteps: [
        'Step 1: 60-Point Comprehensive Diagnostic Scan',
        'Step 2: Total Fluid Extraction & Flushing',
        'Step 3: Filter & Mechanical Replacements',
        'Step 4: Wheel Alignment, Balancing & Deep Detailing',
      ],
      faqs: [
        {
          'q': 'How long does Master Service take?',
          'a': 'Due to detailed multi-system flushing and alignment, it takes approximately 5 to 6 hours.',
        },
      ],
    ),

    // 2. AC Service & Repair
    ServiceItem(
      id: 'srv_1',
      categoryId: 'cat_ac',
      title: 'High-Performance AC Gas Refill',
      description: 'Includes cooling coil disinfection, condenser washing, gas refill & blower dust purge.',
      price: 1499,
      originalPrice: 2299,
      durationText: '2.5 Hours',
      rating: 4.8,
      reviewsCount: 1420,
      warrantyPeriod: '1000 Kms / 1 Month Warranty',
      keyFeatures: [
        'Complete AC Gas Top-up (R134a)',
        'Condenser Cleaning & High-Pressure Flush',
        'Cooling Coil Inspection & Disinfection',
        'AC Cabin Air Filter Deep Clean',
      ],
      isPopular: true,
      serviceType: 'Climate Control',
      includedItems: [
        'Pure Dupont R134a AC Gas Refill (up to 450g)',
        'Condenser High-Pressure Water Jet Cleaning',
        'Cooling Coil Deep Antibacterial Disinfection',
        'Compressor Oil Lubricant Top-up',
        'Cabin Filter Purge & Vent Steam Fogging',
      ],
      excludedItems: [
        'AC compressor replacement or clutch coil repair',
        'Dashboard removal for evaporator core replacement',
      ],
      benefits: [
        'Sub-Zero Cabin Chilling Effect',
        'Eliminates Musty Mold & Odors',
        'Improves Fuel Efficiency by Unloading Compressor',
      ],
      processSteps: [
        'Step 1: Pressure & Leakage Diagnostic Test',
        'Step 2: Old Refrigerant Recovery & Vacuuming',
        'Step 3: New R134a Gas Refill & Compressor Lubrication',
        'Step 4: Vent Temperature Measurement & Quality Check',
      ],
      faqs: [
        {
          'q': 'How cold should my car AC get?',
          'a': 'After our service, vent output temperatures typically register between 4°C and 7°C on high blower speed.',
        },
      ],
    ),
    ServiceItem(
      id: 'srv_ac_2',
      categoryId: 'cat_ac',
      title: 'Complete AC Diagnostics & Cooling Coil Clean',
      description: 'Deep antibacterial evaporator foam wash, expansion valve check, and compressor oil top-up.',
      price: 2499,
      originalPrice: 3499,
      durationText: '3.5 Hours',
      rating: 4.7,
      reviewsCount: 840,
      warrantyPeriod: '2000 Kms / 2 Months Warranty',
      keyFeatures: [
        'Evaporator Ultrasonic Foam Cleaning',
        'Compressor Pressure & Leak Test',
        'Dashboard Duct Antibacterial Fogging',
        'Refrigerant Oil & Gas Top-up',
      ],
      isPopular: false,
      serviceType: 'Climate Control Deep Clean',
      includedItems: [
        'Ultrasonic Foam Treatment for Evaporator Coil',
        'Compressor High/Low Pressure Evaluation',
        'Expansion Valve & Receiver Drier Test',
        'Complete R134a Top-up with PAG 46 Compressor Oil',
      ],
      excludedItems: [
        'Blower motor replacement',
        'Dashboard dismantling repairs',
      ],
    ),

    // 3. Clutch & Brakes
    ServiceItem(
      id: 'srv_2',
      categoryId: 'cat_brakes',
      title: 'Front Brake Pads Replacement',
      description: 'Genuine OEM brake pad installation, disc skimming check & hydraulic brake fluid top-up.',
      price: 1899,
      originalPrice: 2599,
      durationText: '3 Hours',
      rating: 4.9,
      reviewsCount: 980,
      warrantyPeriod: '5000 Kms / 3 Months Warranty',
      keyFeatures: [
        'OEM-Grade Front Brake Pads (Set of 2)',
        'Brake Rotor Caliper Greasing & Cleaning',
        'Brake Fluid Top-up Included',
        'Emergency Stopping Distance Test',
      ],
      isPopular: true,
      serviceType: 'Brake Safety',
      includedItems: [
        'Pair of OEM-Grade Asbestos-Free Front Brake Pads',
        'Caliper Slide Pin Greasing with Ceramic Paste',
        'Brake Rotor Disc Inspection & Deglazing',
        'DOT 4 Brake Fluid Top-up',
        'Emergency Braking Distance Test',
      ],
      excludedItems: [
        'Rear drum brake shoes replacement',
        'New brake disc rotor purchase',
      ],
      benefits: [
        'Zero Squeal & Instant Braking Bite',
        'Shortens Emergency Braking Distance',
        'Genuine OEM Certified Friction Material',
      ],
      processSteps: [
        'Step 1: Wheel Removal & Pad Wear Gauge Check',
        'Step 2: Caliper Disassembly & Sliding Pin Clean',
        'Step 3: New OEM Pad Fitment & Torquing',
        'Step 4: Hydraulic Line Bleed & Road Bedding Test',
      ],
      faqs: [
        {
          'q': 'How do I know my brake pads need changing?',
          'a': 'Warning signs include high-pitched squealing noises, spongy pedal feel, or if pad thickness drops below 3mm.',
        },
      ],
    ),
    ServiceItem(
      id: 'srv_brakes_2',
      categoryId: 'cat_brakes',
      title: 'Disc Rotor Skimming & Caliper Overhaul',
      description: 'Eliminates brake vibration, restores factory pedal bite, and clears rotor scoring.',
      price: 1299,
      originalPrice: 1899,
      durationText: '2 Hours',
      rating: 4.8,
      reviewsCount: 650,
      warrantyPeriod: '3000 Kms / 2 Months Warranty',
      keyFeatures: [
        'Precision Lathe Rotor Surface Skimming',
        'Caliper Pin Greasing with High-Temp Lubricant',
        'Brake Line Bleeding & Pressure Check',
      ],
      isPopular: false,
      serviceType: 'Brake Restorative',
      includedItems: [
        'Computerized Lathe Skimming of Both Front Rotors',
        'Elimination of Surface Rust, Grooves, & Warpage',
        'Caliper Piston Seal & Boot Inspection',
      ],
      excludedItems: [
        'New brake pad set (can be combined at discount)',
      ],
    ),
    ServiceItem(
      id: 'srv_brakes_3',
      categoryId: 'cat_brakes',
      title: 'Complete Brake Fluid Flush & Bleed',
      description: 'Purges contaminated moisture-laden brake fluid and restores hydraulic pedal firmness.',
      price: 999,
      originalPrice: 1499,
      durationText: '1.5 Hours',
      rating: 4.7,
      reviewsCount: 510,
      warrantyPeriod: '1000 Kms / 1 Month Warranty',
      keyFeatures: [
        'Bosch DOT 4 High-Temp Brake Fluid Flush',
        '4-Wheel Caliper Bleeding with Vacuum Pump',
        'Master Cylinder & ABS Unit Test',
      ],
      isPopular: false,
      serviceType: 'Hydraulic Maintenance',
    ),

    // 4. Engine Service
    ServiceItem(
      id: 'srv_engine_1',
      categoryId: 'cat_engine',
      title: 'Engine Decarbonization & Throttle Body Clean',
      description: 'Advanced chemical decarbonization removing carbon crust from intake valves, pistons, and injectors.',
      price: 1799,
      originalPrice: 2499,
      durationText: '2.5 Hours',
      rating: 4.8,
      reviewsCount: 780,
      warrantyPeriod: '3000 Kms / 2 Months Warranty',
      keyFeatures: [
        'Intake Manifold & Throttle Valve De-crusting',
        'Fuel Injector High-Pressure Pulse Clean',
        'Oxygen Sensor & Catalytic Converter Purge',
        'Smoother Engine Idling & Faster Throttle Response',
      ],
      isPopular: true,
      serviceType: 'Engine Performance',
      includedItems: [
        'Throttle Body Disassembly & Aerosol Decarb',
        'Ultrasonic Fuel Injector Spray Pattern Test',
        'Combustion Chamber Carbon Dissolving Treatment',
        'Spark Plug Gap Cleaning & Adjustment',
      ],
      excludedItems: [
        'Engine cylinder head gasket replacement',
        'Timing belt or timing chain renewal',
      ],
      benefits: [
        'Eliminates Engine Knocking & Vibration',
        'Restores Original Fuel Economy (up to 15%)',
        'Reduces Tailpipe Carbon Emissions',
      ],
    ),
    ServiceItem(
      id: 'srv_engine_2',
      categoryId: 'cat_engine',
      title: 'Radiator Coolant Flush & Thermostat Test',
      description: 'Flushes out scale and sludge from cooling passages to prevent summer engine overheating.',
      price: 1199,
      originalPrice: 1699,
      durationText: '1.5 Hours',
      rating: 4.7,
      reviewsCount: 430,
      warrantyPeriod: '2000 Kms / 2 Months Warranty',
      keyFeatures: [
        'Complete Radiator Chemical Flush',
        'Organic Acid Coolant (OAT) Refill',
        'Thermostat Valve & Water Pump Leak Test',
        'Radiator Cap Pressure Audit',
      ],
      isPopular: false,
      serviceType: 'Engine Cooling',
    ),

    // 5. Batteries
    ServiceItem(
      id: 'srv_battery_1',
      categoryId: 'cat_battery',
      title: 'Doorstep Car Battery Replacement',
      description: '100% Genuine battery delivery with scrap buyback discount and free doorstep installation.',
      price: 3899,
      originalPrice: 4999,
      durationText: '45 Mins',
      rating: 4.9,
      reviewsCount: 2240,
      warrantyPeriod: 'Up to 55 Months Manufacturer Warranty',
      keyFeatures: [
        'Authorized OEM Battery (Exide/Amaron)',
        'Free Doorstep Fitment & Alternator Test',
        'Old Battery Buyback Discount Included',
        'Digital Warranty Registration',
      ],
      isPopular: true,
      serviceType: 'Battery & Power',
      includedItems: [
        'Fresh Manufactured OEM Car Battery',
        'Free Express Doorstep Delivery & Fitting',
        'Old Battery Exchange Buyback Deduction',
        'Alternator Charging Voltage & Cranking Load Test',
        'Anti-Corrosion Petroleum Jelly Terminal Treatment',
      ],
      excludedItems: [
        'Alternator rebuild or diode repair',
        'Starter motor electrical wiring replacements',
      ],
      benefits: [
        'Instant Cranking on Every Startup',
        'Nationwide Official Manufacturer Warranty',
        'Eco-Friendly Scrap Battery Recycling',
      ],
      processSteps: [
        'Step 1: Doorstep Arrival with Multi-meter Load Test',
        'Step 2: Safe Extraction of Old Battery Unit',
        'Step 3: New Battery Fitting & Cable Clamping',
        'Step 4: Alternator Voltage Verification & Digital Warranty Card',
      ],
      faqs: [
        {
          'q': 'How quickly will the technician arrive with the battery?',
          'a': 'We dispatch certified technicians within 45 minutes for emergency jumpstarts and battery installations.',
        },
      ],
    ),
    ServiceItem(
      id: 'srv_battery_2',
      categoryId: 'cat_battery',
      title: 'Alternator Testing & Battery Health Scan',
      description: 'In-depth digital analysis of alternator charging amps, parasitic drain, and cranking health.',
      price: 499,
      originalPrice: 799,
      durationText: '30 Mins',
      rating: 4.8,
      reviewsCount: 390,
      warrantyPeriod: '100% Diagnostic Accuracy Guarantee',
      keyFeatures: [
        'Digital Cranking Amps Test (CCA)',
        'Alternator Load vs RPM Output Check',
        'Parasitic Overnight Drain Audit',
      ],
      isPopular: false,
      serviceType: 'Electrical Diagnostic',
    ),

    // 6. Tyres & Wheels
    ServiceItem(
      id: 'srv_4',
      categoryId: 'cat_tyres',
      title: '3D Wheel Alignment & Balancing',
      description: 'Computerized 4-wheel laser alignment, wheel balancing with zinc weights & rotation.',
      price: 699,
      originalPrice: 1199,
      durationText: '1 Hour',
      rating: 4.8,
      reviewsCount: 3120,
      warrantyPeriod: '1000 Kms Warranty',
      keyFeatures: [
        'Computerized 3D Alignment Camera Check',
        'Precision Dynamic Wheel Balancing',
        'All 4 Tyres Free Rotation',
        'Nitrogen Inflation for All Tyres',
      ],
      isPopular: true,
      serviceType: 'Tyre & Suspension',
      includedItems: [
        'Computerized 3D High-Definition Camera Alignment',
        'All 4 Wheels Dynamic Spin Balancing with Weights',
        'Cross-Rotation to Even Out Tread Wear',
        '100% Pure Nitrogen Inflation (4 Tyres + 1 Spare)',
      ],
      excludedItems: [
        'Bent alloy wheel rim straightening',
        'Tie rod end or ball joint replacement',
      ],
      benefits: [
        'Eliminates High-Speed Steering Wheel Wobble',
        'Prevents Premature One-Sided Tyre Wear',
        'Laser-Straight Highway Tracking',
      ],
    ),
    ServiceItem(
      id: 'srv_tyres_2',
      categoryId: 'cat_tyres',
      title: 'Tubeless Tyre Puncture & Valve Replacement Kit',
      description: 'Mushroom patch puncture seals and replacement of degraded high-pressure rubber valves.',
      price: 449,
      originalPrice: 699,
      durationText: '45 Mins',
      rating: 4.6,
      reviewsCount: 560,
      warrantyPeriod: '6 Months Leak-Proof Guarantee',
      keyFeatures: [
        'German Internal Mushroom Patch Seal',
        '4x Fresh Brass Core High-Pressure Valves',
        'Tread Depth & Sidewall Integrity Audit',
      ],
      isPopular: false,
      serviceType: 'Tyre Maintenance',
    ),

    // 7. Car Spa & Detailing
    ServiceItem(
      id: 'srv_3',
      categoryId: 'cat_spa',
      title: 'Deep Interior Spa & Sanitization',
      description: 'Fabric extraction shampooing, dashboard UV treatment, antibacterial steam fogging.',
      price: 1599,
      originalPrice: 2499,
      durationText: '3.5 Hours',
      rating: 4.7,
      reviewsCount: 2310,
      warrantyPeriod: '100% Odor-Free Guarantee',
      keyFeatures: [
        'Deep Carpet & Seat Shampooing',
        'Dashboard Dresser with UV Shield',
        'Ceiling & Door Trim Chemical Wipe',
        'Antibacterial Hot Steam Treatment',
      ],
      isPopular: true,
      serviceType: 'Interior Care',
      includedItems: [
        'Karcher Wet Extraction Fabric & Carpet Shampoo',
        'Leather Upholstery Deep Cleaning & Conditioning',
        'Dashboard, Console & AC Vents Antimicrobial Steam',
        'Roof Liner Spot-Free Chemical Wipe',
        'Boot & Spare Wheel Well Vacuuming',
      ],
      excludedItems: [
        'Torn leather/fabric upholstery stitch repair',
        'Exterior paint correction or polish',
      ],
      benefits: [
        'Kills 99.9% of Cabin Bacteria & Pathogens',
        'Removes Stubborn Beverage & Pet Odors',
        'Restores Factory Fresh Interior Ambience',
      ],
    ),
    ServiceItem(
      id: 'srv_spa_2',
      categoryId: 'cat_spa',
      title: 'Ceramic Shield Hydrophobic Coating',
      description: '9H hardness nano-ceramic coat protecting paint from scratches, swirl marks & UV oxidation.',
      price: 4999,
      originalPrice: 7999,
      durationText: '5 Hours',
      rating: 4.9,
      reviewsCount: 420,
      warrantyPeriod: '1 Year Paint Gloss Warranty',
      keyFeatures: [
        '3-Stage Machine Paint Correction & Buffing',
        'Dual Layer 9H Ceramic Protection',
        'Hydrophobic Water Beading Effect',
        'All Glass Anti-Rain Repellent Treatment',
      ],
      isPopular: false,
      serviceType: 'Paint Protection',
      includedItems: [
        'Clay Bar Decontamination & Iron Fallout Removal',
        '3-Step Rotary Polisher Swirl Correction',
        '2 Coats of 9H Crystal Quartz Ceramic Shield',
        'Hydrophobic Windshield Glass Coating',
      ],
      excludedItems: [
        'Deep metal dent pulling or panel repainting',
      ],
    ),

    // 8. Denting & Painting
    ServiceItem(
      id: 'srv_denting_1',
      categoryId: 'cat_denting',
      title: 'Bumper Paint & Dent Removal (Single Panel)',
      description: 'Dust-free pressurized paint booth refinishing with DuPont colour matching guarantee.',
      price: 2499,
      originalPrice: 3499,
      durationText: '24 Hours',
      rating: 4.8,
      reviewsCount: 1180,
      warrantyPeriod: '2 Years Paint Warranty',
      keyFeatures: [
        'Precision Metal Dent Pulling',
        'Grade-A Anti-Rust Primer Application',
        'DuPont Multi-Coat Factory Color Match',
        'Clear Coat UV High-Gloss Buffing',
      ],
      isPopular: false,
      serviceType: 'Body & Paint',
      includedItems: [
        'Hydraulic Dent Pulling & Panel Shaping',
        'Epoxy Anti-Corrosive Primer Coat',
        'DuPont Spectrophotometer Computer Color Matching',
        'Pressurized Sealed Heat-Bake Booth Application',
        'Scratch-Resistant High-Solid Clear Coat',
      ],
      excludedItems: [
        'Internal radiator support bracket replacement',
        'Headlight assembly replacement',
      ],
      benefits: [
        '100% Exact Factory Shade Color Match',
        'Zero Paint Peeling or Bubble Guarantee',
        '2-Year Written Paint Warranty',
      ],
    ),

    // 9. Electrical
    ServiceItem(
      id: 'srv_electrical_1',
      categoryId: 'cat_electrical',
      title: 'Starter Motor Overhaul & Solenoid Repair',
      description: 'Disassembles, cleans, and replaces worn armature brushes to fix sluggish engine cranking.',
      price: 1699,
      originalPrice: 2399,
      durationText: '3 Hours',
      rating: 4.7,
      reviewsCount: 310,
      warrantyPeriod: '3000 Kms / 3 Months Warranty',
      keyFeatures: [
        'Carbon Brush & Bendix Gear Replacement',
        'Solenoid Switch Contact Overhaul',
        'Cranking Current & Armature Test',
      ],
      isPopular: false,
      serviceType: 'Electrical Rebuild',
      includedItems: [
        'Starter Motor Removal & Bench Testing',
        'New High-Conductivity Copper Brushes',
        'Bendix Pinion Gear Lubrication',
        'Starter Relay & Ignition Switch Line Test',
      ],
      excludedItems: [
        'Flywheel ring gear replacement',
      ],
    ),

    // 10. Inspection
    ServiceItem(
      id: 'srv_inspection_1',
      categoryId: 'cat_inspection',
      title: 'Pre-Purchase Used Car 150-Point Inspection',
      description: 'Comprehensive mechanical, electrical, and structural evaluation before purchasing a pre-owned car.',
      price: 1999,
      originalPrice: 2999,
      durationText: '3.5 Hours',
      rating: 4.9,
      reviewsCount: 1560,
      warrantyPeriod: 'Full Digital Report Delivered in 2 Hours',
      keyFeatures: [
        'Engine Compression & Transmission Health Test',
        'Accidental Chassis Weld & Repaint Meter Check',
        'OBD-II Scanning for Hidden ECU Fault Codes',
        'Suspension, Steering & Brake Trial Evaluation',
      ],
      isPopular: true,
      serviceType: 'Inspection & Advisory',
      includedItems: [
        '150-Point Multi-system Digital Checklist',
        'Paint Thickness Digital Gauge Audit (Accident Check)',
        'Live ECU Diagnostics for Tampered Odometer Flags',
        'Underbody Corrosion & Fluid Seepage Verification',
        'Photographic PDF Inspection Report with Repair Estimates',
      ],
      excludedItems: [
        'RTO vehicle registration background title check',
        'Physical disassembly of engine internals',
      ],
      benefits: [
        'Avoid Expensive Lemon Car Traps',
        'Save Thousands during Price Negotiation',
        'Unbiased Certified Mechanic Assessment',
      ],
    ),
    ServiceItem(
      id: 'srv_inspection_2',
      categoryId: 'cat_inspection',
      title: 'Car Inspection / Diagnostics',
      description: 'Comprehensive computer diagnostics, ECU system scan, and multi-point vehicle safety evaluation. Website-listed starting price from ₹499; final quote varies by vehicle make and condition.',
      price: 499,
      originalPrice: 499,
      durationText: '1.5 Hours',
      rating: 4.8,
      reviewsCount: 320,
      warrantyPeriod: 'Applicable Service Conditions / 30 Days Warranty',
      keyFeatures: [
        'Starting from ₹499 (Website-listed starting price)',
        'Full Computerized OBD-II Diagnostics',
        'Engine & Transmission Health Audit',
        'Fluid Levels & Safety Inspection',
      ],
      isPopular: false,
      serviceType: 'Diagnostics & Inspection',
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
    ),

    // 11. Windshield & Lights
    ServiceItem(
      id: 'srv_lights_1',
      categoryId: 'cat_lights',
      title: 'Headlight Restoration & Lens Clarity Buff',
      description: 'Removes yellowing, oxidation, and scratches to restore 100% night driving beam clarity.',
      price: 799,
      originalPrice: 1299,
      durationText: '1.5 Hours',
      rating: 4.8,
      reviewsCount: 760,
      warrantyPeriod: '6 Months Anti-Yellowing Warranty',
      keyFeatures: [
        '3-Step Wet Sanding & Scratch Removal',
        'Optical Grade Lens Compound Polish',
        'UV Protective Polymer Sealant',
      ],
      isPopular: false,
      serviceType: 'Lighting Restorative',
      includedItems: [
        'Polycarbonate Lens Multi-Grit Wet Sanding',
        'Optical Rotary Machine Compounding',
        'UV Clear Polymer Coating Spray',
        'Headlight Beam Leveling & Alignment',
      ],
      excludedItems: [
        'Internal LED ballast or projector lens repair',
        'Broken headlight housing plastic welding',
      ],
    ),
    ServiceItem(
      id: 'srv_lights_2',
      categoryId: 'cat_lights',
      title: 'Door Glass Replacement',
      description: 'Factory-grade OEM/OES door glass replacement with precision fitting and regulator calibration. Website-listed starting price from ₹850; final quote depends on car segment and glass specifications.',
      price: 850,
      originalPrice: 850,
      durationText: '2 Hours',
      rating: 4.8,
      reviewsCount: 210,
      warrantyPeriod: 'Applicable Service Conditions / 30 Days Warranty',
      keyFeatures: [
        'Starting from ₹850 (Website-listed starting price)',
        '100% Genuine OEM/OES Automotive Glass',
        'Precision Channel & Seal Alignment',
        'Power Window Regulator Operation Check',
      ],
      isPopular: false,
      serviceType: 'Glass Replacement',
      includedItems: [
        'OEM/OES Door Glass Unit',
        'Professional Removal & Safe Installation',
        'Channel Weatherstrip Realignment',
        'Vacuuming of Glass Debris Inside Door Cavity',
      ],
      excludedItems: [
        'Power window motor replacement if defective',
        'Final quote subject to vehicle make, model, and glass variant',
      ],
    ),
  ];

  // Popular services subset for homepage carousel
  static List<ServiceItem> get popularServices =>
      allServices.where((s) => s.isPopular).toList();

  // Comprehensive service packages
  static const List<ServicePackage> servicePackages = [
    ServicePackage(
      id: 'pkg_basic',
      title: 'Basic Periodic Service',
      tag: 'Every 5,000 Kms / 3 Months',
      description: 'Ideal for everyday commute vehicles needing quick fresh fluid & safety checks.',
      price: 2199,
      originalPrice: 2999,
      intervalText: 'Takes 3 Hours',
      timeTakenText: '3 Hours Duration',
      warranty: '1000 Kms / 1 Month Warranty',
      isRecommended: false,
      checklist: [
        'Engine Oil Replacement (Synthetic Blend)',
        'Oil Filter Replacement',
        'Air Filter Cleaning',
        'Coolant Top-up',
        '25-Point Comprehensive Safety Inspection',
        'Complementary Exterior Water Wash',
      ],
    ),
    ServicePackage(
      id: 'pkg_standard',
      title: 'Standard Periodic Service',
      tag: 'Most Recommended • Every 10,000 Kms',
      description: 'Complete maintenance package ensuring engine smoothness, mileage, and braking performance.',
      price: 3699,
      originalPrice: 5199,
      intervalText: 'Takes 4.5 Hours',
      timeTakenText: '4.5 Hours Duration',
      warranty: '5000 Kms / 3 Months Warranty',
      isRecommended: true,
      checklist: [
        '100% Fully Synthetic Engine Oil Replacement',
        'Oil Filter & Air Filter Replacement',
        'Cabin AC Filter Cleansing',
        'Brake Fluid & Coolant Top-up',
        'Front & Rear Brake Caliper Cleaning',
        'Spark Plug Cleaning / Test',
        'Battery Water & Terminal Greasing',
        'Complete 50-Point Digital Health Scan',
        'Exterior Foam Wash + Interior Vacuuming',
      ],
    ),
    ServicePackage(
      id: 'pkg_comprehensive',
      title: 'Comprehensive Master Service',
      tag: 'Every 20,000 Kms / Annual Overhaul',
      description: 'The ultimate bumper-to-bumper rejuvenation for total reliability and factory-grade performance.',
      price: 6499,
      originalPrice: 8999,
      intervalText: 'Takes 6 Hours',
      timeTakenText: '6 Hours Duration',
      warranty: '10000 Kms / 6 Months Warranty',
      isRecommended: false,
      checklist: [
        'Full Synthetic Engine Oil + Engine Flush',
        'All Filters Replacement (Oil, Air, AC)',
        'Brake Fluid Complete Bleed & Fluid Renewal',
        'Coolant Flush & Genuine Replacement',
        'Throttle Body Decarbonization Cleaning',
        'Fuel Injector Performance Diagnostic',
        'Wheel Alignment & Dynamic Balancing Included',
        'Full Interior Wet Deep Spa & Exterior Wax Buffing',
        '6 Months / 10,000 Kms Comprehensive Warranty',
      ],
    ),
  ];

  // Promotional offer coupons
  static List<Offer> offers = [
    Offer(
      id: 'off_1',
      couponCode: 'MYFIRST500',
      title: 'Flat ₹500 OFF On First Service',
      subtitle: 'Applicable on any Standard or Master Periodic Package',
      discountTag: 'SAVE ₹500',
      validTill: 'Valid till 30 Nov',
      gradient: const LinearGradient(
        colors: [Color(0xFFE64A19), Color(0xFFFF7043)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      discountValue: 500,
      isPercentage: false,
      minOrderValue: 1499,
      terms: [
        'Applicable for first-time users on scheduled maintenance.',
        'Requires a minimum order value of ₹1,499.',
        'Cannot be clubbed with other promotional coupons.',
        'Doorstep pickup and drop included where available.',
      ],
    ),
    Offer(
      id: 'off_2',
      couponCode: 'COOLCHILL25',
      title: '25% OFF On Car AC Services',
      subtitle: 'Beat the heat with chilled AC gas top-up & duct sanitization',
      discountTag: '25% OFF',
      validTill: 'Valid till 15 Nov',
      gradient: const LinearGradient(
        colors: [Color(0xFF1E3A8A), Color(0xFF3B82F6)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      discountValue: 25,
      isPercentage: true,
      maxDiscount: 750,
      minOrderValue: 1999,
      eligibleCategory: 'AC Service & Repair',
      terms: [
        'Valid exclusively on AC gas refill, condenser cleaning, and filter replacements.',
        'Maximum discount capped at ₹750.',
        'Minimum order value required: ₹1,999.',
        '100% genuine R134a/R1234yf refrigerant used.',
      ],
    ),
    Offer(
      id: 'off_3',
      couponCode: 'PERIODIC300',
      title: 'Periodic Maintenance Deal',
      subtitle: 'Flat ₹300 off on 10,000 km & 20,000 km regular car service',
      discountTag: 'FLAT ₹300',
      validTill: 'Valid till 20 Nov',
      gradient: const LinearGradient(
        colors: [Color(0xFF4A148C), Color(0xFF7B1FA2)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      discountValue: 300,
      isPercentage: false,
      minOrderValue: 2500,
      eligibleCategory: 'Periodic Services',
      terms: [
        'Applicable on Standard and Comprehensive Periodic Services.',
        'Minimum order value of ₹2,500.',
        'Includes 50-point digital car scan report.',
      ],
    ),
    Offer(
      id: 'off_4',
      couponCode: 'SPASPECIAL',
      title: 'Deep Spa Detailing Combo',
      subtitle: '20% off with deep foam wash & interior vacuuming',
      discountTag: '20% OFF',
      validTill: 'Valid till 10 Nov',
      gradient: const LinearGradient(
        colors: [Color(0xFF065F46), Color(0xFF10B981)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      discountValue: 20,
      isPercentage: true,
      maxDiscount: 400,
      minOrderValue: 999,
      eligibleCategory: 'Car Spa & Detailing',
      terms: [
        'Valid on Interior Spa, 3M Ceramic Coating & Teflon buffing.',
        'Maximum discount is ₹400.',
        'Minimum order value of ₹999.',
      ],
    ),
    Offer(
      id: 'off_5',
      couponCode: 'BATTERY200',
      title: 'Battery Check & Upgrade',
      subtitle: 'Flat ₹200 off on Exide, Amaron & OEM automotive batteries',
      discountTag: 'SAVE ₹200',
      validTill: 'Valid till 25 Nov',
      gradient: const LinearGradient(
        colors: [Color(0xFFB45309), Color(0xFFF59E0B)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      discountValue: 200,
      isPercentage: false,
      minOrderValue: 2500,
      eligibleCategory: 'Batteries',
      terms: [
        'Free doorstep alternator and terminal voltage inspection.',
        'Valid on battery purchases above ₹2,500.',
        'Old battery scrap exchange discount credited separately.',
      ],
    ),
    Offer(
      id: 'off_6',
      couponCode: 'SEASONAL15',
      title: 'Seasonal Festive Drive Deal',
      subtitle: '15% savings across all minor and major mechanical repairs',
      discountTag: '15% OFF',
      validTill: 'Valid till 30 Nov',
      gradient: const LinearGradient(
        colors: [Color(0xFFBE123C), Color(0xFFFB7185)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      discountValue: 15,
      isPercentage: true,
      maxDiscount: 600,
      minOrderValue: 1800,
      terms: [
        'Applicable across all mechanical & electrical service categories.',
        'Maximum discount ₹600.',
        'Valid on minimum order value of ₹1,800.',
      ],
    ),
  ];

  /// Reactive notifier for offers
  static final ValueNotifier<List<Offer>> offersNotifier =
      ValueNotifier<List<Offer>>(List.from(offers));

  // Catalog of Coupons for checkout engine
  static List<Coupon> coupons = [
    Coupon(
      code: 'MYFIRST500',
      title: 'First Service Discount',
      description: 'Flat ₹500 off on your first car service appointment.',
      discountType: CouponDiscountType.flat,
      discountValue: 500,
      minOrderValue: 1499,
      expiryDate: DateTime.now().add(const Duration(days: 45)),
      isActive: true,
      terms: [
        'Valid for orders ₹1,499 and above.',
        'Applicable on all periodic and general service packages.',
        'One-time use per customer.',
      ],
    ),
    Coupon(
      code: 'COOLCHILL25',
      title: 'Summer AC Chill 25%',
      description: '25% discount up to ₹750 on car air conditioning services.',
      discountType: CouponDiscountType.percentage,
      discountValue: 25,
      maxDiscount: 750,
      minOrderValue: 1999,
      expiryDate: DateTime.now().add(const Duration(days: 30)),
      eligibleCategory: 'AC Service & Repair',
      isActive: true,
      terms: [
        'Valid only on AC Service & Repair category.',
        'Maximum discount ₹750.',
        'Minimum order value ₹1,999.',
      ],
    ),
    Coupon(
      code: 'PERIODIC300',
      title: 'Periodic Maintenance Saver',
      description: 'Flat ₹300 off on scheduled periodic maintenance.',
      discountType: CouponDiscountType.flat,
      discountValue: 300,
      minOrderValue: 2500,
      expiryDate: DateTime.now().add(const Duration(days: 40)),
      eligibleCategory: 'Periodic Services',
      isActive: true,
      terms: [
        'Valid only for Periodic Services category.',
        'Minimum order value ₹2,500.',
      ],
    ),
    Coupon(
      code: 'SPASPECIAL',
      title: 'Car Spa & Detailing 20%',
      description: '20% discount up to ₹400 on car wash and interior sanitization.',
      discountType: CouponDiscountType.percentage,
      discountValue: 20,
      maxDiscount: 400,
      minOrderValue: 999,
      expiryDate: DateTime.now().add(const Duration(days: 35)),
      eligibleCategory: 'Car Spa & Detailing',
      isActive: true,
      terms: [
        'Valid only on Car Spa & Detailing category.',
        'Maximum discount ₹400.',
        'Minimum order value ₹999.',
      ],
    ),
    Coupon(
      code: 'BATTERY200',
      title: 'Battery Replacement Deal',
      description: 'Flat ₹200 off on OEM vehicle battery replacement.',
      discountType: CouponDiscountType.flat,
      discountValue: 200,
      minOrderValue: 2500,
      expiryDate: DateTime.now().add(const Duration(days: 45)),
      eligibleCategory: 'Batteries',
      isActive: true,
      terms: [
        'Valid on Batteries category.',
        'Minimum order value ₹2,500.',
      ],
    ),
    Coupon(
      code: 'SEASONAL15',
      title: 'Festive Season Savings',
      description: '15% discount up to ₹600 on all repairs & maintenance.',
      discountType: CouponDiscountType.percentage,
      discountValue: 15,
      maxDiscount: 600,
      minOrderValue: 1800,
      expiryDate: DateTime.now().add(const Duration(days: 50)),
      isActive: true,
      terms: [
        'Maximum discount ₹600.',
        'Minimum order value ₹1,800.',
      ],
    ),
    Coupon(
      code: 'EXPIRED50',
      title: 'Flash Sale (Expired)',
      description: '50% off holiday flash sale.',
      discountType: CouponDiscountType.percentage,
      discountValue: 50,
      maxDiscount: 1000,
      minOrderValue: 500,
      expiryDate: DateTime.now().subtract(const Duration(days: 10)), // Expired
      isActive: true,
      terms: ['Expired coupon for testing validation.'],
    ),
    Coupon(
      code: 'LIMITREACHED',
      title: 'Exclusive Member Pass',
      description: 'Flat ₹300 discount voucher.',
      discountType: CouponDiscountType.flat,
      discountValue: 300,
      minOrderValue: 500,
      expiryDate: DateTime.now().add(const Duration(days: 20)),
      usageLimit: 1,
      currentUsageCount: 1, // Limit reached
      isActive: true,
      terms: ['Usage limit reached coupon for testing validation.'],
    ),
    Coupon(
      code: 'BIGSAVER10',
      title: 'Big Saver 10%',
      description: '10% off up to ₹1,000 on orders over ₹3,000.',
      discountType: CouponDiscountType.percentage,
      discountValue: 10,
      maxDiscount: 1000,
      minOrderValue: 3000,
      expiryDate: DateTime.now().add(const Duration(days: 60)),
      isActive: true,
      terms: [
        'Maximum discount ₹1,000.',
        'Minimum order value ₹3,000.',
      ],
    ),
  ];

  /// Reactive notifier for coupons
  static final ValueNotifier<List<Coupon>> couponsNotifier =
      ValueNotifier<List<Coupon>>(List.from(coupons));

  /// Canonical guest bookings displayed when unauthenticated.
  static List<Booking> get guestBookings => [
    Booking(
      id: 'b1',
      bookingNumber: 'MM-2026-9481',
      serviceTitle: 'Standard Periodic Service',
      serviceDescription: 'Complete 30-point vehicle checkup, engine oil renewal & fluid top-ups',
      vehicleName: 'Hyundai Creta 1.5 SX(O)',
      vehicleNumber: 'KA 01 MJ 4521',
      dateTime: DateTime.now().add(const Duration(days: 1, hours: 3)),
      timeSlot: '10:30 AM',
      servicePrice: 3699,
      pickupFee: 0,
      totalAmount: 3699,
      pickupType: 'Doorstep Pickup & Drop',
      address: 'Flat 402, Green Glen Layout, Bellandur, Bengaluru - 560103',
      status: BookingStatus.inProgress,
      workshopName: 'My Mechanic Premium Car Service',
      assignedMechanic: 'Assigned upon arrival',
      packageName: 'Standard Periodic Package',
      warrantyPeriod: '5000 Kms / 3 Months Warranty',
      duration: '4 Hours',
      includedItems: const [
        '100% Fully Synthetic Engine Oil (4L)',
        'OEM Genuine Oil Filter Replacement',
        'Air Filter Cleaning / Replacement',
        'Coolant & Wiper Fluid Top-up',
        '50-Point Digital Health Scan',
      ],
      checklist: const [
        'Oil drain & filter installation',
        'Coolant & brake fluid inspection',
        'Brake caliper pad check & greasing',
        '50-point safety computer scan',
      ],
      exclusions: const [
        'Spark plug replacement',
        'Gearbox transmission fluid flush',
      ],
    ),
    Booking(
      id: 'b2',
      bookingNumber: 'MM-2026-7832',
      serviceTitle: 'Deep Interior Spa & Sanitization',
      serviceDescription: 'Steam sanitization, wet shampooing, and leather conditioning',
      vehicleName: 'Maruti Suzuki Swift ZXi',
      vehicleNumber: 'DL 03 CA 9812',
      dateTime: DateTime.now().subtract(const Duration(days: 12)),
      timeSlot: '02:00 PM',
      servicePrice: 1599,
      pickupFee: 0,
      totalAmount: 1599,
      pickupType: 'Drop at Workshop',
      status: BookingStatus.completed,
      workshopName: 'My Mechanic Premium Car Service',
      assignedMechanic: 'Assigned upon arrival',
      warrantyPeriod: '100% Odor-Free Guarantee',
      duration: '3.5 Hours',
      includedItems: const [
        'Deep Carpet & Seat Shampooing',
        'Dashboard Dresser with UV Shield',
        'Antibacterial Hot Steam Treatment',
        'Boot & Spare Wheel Well Vacuuming',
      ],
      checklist: const [
        'Complete dry vacuuming',
        'Wet shampoo extraction',
        'Dashboard & console conditioning',
        'Antibacterial vent fogging',
      ],
      exclusions: const [
        'Exterior ceramic polish',
      ],
      isRated: false,
    ),
    Booking(
      id: 'b3',
      bookingNumber: 'MM-2026-5120',
      serviceTitle: 'Standard Periodic Service',
      serviceDescription: 'Comprehensive scheduled maintenance with 100% synthetic engine oil replacement & 50-point diagnostic check',
      vehicleName: 'Hyundai Creta 1.5 SX(O)',
      vehicleNumber: 'KA 01 MJ 4521',
      dateTime: DateTime.now().subtract(const Duration(days: 45)),
      timeSlot: '11:00 AM',
      servicePrice: 3699,
      pickupFee: 0,
      discountAmount: 500,
      taxAmount: 288,
      totalAmount: 3487,
      pickupType: 'Doorstep Pickup & Drop',
      address: 'Flat 402, Green Glen Layout, Bellandur, Bengaluru - 560103',
      status: BookingStatus.completed,
      workshopName: 'My Mechanic Premium Car Service',
      assignedMechanic: 'Assigned upon arrival',
      packageName: 'Standard Periodic Package',
      warrantyPeriod: '5000 Kms / 3 Months Warranty',
      duration: '4 Hours',
      includedItems: const [
        '100% Fully Synthetic Engine Oil (4L)',
        'OEM Genuine Oil Filter Replacement',
        'Coolant & Wiper Fluid Top-up',
        'Brake Pad Inspection & Caliper Greasing',
        'Exterior Foam Wash & Underbody Rinse',
      ],
      checklist: const [
        'Engine oil drain & filter change',
        'Brake caliper inspection & greasing',
        'Battery terminal cleaning',
        'Road trial & digital report generation',
      ],
      rating: 5,
      ratingFeedback: 'Smooth engine performance and timely doorstep handover!',
      ratingCategories: const ['Service Quality', 'Timeliness', 'Vehicle Handling'],
      isRated: true,
    ),
    Booking(
      id: 'b4',
      bookingNumber: 'MM-2026-3914',
      serviceTitle: 'Doorstep Car Battery Replacement',
      serviceDescription: '100% Genuine battery delivery with scrap buyback discount and free doorstep installation',
      vehicleName: 'Maruti Suzuki Swift ZXi',
      vehicleNumber: 'DL 03 CA 9812',
      dateTime: DateTime.now().subtract(const Duration(days: 20)),
      timeSlot: '04:00 PM',
      servicePrice: 3899,
      pickupFee: 0,
      totalAmount: 3899,
      pickupType: 'Doorstep Pickup & Drop',
      address: 'Flat 402, Green Glen Layout, Bellandur, Bengaluru - 560103',
      status: BookingStatus.cancelled,
      workshopName: 'My Mechanic Premium Car Service',
      assignedMechanic: 'Assigned upon arrival',
      warrantyPeriod: 'Up to 55 Months Manufacturer Warranty',
      duration: '45 Mins',
      includedItems: const [
        'Fresh Manufactured OEM Car Battery',
        'Free Express Doorstep Delivery & Fitting',
        'Alternator Charging Voltage Test',
      ],
      checklist: const [
        'Alternator load testing',
        'Old battery disconnection',
        'Terminal greasing',
      ],
      exclusions: const [
        'Alternator rebuild or diode repair',
      ],
    ),
    Booking(
      id: 'b5',
      bookingNumber: 'MM-2026-2180',
      serviceTitle: 'Pre-Purchase Used Car 150-Point Inspection',
      serviceDescription: 'Comprehensive mechanical, electrical, and structural evaluation report',
      vehicleName: 'Tata Nexon EV (Fearless+)',
      vehicleNumber: 'MH 02 FE 1109',
      dateTime: DateTime.now().subtract(const Duration(days: 90)),
      timeSlot: '09:30 AM',
      servicePrice: 1999,
      pickupFee: 0,
      totalAmount: 1999,
      pickupType: 'Drop at Workshop',
      status: BookingStatus.completed,
      workshopName: 'My Mechanic Premium Car Service',
      assignedMechanic: 'Assigned upon arrival',
      warrantyPeriod: 'Full Digital Report Delivered in 2 Hours',
      duration: '3.5 Hours',
      includedItems: const [
        '150-Point Multi-system Digital Checklist',
        'High-Voltage Battery Cell Health Audit',
        'Live ECU Diagnostics for Tampered Odometer Flags',
      ],
      checklist: const [
        'High voltage battery health audit',
        'OBD diagnostic computer scan',
        'Underbody corrosion check',
      ],
      rating: 5,
      ratingFeedback: 'Comprehensive report helped identify minor wiring issue before purchase.',
      ratingCategories: const ['Service Quality', 'Staff Behaviour', 'Value for Money'],
      isRated: true,
    ),
  ];

  // Current active bookings list (or guest bookings when unauthenticated)
  static List<Booking> bookings = List.from(guestBookings);

  /// Reactive notifier for bookings
  static final ValueNotifier<List<Booking>> bookingsNotifier =
      ValueNotifier<List<Booking>>(List.from(bookings));

  /// Resets bookings state to the default guest experience and notifies listeners.
  static void resetToGuestBookings() {
    bookings = List.from(guestBookings);
    bookingsNotifier.value = List.from(bookings);
  }

  /// Resets all customer-specific data (vehicles and bookings) back to the clean guest experience.
  static void resetAllToGuest() {
    resetToGuestVehicles();
    resetToGuestBookings();
  }

  /// Adds a new booking to the top of active bookings
  static void addBooking(Booking newBooking) {
    bookings.insert(0, newBooking);
    bookingsNotifier.value = List.from(bookings);
    addNotification(NotificationItem(
      id: 'notif_${DateTime.now().millisecondsSinceEpoch}',
      title: 'Booking Confirmed!',
      message: 'Your booking ${newBooking.bookingNumber} for ${newBooking.serviceTitle} has been confirmed.',
      dateTime: DateTime.now(),
      category: NotificationCategory.booking,
      relatedId: newBooking.id,
    ));
  }

  /// Updates an existing booking
  static void updateBooking(Booking updated) {
    final idx = bookings.indexWhere((b) => b.id == updated.id);
    if (idx != -1) {
      bookings[idx] = updated;
      bookingsNotifier.value = List.from(bookings);
    }
  }

  /// Cancels a booking by id
  static void cancelBooking(String id) {
    final idx = bookings.indexWhere((b) => b.id == id);
    if (idx != -1) {
      bookings[idx] = bookings[idx].copyWith(status: BookingStatus.cancelled);
      bookingsNotifier.value = List.from(bookings);
      final b = bookings[idx];
      addNotification(NotificationItem(
        id: 'notif_${DateTime.now().millisecondsSinceEpoch}',
        title: 'Booking Cancelled',
        message: 'Booking ${b.bookingNumber} for ${b.serviceTitle} has been cancelled.',
        dateTime: DateTime.now(),
        category: NotificationCategory.booking,
        relatedId: b.id,
      ));
    }
  }

  /// Reschedules a booking with a new date and time slot
  static void rescheduleBooking(String id, DateTime newDateTime, String newTimeSlot) {
    final idx = bookings.indexWhere((b) => b.id == id);
    if (idx != -1) {
      bookings[idx] = bookings[idx].copyWith(
        dateTime: newDateTime,
        timeSlot: newTimeSlot,
      );
      bookingsNotifier.value = List.from(bookings);
      final b = bookings[idx];
      addNotification(NotificationItem(
        id: 'notif_${DateTime.now().millisecondsSinceEpoch}',
        title: 'Booking Rescheduled',
        message: 'Booking ${b.bookingNumber} has been rescheduled to $newTimeSlot.',
        dateTime: DateTime.now(),
        category: NotificationCategory.booking,
        relatedId: b.id,
      ));
    }
  }

  /// Submits rating and feedback for a completed booking.
  /// Returns false if already rated or not found, true upon success.
  static bool rateBooking(String id, int rating, List<String> categories, String feedback) {
    final idx = bookings.indexWhere((b) => b.id == id);
    if (idx != -1) {
      if (bookings[idx].isRated || bookings[idx].rating != null) {
        return false;
      }
      bookings[idx] = bookings[idx].copyWith(
        rating: rating,
        ratingFeedback: feedback,
        ratingCategories: categories,
        isRated: true,
      );
      bookingsNotifier.value = List.from(bookings);
      return true;
    }
    return false;
  }

  /// Checks if a booking has already been rated
  static bool isBookingRated(String id) {
    final idx = bookings.indexWhere((b) => b.id == id);
    if (idx == -1) return false;
    final b = bookings[idx];
    return b.isRated || b.rating != null;
  }

  /// Gets all bookings for a vehicle by registration number (case and whitespace-insensitive)
  static List<Booking> getBookingsForVehicle(String registrationNumber) {
    final cleanReg = registrationNumber.replaceAll(' ', '').toUpperCase();
    return bookings.where((b) {
      final bReg = b.vehicleNumber.replaceAll(' ', '').toUpperCase();
      return bReg == cleanReg;
    }).toList();
  }

  /// Gets service history (completed / cancelled) for a vehicle by registration number
  static List<Booking> getServiceHistoryForVehicle(String registrationNumber) {
    final cleanReg = registrationNumber.replaceAll(' ', '').toUpperCase();
    return bookings.where((b) {
      final bReg = b.vehicleNumber.replaceAll(' ', '').toUpperCase();
      return bReg == cleanReg && (b.status == BookingStatus.completed || b.status == BookingStatus.cancelled);
    }).toList();
  }

  // Available locations
  static const List<String> availableLocations = [
    'Atul Kataria Chowk, Gurugram',
    'Old Delhi Road, Gurugram',
    'Cyber City, Gurugram',
    'Sector 14, Gurugram',
    'Connaught Place, New Delhi',
    'Andheri West, Mumbai',
    'Banjara Hills, Hyderabad',
  ];

  // Saved user addresses
  static List<Map<String, String>> savedAddresses = [
    {
      'tag': 'Home',
      'address': 'Flat 402, Green Glen Layout, Bellandur',
      'city': 'Bengaluru',
      'pincode': '560103',
      'phone': '+91 98765 43210',
      'isDefault': 'true',
    },
    {
      'tag': 'Office',
      'address': 'Embassy TechVillage, Outer Ring Road, Devarabeesanahalli',
      'city': 'Bengaluru',
      'pincode': '560103',
      'phone': '+91 98765 43210',
      'isDefault': 'false',
    },
  ];

  /// Reactive notifier for saved addresses
  static final ValueNotifier<List<Map<String, String>>> addressesNotifier =
      ValueNotifier<List<Map<String, String>>>(List.from(savedAddresses));

  /// Adds a new address to saved addresses
  static void addAddress(Map<String, String> newAddress) {
    savedAddresses.add(newAddress);
    addressesNotifier.value = List.from(savedAddresses);
  }

  // Service Invoices
  static List<Map<String, dynamic>> invoices = [
    {
      'invoiceNo': 'INV-2026-0841',
      'bookingNo': 'MM-2026-7832',
      'service': 'Deep Interior Spa & Sanitization',
      'vehicle': 'Maruti Suzuki Swift (DL 03 CA 9812)',
      'date': '08 Oct 2026',
      'amount': 1599.0,
      'status': 'Paid',
    },
    {
      'invoiceNo': 'INV-2026-0612',
      'bookingNo': 'MM-2026-5120',
      'service': '3D Wheel Alignment & Balancing',
      'vehicle': 'Hyundai Creta (KA 01 MJ 4521)',
      'date': '14 Sep 2026',
      'amount': 699.0,
      'status': 'Paid',
    },
  ];

  // ==========================================
  // COUPON ENGINE HELPERS
  // ==========================================

  /// Finds coupon by code (case-insensitive)
  static Coupon? findCoupon(String code) {
    final cleanCode = code.trim().toUpperCase();
    try {
      return coupons.firstWhere((c) => c.code.toUpperCase() == cleanCode);
    } catch (_) {
      return null;
    }
  }

  /// Validates a coupon code against order details
  static CouponValidationResult validateCoupon(
    String code, {
    required double orderAmount,
    String? category,
    String? serviceId,
  }) {
    final coupon = findCoupon(code);
    if (coupon == null) {
      return const CouponValidationResult.invalid('Invalid coupon code. Try MYFIRST500 or COOLCHILL25');
    }
    return coupon.validate(
      orderAmount: orderAmount,
      category: category,
      serviceId: serviceId,
    );
  }

  /// Calculates discount amount for a coupon on an eligible subtotal
  static double calculateDiscount(String code, double eligibleSubtotal) {
    final coupon = findCoupon(code);
    if (coupon == null) return 0.0;
    return coupon.calculateDiscount(eligibleSubtotal);
  }

  // ==========================================
  // FAVORITES / WISHLIST STATE
  // ==========================================

  /// Reactive set of favorited service IDs
  static final ValueNotifier<Set<String>> favoriteServiceIdsNotifier =
      ValueNotifier<Set<String>>({'srv_periodic_1', 'srv_spa_1'});

  /// Reactive set of favorited package IDs
  static final ValueNotifier<Set<String>> favoritePackageIdsNotifier =
      ValueNotifier<Set<String>>({'pkg_1'});

  static bool isServiceFavorite(String serviceId) {
    return favoriteServiceIdsNotifier.value.contains(serviceId);
  }

  static void toggleServiceFavorite(String serviceId) {
    final current = Set<String>.from(favoriteServiceIdsNotifier.value);
    if (current.contains(serviceId)) {
      current.remove(serviceId);
    } else {
      current.add(serviceId);
    }
    favoriteServiceIdsNotifier.value = current;
  }

  static bool isPackageFavorite(String packageId) {
    return favoritePackageIdsNotifier.value.contains(packageId);
  }

  static void togglePackageFavorite(String packageId) {
    final current = Set<String>.from(favoritePackageIdsNotifier.value);
    if (current.contains(packageId)) {
      current.remove(packageId);
    } else {
      current.add(packageId);
    }
    favoritePackageIdsNotifier.value = current;
  }

  static List<ServiceItem> getFavoriteServices() {
    final favIds = favoriteServiceIdsNotifier.value;
    return allServices.where((s) => favIds.contains(s.id)).toList();
  }

  static List<ServicePackage> getFavoritePackages() {
    final favIds = favoritePackageIdsNotifier.value;
    return servicePackages.where((p) => favIds.contains(p.id)).toList();
  }

  // ==========================================
  // RECENTLY VIEWED SERVICES
  // ==========================================

  /// Reactive list of recently viewed service IDs (latest first, max 8 items)
  static final ValueNotifier<List<String>> recentlyViewedNotifier =
      ValueNotifier<List<String>>(['srv_periodic_1', 'srv_ac_1']);

  static void addRecentlyViewed(String serviceId) {
    final current = List<String>.from(recentlyViewedNotifier.value);
    current.remove(serviceId); // Remove if exists so it moves to front
    current.insert(0, serviceId);
    if (current.length > 8) {
      current.removeRange(8, current.length);
    }
    recentlyViewedNotifier.value = current;
  }

  static List<ServiceItem> getRecentlyViewedServices() {
    final ids = recentlyViewedNotifier.value;
    final List<ServiceItem> items = [];
    for (final id in ids) {
      try {
        final match = allServices.firstWhere((s) => s.id == id);
        items.add(match);
      } catch (_) {}
    }
    return items;
  }

  // ==========================================
  // LOCAL RECOMMENDATIONS ENGINE
  // ==========================================

  /// Returns deterministic recommended services based on active vehicle,
  /// service reminders, and recently viewed services.
  static List<ServiceItem> getRecommendedServices() {
    final active = activeVehicle;
    final List<ServiceItem> recommended = [];

    // 1. Vehicle reminder based recommendation
    if (active.reminderStatus != null && active.nextServiceTitle != null) {
      try {
        final match = allServices.firstWhere(
          (s) => s.title.toLowerCase().contains('periodic') || s.title.toLowerCase().contains('standard'),
        );
        recommended.add(match);
      } catch (_) {}
    }

    // 2. Fuel-type specific recommendation (Electric vs ICE)
    if (active.fuelType.toLowerCase().contains('electric')) {
      try {
        final match = allServices.firstWhere((s) => s.categoryId == 'cat_inspection' || s.categoryId == 'cat_battery');
        if (!recommended.any((s) => s.id == match.id)) recommended.add(match);
      } catch (_) {}
    } else {
      try {
        final match = allServices.firstWhere((s) => s.categoryId == 'cat_ac');
        if (!recommended.any((s) => s.id == match.id)) recommended.add(match);
      } catch (_) {}
    }

    // 3. Detailing / Spa recommendation
    try {
      final match = allServices.firstWhere((s) => s.categoryId == 'cat_spa');
      if (!recommended.any((s) => s.id == match.id)) recommended.add(match);
    } catch (_) {}

    // Fallback to top popular services if list is short
    for (final s in popularServices) {
      if (!recommended.any((r) => r.id == s.id) && recommended.length < 4) {
        recommended.add(s);
      }
    }

    return recommended;
  }

  // ==========================================
  // NOTIFICATIONS CENTER
  // ==========================================

  static List<NotificationItem> notifications = [
    NotificationItem(
      id: 'notif_1',
      title: 'Booking Confirmed!',
      message: 'Your service appointment MM-2026-9481 for Standard Periodic Service has been scheduled.',
      dateTime: DateTime.now().subtract(const Duration(minutes: 45)),
      category: NotificationCategory.booking,
      isRead: false,
      relatedId: 'b1',
    ),
    NotificationItem(
      id: 'notif_2',
      title: 'Service Due Soon: Hyundai Creta',
      message: 'Periodic Service is due in 12 days (approx. 30,000 km). Book your slot today for doorstep pickup.',
      dateTime: DateTime.now().subtract(const Duration(hours: 4)),
      category: NotificationCategory.service,
      isRead: false,
    ),
    NotificationItem(
      id: 'notif_3',
      title: 'Flat ₹500 OFF First Service',
      message: 'Use coupon code MYFIRST500 to enjoy ₹500 discount on your complete periodic maintenance.',
      dateTime: DateTime.now().subtract(const Duration(days: 1)),
      category: NotificationCategory.offers,
      isRead: true,
      relatedId: 'MYFIRST500',
    ),
    NotificationItem(
      id: 'notif_4',
      title: 'Service Completed & Inspected',
      message: 'Deep Interior Spa for your Maruti Suzuki Swift has been completed. View warranty card and rate service.',
      dateTime: DateTime.now().subtract(const Duration(days: 12)),
      category: NotificationCategory.booking,
      isRead: true,
      relatedId: 'b2',
    ),
    NotificationItem(
      id: 'notif_5',
      title: 'Monsoon Car AC Check Deal',
      message: 'Get 25% OFF on AC gas top-up and pollen filter replacement with coupon COOLCHILL25.',
      dateTime: DateTime.now().subtract(const Duration(days: 15)),
      category: NotificationCategory.offers,
      isRead: true,
      relatedId: 'COOLCHILL25',
    ),
  ];

  /// Reactive notifier for notifications
  static final ValueNotifier<List<NotificationItem>> notificationsNotifier =
      ValueNotifier<List<NotificationItem>>(List.from(notifications));

  static int get unreadNotificationsCount {
    return notificationsNotifier.value.where((n) => !n.isRead).length;
  }

  static void markNotificationAsRead(String id) {
    final list = List<NotificationItem>.from(notificationsNotifier.value);
    final idx = list.indexWhere((n) => n.id == id);
    if (idx != -1 && !list[idx].isRead) {
      list[idx] = list[idx].copyWith(isRead: true);
      notifications = list;
      notificationsNotifier.value = list;
    }
  }

  static void markAllNotificationsAsRead() {
    final list = notificationsNotifier.value.map((n) => n.copyWith(isRead: true)).toList();
    notifications = list;
    notificationsNotifier.value = list;
  }

  static void deleteNotification(String id) {
    final list = List<NotificationItem>.from(notificationsNotifier.value);
    list.removeWhere((n) => n.id == id);
    notifications = list;
    notificationsNotifier.value = list;
  }

  static void addNotification(NotificationItem item) {
    final list = List<NotificationItem>.from(notificationsNotifier.value);
    list.insert(0, item);
    notifications = list;
    notificationsNotifier.value = list;
  }

  /// Official Verified Workshop Hub
  static List<Workshop> workshops = [
    const Workshop(
      id: 'w_gurugram',
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
    ),
  ];
}
