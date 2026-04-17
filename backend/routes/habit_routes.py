import logging
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from sqlalchemy.exc import IntegrityError
from database.db_connection import get_db
from models.habit import Habit
from models.daily_log import DailyLog
from services.habit_service import HabitService
from services.streak_service import StreakService
from pydantic import BaseModel, Field
from datetime import date
from typing import Annotated, List, Optional, cast, Literal

logger = logging.getLogger(__name__)

router = APIRouter()


# ── Request Schemas ──────────────────────────────────────────────

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


# ── Response Schemas ─────────────────────────────────────────────

class LogResponse(BaseModel):
    id: int
    habit_id: int
    status: str
    date: date
    notes: Optional[str] = None

    class Config:
        from_attributes = True


class HabitResponse(BaseModel):
    id: int
    user_id: int
    title: str
    frequency: str
    current_streak: int = 0
    longest_streak: int = 0
    completion_percentage: float = 0.0

    class Config:
        from_attributes = True


class LogEntryResponse(BaseModel):
    id: int
    habit_id: int
    log_date: date
    status: str
    notes: Optional[str] = None

    class Config:
        from_attributes = True


# ── Routes ───────────────────────────────────────────────────────

@router.post("/habits/", response_model=HabitResponse)
def create_habit(habit: HabitCreate, db: Annotated[Session, Depends(get_db)]):
    try:
        service = HabitService(db)
        db_habit = service.create_habit(habit.user_id, habit.title, habit.frequency)
        return HabitResponse(
            id=db_habit.id,
            user_id=db_habit.user_id,
            title=db_habit.title,
            frequency=db_habit.frequency,
        )
    except IntegrityError:
        db.rollback()
        raise HTTPException(status_code=400, detail="Habit with this title already exists for this user.")
    except Exception as e:
        db.rollback()
        logger.error(f"Error creating habit: {e}")
        raise HTTPException(status_code=500, detail="Internal server error")


@router.get("/habits/{user_id}", response_model=List[HabitResponse])
def get_habits(user_id: int, db: Annotated[Session, Depends(get_db)]):
    try:
        service = HabitService(db)
        habits = service.get_habits_by_user(user_id)
        streak_service = StreakService(db)

        result = []
        for habit in habits:
            habit_id = cast(int, habit.id)
            result.append(HabitResponse(
                id=habit_id,
                user_id=habit.user_id,
                title=habit.title,
                frequency=habit.frequency,
                current_streak=streak_service.calculate_current_streak(habit_id),
                longest_streak=streak_service.calculate_longest_streak(habit_id),
                completion_percentage=round(streak_service.get_completion_percentage(habit_id), 1),
            ))
        return result
    except Exception as e:
        logger.error(f"Error fetching habits: {e}")
        raise HTTPException(status_code=500, detail="Internal server error")


@router.put("/habits/{habit_id}", response_model=HabitResponse)
def update_habit(habit_id: int, habit: HabitUpdate, db: Annotated[Session, Depends(get_db)]):
    try:
        service = HabitService(db)
        updated_habit = service.update_habit(habit_id, **habit.dict(exclude_unset=True))
        if not updated_habit:
            raise HTTPException(status_code=404, detail="Habit not found")
        return HabitResponse(
            id=updated_habit.id,
            user_id=updated_habit.user_id,
            title=updated_habit.title,
            frequency=updated_habit.frequency,
        )
    except HTTPException:
        raise
    except IntegrityError:
        db.rollback()
        raise HTTPException(status_code=400, detail="Habit with this title already exists for this user.")
    except Exception as e:
        db.rollback()
        logger.error(f"Error updating habit: {e}")
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
        logger.error(f"Error deleting habit: {e}")
        raise HTTPException(status_code=500, detail="Internal server error")


@router.post("/habits/{habit_id}/log", response_model=LogResponse)
def mark_done(habit_id: int, log: LogCreate, db: Annotated[Session, Depends(get_db)]):
    """
    Mark a habit as done for a given date.
    Validates:
      - Habit exists (404)
      - Returns proper JSON response (200)
      - Handles DB errors gracefully (400)
    """
    try:
        # 1. Validate habit exists
        habit = db.query(Habit).filter(Habit.id == habit_id).first()
        if not habit:
            raise HTTPException(status_code=404, detail="Habit not found")

        # 2. Check for duplicate log on same date
        existing_log = db.query(DailyLog).filter(
            DailyLog.habit_id == habit_id,
            DailyLog.log_date == log.log_date
        ).first()

        if existing_log:
            # Already logged today — return success with existing log
            return LogResponse(
                id=existing_log.id,
                habit_id=existing_log.habit_id,
                status=existing_log.status,
                date=existing_log.log_date,
                notes=existing_log.notes,
            )

        # 3. Create the log entry
        service = HabitService(db)
        db_log = service.mark_habit_done(habit_id, log.log_date, log.notes)

        return LogResponse(
            id=db_log.id,
            habit_id=db_log.habit_id,
            status=db_log.status,
            date=db_log.log_date,
            notes=db_log.notes,
        )

    except HTTPException:
        raise
    except IntegrityError:
        db.rollback()
        logger.error(f"IntegrityError logging habit {habit_id}")
        raise HTTPException(status_code=400, detail="Log entry could not be saved. Possible duplicate.")
    except Exception as e:
        db.rollback()
        logger.error(f"Error logging habit {habit_id}: {e}")
        raise HTTPException(status_code=500, detail=f"Failed to log progress: {str(e)}")


@router.get("/habits/{habit_id}/logs", response_model=List[LogEntryResponse])
def get_logs(habit_id: int, db: Annotated[Session, Depends(get_db)]):
    try:
        # Validate habit exists
        habit = db.query(Habit).filter(Habit.id == habit_id).first()
        if not habit:
            raise HTTPException(status_code=404, detail="Habit not found")

        service = HabitService(db)
        logs = service.get_logs_for_habit(habit_id)

        return [
            LogEntryResponse(
                id=log.id,
                habit_id=log.habit_id,
                log_date=log.log_date,
                status=log.status,
                notes=log.notes,
            )
            for log in logs
        ]
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error fetching logs for habit {habit_id}: {e}")
        raise HTTPException(status_code=500, detail="Internal server error")