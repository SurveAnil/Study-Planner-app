from sqlalchemy import Column, Integer, String, Boolean, DateTime, ForeignKey
from sqlalchemy.sql import func
from database.db_connection import Base


class UserNotification(Base):
    """
    Persistent in-app notification history per user.

    Types:
        badge_earned  — user unlocked an achievement
        streak_risk   — a habit streak is in danger
        reminder      — general habit reminder
    """
    __tablename__ = "user_notifications"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False, index=True)
    notification_type = Column(String, nullable=False)   # "badge_earned" | "streak_risk" | "reminder"
    title = Column(String, nullable=False)
    message = Column(String, nullable=False)
    emoji = Column(String, default="🔔")
    is_read = Column(Boolean, default=False, nullable=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
