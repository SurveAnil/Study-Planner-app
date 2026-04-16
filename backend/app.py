from fastapi import FastAPI
from database.db_connection import engine, Base
from routes import habit_routes, user_routes

Base.metadata.create_all(bind=engine)

app = FastAPI()

app.include_router(habit_routes.router, prefix="/api", tags=["habits"])
app.include_router(user_routes.router, prefix="/api", tags=["users"])

@app.get("/")
def read_root():
    return {"message": "Daily Habit Tracker API"}

if __name__ == "__main__":
    import uvicorn
    uvicorn.run("app:app", host="127.0.0.1", port=8000, reload=True)