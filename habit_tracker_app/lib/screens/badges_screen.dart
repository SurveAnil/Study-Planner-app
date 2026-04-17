import 'package:flutter/material.dart';
import '../models/badge_model.dart';
import '../models/user.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

class BadgesScreen extends StatefulWidget {
  final User user;
  const BadgesScreen({super.key, required this.user});

  @override
  State<BadgesScreen> createState() => _BadgesScreenState();
}

class _BadgesScreenState extends State<BadgesScreen>
    with AutomaticKeepAliveClientMixin {
  final ApiService _api = ApiService();
  List<Badge> _badges = [];
  bool _isLoading = true;
  String? _error;

  // All possible badges to display (earned or locked)
  static const List<Map<String, String>> _allBadges = [
    {
      'type': 'first_habit',
      'emoji': '⚡',
      'name': 'First Step',
      'description': 'Complete your first habit',
    },
    {
      'type': 'streak_7',
      'emoji': '🔥',
      'name': '7-Day Streak',
      'description': 'Maintain a 7-day streak on any habit',
    },
    {
      'type': 'streak_30',
      'emoji': '💎',
      'name': '30-Day Streak',
      'description': 'Maintain a 30-day streak on any habit',
    },
    {
      'type': 'perfect_week',
      'emoji': '🎯',
      'name': 'Perfect Week',
      'description': '100% completion for 7 consecutive days',
    },
  ];

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadBadges();
  }

  Future<void> _loadBadges() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final result = await _api.getBadges(widget.user.firebaseUid);
      if (mounted) {
        setState(() {
          _badges = result.badges;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = 'Failed to load badges.';
        });
      }
    }
  }

  bool _isEarned(String badgeType) =>
      _badges.any((b) => b.badgeType == badgeType);

  Badge? _getEarned(String badgeType) {
    try {
      return _badges.firstWhere((b) => b.badgeType == badgeType);
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return SafeArea(
      child: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primary))
          : _error != null
              ? _buildError()
              : _buildContent(),
    );
  }

  Widget _buildContent() {
    final earned = _badges.length;
    final total = _allBadges.length;

    return RefreshIndicator(
      onRefresh: _loadBadges,
      color: AppTheme.primary,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Header
          const Text(
            'Achievements',
            style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: AppTheme.textPrimary),
          ),
          const SizedBox(height: 4),
          Text(
            'Unlock badges by building consistent habits',
            style: TextStyle(fontSize: 14, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 20),

          // Progress bar
          _buildProgressBar(earned, total),
          const SizedBox(height: 28),

          // Badge grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 14,
              mainAxisSpacing: 14,
              childAspectRatio: 0.85,
            ),
            itemCount: _allBadges.length,
            itemBuilder: (context, index) {
              final def = _allBadges[index];
              final earned = _isEarned(def['type']!);
              final badge = _getEarned(def['type']!);
              return _buildBadgeCard(def, earned, badge);
            },
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildProgressBar(int earned, int total) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$earned / $total badges earned',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
              Text(
                '${((earned / total) * 100).round()}%',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: total > 0 ? earned / total : 0,
              backgroundColor: AppTheme.surfaceLight,
              valueColor:
                  const AlwaysStoppedAnimation<Color>(AppTheme.primary),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadgeCard(
      Map<String, String> def, bool isEarned, Badge? badge) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        color: isEarned
            ? AppTheme.primary.withOpacity(0.08)
            : AppTheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isEarned
              ? AppTheme.primary.withOpacity(0.35)
              : AppTheme.border.withOpacity(0.4),
          width: isEarned ? 1.5 : 1,
        ),
        boxShadow: isEarned
            ? [
                BoxShadow(
                  color: AppTheme.primary.withOpacity(0.12),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                )
              ]
            : null,
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Badge icon
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                gradient: isEarned ? AppTheme.primaryGradient : null,
                color: isEarned ? null : AppTheme.surfaceLight,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Center(
                child: isEarned
                    ? Text(def['emoji']!,
                        style: const TextStyle(fontSize: 30))
                    : Stack(
                        alignment: Alignment.center,
                        children: [
                          Text(def['emoji']!,
                              style: const TextStyle(
                                  fontSize: 30, color: Colors.transparent)),
                          const Icon(Icons.lock_rounded,
                              color: AppTheme.textMuted, size: 26),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 14),

            // Badge name
            Text(
              isEarned ? def['name']! : def['name']!,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: isEarned ? AppTheme.textPrimary : AppTheme.textMuted,
              ),
            ),
            const SizedBox(height: 6),

            // Description
            Text(
              def['description']!,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                color: isEarned
                    ? AppTheme.textSecondary
                    : AppTheme.textMuted,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 8),

            // Earned date or locked indicator
            if (isEarned && badge?.earnedAt != null)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppTheme.success.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '✓ Earned',
                  style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.success),
                ),
              )
            else if (!isEarned)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppTheme.textMuted.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '🔒 Locked',
                  style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textMuted),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.emoji_events_outlined,
              size: 48, color: AppTheme.textMuted),
          const SizedBox(height: 16),
          Text(_error ?? 'Failed to load badges.',
              style: const TextStyle(color: AppTheme.textSecondary)),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _loadBadges,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}
