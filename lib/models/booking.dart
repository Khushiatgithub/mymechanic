enum BookingStatus {
  confirmed,
  inProgress,
  completed,
  cancelled,
}

class Booking {
  final String id;
  final String bookingNumber;
  final String serviceTitle;
  final String? serviceDescription;
  final String vehicleName;
  final String vehicleNumber;
  final DateTime dateTime;
  final String? timeSlot;
  final double totalAmount;
  final double servicePrice;
  final double pickupFee;
  final double discountAmount;
  final double taxAmount;
  final String pickupType;
  final String? address;
  final String? couponCode;
  final BookingStatus status;
  final String workshopName;
  final String assignedMechanic;

  // Step 4.8: Backend API references and attributes
  final String? serviceId;
  final String? vehicleId;
  final String? serviceMode;
  final String? backendStatus;
  final String? notes;

  // Step 4.18: Payment simulation attributes
  final String paymentMethod;
  final String paymentStatus;
  final String? paymentReference;
  final DateTime? paidAt;

  // Enhanced service history, rating & tracking fields
  final String? packageName;
  final String? warrantyPeriod;
  final String? duration;
  final List<String> includedItems;
  final List<String> checklist;
  final List<String> exclusions;
  final int? rating;
  final String? ratingFeedback;
  final List<String> ratingCategories;
  final bool isRated;

  const Booking({
    required this.id,
    required this.bookingNumber,
    required this.serviceTitle,
    this.serviceDescription,
    required this.vehicleName,
    required this.vehicleNumber,
    required this.dateTime,
    this.timeSlot,
    required this.totalAmount,
    this.servicePrice = 0.0,
    this.pickupFee = 0.0,
    this.discountAmount = 0.0,
    this.taxAmount = 0.0,
    this.pickupType = 'Doorstep Pickup & Drop',
    this.address,
    this.couponCode,
    required this.status,
    required this.workshopName,
    required this.assignedMechanic,
    this.serviceId,
    this.vehicleId,
    this.serviceMode,
    this.backendStatus,
    this.notes,
    this.packageName,
    this.warrantyPeriod,
    this.duration = '3 Hours',
    this.includedItems = const [],
    this.checklist = const [],
    this.exclusions = const [],
    this.rating,
    this.ratingFeedback,
    this.ratingCategories = const [],
    this.isRated = false,
    this.paymentMethod = 'pay_on_delivery',
    this.paymentStatus = 'pending',
    this.paymentReference,
    this.paidAt,
  });

  /// Factory constructor to deserialize a backend JSON response.
  factory Booking.fromJson(Map<String, dynamic> json) {
    // 1. Extract IDs
    final id = json['_id']?.toString() ?? json['id']?.toString() ?? '';
    final bookingNumber = json['bookingNumber']?.toString() ?? 'MM-${id.substring(0, id.length > 6 ? 6 : id.length)}';

    // 2. Extract Service info (handle populated object or scalar)
    String extractedServiceId = '';
    String serviceTitle = 'General Vehicle Service';
    String? serviceDescription;
    double parsedServicePrice = 0.0;
    String duration = '3-4 Hours';
    List<String> incItems = [];

    if (json['serviceId'] is Map<String, dynamic>) {
      final srvMap = json['serviceId'] as Map<String, dynamic>;
      extractedServiceId = srvMap['_id']?.toString() ?? srvMap['id']?.toString() ?? '';
      serviceTitle = srvMap['title']?.toString() ?? serviceTitle;
      serviceDescription = srvMap['description']?.toString();
      parsedServicePrice = (srvMap['price'] as num?)?.toDouble() ?? 0.0;
      duration = srvMap['durationText']?.toString() ?? duration;
      if (srvMap['includedItems'] is List) {
        incItems = (srvMap['includedItems'] as List).map((e) => e.toString()).toList();
      }
    } else if (json['serviceId'] != null) {
      extractedServiceId = json['serviceId'].toString();
      serviceTitle = json['serviceTitle']?.toString() ?? serviceTitle;
      serviceDescription = json['serviceDescription']?.toString();
    } else {
      serviceTitle = json['serviceTitle']?.toString() ?? serviceTitle;
      serviceDescription = json['serviceDescription']?.toString();
    }

    // 3. Extract Vehicle info (handle populated object or scalar)
    String extractedVehicleId = '';
    String vehicleName = 'Customer Vehicle';
    String vehicleNumber = 'TN 01 AB 1234';

    if (json['vehicleId'] is Map<String, dynamic>) {
      final vMap = json['vehicleId'] as Map<String, dynamic>;
      extractedVehicleId = vMap['_id']?.toString() ?? vMap['id']?.toString() ?? '';
      final make = vMap['make']?.toString() ?? '';
      final model = vMap['model']?.toString() ?? '';
      final variant = vMap['variant']?.toString() ?? '';
      vehicleName = '$make $model $variant'.trim();
      if (vehicleName.isEmpty) vehicleName = 'Customer Vehicle';
      vehicleNumber = vMap['registrationNumber']?.toString() ?? vehicleNumber;
    } else if (json['vehicleId'] != null) {
      extractedVehicleId = json['vehicleId'].toString();
      vehicleName = json['vehicleName']?.toString() ?? vehicleName;
      vehicleNumber = json['vehicleNumber']?.toString() ?? vehicleNumber;
    } else {
      vehicleName = json['vehicleName']?.toString() ?? vehicleName;
      vehicleNumber = json['vehicleNumber']?.toString() ?? vehicleNumber;
    }

    // 4. Dates & Times
    final scheduledDateRaw = json['scheduledDate'] ?? json['dateTime'];
    final dateTime = scheduledDateRaw != null
        ? (DateTime.tryParse(scheduledDateRaw.toString()) ?? DateTime.now())
        : DateTime.now();
    final timeSlot = json['scheduledTime']?.toString() ?? json['timeSlot']?.toString() ?? '10:00 AM - 12:00 PM';

    // 5. Financials
    final subtotal = (json['subtotal'] as num?)?.toDouble() ?? parsedServicePrice;
    final discount = (json['discount'] as num?)?.toDouble() ?? (json['discountAmount'] as num?)?.toDouble() ?? 0.0;
    final pickupFee = (json['pickupFee'] as num?)?.toDouble() ?? 0.0;
    final gst = (json['gst'] as num?)?.toDouble() ?? (json['taxAmount'] as num?)?.toDouble() ?? 0.0;
    final totalAmount = (json['totalAmount'] as num?)?.toDouble() ?? (subtotal - discount + pickupFee + gst);

    // 6. Service mode and pickup
    final serviceMode = json['serviceMode']?.toString() ?? 'doorstep';
    final pickupType = json['pickupType']?.toString() ?? (serviceMode == 'doorstep' ? 'Doorstep Pickup & Drop' : 'Drop at Workshop');
    final address = json['address']?.toString();
    final couponCode = json['couponCode']?.toString();

    // 7. Status mapping
    final rawStatus = (json['status'] ?? '').toString().toLowerCase().trim();
    final status = _mapBackendStatusToEnum(rawStatus);

    // 8. Rating and feedback
    final rating = (json['rating'] as num?)?.toInt();
    final ratingFeedback = json['ratingFeedback']?.toString();
    final isRated = json['isRated'] == true || rating != null;
    List<String> ratingCategories = [];
    if (json['ratingCategories'] is List) {
      ratingCategories = (json['ratingCategories'] as List).map((e) => e.toString()).toList();
    }

    // 9. Payment details
    final paymentMethod = json['paymentMethod']?.toString() ?? 'pay_on_delivery';
    final paymentStatus = json['paymentStatus']?.toString() ?? 'pending';
    final paymentReference = json['paymentReference']?.toString();
    final paidAtRaw = json['paidAt'];
    final paidAt = paidAtRaw != null ? DateTime.tryParse(paidAtRaw.toString()) : null;

    return Booking(
      id: id,
      bookingNumber: bookingNumber,
      serviceTitle: serviceTitle,
      serviceDescription: serviceDescription,
      vehicleName: vehicleName,
      vehicleNumber: vehicleNumber,
      dateTime: dateTime,
      timeSlot: timeSlot,
      servicePrice: subtotal,
      pickupFee: pickupFee,
      discountAmount: discount,
      taxAmount: gst,
      totalAmount: totalAmount,
      pickupType: pickupType,
      address: address,
      couponCode: couponCode,
      status: status,
      workshopName: json['workshopName']?.toString() ?? 'My Mechanic Premium Car Service',
      assignedMechanic: json['assignedMechanic']?.toString() ?? 'Assigned upon arrival',
      serviceId: extractedServiceId.isNotEmpty ? extractedServiceId : null,
      vehicleId: extractedVehicleId.isNotEmpty ? extractedVehicleId : null,
      serviceMode: serviceMode,
      backendStatus: rawStatus.isNotEmpty ? rawStatus : null,
      notes: json['notes']?.toString(),
      duration: duration,
      includedItems: incItems,
      rating: rating,
      ratingFeedback: ratingFeedback,
      ratingCategories: ratingCategories,
      isRated: isRated,
      paymentMethod: paymentMethod,
      paymentStatus: paymentStatus,
      paymentReference: paymentReference,
      paidAt: paidAt,
    );
  }

  static BookingStatus _mapBackendStatusToEnum(String rawStatus) {
    switch (rawStatus) {
      case 'confirmed':
        return BookingStatus.confirmed;
      case 'vehicle_received':
      case 'inspection':
      case 'service_in_progress':
      case 'quality_check':
      case 'ready_for_delivery':
        return BookingStatus.inProgress;
      case 'completed':
        return BookingStatus.completed;
      case 'cancelled':
        return BookingStatus.cancelled;
      default:
        return BookingStatus.confirmed;
    }
  }

  String get statusText {
    if (backendStatus != null) {
      switch (backendStatus) {
        case 'confirmed':
          return 'Booking Confirmed';
        case 'vehicle_received':
          return 'Vehicle Received';
        case 'inspection':
          return 'Under Inspection';
        case 'service_in_progress':
          return 'Service In Progress';
        case 'quality_check':
          return 'Quality Check';
        case 'ready_for_delivery':
          return 'Ready for Delivery';
        case 'completed':
          return 'Completed';
        case 'cancelled':
          return 'Cancelled';
      }
    }

    switch (status) {
      case BookingStatus.confirmed:
        return 'Booking Confirmed';
      case BookingStatus.inProgress:
        return 'Service In Progress';
      case BookingStatus.completed:
        return 'Completed';
      case BookingStatus.cancelled:
        return 'Cancelled';
    }
  }

  bool get isPaid => paymentStatus.toLowerCase() == 'paid';

  String get paymentMethodTitle {
    switch (paymentMethod) {
      case 'online_upi':
        return 'UPI Payment (Simulated)';
      case 'online_card':
        return 'Card Payment (Simulated)';
      case 'online_netbanking':
        return 'Net Banking (Simulated)';
      case 'pay_on_delivery':
      default:
        return 'Pay on Delivery';
    }
  }

  Booking copyWith({
    String? id,
    String? bookingNumber,
    String? serviceTitle,
    String? serviceDescription,
    String? vehicleName,
    String? vehicleNumber,
    DateTime? dateTime,
    String? timeSlot,
    double? totalAmount,
    double? servicePrice,
    double? pickupFee,
    double? discountAmount,
    double? taxAmount,
    String? pickupType,
    String? address,
    String? couponCode,
    BookingStatus? status,
    String? workshopName,
    String? assignedMechanic,
    String? serviceId,
    String? vehicleId,
    String? serviceMode,
    String? backendStatus,
    String? notes,
    String? packageName,
    String? warrantyPeriod,
    String? duration,
    List<String>? includedItems,
    List<String>? checklist,
    List<String>? exclusions,
    int? rating,
    String? ratingFeedback,
    List<String>? ratingCategories,
    bool? isRated,
    String? paymentMethod,
    String? paymentStatus,
    String? paymentReference,
    DateTime? paidAt,
  }) {
    return Booking(
      id: id ?? this.id,
      bookingNumber: bookingNumber ?? this.bookingNumber,
      serviceTitle: serviceTitle ?? this.serviceTitle,
      serviceDescription: serviceDescription ?? this.serviceDescription,
      vehicleName: vehicleName ?? this.vehicleName,
      vehicleNumber: vehicleNumber ?? this.vehicleNumber,
      dateTime: dateTime ?? this.dateTime,
      timeSlot: timeSlot ?? this.timeSlot,
      totalAmount: totalAmount ?? this.totalAmount,
      servicePrice: servicePrice ?? this.servicePrice,
      pickupFee: pickupFee ?? this.pickupFee,
      discountAmount: discountAmount ?? this.discountAmount,
      taxAmount: taxAmount ?? this.taxAmount,
      pickupType: pickupType ?? this.pickupType,
      address: address ?? this.address,
      couponCode: couponCode ?? this.couponCode,
      status: status ?? this.status,
      workshopName: workshopName ?? this.workshopName,
      assignedMechanic: assignedMechanic ?? this.assignedMechanic,
      serviceId: serviceId ?? this.serviceId,
      vehicleId: vehicleId ?? this.vehicleId,
      serviceMode: serviceMode ?? this.serviceMode,
      backendStatus: backendStatus ?? this.backendStatus,
      notes: notes ?? this.notes,
      packageName: packageName ?? this.packageName,
      warrantyPeriod: warrantyPeriod ?? this.warrantyPeriod,
      duration: duration ?? this.duration,
      includedItems: includedItems ?? this.includedItems,
      checklist: checklist ?? this.checklist,
      exclusions: exclusions ?? this.exclusions,
      rating: rating ?? this.rating,
      ratingFeedback: ratingFeedback ?? this.ratingFeedback,
      ratingCategories: ratingCategories ?? this.ratingCategories,
      isRated: isRated ?? (rating != null ? true : this.isRated),
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      paymentReference: paymentReference ?? this.paymentReference,
      paidAt: paidAt ?? this.paidAt,
    );
  }
}
