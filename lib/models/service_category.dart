import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';

class ServiceCategory {
  final String id;
  final String name;
  final String description;
  final IconData icon;
  final Color tintColor;
  final Color backgroundColor;
  final String? badgeText;
  final bool isActive;
  final int sortOrder;

  const ServiceCategory({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.tintColor,
    required this.backgroundColor,
    this.badgeText,
    this.isActive = true,
    this.sortOrder = 0,
  });

  /// Factory constructor to deserialize a backend JSON response.
  factory ServiceCategory.fromJson(Map<String, dynamic> json) {
    final iconName = (json['icon'] ?? '').toString().toLowerCase().trim();
    final nameLower = (json['name'] ?? '').toString().toLowerCase().trim();

    final icon = _mapIcon(iconName, nameLower);
    final colors = _mapColors(iconName, nameLower);

    return ServiceCategory(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      icon: icon,
      tintColor: colors.$1,
      backgroundColor: colors.$2,
      badgeText: json['badgeText']?.toString(),
      isActive: json['isActive'] != false,
      sortOrder: (json['sortOrder'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'badgeText': badgeText,
      'isActive': isActive,
      'sortOrder': sortOrder,
    };
  }

  static IconData _mapIcon(String iconStr, String nameLower) {
    if (iconStr.contains('build_circle') || nameLower.contains('periodic') || nameLower.contains('maintenance')) {
      return Icons.build_circle_outlined;
    }
    if (iconStr.contains('ac_unit') || nameLower.contains('ac ') || nameLower.contains('air conditioning')) {
      return Icons.ac_unit_rounded;
    }
    if (iconStr.contains('airline_seat_recline_extra') || iconStr.contains('brake') || nameLower.contains('brake') || nameLower.contains('clutch')) {
      return Icons.airline_seat_recline_extra_rounded;
    }
    if (iconStr.contains('speed') || iconStr.contains('engine') || nameLower.contains('engine')) {
      return Icons.speed_rounded;
    }
    if (iconStr.contains('battery') || nameLower.contains('battery')) {
      return Icons.battery_charging_full_rounded;
    }
    if (iconStr.contains('tire') || iconStr.contains('tyre') || iconStr.contains('wheel') || nameLower.contains('tyre') || nameLower.contains('wheel')) {
      return Icons.tire_repair_rounded;
    }
    if (iconStr.contains('wash') || iconStr.contains('spa') || iconStr.contains('detailing') || nameLower.contains('spa') || nameLower.contains('detailing')) {
      return Icons.local_car_wash_rounded;
    }
    if (iconStr.contains('check') || iconStr.contains('inspect') || nameLower.contains('inspection')) {
      return Icons.checklist_rounded;
    }
    if (iconStr.contains('paint') || nameLower.contains('dent') || nameLower.contains('paint')) {
      return Icons.format_paint_rounded;
    }
    return Icons.miscellaneous_services_rounded;
  }

  static (Color, Color) _mapColors(String iconStr, String nameLower) {
    if (nameLower.contains('periodic') || nameLower.contains('brake') || iconStr.contains('build_circle')) {
      return (AppColors.categoryRed, AppColors.categoryRedBg);
    }
    if (nameLower.contains('ac ') || nameLower.contains('air conditioning') || iconStr.contains('ac_unit')) {
      return (AppColors.categoryBlue, AppColors.categoryBlueBg);
    }
    if (nameLower.contains('tyre') || nameLower.contains('wheel') || iconStr.contains('tire')) {
      return (AppColors.categoryGreen, AppColors.categoryGreenBg);
    }
    if (nameLower.contains('spa') || nameLower.contains('detailing') || iconStr.contains('wash')) {
      return (AppColors.categoryTeal, AppColors.categoryTealBg);
    }
    if (nameLower.contains('battery') || nameLower.contains('engine') || iconStr.contains('speed') || iconStr.contains('battery')) {
      return (AppColors.categoryAmber, AppColors.categoryAmberBg);
    }
    if (nameLower.contains('inspection') || iconStr.contains('check')) {
      return (AppColors.categoryPurple, AppColors.categoryPurpleBg);
    }
    return (AppColors.primary, AppColors.primaryLight.withValues(alpha: 0.2));
  }
}
