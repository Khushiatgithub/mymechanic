import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';

class SummerReadyItem {
  final String id;
  final String title;
  final String description;
  final int price;
  final int originalPrice;
  final IconData icon;
  final Color iconBgColor;
  final Color iconColor;
  final String durationText;
  final String warrantyPeriod;

  const SummerReadyItem({
    required this.id,
    required this.title,
    required this.description,
    required this.price,
    required this.originalPrice,
    required this.icon,
    required this.iconBgColor,
    required this.iconColor,
    required this.durationText,
    required this.warrantyPeriod,
  });
}

/// 2x2 Grid for "Get Summer Ready With MyMechanic" seasonal car services.
class SummerReadyGrid extends StatelessWidget {
  final ValueChanged<SummerReadyItem> onBookItem;

  const SummerReadyGrid({
    super.key,
    required this.onBookItem,
  });

  static const List<SummerReadyItem> items = [
    SummerReadyItem(
      id: 'summer_bumper_paint',
      title: 'Front Bumper Paint',
      description: 'DuPont color-match paint booth finish & anti-scratch clear coat',
      price: 1999,
      originalPrice: 2800,
      icon: Icons.format_paint_rounded,
      iconBgColor: Color(0xFFFFECEB),
      iconColor: Color(0xFFDC2626),
      durationText: '24 Hours',
      warrantyPeriod: '2 Years Paint Warranty',
    ),
    SummerReadyItem(
      id: 'summer_rubbing_polish',
      title: 'Rubbing & Polishing',
      description: '3M compound machine buffing, minor scratch removal & deep gloss',
      price: 1299,
      originalPrice: 1999,
      icon: Icons.auto_awesome_rounded,
      iconBgColor: Color(0xFFFFFBEB),
      iconColor: Color(0xFFD97706),
      durationText: '3 Hours',
      warrantyPeriod: 'High Gloss Guarantee',
    ),
    SummerReadyItem(
      id: 'summer_deep_spa',
      title: 'Deep All Round Spa',
      description: 'Interior steam extraction, anti-microbial sanitization & foam wash',
      price: 1499,
      originalPrice: 2200,
      icon: Icons.local_car_wash_rounded,
      iconBgColor: Color(0xFFEBF5FF),
      iconColor: Color(0xFF2563EB),
      durationText: '3.5 Hours',
      warrantyPeriod: 'Cleanliness Guarantee',
    ),
    SummerReadyItem(
      id: 'summer_standard_service',
      title: 'Standard Service',
      description: 'Engine oil top-grade replacement, AC coolant check & 60-pt scan',
      price: 3199,
      originalPrice: 4500,
      icon: Icons.settings_suggest_rounded,
      iconBgColor: Color(0xFFECFDF5),
      iconColor: Color(0xFF059669),
      durationText: '4 Hours',
      warrantyPeriod: '1000 Kms / 1 Month Warranty',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Get Summer Ready With MyMechanic',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Beat the heat with seasonal protective maintenance',
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
                  color: const Color(0xFFFFFBEB),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFFFDE68A)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.wb_sunny_rounded, size: 12, color: Color(0xFFD97706)),
                    SizedBox(width: 4),
                    Text(
                      'SEASONAL',
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFFD97706),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: items.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.98,
            ),
            itemBuilder: (context, index) {
              final item = items[index];
              return _buildGridCard(context, item);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildGridCard(BuildContext context, SummerReadyItem item) {
    return InkWell(
      onTap: () => onBookItem(item),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border.withValues(alpha: 0.8)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: item.iconBgColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(item.icon, color: item.iconColor, size: 20),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.successBg,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '${(((item.originalPrice - item.price) / item.originalPrice) * 100).round()}% OFF',
                    style: const TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w800,
                      color: AppColors.success,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              item.title,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
                height: 1.15,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              item.description,
              style: const TextStyle(
                fontSize: 10.5,
                color: AppColors.textSecondary,
                height: 1.2,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '₹${item.price}',
                      style: const TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w900,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      '₹${item.originalPrice}',
                      style: const TextStyle(
                        fontSize: 10.5,
                        color: AppColors.textMuted,
                        decoration: TextDecoration.lineThrough,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'BOOK',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
