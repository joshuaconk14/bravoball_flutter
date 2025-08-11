import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart'; // Add this import for video picker
import 'package:permission_handler/permission_handler.dart'; // Add this import for permission status
import 'package:path_provider/path_provider.dart'; // Add this import for directory access
import 'dart:io'; // Add this import for File support
import '../../models/drill_model.dart';
import '../../models/drill_group_model.dart';
import '../../services/custom_drill_service.dart';
import '../../services/app_state_service.dart';
import '../../services/video_file_service.dart'; // ✅ ADDED: Import video file service
import '../../services/permission_service.dart'; // ✅ ADDED: Import permission service
import '../../constants/app_theme.dart';
import '../../utils/haptic_utils.dart';
import '../../widgets/bravo_button.dart';
import '../../widgets/info_popup_widget.dart'; // ✅ ADDED: Import for reusable info popup
import '../../widgets/drill_video_player.dart'; // Add this import for video preview
import '../../widgets/guest_account_creation_dialog.dart'; // ✅ ADDED: Import reusable dialog
import 'package:flutter/foundation.dart'; // Add this import for kDebugMode

class CreateDrillSheet extends StatefulWidget {
  const CreateDrillSheet({Key? key}) : super(key: key);

  @override
  State<CreateDrillSheet> createState() => _CreateDrillSheetState();
}

class _CreateDrillSheetState extends State<CreateDrillSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _instructionsController = TextEditingController();
  final _tipsController = TextEditingController();
  final _equipmentController = TextEditingController();
  // ✅ REMOVED: _videoUrlController no longer needed

  String _selectedSkill = 'Passing';
  String _selectedDifficulty = 'Beginner';
  String _selectedTrainingStyle = 'Medium';
  
  int _sets = 3;
  int _reps = 10;
  int _duration = 10;
  
  List<String> _subSkills = [];
  List<String> _instructions = [];
  List<String> _tips = [];
  List<String> _equipment = [];
  
  bool _isLoading = false;
  DrillModel? _createdDrill;
  bool _hasAttemptedValidation = false; // ✅ ADDED: Track validation attempts

  // Video picking functionality
  final ImagePicker _picker = ImagePicker();
  File? _selectedVideoFile;
  String? _videoPath;
  bool _isVideoLoading = false;

  final List<String> _availableSkills = [
    'Passing',
    'Shooting',
    'Dribbling',
    'First Touch',
    'Defending',
    'Fitness',
  ];

  final List<String> _availableDifficulties = [
    'Beginner',
    'Intermediate',
    'Advanced',
  ];

  final List<String> _availableTrainingStyles = [
    'Low',
    'Medium',
    'High',
  ];

  final Map<String, List<String>> _skillSubSkills = {
    'Passing': ['Short Passing', 'Long Passing', 'One-Touch Passing', 'Through Balls', 'Crossing'],
    'Shooting': ['Power Shooting', 'Accuracy Shooting', 'Volleys', 'Headers', 'Free Kicks'],
    'Dribbling': ['Ball Control', 'Speed Dribbling', 'Close Control', 'Turns', 'Feints'],
    'First Touch': ['Ground Control', 'Aerial Control', 'Chest Control', 'Thigh Control'],
    'Defending': ['Tackling', 'Marking', 'Interceptions', 'Clearances', 'Positioning'],
    'Fitness': ['Endurance', 'Speed', 'Agility', 'Strength', 'Recovery'],
  };

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _instructionsController.dispose();
    _tipsController.dispose();
    _equipmentController.dispose();
    super.dispose();
  }

  void _addInstruction() {
    final instruction = _instructionsController.text.trim();
    if (instruction.isNotEmpty) {
      setState(() {
        _instructions.add(instruction);
        _instructionsController.clear();
        _hasAttemptedValidation = false; // ✅ ADDED: Reset validation flag when instruction is added
      });
      HapticUtils.lightImpact();
    }
  }

  void _removeInstruction(int index) {
    setState(() {
      _instructions.removeAt(index);
      _hasAttemptedValidation = false; // ✅ ADDED: Reset validation flag when instruction is removed
    });
    HapticUtils.lightImpact();
  }

  void _addTip() {
    final tip = _tipsController.text.trim();
    if (tip.isNotEmpty) {
      setState(() {
        _tips.add(tip);
        _tipsController.clear();
      });
      HapticUtils.lightImpact();
    }
  }

  void _removeTip(int index) {
    setState(() {
      _tips.removeAt(index);
    });
    HapticUtils.lightImpact();
  }

  void _addEquipment() {
    final equipment = _equipmentController.text.trim();
    if (equipment.isNotEmpty) {
      setState(() {
        _equipment.add(equipment);
        _equipmentController.clear();
      });
      HapticUtils.lightImpact();
    }
  }

  void _removeEquipment(int index) {
    setState(() {
      _equipment.removeAt(index);
    });
    HapticUtils.lightImpact();
  }

  // Video picker with enhanced Android permission handling
  Future<void> _pickVideo() async {
    try {
      print('🎬 Starting video picker...');
      
      // ✅ SIMPLIFIED: Try picking video directly first without permission checks
      // Since we're only accessing existing videos, iOS often allows this without explicit permission
      
      setState(() {
        _isVideoLoading = true;
      });

      print('🎬 Attempting to pick video from gallery...');
      
      // Try to pick video directly
      final video = await _picker.pickVideo(
        source: ImageSource.gallery,
        maxDuration: const Duration(minutes: 1),
      );

      print('🎬 Video picker result: ${video?.path ?? 'null'}');

      if (video != null) {
        final tempFile = File(video.path);
        final exists = await tempFile.exists();
        
        if (exists) {
          print('🎬 Video file exists, copying to permanent storage...');
          
          // Copy to permanent storage
          final permanentPath = await VideoFileService.instance.copyVideoToPermanentStorage(video.path);
          
          if (permanentPath != null) {
            setState(() {
              _selectedVideoFile = File(permanentPath);
              _videoPath = permanentPath;
            });
            
            HapticUtils.mediumImpact();
            
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('✅ Video selected successfully!'),
                  backgroundColor: AppTheme.success,
                  duration: Duration(seconds: 2),
                ),
              );
            }
            
            print('✅ Video selected and saved successfully');
          } else {
            _showErrorMessage('Failed to save video. Please try again.');
          }
        } else {
          _showErrorMessage('Selected video file not found.');
        }
      } else {
        print('ℹ️ User cancelled video selection');
        // User cancelled - this is normal, no error message needed
      }

      setState(() {
        _isVideoLoading = false;
      });

    } catch (e, stackTrace) {
      print('🎬 Error picking video: $e');
      print('🎬 Stack trace: $stackTrace');
      
      setState(() {
        _isVideoLoading = false;
      });
      
      // Only show permission dialog if the error seems permission-related
      if (e.toString().toLowerCase().contains('permission') || 
          e.toString().toLowerCase().contains('access') ||
          e.toString().toLowerCase().contains('denied')) {
        
        print('🔐 Permission-related error detected, showing permission guidance');
        _showPermissionDeniedDialog();
        
      } else {
        // Show generic error for other issues
        String errorMessage = 'Error selecting video';
        
        if (e.toString().contains('channel-error')) {
          errorMessage = 'Camera/Photos access issue. Please restart the app and try again.';
        } else {
          errorMessage = 'Error selecting video: ${e.toString()}';
        }
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMessage),
              backgroundColor: AppTheme.error,
              duration: const Duration(seconds: 4),
              action: SnackBarAction(
                label: 'Try Again',
                textColor: Colors.white,
                onPressed: () {
                  _pickVideo(); // Retry
                },
              ),
            ),
          );
        }
      }
    }
  }

  // Helper method to show error messages
  void _showErrorMessage(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: AppTheme.error,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  // ✅ IMPROVED: Show dialog for permanently denied permissions with clearer instructions
  void _showPermissionDeniedDialog() {
    print('🔐 [CreateDrill] Showing permission denied dialog to user');
    
    showDialog(
      context: context,
      barrierDismissible: false, // Prevent dismissing by tapping outside
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              Icons.photo_library_outlined,
              color: AppTheme.primaryYellow,
              size: 24,
            ),
            const SizedBox(width: 8),
            const Text('Permission Required'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              Platform.isAndroid 
                ? 'Photo/Media access was previously denied and must be enabled manually in Settings.'
                : 'Photo Library access was previously denied and must be enabled manually in Settings.',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.primaryYellow.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.primaryYellow.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'To enable:',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryDark,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    Platform.isAndroid
                      ? '1. Tap "Open Settings" below\n2. Go to Permissions\n3. Enable Photos/Media access\n4. Return to this app'
                      : '1. Tap "Open Settings" below\n2. Find "Photos" in the list\n3. Select "All Photos" or "Selected Photos"\n4. Return to this app',
                    style: const TextStyle(fontSize: 14, color: Colors.black87),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.success.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.lightbulb_outline,
                          size: 16,
                          color: AppTheme.success,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'After enabling in Settings, tap "Check Again" below',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.success,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              _refreshPermissionsAndRetry();
            },
            child: const Text('Check Again'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              print('🔐 [CreateDrill] User tapped Open Settings');
              
              final permissionService = PermissionService.shared;
              final opened = await permissionService.openPermissionSettings();
              
              print('🔐 [CreateDrill] Settings opened: $opened');
              
              // Always show a helpful message to guide the user
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      opened 
                        ? 'Settings opened! Please enable photo library access and return to the app.'
                        : Platform.isAndroid
                          ? 'Please go to Settings > Apps > BravoBall > Permissions and enable Photo/Media access'
                          : 'Please go to Settings > Privacy & Security > Photos and enable access for BravoBall',
                    ),
                    duration: const Duration(seconds: 8),
                    backgroundColor: AppTheme.primaryYellow,
                    action: SnackBarAction(
                      label: 'Try Again',
                      textColor: Colors.white,
                      onPressed: () {
                        _refreshPermissionsAndRetry();
                      },
                    ),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryYellow),
            child: const Text('Open Settings', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // ✅ IMPROVED: Show dialog for initially required permissions
  void _showPermissionRequiredDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Photo Access Required'),
        content: const Text(
          'This app needs access to your photos and videos to let you select custom drill videos from your camera roll.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              // Try requesting permission again
              final permissionService = PermissionService.shared;
              final granted = await permissionService.requestPhotoLibraryPermission();
              if (granted) {
                _pickVideo(); // Retry video picking
              } else {
                // If still denied, check if it's now permanently denied
                final isPermanentlyDenied = await permissionService.isPhotoLibraryPermissionPermanentlyDenied();
                if (isPermanentlyDenied) {
                  _showPermissionDeniedDialog();
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryYellow),
            child: const Text('Grant Permission', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // ✅ DEBUG: Method to check and log current permission status
  Future<void> _debugPermissionStatus() async {
    final permissionService = PermissionService.shared;
    
    final hasPermission = await permissionService.hasPhotoLibraryPermission();
    final isPermanentlyDenied = await permissionService.isPhotoLibraryPermissionPermanentlyDenied();
    
    print('🔍 [DEBUG] Current permission status:');
    print('   Has permission: $hasPermission');
    print('   Permanently denied: $isPermanentlyDenied');
    
    if (Platform.isIOS) {
      final status = await Permission.photos.status;
      print('   Raw iOS status: $status');
      print('   Status meanings:');
      print('     - granted: Full access to all photos');
      print('     - limited: Access to selected photos only');
      print('     - denied: No access');
      print('     - permanentlyDenied: User must enable in Settings');
      
      // Additional iOS-specific checks
      print('   iOS-specific checks:');
      print('     - Can request permission: ${status != PermissionStatus.permanentlyDenied}');
      print('     - Should work with limited: ${status == PermissionStatus.limited}');
    }
  }

  // ✅ NEW: Alternative video picker method for testing
  Future<void> _pickVideoAlternative() async {
    try {
      print('🎬 [ALTERNATIVE] Trying alternative video picker approach...');
      
      setState(() {
        _isVideoLoading = true;
      });

      // Try picking without any permission checks first
      final video = await _picker.pickVideo(
        source: ImageSource.gallery,
        maxDuration: const Duration(minutes: 1),
      );

      if (video != null) {
        print('✅ [ALTERNATIVE] Video picked successfully: ${video.path}');
        
        final tempFile = File(video.path);
        final exists = await tempFile.exists();
        
        if (exists) {
          final permanentPath = await VideoFileService.instance.copyVideoToPermanentStorage(video.path);
          
          if (permanentPath != null) {
            setState(() {
              _selectedVideoFile = File(permanentPath);
              _videoPath = permanentPath;
            });
            
            HapticUtils.mediumImpact();
            
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('✅ Video selected successfully with alternative method!'),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 3),
              ),
            );
          }
        }
      } else {
        print('❌ [ALTERNATIVE] No video selected');
      }

      setState(() {
        _isVideoLoading = false;
      });

    } catch (e, stackTrace) {
      print('❌ [ALTERNATIVE] Error: $e');
      print('❌ [ALTERNATIVE] Stack: $stackTrace');
      
      setState(() {
        _isVideoLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Alternative method failed: ${e.toString()}'),
          backgroundColor: AppTheme.error,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  // ✅ NEW: Complete diagnostic method
  Future<void> _runCompleteDiagnostics() async {
    print('\n🔍 ===== COMPLETE VIDEO PICKER DIAGNOSTICS =====');
    
    // 1. Platform check
    print('📱 Platform: ${Platform.operatingSystem} ${Platform.operatingSystemVersion}');
    
    // 2. Permission status
    await _debugPermissionStatus();
    
    // 3. Plugin availability check
    try {
      print('🔌 Checking image_picker plugin...');
      final picker = ImagePicker();
      print('   ImagePicker instance created: ${picker != null}');
    } catch (e) {
      print('❌ ImagePicker plugin error: $e');
    }
    
    // 4. File system check
    try {
      print('📁 Checking file system access...');
      final documentsDir = await getApplicationDocumentsDirectory();
      print('   Documents directory: ${documentsDir.path}');
      final tempDir = await getTemporaryDirectory();
      print('   Temp directory: ${tempDir.path}');
    } catch (e) {
      print('❌ File system error: $e');
    }
    
    // 5. Try alternative picker
    print('🎬 Testing alternative video picker...');
    
    print('===== END DIAGNOSTICS =====\n');
  }

  // ✅ NEW: Method to refresh permission status and retry video picker
  Future<void> _refreshPermissionsAndRetry() async {
    print('🔄 [CreateDrill] Refreshing permission status...');
    
    // Force refresh by waiting a moment and checking again
    await Future.delayed(const Duration(milliseconds: 500));
    
    final permissionService = PermissionService.shared;
    final hasPermission = await permissionService.hasPhotoLibraryPermission();
    
    await _debugPermissionStatus();
    
    if (hasPermission) {
      print('✅ [CreateDrill] Permission now granted! Retrying video picker...');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Permission granted! Opening video picker...'),
          backgroundColor: AppTheme.success,
          duration: Duration(seconds: 2),
        ),
      );
      _pickVideo();
    } else {
      print('❌ [CreateDrill] Permission still not granted');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Permission still not detected. Please ensure "All Photos" or "Selected Photos" is enabled and try again.'),
          backgroundColor: AppTheme.error,
          duration: Duration(seconds: 4),
        ),
      );
    }
  }

  // Show permission dialog (legacy method - can be removed)
  void _showPermissionDialog() {
    _showPermissionDeniedDialog();
  }

  void _removeVideo() {
    setState(() {
      _selectedVideoFile = null;
      _videoPath = null;
    });
    HapticUtils.lightImpact();
  }

  void _toggleSubSkill(String subSkill) {
    setState(() {
      if (_subSkills.contains(subSkill)) {
        _subSkills.remove(subSkill);
      } else {
        _subSkills.add(subSkill);
      }
    });
    HapticUtils.lightImpact();
  }

  Future<void> _createDrill() async {
    // ✅ ADDED: Check for guest mode and show account creation prompt
    final appState = Provider.of<AppStateService>(context, listen: false);
    if (appState.isGuestMode) {
      _showGuestAccountPrompt();
      return;
    }

    // Custom validation for instructions
    bool hasInstructions = _instructions.isNotEmpty;
    
    if (!_formKey.currentState!.validate() || !hasInstructions) {
      setState(() {
        _hasAttemptedValidation = true; // ✅ ADDED: Mark that validation was attempted
      });
      _formKey.currentState!.validate();
      HapticUtils.mediumImpact();
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final customDrillService = CustomDrillService.shared;
      final drill = await customDrillService.createCustomDrill(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        skill: _selectedSkill,
        subSkills: _subSkills,
        sets: _sets,
        reps: _reps,
        duration: _duration,
        instructions: _instructions,
        tips: _tips,
        equipment: _equipment,
        trainingStyle: _selectedTrainingStyle,
        difficulty: _selectedDifficulty,
        videoUrl: _videoPath ?? '', // ✅ UPDATED: Pass the selected video path
      );

      if (drill != null) {
        setState(() {
          _createdDrill = drill;
        });
        HapticUtils.heavyImpact();
        
        // ✅ ADDED: Refresh custom drills in app state so new drill appears immediately
        final appState = Provider.of<AppStateService>(context, listen: false);
        await appState.refreshCustomDrillsFromBackend();
        
        _showSaveToGroupDialog();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to create drill. Please try again.'),
            backgroundColor: AppTheme.error,
          ),
        );
        HapticUtils.mediumImpact();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error creating drill: $e'),
          backgroundColor: AppTheme.error,
        ),
      );
      HapticUtils.mediumImpact();
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showSaveToGroupDialog() {
    final appState = Provider.of<AppStateService>(context, listen: false);
    final existingGroups = appState.savedDrillGroups.where((g) => !g.isLikedDrillsGroup).toList();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Save to Collection'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Where would you like to save your custom drill?'),
            const SizedBox(height: 16),
            if (existingGroups.isNotEmpty) ...[
              const Text('Existing Collections:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              ...existingGroups.map((group) => ListTile(
                leading: const Icon(Icons.folder),
                title: Text(group.name),
                subtitle: Text(group.description),
                onTap: () {
                  Navigator.pop(context);
                  _saveToExistingGroup(group);
                },
              )),
              const SizedBox(height: 16),
            ],
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                _showCreateGroupDialog();
              },
              icon: const Icon(Icons.create_new_folder),
              label: const Text('Create New Collection'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryYellow,
                foregroundColor: AppTheme.white,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context); // Close the create drill sheet
            },
            child: const Text('Skip'),
          ),
        ],
      ),
    );
  }

  void _saveToExistingGroup(DrillGroup group) {
    if (_createdDrill != null) {
      final appState = Provider.of<AppStateService>(context, listen: false);
      appState.addDrillToGroup(group.id, _createdDrill!);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Added "${_createdDrill!.title}" to "${group.name}"'),
          backgroundColor: AppTheme.success,
        ),
      );
      
      Navigator.pop(context); // Close the create drill sheet
    }
  }

  // ✅ UPDATED: Use reusable InfoPopupWidget instead of custom dialog
  void _showInfoDialog() {
    InfoPopupWidget.show(
      context,
      title: 'About Custom Drills',
      description: '''🎯 What are Custom Drills?

Custom drills are personalized training exercises that you create specifically for your needs. They're private to your account and perfect for:

• Practicing specific techniques you want to improve
• Preparing for game situations  
• Creating drills your coach taught you
• Designing exercises for specific equipment you have

💾 How do they work?

• Add them to your training sessions
• Save them to any of your drill collections
• Only you can see and use your custom drills
• Available across all your devices when you're logged in''',
    );
  }

  void _showCreateGroupDialog() {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create New Collection'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Collection Name',
                hintText: 'Enter collection name',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description (Optional)',
                hintText: 'Enter description',
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final name = nameController.text.trim();
              if (name.isNotEmpty) {
                Navigator.pop(context);
                _createGroupAndSave(name, descriptionController.text.trim());
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryYellow,
              foregroundColor: AppTheme.white,
            ),
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _createGroupAndSave(String name, String description) async {
    if (_createdDrill != null) {
      final appState = Provider.of<AppStateService>(context, listen: false);
      await appState.createDrillGroup(name, description);
      
      // Get the newly created group and add the drill to it
      final newGroup = appState.savedDrillGroups.last;
      appState.addDrillToGroup(newGroup.id, _createdDrill!);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Created "${name}" and added "${_createdDrill!.title}"'),
          backgroundColor: AppTheme.success,
        ),
      );
      
      Navigator.pop(context); // Close the create drill sheet
    }
  }

  // ✅ UPDATED: Use reusable guest account creation dialog
  void _showGuestAccountPrompt() {
    HapticUtils.mediumImpact();
    GuestAccountCreationDialog.show(
      context: context,
      title: 'Create Account Required',
      description: 'Custom drills are saved to your personal account. Create an account to save and access your drills across all devices.',
      themeColor: AppTheme.primaryYellow,
      icon: Icons.account_circle_outlined,
      showContinueAsGuest: true, // ✅ UPDATED: Show continue as guest option
      continueAsGuestText: 'Continue as Guest',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: const BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.primaryYellow,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: AppTheme.white),
                ),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Create Custom Drill',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'These drills are private to your account',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.white.withOpacity(0.8),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                // ✅ ADDED: Info button with popup explanation
                IconButton(
                  onPressed: _showInfoDialog,
                  icon: const Icon(Icons.info_outline, color: AppTheme.white),
                ),
              ],
            ),
          ),
          
          // Content
          Expanded(
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Basic Information
                    _buildSectionTitle('Basic Information'),
                    const SizedBox(height: 16),
                    
                    TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: 'Drill Title *',
                        hintText: 'Enter drill name',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter a title';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Description *',
                        hintText: 'Describe what this drill accomplishes',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter a description';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    
                    // Skill and Difficulty
                    _buildSectionTitle('Skill & Difficulty'),
                    const SizedBox(height: 16),
                    
                    DropdownButtonFormField<String>(
                      value: _selectedSkill,
                      decoration: const InputDecoration(
                        labelText: 'Primary Skill *',
                        border: OutlineInputBorder(),
                      ),
                      items: _availableSkills.map((skill) {
                        return DropdownMenuItem(
                          value: skill,
                          child: Text(
                            skill,
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedSkill = value!;
                          _subSkills.clear(); // Reset sub-skills when skill changes
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    // Sub-skills
                    if (_skillSubSkills[_selectedSkill] != null) ...[
                      const Text('Sub-skills (Optional):', style: TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: _skillSubSkills[_selectedSkill]!.map((subSkill) {
                          final isSelected = _subSkills.contains(subSkill);
                          return FilterChip(
                            label: Text(subSkill),
                            selected: isSelected,
                            onSelected: (_) => _toggleSubSkill(subSkill),
                            selectedColor: AppTheme.primaryYellow.withOpacity(0.3),
                            checkmarkColor: AppTheme.primaryYellow,
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 16),
                    ],
                    
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _selectedDifficulty,
                            decoration: const InputDecoration(
                              labelText: 'Difficulty *',
                              border: OutlineInputBorder(),
                            ),
                            items: _availableDifficulties.map((difficulty) {
                              return DropdownMenuItem(
                                value: difficulty,
                                child: Text(
                                  difficulty,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                _selectedDifficulty = value!;
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _selectedTrainingStyle,
                            decoration: const InputDecoration(
                              labelText: 'Intensity *',
                              border: OutlineInputBorder(),
                            ),
                            items: _availableTrainingStyles.map((style) {
                              return DropdownMenuItem(
                                value: style,
                                child: Text(
                                  style,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                _selectedTrainingStyle = value!;
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    
                    // Training Parameters
                    _buildSectionTitle('Training Parameters'),
                    const SizedBox(height: 16),
                    
                    Row(
                      children: [
                        // Sets
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Sets', style: TextStyle(fontWeight: FontWeight.w600)),
                              const SizedBox(height: 8),
                              TextFormField(
                                initialValue: _sets.toString(),
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  border: OutlineInputBorder(),
                                  isDense: true,
                                  contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                                ),
                                onChanged: (val) {
                                  final parsed = int.tryParse(val);
                                  if (parsed != null && parsed > 0) {
                                    setState(() => _sets = parsed);
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        // Reps
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Reps', style: TextStyle(fontWeight: FontWeight.w600)),
                              const SizedBox(height: 8),
                              TextFormField(
                                initialValue: _reps.toString(),
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  border: OutlineInputBorder(),
                                  isDense: true,
                                  contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                                ),
                                onChanged: (val) {
                                  final parsed = int.tryParse(val);
                                  if (parsed != null && parsed > 0) {
                                    setState(() => _reps = parsed);
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        // Duration
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Duration (min)', style: TextStyle(fontWeight: FontWeight.w600)),
                              const SizedBox(height: 8),
                              TextFormField(
                                initialValue: _duration.toString(),
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  border: OutlineInputBorder(),
                                  isDense: true,
                                  contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                                ),
                                onChanged: (val) {
                                  final parsed = int.tryParse(val);
                                  if (parsed != null && parsed > 0) {
                                    setState(() => _duration = parsed);
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    
                    // Instructions
                    _buildSectionTitle('Instructions *'),
                    const SizedBox(height: 16),
                    
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _instructionsController,
                            decoration: InputDecoration(
                              labelText: 'Add instruction step',
                              hintText: 'Enter instruction step',
                              border: const OutlineInputBorder(),
                              errorText: _instructions.isEmpty && _hasAttemptedValidation 
                                  ? 'Please add at least one instruction' 
                                  : null,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          onPressed: _addInstruction,
                          icon: const Icon(Icons.add_circle, color: AppTheme.primaryYellow),
                        ),
                      ],
                    ),
                    if (_instructions.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      ..._instructions.asMap().entries.map((entry) {
                        final index = entry.key;
                        final instruction = entry.value;
                        return Card(
                          child: ListTile(
                            title: Text(instruction),
                            trailing: IconButton(
                              onPressed: () => _removeInstruction(index),
                              icon: const Icon(Icons.remove_circle, color: AppTheme.error),
                            ),
                          ),
                        );
                      }),
                    ],
                    const SizedBox(height: 24),
                    
                    // Tips
                    _buildSectionTitle('Tips (Optional)'),
                    const SizedBox(height: 16),
                    
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _tipsController,
                            decoration: const InputDecoration(
                              labelText: 'Add tip',
                              hintText: 'Enter helpful tip',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          onPressed: _addTip,
                          icon: const Icon(Icons.add_circle, color: AppTheme.primaryYellow),
                        ),
                      ],
                    ),
                    if (_tips.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      ..._tips.asMap().entries.map((entry) {
                        final index = entry.key;
                        final tip = entry.value;
                        return Card(
                          child: ListTile(
                            title: Text(tip),
                            trailing: IconButton(
                              onPressed: () => _removeTip(index),
                              icon: const Icon(Icons.remove_circle, color: AppTheme.error),
                            ),
                          ),
                        );
                      }),
                    ],
                    const SizedBox(height: 24),
                    
                    // Equipment
                    _buildSectionTitle('Equipment (Optional)'),
                    const SizedBox(height: 16),
                    
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _equipmentController,
                            decoration: const InputDecoration(
                              labelText: 'Add equipment',
                              hintText: 'Enter equipment needed',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          onPressed: _addEquipment,
                          icon: const Icon(Icons.add_circle, color: AppTheme.primaryYellow),
                        ),
                      ],
                    ),
                    if (_equipment.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      ..._equipment.asMap().entries.map((entry) {
                        final index = entry.key;
                        final equipment = entry.value;
                        return Card(
                          child: ListTile(
                            title: Text(equipment),
                            trailing: IconButton(
                              onPressed: () => _removeEquipment(index),
                              icon: const Icon(Icons.remove_circle, color: AppTheme.error),
                            ),
                          ),
                        );
                      }),
                    ],
                    const SizedBox(height: 24),
                    
                    // Video Upload
                    _buildSectionTitle('Video Upload (Optional)'),
                    const SizedBox(height: 16),
                    
                    // Video picker and preview section
                    if (_isVideoLoading)
                      Container(
                        width: double.infinity,
                        height: 200,
                        decoration: BoxDecoration(
                          color: AppTheme.lightGray,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryYellow),
                              ),
                              SizedBox(height: 12),
                              Text(
                                'Loading video...',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.primaryDark,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    else if (_selectedVideoFile != null && _videoPath != null)
                      // Video preview and remove option
                      Column(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: DrillVideoPlayer(
                                videoUrl: _videoPath!,
                                aspectRatio: 16 / 9,
                                showControls: true,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Icon(
                                Icons.check_circle,
                                color: AppTheme.success,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              const Expanded(
                                child: Text(
                                  'Video selected successfully!',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.success,
                                  ),
                                ),
                              ),
                              TextButton.icon(
                                onPressed: _removeVideo,
                                icon: const Icon(Icons.delete, color: AppTheme.error),
                                label: const Text(
                                  'Remove',
                                  style: TextStyle(color: AppTheme.error),
                                ),
                              ),
                            ],
                          ),
                        ],
                      )
                    else
                      // Video picker button
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: AppTheme.primaryYellow.withOpacity(0.3),
                            width: 2,
                            style: BorderStyle.solid,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          color: AppTheme.primaryYellow.withOpacity(0.05),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Icons.videocam_outlined,
                              size: 48,
                              color: AppTheme.primaryYellow,
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Add a Video of Your Drill',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryDark,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Upload a video from your camera roll to demonstrate your custom drill. This helps you remember the technique!',
                              style: TextStyle(
                                fontSize: 14,
                                color: AppTheme.primaryGray,
                                height: 1.4,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 20),
                            ElevatedButton.icon(
                              onPressed: _pickVideo,
                              icon: const Icon(Icons.upload, color: Colors.white),
                              label: const Text(
                                'Choose Video from Camera Roll',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primaryYellow,
                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 2,
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextButton.icon(
                              onPressed: () {
                                setState(() {
                                  // Skip video for now - this will create drill without video
                                });
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Proceeding without video. You can create the drill and add video later.'),
                                    duration: Duration(seconds: 2),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.skip_next, color: AppTheme.primaryGray),
                              label: const Text(
                                'Skip video for now',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: AppTheme.primaryGray,
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryYellow.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.info_outline,
                                    size: 16,
                                    color: AppTheme.primaryYellow,
                                  ),
                                  const SizedBox(width: 6),
                                  const Text(
                                    'Videos are stored locally on your device',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: AppTheme.primaryDark,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 32),
                    
                    // Create Button
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: BravoButton(
                        text: _isLoading ? 'Creating...' : 'Create Drill',
                        onPressed: _isLoading ? null : _createDrill,
                        color: AppTheme.primaryYellow,
                        backColor: AppTheme.primaryDarkYellow,
                        textColor: AppTheme.white,
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: AppTheme.primaryDark,
      ),
    );
  }

  Widget _buildNumberInput({
    required String label,
    required int value,
    required ValueChanged<int> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Row(
          children: [
            IconButton(
              onPressed: () => onChanged(value - 1),
              icon: const Icon(Icons.remove_circle_outline),
              color: AppTheme.primaryYellow,
              iconSize: 32, // Make button larger
              padding: const EdgeInsets.symmetric(horizontal: 8), // Add horizontal padding
            ),
            const SizedBox(width: 16), // Increase spacing between button and number
            Expanded(
              child: Container(
                alignment: Alignment.center,
                child: Text(
                  value.toString(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold), // Larger font
                ),
              ),
            ),
            const SizedBox(width: 16), // Increase spacing between number and button
            IconButton(
              onPressed: () => onChanged(value + 1),
              icon: const Icon(Icons.add_circle_outline),
              color: AppTheme.primaryYellow,
              iconSize: 32, // Make button larger
              padding: const EdgeInsets.symmetric(horizontal: 8), // Add horizontal padding
            ),
          ],
        ),
      ],
    );
  }
} 