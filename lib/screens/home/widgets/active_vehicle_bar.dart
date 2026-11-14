import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/vehicle.dart';

/// Compact bar displaying the currently active vehicle details on the Home screen.
///
/// Features:
/// - "My Vehicle" section title with "Manage Garage" action link.
/// - Displays vehicle Brand, Model, Variant, and Registration Number.
/// - Shows service due reminder status chip.
/// - Tapping card opens vehicle switch sheet; tapping "Manage Garage" opens garage.
class ActiveVehicleBar extends StatelessWidget {
  final Vehicle activeVehicle;
  final VoidCallback onChangeVehicle;
  final VoidCallback onManageGarage;

  const ActiveVehicleBar({
    super.key,
    required this.activeVehicle,
    required this.onChangeVehicle,
    required this.onManageGarage,
  });

  @override
  Widget build(BuildContext context) {
    final title = '${activeVehicle.brand} ${activeVehicle.model}';
    final regNo = activeVehicle.registrationNumber;
    final due = activeVehicle.serviceDueStatus;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header Row: "My Vehicle" + "Manage Garage"
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Text(
                    'My Vehicle',
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'ACTIVE',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                ],
              ),
              InkWell(
                onTap: onManageGarage,
                borderRadius: BorderRadius.circular(4),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  child: Text(
                    'Manage Garage',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),

        // Active Vehicle Card
        Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border.withValues(alpha: 0.8)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: InkWell(
            onTap: onChangeVehicle,
            borderRadius: BorderRadius.circular(10),
            child: Row(
              children: [
                // Vehicle Avatar Icon
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.directions_car_filled_rounded,
                    color: AppColors.primary,
                    size: 19,
                  ),
                ),
                const SizedBox(width: 10),

                // Vehicle Name & Registration Number
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              title,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceVariant,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Text(
                              regNo,
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textSecondary,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        due.isNotEmpty ? due : 'Active vehicle for bookings',
                        style: TextStyle(
                          fontSize: 11,
                          color: due.contains('Due') ? AppColors.warning : AppColors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),

                // Change link
                TextButton(
                  onPressed: onChangeVehicle,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text(
                    'Change',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
