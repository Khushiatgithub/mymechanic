import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../data/mock_data.dart';
import '../../models/service_package.dart';

class ServicePackageCard extends StatefulWidget {
  final ServicePackage package;
  final VoidCallback onBook;

  const ServicePackageCard({
    super.key,
    required this.package,
    required this.onBook,
  });

  @override
  State<ServicePackageCard> createState() => _ServicePackageCardState();
}

class _ServicePackageCardState extends State<ServicePackageCard> {
  bool _isExpanded = false;

  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final pkg = widget.package;
    final displayedChecklist = _isExpanded ? pkg.checklist : pkg.checklist.take(3).toList();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: pkg.isRecommended
              ? AppColors.primary
              : (isDark ? AppColors.darkBorder : AppColors.border),
          width: pkg.isRecommended ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: pkg.isRecommended
                ? AppColors.primary.withValues(alpha: isDark ? 0.18 : 0.08)
                : Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Material(
          color: Colors.transparent,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Recommended Header Strip
              if (pkg.isRecommended)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.thumb_up_alt_rounded, size: 14, color: Colors.white),
                      const SizedBox(width: 6),
                      Text(
                        'MOST RECOMMENDED BY MECHANICS',
                        style: AppTypography.labelSmall.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),

              // Tappable Card Body (Bug 8: Tapping card expands/collapses details)
              InkWell(
                onTap: _toggleExpanded,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title and Interval Tag + Price
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  pkg.title,
                                  style: AppTypography.titleMedium.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: isDark ? AppColors.darkTextPrimary : null,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: isDark ? AppColors.darkInputSurface : AppColors.surfaceVariant,
                                    borderRadius: BorderRadius.circular(6),
                                    border: isDark
                                        ? Border.all(color: AppColors.darkBorder, width: 0.8)
                                        : null,
                                  ),
                                  child: Text(
                                    pkg.tag,
                                    style: AppTypography.labelSmall.copyWith(
                                      color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Price
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    '${AppConstants.currencySymbol}${pkg.price.toInt()}',
                                    style: AppTypography.priceLarge.copyWith(
                                      color: AppColors.primary,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${AppConstants.currencySymbol}${pkg.originalPrice.toInt()}',
                                    style: AppTypography.priceStrike.copyWith(
                                      color: isDark ? AppColors.darkTextMuted : null,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  ValueListenableBuilder<Set<String>>(
                                    valueListenable: MockData.favoritePackageIdsNotifier,
                                    builder: (context, favs, _) {
                                      final isFav = favs.contains(pkg.id);
                                      return InkWell(
                                        onTap: () {
                                          MockData.togglePackageFavorite(pkg.id);
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
                              if (pkg.savingsPercentage > 0)
                                Container(
                                  margin: const EdgeInsets.only(top: 2),
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: isDark ? const Color(0xFF143322) : AppColors.successBg,
                                    borderRadius: BorderRadius.circular(4),
                                    border: isDark
                                        ? Border.all(color: const Color(0xFF166534).withValues(alpha: 0.5), width: 0.8)
                                        : null,
                                  ),
                                  child: Text(
                                    'SAVE ${pkg.savingsPercentage}%',
                                    style: AppTypography.labelSmall.copyWith(
                                      color: isDark ? const Color(0xFF4ADE80) : AppColors.success,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // Description
                      Text(
                        pkg.description,
                        style: AppTypography.bodySmall.copyWith(
                          color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Time Taken Tag & Expand Hint
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Wrap(
                              crossAxisAlignment: WrapCrossAlignment.center,
                              spacing: 8,
                              runSpacing: 4,
                              children: [
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.schedule_rounded,
                                      size: 14,
                                      color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      pkg.timeTakenText,
                                      style: AppTypography.bodySmall.copyWith(
                                        fontWeight: FontWeight.w600,
                                        color: isDark ? AppColors.darkTextSecondary : null,
                                      ),
                                    ),
                                  ],
                                ),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.shield_outlined,
                                      size: 14,
                                      color: AppColors.success,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      pkg.warranty,
                                      style: AppTypography.labelSmall.copyWith(
                                        color: AppColors.success,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _isExpanded ? 'Hide Checklist' : 'Tap to View Details',
                                style: AppTypography.labelSmall.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Icon(
                                _isExpanded
                                    ? Icons.keyboard_arrow_up_rounded
                                    : Icons.keyboard_arrow_down_rounded,
                                size: 18,
                                color: AppColors.primary,
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      Divider(
                        color: isDark ? AppColors.darkBorder : null,
                      ),
                      const SizedBox(height: 8),

                      // Checklist Title
                      Text(
                        'What\'s Included (${pkg.checklist.length} Services):',
                        style: AppTypography.labelMedium.copyWith(
                          color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Checklist Items
                      ...displayedChecklist.map(
                        (item) => Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Padding(
                                padding: EdgeInsets.only(top: 2),
                                child: Icon(
                                  Icons.check_circle_rounded,
                                  size: 14,
                                  color: AppColors.success,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  item,
                                  style: AppTypography.bodySmall.copyWith(
                                    color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                                    height: 1.3,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      if (!_isExpanded && pkg.checklist.length > 3)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            '+ ${pkg.checklist.length - 3} more services included...',
                            style: AppTypography.labelSmall.copyWith(
                              color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              // Select / Book Button (Bug 9: Intentional Booking Action)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: ElevatedButton(
                    onPressed: widget.onBook,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: pkg.isRecommended
                          ? AppColors.primary
                          : (isDark ? const Color(0xFF202631) : AppColors.secondary),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: isDark && !pkg.isRecommended
                            ? const BorderSide(color: AppColors.darkBorder, width: 1)
                            : BorderSide.none,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Select Package',
                          style: AppTypography.labelLarge.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Icon(Icons.arrow_forward_rounded, size: 16),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
