# this is the backend schema and implementation from the backend for progress history, mainly looking at active freeze date implementation
# use this doc as reference when implementing into this frontend code of app

# backend api endpoint
@router.post("/api/store/use-streak-freeze")
async def use_streak_freeze(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    Use a streak freeze to protect today's streak
    
    This endpoint:
    - Checks if the user has streak freezes available
    - Checks if the user has an active streak (current_streak > 0)
    - Sets active_freeze_date to TODAY
    - Decrements streak_freezes by 1
    - Prevents the streak from breaking if user doesn't train today
    
    Returns:
        Updated progress history and store items
    """
    try:
        # Get user's store items
        store_items = db.query(UserStoreItems).filter(
            UserStoreItems.user_id == current_user.id
        ).first()
        
        if not store_items or store_items.streak_freezes <= 0:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="You don't have any streak freezes available"
            )
        
        # Get user's progress history
        progress_history = db.query(ProgressHistory).filter(
            ProgressHistory.user_id == current_user.id
        ).first()
        
        if not progress_history:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Progress history not found"
            )
        
        # Check if user has an active streak
        if progress_history.current_streak <= 0:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="You need an active streak to use a streak freeze"
            )
        
        # Check if there's already an active freeze
        today = datetime.now().date()
        if progress_history.active_freeze_date:
            if progress_history.active_freeze_date == today:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail="You already have a streak freeze active for today"
                )
            # Clear expired freeze dates (older than today)
            elif progress_history.active_freeze_date < today:
                progress_history.active_freeze_date = None
        
        # Activate freeze for today
        progress_history.active_freeze_date = today
        
        # Decrement streak freezes
        store_items.streak_freezes -= 1
        
        db.commit()
        db.refresh(progress_history)
        db.refresh(store_items)
        
        return {
            "success": True,
            "message": f"Streak freeze activated for today! Your {progress_history.current_streak}-day streak is protected.",
            "freeze_date": today.isoformat(),
            "progress_history": {
                "current_streak": progress_history.current_streak,
                "active_freeze_date": progress_history.active_freeze_date.isoformat() if progress_history.active_freeze_date else None
            },
            "store_items": {
                "streak_freezes": store_items.streak_freezes
            }
        }
    
    except HTTPException:
        raise
    except Exception as e:
        db.rollback()
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to use streak freeze: {str(e)}"
        )


# progress history table schema
lass ProgressHistoryBase(BaseModel):
    current_streak: int = 0
    previous_streak: int = 0  # Add previous_streak field
    highest_streak: int = 0
    completed_sessions_count: int = 0
    # ✅ NEW: Streak freeze date
    active_freeze_date: Optional[date] = None
    # ✅ NEW: Enhanced progress metrics
    favorite_drill: str = ''
    drills_per_session: float = 0.0
    minutes_per_session: float = 0.0
    total_time_all_sessions: int = 0
    dribbling_drills_completed: int = 0
    first_touch_drills_completed: int = 0
    passing_drills_completed: int = 0
    shooting_drills_completed: int = 0
    defending_drills_completed: int = 0
    goalkeeping_drills_completed: int = 0
    fitness_drills_completed: int = 0  # ✅ NEW: Add fitness drills completed
    # ✅ NEW: Additional progress metrics
    most_improved_skill: str = ''
    unique_drills_completed: int = 0
    beginner_drills_completed: int = 0
    intermediate_drills_completed: int = 0
    advanced_drills_completed: int = 0
    # ✅ NEW: Mental training metrics
    mental_training_sessions: int = 0
    total_mental_training_minutes: int = 0

    model_config = ConfigDict(from_attributes=True)
