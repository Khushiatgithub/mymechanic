import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/vehicle.dart';
import 'sell_car_valuation_sheet.dart';

class _CuratedItemData {
  final String id;
  final String title;
  final String? imageAsset;
  final String? badgeText;
  final Color? badgeColor;
  final bool isSellCar;
  final String searchKeyword;

  const _CuratedItemData({
    required this.id,
    required this.title,
    this.imageAsset,
    this.badgeText,
    this.badgeColor,
    this.isSellCar = false,
    required this.searchKeyword,
  });
}

/// 2-row horizontally scrollable grid of "Curated Custom Services" matching the reference screenshot.
/// Shows ~3.3 items across so the 4th item peeks on the right edge.
class CuratedCustomServices extends StatelessWidget {
  final ValueChanged<String> onCategoryTap;
  final Vehicle? activeVehicle;

  const CuratedCustomServices({
    super.key,
    required this.onCategoryTap,
    this.activeVehicle,
  });

  // Top row items
  static const List<_CuratedItemData> _topRow = [
    _CuratedItemData(
      id: 'batteries',
      title: 'Batteries',
      imageAsset: AppConstants.curatedBattery,
      badgeText: 'SALE',
      badgeColor: Color(0xFF22C55E),
      searchKeyword: 'Batteries',
    ),
    _CuratedItemData(
      id: 'ac_parts',
      title: 'AC Parts',
      imageAsset: AppConstants.curatedAc,
      searchKeyword: 'AC',
    ),
    _CuratedItemData(
      id: 'tyres',
      title: 'Tyres',
      imageAsset: AppConstants.curatedTyres,
      badgeText: 'SALE',
      badgeColor: Color(0xFF22C55E),
      searchKeyword: 'Tyres',
    ),
    _CuratedItemData(
      id: 'suspension',
      title: 'Suspension',
      imageAsset: AppConstants.curatedSuspension,
      searchKeyword: 'Suspension',
    ),
    _CuratedItemData(
      id: 'windshield',
      title: 'Windshield',
      imageAsset: AppConstants.curatedLights,
      searchKeyword: 'Windshield',
    ),
  ];

  // Bottom row items
  static const List<_CuratedItemData> _bottomRow = [
    _CuratedItemData(
      id: 'brakes',
      title: 'Brakes',
      imageAsset: AppConstants.curatedBrakes,
      searchKeyword: 'Brakes',
    ),
    _CuratedItemData(
      id: 'clutch',
      title: 'Clutch',
      imageAsset: AppConstants.curatedClutch,
      badgeText: 'NEW',
      badgeColor: Color(0xFF22C55E),
      searchKeyword: 'Clutch',
    ),
    _CuratedItemData(
      id: 'sell_your_car',
      title: 'Sell Your Car',
      isSellCar: true,
      searchKeyword: 'Sell Car',
    ),
    _CuratedItemData(
      id: 'lights',
      title: 'Lights & Fitments',
      imageAsset: AppConstants.curatedLights,
      searchKeyword: 'Lights',
    ),
    _CuratedItemData(
      id: 'car_spa',
      title: 'Car Spa',
      imageAsset: AppConstants.curatedAc,
      badgeText: 'SALE',
      badgeColor: Color(0xFF22C55E),
      searchKeyword: 'Spa',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Title
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Builder(
            builder: (context) {
              final isDark = Theme.of(context).brightness == Brightness.dark;
              return Text(
                'Curated Custom Services',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: isDark ? AppColors.darkTextPrimary : const Color(0xFF1E293B),
                  letterSpacing: -0.3,
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 14),

        // Horizontal scrolling two rows
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Row 1
              Row(
                children: _topRow.map((item) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 18),
                    child: _buildItemCard(context, item),
                  );
                }).toList(),
              ),
              const SizedBox(height: 14),

              // Row 2
              Row(
                children: _bottomRow.map((item) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 18),
                    child: _buildItemCard(context, item),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildItemCard(BuildContext context, _CuratedItemData item) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: () {
        if (item.isSellCar) {
          SellCarValuationSheet.show(
            context: context,
            vehicle: activeVehicle,
          );
        } else {
          onCategoryTap(item.searchKeyword);
        }
      },
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        width: 72,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Circular Avatar with Badge
            Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isDark ? AppColors.darkSurface : Colors.white,
                    border: Border.all(
                      color: isDark ? AppColors.darkBorder : Colors.grey.shade200,
                      width: 1.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.05),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: item.isSellCar
                        ? _buildSellCarIcon()
                        : Image.asset(
                            item.imageAsset!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Icon(
                              Icons.build_circle_rounded,
                              color: isDark ? AppColors.darkTextSecondary : Colors.grey,
                              size: 28,
                            ),
                          ),
                  ),
                ),

                // SALE or NEW green pill badge at bottom
                if (item.badgeText != null)
                  Positioned(
                    bottom: -3,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF166534)
                            : (item.badgeColor ?? const Color(0xFF22C55E)),
                        borderRadius: BorderRadius.circular(6),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.15),
                            blurRadius: 3,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      child: Text(
                        item.badgeText!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 7),

            // Label
            Text(
              item.title,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.darkTextPrimary : const Color(0xFF334155),
                letterSpacing: -0.1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSellCarIcon() {
    return Container(
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: Color(0xFFC2185B),
      ),
      child: Center(
        child: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: const Color(0xFFE91E63),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Center(
            child: Text(
              'S',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
