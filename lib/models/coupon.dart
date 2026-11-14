enum CouponDiscountType {
  flat,
  percentage,
}

class CouponValidationResult {
  final bool isValid;
  final String? errorMessage;

  String? get reason => errorMessage;

  const CouponValidationResult.valid() : isValid = true, errorMessage = null;
  const CouponValidationResult.invalid(this.errorMessage) : isValid = false;
}

class Coupon {
  final String code;
  final String title;
  final String description;
  final CouponDiscountType discountType;
  final double discountValue;
  final double? maxDiscount;
  final double minOrderValue;
  final DateTime expiryDate;
  final String? eligibleCategory;
  final List<String> eligibleServiceIds;
  final int? usageLimit;
  final int currentUsageCount;
  final bool isActive;
  final List<String> terms;

  const Coupon({
    required this.code,
    required this.title,
    required this.description,
    required this.discountType,
    required this.discountValue,
    this.maxDiscount,
    this.minOrderValue = 0,
    required this.expiryDate,
    this.eligibleCategory,
    this.eligibleServiceIds = const [],
    this.usageLimit,
    this.currentUsageCount = 0,
    this.isActive = true,
    this.terms = const [],
  });

  bool get isExpired => DateTime.now().isAfter(expiryDate);
  bool get isUsageLimitReached => usageLimit != null && currentUsageCount >= usageLimit!;

  CouponValidationResult validate({
    required double orderAmount,
    String? category,
    String? serviceId,
  }) {
    if (!isActive) {
      return const CouponValidationResult.invalid('Coupon is currently inactive');
    }
    if (isExpired) {
      return const CouponValidationResult.invalid('This coupon has expired');
    }
    if (isUsageLimitReached) {
      return const CouponValidationResult.invalid('Maximum usage limit reached');
    }
    if (orderAmount < minOrderValue) {
      return CouponValidationResult.invalid(
        'Minimum order value is ₹${minOrderValue.toInt()}',
      );
    }
    if (eligibleCategory != null && eligibleCategory!.isNotEmpty) {
      if (category == null || !category.toLowerCase().contains(eligibleCategory!.toLowerCase())) {
        return CouponValidationResult.invalid(
          'This coupon is valid only for $eligibleCategory',
        );
      }
    }
    if (eligibleServiceIds.isNotEmpty) {
      if (serviceId == null || !eligibleServiceIds.contains(serviceId)) {
        return const CouponValidationResult.invalid(
          'Coupon is not valid for this service',
        );
      }
    }
    return const CouponValidationResult.valid();
  }

  double calculateDiscount(double eligibleSubtotal) {
    if (eligibleSubtotal <= 0) return 0.0;
    double discount = 0.0;
    if (discountType == CouponDiscountType.flat) {
      discount = discountValue;
    } else {
      discount = eligibleSubtotal * (discountValue / 100.0);
      if (maxDiscount != null) {
        discount = discount.clamp(0.0, maxDiscount!);
      }
    }
    return discount.clamp(0.0, eligibleSubtotal);
  }

  Coupon copyWith({
    String? code,
    String? title,
    String? description,
    CouponDiscountType? discountType,
    double? discountValue,
    double? maxDiscount,
    double? minOrderValue,
    DateTime? expiryDate,
    String? eligibleCategory,
    List<String>? eligibleServiceIds,
    int? usageLimit,
    int? currentUsageCount,
    bool? isActive,
    List<String>? terms,
  }) {
    return Coupon(
      code: code ?? this.code,
      title: title ?? this.title,
      description: description ?? this.description,
      discountType: discountType ?? this.discountType,
      discountValue: discountValue ?? this.discountValue,
      maxDiscount: maxDiscount ?? this.maxDiscount,
      minOrderValue: minOrderValue ?? this.minOrderValue,
      expiryDate: expiryDate ?? this.expiryDate,
      eligibleCategory: eligibleCategory ?? this.eligibleCategory,
      eligibleServiceIds: eligibleServiceIds ?? this.eligibleServiceIds,
      usageLimit: usageLimit ?? this.usageLimit,
      currentUsageCount: currentUsageCount ?? this.currentUsageCount,
      isActive: isActive ?? this.isActive,
      terms: terms ?? this.terms,
    );
  }
}
