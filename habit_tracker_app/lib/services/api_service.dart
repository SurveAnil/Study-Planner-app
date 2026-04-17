import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/habit.dart';
import '../models/user.dart';

class ApiService {
  final String baseUrl =
      'https://habit-tracker-api-7w4e.onrender.com/api'; // Adjust for your backend URL

  Future<List<Habit>> getHabits(int userId) async {
    final response = await http
        .get(Uri.parse('$baseUrl/habits/$userId'))
        .timeout(const Duration(seconds: 10));
    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(response.body);
      return data.map((json) => Habit.fromJson(json)).toList();
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
        .timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      return Habit.fromJson(json.decode(response.body));
    } else {
      final error =
          json.decode(response.body)['detail'] ?? 'Failed to create habit';
      throw Exception(error);
    }
  }

  Future<void> markHabitDone(
    int habitId,
    DateTime logDate,
    String? notes,
  ) async {
    final response = await http
        .post(
          Uri.parse('$baseUrl/habits/$habitId/log'),
          headers: {'Content-Type': 'application/json'},
          body: json.encode({
            'log_date': logDate.toIso8601String(),
            'notes': notes,
          }),
        )
        .timeout(const Duration(seconds: 10));

    if (response.statusCode != 200) {
      throw Exception('Failed to log habit');
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
        .timeout(const Duration(seconds: 10));
    if (response.statusCode != 200) {
      throw Exception('Failed to update habit');
    }
  }

  Future<void> deleteHabit(int habitId) async {
    final response = await http
        .delete(Uri.parse('$baseUrl/habits/$habitId'))
        .timeout(const Duration(seconds: 10));
    if (response.statusCode != 200) {
      throw Exception('Failed to delete habit');
    }
  }

  Future<User?> getUser(String firebaseUid) async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/users/$firebaseUid'))
          .timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        if (decoded == null) return null; // backend returned null body
        return User.fromJson(decoded as Map<String, dynamic>);
      } else if (response.statusCode == 404) {
        return null; // user does not exist yet
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
}
