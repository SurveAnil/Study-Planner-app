"""
Notification Routes

Persistent in-app notification inbox endpoints.

GET  /api/users/{uid}/notifications           — list notifications (newest first)
GET  /api/users/{uid}/notifications/unread-count — unread badge count for bell
PATCH /api/users/{uid}/notifications/{id}/read — mark one as read
PATCH /api/users/{uid}/notifications/read-all  — mark all as read
"""

import logging
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from database.db_connection import get_db
from models.user import User
from services.notification_db_service import NotificationDbService
from pydantic import BaseModel
from datetime import datetime
from typing import List, Optional

logger = logging.getLogger(__name__)
router = APIRouter()


# ── Schemas ───────────────────────────────────────────────────────

class NotificationResponse(BaseModel):
    id: int
    notification_type: str
    title: str
    message: str
    emoji: str
    is_read: bool
    created_at: Optional[datetime] = None

    class Config:
        from_attributes = True


class NotificationListResponse(BaseModel):
    notifications: List[NotificationResponse]
    total: int
    unread_count: int


class UnreadCountResponse(BaseModel):
    unread_count: int


# ── Routes ───────────────────────────────────────────────────────

@router.get("/users/{firebase_uid}/notifications", response_model=NotificationListResponse)
def get_notifications(firebase_uid: str, db: Session = Depends(get_db)):
    """List all notifications for the user, newest first."""
    try:
        user = db.query(User).filter(User.firebase_uid == firebase_uid).first()
        if not user:
            raise HTTPException(status_code=404, detail="User not found")

        svc = NotificationDbService(db)
        notifs = svc.get_for_user(user.id)
        unread = svc.get_unread_count(user.id)

        return NotificationListResponse(
            notifications=[NotificationResponse.model_validate(n) for n in notifs],
            total=len(notifs),
            unread_count=unread,
        )
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error fetching notifications for {firebase_uid}: {e}")
        raise HTTPException(status_code=500, detail="Failed to fetch notifications")


@router.get("/users/{firebase_uid}/notifications/unread-count", response_model=UnreadCountResponse)
def get_unread_count(firebase_uid: str, db: Session = Depends(get_db)):
    """Returns just the unread notification count (for bell badge)."""
    try:
        user = db.query(User).filter(User.firebase_uid == firebase_uid).first()
        if not user:
            raise HTTPException(status_code=404, detail="User not found")
        svc = NotificationDbService(db)
        return UnreadCountResponse(unread_count=svc.get_unread_count(user.id))
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error fetching unread count: {e}")
        raise HTTPException(status_code=500, detail="Failed to fetch count")


@router.patch("/users/{firebase_uid}/notifications/{notification_id}/read")
def mark_notification_read(
    firebase_uid: str,
    notification_id: int,
    db: Session = Depends(get_db),
):
    """Mark a single notification as read."""
    try:
        user = db.query(User).filter(User.firebase_uid == firebase_uid).first()
        if not user:
            raise HTTPException(status_code=404, detail="User not found")
        svc = NotificationDbService(db)
        found = svc.mark_read(notification_id, user.id)
        if not found:
            raise HTTPException(status_code=404, detail="Notification not found")
        return {"detail": "Marked as read"}
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error marking notification read: {e}")
        raise HTTPException(status_code=500, detail="Failed to update notification")


@router.patch("/users/{firebase_uid}/notifications/read-all")
def mark_all_read(firebase_uid: str, db: Session = Depends(get_db)):
    """Mark all notifications as read."""
    try:
        user = db.query(User).filter(User.firebase_uid == firebase_uid).first()
        if not user:
            raise HTTPException(status_code=404, detail="User not found")
        svc = NotificationDbService(db)
        count = svc.mark_all_read(user.id)
        return {"detail": f"Marked {count} notifications as read"}
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error marking all read: {e}")
        raise HTTPException(status_code=500, detail="Failed to update notifications")
