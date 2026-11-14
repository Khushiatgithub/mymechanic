class Vehicle {
  final String id;
  final String? userId;
  final String brand;
  final String model;
  final String variant;
  final String fuelType;
  final String registrationNumber;
  final int year;
  final String serviceDueStatus;
  final bool isPrimary;

  // Step 4: Enhanced Vehicle Reminders & History metadata
  final DateTime? lastServiceDate;
  final String? lastServiceTitle;
  final String? nextServiceTitle;
  final DateTime? nextServiceDueDate;
  final String? nextServiceMileage;
  final String? reminderStatus;

  const Vehicle({
    required this.id,
    this.userId,
    required this.brand,
    required this.model,
    required this.variant,
    required this.fuelType,
    required this.registrationNumber,
    required this.year,
    required this.serviceDueStatus,
    this.isPrimary = false,
    this.lastServiceDate,
    this.lastServiceTitle,
    this.nextServiceTitle,
    this.nextServiceDueDate,
    this.nextServiceMileage,
    this.reminderStatus,
  });

  /// Factory mapping backend vehicle JSON schema to Flutter domain model.
  factory Vehicle.fromJson(Map<String, dynamic> json) {
    final make = json['make'] as String? ?? json['brand'] as String? ?? '';
    final model = json['model'] as String? ?? '';
    final variant = json['variant'] as String? ?? '';
    final regNum = json['registrationNumber'] as String? ?? '';
    final fuel = json['fuelType'] as String? ?? 'Petrol';
    final yr = (json['year'] as num?)?.toInt() ?? DateTime.now().year;
    final active = (json['isActive'] as bool?) ?? (json['isPrimary'] as bool?) ?? false;
    final id = json['_id'] as String? ?? json['id'] as String? ?? '';
    final userId = json['userId'] as String?;

    return Vehicle(
      id: id,
      userId: userId,
      brand: make,
      model: model,
      variant: variant.isNotEmpty ? variant : 'Standard',
      fuelType: fuel,
      registrationNumber: regNum,
      year: yr,
      serviceDueStatus: json['serviceDueStatus'] as String? ?? 'Up to date',
      isPrimary: active,
      lastServiceDate: json['lastServiceDate'] != null
          ? DateTime.tryParse(json['lastServiceDate'].toString())
          : null,
      lastServiceTitle: json['lastServiceTitle'] as String?,
      nextServiceTitle: json['nextServiceTitle'] as String?,
      nextServiceDueDate: json['nextServiceDueDate'] != null
          ? DateTime.tryParse(json['nextServiceDueDate'].toString())
          : null,
      nextServiceMileage: json['nextServiceMileage'] as String?,
      reminderStatus: json['reminderStatus'] as String?,
    );
  }

  /// Maps Flutter model to the exact payload expected by backend Vehicle API.
  Map<String, dynamic> toBackendJson() {
    return {
      'make': brand.trim(),
      'model': model.trim(),
      if (variant.trim().isNotEmpty && variant.trim() != 'Standard')
        'variant': variant.trim(),
      'registrationNumber': registrationNumber.trim().toUpperCase(),
      'fuelType': fuelType,
      'year': year,
      'isActive': isPrimary,
    };
  }

  Map<String, dynamic> toJson() => toBackendJson();

  String get fullName => '$brand $model $variant';

  int? get daysUntilNextService {
    if (nextServiceDueDate == null) return null;
    final diff = nextServiceDueDate!.difference(DateTime.now()).inDays;
    return diff >= 0 ? diff : 0;
  }

  Vehicle copyWith({
    String? id,
    String? userId,
    String? brand,
    String? model,
    String? variant,
    String? fuelType,
    String? registrationNumber,
    int? year,
    String? serviceDueStatus,
    bool? isPrimary,
    DateTime? lastServiceDate,
    String? lastServiceTitle,
    String? nextServiceTitle,
    DateTime? nextServiceDueDate,
    String? nextServiceMileage,
    String? reminderStatus,
  }) {
    return Vehicle(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      brand: brand ?? this.brand,
      model: model ?? this.model,
      variant: variant ?? this.variant,
      fuelType: fuelType ?? this.fuelType,
      registrationNumber: registrationNumber ?? this.registrationNumber,
      year: year ?? this.year,
      serviceDueStatus: serviceDueStatus ?? this.serviceDueStatus,
      isPrimary: isPrimary ?? this.isPrimary,
      lastServiceDate: lastServiceDate ?? this.lastServiceDate,
      lastServiceTitle: lastServiceTitle ?? this.lastServiceTitle,
      nextServiceTitle: nextServiceTitle ?? this.nextServiceTitle,
      nextServiceDueDate: nextServiceDueDate ?? this.nextServiceDueDate,
      nextServiceMileage: nextServiceMileage ?? this.nextServiceMileage,
      reminderStatus: reminderStatus ?? this.reminderStatus,
    );
  }
}
