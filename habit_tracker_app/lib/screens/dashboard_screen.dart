import 'dart:math';
import 'package:flutter/material.dart';
import '../models/user.dart';
import '../models/habit.dart';
import '../models/user_progress.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../services/notification_service.dart';
import '../theme/app_theme.dart';
import 'add_habit_screen.dart';
import 'badges_screen.dart';
import 'habit_detail_screen.dart';
import 'notifications_screen.dart';
import 'progress_screen.dart';
import 'login_screen.dart';

class DashboardScreen extends StatefulWidget {
  final User user;
  const DashboardScreen({super.key, required this.user});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with TickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  final AuthService _authService = AuthService();
  List<Habit> _habits = [];
  bool _isLoading = true;
  String? _error;
  int _currentIndex = 0;
  final Set<int> _markedTodayIds = {};
  final Set<int> _atRiskHabitIds = {};
  bool _riskBannerShown = false;
  int _unreadNotifications = 0;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _loadHabits();
    // Request browser push permission on first load
    NotificationService.requestPushPermission();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _loadHabits() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final habits = await _apiService.getHabits(widget.user.id);
      if (mounted) {
        setState(() {
          _habits = habits;
          _isLoading = false;
        });
      }
      // Load streak risks in background (non-blocking)
      _loadStreakRisks();
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = 'Failed to load habits. Pull to retry.';
        });
      }
    }
  }

  /// Fetch streak risk data from the progress API to highlight at-risk habits.
  Future<void> _loadStreakRisks() async {
    try {
      final progress = await _apiService.getUserProgress(
        widget.user.firebaseUid,
      );
      if (mounted) {
        setState(() {
          _atRiskHabitIds.clear();
          for (final risk in progress.streakRisks) {
            _atRiskHabitIds.add(risk.habitId);
          }
          _unreadNotifications = progress.unreadNotifications;
        });
        // Show streak risk banner once per session
        if (!_riskBannerShown && progress.streakRisks.isNotEmpty) {
          _riskBannerShown = true;
          NotificationService.showStreakRiskBanner(context, progress.streakRisks);
        }
      }
    } catch (_) {
      // Non-critical — silently ignore if progress API fails
    }
  }

  Future<void> _markDone(Habit habit) async {
    // Optimistic update
    setState(() {
      _markedTodayIds.add(habit.id);
      habit.currentStreak += 1;
    });

    try {
      await _apiService.markHabitDone(
        habit.id,
        DateTime.now(),
        'Logged via app',
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(
                  Icons.check_circle,
                  color: AppTheme.success,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text('${habit.title} marked done! 🔥'),
              ],
            ),
            backgroundColor: AppTheme.surfaceLight,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      // Rollback on failure
      if (mounted) {
        setState(() {
          _markedTodayIds.remove(habit.id);
          habit.currentStreak = max(0, habit.currentStreak - 1);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to log: ${e.toString().replaceAll('Exception: ', '')}',
            ),
            backgroundColor: AppTheme.danger,
          ),
        );
      }
    }
  }

  Future<void> _signOut() async {
    await _authService.signOut();
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _buildDashboard(),
          ProgressScreen(user: widget.user),
          BadgesScreen(user: widget.user),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  // ── Bottom Navigation ──────────────────────────────────────────

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        border: Border(
          top: BorderSide(color: AppTheme.border.withOpacity(0.3)),
        ),
      ),
      child: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_rounded),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.insights_rounded),
            label: 'Progress',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.emoji_events_rounded),
            label: 'Achievements',
          ),
        ],
      ),
    );
  }

  // ── Dashboard Body ─────────────────────────────────────────────

  Widget _buildDashboard() {
    return SafeArea(
      child: Column(
        children: [
          _buildAppBar(),
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: AppTheme.primary),
                  )
                : _error != null
                ? _buildError()
                : _habits.isEmpty
                ? _buildEmpty()
                : _buildContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        children: [
          // Greeting
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getGreeting(),
                  style: TextStyle(fontSize: 14, color: AppTheme.textSecondary),
                ),
                const SizedBox(height: 2),
                Text(
                  widget.user.name,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          // Notification Bell with unread badge
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_rounded,
                    color: AppTheme.textSecondary),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          NotificationsScreen(user: widget.user),
                    ),
                  ).then((_) => _loadStreakRisks()); // Refresh unread count
                },
              ),
              if (_unreadNotifications > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    width: 16,
                    height: 16,
                    decoration: const BoxDecoration(
                      color: AppTheme.danger,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        _unreadNotifications > 9
                            ? '9+'
                            : '$_unreadNotifications',
                        style: const TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            color: Colors.white),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          // Refresh
          IconButton(
            icon: const Icon(
              Icons.refresh_rounded,
              color: AppTheme.textSecondary,
            ),
            onPressed: _loadHabits,
          ),
          // Logout
          IconButton(
            icon: const Icon(
              Icons.logout_rounded,
              color: AppTheme.textSecondary,
            ),
            onPressed: _signOut,
          ),
        ],
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning,';
    if (hour < 17) return 'Good afternoon,';
    return 'Good evening,';
  }

  Widget _buildContent() {
    final completedToday = _habits
        .where((h) => _markedTodayIds.contains(h.id))
        .length;

    // Sort habits: at-risk first, then by streak descending
    final sortedHabits = List<Habit>.from(_habits);
    sortedHabits.sort((a, b) {
      final aRisk = _atRiskHabitIds.contains(a.id) ? 0 : 1;
      final bRisk = _atRiskHabitIds.contains(b.id) ? 0 : 1;
      if (aRisk != bRisk) return aRisk.compareTo(bRisk);
      return b.currentStreak.compareTo(a.currentStreak);
    });

    return RefreshIndicator(
      onRefresh: _loadHabits,
      color: AppTheme.primary,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Daily progress ring
          _buildDailyProgressCard(completedToday),
          const SizedBox(height: 20),

          // Quick stats row
          _buildQuickStats(completedToday),
          const SizedBox(height: 24),

          // Section header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Your Habits',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
              TextButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AddHabitScreen(userId: widget.user.id),
                    ),
                  ).then((_) => _loadHabits());
                },
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Add'),
                style: TextButton.styleFrom(foregroundColor: AppTheme.primary),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Habit cards (at-risk sorted to top)
          ...sortedHabits.map((h) => _buildHabitCard(h)),
        ],
      ),
    );
  }

  // ── Daily Progress Ring ────────────────────────────────────────

  Widget _buildDailyProgressCard(int completedToday) {
    final total = _habits.length;
    final progress = total > 0 ? completedToday / total : 0.0;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          // Progress Ring
          SizedBox(
            width: 80,
            height: 80,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 80,
                  height: 80,
                  child: CircularProgressIndicator(
                    value: progress,
                    strokeWidth: 6,
                    backgroundColor: Colors.white.withOpacity(0.2),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Colors.white,
                    ),
                  ),
                ),
                Text(
                  '${(progress * 100).round()}%',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
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
                  "Today's Progress",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$completedToday of $total habits completed',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
                const SizedBox(height: 8),
                if (progress >= 1.0)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.25),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      '🎉 All done!',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Quick Stats Row ────────────────────────────────────────────

  Widget _buildQuickStats(int completedToday) {
    final avgStreak = _habits.isEmpty
        ? 0
        : (_habits.fold<int>(0, (sum, h) => sum + h.currentStreak) /
                  _habits.length)
              .round();

    return Row(
      children: [
        _buildStatChip(
          Icons.format_list_numbered_rounded,
          '${_habits.length}',
          'Total',
        ),
        const SizedBox(width: 12),
        _buildStatChip(
          Icons.check_circle_outline_rounded,
          '$completedToday',
          'Today',
        ),
        const SizedBox(width: 12),
        _buildStatChip(
          Icons.local_fire_department_rounded,
          '$avgStreak',
          'Avg Streak',
        ),
      ],
    );
  }

  Widget _buildStatChip(IconData icon, String value, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.border.withOpacity(0.5)),
        ),
        child: Column(
          children: [
            Icon(icon, color: AppTheme.primary, size: 22),
            const SizedBox(height: 6),
            Text(
              value,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Habit Card ─────────────────────────────────────────────────

  Widget _buildHabitCard(Habit habit) {
    final isDone = _markedTodayIds.contains(habit.id);
    final streakColor = _getStreakColor(habit.currentStreak);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: isDone ? AppTheme.primary.withOpacity(0.08) : AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => HabitDetailScreen(habit: habit),
              ),
            ).then((_) => _loadHabits());
          },
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDone
                    ? AppTheme.primary.withOpacity(0.3)
                    : AppTheme.border.withOpacity(0.5),
              ),
            ),
            child: Row(
              children: [
                // Streak badge
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: habit.currentStreak > 0
                        ? AppTheme.fireGradient
                        : null,
                    color: habit.currentStreak == 0
                        ? AppTheme.surfaceLight
                        : null,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: habit.currentStreak > 0
                        ? Text(
                            '🔥${habit.currentStreak}',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          )
                        : Icon(
                            habit.frequency == 'daily'
                                ? Icons.today_rounded
                                : Icons.date_range_rounded,
                            color: AppTheme.textSecondary,
                            size: 22,
                          ),
                  ),
                ),
                const SizedBox(width: 14),

                // Title & metadata
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        habit.title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: isDone
                              ? AppTheme.textSecondary
                              : AppTheme.textPrimary,
                          decoration: isDone
                              ? TextDecoration.lineThrough
                              : null,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          _buildMetaBadge(
                            habit.frequency.toUpperCase(),
                            AppTheme.primary.withOpacity(0.15),
                            AppTheme.primaryLight,
                          ),
                          const SizedBox(width: 8),
                          if (habit.completionPercentage > 0)
                            _buildMetaBadge(
                              '${habit.completionPercentage.round()}%',
                              AppTheme.success.withOpacity(0.15),
                              AppTheme.success,
                            ),
                          if (_atRiskHabitIds.contains(habit.id)) ...[
                            const SizedBox(width: 8),
                            _buildMetaBadge(
                              '⚠️ Risk',
                              AppTheme.danger.withOpacity(0.15),
                              AppTheme.danger,
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),

                // Done button
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: isDone
                      ? Container(
                          key: const ValueKey('done'),
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: AppTheme.success.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.check_rounded,
                            color: AppTheme.success,
                            size: 24,
                          ),
                        )
                      : Material(
                          key: const ValueKey('todo'),
                          color: AppTheme.primary.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(12),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () => _markDone(habit),
                            child: const SizedBox(
                              width: 42,
                              height: 42,
                              child: Icon(
                                Icons.check_rounded,
                                color: AppTheme.primary,
                                size: 24,
                              ),
                            ),
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMetaBadge(String text, Color bg, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }

  Color _getStreakColor(int streak) {
    if (streak >= 30) return AppTheme.danger;
    if (streak >= 14) return AppTheme.streakFire;
    if (streak >= 7) return AppTheme.warning;
    if (streak >= 3) return AppTheme.success;
    return AppTheme.textMuted;
  }

  // ── Empty & Error States ───────────────────────────────────────

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.add_task_rounded,
                size: 40,
                color: AppTheme.primary,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'No habits yet',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Start building better habits today.\nTap the + button to get started!',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AddHabitScreen(userId: widget.user.id),
                  ),
                ).then((_) => _loadHabits());
              },
              icon: const Icon(Icons.add_rounded),
              label: const Text('Create First Habit'),
            ),
          ],
        ),
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
            const Icon(
              Icons.cloud_off_rounded,
              size: 48,
              color: AppTheme.danger,
            ),
            const SizedBox(height: 16),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _loadHabits,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
