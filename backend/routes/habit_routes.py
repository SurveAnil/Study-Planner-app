from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from sqlalchemy.exc import IntegrityError
from database.db_connection import get_db
from services.habit_service import HabitService
from services.streak_service import StreakService
from pydantic import BaseModel, Field
from datetime import date
from typing import Annotated, List, Optional, cast, Literal

router = APIRouter()

class HabitCreate(BaseModel):
    user_id: int
    title: str = Field(..., min_length=1, description="Title cannot be empty")
    frequency: Literal['daily', 'weekly']

class HabitUpdate(BaseModel):
    title: Optional[str] = Field(None, min_length=1)
    frequency: Optional[Literal['daily', 'weekly']] = None

class LogCreate(BaseModel):
    log_date: date
    notes: Optional[str] = None

@router.post("/habits/")
def create_habit(habit: HabitCreate, db: Annotated[Session, Depends(get_db)]):
    try:
        service = HabitService(db)
        return service.create_habit(habit.user_id, habit.title, habit.frequency)
    except IntegrityError:
        db.rollback()
        raise HTTPException(status_code=400, detail="Habit with this title already exists for this user.")
    except Exception as e:
        db.rollback()
        raise HTTPException(status_code=500, detail="Internal server error")

@router.get("/habits/{user_id}")
def get_habits(user_id: int, db: Annotated[Session, Depends(get_db)]):
    try:
        service = HabitService(db)
        habits = service.get_habits_by_user(user_id)
        streak_service = StreakService(db)
        for habit in habits:
            habit_id = cast(int, habit.id)
            habit.current_streak = streak_service.calculate_current_streak(habit_id)
            habit.longest_streak = streak_service.calculate_longest_streak(habit_id)
            habit.completion_percentage = streak_service.get_completion_percentage(habit_id)
        return habits
    except Exception as e:
        raise HTTPException(status_code=500, detail="Internal server error")

@router.put("/habits/{habit_id}")
def update_habit(habit_id: int, habit: HabitUpdate, db: Annotated[Session, Depends(get_db)]):
    try:
        service = HabitService(db)
        updated_habit = service.update_habit(habit_id, **habit.dict(exclude_unset=True))
        if not updated_habit:
            raise HTTPException(status_code=404, detail="Habit not found")
        return updated_habit
    except HTTPException:
        raise
    except IntegrityError:
        db.rollback()
        raise HTTPException(status_code=400, detail="Habit with this title already exists for this user.")
    except Exception as e:
        db.rollback()
        raise HTTPException(status_code=500, detail="Internal server error")

@router.delete("/habits/{habit_id}")
def delete_habit(habit_id: int, db: Annotated[Session, Depends(get_db)]):
    try:
        service = HabitService(db)
        deleted_habit = service.delete_habit(habit_id)
        if not deleted_habit:
            raise HTTPException(status_code=404, detail="Habit not found")
        return {"detail": "Habit deleted"}
    except HTTPException:
        raise
    except Exception as e:
        db.rollback()
        raise HTTPException(status_code=500, detail="Internal server error")

@router.post("/habits/{habit_id}/log")
def mark_done(habit_id: int, log: LogCreate, db: Annotated[Session, Depends(get_db)]):
    try:
        service = HabitService(db)
        return service.mark_habit_done(habit_id, log.log_date, log.notes)
    except IntegrityError:
        db.rollback()
        raise HTTPException(status_code=400, detail="Log entry could not be saved")
    except Exception as e:
        db.rollback()
        raise HTTPException(status_code=500, detail="Internal server error")

@router.get("/habits/{habit_id}/logs")
def get_logs(habit_id: int, db: Annotated[Session, Depends(get_db)]):
    try:
        service = HabitService(db)
        return service.get_logs_for_habit(habit_id)
    except Exception as e:
        raise HTTPException(status_code=500, detail="Internal server error")