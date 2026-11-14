import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/vehicle.dart';

/// Search and Vehicle Selection row for MyMechanic Home Screen.
///
/// Features:
/// - Left: Large rounded search TextField with search icon and placeholder `Search "Periodic Services"`.
/// - Right: Rounded outlined button `Select Vehicle` with vehicle icon and dropdown arrow.
/// - Connects directly to existing service search and vehicle switch sheet functionality.
class SearchVehicleRow extends StatelessWidget {
  final VoidCallback onSearchTap;
  final ValueChanged<String>? onSearchSubmitted;
  final VoidCallback onSelectVehicleTap;
  final Vehicle? activeVehicle;

  const SearchVehicleRow({
    super.key,
    required this.onSearchTap,
    this.onSearchSubmitted,
    required this.onSelectVehicleTap,
    this.activeVehicle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      color: theme.colorScheme.surface,
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
      child: Row(
        children: [
          // Left: Large Rounded Search Field with real TextField
          Expanded(
            child: SizedBox(
              height: 46,
              child: TextField(
                readOnly: true,
                onTap: onSearchTap,
                style: TextStyle(
                  color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
                decoration: InputDecoration(
                  hintText: 'Search "Periodic Services"',
                  hintStyle: TextStyle(
                    color: isDark
                        ? AppColors.darkSearchPlaceholder
                        : AppColors.textSecondary.withValues(alpha: 0.85),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                    size: 20,
                  ),
                  filled: true,
                  fillColor: isDark ? AppColors.darkInputSurface : AppColors.surfaceVariant,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide(
                      color: isDark ? AppColors.darkBorder : AppColors.border.withValues(alpha: 0.8),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide(
                      color: isDark ? AppColors.darkBorder : AppColors.border.withValues(alpha: 0.8),
                    ),
                  ),
                  focusedBorder: const OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(24)),
                    borderSide: BorderSide(color: AppColors.primary, width: 1.2),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),

          // Right: Rounded Outlined "Select Vehicle" Button
          OutlinedButton(
            onPressed: onSelectVehicleTap,
            style: OutlinedButton.styleFrom(
              foregroundColor: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
              backgroundColor: isDark ? AppColors.darkInputSurface : AppColors.surface,
              side: BorderSide(
                color: isDark ? AppColors.darkBorder : AppColors.border,
                width: 1.2,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              minimumSize: const Size(0, 46),
              elevation: 0,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.directions_car_rounded,
                  size: 16,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 6),
                Text(
                  'Select Vehicle',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 16,
                  color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
