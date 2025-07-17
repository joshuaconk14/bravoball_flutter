import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/drill_model.dart';
import '../../models/drill_group_model.dart';
import '../../services/custom_drill_service.dart';
import '../../services/app_state_service.dart';
import '../../constants/app_theme.dart';
import '../../utils/haptic_utils.dart';
import '../../widgets/bravo_button.dart';
import '../../widgets/info_popup_widget.dart'; // ✅ ADDED: Import for reusable info popup
import '../../features/onboarding/onboarding_flow.dart'; // ✅ ADDED: Import for navigation to onboarding

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
      });
      HapticUtils.lightImpact();
    }
  }

  void _removeInstruction(int index) {
    setState(() {
      _instructions.removeAt(index);
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
        videoUrl: '', // ✅ UPDATED: No longer collecting video URL from users
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

  // ✅ ADDED: Show guest account prompt for drill creation
  void _showGuestAccountPrompt() {
    HapticUtils.mediumImpact();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(20),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppTheme.primaryYellow.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.account_circle_outlined,
                  size: 50,
                  color: AppTheme.primaryYellow,
                ),
              ),
              const SizedBox(height: 20),
              
              // Title
              const Text(
                'Create Account Required',
                style: TextStyle(
                  fontFamily: AppTheme.fontPoppins,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryDark,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              
              // Description
              const Text(
                'Custom drills are saved to your personal account. Create an account to save and access your drills across all devices.',
                style: TextStyle(
                  fontFamily: AppTheme.fontPoppins,
                  fontSize: 16,
                  color: AppTheme.primaryGray,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              
              // Buttons
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () {
                        HapticUtils.lightImpact();
                        Navigator.pop(context);
                      },
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(
                          fontFamily: AppTheme.fontPoppins,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primaryGray,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: () {
                        HapticUtils.mediumImpact();
                        // ✅ FIXED: Use popUntil to close all dialogs/sheets, then navigate
                        Navigator.popUntil(context, (route) => route.isFirst);
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (context) => const OnboardingFlow()),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryYellow,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                      ),
                      child: const Text(
                        'Create Account',
                        style: TextStyle(
                          fontFamily: AppTheme.fontPoppins,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
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
                const Expanded(
                  child: Text(
                    'Create Custom Drill',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.white,
                    ),
                    textAlign: TextAlign.center,
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
                        Expanded(
                          child: _buildNumberInput(
                            label: 'Sets',
                            value: _sets,
                            onChanged: (value) => setState(() => _sets = value),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildNumberInput(
                            label: 'Reps',
                            value: _reps,
                            onChanged: (value) => setState(() => _reps = value),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildNumberInput(
                            label: 'Duration (min)',
                            value: _duration,
                            onChanged: (value) => setState(() => _duration = value),
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
                              errorText: _instructions.isEmpty && _formKey.currentState?.validate() == false 
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
                    
                    // Video Upload - Coming Soon
                    _buildSectionTitle('Video Upload'),
                    const SizedBox(height: 16),
                    
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppTheme.primaryYellow.withOpacity(0.1),
                            AppTheme.primaryYellow.withOpacity(0.05),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppTheme.primaryYellow.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.videocam_outlined,
                            size: 40,
                            color: AppTheme.primaryYellow,
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Video Upload Coming Soon!',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryDark,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Soon you\'ll be able to record and upload videos of your custom drills to help and share your creativity with the BravoBall community!',
                            style: TextStyle(
                              fontSize: 14,
                              color: AppTheme.primaryGray,
                              height: 1.4,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryYellow.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.rocket_launch,
                                  size: 16,
                                  color: AppTheme.primaryYellow,
                                ),
                                const SizedBox(width: 6),
                                const Text(
                                  'Stay tuned for updates!',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
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
            ),
            Expanded(
              child: Text(
                value.toString(),
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            IconButton(
              onPressed: () => onChanged(value + 1),
              icon: const Icon(Icons.add_circle_outline),
              color: AppTheme.primaryYellow,
            ),
          ],
        ),
      ],
    );
  }
} 