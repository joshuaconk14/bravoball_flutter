import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/drill_model.dart';
import '../services/app_state_service.dart';
import '../constants/app_theme.dart';
import '../utils/haptic_utils.dart';

class SaveToCollectionDialog {
  static void show(BuildContext context, DrillModel drill) {
    final appState = Provider.of<AppStateService>(context, listen: false);
    final originalContext = context; // Store the original context

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetContext) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            return Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const Text(
                    'Save to Collection',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Choose a collection to save ${drill.title} to:',
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 14,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 16),
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
                    Expanded(
                      child: ListView(
                        controller: scrollController,
                        children: appState.savedDrillGroups.map((group) {
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
                            onTap: () {
                              HapticUtils.mediumImpact();
                              String message;
                              if (isDrillInGroup) {
                                appState.removeDrillFromGroup(group.id, drill);
                                message = 'Removed ${drill.title} from "${group.name}"';
                              } else {
                                appState.addDrillToGroup(group.id, drill);
                                message = 'Added ${drill.title} to "${group.name}"';
                              }
                              Navigator.pop(sheetContext);
                              Future.delayed(const Duration(milliseconds: 300), () {
                                if (originalContext.mounted) {
                                  ScaffoldMessenger.of(originalContext).showSnackBar(
                                    SnackBar(
                                      content: Text(message),
                                      duration: const Duration(seconds: 2),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                }
                              });
                            },
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  const Text(
                    'Or create a new collection:',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      TextButton(
                        onPressed: () {
                          HapticUtils.lightImpact();
                          Navigator.pop(sheetContext);
                        },
                        child: const Text(
                          'Cancel',
                          style: TextStyle(fontFamily: 'Poppins'),
                        ),
                      ),
                      const Spacer(),
                      ElevatedButton(
                        onPressed: () {
                          HapticUtils.mediumImpact();
                          Navigator.pop(sheetContext);
                          _showCreateCollectionDialog(originalContext, appState, drill);
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
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  static void _showCreateCollectionDialog(BuildContext originalContext, AppStateService appState, DrillModel drill) {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    final existingNames = appState.savedDrillGroups.map((g) => g.name.toLowerCase()).toSet();
    
    showDialog(
      context: originalContext,
      builder: (dialogContext) {
        String? errorText;
        return StatefulBuilder(
          builder: (context, setState) {
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
                    decoration: InputDecoration(
                      labelText: 'Collection Name',
                      labelStyle: const TextStyle(fontFamily: 'Poppins'),
                      border: const OutlineInputBorder(),
                      errorText: errorText,
                    ),
                    autofocus: true,
                    onChanged: (_) {
                      if (errorText != null) setState(() => errorText = null);
                    },
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
                    Navigator.pop(dialogContext);
                  },
                  child: const Text(
                    'Cancel',
                    style: TextStyle(fontFamily: 'Poppins'),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    final name = nameController.text.trim();
                    if (name.isEmpty) return;
                    if (existingNames.contains(name.toLowerCase())) {
                      setState(() => errorText = 'A collection with this name already exists.');
                      return;
                    }
                    HapticUtils.mediumImpact();
                    
                    // Create new collection
                    appState.createDrillGroup(
                      name,
                      descriptionController.text.trim().isEmpty
                          ? 'Custom drill collection'
                          : descriptionController.text.trim(),
                    );
                    
                    // Add drill to the newly created collection
                    final newGroup = appState.savedDrillGroups.last;
                    appState.addDrillToGroup(newGroup.id, drill);
                    
                    // Store the message before dismissing the dialog
                    final message = 'Added $name to "${nameController.text.trim()}"';
                    
                    Navigator.pop(dialogContext);
                    
                    // Use the original context to show SnackBar
                    Future.delayed(const Duration(milliseconds: 300), () {
                      if (originalContext.mounted) {
                        ScaffoldMessenger.of(originalContext).showSnackBar(
                          SnackBar(
                            content: Text(message),
                            duration: const Duration(seconds: 2),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    });
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
      },
    );
  }
} 