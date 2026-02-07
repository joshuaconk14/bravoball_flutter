# World Leaderboard Backend API Specification

## Overview
This document specifies the backend API endpoint required for the World Leaderboard feature. The endpoint should return the top 50 users globally ranked by points, along with the current authenticated user's rank.

## Endpoint

### GET `/api/leaderboard/world`

**Authentication:** Required (Bearer token)

**Description:** Returns the top 50 users globally ranked by points, plus the current user's rank information.

---

## Request

### Headers
```
Authorization: Bearer <access_token>
Content-Type: application/json
Accept: application/json
```

### Query Parameters
None required

---

## Response

### Success Response (200 OK)

**Response Body Structure:**
```json
{
  "top_50": [
    {
      "id": 1,
      "username": "player1",
      "points": 5000,
      "sessions_completed": 50,
      "rank": 1,
      "avatar_path": "assets/avatar-icons/SoccerBoy1.png",
      "avatar_background_color": "#FF5733"
    },
    {
      "id": 2,
      "username": "player2",
      "points": 4800,
      "sessions_completed": 48,
      "rank": 2,
      "avatar_path": "assets/avatar-icons/SoccerGirl1.png",
      "avatar_background_color": "#33FF57"
    }
    // ... up to 50 entries, sorted by points descending
  ],
  "user_rank": {
    "id": 123,
    "username": "current_user",
    "points": 500,
    "sessions_completed": 5,
    "rank": 1234,
    "avatar_path": "assets/avatar-icons/SoccerBoy2.png",
    "avatar_background_color": "#3357FF"
  }
}
```

### Response Fields

#### `top_50` (Array of LeaderboardEntry)
- **Type:** Array
- **Required:** Yes
- **Description:** Array of up to 50 leaderboard entries, sorted by points descending (highest first)
- **Note:** If there are fewer than 50 users total, return all users

#### `user_rank` (LeaderboardEntry)
- **Type:** Object
- **Required:** Yes
- **Description:** The current authenticated user's leaderboard entry with their global rank
- **Note:** This should always be included, even if the user is in the top 50

#### LeaderboardEntry Object Fields

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `id` | Integer | Yes | User ID |
| `username` | String | Yes | User's username |
| `points` | Integer | Yes | Total points accumulated by user |
| `sessions_completed` | Integer | Yes | Total number of completed training sessions |
| `rank` | Integer | Yes | Global rank (1 = highest points) |
| `avatar_path` | String (nullable) | No | Path to user's avatar image |
| `avatar_background_color` | String (nullable) | No | Hex color code for avatar background (e.g., "#FF5733") |

---

## Ranking Logic

### Ranking Criteria
1. **Primary:** Points (descending - highest first)
2. **Secondary:** Sessions completed (descending - if points are equal)
3. **Tertiary:** User ID (ascending - for consistent ordering)

### Rank Calculation
- Rank 1 = User with highest points
- Rank 2 = User with second highest points
- etc.
- If multiple users have the same points, they should have the same rank (e.g., if 3 users have 1000 points and it's the highest, they're all rank 1)

---

## Error Responses

### 401 Unauthorized
```json
{
  "detail": "Not authenticated"
}
```
**Cause:** Missing or invalid authentication token

### 500 Internal Server Error
```json
{
  "detail": "Internal server error"
}
```
**Cause:** Server-side error occurred

---

## Implementation Notes

### Performance Considerations
1. **Caching:** Consider caching the top 50 results for 1-5 minutes to reduce database load
2. **Indexing:** Ensure `points` and `sessions_completed` columns are indexed for fast queries
3. **Pagination:** Currently not required, but consider for future scalability

### Database Query Example (Pseudocode)
```sql
-- Get top 50 users
SELECT 
  id,
  username,
  points,
  sessions_completed,
  avatar_path,
  avatar_background_color,
  RANK() OVER (ORDER BY points DESC, sessions_completed DESC) as rank
FROM users
ORDER BY points DESC, sessions_completed DESC
LIMIT 50;

-- Get current user's rank
SELECT 
  id,
  username,
  points,
  sessions_completed,
  avatar_path,
  avatar_background_color,
  (SELECT COUNT(*) + 1 
   FROM users u2 
   WHERE u2.points > u1.points 
   OR (u2.points = u1.points AND u2.sessions_completed > u1.sessions_completed)
  ) as rank
FROM users u1
WHERE id = :current_user_id;
```

### Edge Cases to Handle
1. **User not found:** Return 404 or handle gracefully
2. **Less than 50 users:** Return all users in `top_50`
3. **User in top 50:** Still include them in `user_rank` (frontend will handle highlighting)
4. **Tied ranks:** Multiple users can have the same rank if points are equal

---

## Testing Checklist

- [ ] Returns top 50 users correctly sorted
- [ ] Includes current user's rank even if in top 50
- [ ] Handles users with same points correctly
- [ ] Returns correct rank for user not in top 50
- [ ] Handles empty database gracefully
- [ ] Handles less than 50 users gracefully
- [ ] Requires authentication
- [ ] Returns proper error for invalid token
- [ ] Includes avatar data when available
- [ ] Handles null avatar fields correctly

---

## Example Implementation (Python/FastAPI)

```python
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from sqlalchemy import func, desc
from typing import List

router = APIRouter()

@router.get("/api/leaderboard/world")
async def get_world_leaderboard(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    # Get top 50 users
    top_50_query = (
        db.query(User)
        .order_by(desc(User.points), desc(User.sessions_completed))
        .limit(50)
        .all()
    )
    
    # Calculate ranks for top 50
    top_50_entries = []
    for idx, user in enumerate(top_50_query, start=1):
        top_50_entries.append({
            "id": user.id,
            "username": user.username,
            "points": user.points,
            "sessions_completed": user.sessions_completed,
            "rank": idx,
            "avatar_path": user.avatar_path,
            "avatar_background_color": user.avatar_background_color,
        })
    
    # Get current user's rank
    users_above = (
        db.query(func.count(User.id))
        .filter(
            (User.points > current_user.points) |
            ((User.points == current_user.points) & 
             (User.sessions_completed > current_user.sessions_completed))
        )
        .scalar()
    )
    user_rank = users_above + 1
    
    user_rank_entry = {
        "id": current_user.id,
        "username": current_user.username,
        "points": current_user.points,
        "sessions_completed": current_user.sessions_completed,
        "rank": user_rank,
        "avatar_path": current_user.avatar_path,
        "avatar_background_color": current_user.avatar_background_color,
    }
    
    return {
        "top_50": top_50_entries,
        "user_rank": user_rank_entry,
    }
```

---

## Frontend Integration

The Flutter app expects this exact response structure. Once implemented, the frontend will:
1. Display top 50 users in a scrollable list
2. Highlight the current user if they're in the top 50
3. Show a prominent "Your Rank" card at the bottom if user is not in top 50
4. Handle loading and error states appropriately

---

## Version History

- **v1.0** (2026-02-06): Initial specification
