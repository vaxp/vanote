import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/task.dart';

class TaskProvider with ChangeNotifier {
  final Box<Task> _tasksBox = Hive.box<Task>('tasks');
  final Box<List<String>> _categoriesBox = Hive.box<List<String>>('categories');
  final Set<String> _categories = {'Personal', 'Work', 'Shopping', 'Others'};

  TaskProvider() {
    _loadCategories();
  }

  List<Task> get tasks => _tasksBox.values.toList();
  Set<String> get categories => Set.unmodifiable(_categories);

  void _loadCategories() {
    final categoriesList = _categoriesBox.get('categories');
    if (categoriesList != null) {
      _categories.addAll(categoriesList);
    } else {
      _saveCategories();
    }
  }

  Future<void> _saveCategories() async {
    await _categoriesBox.put('categories', _categories.toList());
  }

  void addTask(Task task) {
    _tasksBox.put(task.id, task);
    notifyListeners();
  }

  void updateTask(Task task) {
    _tasksBox.put(task.id, task);
    notifyListeners();
  }

  void deleteTask(String taskId) {
    _tasksBox.delete(taskId);
    notifyListeners();
  }

  void addCategory(String category) {
    _categories.add(category);
    _saveCategories();
    notifyListeners();
  }

  List<Task> getTasksByCategory(String category) {
    return _tasksBox.values.where((task) => task.category == category).toList();
  }

  void updateTaskStatus(String taskId, TaskStatus status) {
    final task = _tasksBox.get(taskId);
    if (task != null) {
      final updatedTask = task.copyWith(status: status);
      _tasksBox.put(taskId, updatedTask);
      notifyListeners();
    }
  }
}
