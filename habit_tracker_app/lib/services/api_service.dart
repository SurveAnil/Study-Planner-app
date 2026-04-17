import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/habit.dart';
import '../models/user.dart';
import '../models/user_progress.dart';
import '../models/badge_model.dart';

class ApiService {
  final String baseUrl = 'https://habit-tracker-api-7w4e.onrender.com/api';

  // ── Habits ──────────────────────────────────────────────────────

  Future<List<Habit>> getHabits(int userId) async {
    final response = await http
        .get(Uri.parse('$baseUrl/habits/$userId'))
        .timeout(const Duration(seconds: 15));
    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(response.body);
      return data.map((j) => Habit.fromJson(j as Map<String, dynamic>)).toList();
    } else {
      throw Exception('Failed to load habits');
    }
  }

  Future<Habit> createHabit(int userId, String title, String frequency) async {
    final response = await http
        .post(
          Uri.parse('$baseUrl/habits/'),
          headers: {'Content-Type': 'application/json'},
          body: json.encode({
            'user_id': userId,
            'title': title,
            'frequency': frequency,
          }),
        )
        .timeout(const Duration(seconds: 15));

    if (response.statusCode == 200 || response.statusCode == 201) {
      return Habit.fromJson(json.decode(response.body) as Map<String, dynamic>);
    } else {
      final error =
          json.decode(response.body)['detail'] ?? 'Failed to create habit';
      throw Exception(error);
    }
  }

  /// Mark a habit as done for a given date.
  /// Returns the log response JSON map on success.
  Future<Map<String, dynamic>> markHabitDone(
    int habitId,
    DateTime logDate,
    String? notes,
  ) async {
    final response = await http
        .post(
          Uri.parse('$baseUrl/habits/$habitId/log'),
          headers: {'Content-Type': 'application/json'},
          body: json.encode({
            'log_date':
                '${logDate.year}-${logDate.month.toString().padLeft(2, '0')}-${logDate.day.toString().padLeft(2, '0')}',
            'notes': notes,
          }),
        )
        .timeout(const Duration(seconds: 15));

    if (response.statusCode == 200 || response.statusCode == 201) {
      return json.decode(response.body) as Map<String, dynamic>;
    } else {
      final body = response.body.isNotEmpty ? response.body : '{}';
      final detail = json.decode(body)['detail'] ?? 'Failed to log habit';
      throw Exception(detail);
    }
  }

  Future<void> updateHabit(
    int habitId, {
    String? title,
    String? frequency,
  }) async {
    final response = await http
        .put(
          Uri.parse('$baseUrl/habits/$habitId'),
          headers: {'Content-Type': 'application/json'},
          body: json.encode({
            if (title != null) 'title': title,
            if (frequency != null) 'frequency': frequency,
          }),
        )
        .timeout(const Duration(seconds: 15));
    if (response.statusCode != 200) {
      throw Exception('Failed to update habit');
    }
  }

  Future<void> deleteHabit(int habitId) async {
    final response = await http
        .delete(Uri.parse('$baseUrl/habits/$habitId'))
        .timeout(const Duration(seconds: 15));
    if (response.statusCode != 200) {
      throw Exception('Failed to delete habit');
    }
  }

  // ── Users ──────────────────────────────────────────────────────

  Future<User?> getUser(String firebaseUid) async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/users/$firebaseUid'))
          .timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        if (decoded == null) return null;
        return User.fromJson(decoded as Map<String, dynamic>);
      } else if (response.statusCode == 404) {
        return null;
      } else {
        throw Exception('Failed to fetch user: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<User> createUser(String name, String email, String firebaseUid) async {
    final response = await http
        .post(
          Uri.parse('$baseUrl/users/'),
          headers: {'Content-Type': 'application/json'},
          body: json.encode({
            'name': name,
            'email': email,
            'firebase_uid': firebaseUid,
          }),
        )
        .timeout(const Duration(seconds: 15));

    if (response.statusCode == 200 || response.statusCode == 201) {
      final decoded = json.decode(response.body);
      if (decoded == null) {
        throw Exception('Backend returned empty response when creating user');
      }
      return User.fromJson(decoded as Map<String, dynamic>);
    } else {
      final body = response.body.isNotEmpty ? response.body : '{}';
      final detail = json.decode(body)['detail'] ?? 'Failed to create user';
      throw Exception(detail);
    }
  }

  // ── Progress Analytics ────────────────────────────────────────

  /// Fetch aggregated progress data for a user.
  Future<UserProgress> getUserProgress(String firebaseUid) async {
    final response = await http
        .get(Uri.parse('$baseUrl/users/$firebaseUid/progress'))
        .timeout(const Duration(seconds: 20));

    if (response.statusCode == 200) {
      final decoded = json.decode(response.body);
      if (decoded == null) {
        throw Exception('Backend returned empty progress data');
      }
      return UserProgress.fromJson(decoded as Map<String, dynamic>);
    } else {
      throw Exception('Failed to fetch progress: ${response.statusCode}');
    }
  }

  // ── Badges ────────────────────────────────────────────────────

  /// Fetch all earned badges for the user.
  Future<BadgeListResponse> getBadges(String firebaseUid) async {
    final response = await http
        .get(Uri.parse('$baseUrl/users/$firebaseUid/badges'))
        .timeout(const Duration(seconds: 15));

    if (response.statusCode == 200) {
      return BadgeListResponse.fromJson(
          json.decode(response.body) as Map<String, dynamic>);
    } else {
      throw Exception('Failed to fetch badges: ${response.statusCode}');
    }
  }

  /// Trigger badge evaluation — call after marking a habit done.
  /// Returns newly earned badges (may be empty).
  Future<CheckBadgesResponse> checkAndAwardBadges(String firebaseUid) async {
    final response = await http
        .post(Uri.parse('$baseUrl/users/$firebaseUid/badges/check'))
        .timeout(const Duration(seconds: 15));

    if (response.statusCode == 200) {
      return CheckBadgesResponse.fromJson(
          json.decode(response.body) as Map<String, dynamic>);
    } else {
      throw Exception('Failed to check badges: ${response.statusCode}');
    }
  }
}
