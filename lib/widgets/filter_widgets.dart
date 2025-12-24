import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_theme.dart';
import '../models/filter_models.dart';
import '../services/app_state_service.dart';
import '../utils/haptic_utils.dart';
import '../utils/skill_utils.dart'; // ✅ ADDED: Import centralized skill utilities
import '../utils/preference_utils.dart'; // ✅ ADDED: Import centralized preference utilities
import 'package:flutter/foundation.dart';

class FilterChipWidget extends StatelessWidget {
  final FilterType filterType;
  final String displayText;
  final VoidCallback? onTap;
  final bool isSelected;

  const FilterChipWidget({
    Key? key,
    required this.filterType,
    required this.displayText,
    this.onTap,
    this.isSelected = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bool isDisabled = onTap == null;
    
    return Opacity(
      opacity: isDisabled ? 0.5 : 1.0,
      child: GestureDetector(
        onTap: () {
          if (onTap != null) {
            HapticUtils.lightImpact(); // Light haptic for filter interaction
            onTap!();
          }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.primaryLightBlue : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? AppTheme.primaryLightBlue : Colors.grey.shade300,
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _getFilterIcon(),
              const SizedBox(width: 8),
              Text(
                displayText,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                  color: isSelected ? Colors.white : Colors.grey.shade700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _getFilterIcon() {
    final iconColor = isSelected ? Colors.white : Colors.grey.shade700;
    switch (filterType) {
      case FilterType.time:
        return Icon(Icons.timer, size: 18, color: iconColor);
      case FilterType.equipment:
        return Icon(Icons.sports_soccer, size: 18, color: iconColor);
      case FilterType.trainingStyle:
        return Icon(Icons.sports, size: 18, color: iconColor);
      case FilterType.location:
        return Icon(Icons.location_on, size: 18, color: iconColor);
      case FilterType.difficulty:
        return Icon(Icons.trending_up, size: 18, color: iconColor);
    }
  }
}

class FilterDropdown extends StatelessWidget {
  final FilterType filterType;
  final List<String> options;
  final String title;
  final String? selectedValue;
  final ValueChanged<String?> onChanged;

  const FilterDropdown({
    Key? key,
    required this.filterType,
    required this.options,
    required this.title,
    this.selectedValue,
    required this.onChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Validate that the selected value exists in the options
    final validatedValue = (selectedValue != null && options.contains(selectedValue)) 
        ? selectedValue 
        : null;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButton<String>(
            value: validatedValue,
            hint: Text('Select $title'),
            isExpanded: true,
            underline: Container(),
            onChanged: onChanged,
            items: options.map((String option) {
              return DropdownMenuItem<String>(
                value: option,
                child: Text(
                  PreferenceUtils.formatPreferenceForDisplay(option), // ✅ UPDATED: Use centralized preference formatting
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 14,
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class EquipmentMultiSelect extends StatelessWidget {
  final Set<String> selectedEquipment;
  final ValueChanged<Set<String>> onChanged;

  const EquipmentMultiSelect({
    Key? key,
    required this.selectedEquipment,
    required this.onChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Equipment',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: FilterOptions.equipmentOptions.map((equipment) {
            final isSelected = selectedEquipment.contains(equipment);
            return GestureDetector(
              onTap: () {
                HapticUtils.lightImpact(); // Light haptic for equipment selection
                final newSelection = Set<String>.from(selectedEquipment);
                if (isSelected) {
                  newSelection.remove(equipment);
                } else {
                  newSelection.add(equipment);
                }
                onChanged(newSelection);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? AppTheme.primaryLightBlue : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? AppTheme.primaryLightBlue : Colors.grey.shade300,
                    width: 2,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isSelected)
                      const Icon(
                        Icons.check_circle,
                        color: Colors.white,
                        size: 16,
                      ),
                    if (isSelected) const SizedBox(width: 6),
                    Text(
                      PreferenceUtils.formatEquipmentForDisplay(equipment), // ✅ UPDATED: Use centralized equipment formatting
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 14,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                        color: isSelected ? Colors.white : Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class SkillSelector extends StatelessWidget {
  final Set<String> selectedSkills;
  final ValueChanged<Set<String>> onChanged;

  const SkillSelector({
    Key? key,
    required this.selectedSkills,
    required this.onChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Skills Focus',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: ListView.builder(
            itemCount: SkillCategories.categories.length,
            itemBuilder: (context, index) {
              final category = SkillCategories.categories[index];
              return _buildSkillCategory(category);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSkillCategory(SkillCategory category) {
    // Check if all sub-skills for this category are selected
    final allSelected = category.subSkills.every((subSkill) => selectedSkills.contains(subSkill));
    
    return ExpansionTile(
      title: Text(
        category.name,
        style: const TextStyle(
          fontFamily: 'Poppins',
          fontWeight: FontWeight.w600,
          fontSize: 15,
        ),
      ),
      leading: Icon(
        _getSkillIcon(category.name),
        color: AppTheme.getSkillColor(category.name),
      ),
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 16, right: 16, bottom: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Select All / Deselect All button
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () {
                    HapticUtils.lightImpact(); // Light haptic for select all action
                    final newSelection = Set<String>.from(selectedSkills);
                    
                    if (allSelected) {
                      // Deselect all sub-skills for this category
                      for (final subSkill in category.subSkills) {
                        newSelection.remove(subSkill);
                      }
                    } else {
                      // Select all sub-skills for this category
                      for (final subSkill in category.subSkills) {
                        newSelection.add(subSkill);
                      }
                    }
                    
                    onChanged(newSelection);
                  },
                  icon: Icon(
                    allSelected ? Icons.check_box : Icons.check_box_outline_blank,
                    size: 16,
                    color: AppTheme.primaryLightBlue,
                  ),
                  label: Text(
                    allSelected ? 'Deselect All' : 'Select All',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primaryLightBlue,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              // Sub-skills chips
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: category.subSkills.map((subSkill) {
                  final isSelected = selectedSkills.contains(subSkill);
                  return GestureDetector(
                    onTap: () {
                      HapticUtils.lightImpact(); // Light haptic for sub-skill selection
                      final newSelection = Set<String>.from(selectedSkills);
                      if (isSelected) {
                        newSelection.remove(subSkill);
                      } else {
                        newSelection.add(subSkill);
                      }
                      onChanged(newSelection);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: isSelected ? AppTheme.primaryLightBlue : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected ? AppTheme.primaryLightBlue : Colors.grey.shade300,
                          width: 2,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (isSelected)
                            const Icon(
                              Icons.check_circle,
                              color: Colors.white,
                              size: 14,
                            ),
                          if (isSelected) const SizedBox(width: 4),
                          Text(
                            SkillUtils.formatSkillForDisplay(subSkill), // ✅ UPDATED: Use centralized skill formatting
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 12,
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                              color: isSelected ? Colors.white : Colors.grey.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  IconData _getSkillIcon(String skillName) {
    switch (skillName.toLowerCase()) {
      case 'passing':
        return Icons.arrow_forward;
      case 'shooting':
        return Icons.sports_soccer;
      case 'dribbling':
        return Icons.directions_run;
      case 'first touch':
        return Icons.touch_app;
      case 'defending':
        return Icons.shield;
      case 'goalkeeping':
        return Icons.sports_handball;
      default:
        return Icons.sports;
    }
  }
}

class FilterBottomSheet extends StatefulWidget {
  final FilterType filterType;
  final String? initialValue;
  final Set<String>? initialEquipment;
  final ValueChanged<String?>? onApply;
  final ValueChanged<Set<String>>? onApplyEquipment;

  const FilterBottomSheet({
    Key? key,
    required this.filterType,
    this.initialValue,
    this.initialEquipment,
    this.onApply,
    this.onApplyEquipment,
  }) : super(key: key);

  @override
  State<FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<FilterBottomSheet> {
  late String? _localValue;
  late Set<String> _localEquipment;

  @override
  void initState() {
    super.initState();
    // Initialize local state with initial values
    _localValue = widget.initialValue;
    _localEquipment = widget.initialEquipment != null 
        ? Set<String>.from(widget.initialEquipment!)
        : <String>{};
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 50,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          _buildFilterContent(),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () {
                    HapticUtils.lightImpact(); // Light haptic for cancel
                    Navigator.pop(context);
                  },
                  child: const Text(
                    'Cancel',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    HapticUtils.mediumImpact(); // Medium haptic for apply
                    // Apply changes only when Apply is clicked
                    if (widget.filterType == FilterType.equipment) {
                      widget.onApplyEquipment?.call(_localEquipment);
                    } else {
                      widget.onApply?.call(_localValue);
                    }
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF9CC53),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text(
                    'Apply',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterContent() {
    switch (widget.filterType) {
      case FilterType.time:
        return FilterDropdown(
          filterType: widget.filterType,
          options: FilterOptions.timeOptions,
          title: 'Time',
          selectedValue: _localValue,
          onChanged: (value) {
            setState(() {
              _localValue = value;
            });
          },
        );
      case FilterType.equipment:
        return EquipmentMultiSelect(
          selectedEquipment: _localEquipment,
          onChanged: (equipment) {
            setState(() {
              _localEquipment = equipment;
            });
          },
        );
      case FilterType.trainingStyle:
        return FilterDropdown(
          filterType: widget.filterType,
          options: FilterOptions.trainingStyleOptions,
          title: 'Training Style',
          selectedValue: _localValue,
          onChanged: (value) {
            setState(() {
              _localValue = value;
            });
          },
        );
      case FilterType.location:
        return FilterDropdown(
          filterType: widget.filterType,
          options: FilterOptions.locationOptions,
          title: 'Location',
          selectedValue: _localValue,
          onChanged: (value) {
            setState(() {
              _localValue = value;
            });
          },
        );
      case FilterType.difficulty:
        return FilterDropdown(
          filterType: widget.filterType,
          options: FilterOptions.difficultyOptions,
          title: 'Difficulty',
          selectedValue: _localValue,
          onChanged: (value) {
            setState(() {
              _localValue = value;
            });
          },
        );
    }
  }
}

// Updated helper function to show filter bottom sheet
void showFilterSheet(
  BuildContext context,
  FilterType filterType, {
  String? initialValue,
  Set<String>? initialEquipment,
  ValueChanged<String?>? onApply,
  ValueChanged<Set<String>>? onApplyEquipment,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => FilterBottomSheet(
      filterType: filterType,
      initialValue: initialValue,
      initialEquipment: initialEquipment,
      onApply: onApply,
      onApplyEquipment: onApplyEquipment,
    ),
  );
} 