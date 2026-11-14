import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/mock_data.dart';

class LocationSelectorSheet extends StatelessWidget {
  final String currentLocation;
  final ValueChanged<String> onLocationSelected;

  const LocationSelectorSheet({
    super.key,
    required this.currentLocation,
    required this.onLocationSelected,
  });

  static Future<void> show({
    required BuildContext context,
    required String currentLocation,
    required ValueChanged<String> onLocationSelected,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => LocationSelectorSheet(
        currentLocation: currentLocation,
        onLocationSelected: onLocationSelected,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Select Your Location',
                style: AppTypography.titleLarge,
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          Text(
            'We provide free doorstep pickup & drop in these service areas',
            style: AppTypography.bodySmall,
          ),
          const SizedBox(height: 16),

          // Use Current Location Button
          InkWell(
            onTap: () {
              onLocationSelected('Current Location (GPS)');
              Navigator.pop(context);
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.my_location_rounded, color: AppColors.primary, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Detect Current Location',
                          style: AppTypography.titleSmall.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          'Using device GPS',
                          style: AppTypography.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded, color: AppColors.primary),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          Text(
            'Popular Service Hubs:',
            style: AppTypography.labelMedium,
          ),
          const SizedBox(height: 10),

          // Available Cities / Localities
          ...MockData.availableLocations.map((loc) {
            final isSelected = loc == currentLocation;
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.surfaceVariant : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
              ),
              child: ListTile(
                dense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                leading: Icon(
                  Icons.location_on_outlined,
                  color: isSelected ? AppColors.primary : AppColors.textSecondary,
                  size: 20,
                ),
                title: Text(
                  loc,
                  style: AppTypography.bodyLarge.copyWith(
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                    color: isSelected ? AppColors.primary : AppColors.textPrimary,
                  ),
                ),
                trailing: isSelected
                    ? const Icon(Icons.check_rounded, color: AppColors.primary, size: 20)
                    : null,
                onTap: () {
                  onLocationSelected(loc);
                  Navigator.pop(context);
                },
              ),
            );
          }),
        ],
      ),
    );
  }
}
