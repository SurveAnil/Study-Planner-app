import 'package:flutter/material.dart';
import '../models/notification_model.dart';
import '../models/user.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

class NotificationsScreen extends StatefulWidget {
  final User user;
  const NotificationsScreen({super.key, required this.user});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final ApiService _api = ApiService();
  List<NotificationItem> _notifications = [];
  bool _isLoading = true;
  int _unreadCount = 0;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() => _isLoading = true);
    try {
      final result = await _api.getNotifications(widget.user.firebaseUid);
      if (mounted) {
        setState(() {
          _notifications = result.notifications;
          _unreadCount = result.unreadCount;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _markAllRead() async {
    try {
      await _api.markAllNotificationsRead(widget.user.firebaseUid);
      if (mounted) {
        setState(() {
          _notifications = _notifications
              .map((n) => NotificationItem(
                    id: n.id,
                    notificationType: n.notificationType,
                    title: n.title,
                    message: n.message,
                    emoji: n.emoji,
                    isRead: true,
                    createdAt: n.createdAt,
                  ))
              .toList();
          _unreadCount = 0;
        });
      }
    } catch (_) {}
  }

  Future<void> _markRead(NotificationItem notif) async {
    if (notif.isRead) return;
    try {
      await _api.markNotificationRead(widget.user.firebaseUid, notif.id);
      if (mounted) {
        setState(() {
          final idx = _notifications.indexWhere((n) => n.id == notif.id);
          if (idx >= 0) {
            _notifications[idx] = NotificationItem(
              id: notif.id,
              notificationType: notif.notificationType,
              title: notif.title,
              message: notif.message,
              emoji: notif.emoji,
              isRead: true,
              createdAt: notif.createdAt,
            );
          }
          _unreadCount = (_unreadCount - 1).clamp(0, 9999);
        });
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppTheme.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            const Text(
              'Notifications',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary),
            ),
            if (_unreadCount > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.primary,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$_unreadCount',
                  style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Colors.white),
                ),
              ),
            ],
          ],
        ),
        actions: [
          if (_unreadCount > 0)
            TextButton(
              onPressed: _markAllRead,
              child: const Text('Mark all read',
                  style: TextStyle(
                      color: AppTheme.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600)),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primary))
          : _notifications.isEmpty
              ? _buildEmpty()
              : RefreshIndicator(
                  onRefresh: _loadNotifications,
                  color: AppTheme.primary,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _notifications.length,
                    itemBuilder: (context, index) =>
                        _buildNotifCard(_notifications[index]),
                  ),
                ),
    );
  }

  Widget _buildNotifCard(NotificationItem notif) {
    final isRisk = notif.notificationType == 'streak_risk';
    final isBadge = notif.notificationType == 'badge_earned';

    Color accentColor;
    if (isBadge) {
      accentColor = AppTheme.primary;
    } else if (isRisk) {
      accentColor = AppTheme.danger;
    } else {
      accentColor = AppTheme.warning;
    }

    return GestureDetector(
      onTap: () => _markRead(notif),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: notif.isRead
              ? AppTheme.surface
              : accentColor.withOpacity(0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: notif.isRead
                ? AppTheme.border.withOpacity(0.3)
                : accentColor.withOpacity(0.25),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: accentColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(notif.emoji,
                    style: const TextStyle(fontSize: 20)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          notif.title,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: notif.isRead
                                ? FontWeight.w500
                                : FontWeight.w700,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ),
                      if (!notif.isRead)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: accentColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    notif.message,
                    style: TextStyle(
                        fontSize: 12, color: AppTheme.textSecondary),
                  ),
                  if (notif.createdAt != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      _formatTime(notif.createdAt!),
                      style: TextStyle(
                          fontSize: 10, color: AppTheme.textMuted),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppTheme.surfaceLight,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(Icons.notifications_none_rounded,
                size: 36, color: AppTheme.textMuted),
          ),
          const SizedBox(height: 16),
          const Text('No notifications yet',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary)),
          const SizedBox(height: 6),
          const Text('Badge unlocks and streak alerts will appear here.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
        ],
      ),
    );
  }
}
