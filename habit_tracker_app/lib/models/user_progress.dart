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

/// Aggregated user progress data from GET /api/users/{uid}/progress.
class UserProgress {
  final int totalHabits;
  final int totalCompletedLast30d;
  final int completedToday;
  final double averageStreak;
  final double consistencyScore;
  final List<HabitProgress> habits;
  final List<MissedHabitReminder> reminders;

  UserProgress({
    required this.totalHabits,
    required this.totalCompletedLast30d,
    required this.completedToday,
    required this.averageStreak,
    required this.consistencyScore,
    required this.habits,
    required this.reminders,
  });

  factory UserProgress.fromJson(Map<String, dynamic> json) {
    return UserProgress(
      totalHabits: json['total_habits'] ?? 0,
      totalCompletedLast30d: json['total_completed_last_30d'] ?? 0,
      completedToday: json['completed_today'] ?? 0,
      averageStreak: (json['average_streak'] ?? 0.0).toDouble(),
      consistencyScore: (json['consistency_score'] ?? 0.0).toDouble(),
      habits: (json['habits'] as List<dynamic>?)
              ?.map((h) => HabitProgress.fromJson(h as Map<String, dynamic>))
              .toList() ??
          [],
      reminders: (json['reminders'] as List<dynamic>?)
              ?.map((r) => MissedHabitReminder.fromJson(r as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}
