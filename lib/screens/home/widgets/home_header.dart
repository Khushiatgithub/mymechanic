import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/mock_data.dart';
import '../../../models/notification_item.dart';
import 'location_selector_sheet.dart';

class HomeHeader extends StatelessWidget {
  final String currentLocation;
  final ValueChanged<String> onLocationChanged;
  final VoidCallback onSosTap;
  final VoidCallback onNotificationsTap;

  const HomeHeader({
    super.key,
    required this.currentLocation,
    required this.onLocationChanged,
    required this.onSosTap,
    required this.onNotificationsTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
      child: Column(
        children: [
          // Row 1: Brand & Top Actions
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Brand Logo & Name
              Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.car_repair_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: 'My',
                          style: AppTypography.titleLarge.copyWith(
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        TextSpan(
                          text: 'Mechanic',
                          style: AppTypography.titleLarge.copyWith(
                            fontWeight: FontWeight.w900,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              // Action buttons: SOS + Notifications
              Row(
                children: [
                  // Roadside SOS Button
                  InkWell(
                    onTap: onSosTap,
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        gradient: AppColors.sosGradient,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.error.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.emergency_rounded, size: 14, color: Colors.white),
                          SizedBox(width: 4),
                          Text(
                            'SOS 24x7',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Notification Bell with reactive unread badge
                  Stack(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.notifications_none_rounded),
                        color: AppColors.textPrimary,
                        onPressed: onNotificationsTap,
                        splashRadius: 20,
                      ),
                      ValueListenableBuilder<List<NotificationItem>>(
                        valueListenable: MockData.notificationsNotifier,
                        builder: (context, notifications, _) {
                          final unread = MockData.unreadNotificationsCount;
                          if (unread == 0) return const SizedBox.shrink();
                          return Positioned(
                            top: 8,
                            right: 8,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: AppColors.error,
                                shape: BoxShape.circle,
                              ),
                              constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                              child: Text(
                                unread > 9 ? '9+' : '$unread',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Row 2: Location selector
          InkWell(
            onTap: () {
              LocationSelectorSheet.show(
                context: context,
                currentLocation: currentLocation,
                onLocationSelected: onLocationChanged,
              );
            },
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  const Icon(
                    Icons.location_on_rounded,
                    color: AppColors.primary,
                    size: 18,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Service Location',
                              style: AppTypography.bodySmall.copyWith(
                                color: AppColors.textSecondary,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                currentLocation,
                                style: AppTypography.labelMedium.copyWith(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.w700,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(
                              Icons.keyboard_arrow_down_rounded,
                              size: 16,
                              color: AppColors.textSecondary,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
