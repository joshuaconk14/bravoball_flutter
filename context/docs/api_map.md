# this is the backend schema and implementation from the backend for user store products, APIs and routers for updating/fetching store data for user
# use this doc as reference when implementing store into this frontend code of app

# db table
class UserStoreItems(Base):
    __tablename__ = "user_store_items"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), unique=True, nullable=False)
    treats = Column(Integer, default=0, nullable=False)
    streak_freezes = Column(Integer, default=0, nullable=False)
    streak_revivers = Column(Integer, default=0, nullable=False)
    created_at = Column(DateTime, server_default=func.now())
    updated_at = Column(DateTime, server_default=func.now(), onupdate=func.now())

    # Relationship
    user = relationship("User", back_populates="store_items")

# store item models when making requests
class UserStoreItemsBase(BaseModel):
    treats: int = 0
    streak_freezes: int = 0
    streak_revivers: int = 0

    model_config = ConfigDict(from_attributes=True)


class UserStoreItemsResponse(UserStoreItemsBase):
    id: int
    user_id: int
    created_at: datetime
    updated_at: datetime

    model_config = ConfigDict(from_attributes=True)


class UserStoreItemsUpdate(BaseModel):
    treats: Optional[int] = None
    streak_freezes: Optional[int] = None
    streak_revivers: Optional[int] = None

    model_config = ConfigDict(from_attributes=True)

# APIs
@router.get("/api/store/items", response_model=UserStoreItemsResponse)
async def get_user_store_items(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    Get the current user's store items inventory
    """
    try:
        # Get or create store items for user
        store_items = db.query(UserStoreItems).filter(
            UserStoreItems.user_id == current_user.id
        ).first()
        
        if not store_items:
            # Create default store items if they don't exist
            store_items = UserStoreItems(
                user_id=current_user.id,
                treats=0,
                streak_freezes=0,
                streak_revivers=0
            )
            db.add(store_items)
            db.commit()
            db.refresh(store_items)
        
        return store_items
    
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to get store items: {str(e)}"
        )


@router.put("/api/store/items", response_model=UserStoreItemsResponse)
async def update_user_store_items(
    items_update: UserStoreItemsUpdate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    Update the user's store items inventory
    This should be called after RevenueCat confirms a successful purchase
    
    Only updates the fields that are provided (non-None values)
    """
    try:
        # Get or create store items for user
        store_items = db.query(UserStoreItems).filter(
            UserStoreItems.user_id == current_user.id
        ).first()
        
        if not store_items:
            # Create new store items record
            store_items = UserStoreItems(
                user_id=current_user.id,
                treats=items_update.treats if items_update.treats is not None else 0,
                streak_freezes=items_update.streak_freezes if items_update.streak_freezes is not None else 0,
                streak_revivers=items_update.streak_revivers if items_update.streak_revivers is not None else 0
            )
            db.add(store_items)
        else:
            # Update only the fields that are provided
            if items_update.treats is not None:
                store_items.treats = items_update.treats
            if items_update.streak_freezes is not None:
                store_items.streak_freezes = items_update.streak_freezes
            if items_update.streak_revivers is not None:
                store_items.streak_revivers = items_update.streak_revivers
        
        db.commit()
        db.refresh(store_items)
        
        return store_items
    
    except Exception as e:
        db.rollback()
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to update store items: {str(e)}"
        )


@router.post("/api/store/items/increment", response_model=UserStoreItemsResponse)
async def increment_store_items(
    items_update: UserStoreItemsUpdate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    Increment store items by the specified amounts
    Use this endpoint after a successful purchase from RevenueCat
    
    Example: If user has 5 treats and you send treats=3, they'll have 8 treats
    """
    try:
        # Get or create store items for user
        store_items = db.query(UserStoreItems).filter(
            UserStoreItems.user_id == current_user.id
        ).first()
        
        if not store_items:
            # Create new store items record with the increment values
            store_items = UserStoreItems(
                user_id=current_user.id,
                treats=items_update.treats if items_update.treats is not None else 0,
                streak_freezes=items_update.streak_freezes if items_update.streak_freezes is not None else 0,
                streak_revivers=items_update.streak_revivers if items_update.streak_revivers is not None else 0
            )
            db.add(store_items)
        else:
            # Increment the values
            if items_update.treats is not None:
                store_items.treats += items_update.treats
            if items_update.streak_freezes is not None:
                store_items.streak_freezes += items_update.streak_freezes
            if items_update.streak_revivers is not None:
                store_items.streak_revivers += items_update.streak_revivers
        
        db.commit()
        db.refresh(store_items)
        
        return store_items
    
    except Exception as e:
        db.rollback()
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to increment store items: {str(e)}"
        )


@router.post("/api/store/items/decrement", response_model=UserStoreItemsResponse)
async def decrement_store_items(
    items_update: UserStoreItemsUpdate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    Decrement store items by the specified amounts
    Use this endpoint when a user uses/consumes an item
    
    Example: If user has 5 treats and you send treats=1, they'll have 4 treats
    Note: Values cannot go below 0
    """
    try:
        # Get store items for user
        store_items = db.query(UserStoreItems).filter(
            UserStoreItems.user_id == current_user.id
        ).first()
        
        if not store_items:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="User has no store items to decrement"
            )
        
        # Decrement the values (but don't go below 0)
        if items_update.treats is not None:
            store_items.treats = max(0, store_items.treats - items_update.treats)
        if items_update.streak_freezes is not None:
            store_items.streak_freezes = max(0, store_items.streak_freezes - items_update.streak_freezes)
        if items_update.streak_revivers is not None:
            store_items.streak_revivers = max(0, store_items.streak_revivers - items_update.streak_revivers)
        
        db.commit()
        db.refresh(store_items)
        
        return store_items
    
    except HTTPException:
        raise
    except Exception as e:
        db.rollback()
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to decrement store items: {str(e)}"
        )