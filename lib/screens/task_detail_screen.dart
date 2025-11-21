import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vanote/venom_layout.dart';
import '../models/task.dart';
import '../providers/task_provider.dart';

class TaskDetailScreen extends StatelessWidget {
  final Task task;

  const TaskDetailScreen({super.key, required this.task});

  @override
  Widget build(BuildContext context) {
    return VenomScaffold(
      title: "TaskDetail",
      showBackButton: true,
      body: ListView(

        padding: const EdgeInsets.all(16),
        children: [
          Card(
            color: const Color.fromARGB(176, 0, 0, 0),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.title,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 8),
                  _buildStatusChip(context),
                  const SizedBox(height: 16),
                  Text(
                    'Description',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    task.description,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Icon(
                        Icons.category,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Category: ${task.category}',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Created: ${_getFormattedDate(task.createdAt)}',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                  if (task.updatedAt != null) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.update,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Last modified: ${_getFormattedDate(task.updatedAt!)}',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          _buildActionButtons(context),
        ],
      ),
    );
  }

  Widget _buildStatusChip(BuildContext context) {
    Color color;
    String text;
    IconData icon;

    switch (task.status) {
      case TaskStatus.completed:
        color = Colors.green;
        text = 'Completed';
        icon = Icons.check_circle;
        break;
      case TaskStatus.inProgress:
        color = Colors.orange;
        text = 'In Progress';
        icon = Icons.pending;
        break;
      case TaskStatus.notStarted:
        color = Colors.grey;
        text = 'Not Started';
        icon = Icons.circle_outlined;
        break;
    }

    return Chip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(color: color),
          ),
        ],
      ),
      backgroundColor: const Color.fromARGB(176, 0, 0, 0), 
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Consumer<TaskProvider>(
      builder: (context, taskProvider, child) {
        return Column(
          
          children: [
            if (task.status != TaskStatus.completed)
              ElevatedButton.icon(
                onPressed: () {
                  taskProvider.updateTaskStatus(task.id, TaskStatus.completed);
                  Navigator.pop(context);
                },
                icon: const Icon(Icons.check_circle),
                label: const Text('Mark as Completed'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(176, 0, 0, 0),
                  minimumSize: const Size(double.infinity, 48),
                ),
              ),
            if (task.status != TaskStatus.inProgress)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: ElevatedButton.icon(
                  onPressed: () {
                    taskProvider.updateTaskStatus(task.id, TaskStatus.inProgress);
                    Navigator.pop(context);
                  },
                  icon: const Icon(Icons.pending),
                  label: const Text('Mark as In Progress'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 48),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  String _getFormattedDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} at ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}