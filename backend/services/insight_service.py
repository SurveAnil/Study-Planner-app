"""
Insight Service

Provides AI-driven personalized insights and streak risk detection.
Follows OOP principles — all logic is encapsulated in the service class,
keeping routes thin.
"""

from sqlalchemy.orm import Session
from models.habit import Habit
from models.daily_log import DailyLog
from datetime import date, timedelta
from typing import List, Optional


class StreakRiskInfo:
    """Data class for a habit whose streak is at risk."""
    def __init__(self, habit_id: int, title: str, days_missed: int):
        self.habit_id = habit_id
        self.title = title
        self.days_missed = days_missed


class InsightService:
    """
    Generates personalized insights and detects streak risks.

    Usage:
        service = InsightService(db)
        insight = service.generate_ai_insight(consistency_score, habits_progress)
        risks = service.detect_streak_risks(user_id)
    """

    def __init__(self, db: Session):
        self.db = db

    def generate_ai_insight(
        self,
        consistency_score: float,
        habits_progress: list,
    ) -> str:
        """
        Generate a personalized AI insight message based on the user's
        consistency score and per-habit performance.

        Args:
            consistency_score: Overall consistency percentage (0-100).
            habits_progress: List of dicts with keys 'title' and 'completion_percentage'.

        Returns:
            A human-readable insight string.
        """

        # 1. Base insight from consistency score
        if consistency_score < 50:
            base = (
                "You're struggling with consistency. "
                "Start with smaller goals and focus on daily completion."
            )
        elif consistency_score < 80:
            base = (
                "Good progress! You're building momentum. "
                "Try to maintain your streaks and stay disciplined."
            )
        else:
            base = (
                "Excellent discipline! You're maintaining strong consistency. "
                "Keep pushing your limits and raise the bar."
            )

        # 2. Identify lowest-performing habit for a specific recommendation
        focus_suggestion = self._get_focus_suggestion(habits_progress)
        if focus_suggestion:
            return f"{base} {focus_suggestion}"

        return base

    def _get_focus_suggestion(self, habits_progress: list) -> Optional[str]:
        """Find the lowest-performing habit and suggest focus."""
        if not habits_progress:
            return None

        lowest = min(habits_progress, key=lambda h: h.get("completion_percentage", 100))
        lowest_perc = lowest.get("completion_percentage", 100)
        lowest_title = lowest.get("title", "")

        # Only suggest focus if the habit is genuinely underperforming
        if lowest_perc < 70 and lowest_title:
            return f'Focus more on: "{lowest_title}" ({lowest_perc:.0f}% completion).'

        return None

    def detect_streak_risks(self, user_id: int) -> List[StreakRiskInfo]:
        """
        Detect habits whose streaks are at risk.

        A habit is "at risk" if the user hasn't logged it for >= 2 days.

        Args:
            user_id: The database user ID.

        Returns:
            List of StreakRiskInfo objects for at-risk habits.
        """
        today = date.today()
        habits = self.db.query(Habit).filter(Habit.user_id == user_id).all()

        risks: List[StreakRiskInfo] = []

        for habit in habits:
            days_missed = self._calculate_days_since_last_log(habit.id, today)

            if days_missed >= 2:
                risks.append(StreakRiskInfo(
                    habit_id=habit.id,
                    title=habit.title,
                    days_missed=days_missed,
                ))

        # Sort by severity (most missed first)
        risks.sort(key=lambda r: r.days_missed, reverse=True)
        return risks

    def _calculate_days_since_last_log(self, habit_id: int, today: date) -> int:
        """
        Calculate how many days since the last completed log for a habit.

        Returns:
            Number of days since last log, or 999 if never logged.
        """
        last_log = (
            self.db.query(DailyLog)
            .filter(
                DailyLog.habit_id == habit_id,
                DailyLog.status == "completed",
            )
            .order_by(DailyLog.log_date.desc())
            .first()
        )

        if not last_log or not last_log.log_date:
            return 999  # Never logged — definitely at risk

        delta = (today - last_log.log_date).days
        return max(0, delta)
