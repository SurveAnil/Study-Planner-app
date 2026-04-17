/// Model for per-habit progress data from the backend progress API.
class HabitProgress {
  final int habitId;
  final String title;
  final String frequency;
  final int currentStreak;
  final int longestStreak;
  final double completionPercentage;
  final int completedLast30d;
  final int totalLogs;

  HabitProgress({
    required this.habitId,
    required this.title,
    required this.frequency,
    required this.currentStreak,
    required this.longestStreak,
    required this.completionPercentage,
    required this.completedLast30d,
    required this.totalLogs,
  });

  factory HabitProgress.fromJson(Map<String, dynamic> json) {
    return HabitProgress(
      habitId: json['habit_id'],
      title: json['title'],
      frequency: json['frequency'] ?? 'daily',
      currentStreak: json['current_streak'] ?? 0,
      longestStreak: json['longest_streak'] ?? 0,
      completionPercentage: (json['completion_percentage'] ?? 0.0).toDouble(),
      completedLast30d: json['completed_last_30d'] ?? 0,
      totalLogs: json['total_logs'] ?? 0,
    );
  }
}

/// Model for a missed-habit smart reminder.
class MissedHabitReminder {
  final int habitId;
  final String title;
  final int daysMissed;
  final String message;

  MissedHabitReminder({
    required this.habitId,
    required this.title,
    required this.daysMissed,
    required this.message,
  });

  factory MissedHabitReminder.fromJson(Map<String, dynamic> json) {
    return MissedHabitReminder(
      habitId: json['habit_id'],
      title: json['title'],
      daysMissed: json['days_missed'] ?? 0,
      message: json['message'] ?? '',
    );
  }
}

/// Model for a habit whose streak is at risk (2+ days without logging).
class StreakRisk {
  final int habitId;
  final String title;
  final int daysMissed;

  StreakRisk({
    required this.habitId,
    required this.title,
    required this.daysMissed,
  });

  factory StreakRisk.fromJson(Map<String, dynamic> json) {
    return StreakRisk(
      habitId: json['habit_id'],
      title: json['title'],
      daysMissed: json['days_missed'] ?? 0,
    );
  }
}

/// Progress toward a specific badge — drives "5/7 days → 🔥" motivational UI.
class BadgeProgress {
  final String badgeType;
  final String badgeName;
  final String badgeEmoji;
  final int currentValue;
  final int targetValue;
  final double percentage;
  final bool isEarned;
  final String hint;

  BadgeProgress({
    required this.badgeType,
    required this.badgeName,
    required this.badgeEmoji,
    required this.currentValue,
    required this.targetValue,
    required this.percentage,
    required this.isEarned,
    required this.hint,
  });

  factory BadgeProgress.fromJson(Map<String, dynamic> json) {
    return BadgeProgress(
      badgeType: json['badge_type'] ?? '',
      badgeName: json['badge_name'] ?? '',
      badgeEmoji: json['badge_emoji'] ?? '🏆',
      currentValue: json['current_value'] ?? 0,
      targetValue: json['target_value'] ?? 1,
      percentage: (json['percentage'] ?? 0.0).toDouble(),
      isEarned: json['is_earned'] ?? false,
      hint: json['hint'] ?? '',
    );
  }
}

/// Aggregated user progress data from GET /api/users/{uid}/progress.
class UserProgress {
  final int totalHabits;
  final int totalCompletedLast30d;
  final int completedToday;
  final double averageStreak;
  final double consistencyScore;
  final String aiInsight;
  final int unreadNotifications;
  final List<HabitProgress> habits;
  final List<MissedHabitReminder> reminders;
  final List<StreakRisk> streakRisks;
  final List<BadgeProgress> badgeProgress;

  UserProgress({
    required this.totalHabits,
    required this.totalCompletedLast30d,
    required this.completedToday,
    required this.averageStreak,
    required this.consistencyScore,
    required this.aiInsight,
    required this.unreadNotifications,
    required this.habits,
    required this.reminders,
    required this.streakRisks,
    required this.badgeProgress,
  });

  factory UserProgress.fromJson(Map<String, dynamic> json) {
    return UserProgress(
      totalHabits: json['total_habits'] ?? 0,
      totalCompletedLast30d: json['total_completed_last_30d'] ?? 0,
      completedToday: json['completed_today'] ?? 0,
      averageStreak: (json['average_streak'] ?? 0.0).toDouble(),
      consistencyScore: (json['consistency_score'] ?? 0.0).toDouble(),
      aiInsight: json['ai_insight'] ?? '',
      unreadNotifications: json['unread_notifications'] ?? 0,
      habits: (json['habits'] as List<dynamic>?)
              ?.map((h) => HabitProgress.fromJson(h as Map<String, dynamic>))
              .toList() ??
          [],
      reminders: (json['reminders'] as List<dynamic>?)
              ?.map((r) => MissedHabitReminder.fromJson(r as Map<String, dynamic>))
              .toList() ??
          [],
      streakRisks: (json['streak_risks'] as List<dynamic>?)
              ?.map((r) => StreakRisk.fromJson(r as Map<String, dynamic>))
              .toList() ??
          [],
      badgeProgress: (json['badge_progress'] as List<dynamic>?)
              ?.map((b) => BadgeProgress.fromJson(b as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}
