import 'package:flutter/material.dart';
import '../services/api_service.dart';

class AddHabitScreen extends StatefulWidget {
  final int userId;

  AddHabitScreen({required this.userId});

  @override
  _AddHabitScreenState createState() => _AddHabitScreenState();
}

class _AddHabitScreenState extends State<AddHabitScreen> {
  final _titleController = TextEditingController();
  String _frequency = 'daily';
  bool _isSaving = false;

  final ApiService _apiService = ApiService();

  Future<void> _saveHabit() async {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Title cannot be empty'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      await _apiService.createHabit(
        widget.userId,
        _titleController.text.trim(),
        _frequency,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Habit added successfully!'), backgroundColor: Colors.green),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll('Exception: ', '')), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Add Habit')),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: 'Title',
                border: OutlineInputBorder(),
              ),
              enabled: !_isSaving,
            ),
            SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _frequency,
              decoration: InputDecoration(
                labelText: 'Frequency',
                border: OutlineInputBorder(),
              ),
              items: ['daily', 'weekly'].map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value.toUpperCase()),
                );
              }).toList(),
              onChanged: _isSaving
                  ? null
                  : (newValue) {
                      setState(() {
                        _frequency = newValue!;
                      });
                    },
            ),
            SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isSaving ? null : _saveHabit,
              child: _isSaving
                  ? SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : Text('Save Habit'),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
