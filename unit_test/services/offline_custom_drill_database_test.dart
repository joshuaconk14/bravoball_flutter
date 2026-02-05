import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:bravoball_flutter/services/offline_custom_drill_database.dart';
import 'package:bravoball_flutter/models/drill_model.dart';

void main() {
  // Initialize sqflite for testing (uses in-memory database)
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('OfflineCustomDrillDatabase', () {
    late OfflineCustomDrillDatabase database;

    setUp(() async {
      // Get fresh instance for each test
      database = OfflineCustomDrillDatabase.instance;
      // Close any existing database
      await database.close();
      // Reinitialize for clean state
      await database.database;
      // Clear all data to ensure clean test state
      await database.clearAllDrills();
    });

    tearDown(() async {
      // Clean up after each test
      await database.clearAllDrills();
      await database.close();
    });

    test('database initializes successfully', () async {
      // Arrange & Act
      final db = await database.database;

      // Assert
      expect(db, isNotNull);
      expect(database.isInitialized, true);
    });

    test('saveDrillOffline saves drill without server ID', () async {
      // Arrange
      final drill = DrillModel(
        id: 'local-123',
        title: 'Test Drill',
        skill: 'dribbling',
        subSkills: ['ball_control'],
        sets: 3,
        reps: 10,
        duration: 5,
        description: 'Test description',
        instructions: ['Step 1', 'Step 2'],
        tips: ['Tip 1'],
        equipment: ['ball'],
        trainingStyle: 'medium',
        difficulty: 'beginner',
        videoUrl: '',
        isCustom: true,
      );

      // Act
      final localId = await database.saveDrillOffline(
        serverId: null,
        localId: 'local-123',
        drill: drill,
      );

      // Assert
      expect(localId, 'local-123');
      
      // Verify drill was saved
      final savedDrill = await database.getDrillByLocalId('local-123');
      expect(savedDrill, isNotNull);
      expect(savedDrill!['title'], 'Test Drill');
      expect(savedDrill['is_synced'], false);
    });

    test('saveDrillOffline saves drill with server ID marks as synced', () async {
      // Arrange
      final drill = DrillModel(
        id: 'server-456',
        title: 'Synced Drill',
        skill: 'passing',
        subSkills: ['short_pass'],
        sets: 5,
        reps: 15,
        duration: 10,
        description: 'Synced description',
        instructions: ['Step 1'],
        tips: [],
        equipment: ['ball', 'cones'],
        trainingStyle: 'high',
        difficulty: 'intermediate',
        videoUrl: 'https://example.com/video.mp4',
        isCustom: true,
      );

      // Act
      final localId = await database.saveDrillOffline(
        serverId: 'server-456',
        localId: 'local-456',
        drill: drill,
      );

      // Assert
      expect(localId, 'local-456');
      
      final savedDrill = await database.getDrillByLocalId('local-456');
      expect(savedDrill, isNotNull);
      expect(savedDrill!['is_synced'], true);
      expect(savedDrill['server_id'], 'server-456');
    });

    test('getUnsyncedDrills returns only unsynced drills', () async {
      // Arrange - Save multiple drills
      final syncedDrill = DrillModel(
        id: 'server-1',
        title: 'Synced',
        skill: 'shooting',
        subSkills: [],
        sets: 3,
        reps: 10,
        duration: 5,
        description: '',
        instructions: [],
        tips: [],
        equipment: [],
        trainingStyle: 'medium',
        difficulty: 'beginner',
        videoUrl: '',
        isCustom: true,
      );

      final unsyncedDrill1 = DrillModel(
        id: 'local-1',
        title: 'Unsynced 1',
        skill: 'dribbling',
        subSkills: [],
        sets: 3,
        reps: 10,
        duration: 5,
        description: '',
        instructions: [],
        tips: [],
        equipment: [],
        trainingStyle: 'medium',
        difficulty: 'beginner',
        videoUrl: '',
        isCustom: true,
      );

      final unsyncedDrill2 = DrillModel(
        id: 'local-2',
        title: 'Unsynced 2',
        skill: 'passing',
        subSkills: [],
        sets: 3,
        reps: 10,
        duration: 5,
        description: '',
        instructions: [],
        tips: [],
        equipment: [],
        trainingStyle: 'medium',
        difficulty: 'beginner',
        videoUrl: '',
        isCustom: true,
      );

      await database.saveDrillOffline(
        serverId: 'server-1',
        localId: 'local-synced',
        drill: syncedDrill,
      );
      await database.saveDrillOffline(
        serverId: null,
        localId: 'local-1',
        drill: unsyncedDrill1,
      );
      await database.saveDrillOffline(
        serverId: null,
        localId: 'local-2',
        drill: unsyncedDrill2,
      );

      // Act
      final unsynced = await database.getUnsyncedDrills();

      // Assert
      expect(unsynced.length, 2);
      expect(unsynced.any((d) => d['title'] == 'Unsynced 1'), true);
      expect(unsynced.any((d) => d['title'] == 'Unsynced 2'), true);
      expect(unsynced.any((d) => d['title'] == 'Synced'), false);
    });

    test('markAsSynced updates drill sync status', () async {
      // Arrange
      final drill = DrillModel(
        id: 'local-789',
        title: 'To Sync',
        skill: 'defending',
        subSkills: [],
        sets: 3,
        reps: 10,
        duration: 5,
        description: '',
        instructions: [],
        tips: [],
        equipment: [],
        trainingStyle: 'medium',
        difficulty: 'beginner',
        videoUrl: '',
        isCustom: true,
      );

      await database.saveDrillOffline(
        serverId: null,
        localId: 'local-789',
        drill: drill,
      );

      // Verify it's unsynced
      var savedDrill = await database.getDrillByLocalId('local-789');
      expect(savedDrill!['is_synced'], false);

      // Act
      await database.markAsSynced(
        localId: 'local-789',
        serverId: 'server-789',
      );

      // Assert
      savedDrill = await database.getDrillByLocalId('local-789');
      expect(savedDrill!['is_synced'], true);
      expect(savedDrill['server_id'], 'server-789');
    });

    test('getUnsyncedCount returns correct count', () async {
      // Arrange
      for (int i = 0; i < 3; i++) {
        final drill = DrillModel(
          id: 'local-$i',
          title: 'Drill $i',
          skill: 'dribbling',
          subSkills: [],
          sets: 3,
          reps: 10,
          duration: 5,
          description: '',
          instructions: [],
          tips: [],
          equipment: [],
          trainingStyle: 'medium',
          difficulty: 'beginner',
          videoUrl: '',
          isCustom: true,
        );

        await database.saveDrillOffline(
          serverId: null,
          localId: 'local-$i',
          drill: drill,
        );
      }

      // Act
      final count = await database.getUnsyncedCount();

      // Assert
      expect(count, 3);
    });

    test('deleteDrill removes drill from database', () async {
      // Arrange
      final drill = DrillModel(
        id: 'local-delete',
        title: 'To Delete',
        skill: 'shooting',
        subSkills: [],
        sets: 3,
        reps: 10,
        duration: 5,
        description: '',
        instructions: [],
        tips: [],
        equipment: [],
        trainingStyle: 'medium',
        difficulty: 'beginner',
        videoUrl: '',
        isCustom: true,
      );

      await database.saveDrillOffline(
        serverId: null,
        localId: 'local-delete',
        drill: drill,
      );

      // Verify it exists
      var savedDrill = await database.getDrillByLocalId('local-delete');
      expect(savedDrill, isNotNull);

      // Act
      await database.deleteDrill('local-delete');

      // Assert
      savedDrill = await database.getDrillByLocalId('local-delete');
      expect(savedDrill, isNull);
    });

    test('markSyncFailed records error message', () async {
      // Arrange
      final drill = DrillModel(
        id: 'local-error',
        title: 'Error Drill',
        skill: 'passing',
        subSkills: [],
        sets: 3,
        reps: 10,
        duration: 5,
        description: '',
        instructions: [],
        tips: [],
        equipment: [],
        trainingStyle: 'medium',
        difficulty: 'beginner',
        videoUrl: '',
        isCustom: true,
      );

      await database.saveDrillOffline(
        serverId: null,
        localId: 'local-error',
        drill: drill,
      );

      // Act
      await database.markSyncFailed(
        localId: 'local-error',
        error: 'Network timeout',
      );

      // Assert
      final savedDrill = await database.getDrillByLocalId('local-error');
      expect(savedDrill!['sync_error'], 'Network timeout');
    });
  });
}
