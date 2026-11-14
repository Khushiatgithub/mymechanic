enum NotificationCategory {
  booking,
  service,
  offers,
}

class NotificationItem {
  final String id;
  final String title;
  final String message;
  final DateTime dateTime;
  final NotificationCategory category;
  final bool isRead;
  final String? actionRoute;
  final String? relatedId;

  const NotificationItem({
    required this.id,
    required this.title,
    required this.message,
    required this.dateTime,
    required this.category,
    this.isRead = false,
    this.actionRoute,
    this.relatedId,
  });

  NotificationItem copyWith({
    String? id,
    String? title,
    String? message,
    DateTime? dateTime,
    NotificationCategory? category,
    bool? isRead,
    String? actionRoute,
    String? relatedId,
  }) {
    return NotificationItem(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      dateTime: dateTime ?? this.dateTime,
      category: category ?? this.category,
      isRead: isRead ?? this.isRead,
      actionRoute: actionRoute ?? this.actionRoute,
      relatedId: relatedId ?? this.relatedId,
    );
  }

  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    NotificationCategory cat;
    final catStr = json['category']?.toString().toLowerCase();
    switch (catStr) {
      case 'service':
        cat = NotificationCategory.service;
        break;
      case 'offers':
        cat = NotificationCategory.offers;
        break;
      case 'booking':
      default:
        cat = NotificationCategory.booking;
        break;
    }

    final createdAtStr = json['createdAt']?.toString() ?? json['dateTime']?.toString();
    final dt = createdAtStr != null ? (DateTime.tryParse(createdAtStr) ?? DateTime.now()) : DateTime.now();

    return NotificationItem(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? 'Notification',
      message: json['message']?.toString() ?? '',
      dateTime: dt,
      category: cat,
      isRead: json['isRead'] == true,
      actionRoute: json['actionRoute']?.toString(),
      relatedId: json['relatedId']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'message': message,
      'dateTime': dateTime.toIso8601String(),
      'category': category.name,
      'isRead': isRead,
      if (actionRoute != null) 'actionRoute': actionRoute,
      if (relatedId != null) 'relatedId': relatedId,
    };
  }
}
