import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/drill_model.dart';
import '../services/app_state_service.dart';
import '../constants/app_theme.dart';
import '../utils/haptic_utils.dart';

class SaveToCollectionDialog {
  static void show(BuildContext context, DrillModel drill) {
    final appState = Provider.of<AppStateService>(context, listen: false);
    
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            'Save to Collection',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Choose a collection to save "${drill.title}" to:',
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 14,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 16),
              
              // Show existing collections
              if (appState.savedDrillGroups.isNotEmpty) ...[
                const Text(
                  'Existing Collections:',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                
                // List existing collections
                ...appState.savedDrillGroups.map((group) {
                  final isDrillInGroup = group.drills.any((d) => d.id == drill.id);
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      Icons.folder,
                      color: AppTheme.primaryPurple,
                    ),
                    title: Text(
                      group.name,
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 14,
                      ),
                    ),
                    subtitle: Text(
                      '${group.drills.length} drills',
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 12,
                      ),
                    ),
                    trailing: isDrillInGroup 
                        ? const Icon(Icons.check, color: Colors.green)
                        : null,
                    onTap: isDrillInGroup ? null : () {
                      HapticUtils.mediumImpact();
                      appState.addDrillToGroup(group.id, drill);
                      Navigator.pop(context);
                      
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Added to ${group.name}'),
                          duration: const Duration(seconds: 2),
                          backgroundColor: Colors.green,
                        ),
                      );
                    },
                  );
                }).toList(),
                
                const SizedBox(height: 16),
              ],
              
              // Option to create new collection
              const Text(
                'Or create a new collection:',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                HapticUtils.lightImpact();
                Navigator.pop(context);
              },
              child: const Text(
                'Cancel',
                style: TextStyle(fontFamily: 'Poppins'),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                HapticUtils.mediumImpact();
                Navigator.pop(context);
                _showCreateCollectionDialog(context, appState, drill);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryPurple,
                foregroundColor: Colors.white,
              ),
              child: const Text(
                'New Collection',
                style: TextStyle(fontFamily: 'Poppins'),
              ),
            ),
          ],
        );
      },
    );
  }

  static void _showCreateCollectionDialog(BuildContext context, AppStateService appState, DrillModel drill) {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            'Create New Collection',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                style: const TextStyle(fontFamily: 'Poppins'),
                decoration: const InputDecoration(
                  labelText: 'Collection Name',
                  labelStyle: TextStyle(fontFamily: 'Poppins'),
                  border: OutlineInputBorder(),
                ),
                autofocus: true,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descriptionController,
                style: const TextStyle(fontFamily: 'Poppins'),
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Description (optional)',
                  labelStyle: TextStyle(fontFamily: 'Poppins'),
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                HapticUtils.lightImpact();
                Navigator.pop(context);
              },
              child: const Text(
                'Cancel',
                style: TextStyle(fontFamily: 'Poppins'),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                if (nameController.text.trim().isNotEmpty) {
                  HapticUtils.mediumImpact();
                  
                  // Create new collection
                  appState.createDrillGroup(
                    nameController.text.trim(),
                    descriptionController.text.trim().isEmpty
                        ? 'Custom drill collection'
                        : descriptionController.text.trim(),
                  );
                  
                  // Add drill to the newly created collection
                  final newGroup = appState.savedDrillGroups.last;
                  appState.addDrillToGroup(newGroup.id, drill);
                  
                  Navigator.pop(context);
                  
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Created "${nameController.text.trim()}" and added drill'),
                      duration: const Duration(seconds: 2),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryPurple,
                foregroundColor: Colors.white,
              ),
              child: const Text(
                'Create & Add',
                style: TextStyle(fontFamily: 'Poppins'),
              ),
            ),
          ],
        );
      },
    );
  }
} 