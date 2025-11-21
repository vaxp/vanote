import 'package:flutter/material.dart';
import 'lib/panel/features/diagram/presentation/pages/diagram_editor_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DiagramPro',
      theme: ThemeData(primarySwatch: Colors.teal),
      home: DiagramEditorPage(onActionsAvailable: (_) {}),
    );
  }
}