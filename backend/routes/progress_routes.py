"""
Progress Analytics Routes

Provides aggregated user progress data including:
- Total habits & completion counts
- Average streak across all habits
- Per-habit streaks and completion percentages
- Missed habit reminders
- Consistency scoring
- AI insight message (personalized feedback)
- Streak risk warnings
"""

import logging
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from database.db_connection import get_db
from models.user import User
from models.habit import Habit
from models.daily_log import DailyLog
from services.streak_service import StreakService
from services.insight_service import InsightService
from services.badge_service import BadgeService
from services.notification_db_service import NotificationDbService
from pydantic import BaseModel
from datetime import date, timedelta
from typing import List, Optional

logger = logging.getLogger(__name__)

router = APIRouter()


# ── Response Schemas ─────────────────────────────────────────────

class HabitProgress(BaseModel):
    habit_id: int
    title: str
    frequency: str
    current_streak: int
    longest_streak: int
    completion_percentage: float
    completed_last_30d: int
    total_logs: int


class MissedHabitReminder(BaseModel):
    habit_id: int
    title: str
    days_missed: int
    message: str


class StreakRisk(BaseModel):
    habit_id: int
    title: str
    days_missed: int


class BadgeProgress(BaseModel):
    badge_type: str
    badge_name: str
    badge_emoji: str
    current_value: int
    target_value: int
    percentage: float
    is_earned: bool
    hint: str


class UserProgress(BaseModel):
    total_habits: int
    total_completed_last_30d: int
    completed_today: int
    average_streak: float
    consistency_score: float
    ai_insight: str
    unread_notifications: int
    habits: List[HabitProgress]
    reminders: List[MissedHabitReminder]
    streak_risks: List[StreakRisk]
    badge_progress: List[BadgeProgress]


# ── Routes ───────────────────────────────────────────────────────

@router.get("/users/{firebase_uid}/progress", response_model=UserProgress)
def get_user_progress(firebase_uid: str, db: Session = Depends(get_db)):
    """
    Aggregated progress analytics for a user.
    Returns streaks, completion rates, consistency scores, smart reminders,
    AI insight message, and streak risk warnings.
    """
    try:
        # 1. Find user
        user = db.query(User).filter(User.firebase_uid == firebase_uid).first()
        if not user:
            raise HTTPException(status_code=404, detail="User not found")

        # 2. Fetch all habits for this user
        habits = db.query(Habit).filter(Habit.user_id == user.id).all()

        streak_service = StreakService(db)
        insight_service = InsightService(db)
        badge_service = BadgeService(db)
        notif_svc = NotificationDbService(db)
        today = date.today()
        thirty_days_ago = today - timedelta(days=30)

        habit_progress_list: List[HabitProgress] = []
        reminders: List[MissedHabitReminder] = []
        total_completed_30d = 0
        completed_today = 0
        total_streak = 0
        total_possible_logs = 0
        total_actual_logs = 0

        for h in habits:
            hid = h.id

            # Calculate streaks
            cur_streak = streak_service.calculate_current_streak(hid)
            longest = streak_service.calculate_longest_streak(hid)
            perc = round(streak_service.get_completion_percentage(hid, days=30), 1)
            total_streak += cur_streak

            # Count completed logs in last 30 days
            completed_30d = db.query(DailyLog).filter(
                DailyLog.habit_id == hid,
                DailyLog.status == "completed",
                DailyLog.log_date >= thirty_days_ago,
            ).count()
            total_completed_30d += completed_30d

            # Count total logs ever
            total_logs = db.query(DailyLog).filter(
                DailyLog.habit_id == hid,
            ).count()

            # Check if completed today
            done_today = db.query(DailyLog).filter(
                DailyLog.habit_id == hid,
                DailyLog.status == "completed",
                DailyLog.log_date == today,
            ).first()
            if done_today:
                completed_today += 1

            # Consistency: for daily habits, 30 possible days; for weekly, ~4
            if h.frequency == 'daily':
                possible = 30
            else:
                possible = 4  # weekly
            total_possible_logs += possible
            total_actual_logs += completed_30d

            habit_progress_list.append(HabitProgress(
                habit_id=hid,
                title=h.title,
                frequency=h.frequency,
                current_streak=cur_streak,
                longest_streak=longest,
                completion_percentage=perc,
                completed_last_30d=completed_30d,
                total_logs=total_logs,
            ))

            # Smart reminder: check if missed yesterday
            yesterday = today - timedelta(days=1)
            missed_yesterday = db.query(DailyLog).filter(
                DailyLog.habit_id == hid,
                DailyLog.log_date == yesterday,
                DailyLog.status == "completed",
            ).first()

            if not missed_yesterday and cur_streak == 0:
                # Find how many consecutive days missed
                days_missed = 0
                for d in range(1, 8):
                    check_date = today - timedelta(days=d)
                    logged = db.query(DailyLog).filter(
                        DailyLog.habit_id == hid,
                        DailyLog.log_date == check_date,
                        DailyLog.status == "completed",
                    ).first()
                    if not logged:
                        days_missed += 1
                    else:
                        break

                if days_missed > 0:
                    reminders.append(MissedHabitReminder(
                        habit_id=hid,
                        title=h.title,
                        days_missed=days_missed,
                        message=f"You missed '{h.title}' for {days_missed} day(s). Resume your streak!",
                    ))

        # Overall metrics
        avg_streak = round(total_streak / len(habits), 1) if habits else 0.0
        consistency = round((total_actual_logs / total_possible_logs) * 100, 1) if total_possible_logs > 0 else 0.0

        # ── AI Insight ───────────────────────────────────────────
        habits_for_insight = [
            {"title": hp.title, "completion_percentage": hp.completion_percentage}
            for hp in habit_progress_list
        ]
        ai_insight = insight_service.generate_ai_insight(consistency, habits_for_insight)

        # ── Streak Risk Detection ────────────────────────────────
        risk_infos = insight_service.detect_streak_risks(user.id)
        streak_risks = [
            StreakRisk(
                habit_id=r.habit_id,
                title=r.title,
                days_missed=r.days_missed,
            )
            for r in risk_infos
        ]

        # Write streak-risk notifications (one per at-risk habit, deduped)
        try:
            for risk in risk_infos:
                if risk.days_missed == 2:  # Only on day 2 to avoid spam
                    notif_svc.create(
                        user_id=user.id,
                        notification_type="streak_risk",
                        title=f"⚠️ Streak at risk: {risk.title}",
                        message=f"You missed '{risk.title}' for {risk.days_missed} days. Act now!",
                        emoji="⚠️",
                    )
        except Exception as e:
            logger.warning(f"Failed to write risk notifications: {e}")

        # ── Badge Progress ───────────────────────────────────────
        raw_progress = badge_service.get_badge_progress(user.id)
        badge_progress = [
            BadgeProgress(**p) for p in raw_progress
        ]

        # ── Unread notification count ────────────────────────────
        unread_count = notif_svc.get_unread_count(user.id)

        return UserProgress(
            total_habits=len(habits),
            total_completed_last_30d=total_completed_30d,
            completed_today=completed_today,
            average_streak=avg_streak,
            consistency_score=consistency,
            ai_insight=ai_insight,
            unread_notifications=unread_count,
            habits=habit_progress_list,
            reminders=reminders,
            streak_risks=streak_risks,
            badge_progress=badge_progress,
        )

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error computing progress for {firebase_uid}: {e}")
        raise HTTPException(status_code=500, detail="Failed to compute progress")
