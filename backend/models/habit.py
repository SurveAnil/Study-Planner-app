from sqlalchemy import Column, Integer, String, Date, ForeignKey, UniqueConstraint
from sqlalchemy.orm import relationship
from database.db_connection import Base
from models.user import User

class Habit(Base):
    __tablename__ = "habits"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"))
    title = Column(String, index=True)
    frequency = Column(String)  # 'daily' or 'weekly'

    user = relationship("User")
    logs = relationship("DailyLog", back_populates="habit")

    __table_args__ = (UniqueConstraint('user_id', 'title', name='_user_title_uc'),)