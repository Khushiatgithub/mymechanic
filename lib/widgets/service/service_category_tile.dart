import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../models/service_category.dart';

class ServiceCategoryTile extends StatelessWidget {
  final ServiceCategory category;
  final VoidCallback onTap;

  const ServiceCategoryTile({
    super.key,
    required this.category,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Icon Container with subtle badge
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: category.backgroundColor,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: category.tintColor.withValues(alpha: 0.12),
                    width: 1,
                  ),
                ),
                child: Center(
                  child: Icon(
                    category.icon,
                    size: 28,
                    color: category.tintColor,
                  ),
                ),
              ),
              if (category.badgeText != null)
                Positioned(
                  top: -6,
                  right: -8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.3),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      category.badgeText!,
                      style: const TextStyle(
                        fontSize: 8,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          // Category Name
          SizedBox(
            width: 76,
            child: Text(
              category.name,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.labelSmall.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
                height: 1.2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
