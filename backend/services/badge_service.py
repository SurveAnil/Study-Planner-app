"""
Badge Service

Evaluates achievement conditions and awards badges to users.
All badge logic lives here — routes stay thin.

Badge Types:
    first_habit  — ⚡ First habit ever completed
    streak_7     — 🔥 7-day streak on any single habit
    streak_30    — 💎 30-day streak on any single habit
    perfect_week — 🎯 100% completion across all habits for any 7-day window
"""

import logging
from sqlalchemy.orm import Session
from sqlalchemy.exc import IntegrityError
from models.badge import UserBadge
from models.habit import Habit
from models.daily_log import DailyLog
from models.user import User
from datetime import date, timedelta
from typing import List, Dict

logger = logging.getLogger(__name__)


# ── Badge Definitions ─────────────────────────────────────────────

BADGE_DEFINITIONS: Dict[str, dict] = {
    "first_habit": {
        "name": "First Step",
        "emoji": "⚡",
        "description": "Completed your first habit. The journey begins!",
    },
    "streak_7": {
        "name": "7-Day Streak",
        "emoji": "🔥",
        "description": "Maintained a 7-day streak on a habit. Momentum is building!",
    },
    "streak_30": {
        "name": "30-Day Streak",
        "emoji": "💎",
        "description": "Maintained a 30-day streak. Absolute discipline!",
    },
    "perfect_week": {
        "name": "Perfect Week",
        "emoji": "🎯",
        "description": "Completed 100% of habits for 7 consecutive days. Flawless!",
    },
}


class BadgeService:
    """
    Checks badge conditions and awards badges.

    Usage:
        service = BadgeService(db)
        newly_earned = service.check_and_award_badges(user_id)
        all_badges = service.get_user_badges(user_id)
    """

    def __init__(self, db: Session):
        self.db = db

    def check_and_award_badges(self, user_id: int) -> List[UserBadge]:
        """
        Evaluate all badge conditions for a user and award any newly earned badges.

        Returns:
            List of newly earned UserBadge objects (empty if none new).
        """
        newly_earned: List[UserBadge] = []

        # Get already-earned badge types to skip re-checking
        existing = self._get_existing_badge_types(user_id)

        checks = [
            ("first_habit", self._check_first_habit),
            ("streak_7",    self._check_streak_7),
            ("streak_30",   self._check_streak_30),
            ("perfect_week", self._check_perfect_week),
        ]

        for badge_type, check_fn in checks:
            if badge_type in existing:
                continue  # Already earned — skip
            if check_fn(user_id):
                badge = self._award_badge(user_id, badge_type)
                if badge:
                    newly_earned.append(badge)

        return newly_earned

    def get_user_badges(self, user_id: int) -> List[UserBadge]:
        """Return all badges earned by a user, newest first."""
        return (
            self.db.query(UserBadge)
            .filter(UserBadge.user_id == user_id)
            .order_by(UserBadge.earned_at.desc())
            .all()
        )

    # ── Private: Condition Checkers ───────────────────────────────

    def _check_first_habit(self, user_id: int) -> bool:
        """True if user has ever completed at least one habit log."""
        habit_ids = [
            h.id for h in self.db.query(Habit.id)
            .filter(Habit.user_id == user_id).all()
        ]
        if not habit_ids:
            return False
        return self.db.query(DailyLog).filter(
            DailyLog.habit_id.in_(habit_ids),
            DailyLog.status == "completed",
        ).first() is not None

    def _check_streak_7(self, user_id: int) -> bool:
        """True if any habit has current_streak >= 7."""
        habits = self.db.query(Habit).filter(Habit.user_id == user_id).all()
        for habit in habits:
            streak = self._calculate_streak(habit.id)
            if streak >= 7:
                return True
        return False

    def _check_streak_30(self, user_id: int) -> bool:
        """True if any habit has current_streak >= 30."""
        habits = self.db.query(Habit).filter(Habit.user_id == user_id).all()
        for habit in habits:
            streak = self._calculate_streak(habit.id)
            if streak >= 30:
                return True
        return False

    def _check_perfect_week(self, user_id: int) -> bool:
        """
        True if user completed ALL habits every day for any 7-day window
        in the last 30 days.
        """
        habits = self.db.query(Habit).filter(Habit.user_id == user_id).all()
        if not habits:
            return False

        today = date.today()
        habit_ids = [h.id for h in habits]
        num_habits = len(habit_ids)

        # Check each 7-day window in the last 30 days
        for offset in range(0, 24):  # 30 - 7 + 1 windows
            window_start = today - timedelta(days=offset + 6)
            window_end = today - timedelta(days=offset)
            window_dates = [window_start + timedelta(days=i) for i in range(7)]

            perfect = True
            for check_date in window_dates:
                completed = self.db.query(DailyLog).filter(
                    DailyLog.habit_id.in_(habit_ids),
                    DailyLog.status == "completed",
                    DailyLog.log_date == check_date,
                ).count()
                if completed < num_habits:
                    perfect = False
                    break

            if perfect:
                return True

        return False

    def _calculate_streak(self, habit_id: int) -> int:
        """Calculate the current streak for a habit (consecutive days back from today)."""
        today = date.today()
        streak = 0
        for i in range(365):
            check_date = today - timedelta(days=i)
            logged = self.db.query(DailyLog).filter(
                DailyLog.habit_id == habit_id,
                DailyLog.log_date == check_date,
                DailyLog.status == "completed",
            ).first()
            if logged:
                streak += 1
            else:
                break
        return streak

    # ── Private: Award ────────────────────────────────────────────

    def _award_badge(self, user_id: int, badge_type: str) -> UserBadge | None:
        """
        Insert a badge row. Returns None if it already exists (race condition guard).
        """
        definition = BADGE_DEFINITIONS.get(badge_type)
        if not definition:
            return None

        badge = UserBadge(
            user_id=user_id,
            badge_type=badge_type,
            badge_name=definition["name"],
            badge_emoji=definition["emoji"],
            description=definition["description"],
        )
        try:
            self.db.add(badge)
            self.db.commit()
            self.db.refresh(badge)
            logger.info(f"Awarded badge '{badge_type}' to user {user_id}")
            return badge
        except IntegrityError:
            self.db.rollback()
            logger.debug(f"Badge '{badge_type}' already exists for user {user_id}")
            return None

    def _get_existing_badge_types(self, user_id: int) -> set:
        """Return set of badge_type strings already earned by the user."""
        rows = (
            self.db.query(UserBadge.badge_type)
            .filter(UserBadge.user_id == user_id)
            .all()
        )
        return {r.badge_type for r in rows}
