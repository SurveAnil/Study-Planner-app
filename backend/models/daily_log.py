from sqlalchemy import Column, Integer, String, Date, ForeignKey
from sqlalchemy.orm import relationship
from database.db_connection import Base

class DailyLog(Base):
    __tablename__ = "daily_logs"

    id = Column(Integer, primary_key=True, index=True)
    habit_id = Column(Integer, ForeignKey("habits.id"))
    log_date = Column(Date)
    status = Column(String)  # 'completed' or 'missed'
    notes = Column(String, nullable=True)

    habit = relationship("Habit", back_populates="logs")