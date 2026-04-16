from sqlalchemy.orm import Session
from models.habit import Habit
from models.daily_log import DailyLog
from datetime import date, timedelta
from typing import Optional

class HabitService:
    def __init__(self, db: Session):
        self.db = db

    def create_habit(self, user_id: int, title: str, frequency: str):
        habit = Habit(user_id=user_id, title=title, frequency=frequency)
        self.db.add(habit)
        self.db.commit()
        self.db.refresh(habit)
        return habit

    def get_habits_by_user(self, user_id: int):
        return self.db.query(Habit).filter(Habit.user_id == user_id).all()

    def update_habit(self, habit_id: int, **kwargs):
        habit = self.db.query(Habit).filter(Habit.id == habit_id).first()
        if habit:
            for key, value in kwargs.items():
                setattr(habit, key, value)
            self.db.commit()
            self.db.refresh(habit)
        return habit

    def delete_habit(self, habit_id: int):
        habit = self.db.query(Habit).filter(Habit.id == habit_id).first()
        if habit:
            self.db.delete(habit)
            self.db.commit()
        return habit

    def mark_habit_done(self, habit_id: int, log_date: date, notes: Optional[str] = None):
        log = DailyLog(habit_id=habit_id, log_date=log_date, status="completed", notes=notes)
        self.db.add(log)
        self.db.commit()
        self.db.refresh(log)
        return log

    def get_logs_for_habit(self, habit_id: int):
        return self.db.query(DailyLog).filter(DailyLog.habit_id == habit_id).all()