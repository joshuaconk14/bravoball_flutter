# Offline Feature Implementation Plan

## Overview
This document outlines the comprehensive implementation plan for adding offline functionality to BravoBall using SQLite. This feature will enable users to create, save, and manage drills and training data without requiring an active internet connection.

## Business Context
Currently, users must be online to create custom drills, save drill collections, and sync their training data. This limitation creates friction in the user experience and prevents users from engaging with the app in areas with poor connectivity (gyms, outdoor fields, etc.).

## Implementation Phases

### Phase 1: Foundation Setup ✅
**Status:** Ready to begin

**Objectives:**
- Set up SQLite infrastructure
- Create database service architecture
- Establish migration framework

**Tasks:**
1. Add `sqflite` and `path` dependencies to `pubspec.yaml`
2. Create `OfflineDrillDatabase` service class
3. Initialize database on app startup
4. Set up database schema versioning system
5. Create database migration framework

**Deliverables:**
- Database service with initialization
- Schema versioning system
- Migration handlers

**Estimated Time:** 2-3 hours

---

### Phase 2: Core Data Types Identification ✅
**Status:** Analysis complete

**Data Types Requiring Offline Storage:**

1. **Custom Drills**
   - User-created drills with all metadata
   - Priority: HIGH (primary user-generated content)

2. **Drill Groups/Collections**
   - User-created drill collections
   - Priority: HIGH (core feature)

3. **Liked Drills**
   - User-favorited drills
   - Priority: MEDIUM (engagement feature)

4. **Session Data**
   - Current training session progress
   - Priority: MEDIUM (user experience)

5. **User Preferences**
   - Skill preferences, equipment, training styles
   - Priority: LOW (can be re-fetched)

**Deliverables:**
- Prioritized list of data types
- Storage requirements for each type

---

### Phase 3: Database Schema Design ✅
**Status:** Designed

**Schema Overview:**

#### Table 1: `offline_drills`
**Purpose:** Store custom drills created offline

**Fields:**
- `id` (TEXT PRIMARY KEY) - Server ID or local ID
- `local_id` (TEXT UNIQUE) - Local UUID for offline tracking
- `title` (TEXT) - Drill title
- `description` (TEXT) - Drill description
- `skill` (TEXT) - Primary skill category
- `sub_skills` (TEXT) - JSON array of sub-skills
- `sets` (INTEGER) - Number of sets
- `reps` (INTEGER) - Number of reps
- `duration` (INTEGER) - Duration in minutes
- `instructions` (TEXT) - JSON array of instructions
- `tips` (TEXT) - JSON array of tips
- `equipment` (TEXT) - JSON array of equipment
- `training_style` (TEXT) - Training style
- `difficulty` (TEXT) - Difficulty level
- `video_url` (TEXT) - Video URL
- `is_synced` (INTEGER) - Sync status (0/1)
- `sync_error` (TEXT) - Error message if sync failed
- `created_at` (INTEGER) - Creation timestamp
- `updated_at` (INTEGER) - Last update timestamp
- `server_id` (TEXT) - Server-assigned ID after sync

**Indexes:**
- `idx_is_synced` on `is_synced`
- `idx_local_id` on `local_id`

#### Table 2: `offline_drill_groups`
**Purpose:** Store drill collections/groups

**Fields:**
- `id` (TEXT PRIMARY KEY)
- `local_id` (TEXT UNIQUE)
- `name` (TEXT)
- `description` (TEXT)
- `drill_ids` (TEXT) - JSON array of drill IDs
- `is_synced` (INTEGER)
- `sync_error` (TEXT)
- `created_at` (INTEGER)
- `updated_at` (INTEGER)
- `server_id` (TEXT)

#### Table 3: `offline_liked_drills`
**Purpose:** Track favorited drills

**Fields:**
- `id` (TEXT PRIMARY KEY)
- `drill_id` (TEXT)
- `is_synced` (INTEGER)
- `created_at` (INTEGER)

#### Table 4: `offline_sessions`
**Purpose:** Store session progress

**Fields:**
- `id` (TEXT PRIMARY KEY)
- `local_id` (TEXT UNIQUE)
- `drill_ids` (TEXT) - JSON array
- `progress_data` (TEXT) - JSON object
- `state` (TEXT) - Session state
- `is_synced` (INTEGER)
- `sync_error` (TEXT)
- `created_at` (INTEGER)
- `updated_at` (INTEGER)
- `server_id` (TEXT)

#### Table 5: `offline_preferences`
**Purpose:** Store user preferences

**Fields:**
- `id` (TEXT PRIMARY KEY)
- `preference_key` (TEXT)
- `preference_value` (TEXT) - JSON
- `is_synced` (INTEGER)
- `updated_at` (INTEGER)

**Deliverables:**
- Complete database schema
- Index definitions
- Migration scripts

**Estimated Time:** 3-4 hours

---

### Phase 4: Database Service Layer Implementation
**Status:** Pending

**Objectives:**
- Create CRUD operations for each data type
- Implement sync status tracking
- Add error handling

**Tasks:**

**4.1: Core Database Service**
- Create `OfflineDrillDatabase` class
- Implement `saveDrillOffline()` method
- Implement `getUnsyncedDrills()` method
- Implement `markAsSynced()` method
- Implement `markSyncFailed()` method
- Add data mapping utilities

**4.2: Drill Groups Service**
- Create `OfflineDrillGroupDatabase` class
- Implement group CRUD operations
- Link groups to drills

**4.3: Liked Drills Service**
- Create `OfflineLikedDrillsDatabase` class
- Implement like/unlike operations

**4.4: Session Service**
- Create `OfflineSessionDatabase` class
- Implement session save/load operations

**4.5: Preferences Service**
- Create `OfflinePreferencesDatabase` class
- Implement preference save/load operations

**Deliverables:**
- Complete database service layer
- Unit tests for each service
- Error handling implementation

**Estimated Time:** 8-10 hours

---

### Phase 5: Sync Service Layer Implementation
**Status:** Pending

**Objectives:**
- Create automatic sync mechanism
- Handle sync conflicts
- Implement retry logic

**Tasks:**

**5.1: Core Sync Service**
- Create `OfflineDrillSyncService` class
- Implement `syncUnsyncedDrills()` method
- Add connectivity checking
- Implement retry logic with exponential backoff
- Handle sync conflicts (server ID vs local ID)

**5.2: Sync for Other Data Types**
- Create sync services for drill groups
- Create sync services for liked drills
- Create sync services for sessions
- Create sync services for preferences

**5.3: Sync Orchestration**
- Create `OfflineSyncOrchestrator` to coordinate all syncs
- Implement priority-based syncing
- Add sync progress tracking

**Deliverables:**
- Complete sync service layer
- Conflict resolution logic
- Retry mechanisms

**Estimated Time:** 6-8 hours

---

### Phase 6: Integration with Existing Services
**Status:** Pending

**Objectives:**
- Modify existing services to use offline storage
- Maintain backward compatibility
- Ensure seamless user experience

**Tasks:**

**6.1: CustomDrillService Integration**
- Modify `createCustomDrill()` to save offline on failure
- Add offline-first approach
- Return drill immediately (optimistic UI)
- Sync in background

**6.2: DrillGroupService Integration**
- Modify group creation to save offline
- Handle group-drill relationships offline

**6.3: AppStateService Integration**
- Load data from SQLite on startup
- Merge server data with local data
- Handle conflicts gracefully

**6.4: PreferencesService Integration**
- Save preferences to SQLite immediately
- Sync to server when online

**Deliverables:**
- Updated service integrations
- Backward compatibility maintained
- Seamless user experience

**Estimated Time:** 6-8 hours

---

### Phase 7: Sync Logic Implementation
**Status:** Pending

**Objectives:**
- Implement automatic syncing
- Add manual sync triggers
- Handle sync errors gracefully

**Tasks:**

**7.1: Connectivity Listener**
- Add listener to `ConnectivityService`
- Trigger sync when connectivity returns
- Show sync progress to user

**7.2: Sync Triggers**
- On app startup (if online)
- When connectivity returns
- After creating/updating data (if online)
- Manual retry button

**7.3: Sync Strategy**
- Sort by creation date (oldest first)
- Send to server one by one
- Update sync status on success
- Keep failed records for retry
- Show sync progress

**7.4: Conflict Resolution**
- Handle server ID assignment
- Resolve conflicts (server wins)
- Update local records with server data

**Deliverables:**
- Automatic sync mechanism
- Manual sync triggers
- Conflict resolution logic

**Estimated Time:** 4-5 hours

---

### Phase 8: User Experience Enhancements
**Status:** Pending

**Objectives:**
- Provide clear feedback about offline state
- Show sync status
- Handle errors gracefully

**Tasks:**

**8.1: Visual Indicators**
- "Saved offline" message when drill saved offline
- Sync indicator when syncing
- "X unsynced" badge on relevant screens
- "Syncing..." message when connectivity returns

**8.2: Error Handling**
- Network errors → save offline, retry later
- Server errors → save offline, retry later
- Validation errors → show to user, don't save
- Sync failures → keep in SQLite, show error

**8.3: User Feedback**
- Toast messages for save status
- Progress indicators for sync
- Error messages with retry options

**Deliverables:**
- Updated UI components
- Error handling UX
- User feedback mechanisms

**Estimated Time:** 4-5 hours

---

### Phase 9: Testing and Quality Assurance
**Status:** Pending

**Objectives:**
- Ensure reliability
- Test edge cases
- Verify data integrity

**Tasks:**

**9.1: Unit Tests**
- Test database operations
- Test sync logic
- Test conflict resolution

**9.2: Integration Tests**
- Test offline creation flow
- Test sync flow
- Test app restart scenarios

**9.3: Edge Cases**
- Multiple unsynced items
- Server down scenarios
- Network interruption during sync
- Database corruption recovery

**Deliverables:**
- Comprehensive test suite
- Test documentation
- Bug fixes

**Estimated Time:** 6-8 hours

---

### Phase 10: Performance Optimization
**Status:** Pending

**Objectives:**
- Optimize database queries
- Improve sync performance
- Reduce battery impact

**Tasks:**

**10.1: Database Optimization**
- Add missing indexes
- Optimize query patterns
- Implement query caching

**10.2: Sync Optimization**
- Batch sync operations
- Limit batch size
- Implement sync throttling

**10.3: Resource Management**
- Lazy load data
- Clean up old records
- Optimize memory usage

**Deliverables:**
- Optimized database queries
- Improved sync performance
- Reduced resource usage

**Estimated Time:** 3-4 hours

---

### Phase 11: Migration and Maintenance
**Status:** Pending

**Objectives:**
- Handle schema changes
- Maintain backward compatibility
- Clean up old data

**Tasks:**

**11.1: Migration Support**
- Version database schema
- Handle schema changes gracefully
- Migrate old data to new format

**11.2: Maintenance**
- Clean up old synced records (optional)
- Archive old sessions
- Optimize database periodically
- Handle database corruption

**Deliverables:**
- Migration scripts
- Maintenance utilities
- Documentation

**Estimated Time:** 2-3 hours

---

## Implementation Timeline

**Total Estimated Time:** 44-58 hours

**Recommended Approach:**
- **Sprint 1 (Week 1):** Phases 1-3 (Foundation & Design)
- **Sprint 2 (Week 2):** Phases 4-5 (Database & Sync Services)
- **Sprint 3 (Week 3):** Phases 6-7 (Integration & Sync Logic)
- **Sprint 4 (Week 4):** Phases 8-9 (UX & Testing)
- **Sprint 5 (Week 5):** Phases 10-11 (Optimization & Maintenance)

## Success Metrics

**Technical Metrics:**
- 100% of offline-created drills successfully sync when online
- < 1% sync failure rate
- < 100ms average database query time
- Zero data loss incidents

**User Metrics:**
- Increased drill creation rate (especially in offline scenarios)
- Reduced user frustration from failed saves
- Improved app engagement in low-connectivity areas
- Higher user retention

## Risks and Mitigation

**Risk 1: Data Conflicts**
- **Mitigation:** Implement conflict resolution strategy (server wins)

**Risk 2: Sync Failures**
- **Mitigation:** Retry logic with exponential backoff, error tracking

**Risk 3: Database Corruption**
- **Mitigation:** Regular backups, corruption detection, recovery mechanisms

**Risk 4: Performance Impact**
- **Mitigation:** Optimize queries, implement caching, lazy loading

## Dependencies

- `sqflite` package
- `path` package
- `connectivity_plus` (already implemented)
- Existing `CustomDrillService`
- Existing `ApiService`

## Next Steps

1. Review and approve this implementation plan
2. Set up development environment
3. Begin Phase 1: Foundation Setup
4. Regular progress reviews after each phase

---

**Document Version:** 1.0  
**Last Updated:** January 2026  
**Owner:** Engineering Team
