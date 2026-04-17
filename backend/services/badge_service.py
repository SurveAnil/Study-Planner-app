"""
Badge Service

Evaluates achievement conditions, awards badges, writes notification events,
and returns badge progress data for motivational "next goal" UI.

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
from services.notification_db_service import NotificationDbService
from datetime import date, timedelta
from typing import List, Dict, Optional

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
    Checks badge conditions, awards badges, writes notification history,
    and returns badge progress for motivational UI.
    """

    def __init__(self, db: Session):
        self.db = db
        self._notif_svc = NotificationDbService(db)

    def check_and_award_badges(self, user_id: int) -> List[UserBadge]:
        """
        Evaluate all badge conditions and award newly earned badges.
        Persists a notification for each badge earned.
        Returns list of newly earned UserBadge objects.
        """
        newly_earned: List[UserBadge] = []
        existing = self._get_existing_badge_types(user_id)

        checks = [
            ("first_habit",  self._check_first_habit),
            ("streak_7",     self._check_streak_7),
            ("streak_30",    self._check_streak_30),
            ("perfect_week", self._check_perfect_week),
        ]

        for badge_type, check_fn in checks:
            if badge_type in existing:
                continue
            if check_fn(user_id):
                badge = self._award_badge(user_id, badge_type)
                if badge:
                    newly_earned.append(badge)
                    # Write persistent notification
                    try:
                        defn = BADGE_DEFINITIONS[badge_type]
                        self._notif_svc.create(
                            user_id=user_id,
                            notification_type="badge_earned",
                            title=f"Badge Unlocked: {defn['name']}",
                            message=defn["description"],
                            emoji=defn["emoji"],
                        )
                    except Exception as e:
                        logger.warning(f"Failed to create badge notification: {e}")

        return newly_earned

    def get_user_badges(self, user_id: int) -> List[UserBadge]:
        """Return all badges earned by a user, newest first."""
        return (
            self.db.query(UserBadge)
            .filter(UserBadge.user_id == user_id)
            .order_by(UserBadge.earned_at.desc())
            .all()
        )

    def get_badge_progress(self, user_id: int) -> List[dict]:
        """
        Return progress toward each badge — current/target values.
        Used to drive "5/7 days → 🔥 Badge" motivational UI.
        """
        existing = self._get_existing_badge_types(user_id)
        habits = self.db.query(Habit).filter(Habit.user_id == user_id).all()
        habit_ids = [h.id for h in habits]

        # Max current streak across all habits
        max_streak = 0
        total_logs = 0
        for hid in habit_ids:
            s = self._calculate_streak(hid)
            max_streak = max(max_streak, s)
            log_count = self.db.query(DailyLog).filter(
                DailyLog.habit_id == hid,
                DailyLog.status == "completed",
            ).count()
            total_logs += log_count

        # Best consecutive days where ALL habits were completed
        best_complete_days = self._get_best_all_complete_streak(habit_ids)

        progress = []

        # ⚡ first_habit
        first_done = min(total_logs, 1)
        progress.append({
            "badge_type": "first_habit",
            "badge_name": "First Step",
            "badge_emoji": "⚡",
            "current_value": first_done,
            "target_value": 1,
            "percentage": 100.0 if first_done >= 1 else 0.0,
            "is_earned": "first_habit" in existing,
            "hint": "Complete your first habit to unlock" if first_done < 1 else "✓ Unlocked!",
        })

        # 🔥 streak_7
        cur7 = min(max_streak, 7)
        progress.append({
            "badge_type": "streak_7",
            "badge_name": "7-Day Streak",
            "badge_emoji": "🔥",
            "current_value": cur7,
            "target_value": 7,
            "percentage": round(min(100.0, (max_streak / 7) * 100), 1),
            "is_earned": "streak_7" in existing,
            "hint": f"{cur7}/7 days — keep going!" if cur7 < 7 else "✓ Unlocked!",
        })

        # 💎 streak_30
        cur30 = min(max_streak, 30)
        progress.append({
            "badge_type": "streak_30",
            "badge_name": "30-Day Streak",
            "badge_emoji": "💎",
            "current_value": cur30,
            "target_value": 30,
            "percentage": round(min(100.0, (max_streak / 30) * 100), 1),
            "is_earned": "streak_30" in existing,
            "hint": f"{cur30}/30 days — stay consistent!" if cur30 < 30 else "✓ Unlocked!",
        })

        # 🎯 perfect_week
        curw = min(best_complete_days, 7)
        progress.append({
            "badge_type": "perfect_week",
            "badge_name": "Perfect Week",
            "badge_emoji": "🎯",
            "current_value": curw,
            "target_value": 7,
            "percentage": round(min(100.0, (best_complete_days / 7) * 100), 1),
            "is_earned": "perfect_week" in existing,
            "hint": f"{curw}/7 perfect days — complete all habits daily!" if curw < 7 else "✓ Unlocked!",
        })

        return progress

    # ── Private: Condition Checkers ───────────────────────────────

    def _check_first_habit(self, user_id: int) -> bool:
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
        for habit in self.db.query(Habit).filter(Habit.user_id == user_id).all():
            if self._calculate_streak(habit.id) >= 7:
                return True
        return False

    def _check_streak_30(self, user_id: int) -> bool:
        for habit in self.db.query(Habit).filter(Habit.user_id == user_id).all():
            if self._calculate_streak(habit.id) >= 30:
                return True
        return False

    def _check_perfect_week(self, user_id: int) -> bool:
        habits = self.db.query(Habit).filter(Habit.user_id == user_id).all()
        if not habits:
            return False
        today = date.today()
        habit_ids = [h.id for h in habits]
        num_habits = len(habit_ids)
        for offset in range(0, 24):
            window_dates = [today - timedelta(days=offset + 6 - i) for i in range(7)]
            perfect = all(
                self.db.query(DailyLog).filter(
                    DailyLog.habit_id.in_(habit_ids),
                    DailyLog.status == "completed",
                    DailyLog.log_date == d,
                ).count() >= num_habits
                for d in window_dates
            )
            if perfect:
                return True
        return False

    def _calculate_streak(self, habit_id: int) -> int:
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

    def _get_best_all_complete_streak(self, habit_ids: list) -> int:
        """Longest consecutive streak where ALL habits were completed in a single day."""
        if not habit_ids:
            return 0
        today = date.today()
        num = len(habit_ids)
        streak = 0
        for i in range(90):  # Check last 90 days
            check_date = today - timedelta(days=i)
            count = self.db.query(DailyLog).filter(
                DailyLog.habit_id.in_(habit_ids),
                DailyLog.status == "completed",
                DailyLog.log_date == check_date,
            ).count()
            if count >= num:
                streak += 1
            else:
                break
        return streak

    # ── Private: Award ────────────────────────────────────────────

    def _award_badge(self, user_id: int, badge_type: str) -> Optional[UserBadge]:
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
            return None

    def _get_existing_badge_types(self, user_id: int) -> set:
        rows = (
            self.db.query(UserBadge.badge_type)
            .filter(UserBadge.user_id == user_id)
            .all()
        )
        return {r.badge_type for r in rows}
