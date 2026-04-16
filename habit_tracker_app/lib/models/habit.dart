class Habit {
  final int id;
  final int userId;
  final String title;
  final String frequency;
  int currentStreak;
  int longestStreak;
  double completionPercentage;

  Habit({
    required this.id,
    required this.userId,
    required this.title,
    required this.frequency,
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.completionPercentage = 0.0,
  });

  factory Habit.fromJson(Map<String, dynamic> json) {
    return Habit(
      id: json['id'],
      userId: json['user_id'],
      title: json['title'],
      frequency: json['frequency'] ?? 'daily',
      currentStreak: json['current_streak'] ?? 0,
      longestStreak: json['longest_streak'] ?? 0,
      completionPercentage: json['completion_percentage'] ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'title': title,
      'frequency': frequency,
    };
  }
}
