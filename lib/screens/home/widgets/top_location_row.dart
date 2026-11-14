import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/mock_data.dart';
import '../../../models/notification_item.dart';
import '../../../services/theme_service.dart';
import 'location_selector_sheet.dart';

/// Top Location Row for MyMechanic Home Screen.
///
/// Features:
/// - Location pin icon on the left (MyMechanic primary red).
/// - Dynamic location display with truncation.
/// - Dropdown arrow indicating that location can be changed.
/// - Quick Dark / Light mode toggle button.
/// - Right-aligned notification bell with reactive unread counter.
/// - Tapping location opens [LocationSelectorSheet].
class TopLocationRow extends StatelessWidget {
  final String currentLocation;
  final ValueChanged<String> onLocationChanged;
  final VoidCallback onNotificationsTap;

  const TopLocationRow({
    super.key,
    required this.currentLocation,
    required this.onLocationChanged,
    required this.onNotificationsTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      color: theme.colorScheme.surface,
      padding: const EdgeInsets.fromLTRB(16, 8, 12, 6),
      child: Row(
        children: [
          // Location Pin Icon
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.location_on_rounded,
              color: AppColors.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 8),

          // Location Text & Dropdown
          Expanded(
            child: InkWell(
              onTap: () {
                LocationSelectorSheet.show(
                  context: context,
                  currentLocation: currentLocation,
                  onLocationSelected: onLocationChanged,
                );
              },
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        currentLocation,
                        style: AppTypography.titleSmall.copyWith(
                          fontWeight: FontWeight.w700,
                          color: theme.colorScheme.onSurface,
                          fontSize: 13.5,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Dark / Light Mode Quick Toggle Button
          ValueListenableBuilder<ThemeMode>(
            valueListenable: ThemeService.instance.themeModeNotifier,
            builder: (context, mode, _) {
              final activeDark = mode == ThemeMode.dark;
              return IconButton(
                icon: Icon(
                  activeDark ? Icons.light_mode_rounded : Icons.dark_mode_outlined,
                  color: activeDark ? const Color(0xFFFACC15) : theme.colorScheme.onSurface,
                ),
                iconSize: 22,
                padding: const EdgeInsets.all(6),
                constraints: const BoxConstraints(),
                splashRadius: 22,
                onPressed: () {
                  ThemeService.instance.toggleDarkMode();
                },
                tooltip: activeDark ? 'Switch to Light Mode' : 'Switch to Dark Mode',
              );
            },
          ),
          const SizedBox(width: 4),

          // Notifications Bell with Unread Badge
          ValueListenableBuilder<List<NotificationItem>>(
            valueListenable: MockData.notificationsNotifier,
            builder: (context, notifications, _) {
              final unreadCount = notifications.where((n) => !n.isRead).length;

              return Stack(
                clipBehavior: Clip.none,
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications_none_rounded),
                    color: theme.colorScheme.onSurface,
                    iconSize: 24,
                    padding: const EdgeInsets.all(8),
                    constraints: const BoxConstraints(),
                    splashRadius: 22,
                    onPressed: onNotificationsTap,
                    tooltip: 'Notifications',
                  ),
                  if (unreadCount > 0)
                    Positioned(
                      right: 4,
                      top: 4,
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          unreadCount > 9 ? '9+' : '$unreadCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
