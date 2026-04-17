/// A single notification in the user's inbox.
class NotificationItem {
  final int id;
  final String notificationType;
  final String title;
  final String message;
  final String emoji;
  final bool isRead;
  final DateTime? createdAt;

  NotificationItem({
    required this.id,
    required this.notificationType,
    required this.title,
    required this.message,
    required this.emoji,
    required this.isRead,
    this.createdAt,
  });

  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    return NotificationItem(
      id: json['id'],
      notificationType: json['notification_type'] ?? 'reminder',
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      emoji: json['emoji'] ?? '🔔',
      isRead: json['is_read'] ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'])
          : null,
    );
  }
}

/// Response from GET /api/users/{uid}/notifications
class NotificationListResponse {
  final List<NotificationItem> notifications;
  final int total;
  final int unreadCount;

  NotificationListResponse({
    required this.notifications,
    required this.total,
    required this.unreadCount,
  });

  factory NotificationListResponse.fromJson(Map<String, dynamic> json) {
    return NotificationListResponse(
      total: json['total'] ?? 0,
      unreadCount: json['unread_count'] ?? 0,
      notifications: (json['notifications'] as List<dynamic>?)
              ?.map((n) =>
                  NotificationItem.fromJson(n as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}
