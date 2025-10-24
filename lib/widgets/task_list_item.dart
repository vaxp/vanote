import 'package:flutter/material.dart';
// import 'dart:ui';
import '../models/task.dart';

class TaskListItem extends StatefulWidget {
  final Task task;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const TaskListItem({
    super.key,
    required this.task,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  State<TaskListItem> createState() => _TaskListItemState();
}

class _TaskListItemState extends State<TaskListItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          color: _isHovered
              // ignore: deprecated_member_use
              ? Theme.of(context).colorScheme.surface.withOpacity(0.15)
              // ignore: deprecated_member_use
              : Theme.of(context).colorScheme.surface.withOpacity(0.08),
          border: Border.all(
            color: _isHovered
                // ignore: deprecated_member_use
                ? Theme.of(context).colorScheme.primary.withOpacity(0.3)
                // ignore: deprecated_member_use
                : Colors.white.withOpacity(0.06),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: _isHovered
                  // ignore: deprecated_member_use
                  ? Theme.of(context).colorScheme.primary.withOpacity(0.2)
                  // ignore: deprecated_member_use
                  : Colors.black.withOpacity(0.3),
              blurRadius: 20,
              spreadRadius: _isHovered ? 4 : -2,
            ),
            if (_isHovered)
              BoxShadow(
                // ignore: deprecated_member_use
                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                blurRadius: 30,
                spreadRadius: 10,
              ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
        
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: widget.onTap,
                onLongPress: widget.onLongPress,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildStatusIndicator(context),
              const SizedBox(height: 12),
              Text(
                widget.task.title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      decoration: widget.task.status == TaskStatus.completed
                          ? TextDecoration.lineThrough
                          : null,
                      fontSize: 20,
                      height: 1.2,
                    ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              Expanded(
                child: Text(
                  widget.task.description,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    height: 1.5,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      // ignore: deprecated_member_use
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        // ignore: deprecated_member_use
                        color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          // ignore: deprecated_member_use
                          color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                          blurRadius: 8,
                          spreadRadius: 0,
                        ),
                      ],
                    ),
                    child: Text(
                      widget.task.category,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      // ignore: deprecated_member_use
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _getFormattedDate(),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        // ignore: deprecated_member_use
                        color: Colors.white.withOpacity(0.7),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),),),)
    );
  }

  Widget _buildStatusIndicator(BuildContext context) {
    final color = _getStatusColor(context);
    final icon = _getStatusIcon();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        // ignore: deprecated_member_use
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          // ignore: deprecated_member_use
          color: color.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            // ignore: deprecated_member_use
            color: color.withOpacity(0.1),
            blurRadius: 8,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            _getStatusText(),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3,
                ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(BuildContext context) {
    switch (widget.task.status) {
      case TaskStatus.completed:
        return const Color(0xFF4CAF50);
      case TaskStatus.inProgress:
        return const Color(0xFFFF9800);
      case TaskStatus.notStarted:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon() {
    switch (widget.task.status) {
      case TaskStatus.completed:
        return Icons.check_circle;
      case TaskStatus.inProgress:
        return Icons.pending;
      case TaskStatus.notStarted:
        return Icons.circle_outlined;
    }
  }

  String _getStatusText() {
    switch (widget.task.status) {
      case TaskStatus.completed:
        return 'Done';
      case TaskStatus.inProgress:
        return 'In Progress';
      case TaskStatus.notStarted:
        return 'To Do';
    }
  }

  String _getFormattedDate() {
    final now = DateTime.now();
    final difference = now.difference(widget.task.createdAt);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else {
      return '${difference.inDays} days ago';
    }
  }
}