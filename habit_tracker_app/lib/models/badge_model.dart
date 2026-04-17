/// Achievement badge earned by the user.
/// Named HabitBadge to avoid conflict with Flutter's material Badge widget.
class HabitBadge {
  final int id;
  final String badgeType;
  final String badgeName;
  final String badgeEmoji;
  final String description;
  final DateTime? earnedAt;

  HabitBadge({
    required this.id,
    required this.badgeType,
    required this.badgeName,
    required this.badgeEmoji,
    required this.description,
    this.earnedAt,
  });

  factory HabitBadge.fromJson(Map<String, dynamic> json) {
    return HabitBadge(
      id: json['id'],
      badgeType: json['badge_type'],
      badgeName: json['badge_name'],
      badgeEmoji: json['badge_emoji'],
      description: json['description'],
      earnedAt: json['earned_at'] != null
          ? DateTime.tryParse(json['earned_at'])
          : null,
    );
  }
}

/// Response from GET /api/users/{uid}/badges
class BadgeListResponse {
  final List<HabitBadge> badges;
  final int total;

  BadgeListResponse({required this.badges, required this.total});

  factory BadgeListResponse.fromJson(Map<String, dynamic> json) {
    return BadgeListResponse(
      total: json['total'] ?? 0,
      badges: (json['badges'] as List<dynamic>?)
              ?.map((b) => HabitBadge.fromJson(b as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

/// Response from POST /api/users/{uid}/badges/check
class CheckBadgesResponse {
  final List<HabitBadge> newlyEarned;
  final int totalBadges;
  final String message;

  CheckBadgesResponse({
    required this.newlyEarned,
    required this.totalBadges,
    required this.message,
  });

  factory CheckBadgesResponse.fromJson(Map<String, dynamic> json) {
    return CheckBadgesResponse(
      totalBadges: json['total_badges'] ?? 0,
      message: json['message'] ?? '',
      newlyEarned: (json['newly_earned'] as List<dynamic>?)
              ?.map((b) => HabitBadge.fromJson(b as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}
