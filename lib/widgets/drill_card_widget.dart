import 'package:flutter/material.dart';
import '../models/drill_model.dart';

class DraggableDrillCard extends StatelessWidget {
  final DrillModel drill;
  final int? sets;
  final int? reps;
  final int? duration;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;
  final bool isDraggable;

  const DraggableDrillCard({
    Key? key,
    required this.drill,
    this.sets,
    this.reps,
    this.duration,
    this.onTap,
    this.onDelete,
    this.isDraggable = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final cardContent = Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Drag handle (only show if draggable)
                if (isDraggable)
                  Container(
                    padding: const EdgeInsets.all(4),
                    margin: const EdgeInsets.only(right: 12),
                    child: Icon(
                      Icons.drag_handle,
                      color: Colors.grey.shade400,
                      size: 20,
                    ),
                  ),
                // Skill indicator
                Container(
                  width: 4,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _getSkillColor(drill.skill),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 12),
                // Drill content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        drill.title,
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.black87,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        drill.skill,
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 12,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${sets ?? drill.sets} sets • ${reps ?? drill.reps} reps • ${duration ?? drill.duration} min',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 11,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ),
                // Action buttons
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (onDelete != null)
                      IconButton(
                        onPressed: onDelete,
                        icon: Icon(
                          Icons.delete_outline,
                          color: Colors.red.shade400,
                          size: 20,
                        ),
                        visualDensity: VisualDensity.compact,
                      ),
                    Icon(
                      Icons.arrow_forward_ios,
                      color: Colors.grey.shade400,
                      size: 16,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );

    // If draggable, wrap with ReorderableDragStartListener
    if (isDraggable) {
      return ReorderableDragStartListener(
        index: 0, // This will be overridden by the ReorderableListView
        child: cardContent,
      );
    }

    return cardContent;
  }

  Color _getSkillColor(String skill) {
    switch (skill.toLowerCase()) {
      case 'passing':
        return Colors.blue;
      case 'shooting':
        return Colors.red;
      case 'dribbling':
        return Colors.green;
      case 'first touch':
        return Colors.purple;
      case 'defending':
        return Colors.orange;
      case 'fitness':
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }
}

class SimpleDrillCard extends StatelessWidget {
  final DrillModel drill;
  final VoidCallback? onTap;
  final VoidCallback? onAdd;

  const SimpleDrillCard({
    Key? key,
    required this.drill,
    this.onTap,
    this.onAdd,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Skill indicator
                Container(
                  width: 4,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _getSkillColor(drill.skill),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                
                const SizedBox(width: 12),
                
                // Drill content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        drill.title,
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.black87,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        drill.skill,
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 12,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${drill.sets} sets • ${drill.reps} reps • ${drill.duration} min',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 11,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Add button
                if (onAdd != null)
                  Container(
                    margin: const EdgeInsets.only(left: 8),
                    child: IconButton(
                      onPressed: onAdd,
                      icon: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF9CC53),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(
                          Icons.add,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                
                // Arrow icon
                const SizedBox(width: 8),
                Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.grey.shade400,
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getSkillColor(String skill) {
    switch (skill.toLowerCase()) {
      case 'passing':
        return Colors.blue;
      case 'shooting':
        return Colors.red;
      case 'dribbling':
        return Colors.green;
      case 'first touch':
        return Colors.purple;
      case 'defending':
        return Colors.orange;
      case 'fitness':
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }
}

class DrillDropTarget extends StatelessWidget {
  final VoidCallback onAccept;
  final Widget child;

  const DrillDropTarget({
    Key? key,
    required this.onAccept,
    required this.child,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DragTarget<DrillModel>(
      onAccept: (drill) => onAccept(),
      builder: (context, candidateData, rejectedData) {
        return Container(
          decoration: BoxDecoration(
            border: candidateData.isNotEmpty
                ? Border.all(color: Colors.blue, width: 2)
                : null,
            borderRadius: BorderRadius.circular(8),
          ),
          child: child,
        );
      },
    );
  }
} 