/// Achievement badge earned by the user.
class Badge {
  final int id;
  final String badgeType;
  final String badgeName;
  final String badgeEmoji;
  final String description;
  final DateTime? earnedAt;

  Badge({
    required this.id,
    required this.badgeType,
    required this.badgeName,
    required this.badgeEmoji,
    required this.description,
    this.earnedAt,
  });

  factory Badge.fromJson(Map<String, dynamic> json) {
    return Badge(
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
  final List<Badge> badges;
  final int total;

  BadgeListResponse({required this.badges, required this.total});

  factory BadgeListResponse.fromJson(Map<String, dynamic> json) {
    return BadgeListResponse(
      total: json['total'] ?? 0,
      badges: (json['badges'] as List<dynamic>?)
              ?.map((b) => Badge.fromJson(b as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

/// Response from POST /api/users/{uid}/badges/check
class CheckBadgesResponse {
  final List<Badge> newlyEarned;
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
              ?.map((b) => Badge.fromJson(b as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}
