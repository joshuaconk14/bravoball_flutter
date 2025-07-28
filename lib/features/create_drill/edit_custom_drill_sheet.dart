import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../models/drill_model.dart';
import '../../services/custom_drill_service.dart';
import '../../services/app_state_service.dart';
import '../../services/video_file_service.dart'; // ✅ ADDED: Import video file service
import '../../constants/app_theme.dart';
import '../../utils/haptic_utils.dart';
import '../../widgets/bravo_button.dart';
import '../../widgets/drill_video_player.dart';

class EditCustomDrillSheet extends StatefulWidget {
  final DrillModel drill;

  const EditCustomDrillSheet({
    Key? key,
    required this.drill,
  });

  @override
  State<EditCustomDrillSheet> createState() => _EditCustomDrillSheetState();
}

class _EditCustomDrillSheetState extends State<EditCustomDrillSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  final _instructionsController = TextEditingController();
  final _tipsController = TextEditingController();
  final _equipmentController = TextEditingController();

  late String _selectedSkill;
  late String _selectedDifficulty;
  late String _selectedTrainingStyle;
  
  late int _sets;
  late int _reps;
  late int _duration;
  
  late List<String> _subSkills;
  late List<String> _instructions;
  late List<String> _tips;
  late List<String> _equipment;
  
  bool _isLoading = false;
  DrillModel? _updatedDrill;
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
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    // Initialize controllers with existing drill data
    _titleController = TextEditingController(text: widget.drill.title);
    _descriptionController = TextEditingController(text: widget.drill.description);
    
    _selectedSkill = widget.drill.skill;
    _selectedDifficulty = widget.drill.difficulty;
    _selectedTrainingStyle = _mapTrainingStyleToDisplay(widget.drill.trainingStyle);
    
    _sets = widget.drill.sets;
    _reps = widget.drill.reps;
    _duration = widget.drill.duration;
    
    _subSkills = List.from(widget.drill.subSkills);
    _instructions = List.from(widget.drill.instructions);
    _tips = List.from(widget.drill.tips);
    _equipment = List.from(widget.drill.equipment);
    
    _videoPath = widget.drill.videoUrl;
  }

  String _mapTrainingStyleToDisplay(String trainingStyle) {
    if (trainingStyle.toLowerCase().contains('low')) return 'Low';
    if (trainingStyle.toLowerCase().contains('high')) return 'High';
    return 'Medium';
  }

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

  // Video picker methods
  Future<void> _pickVideo() async {
    try {
      setState(() {
        _isVideoLoading = true;
      });

      final video = await _picker.pickVideo(
        source: ImageSource.gallery,
        maxDuration: const Duration(minutes: 1),
      );

      if (video != null) {
        final tempFile = File(video.path);
        final exists = await tempFile.exists();
        
        if (exists) {
          // ✅ UPDATED: Copy temporary file to permanent storage
          final permanentPath = await VideoFileService.instance.copyVideoToPermanentStorage(video.path);
          
          if (permanentPath != null) {
            // ✅ ADDED: Immediately save the video to the backend
            final customDrillService = CustomDrillService.shared;
            final success = await customDrillService.updateCustomDrillVideo(
              widget.drill.id,
              permanentPath,
            );

            if (success) {
              setState(() {
                _selectedVideoFile = File(permanentPath); // Point to permanent file
                _videoPath = permanentPath; // Store permanent path
              });

              // ✅ ADDED: Refresh custom drills in app state so changes are immediate
              final appState = Provider.of<AppStateService>(context, listen: false);
              await appState.refreshCustomDrillsFromBackend();

              HapticUtils.mediumImpact();
              
              // Show success message
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Video updated successfully!'),
                  backgroundColor: Colors.green,
                  duration: Duration(seconds: 2),
                ),
              );
            } else {
              _showErrorMessage('Failed to save video to server. Please try again.');
            }
          } else {
            _showErrorMessage('Failed to save video. Please try again.');
          }
        } else {
          _showErrorMessage('Selected video file not found');
        }
      }
    } catch (e) {
      _showErrorMessage('Error selecting video: ${e.toString()}');
    } finally {
      setState(() {
        _isVideoLoading = false;
      });
    }
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.error,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _updateDrill() async {
    // Custom validation for instructions
    bool hasInstructions = _instructions.isNotEmpty;
    
    setState(() {
      _hasAttemptedValidation = true; // ✅ ADDED: Mark that validation has been attempted
    });
    
    if (!_formKey.currentState!.validate() || !hasInstructions) {
      HapticUtils.mediumImpact();
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final customDrillService = CustomDrillService.shared;
      // ✅ UPDATED: Note that video is already saved separately when user picks it
      final drill = await customDrillService.updateCustomDrill(
        drillId: widget.drill.id,
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
        videoUrl: _videoPath ?? '', // Use current video path (already saved if updated)
      );

      if (drill != null) {
        setState(() {
          _updatedDrill = drill;
        });
        HapticUtils.heavyImpact();
        
        // ✅ ADDED: Refresh custom drills and drill groups so updated drill appears everywhere
        final appState = Provider.of<AppStateService>(context, listen: false);
        await appState.refreshCustomDrillsFromBackend();
        await appState.refreshDrillGroupsFromBackend();
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Drill updated successfully!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
        
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to update drill. Please try again.'),
            backgroundColor: AppTheme.error,
          ),
        );
        HapticUtils.mediumImpact();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating drill: ${e.toString()}'),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black),
          onPressed: () {
            HapticUtils.lightImpact();
            Navigator.pop(context);
          },
        ),
        title: const Text(
          'Edit Drill',
          style: TextStyle(
            color: Colors.black,
            fontFamily: 'Poppins',
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppTheme.primaryYellow,
                ),
              ),
            )
          else
            TextButton(
              onPressed: _updateDrill,
              child: const Text(
                'Save',
                style: TextStyle(
                  color: AppTheme.primaryYellow,
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Drill Title',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a drill title';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 20),
              
              // Description
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
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
              
              const SizedBox(height: 20),
              
              // Skill Selection
              DropdownButtonFormField<String>(
                value: _selectedSkill,
                decoration: const InputDecoration(
                  labelText: 'Primary Skill',
                  border: OutlineInputBorder(),
                ),
                items: _availableSkills.map((skill) {
                  return DropdownMenuItem(
                    value: skill,
                    child: Text(skill),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedSkill = value!;
                    _subSkills.clear();
                  });
                },
              ),
              
              const SizedBox(height: 20),
              
              // Sub-skills
              if (_skillSubSkills[_selectedSkill] != null) ...[
                Text(
                  'Sub-skills (optional)',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _skillSubSkills[_selectedSkill]!.map((subSkill) {
                    final isSelected = _subSkills.contains(subSkill);
                    return FilterChip(
                      label: Text(subSkill),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            _subSkills.add(subSkill);
                          } else {
                            _subSkills.remove(subSkill);
                          }
                        });
                        HapticUtils.lightImpact();
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),
              ],
              
              // Drill Parameters
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Sets'),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<int>(
                          value: _sets,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                          ),
                          items: List.generate(10, (index) => index + 1).map((sets) {
                            return DropdownMenuItem(
                              value: sets,
                              child: Text('$sets'),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _sets = value!;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Reps'),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<int>(
                          value: _reps,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                          ),
                          items: List.generate(20, (index) => (index + 1) * 5).map((reps) {
                            return DropdownMenuItem(
                              value: reps,
                              child: Text('$reps'),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _reps = value!;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Duration (min)'),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<int>(
                          value: _duration,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                          ),
                          items: List.generate(12, (index) => (index + 1) * 5).map((duration) {
                            return DropdownMenuItem(
                              value: duration,
                              child: Text('$duration'),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _duration = value!;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 20),
              
              // Difficulty and Training Style
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _selectedDifficulty,
                      decoration: const InputDecoration(
                        labelText: 'Difficulty',
                        border: OutlineInputBorder(),
                      ),
                      items: _availableDifficulties.map((difficulty) {
                        return DropdownMenuItem(
                          value: difficulty,
                          child: Text(difficulty),
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
                        labelText: 'Training Style',
                        border: OutlineInputBorder(),
                      ),
                      items: _availableTrainingStyles.map((style) {
                        return DropdownMenuItem(
                          value: style,
                          child: Text(style),
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
              
              const SizedBox(height: 20),
              
              // Instructions Section
              Text(
                'Instructions',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _instructionsController,
                      decoration: InputDecoration(
                        hintText: 'Add an instruction step',
                        border: const OutlineInputBorder(),
                        errorText: _instructions.isEmpty && _hasAttemptedValidation 
                            ? 'Please add at least one instruction' 
                            : null,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _addInstruction,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryYellow,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Add'),
                  ),
                ],
              ),
              
              if (_instructions.isNotEmpty) ...[
                const SizedBox(height: 12),
                ...List.generate(_instructions.length, (index) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: AppTheme.getSkillColor(_selectedSkill),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              '${index + 1}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(_instructions[index]),
                        ),
                        IconButton(
                          onPressed: () => _removeInstruction(index),
                          icon: const Icon(Icons.delete, color: Colors.red),
                        ),
                      ],
                    ),
                  );
                }),
              ],
              
              const SizedBox(height: 20),
              
              // Tips Section
              Text(
                'Tips (optional)',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _tipsController,
                      decoration: const InputDecoration(
                        hintText: 'Add a tip',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _addTip,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryYellow,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Add'),
                  ),
                ],
              ),
              
              if (_tips.isNotEmpty) ...[
                const SizedBox(height: 12),
                ...List.generate(_tips.length, (index) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: AppTheme.getSkillColor(_selectedSkill),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(_tips[index]),
                        ),
                        IconButton(
                          onPressed: () => _removeTip(index),
                          icon: const Icon(Icons.delete, color: Colors.red),
                        ),
                      ],
                    ),
                  );
                }),
              ],
              
              const SizedBox(height: 20),
              
              // Equipment Section
              Text(
                'Equipment (optional)',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _equipmentController,
                      decoration: const InputDecoration(
                        hintText: 'Add equipment',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _addEquipment,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryYellow,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Add'),
                  ),
                ],
              ),
              
              if (_equipment.isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _equipment.asMap().entries.map((entry) {
                    final index = entry.key;
                    final item = entry.value;
                    return Chip(
                      label: Text(item),
                      onDeleted: () => _removeEquipment(index),
                      deleteIcon: const Icon(Icons.close, size: 18),
                    );
                  }).toList(),
                ),
              ],
              
              const SizedBox(height: 20),
              
              // Video Section
              Text(
                'Video (optional)',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              
              // Current video preview
              if (_videoPath != null && _videoPath!.isNotEmpty) ...[
                Container(
                  width: double.infinity,
                  height: 200,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: DrillVideoPlayer(
                      videoUrl: _videoPath!,
                      key: ValueKey(_videoPath), // ✅ ADDED: Force rebuild when video changes
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],
              
              // Video picker button
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isVideoLoading ? null : _pickVideo,
                      icon: _isVideoLoading
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.videocam),
                      label: Text(_isVideoLoading ? 'Loading...' : 'Pick Video'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryYellow,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  if (_videoPath != null && _videoPath!.isNotEmpty) ...[
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: () async {
                        // ✅ UPDATED: Immediately remove video from server
                        setState(() {
                          _isVideoLoading = true;
                        });

                        try {
                          final customDrillService = CustomDrillService.shared;
                          final success = await customDrillService.updateCustomDrillVideo(
                            widget.drill.id,
                            '', // Empty string to remove video
                          );

                          if (success) {
                            setState(() {
                              _videoPath = null;
                              _selectedVideoFile = null;
                            });

                            // Refresh custom drills in app state
                            final appState = Provider.of<AppStateService>(context, listen: false);
                            await appState.refreshCustomDrillsFromBackend();

                            HapticUtils.lightImpact();
                            
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Video removed successfully!'),
                                backgroundColor: Colors.green,
                                duration: Duration(seconds: 2),
                              ),
                            );
                          } else {
                            _showErrorMessage('Failed to remove video. Please try again.');
                          }
                        } catch (e) {
                          _showErrorMessage('Error removing video: ${e.toString()}');
                        } finally {
                          setState(() {
                            _isVideoLoading = false;
                          });
                        }
                      },
                      icon: const Icon(Icons.delete),
                      label: const Text('Remove'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ],
              ),
              
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
} 