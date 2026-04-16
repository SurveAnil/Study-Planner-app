from sqlalchemy.orm import Session
from models.daily_log import DailyLog
from datetime import date, timedelta

class StreakService:
    def __init__(self, db: Session):
        self.db = db

    def calculate_current_streak(self, habit_id: int):
        logs = self.db.query(DailyLog).filter(
            DailyLog.habit_id == habit_id,
            DailyLog.status == "completed"
        ).order_by(DailyLog.log_date.desc()).all()

        if not logs:
            return 0

        streak = 0
        current_date = date.today()
        for log in logs:
            if log.log_date == current_date - timedelta(days=streak):
                streak += 1
            else:
                break
        return streak

    def calculate_longest_streak(self, habit_id: int):
        logs = self.db.query(DailyLog).filter(
            DailyLog.habit_id == habit_id,
            DailyLog.status == "completed"
        ).order_by(DailyLog.log_date).all()

        if not logs:
            return 0

        max_streak = 0
        current_streak = 1
        for i in range(1, len(logs)):
            if logs[i].log_date == logs[i-1].log_date + timedelta(days=1):
                current_streak += 1
            else:
                max_streak = max(max_streak, current_streak)
                current_streak = 1
        max_streak = max(max_streak, current_streak)
        return max_streak

    def get_completion_percentage(self, habit_id: int, days: int = 30):
        end_date = date.today()
        start_date = end_date - timedelta(days=days)
        total_logs = self.db.query(DailyLog).filter(
            DailyLog.habit_id == habit_id,
            DailyLog.log_date >= start_date,
            DailyLog.log_date <= end_date
        ).count()
        completed_logs = self.db.query(DailyLog).filter(
            DailyLog.habit_id == habit_id,
            DailyLog.log_date >= start_date,
            DailyLog.log_date <= end_date,
            DailyLog.status == "completed"
        ).count()
        if total_logs == 0:
            return 0
        return (completed_logs / total_logs) * 100