import 'package:flutter/material.dart';

class Offer {
  final String id;
  final String couponCode;
  final String title;
  final String subtitle;
  final String discountTag;
  final String validTill;
  final LinearGradient gradient;
  final double discountValue;
  final bool isPercentage;
  final double? maxDiscount;
  final double minOrderValue;
  final String? eligibleCategory;
  final List<String> eligibleServiceIds;
  final List<String> terms;
  final bool isExpired;

  const Offer({
    required this.id,
    required this.couponCode,
    required this.title,
    required this.subtitle,
    required this.discountTag,
    required this.validTill,
    required this.gradient,
    this.discountValue = 0,
    this.isPercentage = false,
    this.maxDiscount,
    this.minOrderValue = 0,
    this.eligibleCategory,
    this.eligibleServiceIds = const [],
    this.terms = const [],
    this.isExpired = false,
  });

  static const List<LinearGradient> presetGradients = [
    LinearGradient(
      colors: [Color(0xFFFF5252), Color(0xFFFF7A00)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    LinearGradient(
      colors: [Color(0xFF2196F3), Color(0xFF00BCD4)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    LinearGradient(
      colors: [Color(0xFF4CAF50), Color(0xFF8BC34A)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    LinearGradient(
      colors: [Color(0xFF9C27B0), Color(0xFFE040FB)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    LinearGradient(
      colors: [Color(0xFFFF9800), Color(0xFFFFC107)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
  ];

  factory Offer.fromJson(Map<String, dynamic> json, [int index = 0]) {
    final id = json['_id']?.toString() ?? json['id']?.toString() ?? '';
    final code = json['code']?.toString() ?? json['couponCode']?.toString() ?? '';
    final title = json['title']?.toString() ?? '';
    final description = json['description']?.toString() ?? json['subtitle']?.toString() ?? '';
    final discountType = (json['discountType'] ?? '').toString().toLowerCase();
    final isPercentage = discountType == 'percentage' || json['isPercentage'] == true;
    final discountValue = (json['discountValue'] as num?)?.toDouble() ?? 0.0;
    final maxDiscount = (json['maxDiscount'] as num?)?.toDouble();
    final minOrderValue = (json['minOrderValue'] as num?)?.toDouble() ?? 0.0;

    final expiryRaw = json['expiryDate'] ?? json['validTill'];
    DateTime? expiryDate;
    if (expiryRaw != null) {
      expiryDate = DateTime.tryParse(expiryRaw.toString());
    }
    final isExpired = expiryDate != null ? DateTime.now().isAfter(expiryDate) : false;
    final validTillText = expiryDate != null
        ? 'Valid till ${expiryDate.day}/${expiryDate.month}/${expiryDate.year}'
        : (json['validTill']?.toString() ?? 'Limited time');

    final discountTag = isPercentage
        ? '${discountValue.toInt()}% OFF'
        : '₹${discountValue.toInt()} FLAT OFF';

    List<String> terms = [];
    if (json['terms'] is List) {
      terms = (json['terms'] as List).map((e) => e.toString()).toList();
    }

    List<String> eligibleServiceIds = [];
    if (json['eligibleServiceIds'] is List) {
      eligibleServiceIds =
          (json['eligibleServiceIds'] as List).map((e) => e.toString()).toList();
    }

    final gradient = presetGradients[index % presetGradients.length];

    return Offer(
      id: id,
      couponCode: code,
      title: title,
      subtitle: description,
      discountTag: discountTag,
      validTill: validTillText,
      gradient: gradient,
      discountValue: discountValue,
      isPercentage: isPercentage,
      maxDiscount: maxDiscount,
      minOrderValue: minOrderValue,
      eligibleCategory: json['eligibleCategory']?.toString(),
      eligibleServiceIds: eligibleServiceIds,
      terms: terms,
      isExpired: isExpired,
    );
  }
}
