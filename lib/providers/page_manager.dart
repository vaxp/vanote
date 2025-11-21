import 'package:flutter/foundation.dart';

enum PageType {
  home,
  taskDetail,
  addTask,
  diagramEditor,
}

class PageManager with ChangeNotifier {
  PageType _currentPage = PageType.home;
  dynamic _pageData; // For passing data like task objects

  PageType get currentPage => _currentPage;
  dynamic get pageData => _pageData;

  void goToHome() {
    _currentPage = PageType.home;
    _pageData = null;
    notifyListeners();
  }

  void goToTaskDetail(dynamic task) {
    _currentPage = PageType.taskDetail;
    _pageData = task;
    notifyListeners();
  }

  void goToAddTask({dynamic task}) {
    _currentPage = PageType.addTask;
    _pageData = task;
    notifyListeners();
  }

  void goToDiagramEditor({dynamic data}) {
    _currentPage = PageType.diagramEditor;
    _pageData = data;
    notifyListeners();
  }

  void goBack() {
    // Always go back to home
    goToHome();
  }
}
