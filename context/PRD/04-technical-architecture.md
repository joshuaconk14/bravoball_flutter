# BravoBall - Technical Architecture (AI Summary)

## 🎯 System Overview
Cross-platform soccer training app with AI-powered session generation.

**Tech Stack**: Flutter (Frontend) + FastAPI (Backend) + PostgreSQL (Database)

## 🏗️ Architecture
```
Frontend (Flutter)     │  Backend (FastAPI)
├── iOS/Android Apps   │  ├── Authentication Service
├── State Management   │  ├── Session Generation Engine
└── Video Playback     │  ├── Drill Management API
                       │  └── Progress Tracking API
Database & Infrastructure
├── PostgreSQL (Primary)
├── Redis (Caching)
└── AWS S3 (Video CDN)
```

## 📱 Frontend (Flutter)

### State Management
- **Provider Pattern**: Primary state management
- **AppStateService**: Core application state with:
  - State Machines: `SessionState`, `LoadingState`, `SyncState`
  - SyncCoordinator: Prevents race conditions
  - Operation Guards: Prevents concurrent operations
  - Debounced Operations: Smart batching (search, sync, preferences)

### Key Components
- **UserManagerService**: Authentication and user data
- **SessionGeneratorViewModel**: Session generation logic
- **ProgressService**: Progress tracking and analytics

### Project Structure
```
lib/
├── features/          # Feature-based modules
├── services/          # Business logic services
├── models/            # Data models
├── widgets/           # Reusable UI components
└── views/             # Main view components
```

## 🔧 Backend (FastAPI)

### Core Services
- **Authentication**: JWT with refresh tokens
- **Session Generation**: AI-powered drill selection
- **Drill Management**: CRUD operations for drill library
- **Progress Tracking**: User performance analytics

### Key API Endpoints
```python
# Authentication
POST /login/                    # User login
POST /refresh/                  # Token refresh

# Drill Management
GET /drills/                    # Get drills with filters
GET /api/drills/search         # Search drills

# Session Management
GET /api/sessions/ordered_drills/    # Get current session
PUT /api/sessions/ordered_drills/    # Update session
POST /api/sessions/completed/        # Mark session complete

# Progress Tracking
GET /api/progress_history/      # Get user progress
```

### Database Models
```python
class User(Base):
    id, email, hashed_password, created_at

class Drill(Base):
    id, uuid, title, description, category, duration, difficulty
    equipment, instructions, tips, video_url

class Session(Base):
    id, user_id, created_at, drills, preferences, completed

class Progress(Base):
    id, user_id, session_id, drill_id, completed_at, performance
```

## 🗄️ Database Architecture

### PostgreSQL Schema
```sql
-- Core tables
users (id, email, hashed_password, created_at)
drills (id, uuid, title, category, duration, difficulty, equipment)
sessions (id, user_id, preferences, drills, completed_at)
progress_history (id, user_id, session_id, drill_id, performance_data)
```

### Caching Strategy
- **CloudFront**: Video CDN
- **Local Storage**: Offline drill storage, session state

## 🔐 Security

### Authentication Flow
```python
# JWT Token Structure
{
    "sub": "user@example.com",
    "user_id": 123,
    "exp": 1640995200,
    "type": "access"
}
```

### Data Protection
- **Encryption**: HTTPS/TLS, database encryption
- **Password Security**: bcrypt hashing
- **API Security**: Rate limiting, input validation, JWT tokens

## 📊 Performance

### Frontend Optimization
- **State Coordination**: Prevents race conditions
- **Debounced Operations**: Reduces API calls
- **Caching**: Aggressive caching of static content

### Backend Optimization
- **Database**: Query optimization and indexing
- **Caching**: CloudFront for video delivery
- **API Response**: <200ms for most endpoints

## 🚀 Development Workflow

### Architecture Patterns
- **MVVM Pattern**: Model-View-ViewModel separation
- **Repository Pattern**: Data layer abstraction
- **Provider Pattern**: Reactive state management
- **Clean Architecture**: Dependency inversion

### Key Dependencies
```yaml
# Flutter
dependencies:
  provider: ^6.0.5          # State management
  http: ^1.1.0              # HTTP client
  video_player: ^2.8.1      # Video playback

# Python
fastapi, sqlalchemy, pydantic, jwt, bcrypt
```

## 🎯 Current Focus Areas
- **Race Condition Prevention**: Implemented via SyncCoordinator
- **State Management**: State machines for predictable transitions
- **Performance**: Optimized for 10,000+ concurrent users
- **Scalability**: Designed for microservices migration

---
*Essential technical reference for BravoBall development* 