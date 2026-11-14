import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';

class ComboPackageItem {
  final String id;
  final String title;
  final String popularTag;
  final List<String> highlights;
  final int price;
  final int originalPrice;
  final String durationText;
  final String warrantyPeriod;

  const ComboPackageItem({
    required this.id,
    required this.title,
    required this.popularTag,
    required this.highlights,
    required this.price,
    required this.originalPrice,
    required this.durationText,
    required this.warrantyPeriod,
  });

  int get discountPercent =>
      (((originalPrice - price) / originalPrice) * 100).round();
}

/// Horizontal scrolling Designer Service Combos section.
class DesignerCombosSection extends StatelessWidget {
  final ValueChanged<ComboPackageItem> onBookCombo;

  const DesignerCombosSection({
    super.key,
    required this.onBookCombo,
  });

  static const List<ComboPackageItem> combos = [
    ComboPackageItem(
      id: 'combo_festive_clean_paint',
      title: 'Festive Cleaning & Dent Paint Combo',
      popularTag: 'Added in 45 Carts',
      highlights: [
        'Front Bumper Denting & Painting',
        'Deep All Round Car Spa & Foam Wash',
        '3M Machine Rubbing & Wax Polish',
      ],
      price: 3499,
      originalPrice: 5200,
      durationText: '1 Day',
      warrantyPeriod: '1000 Kms / 1 Month Warranty',
    ),
    ComboPackageItem(
      id: 'combo_standard_spa',
      title: 'Standard Service & Car Spa Combo',
      popularTag: 'Added in 62 Carts',
      highlights: [
        'Complete Engine Oil & Filter Change',
        '60-Point Comprehensive Diagnostics',
        'Interior Deep Sanitization & Underbody Wash',
      ],
      price: 4299,
      originalPrice: 6500,
      durationText: '4 Hours',
      warrantyPeriod: '1000 Kms / 1 Month Warranty',
    ),
    ComboPackageItem(
      id: 'combo_summer_ac_spa',
      title: 'Summer AC Refresh & Deep Spa',
      popularTag: 'Added in 38 Carts',
      highlights: [
        'High Performance AC Gas Top-up',
        'Condenser Coil Jet Wash & Cabin Filter Clean',
        'Anti-Bacterial AC Vent Sanitization',
      ],
      price: 2799,
      originalPrice: 3999,
      durationText: '3 Hours',
      warrantyPeriod: '30 Days AC Cooling Warranty',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Designer Service Combos',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Curated multi-service combos with maximum savings',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'HOT DEALS',
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 220,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: combos.length,
            itemBuilder: (context, index) {
              final combo = combos[index];
              return _buildComboCard(context, combo);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildComboCard(BuildContext context, ComboPackageItem combo) {
    return Container(
      width: 305,
      margin: const EdgeInsets.only(right: 14, bottom: 4),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.8)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Tag row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFFFCA5A5)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.local_fire_department_rounded, size: 12, color: AppColors.error),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          combo.popularTag,
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: AppColors.error,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                combo.durationText,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Title
          Text(
            combo.title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
              height: 1.2,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),

          // Highlights
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: combo.highlights.take(3).map((item) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 3),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('• ', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                      Expanded(
                        child: Text(
                          item,
                          style: const TextStyle(
                            fontSize: 11.5,
                            color: AppColors.textSecondary,
                            height: 1.2,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),

          // Price and Book Button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '₹${combo.price}',
                      style: const TextStyle(
                        fontSize: 16.5,
                        fontWeight: FontWeight.w900,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '₹${combo.originalPrice}',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textMuted,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${combo.discountPercent}% OFF',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: AppColors.success,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              ElevatedButton(
                onPressed: () => onBookCombo(combo),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  elevation: 0,
                ),
                child: const Text(
                  'BOOK COMBO',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
