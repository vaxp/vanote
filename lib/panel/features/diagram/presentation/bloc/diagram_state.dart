import '../../domain/entities/diagram_node.dart';
import '../../domain/entities/diagram_connection.dart';

// Diagram States
abstract class DiagramState {
  const DiagramState();
}

class DiagramInitial extends DiagramState {
  const DiagramInitial();
}

class DiagramLoaded extends DiagramState {
  final List<DiagramNode> nodes;
  final List<DiagramConnection> connections;
  final DiagramNode? selectedNode;
  final List<String> selectedNodeIds; // Multi-select
  final DiagramConnection? selectedConnection;
  final double canvasWidth;
  final double canvasHeight;
  final bool showPropertiesPanel;
  final int historyIndex;
  final int historyLength;
  final double zoomLevel;
  final bool showGrid;
  final bool snapToGrid;
  final double gridSize;
  final String? searchQuery;
  final List<String> searchResults;

  const DiagramLoaded({
    required this.nodes,
    required this.connections,
    this.selectedNode,
    this.selectedNodeIds = const [],
    this.selectedConnection,
    required this.canvasWidth,
    required this.canvasHeight,
    this.showPropertiesPanel = false,
    this.historyIndex = 0,
    this.historyLength = 1,
    this.zoomLevel = 1.0,
    this.showGrid = true,
    this.snapToGrid = false,
    this.gridSize = 30.0,
    this.searchQuery,
    this.searchResults = const [],
  });

  DiagramLoaded copyWith({
    List<DiagramNode>? nodes,
    List<DiagramConnection>? connections,
    DiagramNode? selectedNode,
    List<String>? selectedNodeIds,
    DiagramConnection? selectedConnection,
    double? canvasWidth,
    double? canvasHeight,
    bool? showPropertiesPanel,
    int? historyIndex,
    int? historyLength,
    double? zoomLevel,
    bool? showGrid,
    bool? snapToGrid,
    double? gridSize,
    String? searchQuery,
    List<String>? searchResults,
  }) {
    return DiagramLoaded(
      nodes: nodes ?? this.nodes,
      connections: connections ?? this.connections,
      selectedNode: selectedNode ?? this.selectedNode,
      selectedNodeIds: selectedNodeIds ?? this.selectedNodeIds,
      selectedConnection: selectedConnection ?? this.selectedConnection,
      canvasWidth: canvasWidth ?? this.canvasWidth,
      canvasHeight: canvasHeight ?? this.canvasHeight,
      showPropertiesPanel: showPropertiesPanel ?? this.showPropertiesPanel,
      historyIndex: historyIndex ?? this.historyIndex,
      historyLength: historyLength ?? this.historyLength,
      zoomLevel: zoomLevel ?? this.zoomLevel,
      showGrid: showGrid ?? this.showGrid,
      snapToGrid: snapToGrid ?? this.snapToGrid,
      gridSize: gridSize ?? this.gridSize,
      searchQuery: searchQuery ?? this.searchQuery,
      searchResults: searchResults ?? this.searchResults,
    );
  }
}

class DiagramError extends DiagramState {
  final String message;

  const DiagramError({required this.message});
}
