# Backend Specification: Friend Detail Endpoint

## Overview
This document specifies the backend endpoint needed to display detailed friend information including stats (points, sessions completed, rank).

---

## Endpoint: Get Friend Details

### Endpoint
**GET** `/api/friends/{user_id}`

### Authentication
Required

### Request Parameters
- **Path Parameter**: `user_id` (integer) - The user ID of the friend

### Response Format

**Success Response (200 OK)**:
```json
{
  "id": 123,
  "friendship_id": 456,
  "username": "friend1",
  "email": "friend@example.com",
  "first_name": "John",
  "last_name": "Doe",
  "avatar_path": "assets/avatars/avatar_1.png",
  "avatar_background_color": "#FF5733",
  "points": 1250,
  "sessions_completed": 45,
  "rank": 3,
  "current_streak": 5,
  "highest_streak": 12,
  "favorite_drill": "Cone Weaving",
  "last_active": "2026-02-02T10:30:00Z",
  "total_practice_minutes": 2700
}
```

**Error Responses**:
- `404`: Friend not found or not a friend
- `401`: Not authenticated
- `403`: User is not your friend (if you want to restrict access)

---

## Field Specifications

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `id` | integer | Yes | User ID of the friend |
| `friendship_id` | integer | Yes | The `friendships.id` primary key |
| `username` | string | Yes | Friend's username |
| `email` | string | Yes | Friend's email |
| `first_name` | string \| null | No | Friend's first name |
| `last_name` | string \| null | No | Friend's last name |
| `avatar_path` | string \| null | No | Path to avatar image |
| `avatar_background_color` | string \| null | No | Hex color code |
| `points` | integer | Yes | Total points earned |
| `sessions_completed` | integer | Yes | Total sessions completed |
| `rank` | integer | Yes | Rank among friends (or world rank if not in friends leaderboard) |
| `current_streak` | integer | Yes | Current consecutive days with completed sessions |
| `highest_streak` | integer | Yes | Highest streak ever achieved |
| `favorite_drill` | string \| null | No | Most practiced drill name |
| `last_active` | string (ISO 8601) \| null | No | Timestamp of last completed session |
| `total_practice_minutes` | integer | Yes | Total minutes practiced across all sessions |

---

## Backend Logic

### Step 1: Verify Friendship
- Check that the requested `user_id` is actually a friend of the current user
- Query: Find an active (`status = 'accepted'`) friendship between current user and requested user

### Step 2: Get Friend User Data
- Fetch user information (username, email, name, avatar, etc.)

### Step 3: Get Friend Stats
- Calculate or fetch:
  - **Points**: Total points from all completed sessions
  - **Sessions Completed**: Count of completed sessions
  - **Rank**: Rank among friends (or world rank if not in friends leaderboard)
  - **Current Streak**: Current consecutive days with completed sessions
  - **Highest Streak**: Highest streak ever achieved
  - **Favorite Drill**: Most practiced drill (drill with highest completion count)
  - **Last Active**: Timestamp of most recent completed session
  - **Total Practice Minutes**: Sum of all session durations

### Step 4: Build Response
- Combine user data with stats
- Include `friendship_id` for potential future operations
- Format `last_active` as ISO 8601 timestamp string

---

## Example Implementation (Python/FastAPI)

```python
from sqlalchemy.orm import Session
from fastapi import APIRouter, Depends, HTTPException

router = APIRouter()

@router.get("/api/friends/{user_id}")
async def get_friend_detail(
    user_id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Get detailed information about a friend including stats"""
    
    # Step 1: Verify friendship exists and is active
    friendship = db.query(Friendship).filter(
        ((Friendship.requester_user_id == current_user.id) &
         (Friendship.addressee_user_id == user_id)) |
        ((Friendship.requester_user_id == user_id) &
         (Friendship.addressee_user_id == current_user.id)),
        Friendship.status == 'accepted'
    ).first()
    
    if not friendship:
        raise HTTPException(
            status_code=404,
            detail="Friend not found or not a friend"
        )
    
    # Step 2: Get friend user data
    friend_user = db.query(User).filter(User.id == user_id).first()
    if not friend_user:
        raise HTTPException(
            status_code=404,
            detail="User not found"
        )
    
    # Step 3: Get friend stats
    # Calculate total points (sum of all session points)
    total_points = db.query(func.sum(Session.points)).filter(
        Session.user_id == user_id,
        Session.completed == True
    ).scalar() or 0
    
    # Count completed sessions
    sessions_completed = db.query(func.count(Session.id)).filter(
        Session.user_id == user_id,
        Session.completed == True
    ).scalar() or 0
    
    # Get current streak and highest streak
    # (Assuming you have a progress_history table or calculate from sessions)
    progress_history = db.query(ProgressHistory).filter(
        ProgressHistory.user_id == user_id
    ).first()
    
    current_streak = progress_history.current_streak if progress_history else 0
    highest_streak = progress_history.highest_streak if progress_history else 0
    
    # Get favorite drill (most practiced drill)
    favorite_drill_result = db.query(
        Drill.name,
        func.count(SessionDrill.id).label('count')
    ).join(SessionDrill).join(Session).filter(
        Session.user_id == user_id,
        Session.completed == True
    ).group_by(Drill.name).order_by(desc('count')).first()
    
    favorite_drill = favorite_drill_result[0] if favorite_drill_result else None
    
    # Get last active timestamp (most recent completed session)
    last_session = db.query(Session).filter(
        Session.user_id == user_id,
        Session.completed == True
    ).order_by(desc(Session.completed_at)).first()
    
    last_active = last_session.completed_at if last_session else None
    
    # Calculate total practice minutes (sum of all session durations)
    total_practice_minutes = db.query(func.sum(Session.duration_minutes)).filter(
        Session.user_id == user_id,
        Session.completed == True
    ).scalar() or 0
    
    # Get rank among friends
    # First, get all friends' points
    friends_ids = db.query(
        case(
            (Friendship.requester_user_id == current_user.id, Friendship.addressee_user_id),
            else_=Friendship.requester_user_id
        )
    ).filter(
        ((Friendship.requester_user_id == current_user.id) |
         (Friendship.addressee_user_id == current_user.id)),
        Friendship.status == 'accepted'
    ).all()
    
    friends_ids.append(current_user.id)  # Include current user
    
    # Get all users' points for ranking
    user_points = db.query(
        User.id,
        func.sum(Session.points).label('total_points')
    ).join(Session).filter(
        User.id.in_(friends_ids),
        Session.completed == True
    ).group_by(User.id).order_by(desc('total_points')).all()
    
    # Find rank
    rank = 1
    for idx, (uid, points) in enumerate(user_points, start=1):
        if uid == user_id:
            rank = idx
            break
    
    # If not found in friends leaderboard, use world rank
    if rank == 1 and user_id not in [uid for uid, _ in user_points]:
        # Get world rank (simplified - you may have a better way)
        world_rank = db.query(func.count(User.id)).filter(
            User.id.in_(
                db.query(Session.user_id).filter(
                    Session.completed == True
                ).group_by(Session.user_id).having(
                    func.sum(Session.points) > total_points
                )
            )
        ).scalar() or 0
        rank = world_rank + 1
    
    # Step 4: Build response
    return {
        "id": friend_user.id,
        "friendship_id": friendship.id,
        "username": friend_user.username,
        "email": friend_user.email,
        "first_name": friend_user.first_name,
        "last_name": friend_user.last_name,
        "avatar_path": friend_user.avatar_path,
        "avatar_background_color": friend_user.avatar_background_color,
        "points": int(total_points),
        "sessions_completed": int(sessions_completed),
        "rank": rank,
        "current_streak": int(current_streak),
        "highest_streak": int(highest_streak),
        "favorite_drill": favorite_drill,
        "last_active": last_active.isoformat() if last_active else None,
        "total_practice_minutes": int(total_practice_minutes),
    }
```

---

## Alternative: Reuse Existing Leaderboard Logic

If you already have leaderboard calculation logic, you can reuse it:

```python
@router.get("/api/friends/{user_id}")
async def get_friend_detail(
    user_id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Get detailed information about a friend including stats"""
    
    # Verify friendship
    friendship = db.query(Friendship).filter(
        ((Friendship.requester_user_id == current_user.id) &
         (Friendship.addressee_user_id == user_id)) |
        ((Friendship.requester_user_id == user_id) &
         (Friendship.addressee_user_id == current_user.id)),
        Friendship.status == 'accepted'
    ).first()
    
    if not friendship:
        raise HTTPException(status_code=404, detail="Friend not found")
    
    # Get friend user
    friend_user = db.query(User).filter(User.id == user_id).first()
    if not friend_user:
        raise HTTPException(status_code=404, detail="User not found")
    
    # Get stats using existing leaderboard calculation
    # (Assuming you have a function that calculates leaderboard entries)
    leaderboard_entry = calculate_leaderboard_entry(user_id, db)
    
    # Get additional stats
    progress_history = db.query(ProgressHistory).filter(
        ProgressHistory.user_id == user_id
    ).first()
    
    current_streak = progress_history.current_streak if progress_history else 0
    highest_streak = progress_history.highest_streak if progress_history else 0
    
    # Get favorite drill
    favorite_drill_result = db.query(
        Drill.name,
        func.count(SessionDrill.id).label('count')
    ).join(SessionDrill).join(Session).filter(
        Session.user_id == user_id,
        Session.completed == True
    ).group_by(Drill.name).order_by(desc('count')).first()
    
    favorite_drill = favorite_drill_result[0] if favorite_drill_result else None
    
    # Get last active
    last_session = db.query(Session).filter(
        Session.user_id == user_id,
        Session.completed == True
    ).order_by(desc(Session.completed_at)).first()
    
    last_active = last_session.completed_at if last_session else None
    
    # Get total practice minutes
    total_practice_minutes = db.query(func.sum(Session.duration_minutes)).filter(
        Session.user_id == user_id,
        Session.completed == True
    ).scalar() or 0
    
    return {
        "id": friend_user.id,
        "friendship_id": friendship.id,
        "username": friend_user.username,
        "email": friend_user.email,
        "first_name": friend_user.first_name,
        "last_name": friend_user.last_name,
        "avatar_path": friend_user.avatar_path,
        "avatar_background_color": friend_user.avatar_background_color,
        "points": leaderboard_entry.points,
        "sessions_completed": leaderboard_entry.sessions_completed,
        "rank": leaderboard_entry.rank,  # Rank among friends
        "current_streak": int(current_streak),
        "highest_streak": int(highest_streak),
        "favorite_drill": favorite_drill,
        "last_active": last_active.isoformat() if last_active else None,
        "total_practice_minutes": int(total_practice_minutes),
    }
```

---

## Ranking Logic

### Friends Leaderboard Rank
- Calculate rank among all friends of the current user
- Include current user in ranking
- Rank by total points (descending)
- If tied, you may want to use sessions completed as tiebreaker

### World Rank (Fallback)
- If friend is not in the friends leaderboard (shouldn't happen, but good to have)
- Calculate rank globally among all users
- Use same ranking logic as world leaderboard

---

## Testing Checklist

- [ ] Returns friend details for valid friend
- [ ] Returns 404 for non-friend user
- [ ] Returns 404 for non-existent user
- [ ] Returns 401 for unauthenticated requests
- [ ] Points calculation is correct
- [ ] Sessions completed count is correct
- [ ] Rank calculation is correct (among friends)
- [ ] `friendship_id` is included in response
- [ ] All user fields (username, email, avatar, etc.) are included
- [ ] Current streak is correct
- [ ] Highest streak is correct
- [ ] Favorite drill is correct (or null if no drills)
- [ ] Last active timestamp is correct (or null if no sessions)
- [ ] Total practice minutes is correct
- [ ] Handles friends with 0 points/sessions correctly
- [ ] Handles edge cases (only one friend, no sessions, etc.)
- [ ] `last_active` is formatted as ISO 8601 string

---

## Performance Considerations

1. **Caching**: Consider caching leaderboard calculations if they're expensive
2. **Database Indexes**: Ensure indexes on:
   - `friendships.requester_user_id`
   - `friendships.addressee_user_id`
   - `friendships.status`
   - `sessions.user_id`
   - `sessions.completed`
3. **Query Optimization**: Use efficient queries to calculate stats
4. **Ranking**: If ranking calculation is expensive, consider pre-calculating and storing ranks

---

## Summary

### Required Changes
1. ✅ Create `GET /api/friends/{user_id}` endpoint
2. ✅ Verify friendship exists and is active
3. ✅ Return friend user data + stats (points, sessions, rank, streaks, activity)
4. ✅ Include `friendship_id` in response

### Response Fields
- **User info**: `id`, `username`, `email`, `first_name`, `last_name`, `avatar_path`, `avatar_background_color`
- **Friendship**: `friendship_id`
- **Basic stats**: `points`, `sessions_completed`, `rank`
- **Streak stats**: `current_streak`, `highest_streak`
- **Activity stats**: `favorite_drill`, `last_active`, `total_practice_minutes`

---

**Last Updated**: February 2026
