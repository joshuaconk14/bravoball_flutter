import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';
import '../models/drill_model.dart';

/// Offline Custom Drill Database Service
/// 
/// Handles local SQLite storage for **custom drills** (user-created drills) created offline.
/// 
/// **Important:** This database only stores custom drills (user-created), NOT default/pre-existing drills.
/// Default drills are fetched from the backend and don't need offline storage.
/// 
/// Follows repository pattern for clean separation of concerns.
/// 
/// **Architecture Principles:**
/// - Singleton pattern for single database instance
/// - Lazy initialization for performance
/// - Migration support for schema evolution
/// - Error handling with proper logging
/// - Type safety throughout
/// 
/// **Usage:**
/// ```dart
/// final db = OfflineCustomDrillDatabase.instance;
/// await db.database; // Initialize if needed
/// final localId = await db.saveDrillOffline(...);
/// ```
class OfflineCustomDrillDatabase {
  // Singleton pattern
  static final OfflineCustomDrillDatabase _instance = OfflineCustomDrillDatabase._internal();
  factory OfflineCustomDrillDatabase() => _instance;
  OfflineCustomDrillDatabase._internal();

  static OfflineCustomDrillDatabase get instance => _instance;

  // Database instance (lazy initialization)
  Database? _database;
  
  // Database configuration constants
  static const String _databaseName = 'offline_custom_drills.db';
  
  /// Database schema version
  /// 
  /// **When to increment:**
  /// - When adding new columns to existing tables
  /// - When adding new tables
  /// - When modifying table structure
  /// - When adding/removing indexes
  /// 
  /// **How to increment:**
  /// 1. Increment this number (e.g., 1 → 2)
  /// 2. Add migration code in `_onUpgrade()` method
  /// 3. Test migration thoroughly
  /// 4. Document the change
  /// 
  /// **Example:**
  /// ```dart
  /// // Version 1: Initial schema
  /// static const int _databaseVersion = 1;
  /// 
  /// // Version 2: Added tags column
  /// static const int _databaseVersion = 2;
  /// // Then add: if (oldVersion < 2) { ... } in _onUpgrade()
  /// ```
  static const int _databaseVersion = 1;
  
  // Table and column names (avoid magic strings)
  static const String _tableName = 'offline_custom_drills';
  static const String _columnId = 'id';
  static const String _columnLocalId = 'local_id';
  static const String _columnTitle = 'title';
  static const String _columnDescription = 'description';
  static const String _columnSkill = 'skill';
  static const String _columnSubSkills = 'sub_skills';
  static const String _columnSets = 'sets';
  static const String _columnReps = 'reps';
  static const String _columnDuration = 'duration';
  static const String _columnInstructions = 'instructions';
  static const String _columnTips = 'tips';
  static const String _columnEquipment = 'equipment';
  static const String _columnTrainingStyle = 'training_style';
  static const String _columnDifficulty = 'difficulty';
  static const String _columnVideoUrl = 'video_url';
  static const String _columnIsSynced = 'is_synced';
  static const String _columnSyncError = 'sync_error';
  static const String _columnCreatedAt = 'created_at';
  static const String _columnUpdatedAt = 'updated_at';
  static const String _columnServerId = 'server_id';

  /// Get database instance (lazy initialization)
  /// 
  /// Initializes database on first access if not already initialized.
  /// Returns existing instance if already initialized.
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  /// Initialize database with schema and migrations
  /// 
  /// Creates database file if it doesn't exist.
  /// Runs onCreate callback for initial schema creation.
  /// Handles onUpgrade for future schema migrations.
  Future<Database> _initDatabase() async {
    try {
      final dbPath = await getDatabasesPath();
      final path = join(dbPath, _databaseName);

      final database = await openDatabase(
        path,
        version: _databaseVersion,
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
        onOpen: (db) {
      if (kDebugMode) {
        print('📦 OfflineCustomDrillDatabase: Database opened successfully');
      }
        },
      );

      if (kDebugMode) {
        print('✅ OfflineCustomDrillDatabase: Initialized at $path');
      }

      return database;
    } catch (e) {
      if (kDebugMode) {
        print('❌ OfflineCustomDrillDatabase: Initialization error - $e');
      }
      rethrow;
    }
  }

  /// Create database schema
  /// 
  /// Called when database is created for the first time.
  /// Creates all tables and indexes.
  Future<void> _onCreate(Database db, int version) async {
    try {
      // Create main table
      await db.execute('''
        CREATE TABLE $_tableName(
          $_columnId TEXT PRIMARY KEY,
          $_columnLocalId TEXT UNIQUE NOT NULL,
          $_columnTitle TEXT NOT NULL,
          $_columnDescription TEXT NOT NULL,
          $_columnSkill TEXT NOT NULL,
          $_columnSubSkills TEXT NOT NULL,
          $_columnSets INTEGER NOT NULL,
          $_columnReps INTEGER NOT NULL,
          $_columnDuration INTEGER NOT NULL,
          $_columnInstructions TEXT NOT NULL,
          $_columnTips TEXT NOT NULL,
          $_columnEquipment TEXT NOT NULL,
          $_columnTrainingStyle TEXT NOT NULL,
          $_columnDifficulty TEXT NOT NULL,
          $_columnVideoUrl TEXT NOT NULL,
          $_columnIsSynced INTEGER NOT NULL DEFAULT 0,
          $_columnSyncError TEXT,
          $_columnCreatedAt INTEGER NOT NULL,
          $_columnUpdatedAt INTEGER NOT NULL,
          $_columnServerId TEXT
        )
      ''');

      // Create indexes for performance
      await db.execute('''
        CREATE INDEX idx_is_synced ON $_tableName($_columnIsSynced)
      ''');

      await db.execute('''
        CREATE INDEX idx_local_id ON $_tableName($_columnLocalId)
      ''');

      await db.execute('''
        CREATE INDEX idx_created_at ON $_tableName($_columnCreatedAt)
      ''');

      if (kDebugMode) {
        print('✅ OfflineCustomDrillDatabase: Schema created successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ OfflineCustomDrillDatabase: Schema creation error - $e');
      }
      rethrow;
    }
  }

  /// Handle database migrations
  /// 
  /// Called automatically when database version is upgraded.
  /// Handles schema changes between versions safely.
  /// 
  /// **Migration Strategy:**
  /// - Always check oldVersion before applying migrations
  /// - Apply migrations sequentially (oldVersion < 2, then < 3, etc.)
  /// - Never delete data unless explicitly required
  /// - Test migrations thoroughly before release
  /// - Migrations run automatically when user updates app
  /// 
  /// **How to add a new migration:**
  /// 1. Increment `_databaseVersion` constant above
  /// 2. Add migration code here: `if (oldVersion < NEW_VERSION) { ... }`
  /// 3. Test with existing database data
  /// 4. Document what changed
  /// 
  /// **Example:**
  /// ```dart
  /// // Migration to version 2: Add tags column
  /// if (oldVersion < 2) {
  ///   await db.execute('ALTER TABLE $_tableName ADD COLUMN tags TEXT');
  /// }
  /// 
  /// // Migration to version 3: Add index
  /// if (oldVersion < 3) {
  ///   await db.execute('CREATE INDEX idx_tags ON $_tableName(tags)');
  /// }
  /// ```
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (kDebugMode) {
      print('🔄 OfflineCustomDrillDatabase: Migrating from version $oldVersion to $newVersion');
    }

    try {
      // ✅ ADD MIGRATIONS HERE WHEN INCREMENTING _databaseVersion
      // 
      // Example migration pattern:
      // 
      // // Migration to version 2: Add tags column
      // if (oldVersion < 2) {
      //   await db.execute('ALTER TABLE $_tableName ADD COLUMN tags TEXT');
      // }
      // 
      // // Migration to version 3: Add difficulty_level column
      // if (oldVersion < 3) {
      //   await db.execute('ALTER TABLE $_tableName ADD COLUMN difficulty_level INTEGER DEFAULT 0');
      // }
      // 
      // // Migration to version 4: Add index for performance
      // if (oldVersion < 4) {
      //   await db.execute('CREATE INDEX idx_tags ON $_tableName(tags)');
      // }

      if (kDebugMode) {
        print('✅ OfflineCustomDrillDatabase: Migration completed');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ OfflineCustomDrillDatabase: Migration error - $e');
      }
      rethrow;
    }
  }

  /// Save drill offline
  /// 
  /// Saves a drill to local SQLite database.
  /// If serverId is provided, marks drill as synced.
  /// If serverId is null, marks drill as unsynced for later sync.
  /// 
  /// **Parameters:**
  /// - `serverId`: Server-assigned ID (null if not yet synced)
  /// - `localId`: Local UUID for tracking offline drills
  /// - `drill`: DrillModel to save
  /// 
  /// **Returns:**
  /// Local ID of saved drill
  /// 
  /// **Throws:**
  /// DatabaseException if save fails
  Future<String> saveDrillOffline({
    required String? serverId,
    required String localId,
    required DrillModel drill,
  }) async {
    try {
      final db = await database;
      
      final now = DateTime.now().millisecondsSinceEpoch;
      final drillData = {
        _columnId: serverId ?? localId, // Use server ID if available, otherwise local
        _columnLocalId: localId,
        _columnTitle: drill.title,
        _columnDescription: drill.description,
        _columnSkill: drill.skill,
        _columnSubSkills: jsonEncode(drill.subSkills),
        _columnSets: drill.sets,
        _columnReps: drill.reps,
        _columnDuration: drill.duration,
        _columnInstructions: jsonEncode(drill.instructions),
        _columnTips: jsonEncode(drill.tips),
        _columnEquipment: jsonEncode(drill.equipment),
        _columnTrainingStyle: drill.trainingStyle,
        _columnDifficulty: drill.difficulty,
        _columnVideoUrl: drill.videoUrl,
        _columnIsSynced: serverId != null ? 1 : 0, // Synced if server ID exists
        _columnSyncError: null,
        _columnCreatedAt: now,
        _columnUpdatedAt: now,
        _columnServerId: serverId,
      };

      await db.insert(
        _tableName,
        drillData,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      if (kDebugMode) {
        print('💾 OfflineCustomDrillDatabase: Saved custom drill offline - $localId (synced: ${serverId != null})');
      }

      return localId;
    } catch (e) {
      if (kDebugMode) {
        print('❌ OfflineCustomDrillDatabase: Error saving drill - $e');
      }
      rethrow;
    }
  }

  /// Get all unsynced drills
  /// 
  /// Retrieves all drills that haven't been synced to server yet.
  /// Ordered by creation date (oldest first) for fair sync order.
  /// 
  /// **Returns:**
  /// List of drill data maps ready for sync
  Future<List<Map<String, dynamic>>> getUnsyncedDrills() async {
    try {
      final db = await database;
      final results = await db.query(
        _tableName,
        where: '$_columnIsSynced = ?',
        whereArgs: [0],
        orderBy: '$_columnCreatedAt ASC', // Oldest first
      );

      final drills = results.map(_mapRowToDrillData).toList();

      if (kDebugMode) {
        print('📋 OfflineCustomDrillDatabase: Found ${drills.length} unsynced custom drills');
      }

      return drills;
    } catch (e) {
      if (kDebugMode) {
        print('❌ OfflineCustomDrillDatabase: Error getting unsynced drills - $e');
      }
      return [];
    }
  }

  /// Get drill by local ID
  /// 
  /// Retrieves a specific drill by its local ID.
  /// 
  /// **Parameters:**
  /// - `localId`: Local UUID of the drill
  /// 
  /// **Returns:**
  /// Drill data map or null if not found
  Future<Map<String, dynamic>?> getDrillByLocalId(String localId) async {
    try {
      final db = await database;
      final results = await db.query(
        _tableName,
        where: '$_columnLocalId = ?',
        whereArgs: [localId],
        limit: 1,
      );

      if (results.isEmpty) return null;
      return _mapRowToDrillData(results.first);
    } catch (e) {
      if (kDebugMode) {
        print('❌ OfflineCustomDrillDatabase: Error getting drill - $e');
      }
      return null;
    }
  }

  /// Mark drill as synced
  /// 
  /// Updates drill record after successful server sync.
  /// Updates ID to server ID and marks as synced.
  /// 
  /// **Parameters:**
  /// - `localId`: Local UUID of the drill
  /// - `serverId`: Server-assigned ID
  /// 
  /// **Throws:**
  /// DatabaseException if update fails
  Future<void> markAsSynced({
    required String localId,
    required String serverId,
  }) async {
    try {
      final db = await database;
      final now = DateTime.now().millisecondsSinceEpoch;
      
      await db.update(
        _tableName,
        {
          _columnIsSynced: 1,
          _columnServerId: serverId,
          _columnId: serverId, // Update ID to server ID
          _columnSyncError: null,
          _columnUpdatedAt: now,
        },
        where: '$_columnLocalId = ?',
        whereArgs: [localId],
      );

      if (kDebugMode) {
        print('✅ OfflineCustomDrillDatabase: Marked custom drill as synced - $localId -> $serverId');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ OfflineCustomDrillDatabase: Error marking as synced - $e');
      }
      rethrow;
    }
  }

  /// Mark drill sync as failed
  /// 
  /// Records sync failure for debugging and retry logic.
  /// 
  /// **Parameters:**
  /// - `localId`: Local UUID of the drill
  /// - `error`: Error message or exception
  Future<void> markSyncFailed({
    required String localId,
    required String error,
  }) async {
    try {
      final db = await database;
      await db.update(
        _tableName,
        {
          _columnSyncError: error,
          _columnUpdatedAt: DateTime.now().millisecondsSinceEpoch,
        },
        where: '$_columnLocalId = ?',
        whereArgs: [localId],
      );

      if (kDebugMode) {
        print('⚠️ OfflineCustomDrillDatabase: Marked sync failed for $localId - $error');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ OfflineCustomDrillDatabase: Error marking sync failed - $e');
      }
    }
  }

  /// Get count of unsynced drills
  /// 
  /// Returns the number of drills waiting to be synced.
  /// Useful for UI indicators and sync prioritization.
  /// 
  /// **Returns:**
  /// Count of unsynced drills
  Future<int> getUnsyncedCount() async {
    try {
      final db = await database;
      final result = await db.rawQuery(
        'SELECT COUNT(*) as count FROM $_tableName WHERE $_columnIsSynced = 0',
      );
      final count = Sqflite.firstIntValue(result) ?? 0;
      
      if (kDebugMode && count > 0) {
        print('📊 OfflineCustomDrillDatabase: $count custom drills pending sync');
      }
      
      return count;
    } catch (e) {
      if (kDebugMode) {
        print('❌ OfflineDrillDatabase: Error getting unsynced count - $e');
      }
      return 0;
    }
  }

  /// Delete drill by local ID
  /// 
  /// Removes a drill from local database.
  /// Use with caution - consider soft delete for production.
  /// 
  /// **Parameters:**
  /// - `localId`: Local UUID of the drill to delete
  /// 
  /// **Throws:**
  /// DatabaseException if delete fails
  Future<void> deleteDrill(String localId) async {
    try {
      final db = await database;
      final deleted = await db.delete(
        _tableName,
        where: '$_columnLocalId = ?',
        whereArgs: [localId],
      );

      if (kDebugMode) {
        print('🗑️ OfflineCustomDrillDatabase: Deleted custom drill - $localId (rows: $deleted)');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ OfflineCustomDrillDatabase: Error deleting drill - $e');
      }
      rethrow;
    }
  }

  /// Convert database row to drill data map
  /// 
  /// Maps SQLite row to application data structure.
  /// Handles JSON deserialization for complex fields.
  /// 
  /// **Parameters:**
  /// - `row`: Database row map
  /// 
  /// **Returns:**
  /// Drill data map ready for sync or display
  Map<String, dynamic> _mapRowToDrillData(Map<String, dynamic> row) {
    try {
      return {
        'local_id': row[_columnLocalId],
        'server_id': row[_columnServerId],
        'title': row[_columnTitle],
        'description': row[_columnDescription],
        'skill': row[_columnSkill],
        'subSkills': jsonDecode(row[_columnSubSkills] as String) as List<dynamic>,
        'sets': row[_columnSets] as int,
        'reps': row[_columnReps] as int,
        'duration': row[_columnDuration] as int,
        'instructions': jsonDecode(row[_columnInstructions] as String) as List<dynamic>,
        'tips': jsonDecode(row[_columnTips] as String) as List<dynamic>,
        'equipment': jsonDecode(row[_columnEquipment] as String) as List<dynamic>,
        'trainingStyle': row[_columnTrainingStyle],
        'difficulty': row[_columnDifficulty],
        'videoUrl': row[_columnVideoUrl],
        'is_synced': (row[_columnIsSynced] as int) == 1,
        'sync_error': row[_columnSyncError],
        'created_at': row[_columnCreatedAt],
      };
    } catch (e) {
      if (kDebugMode) {
        print('❌ OfflineCustomDrillDatabase: Error mapping row data - $e');
      }
      rethrow;
    }
  }

  /// Close database connection
  /// 
  /// Properly closes database connection.
  /// Should be called during app shutdown or testing cleanup.
  /// 
  /// **Note:** Database will be reinitialized on next access.
  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
      if (kDebugMode) {
        print('🔒 OfflineCustomDrillDatabase: Database closed');
      }
    }
  }

  /// Check if database is initialized
  /// 
  /// Useful for testing and debugging.
  /// 
  /// **Returns:**
  /// True if database is initialized, false otherwise
  bool get isInitialized => _database != null;

  /// Clear all drills from database
  /// 
  /// **WARNING:** This method is for testing only!
  /// Deletes all records from the database.
  /// 
  /// **Use cases:**
  /// - Unit testing cleanup
  /// - Debug reset functionality
  /// 
  /// **Throws:**
  /// DatabaseException if clear fails
  Future<void> clearAllDrills() async {
    try {
      final db = await database;
      await db.delete(_tableName);
      
      if (kDebugMode) {
        print('🗑️ OfflineCustomDrillDatabase: Cleared all drills');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ OfflineCustomDrillDatabase: Error clearing drills - $e');
      }
      rethrow;
    }
  }
}
