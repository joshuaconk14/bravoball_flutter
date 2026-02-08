# Offline Database Testing Guide

## Overview
This guide explains how to test the offline custom drill database implementation to ensure it works correctly before proceeding with additional tables.

## Testing Approaches

### 1. Automated Unit Tests ✅
**Location:** `unit_test/services/offline_custom_drill_database_test.dart`

**What it tests:**
- Database initialization
- Saving drills offline (with and without server ID)
- Retrieving unsynced drills
- Marking drills as synced
- Counting unsynced drills
- Deleting drills
- Error handling

**How to run:**
```bash
flutter test unit_test/services/offline_custom_drill_database_test.dart
```

**Expected output:**
- All tests should pass ✅
- No errors or warnings

---

### 2. Manual Testing via Debug Page ✅
**Location:** `lib/features/debug/offline_database_test_page.dart`

**How to access:**
1. Run app in debug mode
2. Navigate to Profile tab
3. Tap "Debug Settings" (only visible in debug mode)
4. Scroll to "Developer Actions" section
5. Tap "Test Offline Database"

**What you can test:**
- ✅ Create test drills
- ✅ View unsynced drills list
- ✅ Mark drills as synced
- ✅ Delete drills
- ✅ Refresh list
- ✅ See unsynced count

**Test Scenarios:**

**Scenario 1: Create and View**
1. Tap "Create Test Drill"
2. Verify drill appears in list
3. Check unsynced count increases

**Scenario 2: Mark as Synced**
1. Create a drill
2. Tap checkmark icon on drill
3. Verify drill disappears from list
4. Check unsynced count decreases

**Scenario 3: Delete Drill**
1. Create a drill
2. Tap delete icon on drill
3. Verify drill disappears from list

**Scenario 4: Persistence**
1. Create several drills
2. Close app completely
3. Reopen app
4. Navigate back to test page
5. Verify drills are still there ✅

---

## What to Verify

### ✅ Database Initialization
- Database creates successfully
- No errors in console
- Database file exists on device

### ✅ Save Operations
- Can save drill without server ID (offline)
- Can save drill with server ID (synced)
- Drill data is correct (title, skill, sets, etc.)
- JSON arrays (subSkills, instructions, tips, equipment) are stored correctly

### ✅ Read Operations
- Can retrieve unsynced drills
- Can retrieve drill by local ID
- Unsynced count is accurate
- Data is correctly deserialized from JSON

### ✅ Update Operations
- Can mark drill as synced
- Server ID is updated correctly
- Sync status changes properly

### ✅ Delete Operations
- Can delete drill by local ID
- Drill is removed from database
- Count updates correctly

### ✅ Data Persistence
- Data survives app restart
- Data survives app close/reopen
- Database file persists on device

---

## Quick Test Checklist

Before proceeding to Phase 4, verify:

- [ ] Unit tests all pass
- [ ] Can create drill via test page
- [ ] Can view unsynced drills
- [ ] Can mark drill as synced
- [ ] Can delete drill
- [ ] Data persists after app restart
- [ ] No console errors
- [ ] Database file created on device

---

## Troubleshooting

### Issue: Tests fail with "database not found"
**Solution:** Make sure `sqflite_common_ffi` is added to dev_dependencies

### Issue: Can't access test page
**Solution:** 
- Ensure app is running in debug mode
- Check `AppConfig.shouldShowDebugMenu` returns true
- Verify Debug Settings is visible in Profile tab

### Issue: Database not initializing
**Solution:**
- Check console for error messages
- Verify `sqflite` and `path` packages are installed
- Run `flutter pub get`
- Check device storage permissions

### Issue: Data not persisting
**Solution:**
- Verify database is being saved to correct location
- Check device storage space
- Ensure app has storage permissions

---

## Next Steps After Testing

Once all tests pass:

1. ✅ **Phase 1 & 2 Complete** - Database foundation is solid
2. ✅ **Ready for Phase 4** - Can add other tables (drill groups, liked drills, etc.)
3. ✅ **Ready for Phase 5** - Can implement sync service

**Recommendation:** Complete testing before moving to Phase 4 to ensure foundation is solid.

---

## Test Results Template

**Date:** _______________
**Tester:** _______________

**Unit Tests:**
- [ ] All tests pass
- [ ] No errors

**Manual Tests:**
- [ ] Create drill works
- [ ] View drills works
- [ ] Mark as synced works
- [ ] Delete works
- [ ] Persistence works

**Issues Found:**
- _______________________
- _______________________

**Status:** ✅ Ready for Phase 4 / ⚠️ Needs fixes
