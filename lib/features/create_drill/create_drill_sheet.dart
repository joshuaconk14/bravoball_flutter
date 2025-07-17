import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/drill_model.dart';
import '../../models/drill_group_model.dart';
import '../../services/custom_drill_service.dart';
import '../../services/app_state_service.dart';
import '../../constants/app_theme.dart';
import '../../utils/haptic_utils.dart';
import '../../widgets/bravo_button.dart';

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
  final _videoUrlController = TextEditingController();

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
    _videoUrlController.dispose();
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
        videoUrl: _videoUrlController.text.trim(),
      );

      if (drill != null) {
        setState(() {
          _createdDrill = drill;
        });
        HapticUtils.heavyImpact();
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
                const SizedBox(width: 48), // Balance the close button
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
                    
                    // Video URL
                    _buildSectionTitle('Video URL (Optional)'),
                    const SizedBox(height: 16),
                    
                    TextField(
                      controller: _videoUrlController,
                      decoration: const InputDecoration(
                        labelText: 'Video URL',
                        hintText: 'Enter video URL (optional)',
                        border: OutlineInputBorder(),
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