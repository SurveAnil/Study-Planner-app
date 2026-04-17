from sqlalchemy import Column, Integer, String, DateTime, ForeignKey, UniqueConstraint
from sqlalchemy.sql import func
from database.db_connection import Base


class UserBadge(Base):
    """
    Stores earned achievement badges per user.

    Each badge type can only be earned ONCE per user (unique constraint).
    Badge types:
        - first_habit     : First habit marked complete
        - streak_7        : 7-day streak on any habit
        - streak_30       : 30-day streak on any habit
        - perfect_week    : 100% completion in a 7-day window
    """
    __tablename__ = "user_badges"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False, index=True)
    badge_type = Column(String, nullable=False)          # e.g. "streak_7"
    badge_name = Column(String, nullable=False)          # e.g. "7-Day Streak"
    badge_emoji = Column(String, nullable=False)         # e.g. "🔥"
    description = Column(String, nullable=False)
    earned_at = Column(DateTime(timezone=True), server_default=func.now())

    __table_args__ = (
        UniqueConstraint("user_id", "badge_type", name="uq_user_badge_type"),
    )
