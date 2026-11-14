import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

/// Item data for the prominent 2-column service category cards.
class MainCategoryItem {
  final String title;
  final String subtitle;
  final String badgeText;
  final IconData icon;
  final Color iconBgColor;
  final Color iconColor;
  final String categoryId;

  const MainCategoryItem({
    required this.title,
    required this.subtitle,
    required this.badgeText,
    required this.icon,
    required this.iconBgColor,
    required this.iconColor,
    required this.categoryId,
  });
}

/// 2-Column Main Service Categories for MyMechanic Home Screen.
///
/// Matches the reference layout:
/// - Row 1: Car Services (Heavy Discount), Denting & Painting (2 Years Warranty)
/// - Row 2: AC Service & Repair (Lowest Prices), Car Spa & Cleaning (Starting from ₹99/-)
///
/// Features:
/// - Large automotive illustration/icon in tinted container.
/// - Clean category title and micro-copy.
/// - Green promotion badge in top-right.
/// - Subtle elevation, clean white card, comfortable internal padding.
class MainServiceCategories extends StatelessWidget {
  final ValueChanged<String> onCategoryTap;

  const MainServiceCategories({
    super.key,
    required this.onCategoryTap,
  });

  static const List<MainCategoryItem> _items = [
    MainCategoryItem(
      title: 'Car Services',
      subtitle: 'Periodic • Oil & Filters',
      badgeText: 'Flat ₹500 OFF',
      icon: Icons.car_repair_rounded,
      iconBgColor: Color(0xFFFFECEB),
      iconColor: Color(0xFFDC2626),
      categoryId: 'srv_cat_periodic',
    ),
    MainCategoryItem(
      title: 'Denting & Painting',
      subtitle: 'Scratch • Panels • Touchup',
      badgeText: 'From ₹850',
      icon: Icons.format_paint_rounded,
      iconBgColor: Color(0xFFF5F3FF),
      iconColor: Color(0xFF7C3AED),
      categoryId: 'srv_cat_denting',
    ),
    MainCategoryItem(
      title: 'AC Service & Repair',
      subtitle: 'Gas Refill • Cooling Coil',
      badgeText: 'From ₹499',
      icon: Icons.ac_unit_rounded,
      iconBgColor: Color(0xFFEBF5FF),
      iconColor: Color(0xFF2563EB),
      categoryId: 'srv_cat_ac',
    ),
    MainCategoryItem(
      title: 'Car Spa & Cleaning',
      subtitle: 'Foam Wash • Interior Spa',
      badgeText: 'Starting ₹499',
      icon: Icons.local_car_wash_rounded,
      iconBgColor: Color(0xFFECFDF5),
      iconColor: Color(0xFF059669),
      categoryId: 'srv_cat_spa',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final cardWidth = (constraints.maxWidth - 12) / 2;

          return Wrap(
            spacing: 12,
            runSpacing: 12,
            children: _items.map((item) {
              return SizedBox(
                width: cardWidth,
                child: _buildCard(context, item),
              );
            }).toList(),
          );
        },
      ),
    );
  }

  Widget _buildCard(BuildContext context, MainCategoryItem item) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.border.withValues(alpha: 0.6),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => onCategoryTap(item.categoryId),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(10, 10, 10, 14),
            child: Stack(
              children: [
                // Card Content (Centered Warm Illustration + Centered Title)
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 10),
                    // Centered warm illustration container
                    Center(
                      child: Container(
                        width: 72,
                        height: 60,
                        decoration: BoxDecoration(
                          gradient: RadialGradient(
                            colors: isDark
                                ? [
                                    item.iconColor.withValues(alpha: 0.22),
                                    item.iconColor.withValues(alpha: 0.06),
                                    Colors.transparent,
                                  ]
                                : [
                                    const Color(0xFFFFF3D6).withValues(alpha: 0.9),
                                    const Color(0xFFFFF9EE).withValues(alpha: 0.4),
                                    Colors.transparent,
                                  ],
                            radius: 0.75,
                          ),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Center(
                          child: Icon(
                            item.icon,
                            size: 38,
                            color: item.iconColor,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Centered Category Title
                    Center(
                      child: Text(
                        item.title,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w800,
                          color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                          letterSpacing: -0.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),

                // Promotional Green Badge at Top Right
                Positioned(
                  top: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF143322) : const Color(0xFFE8F5E9),
                      borderRadius: BorderRadius.circular(5),
                      border: isDark
                          ? Border.all(color: const Color(0xFF166534).withValues(alpha: 0.5), width: 0.8)
                          : null,
                    ),
                    child: Text(
                      item.badgeText,
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w800,
                        color: isDark ? const Color(0xFF4ADE80) : const Color(0xFF2E7D32),
                        letterSpacing: 0.1,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
