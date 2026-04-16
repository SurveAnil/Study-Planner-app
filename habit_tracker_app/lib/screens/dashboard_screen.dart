import 'package:flutter/material.dart';
import '../models/user.dart';
import '../models/habit.dart';
import '../services/api_service.dart';
import 'add_habit_screen.dart';
import 'habit_detail_screen.dart';

class DashboardScreen extends StatefulWidget {
  final User user;

  DashboardScreen({required this.user});

  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final ApiService _apiService = ApiService();
  List<Habit> _habits = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadHabits();
  }

  Future<void> _loadHabits() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final habits = await _apiService.getHabits(widget.user.id);
      setState(() {
        _habits = habits;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = 'Failed to load habits. Please check your connection.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Dashboard'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadHabits,
          ),
        ],
      ),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddHabitScreen(userId: widget.user.id),
            ),
          ).then((_) => _loadHabits());
        },
        child: Icon(Icons.add),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_error!, style: TextStyle(color: Colors.red)),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadHabits,
              child: Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_habits.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.assignment_turned_in_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('No habits created yet.', style: TextStyle(fontSize: 18, color: Colors.grey)),
            SizedBox(height: 8),
            Text('Tap the + button to start your journey!', style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: _habits.length,
      itemBuilder: (context, index) {
        final habit = _habits[index];
        return Card(
          margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ListTile(
            leading: CircleAvatar(
              child: Icon(habit.frequency == 'daily' ? Icons.today : Icons.date_range),
              backgroundColor: Colors.indigo.shade100,
              foregroundColor: Colors.indigo,
            ),
            title: Text(habit.title, style: TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('Current Streak: ${habit.currentStreak} days'),
            trailing: Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => HabitDetailScreen(habit: habit),
                ),
              ).then((_) => _loadHabits());
            },
          ),
        );
      },
    );
  }
}
