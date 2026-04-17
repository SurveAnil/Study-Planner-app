import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/user.dart';
import '../models/user_progress.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

class ProgressScreen extends StatefulWidget {
  final User user;
  const ProgressScreen({super.key, required this.user});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen>
    with AutomaticKeepAliveClientMixin {
  final ApiService _apiService = ApiService();
  UserProgress? _progress;
  bool _isLoading = true;
  String? _error;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _fetchProgress();
  }

  Future<void> _fetchProgress() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final p = await _apiService.getUserProgress(widget.user.firebaseUid);
      if (mounted) {
        setState(() {
          _progress = p;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = 'Failed to load progress. Pull to retry.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return SafeArea(
      child: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
          : _error != null
              ? _buildError()
              : _progress == null
                  ? _buildError()
                  : _buildContent(),
    );
  }

  Widget _buildContent() {
    return RefreshIndicator(
      onRefresh: _fetchProgress,
      color: AppTheme.primary,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Header
          const Text(
            'Your Progress',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AppTheme.textPrimary),
          ),
          const SizedBox(height: 4),
          Text(
            'Track your consistency and growth',
            style: TextStyle(fontSize: 14, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 24),

          // ── AI Insight Card ──────────────────────────────────
          if (_progress!.aiInsight.isNotEmpty) ...[
            _buildAiInsightCard(),
            const SizedBox(height: 20),
          ],

          // ── Streak Risk Warnings ─────────────────────────────
          if (_progress!.streakRisks.isNotEmpty) ...[
            _buildStreakRiskSection(),
            const SizedBox(height: 20),
          ],

          // Summary cards
          _buildSummaryRow(),
          const SizedBox(height: 24),

          // Consistency score
          _buildConsistencyCard(),
          const SizedBox(height: 24),

          // Reminders
          if (_progress!.reminders.isNotEmpty) ...[
            _buildRemindersSection(),
            const SizedBox(height: 24),
          ],

          // Streak chart
          _buildSectionHeader('Streak Overview', Icons.local_fire_department_rounded),
          const SizedBox(height: 12),
          _buildStreakChart(),
          const SizedBox(height: 24),

          // Completion chart
          _buildSectionHeader('Completion Rate (30 days)', Icons.pie_chart_rounded),
          const SizedBox(height: 12),
          _buildCompletionChart(),
          const SizedBox(height: 24),

          // Per-habit breakdown
          _buildSectionHeader('Habit Breakdown', Icons.list_alt_rounded),
          const SizedBox(height: 12),
          ..._progress!.habits.map((h) => _buildHabitBreakdownCard(h)),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  // ── AI Insight Card ──────────────────────────────────────────

  Widget _buildAiInsightCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6C63FF), Color(0xFF896BFF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withOpacity(0.25),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.lightbulb_rounded, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Your Insight Today',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _progress!.aiInsight,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white.withOpacity(0.9),
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Streak Risk Warning Section ────────────────────────────────

  Widget _buildStreakRiskSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('⚠️ Streaks at Risk', Icons.warning_amber_rounded),
        const SizedBox(height: 10),
        ..._progress!.streakRisks.map((risk) => _buildStreakRiskCard(risk)),
      ],
    );
  }

  Widget _buildStreakRiskCard(StreakRisk risk) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.danger.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.danger.withOpacity(0.25)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppTheme.danger.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(
                '${risk.daysMissed}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.danger,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  risk.title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Missed for ${risk.daysMissed} day(s) — your streak is at risk!',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.danger.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: AppTheme.danger, size: 20),
        ],
      ),
    );
  }

  // ── Summary Row ────────────────────────────────────────────────

  Widget _buildSummaryRow() {
    return Row(
      children: [
        _buildSummaryCard('Total\nHabits', '${_progress!.totalHabits}', AppTheme.primary, Icons.format_list_numbered),
        const SizedBox(width: 12),
        _buildSummaryCard('Done\n(30d)', '${_progress!.totalCompletedLast30d}', AppTheme.success, Icons.check_circle),
        const SizedBox(width: 12),
        _buildSummaryCard('Avg\nStreak', '${_progress!.averageStreak.toStringAsFixed(1)}', AppTheme.streakFire, Icons.local_fire_department),
      ],
    );
  }

  Widget _buildSummaryCard(String label, String value, Color color, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.border.withOpacity(0.5)),
        ),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 10),
            Text(
              value,
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: color),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary, height: 1.3),
            ),
          ],
        ),
      ),
    );
  }

  // ── Consistency Score ──────────────────────────────────────────

  Widget _buildConsistencyCard() {
    final score = _progress!.consistencyScore;
    Color scoreColor;
    String scoreLabel;

    if (score >= 80) {
      scoreColor = AppTheme.success;
      scoreLabel = 'Excellent! 🌟';
    } else if (score >= 60) {
      scoreColor = AppTheme.primary;
      scoreLabel = 'Good progress! 💪';
    } else if (score >= 40) {
      scoreColor = AppTheme.warning;
      scoreLabel = 'Keep pushing! 🔄';
    } else {
      scoreColor = AppTheme.danger;
      scoreLabel = 'Let\'s improve! 🚀';
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border.withOpacity(0.5)),
      ),
      child: Row(
        children: [
          // Score ring
          SizedBox(
            width: 70,
            height: 70,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 70,
                  height: 70,
                  child: CircularProgressIndicator(
                    value: score / 100,
                    strokeWidth: 5,
                    backgroundColor: AppTheme.surfaceLight,
                    valueColor: AlwaysStoppedAnimation<Color>(scoreColor),
                  ),
                ),
                Text(
                  '${score.round()}%',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: scoreColor),
                ),
              ],
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Consistency Score',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
                ),
                const SizedBox(height: 4),
                Text(
                  scoreLabel,
                  style: TextStyle(fontSize: 14, color: scoreColor, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 4),
                Text(
                  'Based on last 30 days of activity',
                  style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Smart Reminders ────────────────────────────────────────────

  Widget _buildRemindersSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Reminders', Icons.notifications_active_rounded),
        const SizedBox(height: 12),
        ..._progress!.reminders.map((r) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.warning.withOpacity(0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppTheme.warning.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: AppTheme.warning, size: 22),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      r.message,
                      style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary),
                    ),
                  ),
                ],
              ),
            )),
      ],
    );
  }

  // ── Streak Bar Chart ───────────────────────────────────────────

  Widget _buildStreakChart() {
    if (_progress!.habits.isEmpty) return _buildNoData();

    final habits = _progress!.habits;

    return Container(
      height: 220,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border.withOpacity(0.5)),
      ),
      child: BarChart(
        BarChartData(
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                return BarTooltipItem(
                  '${habits[group.x.toInt()].title}\n${rod.toY.round()} days',
                  const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                );
              },
            ),
          ),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final idx = value.toInt();
                  if (idx >= habits.length) return const SizedBox.shrink();
                  final name = habits[idx].title;
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      name.length > 6 ? '${name.substring(0, 6)}…' : name,
                      style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary),
                    ),
                  );
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 28,
                getTitlesWidget: (value, meta) {
                  return Text(
                    value.toInt().toString(),
                    style: const TextStyle(fontSize: 10, color: AppTheme.textMuted),
                  );
                },
              ),
            ),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: 5,
            getDrawingHorizontalLine: (value) => FlLine(
              color: AppTheme.border.withOpacity(0.3),
              strokeWidth: 1,
            ),
          ),
          barGroups: habits
              .asMap()
              .entries
              .map((e) => BarChartGroupData(
                    x: e.key,
                    barRods: [
                      BarChartRodData(
                        toY: e.value.currentStreak.toDouble(),
                        gradient: AppTheme.fireGradient,
                        width: 20,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                      ),
                    ],
                  ))
              .toList(),
        ),
        duration: const Duration(milliseconds: 500),
      ),
    );
  }

  // ── Completion Line Chart ──────────────────────────────────────

  Widget _buildCompletionChart() {
    if (_progress!.habits.isEmpty) return _buildNoData();

    final habits = _progress!.habits;

    return Container(
      height: 220,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border.withOpacity(0.5)),
      ),
      child: BarChart(
        BarChartData(
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                return BarTooltipItem(
                  '${habits[group.x.toInt()].title}\n${rod.toY.round()}%',
                  const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                );
              },
            ),
          ),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final idx = value.toInt();
                  if (idx >= habits.length) return const SizedBox.shrink();
                  final name = habits[idx].title;
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      name.length > 6 ? '${name.substring(0, 6)}…' : name,
                      style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary),
                    ),
                  );
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 32,
                getTitlesWidget: (value, meta) {
                  return Text(
                    '${value.toInt()}%',
                    style: const TextStyle(fontSize: 10, color: AppTheme.textMuted),
                  );
                },
              ),
            ),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: 25,
            getDrawingHorizontalLine: (value) => FlLine(
              color: AppTheme.border.withOpacity(0.3),
              strokeWidth: 1,
            ),
          ),
          maxY: 100,
          barGroups: habits
              .asMap()
              .entries
              .map((e) => BarChartGroupData(
                    x: e.key,
                    barRods: [
                      BarChartRodData(
                        toY: e.value.completionPercentage,
                        gradient: AppTheme.successGradient,
                        width: 20,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                      ),
                    ],
                  ))
              .toList(),
        ),
        duration: const Duration(milliseconds: 500),
      ),
    );
  }

  // ── Per-Habit Breakdown Card ───────────────────────────────────

  Widget _buildHabitBreakdownCard(HabitProgress h) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.border.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title row
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  gradient: h.currentStreak > 0 ? AppTheme.fireGradient : null,
                  color: h.currentStreak == 0 ? AppTheme.surfaceLight : null,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: h.currentStreak > 0
                      ? Text('🔥', style: const TextStyle(fontSize: 16))
                      : Icon(Icons.circle_outlined, color: AppTheme.textMuted, size: 16),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(h.title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
                    Text(h.frequency.toUpperCase(), style: TextStyle(fontSize: 10, color: AppTheme.textMuted, letterSpacing: 1)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${h.completionPercentage.round()}%',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.primaryLight),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: h.completionPercentage / 100,
              backgroundColor: AppTheme.surfaceLight,
              valueColor: AlwaysStoppedAnimation<Color>(
                h.completionPercentage >= 80
                    ? AppTheme.success
                    : h.completionPercentage >= 50
                        ? AppTheme.primary
                        : AppTheme.warning,
              ),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 12),

          // Stats row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildMiniStat('Current', '${h.currentStreak}d', AppTheme.streakFire),
              _buildMiniStat('Longest', '${h.longestStreak}d', AppTheme.warning),
              _buildMiniStat('Done (30d)', '${h.completedLast30d}', AppTheme.success),
              _buildMiniStat('Total', '${h.totalLogs}', AppTheme.textSecondary),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: color)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 10, color: AppTheme.textMuted)),
      ],
    );
  }

  // ── Helpers ────────────────────────────────────────────────────

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: AppTheme.primary, size: 20),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
        ),
      ],
    );
  }

  Widget _buildNoData() {
    return Container(
      height: 120,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border.withOpacity(0.5)),
      ),
      child: const Text(
        'No data yet. Start logging habits!',
        style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cloud_off_rounded, size: 48, color: AppTheme.danger),
            const SizedBox(height: 16),
            Text(
              _error ?? 'Something went wrong',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppTheme.textSecondary, fontSize: 14),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _fetchProgress,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
