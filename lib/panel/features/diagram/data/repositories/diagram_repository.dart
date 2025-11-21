import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/entities/diagram_node.dart';
import '../../domain/entities/diagram_connection.dart';

class DiagramRepository {
  static const String _diagramKey = 'saved_diagrams';
  static const String _templatesKey = 'saved_templates';

  // Save diagram to JSON file
  Future<String> saveDiagramToFile({
    required List<DiagramNode> nodes,
    required List<DiagramConnection> connections,
    required double canvasWidth,
    required double canvasHeight,
    String? filePath,
  }) async {
    final data = {
      'nodes': nodes.map((n) => n.toJson()).toList(),
      'connections': connections.map((c) => c.toJson()).toList(),
      'canvasWidth': canvasWidth,
      'canvasHeight': canvasHeight,
      'version': '1.0',
      'createdAt': DateTime.now().toIso8601String(),
    };

    final jsonString = jsonEncode(data);
    
    if (filePath != null) {
      final file = File(filePath);
      await file.writeAsString(jsonString);
      return filePath;
    } else {
      // Save to app directory
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/diagram_${DateTime.now().millisecondsSinceEpoch}.json');
      await file.writeAsString(jsonString);
      return file.path;
    }
  }

  // Load diagram from JSON file
  Future<Map<String, dynamic>> loadDiagramFromFile(String filePath) async {
    final file = File(filePath);
    final jsonString = await file.readAsString();
    final data = jsonDecode(jsonString) as Map<String, dynamic>;
    
    return {
      'nodes': (data['nodes'] as List)
          .map((n) => DiagramNode.fromJson(n as Map<String, dynamic>))
          .toList(),
      'connections': (data['connections'] as List)
          .map((c) => DiagramConnection.fromJson(c as Map<String, dynamic>))
          .toList(),
      'canvasWidth': (data['canvasWidth'] as num).toDouble(),
      'canvasHeight': (data['canvasHeight'] as num).toDouble(),
    };
  }

  // Save diagram to local storage (SharedPreferences)
  Future<void> saveDiagramToLocal({
    required List<DiagramNode> nodes,
    required List<DiagramConnection> connections,
    required double canvasWidth,
    required double canvasHeight,
    String name = 'default',
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final data = {
      'nodes': nodes.map((n) => n.toJson()).toList(),
      'connections': connections.map((c) => c.toJson()).toList(),
      'canvasWidth': canvasWidth,
      'canvasHeight': canvasHeight,
    };
    
    await prefs.setString('$_diagramKey:$name', jsonEncode(data));
    
    // Save list of diagram names
    final names = prefs.getStringList('$_diagramKey:_names') ?? [];
    if (!names.contains(name)) {
      names.add(name);
      await prefs.setStringList('$_diagramKey:_names', names);
    }
  }

  // Load diagram from local storage
  Future<Map<String, dynamic>?> loadDiagramFromLocal(String name) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString('$_diagramKey:$name');
    
    if (jsonString == null) {
      return null;
    }
    
    final data = jsonDecode(jsonString) as Map<String, dynamic>;
    
    return {
      'nodes': (data['nodes'] as List)
          .map((n) => DiagramNode.fromJson(n as Map<String, dynamic>))
          .toList(),
      'connections': (data['connections'] as List)
          .map((c) => DiagramConnection.fromJson(c as Map<String, dynamic>))
          .toList(),
      'canvasWidth': (data['canvasWidth'] as num).toDouble(),
      'canvasHeight': (data['canvasHeight'] as num).toDouble(),
    };
  }

  // Get list of saved diagrams
  Future<List<String>> getSavedDiagramNames() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList('$_diagramKey:_names') ?? [];
  }

  // Save as template
  Future<void> saveAsTemplate({
    required List<DiagramNode> nodes,
    required List<DiagramConnection> connections,
    required String templateName,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final data = {
      'nodes': nodes.map((n) => n.toJson()).toList(),
      'connections': connections.map((c) => c.toJson()).toList(),
    };
    
    await prefs.setString('$_templatesKey:$templateName', jsonEncode(data));
    
    // Save list of template names
    final names = prefs.getStringList('$_templatesKey:_names') ?? [];
    if (!names.contains(templateName)) {
      names.add(templateName);
      await prefs.setStringList('$_templatesKey:_names', names);
    }
  }

  // Load template
  Future<Map<String, dynamic>?> loadTemplate(String templateName) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString('$_templatesKey:$templateName');
    
    if (jsonString == null) {
      return null;
    }
    
    final data = jsonDecode(jsonString) as Map<String, dynamic>;
    
    return {
      'nodes': (data['nodes'] as List)
          .map((n) => DiagramNode.fromJson(n as Map<String, dynamic>))
          .toList(),
      'connections': (data['connections'] as List)
          .map((c) => DiagramConnection.fromJson(c as Map<String, dynamic>))
          .toList(),
    };
  }

  // Get list of templates
  Future<List<String>> getTemplateNames() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList('$_templatesKey:_names') ?? [];
  }
}

