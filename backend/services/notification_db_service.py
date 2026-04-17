"""
Notification DB Service

Handles creating, reading, and managing persistent user notifications.
All other services inject this to write notifications — keeps logic centralized.
"""

import logging
from sqlalchemy.orm import Session
from models.notification import UserNotification
from typing import List

logger = logging.getLogger(__name__)


class NotificationDbService:
    """
    Centralized service for writing and reading notification history.

    Usage:
        svc = NotificationDbService(db)
        svc.create(user_id, "badge_earned", "🔥 Badge Earned!", "...")
        svc.get_for_user(user_id)
    """

    def __init__(self, db: Session):
        self.db = db

    def create(
        self,
        user_id: int,
        notification_type: str,
        title: str,
        message: str,
        emoji: str = "🔔",
    ) -> UserNotification:
        """Insert a new notification for the user."""
        notif = UserNotification(
            user_id=user_id,
            notification_type=notification_type,
            title=title,
            message=message,
            emoji=emoji,
            is_read=False,
        )
        self.db.add(notif)
        self.db.commit()
        self.db.refresh(notif)
        logger.info(f"Created notification '{notification_type}' for user {user_id}")
        return notif

    def get_for_user(self, user_id: int, limit: int = 50) -> List[UserNotification]:
        """Return the most recent notifications for a user."""
        return (
            self.db.query(UserNotification)
            .filter(UserNotification.user_id == user_id)
            .order_by(UserNotification.created_at.desc())
            .limit(limit)
            .all()
        )

    def get_unread_count(self, user_id: int) -> int:
        """Return number of unread notifications."""
        return (
            self.db.query(UserNotification)
            .filter(
                UserNotification.user_id == user_id,
                UserNotification.is_read == False,
            )
            .count()
        )

    def mark_read(self, notification_id: int, user_id: int) -> bool:
        """Mark a single notification as read. Returns True if found."""
        notif = (
            self.db.query(UserNotification)
            .filter(
                UserNotification.id == notification_id,
                UserNotification.user_id == user_id,
            )
            .first()
        )
        if not notif:
            return False
        notif.is_read = True
        self.db.commit()
        return True

    def mark_all_read(self, user_id: int) -> int:
        """Mark all unread notifications as read. Returns count updated."""
        count = (
            self.db.query(UserNotification)
            .filter(
                UserNotification.user_id == user_id,
                UserNotification.is_read == False,
            )
            .update({"is_read": True})
        )
        self.db.commit()
        return count
