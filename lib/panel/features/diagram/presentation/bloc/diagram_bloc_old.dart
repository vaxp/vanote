import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/diagram_node.dart';
import '../../domain/entities/diagram_connection.dart';
import 'diagram_event.dart';
import 'diagram_state.dart';
import 'dart:async';

class DiagramBloc extends Bloc<DiagramEvent, DiagramState> {
  List<DiagramNode> _nodes = [];
  List<DiagramConnection> _connections = [];
  DiagramNode? _selectedNode;
  double _canvasWidth = 50000;
  double _canvasHeight = 50000;
  bool _showPropertiesPanel = false;
  final List<List<DiagramNode>> _history = [];
  int _historyIndex = -1;

  DiagramBloc() : super(const DiagramInitial()) {
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
  }

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

    _saveHistory();
    emit(
      DiagramLoaded(
        nodes: List.from(_nodes),
        connections: List.from(_connections),
        selectedNode: _selectedNode,
        canvasWidth: _canvasWidth,
        canvasHeight: _canvasHeight,
        showPropertiesPanel: _showPropertiesPanel,
        historyIndex: _historyIndex,
        historyLength: _history.length,
      ),
    );
  }

  Future<void> _onAddNode(
    AddNodeEvent event,
    Emitter<DiagramState> emit,
  ) async {
    final newNode = DiagramNode(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      position: const Offset(400, 300),
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
    _saveHistory();
    _emitLoaded(emit);
  }

  Future<void> _onSelectNode(
    SelectNodeEvent event,
    Emitter<DiagramState> emit,
  ) async {
    if (event.nodeId == null) {
      _selectedNode = null;
      _showPropertiesPanel = false;
    } else {
      _selectedNode = _nodes.firstWhere((n) => n.id == event.nodeId);
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
      _nodes[nodeIndex] = node.copyWith(
        content: event.content,
        position: event.position,
        width: event.width,
        height: event.height,
        fontFamily: event.fontFamily,
        fontSize: event.fontSize,
        color: event.color,
        shapeType: event.shapeType != null ? _parseShapeType(event.shapeType!) : null,
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
    final conn = DiagramConnection(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      fromNodeId: event.fromNodeId,
      toNodeId: event.toNodeId,
    );
    _connections.add(conn);
    _saveHistory();
    _emitLoaded(emit);
  }

  Future<void> _onDeleteConnection(
    DeleteConnectionEvent event,
    Emitter<DiagramState> emit,
  ) async {
    _connections.removeWhere((c) => c.id == event.connectionId);
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
      _nodes = List.from(_history[_historyIndex]);
      _selectedNode = null;
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
      _nodes = List.from(_history[_historyIndex]);
      _selectedNode = null;
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

  void _saveHistory() {
    _history.removeRange(_historyIndex + 1, _history.length);
    _history.add(List.from(_nodes));
    _historyIndex++;
  }

  void _emitLoaded(Emitter<DiagramState> emit) {
    emit(
      DiagramLoaded(
        nodes: List.from(_nodes),
        connections: List.from(_connections),
        selectedNode: _selectedNode,
        canvasWidth: _canvasWidth,
        canvasHeight: _canvasHeight,
        showPropertiesPanel: _showPropertiesPanel,
        historyIndex: _historyIndex,
        historyLength: _history.length,
      ),
    );
  }

  ShapeType _parseShapeType(String type) {
    try {
      return ShapeType.values.firstWhere((e) => e.toString() == type);
    } catch (_) {
      return ShapeType.rectangle;
    }
  }
}
