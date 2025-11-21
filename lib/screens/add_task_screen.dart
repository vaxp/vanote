import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/task.dart';
import '../providers/task_provider.dart';

class AddTaskScreen extends StatefulWidget {
  final Task? task;
  final VoidCallback? onBack;

  const AddTaskScreen({super.key, this.task, this.onBack});

  @override
  State<AddTaskScreen> createState() => _AddTaskScreenState();
}

class _AddTaskScreenState extends State<AddTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late String _selectedCategory;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.task?.title);
    _descriptionController = TextEditingController(text: widget.task?.description);
    _selectedCategory = widget.task?.category ?? 'Personal';
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
           backgroundColor: const Color.fromARGB(0, 0, 0, 0),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Title',
                hintText: 'Enter task title',
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a title';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                hintText: 'Enter task description',
              ),
              maxLines: 3,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a description';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            Consumer<TaskProvider>(
              builder: (context, taskProvider, child) {
                return DropdownButtonFormField<String>(
                  dropdownColor: const Color.fromARGB(216, 22, 22, 22),
                  value: _selectedCategory,
                  decoration: const InputDecoration(
                    labelText: 'Category',
                  ),
                  items: taskProvider.categories
                      .map((category) => DropdownMenuItem(
                            value: category,
                            child: Text(category),
                          ))
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _selectedCategory = value;
                      });
                    }
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please select a category';
                    }
                    return null;
                  },
                );
              },
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _saveTask,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),backgroundColor: const Color.fromARGB(174, 31, 31, 31), 
              ),
              child: Text(
                widget.task == null ? 'Add Task' : 'Save Changes',
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _saveTask() {
    if (_formKey.currentState!.validate()) {
      final taskProvider = Provider.of<TaskProvider>(context, listen: false);

      if (widget.task == null) {
        final newTask = Task(
          title: _titleController.text,
          description: _descriptionController.text,
          category: _selectedCategory,
        );
        taskProvider.addTask(newTask);
      } else {
        final updatedTask = widget.task!.copyWith(
          title: _titleController.text,
          description: _descriptionController.text,
          category: _selectedCategory,
        );
        taskProvider.updateTask(updatedTask);
      }

      if (widget.onBack != null) {
        widget.onBack!();
      }
    }
  }
}