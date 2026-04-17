"""
Badge Routes

Endpoints:
    GET  /api/users/{firebase_uid}/badges         — list all earned badges
    POST /api/users/{firebase_uid}/badges/check   — trigger badge evaluation + award
"""

import logging
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from database.db_connection import get_db
from models.user import User
from services.badge_service import BadgeService
from pydantic import BaseModel
from datetime import datetime
from typing import List, Optional

logger = logging.getLogger(__name__)
router = APIRouter()


# ── Response Schemas ─────────────────────────────────────────────

class BadgeResponse(BaseModel):
    id: int
    badge_type: str
    badge_name: str
    badge_emoji: str
    description: str
    earned_at: Optional[datetime] = None

    class Config:
        from_attributes = True


class BadgeListResponse(BaseModel):
    badges: List[BadgeResponse]
    total: int


class CheckBadgesResponse(BaseModel):
    newly_earned: List[BadgeResponse]
    total_badges: int
    message: str


# ── Routes ───────────────────────────────────────────────────────

@router.get("/users/{firebase_uid}/badges", response_model=BadgeListResponse)
def get_user_badges(firebase_uid: str, db: Session = Depends(get_db)):
    """Return all achievement badges earned by the user."""
    try:
        user = db.query(User).filter(User.firebase_uid == firebase_uid).first()
        if not user:
            raise HTTPException(status_code=404, detail="User not found")

        service = BadgeService(db)
        badges = service.get_user_badges(user.id)

        return BadgeListResponse(
            badges=[BadgeResponse.model_validate(b) for b in badges],
            total=len(badges),
        )

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error fetching badges for {firebase_uid}: {e}")
        raise HTTPException(status_code=500, detail="Failed to fetch badges")


@router.post("/users/{firebase_uid}/badges/check", response_model=CheckBadgesResponse)
def check_and_award_badges(firebase_uid: str, db: Session = Depends(get_db)):
    """
    Evaluate all badge conditions and award any newly earned badges.
    Call this after a habit is marked complete.
    """
    try:
        user = db.query(User).filter(User.firebase_uid == firebase_uid).first()
        if not user:
            raise HTTPException(status_code=404, detail="User not found")

        service = BadgeService(db)
        newly_earned = service.check_and_award_badges(user.id)
        all_badges = service.get_user_badges(user.id)

        message = (
            f"🏆 Earned {len(newly_earned)} new badge(s)!"
            if newly_earned
            else "No new badges yet. Keep going!"
        )

        return CheckBadgesResponse(
            newly_earned=[BadgeResponse.model_validate(b) for b in newly_earned],
            total_badges=len(all_badges),
            message=message,
        )

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error checking badges for {firebase_uid}: {e}")
        raise HTTPException(status_code=500, detail="Failed to check badges")
