import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:async';
import 'dart:math' as math;
import '../../domain/entities/diagram_node.dart';
import '../../domain/entities/diagram_connection.dart';
import '../../data/repositories/diagram_repository.dart';
import 'diagram_event.dart';
import 'diagram_state.dart';
import 'diagram_history_state.dart';

class DiagramBloc extends Bloc<DiagramEvent, DiagramState> {
  final DiagramRepository _repository = DiagramRepository();
  
  List<DiagramNode> _nodes = [];
  List<DiagramConnection> _connections = [];
  DiagramNode? _selectedNode;
  List<String> _selectedNodeIds = [];
  DiagramConnection? _selectedConnection;
  double _canvasWidth = 50000;
  double _canvasHeight = 50000;
  bool _showPropertiesPanel = false;
  double _zoomLevel = 1.0;
  bool _showGrid = true;
  bool _snapToGrid = false;
  double _gridSize = 30.0;
  
  // History with both nodes and connections
  final List<DiagramHistoryState> _history = [];
  int _historyIndex = -1;
  
  // Clipboard for copy/paste
  List<DiagramNode> _clipboardNodes = [];
  List<DiagramConnection> _clipboardConnections = [];
  Offset _clipboardOffset = Offset.zero;

  DiagramBloc() : super(const DiagramInitial()) {
    // Core events
    on<LoadDemoDiagramEvent>(_onLoadDemoDiagram);
    on<AddNodeEvent>(_onAddNode);
    on<DeleteNodeEvent>(_onDeleteNode);
    on<SelectNodeEvent>(_onSelectNode);
    on<UpdateNodeEvent>(_onUpdateNode);
    on<CreateConnectionEvent>(_onCreateConnection);
    on<DeleteConnectionEvent>(_onDeleteConnection);
    on<SetCanvasSizeEvent>(_onSetCanvasSize);
    on<UndoEvent>(_onUndo);
    on<RedoEvent>(_onRedo);
    on<ShowPropertiesPanelEvent>(_onShowPropertiesPanel);
    
    // Connection events
    on<SelectConnectionEvent>(_onSelectConnection);
    on<UpdateConnectionEvent>(_onUpdateConnection);
    
    // Multi-select events
    on<SelectMultipleNodesEvent>(_onSelectMultipleNodes);
    on<ClearSelectionEvent>(_onClearSelection);
    
    // Copy/Paste events
    on<CopySelectedEvent>(_onCopySelected);
    on<PasteEvent>(_onPaste);
    on<DuplicateSelectedEvent>(_onDuplicateSelected);
    
    // Alignment events
    on<AlignNodesEvent>(_onAlignNodes);
    on<NudgeNodesEvent>(_onNudgeNodes);
    
    // Save/Load events
    on<SaveDiagramEvent>(_onSaveDiagram);
    on<LoadDiagramEvent>(_onLoadDiagram);
    
    // Export events
    on<ExportDiagramEvent>(_onExportDiagram);
    
    // Search events
    on<SearchNodesEvent>(_onSearchNodes);
    on<NavigateToNodeEvent>(_onNavigateToNode);
    
    // Zoom events
    on<ZoomInEvent>(_onZoomIn);
    on<ZoomOutEvent>(_onZoomOut);
    on<ZoomToFitEvent>(_onZoomToFit);
    on<SetZoomEvent>(_onSetZoom);
    
    // Grid events
    on<ToggleGridEvent>(_onToggleGrid);
    on<ToggleSnapToGridEvent>(_onToggleSnapToGrid);
    on<SetGridSizeEvent>(_onSetGridSize);
    
    // Template events
    on<LoadTemplateEvent>(_onLoadTemplate);
    on<SaveAsTemplateEvent>(_onSaveAsTemplate);
  }


  void _saveHistory() {
    // Remove future history if we're not at the end
    if (_historyIndex < _history.length - 1) {
      _history.removeRange(_historyIndex + 1, _history.length);
    }
    
    _history.add(DiagramHistoryState(
      nodes: _nodes.map((n) => _copyNode(n)).toList(),
      connections: _connections.map((c) => _copyConnection(c)).toList(),
    ));
    
    _historyIndex++;
    
    // Limit history size to 50
    if (_history.length > 50) {
      _history.removeAt(0);
      _historyIndex--;
    }
  }

  DiagramNode _copyNode(DiagramNode node) {
    return DiagramNode(
      id: node.id,
      position: node.position,
      content: node.content,
      color: node.color,
      shapeType: node.shapeType,
      width: node.width,
      height: node.height,
      fontFamily: node.fontFamily,
      fontSize: node.fontSize,
      isBold: node.isBold,
      isItalic: node.isItalic,
      isUnderlined: node.isUnderlined,
      textColor: node.textColor,
    );
  }

  DiagramConnection _copyConnection(DiagramConnection conn) {
    return DiagramConnection(
      id: conn.id,
      fromNodeId: conn.fromNodeId,
      toNodeId: conn.toNodeId,
      label: conn.label,
      color: conn.color,
      strokeWidth: conn.strokeWidth,
      hasArrow: conn.hasArrow,
      style: conn.style,
      labelPosition: conn.labelPosition,
    );
  }

  void _emitLoaded(Emitter<DiagramState> emit) {
    emit(
      DiagramLoaded(
        nodes: List.from(_nodes),
        connections: List.from(_connections),
        selectedNode: _selectedNode,
        selectedNodeIds: List.from(_selectedNodeIds),
        selectedConnection: _selectedConnection,
        canvasWidth: _canvasWidth,
        canvasHeight: _canvasHeight,
        showPropertiesPanel: _showPropertiesPanel,
        historyIndex: _historyIndex,
        historyLength: _history.length,
        zoomLevel: _zoomLevel,
        showGrid: _showGrid,
        snapToGrid: _snapToGrid,
        gridSize: _gridSize,
      ),
    );
  }

  Offset _snapPosition(Offset position) {
    if (!_snapToGrid) return position;
    return Offset(
      (position.dx / _gridSize).round() * _gridSize,
      (position.dy / _gridSize).round() * _gridSize,
    );
  }

  // Event handlers
  Future<void> _onLoadDemoDiagram(
    LoadDemoDiagramEvent event,
    Emitter<DiagramState> emit,
  ) async {
    _nodes = [
      DiagramNode(
        id: '1',
        position: const Offset(150, 50),
        content: 'Start',
        color: const Color(0xFF4CAF50),
        shapeType: ShapeType.roundedRect,
        width: 200,
        height: 80,
      ),
      DiagramNode(
        id: '2',
        position: const Offset(100, 250),
        content: 'Planning',
        color: const Color(0xFF2196F3),
        shapeType: ShapeType.rectangle,
        width: 200,
        height: 100,
      ),
      DiagramNode(
        id: '3',
        position: const Offset(450, 250),
        content: 'Development',
        color: const Color(0xFF2196F3),
        shapeType: ShapeType.rectangle,
        width: 220,
        height: 100,
      ),
      DiagramNode(
        id: '4',
        position: const Offset(850, 250),
        content: 'Testing',
        color: const Color(0xFF2196F3),
        shapeType: ShapeType.rectangle,
        width: 200,
        height: 100,
      ),
      DiagramNode(
        id: '5',
        position: const Offset(500, 500),
        content: 'Deploy',
        color: const Color(0xFFFF9800),
        shapeType: ShapeType.diamond,
        width: 240,
        height: 140,
      ),
    ];

    _connections = [
      DiagramConnection(
        id: 'c1',
        fromNodeId: '1',
        toNodeId: '2',
        label: 'Start',
      ),
      DiagramConnection(
        id: 'c2',
        fromNodeId: '2',
        toNodeId: '3',
        label: 'Plan',
      ),
      DiagramConnection(
        id: 'c3',
        fromNodeId: '3',
        toNodeId: '4',
        label: 'Build',
      ),
      DiagramConnection(
        id: 'c4',
        fromNodeId: '4',
        toNodeId: '5',
        label: 'Test',
      ),
    ];

    _selectedNode = null;
    _selectedNodeIds = [];
    _selectedConnection = null;
    _saveHistory();
    _emitLoaded(emit);
  }

  Future<void> _onAddNode(
    AddNodeEvent event,
    Emitter<DiagramState> emit,
  ) async {
    final newNode = DiagramNode(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      position: _snapPosition(const Offset(400, 300)),
      content: event.type,
      shapeType: _parseShapeType(event.shapeType),
    );
    _nodes.add(newNode);
    _saveHistory();
    _emitLoaded(emit);
  }

  Future<void> _onDeleteNode(
    DeleteNodeEvent event,
    Emitter<DiagramState> emit,
  ) async {
    _nodes.removeWhere((n) => n.id == event.nodeId);
    _connections.removeWhere((c) =>
      c.fromNodeId == event.nodeId ||
      c.toNodeId == event.nodeId
    );
    if (_selectedNode?.id == event.nodeId) {
      _selectedNode = null;
      _showPropertiesPanel = false;
    }
    _selectedNodeIds.remove(event.nodeId);
    _saveHistory();
    _emitLoaded(emit);
  }

  Future<void> _onSelectNode(
    SelectNodeEvent event,
    Emitter<DiagramState> emit,
  ) async {
    if (event.nodeId == null) {
      _selectedNode = null;
      _selectedNodeIds = [];
      _showPropertiesPanel = false;
    } else {
      _selectedNode = _nodes.firstWhere((n) => n.id == event.nodeId);
      _selectedNodeIds = [event.nodeId!];
      _selectedConnection = null;
    }
    _emitLoaded(emit);
  }

  Future<void> _onUpdateNode(
    UpdateNodeEvent event,
    Emitter<DiagramState> emit,
  ) async {
    final nodeIndex = _nodes.indexWhere((n) => n.id == event.nodeId);
    if (nodeIndex != -1) {
      final node = _nodes[nodeIndex];
      var newPosition = event.position ?? node.position;
      if (event.position != null) {
        newPosition = _snapPosition(newPosition);
      }
      
      _nodes[nodeIndex] = node.copyWith(
        content: event.content,
        position: newPosition,
        width: event.width,
        height: event.height,
        fontFamily: event.fontFamily,
        fontSize: event.fontSize,
        color: event.color,
        shapeType: event.shapeType != null ? _parseShapeType(event.shapeType!) : null,
        isBold: event.isBold,
        isItalic: event.isItalic,
        isUnderlined: event.isUnderlined,
        textColor: event.textColor,
      );
      _selectedNode = _nodes[nodeIndex];
      _saveHistory();
    }
    _emitLoaded(emit);
  }

  Future<void> _onCreateConnection(
    CreateConnectionEvent event,
    Emitter<DiagramState> emit,
  ) async {
    // Check if connection already exists
    final exists = _connections.any((c) =>
      (c.fromNodeId == event.fromNodeId && c.toNodeId == event.toNodeId) ||
      (c.fromNodeId == event.toNodeId && c.toNodeId == event.fromNodeId)
    );
    
    if (!exists) {
      final conn = DiagramConnection(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        fromNodeId: event.fromNodeId,
        toNodeId: event.toNodeId,
      );
      _connections.add(conn);
      _saveHistory();
    }
    _emitLoaded(emit);
  }

  Future<void> _onDeleteConnection(
    DeleteConnectionEvent event,
    Emitter<DiagramState> emit,
  ) async {
    _connections.removeWhere((c) => c.id == event.connectionId);
    if (_selectedConnection?.id == event.connectionId) {
      _selectedConnection = null;
      _showPropertiesPanel = false;
    }
    _saveHistory();
    _emitLoaded(emit);
  }

  Future<void> _onSetCanvasSize(
    SetCanvasSizeEvent event,
    Emitter<DiagramState> emit,
  ) async {
    _canvasWidth = event.width;
    _canvasHeight = event.height;
    _emitLoaded(emit);
  }

  Future<void> _onUndo(
    UndoEvent event,
    Emitter<DiagramState> emit,
  ) async {
    if (_historyIndex > 0) {
      _historyIndex--;
      final historyState = _history[_historyIndex];
      _nodes = historyState.nodes.map((n) => _copyNode(n)).toList();
      _connections = historyState.connections.map((c) => _copyConnection(c)).toList();
      _selectedNode = null;
      _selectedNodeIds = [];
      _selectedConnection = null;
      _showPropertiesPanel = false;
    }
    _emitLoaded(emit);
  }

  Future<void> _onRedo(
    RedoEvent event,
    Emitter<DiagramState> emit,
  ) async {
    if (_historyIndex < _history.length - 1) {
      _historyIndex++;
      final historyState = _history[_historyIndex];
      _nodes = historyState.nodes.map((n) => _copyNode(n)).toList();
      _connections = historyState.connections.map((c) => _copyConnection(c)).toList();
      _selectedNode = null;
      _selectedNodeIds = [];
      _selectedConnection = null;
      _showPropertiesPanel = false;
    }
    _emitLoaded(emit);
  }

  Future<void> _onShowPropertiesPanel(
    ShowPropertiesPanelEvent event,
    Emitter<DiagramState> emit,
  ) async {
    _showPropertiesPanel = event.show;
    _emitLoaded(emit);
  }

  // Connection handlers
  Future<void> _onSelectConnection(
    SelectConnectionEvent event,
    Emitter<DiagramState> emit,
  ) async {
    if (event.connectionId == null) {
      _selectedConnection = null;
      _showPropertiesPanel = false;
    } else {
      _selectedConnection = _connections.firstWhere((c) => c.id == event.connectionId);
      _selectedNode = null;
      _selectedNodeIds = [];
    }
    _emitLoaded(emit);
  }

  Future<void> _onUpdateConnection(
    UpdateConnectionEvent event,
    Emitter<DiagramState> emit,
  ) async {
    final connIndex = _connections.indexWhere((c) => c.id == event.connectionId);
    if (connIndex != -1) {
      final conn = _connections[connIndex];
      _connections[connIndex] = conn.copyWith(
        label: event.label,
        color: event.color,
        strokeWidth: event.strokeWidth,
        hasArrow: event.hasArrow,
        style: event.style != null ? _parseConnectionStyle(event.style!) : null,
        labelPosition: event.labelPosition,
      );
      _selectedConnection = _connections[connIndex];
      _saveHistory();
    }
    _emitLoaded(emit);
  }

  // Multi-select handlers
  Future<void> _onSelectMultipleNodes(
    SelectMultipleNodesEvent event,
    Emitter<DiagramState> emit,
  ) async {
    if (event.addToSelection) {
      _selectedNodeIds.addAll(event.nodeIds.where((id) => !_selectedNodeIds.contains(id)));
    } else {
      _selectedNodeIds = List.from(event.nodeIds);
    }
    
    if (_selectedNodeIds.length == 1) {
      _selectedNode = _nodes.firstWhere((n) => n.id == _selectedNodeIds.first);
    } else {
      _selectedNode = null;
    }
    _selectedConnection = null;
    _emitLoaded(emit);
  }

  Future<void> _onClearSelection(
    ClearSelectionEvent event,
    Emitter<DiagramState> emit,
  ) async {
    _selectedNode = null;
    _selectedNodeIds = [];
    _selectedConnection = null;
    _showPropertiesPanel = false;
    _emitLoaded(emit);
  }

  // Copy/Paste handlers
  Future<void> _onCopySelected(
    CopySelectedEvent event,
    Emitter<DiagramState> emit,
  ) async {
    if (_selectedNodeIds.isEmpty && _selectedNode == null) {
      return;
    }
    
    final idsToCopy = _selectedNodeIds.isNotEmpty ? _selectedNodeIds : [_selectedNode!.id];
    _clipboardNodes = _nodes
        .where((n) => idsToCopy.contains(n.id))
        .map((n) => _copyNode(n))
        .toList();
    
    // Copy connections between selected nodes
    _clipboardConnections = _connections
        .where((c) => idsToCopy.contains(c.fromNodeId) && idsToCopy.contains(c.toNodeId))
        .map((c) => _copyConnection(c))
        .toList();
    
    // Calculate center offset for paste positioning
    if (_clipboardNodes.isNotEmpty) {
      final minX = _clipboardNodes.map((n) => n.position.dx).reduce(math.min);
      final minY = _clipboardNodes.map((n) => n.position.dy).reduce(math.min);
      _clipboardOffset = Offset(minX, minY);
    }
    
    _emitLoaded(emit);
  }

  Future<void> _onPaste(
    PasteEvent event,
    Emitter<DiagramState> emit,
  ) async {
    if (_clipboardNodes.isEmpty) return;
    
    final pasteOffset = event.position ?? const Offset(50, 50);
    final offsetDelta = pasteOffset - _clipboardOffset;
    
    final newNodes = <DiagramNode>[];
    final nodeIdMap = <String, String>{};
    
    // Create new nodes with new IDs
    for (final node in _clipboardNodes) {
      final newId = DateTime.now().millisecondsSinceEpoch.toString() + '_${newNodes.length}';
      nodeIdMap[node.id] = newId;
      newNodes.add(_copyNode(node).copyWith(
        id: newId,
        position: _snapPosition(node.position + offsetDelta),
      ));
    }
    
    // Create new connections with new IDs
    final newConnections = <DiagramConnection>[];
    for (final conn in _clipboardConnections) {
      final newFromId = nodeIdMap[conn.fromNodeId];
      final newToId = nodeIdMap[conn.toNodeId];
      if (newFromId != null && newToId != null) {
        newConnections.add(_copyConnection(conn).copyWith(
          id: DateTime.now().millisecondsSinceEpoch.toString() + '_${newConnections.length}',
          fromNodeId: newFromId,
          toNodeId: newToId,
        ));
      }
    }
    
    _nodes.addAll(newNodes);
    _connections.addAll(newConnections);
    _selectedNodeIds = newNodes.map((n) => n.id).toList();
    _selectedNode = newNodes.isNotEmpty ? newNodes.first : null;
    _saveHistory();
    _emitLoaded(emit);
  }

  Future<void> _onDuplicateSelected(
    DuplicateSelectedEvent event,
    Emitter<DiagramState> emit,
  ) async {
    await _onCopySelected(const CopySelectedEvent(), emit);
    await _onPaste(const PasteEvent(), emit);
  }

  // Alignment handlers
  Future<void> _onAlignNodes(
    AlignNodesEvent event,
    Emitter<DiagramState> emit,
  ) async {
    if (_selectedNodeIds.length < 2) return;
    
    final selectedNodes = _nodes.where((n) => _selectedNodeIds.contains(n.id)).toList();
    if (selectedNodes.isEmpty) return;
    
    switch (event.alignmentType) {
      case AlignmentType.left:
        final minX = selectedNodes.map((n) => n.position.dx).reduce(math.min);
        for (final node in selectedNodes) {
          final index = _nodes.indexWhere((n) => n.id == node.id);
          if (index != -1) {
            _nodes[index] = node.copyWith(position: _snapPosition(Offset(minX, node.position.dy)));
          }
        }
        break;
      case AlignmentType.right:
        final maxX = selectedNodes.map((n) => n.position.dx + n.width).reduce(math.max);
        for (final node in selectedNodes) {
          final index = _nodes.indexWhere((n) => n.id == node.id);
          if (index != -1) {
            _nodes[index] = node.copyWith(position: _snapPosition(Offset(maxX - node.width, node.position.dy)));
          }
        }
        break;
      case AlignmentType.center:
        final avgX = selectedNodes.map((n) => n.position.dx + n.width / 2).reduce((a, b) => a + b) / selectedNodes.length;
        for (final node in selectedNodes) {
          final index = _nodes.indexWhere((n) => n.id == node.id);
          if (index != -1) {
            _nodes[index] = node.copyWith(position: _snapPosition(Offset(avgX - node.width / 2, node.position.dy)));
          }
        }
        break;
      case AlignmentType.top:
        final minY = selectedNodes.map((n) => n.position.dy).reduce(math.min);
        for (final node in selectedNodes) {
          final index = _nodes.indexWhere((n) => n.id == node.id);
          if (index != -1) {
            _nodes[index] = node.copyWith(position: _snapPosition(Offset(node.position.dx, minY)));
          }
        }
        break;
      case AlignmentType.bottom:
        final maxY = selectedNodes.map((n) => n.position.dy + n.height).reduce(math.max);
        for (final node in selectedNodes) {
          final index = _nodes.indexWhere((n) => n.id == node.id);
          if (index != -1) {
            _nodes[index] = node.copyWith(position: _snapPosition(Offset(node.position.dx, maxY - node.height)));
          }
        }
        break;
      case AlignmentType.distributeH:
        selectedNodes.sort((a, b) => a.position.dx.compareTo(b.position.dx));
        final minX = selectedNodes.first.position.dx;
        final maxX = selectedNodes.last.position.dx + selectedNodes.last.width;
        final totalWidth = maxX - minX;
        final nodeWidths = selectedNodes.map((n) => n.width).reduce((a, b) => a + b);
        final spacing = (totalWidth - nodeWidths) / (selectedNodes.length - 1);
        double currentX = minX;
        for (final node in selectedNodes) {
          final index = _nodes.indexWhere((n) => n.id == node.id);
          if (index != -1) {
            _nodes[index] = node.copyWith(position: _snapPosition(Offset(currentX, node.position.dy)));
            currentX += node.width + spacing;
          }
        }
        break;
      case AlignmentType.distributeV:
        selectedNodes.sort((a, b) => a.position.dy.compareTo(b.position.dy));
        final minY = selectedNodes.first.position.dy;
        final maxY = selectedNodes.last.position.dy + selectedNodes.last.height;
        final totalHeight = maxY - minY;
        final nodeHeights = selectedNodes.map((n) => n.height).reduce((a, b) => a + b);
        final spacing = (totalHeight - nodeHeights) / (selectedNodes.length - 1);
        double currentY = minY;
        for (final node in selectedNodes) {
          final index = _nodes.indexWhere((n) => n.id == node.id);
          if (index != -1) {
            _nodes[index] = node.copyWith(position: _snapPosition(Offset(node.position.dx, currentY)));
            currentY += node.height + spacing;
          }
        }
        break;
    }
    
    _saveHistory();
    _emitLoaded(emit);
  }

  Future<void> _onNudgeNodes(
    NudgeNodesEvent event,
    Emitter<DiagramState> emit,
  ) async {
    final idsToNudge = _selectedNodeIds.isNotEmpty ? _selectedNodeIds : 
                       (_selectedNode != null ? [_selectedNode!.id] : []);
    
    for (final nodeId in idsToNudge) {
      final index = _nodes.indexWhere((n) => n.id == nodeId);
      if (index != -1) {
        final node = _nodes[index];
        _nodes[index] = node.copyWith(
          position: _snapPosition(node.position + event.offset),
        );
      }
    }
    
    if (idsToNudge.isNotEmpty) {
      _selectedNode = _nodes.firstWhere((n) => n.id == idsToNudge.first);
      _saveHistory();
    }
    _emitLoaded(emit);
  }

  // Save/Load handlers
  Future<void> _onSaveDiagram(
    SaveDiagramEvent event,
    Emitter<DiagramState> emit,
  ) async {
    try {
      if (event.filePath != null) {
        await _repository.saveDiagramToFile(
          nodes: _nodes,
          connections: _connections,
          canvasWidth: _canvasWidth,
          canvasHeight: _canvasHeight,
          filePath: event.filePath,
        );
      } else {
        await _repository.saveDiagramToLocal(
          nodes: _nodes,
          connections: _connections,
          canvasWidth: _canvasWidth,
          canvasHeight: _canvasHeight,
        );
      }
    } catch (e) {
      emit(DiagramError(message: 'Failed to save diagram: $e'));
    }
    _emitLoaded(emit);
  }

  Future<void> _onLoadDiagram(
    LoadDiagramEvent event,
    Emitter<DiagramState> emit,
  ) async {
    try {
      Map<String, dynamic>? data;
      if (event.filePath != null) {
        data = await _repository.loadDiagramFromFile(event.filePath!);
      } else {
        data = await _repository.loadDiagramFromLocal('default');
      }
      
      if (data != null) {
        _nodes = data['nodes'] as List<DiagramNode>;
        _connections = data['connections'] as List<DiagramConnection>;
        _canvasWidth = data['canvasWidth'] as double;
        _canvasHeight = data['canvasHeight'] as double;
        _selectedNode = null;
        _selectedNodeIds = [];
        _selectedConnection = null;
        _saveHistory();
      }
    } catch (e) {
      emit(DiagramError(message: 'Failed to load diagram: $e'));
    }
    _emitLoaded(emit);
  }

  // Export handlers
  Future<void> _onExportDiagram(
    ExportDiagramEvent event,
    Emitter<DiagramState> emit,
  ) async {
    // Export will be handled by UI layer with screenshot/pdf packages
    _emitLoaded(emit);
  }

  // Search handlers
  Future<void> _onSearchNodes(
    SearchNodesEvent event,
    Emitter<DiagramState> emit,
  ) async {
    if (event.query.isEmpty) {
      _emitLoaded(emit);
      return;
    }
    
    final results = _nodes
        .where((n) => n.content.toLowerCase().contains(event.query.toLowerCase()))
        .map((n) => n.id)
        .toList();
    
    emit(
      (state as DiagramLoaded).copyWith(
        searchQuery: event.query,
        searchResults: results,
      ),
    );
  }

  Future<void> _onNavigateToNode(
    NavigateToNodeEvent event,
    Emitter<DiagramState> emit,
  ) async {
    _selectedNode = _nodes.firstWhere((n) => n.id == event.nodeId);
    _selectedNodeIds = [event.nodeId];
    _emitLoaded(emit);
  }

  // Zoom handlers
  Future<void> _onZoomIn(
    ZoomInEvent event,
    Emitter<DiagramState> emit,
  ) async {
    _zoomLevel = (_zoomLevel * 1.2).clamp(0.1, 5.0);
    _emitLoaded(emit);
  }

  Future<void> _onZoomOut(
    ZoomOutEvent event,
    Emitter<DiagramState> emit,
  ) async {
    _zoomLevel = (_zoomLevel / 1.2).clamp(0.1, 5.0);
    _emitLoaded(emit);
  }

  Future<void> _onZoomToFit(
    ZoomToFitEvent event,
    Emitter<DiagramState> emit,
  ) async {
    // Zoom to fit will be handled by UI layer
    _emitLoaded(emit);
  }

  Future<void> _onSetZoom(
    SetZoomEvent event,
    Emitter<DiagramState> emit,
  ) async {
    _zoomLevel = event.zoom.clamp(0.1, 5.0);
    _emitLoaded(emit);
  }

  // Grid handlers
  Future<void> _onToggleGrid(
    ToggleGridEvent event,
    Emitter<DiagramState> emit,
  ) async {
    _showGrid = !_showGrid;
    _emitLoaded(emit);
  }

  Future<void> _onToggleSnapToGrid(
    ToggleSnapToGridEvent event,
    Emitter<DiagramState> emit,
  ) async {
    _snapToGrid = !_snapToGrid;
    _emitLoaded(emit);
  }

  Future<void> _onSetGridSize(
    SetGridSizeEvent event,
    Emitter<DiagramState> emit,
  ) async {
    _gridSize = event.size.clamp(10.0, 100.0);
    _emitLoaded(emit);
  }

  // Template handlers
  Future<void> _onLoadTemplate(
    LoadTemplateEvent event,
    Emitter<DiagramState> emit,
  ) async {
    try {
      final data = await _repository.loadTemplate(event.templateName);
      if (data != null) {
        _nodes = data['nodes'] as List<DiagramNode>;
        _connections = data['connections'] as List<DiagramConnection>;
        _selectedNode = null;
        _selectedNodeIds = [];
        _selectedConnection = null;
        _saveHistory();
      }
    } catch (e) {
      emit(DiagramError(message: 'Failed to load template: $e'));
    }
    _emitLoaded(emit);
  }

  Future<void> _onSaveAsTemplate(
    SaveAsTemplateEvent event,
    Emitter<DiagramState> emit,
  ) async {
    try {
      await _repository.saveAsTemplate(
        nodes: _nodes,
        connections: _connections,
        templateName: event.templateName,
      );
    } catch (e) {
      emit(DiagramError(message: 'Failed to save template: $e'));
    }
    _emitLoaded(emit);
  }

  // Helper methods
  ShapeType _parseShapeType(String type) {
    try {
      return ShapeType.values.firstWhere((e) => e.toString() == type);
    } catch (_) {
      return ShapeType.rectangle;
    }
  }

  ConnectionStyle _parseConnectionStyle(String style) {
    try {
      return ConnectionStyle.values.firstWhere((e) => e.toString() == style);
    } catch (_) {
      return ConnectionStyle.straight;
    }
  }
}

