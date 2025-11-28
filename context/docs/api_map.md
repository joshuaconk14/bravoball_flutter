# this is the backend schema and implementation from the backend for session completion and rewarding treats. currently, we only return the completed session to the user when we do a POST to the backend. we need to grant treats to users when we complete a session. the backend will perform the treat calculation. here is what we currently have in the backend for completed sessions:

# API
# Completed Sessions Endpoints
@router.post("/api/sessions/completed/", response_model=CompletedSessionSchema)
def create_completed_session(session: CompletedSessionCreate,
                           current_user: User = Depends(get_current_user),
                           db: Session = Depends(get_db)):
    try:
        # Parse the ISO8601 date string to datetime
        session_date = datetime.fromisoformat(session.date.replace('Z', '+00:00'))

        # Check for duplicate sessions (same user, same date, same drill count)
        existing_session = db.query(CompletedSession).filter(
            CompletedSession.user_id == current_user.id,
            CompletedSession.date == session_date,
            CompletedSession.total_drills == session.total_drills,
            CompletedSession.total_completed_drills == session.total_completed_drills,
            CompletedSession.session_type == session.session_type
        ).first()
        
        if existing_session:
            # Return existing session instead of creating duplicate
            return existing_session
        
        # Create the completed session
        db_session = CompletedSession(
            user_id=current_user.id,
            date=session_date,
            total_completed_drills=session.total_completed_drills,
            total_drills=session.total_drills,
            session_type=session.session_type,
            drills=[{
                "drill": {
                    "uuid": drill.drill.uuid,  # Use UUID as primary identifier
                    "title": drill.drill.title,
                    "skill": drill.drill.skill,
                    "subSkills": drill.drill.subSkills,
                    "sets": drill.drill.sets,
                    "reps": drill.drill.reps,
                    "duration": drill.drill.duration,
                    "description": drill.drill.description,
                    "instructions": drill.drill.instructions,
                    "tips": drill.drill.tips,
                    "equipment": drill.drill.equipment,
                    "trainingStyle": drill.drill.trainingStyle,
                    "difficulty": drill.drill.difficulty,
                    "videoUrl": drill.drill.videoUrl
                },
                "setsDone": drill.setsDone,
                "totalSets": drill.totalSets,
                "totalReps": drill.totalReps,
                "totalDuration": drill.totalDuration,
                "isCompleted": drill.isCompleted
            } for drill in session.drills] if session.drills else None,
            duration_minutes=session.duration_minutes
        )
        db.add(db_session)
        db.commit()
        db.refresh(db_session)
        
        # ✅ NEW: Update streak in progress history when session is completed
        progress_history = db.query(ProgressHistory).filter(
            ProgressHistory.user_id == current_user.id
        ).first()
        
        session_date_only = session_date.date()
        
        # Get the previous session (before this one)
        previous_session = db.query(CompletedSession).filter(
            CompletedSession.user_id == current_user.id,
            CompletedSession.id != db_session.id
        ).order_by(CompletedSession.date.desc()).first()
        
        if progress_history:
            # Update streak using helper function
            update_streak_on_session_completion(
                progress_history=progress_history,
                session_date=session_date_only,
                previous_session=previous_session
            )
            db.commit()
        
        return db_session
        
    except Exception as e:
        db.rollback()
        raise HTTPException(
            status_code=500,
            detail=f"Failed to create completed session: {str(e)}"
        )

# MODEL SCHEMA
# Completed Session Schemas
class CompletedSessionBase(BaseModel):
    date: datetime
    session_type: str = 'drill_training'  # 'drill_training', 'mental_training', etc.
    
    # ✅ UPDATED: Optional drill-specific fields
    total_completed_drills: Optional[int] = None
    total_drills: Optional[int] = None
    drills: Optional[List[dict]] = None  # List of drill data (null for mental training)
    
    # ✅ NEW: Mental training specific fields
    duration_minutes: Optional[int] = None  # For mental training sessions
    mental_training_session_id: Optional[int] = None

class DrillData(BaseModel):
    uuid: str  # Use UUID instead of id
    title: str
    skill: str
    subSkills: List[str]
    sets: Optional[int] = None
    reps: Optional[int] = None
    duration: Optional[int] = None
    description: str
    instructions: List[str]
    tips: List[str]
    equipment: List[str]
    trainingStyle: str
    difficulty: str
    videoUrl: str

class CompletedDrillData(BaseModel):
    drill: DrillData
    setsDone: int
    totalSets: int
    totalReps: int
    totalDuration: int
    isCompleted: bool

# ✅ NEW: Drill training session creation
class CompletedDrillSessionCreate(BaseModel):
    date: str  # ISO8601 formatted string
    session_type: str = 'drill_training'
    drills: List[CompletedDrillData]
    total_completed_drills: int
    total_drills: int

    model_config = ConfigDict(from_attributes=True)

# ✅ NEW: Mental training session creation
class CompletedMentalTrainingSessionCreate(BaseModel):
    date: str  # ISO8601 formatted string
    session_type: str = 'mental_training'
    duration_minutes: int
    mental_training_session_id: int

    model_config = ConfigDict(from_attributes=True)

# ✅ UPDATED: Generic completed session creation (backwards compatible)
class CompletedSessionCreate(BaseModel):
    date: str  # ISO8601 formatted string    
    # Drill session fields (optional)
    drills: Optional[List[CompletedDrillData]] = None
    total_completed_drills: Optional[int] = None
    total_drills: Optional[int] = None
    session_type: Optional[str] = None

    
    # Mental training session fields (optional)
    duration_minutes: Optional[int] = None
    mental_training_session_id: Optional[int] = None

    model_config = ConfigDict(from_attributes=True)

class CompletedSession(CompletedSessionBase):
    id: int
    user_id: int

    model_config = ConfigDict(from_attributes=True)
