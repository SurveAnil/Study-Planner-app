import logging
from contextlib import asynccontextmanager
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from database.db_connection import engine, Base
from models import user, habit, daily_log  # Must import before create_all
from models import badge                   # Badge model — creates user_badges table
from routes import habit_routes, user_routes, progress_routes, badge_routes

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)


@asynccontextmanager
async def lifespan(app: FastAPI):
    # Startup: create DB tables
    try:
        logger.info("Connecting to database and creating tables...")
        Base.metadata.create_all(bind=engine)
        logger.info("Database tables created/verified successfully.")
    except Exception as e:
        logger.error(f"STARTUP ERROR: Could not connect to the database: {e}")
        logger.error("The app will start, but DB operations will fail until the DB is reachable.")
    yield
    logger.info("Application shutting down.")


app = FastAPI(
    title="Habit Tracker API",
    description="Backend API for the Daily Habit Tracker application",
    version="3.0.0",
    lifespan=lifespan,
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(habit_routes.router, prefix="/api", tags=["habits"])
app.include_router(user_routes.router, prefix="/api", tags=["users"])
app.include_router(progress_routes.router, prefix="/api", tags=["progress"])
app.include_router(badge_routes.router, prefix="/api", tags=["badges"])


@app.get("/")
def read_root():
    return {"message": "Daily Habit Tracker API is running", "version": "3.0.0"}


if __name__ == "__main__":
    import uvicorn
    uvicorn.run("app:app", host="127.0.0.1", port=8000, reload=True)