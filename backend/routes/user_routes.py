from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from database.db_connection import get_db
from models.user import User
from pydantic import BaseModel

router = APIRouter()

class UserCreate(BaseModel):
    name: str
    email: str
    firebase_uid: str

@router.post("/users/")
def create_user(user: UserCreate, db: Session = Depends(get_db)):
    db_user = User(name=user.name, email=user.email, firebase_uid=user.firebase_uid)
    db.add(db_user)
    db.commit()
    db.refresh(db_user)
    return db_user

@router.get("/users/{firebase_uid}")
def get_user(firebase_uid: str, db: Session = Depends(get_db)):
    return db.query(User).filter(User.firebase_uid == firebase_uid).first()