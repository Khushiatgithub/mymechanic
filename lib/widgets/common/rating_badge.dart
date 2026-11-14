import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';

class RatingBadge extends StatelessWidget {
  final double rating;
  final int? reviewsCount;

  const RatingBadge({
    super.key,
    required this.rating,
    this.reviewsCount,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: AppColors.success,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                rating.toStringAsFixed(1),
                style: AppTypography.labelSmall.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 3),
              const Icon(
                Icons.star_rounded,
                color: Colors.white,
                size: 11,
              ),
            ],
          ),
        ),
        if (reviewsCount != null) ...[
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              '($reviewsCount)',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
