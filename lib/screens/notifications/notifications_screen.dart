import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../data/mock_data.dart';
import '../../models/notification_item.dart';
import '../../services/notification_service.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  String _selectedCategory = 'All';

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    await NotificationService.instance.getNotifications(category: _selectedCategory);
  }

  final List<String> _categories = [
    'All',
    'Booking',
    'Service',
    'Offers',
  ];

  IconData _getCategoryIcon(NotificationCategory cat) {
    switch (cat) {
      case NotificationCategory.booking:
        return Icons.calendar_today_rounded;
      case NotificationCategory.service:
        return Icons.build_circle_rounded;
      case NotificationCategory.offers:
        return Icons.local_offer_rounded;
    }
  }

  Color _getCategoryColor(NotificationCategory cat) {
    switch (cat) {
      case NotificationCategory.booking:
        return AppColors.categoryBlue;
      case NotificationCategory.service:
        return AppColors.categoryAmber;
      case NotificationCategory.offers:
        return AppColors.categoryRed;
    }
  }

  String _formatTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h ago';
    } else {
      return '${diff.inDays}d ago';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Notifications Center'),
        elevation: 0,
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        actions: [
          ValueListenableBuilder<List<NotificationItem>>(
            valueListenable: MockData.notificationsNotifier,
            builder: (context, notifications, _) {
              final unread = notifications.where((n) => !n.isRead).length;
              if (unread == 0) return const SizedBox.shrink();

              return TextButton(
                onPressed: () {
                  NotificationService.instance.markAllAsRead();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('All notifications marked as read'),
                      duration: Duration(seconds: 1),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                child: const Text('Mark all as read', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Chips
          Container(
            color: AppColors.surface,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: SizedBox(
              height: 34,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _categories.length,
                itemBuilder: (context, index) {
                  final cat = _categories[index];
                  final isSelected = _selectedCategory == cat;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(cat),
                      selected: isSelected,
                      onSelected: (selected) {
                        if (selected) setState(() => _selectedCategory = cat);
                      },
                      selectedColor: AppColors.primary,
                      backgroundColor: AppColors.surfaceVariant,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : AppColors.textPrimary,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        fontSize: 12,
                      ),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      side: BorderSide.none,
                    ),
                  );
                },
              ),
            ),
          ),

          // Notifications List
          Expanded(
            child: ValueListenableBuilder<List<NotificationItem>>(
              valueListenable: MockData.notificationsNotifier,
              builder: (context, notifications, _) {
                final filtered = notifications.where((n) {
                  if (_selectedCategory == 'All') return true;
                  if (_selectedCategory == 'Booking') return n.category == NotificationCategory.booking;
                  if (_selectedCategory == 'Service') return n.category == NotificationCategory.service;
                  if (_selectedCategory == 'Offers') return n.category == NotificationCategory.offers;
                  return true;
                }).toList();

                if (filtered.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.notifications_off_outlined, size: 56, color: Colors.grey.shade400),
                          const SizedBox(height: 12),
                          Text(
                            'No notifications yet',
                            style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Updates on bookings, service reminders and exclusive deals will appear here.',
                            style: AppTypography.bodySmall,
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: _loadNotifications,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final item = filtered[index];
                      return _buildNotificationCard(item);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationCard(NotificationItem item) {
    final color = _getCategoryColor(item.category);

    return Dismissible(
      key: Key(item.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) {
        NotificationService.instance.deleteNotification(item.id);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Notification deleted'),
            duration: Duration(seconds: 1),
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
      background: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppColors.error,
          borderRadius: BorderRadius.circular(14),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete_outline_rounded, color: Colors.white),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: item.isRead ? AppColors.surface : AppColors.primary.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: item.isRead ? AppColors.border : AppColors.primary.withValues(alpha: 0.25),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: InkWell(
          onTap: () {
            NotificationService.instance.markAsRead(item.id);
          },
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Category Icon
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Icon(_getCategoryIcon(item.category), color: color, size: 20),
                  ),
                ),
                const SizedBox(width: 12),

                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              item.title,
                              style: TextStyle(
                                fontWeight: item.isRead ? FontWeight.w600 : FontWeight.w800,
                                fontSize: 13,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _formatTime(item.dateTime),
                            style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.message,
                        style: AppTypography.bodySmall.copyWith(
                          color: item.isRead ? AppColors.textSecondary : AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),

                // Unread dot
                if (!item.isRead)
                  Container(
                    margin: const EdgeInsets.only(left: 8, top: 4),
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
