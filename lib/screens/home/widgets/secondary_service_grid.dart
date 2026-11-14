import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

/// Item data for the compact 4-column secondary service grid.
class SecondaryCategoryItem {
  final String title;
  final String? badgeText;
  final IconData icon;
  final Color iconBgColor;
  final Color iconColor;
  final String categoryId;

  const SecondaryCategoryItem({
    required this.title,
    this.badgeText,
    required this.icon,
    required this.iconBgColor,
    required this.iconColor,
    required this.categoryId,
  });
}

/// 4-Column Compact Secondary Service Grid for MyMechanic Home Screen.
///
/// Features:
/// - 8 essential automotive categories in a clean 4-column layout:
///   1. Detailing Services (Teflon/PPF)
///   2. Batteries (Free Fitting)
///   3. Tyres & Wheel Care (Alignment)
///   4. Car Inspections (150-Point)
///   5. Clutch & Body Parts (OEM Spares)
///   6. Windshield & Lights (AIS Glass)
///   7. Suspension & Fitments (Shockers)
///   8. Insurance / Claims (Cashless)
/// - Consistent height, subtle shadows, clean rounded corners.
/// - Highly optimized for 360-420 dp widths without text clipping or RenderFlex overflow.
class SecondaryServiceGrid extends StatelessWidget {
  final ValueChanged<String> onCategoryTap;

  const SecondaryServiceGrid({
    super.key,
    required this.onCategoryTap,
  });

  static const List<SecondaryCategoryItem> _items = [
    SecondaryCategoryItem(
      title: 'Detailing\nServices',
      icon: Icons.auto_awesome_rounded,
      iconBgColor: Color(0xFFFDF4FF),
      iconColor: Color(0xFFC026D3),
      categoryId: 'srv_cat_spa',
    ),
    SecondaryCategoryItem(
      title: 'Batteries',
      icon: Icons.battery_charging_full_rounded,
      iconBgColor: Color(0xFFFFFBEB),
      iconColor: Color(0xFFD97706),
      categoryId: 'srv_cat_battery',
    ),
    SecondaryCategoryItem(
      title: 'Tyres &\nWheel Care',
      icon: Icons.album_rounded,
      iconBgColor: Color(0xFFF1F5F9),
      iconColor: Color(0xFF475569),
      categoryId: 'srv_cat_tyre',
    ),
    SecondaryCategoryItem(
      title: 'Car\nInspections',
      badgeText: 'At Your Home',
      icon: Icons.assignment_turned_in_rounded,
      iconBgColor: Color(0xFFEFF6FF),
      iconColor: Color(0xFF2563EB),
      categoryId: 'srv_cat_inspection',
    ),
    SecondaryCategoryItem(
      title: 'Clutch &\nBody Parts',
      icon: Icons.settings_suggest_rounded,
      iconBgColor: Color(0xFFFFF7ED),
      iconColor: Color(0xFFEA580C),
      categoryId: 'srv_cat_clutch',
    ),
    SecondaryCategoryItem(
      title: 'Windshield &\nLights',
      icon: Icons.light_mode_rounded,
      iconBgColor: Color(0xFFECFEFF),
      iconColor: Color(0xFF0891B2),
      categoryId: 'srv_cat_windshield',
    ),
    SecondaryCategoryItem(
      title: 'Suspension &\nFitments',
      badgeText: 'Free Inspection',
      icon: Icons.construction_rounded,
      iconBgColor: Color(0xFFF0FDF4),
      iconColor: Color(0xFF16A34A),
      categoryId: 'srv_cat_suspension',
    ),
    SecondaryCategoryItem(
      title: 'Insurance\nClaims',
      badgeText: 'Cashless Claims',
      icon: Icons.shield_rounded,
      iconBgColor: Color(0xFFFEF2F2),
      iconColor: Color(0xFFDC2626),
      categoryId: 'srv_cat_insurance',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final totalWidth = constraints.maxWidth;
          const spacing = 8.0;
          final itemWidth = (totalWidth - (3 * spacing)) / 4;

          return Wrap(
            spacing: spacing,
            runSpacing: 10,
            children: _items.map((item) {
              return SizedBox(
                width: itemWidth,
                child: _buildItemCard(context, item),
              );
            }).toList(),
          );
        },
      ),
    );
  }

  Widget _buildItemCard(BuildContext context, SecondaryCategoryItem item) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: 98,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.border.withValues(alpha: 0.6),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => onCategoryTap(item.categoryId),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Icon & Title Column
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: isDark
                            ? item.iconColor.withValues(alpha: 0.18)
                            : item.iconBgColor,
                        shape: BoxShape.circle,
                        border: isDark
                            ? Border.all(
                                color: item.iconColor.withValues(alpha: 0.35),
                                width: 0.8,
                              )
                            : null,
                      ),
                      child: Center(
                        child: Icon(
                          item.icon,
                          size: 20,
                          color: item.iconColor,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      item.title,
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                        color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                        height: 1.15,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),

                // Tiny Green Promotion Badge at Top Right (if present)
                if (item.badgeText != null)
                  Positioned(
                    top: 0,
                    right: 2,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1.5),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF143322) : const Color(0xFFE8F5E9),
                        borderRadius: BorderRadius.circular(4),
                        border: isDark
                            ? Border.all(
                                color: const Color(0xFF166534).withValues(alpha: 0.5),
                                width: 0.8,
                              )
                            : null,
                      ),
                      child: Text(
                        item.badgeText!,
                        style: TextStyle(
                          fontSize: 7.5,
                          fontWeight: FontWeight.w800,
                          color: isDark ? const Color(0xFF4ADE80) : const Color(0xFF2E7D32),
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
