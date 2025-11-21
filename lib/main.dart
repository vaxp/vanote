import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:window_manager/window_manager.dart';
import 'providers/task_provider.dart';
import 'providers/page_manager.dart';
import 'screens/home_page.dart';
import 'screens/task_detail_screen.dart';
import 'screens/add_task_screen.dart';
import 'venom_layout.dart';
import 'panel/features/diagram/presentation/pages/diagram_editor_page.dart';
import 'utils/theme.dart';
import 'models/task.dart';

void main() async {
  
      // Initialize Flutter bindings first to ensure the binary messenger is ready
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize window manager for desktop controls
  await windowManager.ensureInitialized();

  WindowOptions windowOptions = const WindowOptions(
    size: Size(1000, 700),
    center: true,
    titleBarStyle: TitleBarStyle.hidden, // يخفي شريط مدير النوافذ
  );

  windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
  });

  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  
  // Register adapters
  Hive.registerAdapter(TaskAdapter());
  Hive.registerAdapter(TaskStatusAdapter());
  
  // Open boxes
  await Hive.openBox<Task>('tasks');
  await Hive.openBox<List<String>>('categories');
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => TaskProvider()),
        ChangeNotifierProvider(create: (context) => PageManager()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Task Manager',
      theme: AppTheme.darkTheme,
      home: const MainAppShell(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class MainAppShell extends StatelessWidget {
  const MainAppShell({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<PageManager, TaskProvider>(
      builder: (context, pageManager, taskProvider, _) {
        return MainLayout(
          currentPage: pageManager.currentPage,
          pageData: pageManager.pageData,
        );
      },
    );
  }
}

class MainLayout extends StatefulWidget {
  final PageType currentPage;
  final dynamic pageData;

  const MainLayout({
    super.key,
    required this.currentPage,
    required this.pageData,
  });

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  // Preloaded page instances (static pages that can be created at startup)
  Widget? _homePageInstance;
  Widget? _addTaskPageInstance;
  Widget? _diagramEditorPageInstance;
  List<Widget>? _diagramActions;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();
    // Preload static pages after first frame so we can access context safely
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      _homePageInstance = HomePage(onNavigate: (pageType, {data}) {
        final pageManager = Provider.of<PageManager>(context, listen: false);
        switch (pageType) {
          case PageType.taskDetail:
            pageManager.goToTaskDetail(data);
            break;
          case PageType.addTask:
            pageManager.goToAddTask(task: data);
            break;
          case PageType.diagramEditor:
            pageManager.goToDiagramEditor(data: data);
            break;
          default:
            pageManager.goToHome();
        }
      });

      _addTaskPageInstance = AddTaskScreen(
        task: null,
        onBack: () => Provider.of<PageManager>(context, listen: false).goBack(),
      );

      _diagramEditorPageInstance = DiagramEditorPage(onActionsAvailable: (actions) {
        if (!mounted) return;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          setState(() {
            _diagramActions = actions;
          });
        });
      });

      // Force rebuild so preloaded instances are used
      setState(() {});
    });
  }

  @override
  void didUpdateWidget(MainLayout oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentPage != widget.currentPage) {
      _animationController.reset();
      _animationController.forward();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Widget _buildPageContent() {
    switch (widget.currentPage) {
      case PageType.home:
        return _homePageInstance ?? HomePage(onNavigate: (pageType, {data}) {
          final pageManager = Provider.of<PageManager>(context, listen: false);
          switch (pageType) {
            case PageType.taskDetail:
              pageManager.goToTaskDetail(data);
              break;
            case PageType.addTask:
              pageManager.goToAddTask(task: data);
              break;
            case PageType.diagramEditor:
              pageManager.goToDiagramEditor(data: data);
              break;
            default:
              pageManager.goToHome();
          }
        });
      case PageType.diagramEditor:
        return _diagramEditorPageInstance ?? DiagramEditorPage();
      case PageType.taskDetail:
        return TaskDetailScreen(
          task: widget.pageData,
          onBack: () {
            Provider.of<PageManager>(context, listen: false).goBack();
          },
          onEdit: (task) {
            Provider.of<PageManager>(context, listen: false).goToAddTask(task: task);
          },
        );
      case PageType.addTask:
        // Use preloaded instance for new task, otherwise create instance for editing
        if (widget.pageData == null) {
          return _addTaskPageInstance ?? AddTaskScreen(
            task: null,
            onBack: () {
              Provider.of<PageManager>(context, listen: false).goBack();
            },
          );
        }

        return AddTaskScreen(
          task: widget.pageData,
          onBack: () {
            Provider.of<PageManager>(context, listen: false).goBack();
          },
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    String title = 'VaNote';
    bool showBackButton = false;
    bool showAddButton = false;
    bool showDiagramButton = false;

    switch (widget.currentPage) {
      case PageType.home:
        title = 'VaNote';
        showBackButton = false;
        showAddButton = true;
        showDiagramButton = true;
        break;
      case PageType.taskDetail:
        title = 'TaskDetail';
        showBackButton = true;
        showAddButton = false;
        showDiagramButton = false;
        break;
      case PageType.addTask:
        title = 'AddTask';
        showBackButton = true;
        showAddButton = false;
        showDiagramButton = false;
        break;
      case PageType.diagramEditor:
        title = 'DiagramEditor';
        showBackButton = true;
        showAddButton = false;
        showDiagramButton = false;
        break;
    }

    return VenomScaffold(
      title: title,
      showBackButton: showBackButton,
      showAddButton: showAddButton,
      showDiagramButton: showDiagramButton,
      actions: widget.currentPage == PageType.diagramEditor ? _diagramActions : null,
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: _buildPageContent(),
      ),
    );
  }
}
