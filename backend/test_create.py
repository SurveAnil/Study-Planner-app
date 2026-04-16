import traceback
from database.db_connection import SessionLocal
from services.habit_service import HabitService

db = SessionLocal()
service = HabitService(db)
try:
    service.create_habit(1, 'Drink Water', 'daily')
    print("Success")
except Exception as e:
    traceback.print_exc()
