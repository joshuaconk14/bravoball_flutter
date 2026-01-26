import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../../services/offline_custom_drill_database.dart';
import '../../models/drill_model.dart';
import '../../constants/app_theme.dart';
import 'package:uuid/uuid.dart';

/// Debug page for testing offline custom drill database
/// 
/// **Usage:**
/// - Navigate to this page to manually test database operations
/// - Useful for verifying database works before adding other tables
/// - Only available in debug mode
class OfflineDatabaseTestPage extends StatefulWidget {
  const OfflineDatabaseTestPage({Key? key}) : super(key: key);

  @override
  State<OfflineDatabaseTestPage> createState() => _OfflineDatabaseTestPageState();
}

class _OfflineDatabaseTestPageState extends State<OfflineDatabaseTestPage> {
  final OfflineCustomDrillDatabase _database = OfflineCustomDrillDatabase.instance;
  final Uuid _uuid = const Uuid();
  
  List<Map<String, dynamic>> _unsyncedDrills = [];
  int _unsyncedCount = 0;
  String _statusMessage = 'Ready to test';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadUnsyncedDrills();
  }

  Future<void> _loadUnsyncedDrills() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Loading...';
    });

    try {
      final drills = await _database.getUnsyncedDrills();
      final count = await _database.getUnsyncedCount();
      
      setState(() {
        _unsyncedDrills = drills;
        _unsyncedCount = count;
        _statusMessage = 'Loaded ${drills.length} unsynced drills';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Error: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _createTestDrill() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Creating test drill...';
    });

    try {
      final localId = _uuid.v4();
      final drill = DrillModel(
        id: localId,
        title: 'Test Drill ${DateTime.now().millisecondsSinceEpoch}',
        skill: 'dribbling',
        subSkills: ['ball_control', 'speed'],
        sets: 3,
        reps: 10,
        duration: 5,
        description: 'This is a test drill created for database testing',
        instructions: [
          'Step 1: Set up cones',
          'Step 2: Dribble through cones',
          'Step 3: Repeat',
        ],
        tips: ['Keep ball close', 'Use both feet'],
        equipment: ['ball', 'cones'],
        trainingStyle: 'medium',
        difficulty: 'beginner',
        videoUrl: '',
        isCustom: true,
      );

      await _database.saveDrillOffline(
        serverId: null,
        localId: localId,
        drill: drill,
      );

      setState(() {
        _statusMessage = '✅ Test drill created successfully!';
        _isLoading = false;
      });

      // Reload list
      await _loadUnsyncedDrills();
    } catch (e) {
      setState(() {
        _statusMessage = '❌ Error creating drill: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _markAsSynced(int index) async {
    if (index >= _unsyncedDrills.length) return;

    setState(() {
      _isLoading = true;
      _statusMessage = 'Marking as synced...';
    });

    try {
      final drill = _unsyncedDrills[index];
      final localId = drill['local_id'] as String;
      final serverId = 'server-${_uuid.v4()}';

      await _database.markAsSynced(
        localId: localId,
        serverId: serverId,
      );

      setState(() {
        _statusMessage = '✅ Marked as synced!';
        _isLoading = false;
      });

      // Reload list
      await _loadUnsyncedDrills();
    } catch (e) {
      setState(() {
        _statusMessage = '❌ Error: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteDrill(int index) async {
    if (index >= _unsyncedDrills.length) return;

    setState(() {
      _isLoading = true;
      _statusMessage = 'Deleting drill...';
    });

    try {
      final drill = _unsyncedDrills[index];
      final localId = drill['local_id'] as String;

      await _database.deleteDrill(localId);

      setState(() {
        _statusMessage = '✅ Drill deleted!';
        _isLoading = false;
      });

      // Reload list
      await _loadUnsyncedDrills();
    } catch (e) {
      setState(() {
        _statusMessage = '❌ Error: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Offline DB Test (Debug)'),
        backgroundColor: AppTheme.primaryYellow,
      ),
      body: Column(
        children: [
          // Status bar
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: AppTheme.lightGray,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Status: $_statusMessage',
                  style: AppTheme.bodyMedium.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Unsynced Count: $_unsyncedCount',
                  style: AppTheme.bodySmall,
                ),
              ],
            ),
          ),

          // Action buttons
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _createTestDrill,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.buttonPrimary,
                    ),
                    child: const Text('Create Test Drill'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _loadUnsyncedDrills,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.secondaryBlue,
                    ),
                    child: const Text('Refresh'),
                  ),
                ),
              ],
            ),
          ),

          // Drills list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _unsyncedDrills.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.inbox_outlined,
                              size: 64,
                              color: AppTheme.primaryGray,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No unsynced drills',
                              style: AppTheme.titleMedium.copyWith(
                                color: AppTheme.primaryGray,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Tap "Create Test Drill" to add one',
                              style: AppTheme.bodySmall,
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: _unsyncedDrills.length,
                        itemBuilder: (context, index) {
                          final drill = _unsyncedDrills[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            child: ListTile(
                              title: Text(
                                drill['title'] ?? 'Untitled',
                                style: AppTheme.titleMedium,
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 4),
                                  Text(
                                    'Local ID: ${drill['local_id']}',
                                    style: AppTheme.bodySmall,
                                  ),
                                  Text(
                                    'Skill: ${drill['skill']}',
                                    style: AppTheme.bodySmall,
                                  ),
                                  Text(
                                    'Sets: ${drill['sets']}, Reps: ${drill['reps']}',
                                    style: AppTheme.bodySmall,
                                  ),
                                ],
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.check),
                                    color: Colors.green,
                                    onPressed: () => _markAsSynced(index),
                                    tooltip: 'Mark as synced',
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete),
                                    color: Colors.red,
                                    onPressed: () => _deleteDrill(index),
                                    tooltip: 'Delete',
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
