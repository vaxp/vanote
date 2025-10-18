import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/task.dart';

class TaskProvider with ChangeNotifier {
  List<Task> _tasks = [];
  final Set<String> _categories = {'Personal', 'Work', 'Shopping', 'Others'};
  static const String _tasksKey = 'tasks';
  static const String _categoriesKey = 'categories';
  final SharedPreferences _prefs;

  TaskProvider(this._prefs) {
    _loadTasks();
    _loadCategories();
  }

  List<Task> get tasks => List.unmodifiable(_tasks);
  Set<String> get categories => Set.unmodifiable(_categories);

  void _loadTasks() {
    final tasksJson = _prefs.getStringList(_tasksKey);
    if (tasksJson != null) {
      _tasks = tasksJson
          .map((taskJson) => Task.fromJson(json.decode(taskJson)))
          .toList();
      notifyListeners();
    }
  }

  void _loadCategories() {
    final categoriesList = _prefs.getStringList(_categoriesKey);
    if (categoriesList != null) {
      _categories.addAll(categoriesList);
      notifyListeners();
    }
  }

  Future<void> _saveTasks() async {
    final tasksJson = _tasks
        .map((task) => json.encode(task.toJson()))
        .toList();
    await _prefs.setStringList(_tasksKey, tasksJson);
  }

  Future<void> _saveCategories() async {
    await _prefs.setStringList(_categoriesKey, _categories.toList());
  }

  void addTask(Task task) {
    _tasks.add(task);
    _saveTasks();
    notifyListeners();
  }

  void updateTask(Task task) {
    final index = _tasks.indexWhere((t) => t.id == task.id);
    if (index != -1) {
      _tasks[index] = task;
      _saveTasks();
      notifyListeners();
    }
  }

  void deleteTask(String taskId) {
    _tasks.removeWhere((task) => task.id == taskId);
    _saveTasks();
    notifyListeners();
  }

  void addCategory(String category) {
    _categories.add(category);
    _saveCategories();
    notifyListeners();
  }

  List<Task> getTasksByCategory(String category) {
    return _tasks.where((task) => task.category == category).toList();
  }

  void updateTaskStatus(String taskId, TaskStatus status) {
    final index = _tasks.indexWhere((task) => task.id == taskId);
    if (index != -1) {
      final task = _tasks[index];
      _tasks[index] = task.copyWith(status: status);
      _saveTasks();
      notifyListeners();
    }
  }
}