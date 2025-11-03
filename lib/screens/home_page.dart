import 'package:flutter/material.dart';
// import 'dart:ui';
import 'package:provider/provider.dart';
import '../models/task.dart';
import '../providers/task_provider.dart';
import 'add_task_screen.dart';
import 'task_detail_screen.dart';
import '../widgets/task_list_item.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String _selectedCategory = 'All';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(97, 0, 0, 0),
      body: Container(
        decoration: BoxDecoration(),

        child: Row(
          children: [
            _buildSidebar(context),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: const Color.fromARGB(176, 0, 0, 0),
                  border: Border(
                    left: BorderSide(
                      color: const Color.fromARGB(176, 0, 0, 0),
                      width: 1,
                    ),
                  ),
                ),
                child: Column(
                  children: [
                    _buildAppBar(context),
                    Expanded(
                      child: Consumer<TaskProvider>(
                        builder: (context, taskProvider, child) {
                          final tasks =
                              _selectedCategory == 'All'
                                  ? taskProvider.tasks
                                  : taskProvider.getTasksByCategory(
                                    _selectedCategory,
                                  );

                          if (tasks.isEmpty) {
                            return Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.task_alt,
                                    size: 64,
                                    color: Theme.of(
                                      context,
                                    // ignore: deprecated_member_use
                                    ).colorScheme.primary.withOpacity(0.5),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'No tasks yet',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.titleLarge?.copyWith(
                                      color: Theme.of(
                                        context,
                                      // ignore: deprecated_member_use
                                      ).colorScheme.onSurface.withOpacity(0.7),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Click the + button to add a new task',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodyMedium?.copyWith(
                                      color: Theme.of(
                                        context,
                                      // ignore: deprecated_member_use
                                      ).colorScheme.onSurface.withOpacity(0.5),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }

                          return GridView.builder(
                            padding: const EdgeInsets.all(16),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 3,
                                  childAspectRatio: 1.2,
                                  crossAxisSpacing: 10,
                                  mainAxisSpacing: 10,
                                ),
                            itemCount: tasks.length,
                            itemBuilder: (context, index) {
                              final task = tasks[index];
                              return TaskListItem(
                                task: task,
                                onTap: () => _openTaskDetails(context, task),
                                onLongPress:
                                    () => _showTaskOptions(context, task),
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSidebar(BuildContext context) {
    final taskProvider = Provider.of<TaskProvider>(context);
    final categories = ['All', ...taskProvider.categories];
    final theme = Theme.of(context);

    return ClipRRect(
      child: Container(
        width: 280,
        decoration: BoxDecoration(
          color: const Color.fromARGB(176, 0, 0, 0),
          border: Border(
            right: BorderSide(color: const Color.fromARGB(176, 0, 0, 0), width: 1),
          ),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Text(
                    'Tasks',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: () => _addNewTask(context),
                    tooltip: 'Add Task',
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: categories.length,
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemBuilder: (context, index) {
                  final category = categories[index];
                  return _CategoryListItem(
                    category: category,
                    index: index,
                    isSelected: _selectedCategory == category,
                    onTap: () {
                      setState(() {
                        _selectedCategory = category;
                      });
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    final theme = Theme.of(context);

    return ClipRRect(
      child: Container(
        height: 60,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          //theme.colorScheme.surface,
          border: Border(
            // ignore: deprecated_member_use
            bottom: BorderSide(color: Colors.white.withOpacity(0.06), width: 1),
          ),
        ),
        child: Row(
          children: [
            Text(
              _selectedCategory,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
          ],
        ),
      ),
    );
  }

  void _addNewTask(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddTaskScreen()),
    );
  }

  void _openTaskDetails(BuildContext context, Task task) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => TaskDetailScreen(task: task)),
    );
  }

  void _showTaskOptions(BuildContext context, Task task) {
    final taskProvider = Provider.of<TaskProvider>(context, listen: false);

    showModalBottomSheet(
      context: context,
      builder:
          (context) => ClipRRect(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 20),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
                border: Border(
                  top: BorderSide(
                    // ignore: deprecated_member_use
                    color: Colors.white.withOpacity(0.06),
                    width: 1,
                  ),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildOptionTile(
                    context,
                    icon: Icons.check_circle_outline,
                    title: 'Mark as Completed',
                    onTap: () {
                      taskProvider.updateTaskStatus(
                        task.id,
                        TaskStatus.completed,
                      );
                      Navigator.pop(context);
                    },
                  ),
                  _buildOptionTile(
                    context,
                    icon: Icons.pending_actions,
                    title: 'Mark as In Progress',
                    onTap: () {
                      taskProvider.updateTaskStatus(
                        task.id,
                        TaskStatus.inProgress,
                      );
                      Navigator.pop(context);
                    },
                  ),
                  _buildOptionTile(
                    context,
                    icon: Icons.edit,
                    title: 'Edit Task',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AddTaskScreen(task: task),
                        ),
                      );
                    },
                  ),
                  _buildOptionTile(
                    context,
                    icon: Icons.delete,
                    title: 'Delete Task',
                    isDestructive: true,
                    onTap: () {
                      taskProvider.deleteTask(task.id);
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
            ),
          ),
    );
  }

  Widget _buildOptionTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return ListTile(
      leading: Icon(icon, color: isDestructive ? Colors.red : null),
      title: Text(
        title,
        style: TextStyle(color: isDestructive ? Colors.red : null),
      ),
      onTap: onTap,
    );
  }
}

class _CategoryListItem extends StatefulWidget {
  final String category;
  final int index;
  final bool isSelected;
  final VoidCallback onTap;

  const _CategoryListItem({
    required this.category,
    required this.index,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_CategoryListItem> createState() => _CategoryListItemState();
}

class _CategoryListItemState extends State<_CategoryListItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color:
              widget.isSelected
                  // ignore: deprecated_member_use
                  ? theme.colorScheme.primary.withOpacity(0.15)
                  : _isHovered
                  // ignore: deprecated_member_use
                  ? Colors.white.withOpacity(0.05)
                  : Colors.transparent,
          border: Border.all(
            color:
                widget.isSelected
                    // ignore: deprecated_member_use
                    ? theme.colorScheme.primary.withOpacity(0.3)
                    : _isHovered
                    // ignore: deprecated_member_use
                    ? Colors.white.withOpacity(0.1)
                    : Colors.transparent,
            width: 1,
          ),
          boxShadow:
              widget.isSelected || _isHovered
                  ? [
                    BoxShadow(
                      color:
                          widget.isSelected
                              // ignore: deprecated_member_use
                              ? theme.colorScheme.primary.withOpacity(0.2)
                              // ignore: deprecated_member_use
                              : Colors.white.withOpacity(0.03),
                      blurRadius: 8,
                      spreadRadius: 0,
                    ),
                  ]
                  : null,
        ),
        child: ListTile(
          dense: true,
          leading: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            child: Icon(
              widget.index == 0 ? Icons.inbox : Icons.folder_outlined,
              color:
                  widget.isSelected || _isHovered
                      ? theme.colorScheme.primary
                      // ignore: deprecated_member_use
                      : theme.colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
          title: Text(
            widget.category,
            style: theme.textTheme.bodyLarge?.copyWith(
              color:
                  widget.isSelected || _isHovered
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurface,
              fontWeight: widget.isSelected ? FontWeight.w600 : null,
            ),
          ),
          onTap: widget.onTap,
        ),
      ),
    );
  }
}
