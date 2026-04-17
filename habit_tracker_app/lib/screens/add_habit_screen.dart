import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

class AddHabitScreen extends StatefulWidget {
  final int userId;
  const AddHabitScreen({super.key, required this.userId});

  @override
  State<AddHabitScreen> createState() => _AddHabitScreenState();
}

class _AddHabitScreenState extends State<AddHabitScreen> {
  final _titleController = TextEditingController();
  String _frequency = 'daily';
  bool _isSaving = false;
  final ApiService _apiService = ApiService();

  Future<void> _saveHabit() async {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a habit name'),
          backgroundColor: AppTheme.danger,
        ),
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
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: AppTheme.success, size: 20),
                const SizedBox(width: 8),
                const Text('Habit created! 🎉'),
              ],
            ),
            backgroundColor: AppTheme.surfaceLight,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: AppTheme.danger,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('New Habit'),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Illustration
            Container(
              width: 64,
              height: 64,
              margin: const EdgeInsets.only(bottom: 24),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Icon(Icons.add_task_rounded, size: 32, color: AppTheme.primary),
            ),

            const Text(
              'What habit do you want to build?',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
            ),
            const SizedBox(height: 8),
            Text(
              'Choose a simple, actionable habit to start.',
              style: TextStyle(fontSize: 14, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 28),

            // Title input
            TextField(
              controller: _titleController,
              enabled: !_isSaving,
              style: const TextStyle(color: AppTheme.textPrimary, fontSize: 16),
              decoration: const InputDecoration(
                labelText: 'Habit Name',
                hintText: 'e.g. Drink 8 glasses of water',
                prefixIcon: Icon(Icons.edit_rounded, color: AppTheme.textMuted),
              ),
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 20),

            // Frequency selector
            const Text(
              'Frequency',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                _buildFrequencyOption('daily', 'Daily', Icons.today_rounded),
                const SizedBox(width: 12),
                _buildFrequencyOption('weekly', 'Weekly', Icons.date_range_rounded),
              ],
            ),
            const SizedBox(height: 36),

            // Save button
            SizedBox(
              height: 54,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _saveHabit,
                child: _isSaving
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                      )
                    : const Text('Create Habit', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFrequencyOption(String value, String label, IconData icon) {
    final isSelected = _frequency == value;
    return Expanded(
      child: GestureDetector(
        onTap: _isSaving ? null : () => setState(() => _frequency = value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.primary.withOpacity(0.12) : AppTheme.surfaceLight,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected ? AppTheme.primary : AppTheme.border,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(icon, color: isSelected ? AppTheme.primary : AppTheme.textMuted, size: 24),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? AppTheme.primary : AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
