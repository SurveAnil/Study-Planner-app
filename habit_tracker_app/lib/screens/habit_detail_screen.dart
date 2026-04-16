import 'package:flutter/material.dart';
import '../models/habit.dart';
import '../services/api_service.dart';

class HabitDetailScreen extends StatefulWidget {
  final Habit habit;

  HabitDetailScreen({required this.habit});

  @override
  _HabitDetailScreenState createState() => _HabitDetailScreenState();
}

class _HabitDetailScreenState extends State<HabitDetailScreen> {
  final ApiService _apiService = ApiService();
  bool _isProcessing = false;

  Future<void> _markDone() async {
    setState(() => _isProcessing = true);
    try {
      await _apiService.markHabitDone(widget.habit.id, DateTime.now(), 'Logged via app');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Progress logged!'), backgroundColor: Colors.green),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to log progress'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  Future<void> _deleteHabit() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Habit?'),
        content: Text('This action cannot be undone and will remove all history.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isProcessing = true);
      try {
        await _apiService.deleteHabit(widget.habit.id);
        Navigator.pop(context);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete habit')),
        );
      } finally {
        setState(() => _isProcessing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Habit Details'),
        actions: [
          IconButton(
            icon: Icon(Icons.delete_outline, color: Colors.redAccent),
            onPressed: _isProcessing ? null : _deleteHabit,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildInfoCard(),
            SizedBox(height: 24),
            _buildStatsSection(),
            SizedBox(height: 32),
            ElevatedButton(
              onPressed: _isProcessing ? null : _markDone,
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Colors.indigo,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _isProcessing
                  ? SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : Text('Mark as Done', style: TextStyle(fontSize: 18, color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [Colors.indigo.shade400, Colors.indigo.shade700]),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.indigo.withOpacity(0.3), blurRadius: 10, offset: Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.habit.title, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
          SizedBox(height: 16),
          _Badge(text: widget.habit.frequency.toUpperCase(), color: Colors.white24),
        ],
      ),
    );
  }

  Widget _buildStatsSection() {
    return Row(
      children: [
        _StatItem(label: 'STREAK', value: '${widget.habit.currentStreak}', icon: Icons.local_fire_department, color: Colors.orange),
        _StatItem(label: 'LONGEST', value: '${widget.habit.longestStreak}', icon: Icons.emoji_events, color: Colors.amber),
        _StatItem(label: 'GOAL', value: '${widget.habit.completionPercentage}%', icon: Icons.pie_chart, color: Colors.blue),
      ],
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatItem({required this.label, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          SizedBox(height: 8),
          Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          Text(label, style: TextStyle(fontSize: 10, letterSpacing: 1, color: Colors.grey)),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String text;
  final Color color;
  const _Badge({required this.text, required this.color});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(20)),
      child: Text(text, style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
    );
  }
}
