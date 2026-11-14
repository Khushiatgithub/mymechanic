import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../data/mock_data.dart';
import '../../models/service_item.dart';
import '../common/rating_badge.dart';

class PopularServiceCard extends StatelessWidget {
  final ServiceItem service;
  final VoidCallback onTap;
  final VoidCallback onBook;

  const PopularServiceCard({
    super.key,
    required this.service,
    required this.onTap,
    required this.onBook,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      width: 290,
      margin: const EdgeInsets.only(right: 14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.border,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Rating, Duration, & Favorite row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: RatingBadge(
                        rating: service.rating,
                        reviewsCount: service.reviewsCount,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.darkInputSurface : AppColors.surfaceVariant,
                            borderRadius: BorderRadius.circular(6),
                            border: isDark
                                ? Border.all(color: AppColors.darkBorder, width: 0.8)
                                : null,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.access_time_rounded,
                                size: 11,
                                color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                              ),
                              const SizedBox(width: 3),
                              Text(
                                service.durationText,
                                style: AppTypography.bodySmall.copyWith(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 6),
                        ValueListenableBuilder<Set<String>>(
                          valueListenable: MockData.favoriteServiceIdsNotifier,
                          builder: (context, favs, _) {
                            final isFav = favs.contains(service.id);
                            return InkWell(
                              onTap: () {
                                MockData.toggleServiceFavorite(service.id);
                              },
                              borderRadius: BorderRadius.circular(14),
                              child: Padding(
                                padding: const EdgeInsets.all(2),
                                child: Icon(
                                  isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                                  color: isFav
                                      ? AppColors.error
                                      : (isDark ? AppColors.darkTextSecondary : AppColors.textSecondary),
                                  size: 18,
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Title
                Text(
                  service.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.titleSmall.copyWith(
                    fontWeight: FontWeight.w700,
                    height: 1.25,
                    color: isDark ? AppColors.darkTextPrimary : null,
                  ),
                ),
                const SizedBox(height: 8),

                // Warranty Tag
                Row(
                  children: [
                    const Icon(
                      Icons.verified_user_rounded,
                      size: 14,
                      color: AppColors.success,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        service.warrantyPeriod,
                        style: AppTypography.labelSmall.copyWith(
                          color: AppColors.success,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Features Checklist Preview (up to 2 items)
                ...service.keyFeatures.take(2).map(
                      (feat) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.check_circle_outline_rounded,
                              size: 13,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                feat,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTypography.bodySmall.copyWith(
                                  color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                const Spacer(),
                Divider(
                  height: 14,
                  color: isDark ? AppColors.darkBorder : null,
                ),

                // Price and Book Action
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            crossAxisAlignment: WrapCrossAlignment.center,
                            spacing: 4,
                            children: [
                              Text(
                                '${AppConstants.currencySymbol}${service.price.toInt()}',
                                style: AppTypography.priceLarge.copyWith(
                                  color: isDark ? AppColors.darkTextPrimary : null,
                                ),
                              ),
                              Text(
                                '${AppConstants.currencySymbol}${service.originalPrice.toInt()}',
                                style: AppTypography.priceStrike.copyWith(
                                  color: isDark ? AppColors.darkTextMuted : null,
                                ),
                              ),
                            ],
                          ),
                          if (service.discountPercentage > 0)
                            Text(
                              '${service.discountPercentage}% OFF',
                              style: AppTypography.labelSmall.copyWith(
                                color: AppColors.success,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                        ],
                      ),
                    ),
                    ElevatedButton(
                      onPressed: onBook,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Book',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          SizedBox(width: 4),
                          Icon(Icons.add_rounded, size: 16),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
