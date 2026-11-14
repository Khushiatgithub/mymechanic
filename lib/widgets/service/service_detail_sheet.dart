import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../data/mock_data.dart';
import '../../models/service_item.dart';
import '../../models/service_package.dart';
import '../common/rating_badge.dart';

class ServiceDetailSheet extends StatefulWidget {
  final ServiceItem service;
  final VoidCallback onBookNow;
  final void Function(ServicePackage package)? onBookPackage;

  const ServiceDetailSheet({
    super.key,
    required this.service,
    required this.onBookNow,
    this.onBookPackage,
  });

  static Future<void> show({
    required BuildContext context,
    required ServiceItem service,
    required VoidCallback onBookNow,
    void Function(ServicePackage package)? onBookPackage,
  }) {
    MockData.addRecentlyViewed(service.id);
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ServiceDetailSheet(
        service: service,
        onBookNow: onBookNow,
        onBookPackage: onBookPackage,
      ),
    );
  }

  @override
  State<ServiceDetailSheet> createState() => _ServiceDetailSheetState();
}

class _ServiceDetailSheetState extends State<ServiceDetailSheet> {
  String? _expandedPackageId;

  List<ServicePackage> get _relatedPackages {
    if (widget.service.packageIds.isNotEmpty) {
      return MockData.servicePackages
          .where((p) => widget.service.packageIds.contains(p.id))
          .toList();
    }
    if (widget.service.categoryId == 'cat_periodic') {
      return MockData.servicePackages;
    }
    return [];
  }

  String _getCategoryName(String catId) {
    if (widget.service.categoryName != null && widget.service.categoryName!.isNotEmpty) {
      return widget.service.categoryName!;
    }
    final cat = MockData.categories.firstWhere(
      (c) => c.id == catId,
      orElse: () => MockData.categories.first,
    );
    return cat.name;
  }

  @override
  Widget build(BuildContext context) {
    final service = widget.service;
    final relatedPkgs = _relatedPackages;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkElevatedSurface : AppColors.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: isDark ? const Border(top: BorderSide(color: AppColors.darkBorder)) : null,
          ),
          child: Column(
            children: [
              // Drag Indicator
              Padding(
                padding: const EdgeInsets.only(top: 12, bottom: 6),
                child: Center(
                  child: Container(
                    width: 44,
                    height: 4,
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkBorder : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ),

              // Scrollable Details Body
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(20, 6, 20, 24),
                  children: [
                    // Header Row: Category Badge + Close
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            _getCategoryName(service.categoryId).toUpperCase(),
                            style: AppTypography.labelSmall.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.4,
                            ),
                          ),
                        ),
                        Row(
                          children: [
                            ValueListenableBuilder<Set<String>>(
                              valueListenable: MockData.favoriteServiceIdsNotifier,
                              builder: (context, favs, _) {
                                final isFav = favs.contains(service.id);
                                return IconButton(
                                  icon: Icon(
                                    isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                                    color: isFav ? AppColors.error : AppColors.textSecondary,
                                  ),
                                  onPressed: () {
                                    MockData.toggleServiceFavorite(service.id);
                                  },
                                );
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.close_rounded),
                              onPressed: () => Navigator.pop(context),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),

                    // Service Title
                    Text(
                      service.title,
                      style: AppTypography.titleLarge.copyWith(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 10),

                    // Rating, Reviews & Starting Price Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        RatingBadge(
                          rating: service.rating,
                          reviewsCount: service.reviewsCount,
                        ),
                        Row(
                          children: [
                            Text(
                              '${AppConstants.currencySymbol}${service.price.toInt()}',
                              style: AppTypography.priceLarge.copyWith(
                                fontSize: 20,
                                color: AppColors.primary,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '${AppConstants.currencySymbol}${service.originalPrice.toInt()}',
                              style: AppTypography.priceStrike,
                            ),
                            if (service.discountPercentage > 0) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.successBg,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  'SAVE ${service.discountPercentage}%',
                                  style: AppTypography.labelSmall.copyWith(
                                    color: AppColors.success,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Key Specs Chips (Duration, Warranty, Service Type)
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildSpecChip(Icons.schedule_rounded, service.durationText),
                        _buildSpecChip(Icons.shield_outlined, service.warrantyPeriod, color: AppColors.success),
                        _buildSpecChip(Icons.home_repair_service_outlined, service.serviceType),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Description / Overview
                    Text(
                      'Overview',
                      style: AppTypography.titleSmall.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      service.description,
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Assurance Cards Row
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkSurface : AppColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.border),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildAssuranceCol(Icons.local_shipping_outlined, 'Free Pickup', '& Doorstep Drop'),
                          Container(width: 1, height: 30, color: AppColors.border),
                          _buildAssuranceCol(Icons.verified_outlined, '100% Genuine', 'OEM / OES Spares'),
                          Container(width: 1, height: 30, color: AppColors.border),
                          _buildAssuranceCol(Icons.health_and_safety_outlined, 'Warranty', 'Backed Service'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 22),

                    // Related Packages Section (if available)
                    if (relatedPkgs.isNotEmpty) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Available Service Packages',
                            style: AppTypography.titleSmall.copyWith(fontWeight: FontWeight.w700),
                          ),
                          Text(
                            'Compare Packages',
                            style: AppTypography.labelSmall.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      ...relatedPkgs.map((pkg) => _buildPackageCard(pkg)),
                      const SizedBox(height: 22),
                    ],

                    // Section 1: What's Included (Checklist)
                    Text(
                      'What\'s Included',
                      style: AppTypography.titleSmall.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkSurface : AppColors.surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.border),
                      ),
                      child: Column(
                        children: service.allIncludedItems.map((item) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(
                                  Icons.check_circle_rounded,
                                  color: AppColors.success,
                                  size: 18,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    item,
                                    style: AppTypography.bodySmall.copyWith(
                                      color: AppColors.textPrimary,
                                      fontWeight: FontWeight.w600,
                                      height: 1.35,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Section 2: What's Not Included (Exclusions)
                    Text(
                      'What\'s Not Included',
                      style: AppTypography.titleSmall.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceVariant.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        children: service.allExcludedItems.map((item) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(
                                  Icons.cancel_rounded,
                                  color: AppColors.textMuted,
                                  size: 18,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    item,
                                    style: AppTypography.bodySmall.copyWith(
                                      color: AppColors.textSecondary,
                                      height: 1.35,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Section 3: Benefits
                    Text(
                      'Service Benefits',
                      style: AppTypography.titleSmall.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 10),
                    ...service.allBenefits.map((benefit) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.darkSurface : AppColors.surface,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.border),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(alpha: 0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.star_rounded,
                                  size: 16,
                                  color: AppColors.primary,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  benefit,
                                  style: AppTypography.bodySmall.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                    const SizedBox(height: 20),

                    // Section 4: Service Process
                    Text(
                      'How It Works',
                      style: AppTypography.titleSmall.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkSurface : AppColors.surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.border),
                      ),
                      child: Column(
                        children: List.generate(service.allProcessSteps.length, (idx) {
                          final step = service.allProcessSteps[idx];
                          final isLast = idx == service.allProcessSteps.length - 1;
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Column(
                                children: [
                                  CircleAvatar(
                                    radius: 12,
                                    backgroundColor: AppColors.primary,
                                    child: Text(
                                      '${idx + 1}',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w800,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                  if (!isLast)
                                    Container(
                                      width: 2,
                                      height: 24,
                                      color: AppColors.border,
                                    ),
                                ],
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.only(top: 2, bottom: 12),
                                  child: Text(
                                    step,
                                    style: AppTypography.bodySmall.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          );
                        }),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Section 5: FAQs
                    Text(
                      'Frequently Asked Questions',
                      style: AppTypography.titleSmall.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 10),
                    ...service.allFaqs.map((faq) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Container(
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.darkSurface : AppColors.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.border),
                          ),
                          child: Theme(
                            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                            child: ExpansionTile(
                              tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 0),
                              title: Text(
                                faq['q'] ?? '',
                                style: AppTypography.bodySmall.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              children: [
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
                                  child: Text(
                                    faq['a'] ?? '',
                                    style: AppTypography.bodySmall.copyWith(
                                      color: AppColors.textSecondary,
                                      height: 1.4,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                    const SizedBox(height: 20),
                  ],
                ),
              ),

              // Bottom Sticky Action Bar
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkElevatedSurface : AppColors.surface,
                  border: isDark ? const Border(top: BorderSide(color: AppColors.darkBorder)) : null,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.06),
                      blurRadius: 10,
                      offset: const Offset(0, -3),
                    ),
                  ],
                ),
                child: SafeArea(
                  top: false,
                  child: Row(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Estimated Price',
                            style: AppTypography.bodySmall,
                          ),
                          Row(
                            children: [
                              Text(
                                '${AppConstants.currencySymbol}${service.price.toInt()}',
                                style: AppTypography.priceLarge.copyWith(
                                  fontSize: 22,
                                  color: AppColors.primary,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '${AppConstants.currencySymbol}${service.originalPrice.toInt()}',
                                style: AppTypography.priceStrike,
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(width: 18),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                            widget.onBookNow();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            'Book Now',
                            style: AppTypography.labelLarge.copyWith(
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPackageCard(ServicePackage pkg) {
    final isExpanded = _expandedPackageId == pkg.id;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: pkg.isRecommended
              ? AppColors.primary
              : (isDark ? AppColors.darkBorder : AppColors.border),
          width: pkg.isRecommended ? 1.5 : 1,
        ),
      ),
      child: Column(
        children: [
          if (pkg.isRecommended)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
              decoration: const BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
              ),
              child: const Text(
                'RECOMMENDED PACKAGE',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(12),
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
                          Text(
                            pkg.title,
                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                          ),
                          Text(
                            pkg.tag,
                            style: AppTypography.labelSmall.copyWith(color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${AppConstants.currencySymbol}${pkg.price.toInt()}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primary,
                          ),
                        ),
                        Text(
                          '${AppConstants.currencySymbol}${pkg.originalPrice.toInt()}',
                          style: AppTypography.priceStrike,
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Checklist teaser or full
                Column(
                  children: (isExpanded ? pkg.checklist : pkg.checklist.take(2)).map((c) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(
                        children: [
                          const Icon(Icons.check, size: 14, color: AppColors.success),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              c,
                              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 8),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    InkWell(
                      onTap: () {
                        setState(() {
                          _expandedPackageId = isExpanded ? null : pkg.id;
                        });
                      },
                      child: Text(
                        isExpanded ? 'Show Less' : '+ ${pkg.checklist.length - 2} More Services',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        if (widget.onBookPackage != null) {
                          widget.onBookPackage!(pkg);
                        } else {
                          widget.onBookNow();
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: pkg.isRecommended ? AppColors.primary : AppColors.secondary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        minimumSize: const Size(0, 32),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text('Book Package', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpecChip(IconData icon, String text, {Color? color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color ?? AppColors.textSecondary),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color ?? AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAssuranceCol(IconData icon, String line1, String line2) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: AppColors.primary),
        const SizedBox(height: 4),
        Text(line1, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700)),
        Text(line2, style: const TextStyle(fontSize: 9, color: AppColors.textSecondary)),
      ],
    );
  }
}
