# Daily Habit Tracker System

A mobile application to help users build and maintain daily habits with streak tracking and progress visualization.

## Features

- Google Authentication via Firebase
- Create and manage daily/weekly habits
- Track daily progress with streak calculation
- Progress visualization and statistics
- OOP-based Python backend with SQL database

## Tech Stack

- **Frontend**: Flutter (Dart)
- **Backend**: Python FastAPI (OOP)
- **Database**: SQLite
- **Authentication**: Firebase Auth

## Setup Instructions

### Backend Setup

1. Navigate to the backend directory:
   ```
   cd backend
   ```

2. Install dependencies:
   ```
   pip install -r requirements.txt
   ```

3. Run the server:
   ```
   uvicorn app:app --reload
   ```

The API will be available at `http://localhost:8000`

### Frontend Setup

1. Navigate to the Flutter project:
   ```
   cd habit_tracker_app
   ```

2. Install dependencies:
   ```
   flutter pub get
   ```

3. Configure Firebase:
   - Create a Firebase project
   - Enable Google Sign-In
   - Add your app's configuration to `lib/main.dart` or use Firebase CLI

4. Run the app:
   ```
   flutter run
   ```

## Project Structure

### Backend
```
backend/
├── app.py                 # Main FastAPI app
├── config.py              # Configuration
├── models/                # SQLAlchemy models
├── services/              # Business logic services
├── routes/                # API routes
└── database/              # Database connection
```

### Frontend
```
habit_tracker_app/lib/
├── screens/               # UI screens
├── models/                # Data models
├── services/              # API and auth services
└── widgets/               # Reusable widgets
```

## API Endpoints

- `GET /api/habits/{user_id}` - Get user's habits
- `POST /api/habits/` - Create new habit
- `POST /api/habits/{habit_id}/log` - Mark habit as done
- `GET /api/users/{firebase_uid}` - Get user by Firebase UID
- `POST /api/users/` - Create new user

## Database Schema

- **Users**: id, name, email, firebase_uid
- **Habits**: id, user_id, title, description, type, start_date
- **DailyLogs**: id, habit_id, log_date, status, notes

Streaks are calculated dynamically in the backend services.