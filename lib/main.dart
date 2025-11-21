import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:window_manager/window_manager.dart';
import 'providers/task_provider.dart';
import 'screens/home_page.dart';
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
    ChangeNotifierProvider(
      create: (context) => TaskProvider(),
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
      home: const HomePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}
