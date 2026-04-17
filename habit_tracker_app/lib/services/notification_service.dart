// ignore: avoid_web_libraries_in_flutter
import 'dart:js' as js;
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../models/badge_model.dart';
import '../models/user_progress.dart';

/// Manages in-app notification overlays AND real browser push notifications.
///
/// Push notifications use the Web Notifications API via the JS bridge
/// defined in web/index.html. No FCM or external package needed.
class NotificationService {
  NotificationService._();

  // ── Browser Push Notifications (Real OS-level) ────────────────

  /// Request permission for browser push notifications.
  /// Should be called once after user logs in.
  static Future<bool> requestPushPermission() async {
    if (!kIsWeb) return false;
    try {
      final result = await js.context
          .callMethod('requestNotificationPermission', []);
      final permission = result?.toString() ?? 'denied';
      debugPrint('🔔 Notification permission: $permission');
      return permission == 'granted';
    } catch (e) {
      debugPrint('⚠️ Could not request notification permission: $e');
      return false;
    }
  }

  /// Get current browser notification permission status.
  static String getPushPermission() {
    if (!kIsWeb) return 'not_supported';
    try {
      return js.context.callMethod('getNotificationPermission', [])?.toString()
          ?? 'unknown';
    } catch (_) {
      return 'unknown';
    }
  }

  /// Show a real OS-level browser push notification.
  /// This appears even when the user is in another tab.
  static void sendPushNotification(String title, String body) {
    if (!kIsWeb) return;
    try {
      js.context.callMethod('showBrowserNotification', [
        title,
        body,
        '/icons/Icon-192.png',
      ]);
      debugPrint('📤 Sent push notification: $title');
    } catch (e) {
      debugPrint('⚠️ Push notification failed: $e');
    }
  }

  /// Send a badge-unlock push notification.
  static void sendBadgePush(String badgeName, String badgeEmoji) {
    sendPushNotification(
      '$badgeEmoji Badge Unlocked!',
      'You earned the "$badgeName" achievement. Keep it up!',
    );
  }

  /// Send a streak-risk push notification.
  static void sendStreakRiskPush(String habitTitle, int daysMissed) {
    sendPushNotification(
      '⚠️ Streak at Risk!',
      '"$habitTitle" missed for $daysMissed days. Log it now to save your streak!',
    );
  }

  // ── In-App Badge Unlock Toast (Overlay) ──────────────────────

  static void showBadgeUnlock(BuildContext context, Badge badge) {
    final overlay = Overlay.of(context);
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => _BadgeUnlockToast(
        badge: badge,
        onDismiss: () => entry.remove(),
      ),
    );
    overlay.insert(entry);
    Timer(const Duration(seconds: 4), () {
      if (entry.mounted) entry.remove();
    });

    // Also send real push notification
    sendBadgePush(badge.badgeName, badge.badgeEmoji);
  }

  // ── Streak Risk Banner ────────────────────────────────────────

  static void showStreakRiskBanner(
    BuildContext context,
    List<StreakRisk> risks,
  ) {
    if (risks.isEmpty) return;
    final most = risks.first;

    // Send real push notification
    sendStreakRiskPush(most.title, most.daysMissed);

    ScaffoldMessenger.of(context).showMaterialBanner(
      MaterialBanner(
        backgroundColor: const Color(0xFF1C1010),
        leading: const Text('🔥', style: TextStyle(fontSize: 22)),
        content: Text(
          '⚠️ "${most.title}" streak at risk! ${most.daysMissed} days missed.',
          style: const TextStyle(
            color: Color(0xFFFF5252),
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
        actions: [
          TextButton(
            child: const Text('DISMISS',
                style: TextStyle(color: Color(0xFF8B949E))),
            onPressed: () =>
                ScaffoldMessenger.of(context).hideCurrentMaterialBanner(),
          ),
          TextButton(
            child: const Text('LOG NOW',
                style: TextStyle(
                    color: Color(0xFF6C63FF), fontWeight: FontWeight.w700)),
            onPressed: () =>
                ScaffoldMessenger.of(context).hideCurrentMaterialBanner(),
          ),
        ],
      ),
    );
  }

  /// Simple snackbar for newly earned badges.
  static void showBadgeSnackbar(BuildContext context, List<Badge> badges) {
    if (badges.isEmpty) return;
    final badge = badges.first;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 4),
        backgroundColor: const Color(0xFF21262D),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        behavior: SnackBarBehavior.floating,
        content: Row(
          children: [
            Text(badge.badgeEmoji, style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('🏆 Badge Unlocked!',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF9D97FF))),
                  Text(badge.badgeName,
                      style: const TextStyle(
                          fontSize: 12, color: Color(0xFFF0F6FC))),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Badge Unlock Overlay Widget ────────────────────────────────

class _BadgeUnlockToast extends StatefulWidget {
  final Badge badge;
  final VoidCallback onDismiss;
  const _BadgeUnlockToast({required this.badge, required this.onDismiss});

  @override
  State<_BadgeUnlockToast> createState() => _BadgeUnlockToastState();
}

class _BadgeUnlockToastState extends State<_BadgeUnlockToast>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fade;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(begin: const Offset(0, -1), end: Offset.zero)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack));
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 16,
      left: 20,
      right: 20,
      child: SlideTransition(
        position: _slide,
        child: FadeTransition(
          opacity: _fade,
          child: Material(
            color: Colors.transparent,
            child: GestureDetector(
              onTap: widget.onDismiss,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF21262D),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                      color: const Color(0xFF6C63FF).withOpacity(0.4)),
                  boxShadow: [
                    BoxShadow(
                        color: const Color(0xFF6C63FF).withOpacity(0.2),
                        blurRadius: 20,
                        offset: const Offset(0, 8))
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF6C63FF), Color(0xFF896BFF)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Center(
                          child: Text(widget.badge.badgeEmoji,
                              style: const TextStyle(fontSize: 26))),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('🏆 Badge Unlocked!',
                              style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF9D97FF),
                                  letterSpacing: 0.5)),
                          const SizedBox(height: 3),
                          Text(widget.badge.badgeName,
                              style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFFF0F6FC))),
                          const SizedBox(height: 2),
                          Text(widget.badge.description,
                              style: const TextStyle(
                                  fontSize: 11, color: Color(0xFF8B949E)),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis),
                        ],
                      ),
                    ),
                    const Icon(Icons.close_rounded,
                        color: Color(0xFF484F58), size: 18),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
