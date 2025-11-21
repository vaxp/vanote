import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:math' as math;
import 'package:flutter/gestures.dart';
import 'package:screenshot/screenshot.dart';
import '../../domain/entities/diagram_node.dart';
import '../../domain/entities/diagram_connection.dart';
import '../bloc/diagram_bloc.dart';
import '../bloc/diagram_event.dart';
import '../bloc/diagram_state.dart';
import '../painters/diagram_painters.dart';
import '../painters/shape_painter.dart';

class CanvasWidget extends StatefulWidget {
  const CanvasWidget({Key? key}) : super(key: key);

  @override
  State<CanvasWidget> createState() => CanvasWidgetState();
}

class CanvasWidgetState extends State<CanvasWidget> {
  late TransformationController _transformController;
  final ScreenshotController _screenshotController = ScreenshotController();
  DiagramNode? _connectionStartNode;
  Offset? _connectionPreviewEnd;
  String? _editingNodeId;
  TextEditingController? _textController;
  TextEditingController? _connectionLabelController;
  
  // Multi-select
  Offset? _selectionStart;
  Offset? _selectionEnd;
  bool _isSelecting = false;
  
  // Resize handles
  String? _resizingNodeId;
  String? _resizeHandle;
  Offset? _resizeStartPos;
  Size? _resizeStartSize;
  
  // Drag tracking
  String? _draggingNodeId;
  Offset? _dragStartOffset; // Offset from node position to initial touch point


  void _onTransformChanged() {
    // Update zoom level in BLoC if needed
  }

  @override
  void dispose() {
    _transformController.removeListener(_onTransformChanged);
    _transformController.dispose();
    _keyboardFocusNode.dispose();
    _textController?.dispose();
    _connectionLabelController?.dispose();
    super.dispose();
  }

  // Expose screenshot controller for export
  ScreenshotController get screenshotController => _screenshotController;

  final FocusNode _keyboardFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _transformController = TransformationController();
    _transformController.addListener(_onTransformChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _keyboardFocusNode.requestFocus();
    });
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardListener(
      focusNode: _keyboardFocusNode,
      onKeyEvent: _handleKeyEvent,
      child: BlocBuilder<DiagramBloc, DiagramState>(
        builder: (context, state) {
          if (state is! DiagramLoaded) {
            return const Center(child: CircularProgressIndicator());
          }

          return GestureDetector(
            onTapDown: (details) {
              if (_connectionStartNode == null && !_isSelecting) {
                _handleCanvasTap(context, details, state);
              }
            },
            onPanStart: (details) {
              if (_connectionStartNode == null) {
                final canvasPos = _globalToCanvas(details.globalPosition);
                _selectionStart = canvasPos;
                _isSelecting = true;
              }
            },
            onPanUpdate: (details) {
              if (_connectionStartNode != null) {
                setState(() {
                  _connectionPreviewEnd = details.globalPosition;
                });
              } else if (_isSelecting) {
                setState(() {
                  _selectionEnd = _globalToCanvas(details.globalPosition);
                });
              }
            },
            onPanEnd: (details) {
              if (_isSelecting) {
                _handleSelectionBox(context, state);
                setState(() {
                  _isSelecting = false;
                  _selectionStart = null;
                  _selectionEnd = null;
                });
              }
            },
            onSecondaryTapDown: (details) {
              context.read<DiagramBloc>().add(const ClearSelectionEvent());
              _connectionStartNode = null;
              _connectionPreviewEnd = null;
            },
            child: Screenshot(
              controller: _screenshotController,
              child: InteractiveViewer(
                transformationController: _transformController,
                boundaryMargin: const EdgeInsets.all(double.infinity),
                minScale: 0.1,
                maxScale: 5.0,
                child: Container(
                  width: state.canvasWidth,
                  height: state.canvasHeight,
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(0, 0, 0, 0),
                    border: Border.all(color: const Color(0xFFCCCCCC)),
                  ),
                  child: Stack(
                  children: [
                    // Grid
                    if (state.showGrid)
                      CustomPaint(
                        painter: GridPainter(
                          gridSize: state.gridSize,
                          showGrid: state.showGrid,
                        ),
                        size: Size(state.canvasWidth, state.canvasHeight),
                      ),
                    // Connections
                    ...state.connections.map((conn) {
                      final fromNode = state.nodes.firstWhere(
                        (n) => n.id == conn.fromNodeId,
                        orElse: () => state.nodes.first,
                      );
                      final toNode = state.nodes.firstWhere(
                        (n) => n.id == conn.toNodeId,
                        orElse: () => state.nodes.first,
                      );
                      return _buildConnectionWidget(
                        context,
                        state,
                        conn,
                        fromNode,
                        toNode,
                      );
                    }).toList(),
                    // Connection preview
                    if (_connectionStartNode != null && _connectionPreviewEnd != null)
                      _buildConnectionPreview(state),
                    // Selection box
                    if (_isSelecting && _selectionStart != null && _selectionEnd != null)
                      _buildSelectionBox(),
                    // Nodes
                    ...state.nodes.map((node) {
                      return Positioned(
                        left: node.position.dx,
                        top: node.position.dy,
                        child: _buildNodeWidget(context, state, node),
                      );
                    }).toList(),
                  ],
                ),
              ),
                ),
            ),
          );
        },
      ),
    );
  }

  void _handleCanvasTap(BuildContext context, TapDownDetails details, DiagramLoaded state) {
    final canvasPos = _globalToCanvas(details.globalPosition);
    
    // Check if clicking on a connection
    bool clickedConnection = false;
    for (final conn in state.connections) {
      if (_isPointOnConnection(canvasPos, conn, state)) {
        context.read<DiagramBloc>().add(SelectConnectionEvent(connectionId: conn.id));
        clickedConnection = true;
        break;
      }
    }
    
    if (!clickedConnection) {
      context.read<DiagramBloc>().add(const ClearSelectionEvent());
    }
  }

  bool _isPointOnConnection(Offset point, DiagramConnection conn, DiagramLoaded state) {
    final fromNode = state.nodes.firstWhere((n) => n.id == conn.fromNodeId);
    final toNode = state.nodes.firstWhere((n) => n.id == conn.toNodeId);
    final fromPos = fromNode.getConnectionPoint(toNode.center);
    final toPos = toNode.getConnectionPoint(fromNode.center);
    
    // Simple distance check (can be improved for curved lines)
    final distance = _pointToLineDistance(point, fromPos, toPos);
    return distance < 10.0;
  }

  double _pointToLineDistance(Offset point, Offset lineStart, Offset lineEnd) {
    final A = point.dx - lineStart.dx;
    final B = point.dy - lineStart.dy;
    final C = lineEnd.dx - lineStart.dx;
    final D = lineEnd.dy - lineStart.dy;

    final dot = A * C + B * D;
    final lenSq = C * C + D * D;
    final param = lenSq != 0 ? dot / lenSq : -1;

    double xx, yy;
    if (param < 0) {
      xx = lineStart.dx;
      yy = lineStart.dy;
    } else if (param > 1) {
      xx = lineEnd.dx;
      yy = lineEnd.dy;
    } else {
      xx = lineStart.dx + param * C;
      yy = lineStart.dy + param * D;
    }

    final dx = point.dx - xx;
    final dy = point.dy - yy;
    return math.sqrt(dx * dx + dy * dy);
  }

  void _handleSelectionBox(BuildContext context, DiagramLoaded state) {
    if (_selectionStart == null || _selectionEnd == null) return;
    
    final rect = Rect.fromPoints(_selectionStart!, _selectionEnd!);
    final selectedIds = <String>[];
    
    for (final node in state.nodes) {
      final nodeRect = Rect.fromLTWH(
        node.position.dx,
        node.position.dy,
        node.width,
        node.height,
      );
      if (rect.overlaps(nodeRect)) {
        selectedIds.add(node.id);
      }
    }
    
    if (selectedIds.isNotEmpty) {
      context.read<DiagramBloc>().add(
        SelectMultipleNodesEvent(nodeIds: selectedIds),
      );
    }
  }

  Widget _buildSelectionBox() {
    if (_selectionStart == null || _selectionEnd == null) {
      return const SizedBox.shrink();
    }
    
    final rect = Rect.fromPoints(_selectionStart!, _selectionEnd!);
    return Positioned(
      left: rect.left,
      top: rect.top,
      child: Container(
        width: rect.width,
        height: rect.height,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.cyan, width: 2),
          color: Colors.cyan.withOpacity(0.1),
        ),
      ),
    );
  }

  Widget _buildConnectionWidget(
    BuildContext context,
    DiagramLoaded state,
    DiagramConnection conn,
    DiagramNode fromNode,
    DiagramNode toNode,
  ) {
    final isSelected = state.selectedConnection?.id == conn.id;
    
    return GestureDetector(
      onTap: () {
        context.read<DiagramBloc>().add(SelectConnectionEvent(connectionId: conn.id));
      },
      onDoubleTap: () {
        _startEditingConnection(context, conn);
      },
      child: CustomPaint(
        painter: ConnectionPainter(
          fromPos: fromNode.getConnectionPoint(toNode.center),
          toPos: toNode.getConnectionPoint(fromNode.center),
          color: conn.color,
          label: conn.label,
          strokeWidth: conn.strokeWidth,
          style: conn.style,
          hasArrow: conn.hasArrow,
          isSelected: isSelected,
          labelPosition: conn.labelPosition,
        ),
        size: Size(state.canvasWidth, state.canvasHeight),
      ),
    );
  }

  Widget _buildConnectionPreview(DiagramLoaded state) {
    if (_connectionStartNode == null || _connectionPreviewEnd == null) return const SizedBox.shrink();
    
    final canvasPos = _globalToCanvas(_connectionPreviewEnd!);
    final fromPos = _connectionStartNode!.getConnectionPoint(canvasPos);
    
    return CustomPaint(
      painter: ConnectionPainter(
        fromPos: fromPos,
        toPos: canvasPos,
        color: Colors.cyan.withOpacity(0.5),
        label: '',
        strokeWidth: 2.5,
      ),
      size: Size(state.canvasWidth, state.canvasHeight),
    );
  }

  Widget _buildNodeWidget(BuildContext context, DiagramLoaded state, DiagramNode node) {
    final isSelected = state.selectedNodeIds.contains(node.id) || state.selectedNode?.id == node.id;
    final isMultiSelected = state.selectedNodeIds.contains(node.id) && state.selectedNodeIds.length > 1;

    return GestureDetector(
      onTapDown: (details) {
        if (_connectionStartNode != null && _connectionStartNode!.id != node.id) {
          context.read<DiagramBloc>().add(
            CreateConnectionEvent(
              fromNodeId: _connectionStartNode!.id,
              toNodeId: node.id,
            ),
          );
          setState(() {
            _connectionStartNode = null;
            _connectionPreviewEnd = null;
          });
        } else {
          // Multi-select with Ctrl/Cmd - handled via keyboard shortcuts
          final isCtrlPressed = false; // Will be handled via keyboard events
          
          if (isCtrlPressed || state.selectedNodeIds.length > 1) {
            // Add to selection
            final newIds = List<String>.from(state.selectedNodeIds);
            if (newIds.contains(node.id)) {
              newIds.remove(node.id);
            } else {
              newIds.add(node.id);
            }
            context.read<DiagramBloc>().add(SelectMultipleNodesEvent(nodeIds: newIds));
          } else {
            context.read<DiagramBloc>().add(SelectNodeEvent(nodeId: node.id));
          }
        }
      },
      onPanStart: (details) {
        if (_resizingNodeId != node.id) {
          // Calculate the offset from the node's position to the touch point
          final globalPos = details.globalPosition;
          final transform = _transformController.value;
          final invertedTransform = Matrix4.inverted(transform);
          final canvasPos = MatrixUtils.transformPoint(invertedTransform, globalPos);
          
          setState(() {
            _draggingNodeId = node.id;
            _dragStartOffset = canvasPos - node.position;
          });
        }
      },
      onPanUpdate: (details) {
        if (_resizingNodeId == node.id) {
          _handleResize(context, node, details);
        } else if (_draggingNodeId == node.id && _dragStartOffset != null) {
          final globalPos = details.globalPosition;
          final transform = _transformController.value;
          final invertedTransform = Matrix4.inverted(transform);
          final canvasPos = MatrixUtils.transformPoint(invertedTransform, globalPos);
          // Use the stored offset to maintain relative position
          final newPos = canvasPos - _dragStartOffset!;
          
          context.read<DiagramBloc>().add(
            UpdateNodeEvent(
              nodeId: node.id,
              position: newPos,
            ),
          );
        }
      },
      onPanEnd: (details) {
        if (_draggingNodeId == node.id) {
          setState(() {
            _draggingNodeId = null;
            _dragStartOffset = null;
          });
        }
      },
      onLongPress: () {
        setState(() {
          _connectionStartNode = node;
        });
      },
      onSecondaryTapDown: (details) {
        _showNodeContextMenu(context, node, details.globalPosition);
      },
      child: Stack(
        children: [
          _buildShapeContainer(node, isSelected),
          Positioned.fill(
            child: _editingNodeId == node.id
                ? TextField(
                    controller: _textController,
                    style: TextStyle(
                      color: node.textColor,
                      fontSize: node.fontSize,
                      fontWeight: node.isBold ? FontWeight.bold : FontWeight.normal,
                      fontStyle: node.isItalic ? FontStyle.italic : FontStyle.normal,
                      decoration: node.isUnderlined ? TextDecoration.underline : null,
                    ),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.all(8),
                    ),
                    onSubmitted: (_) => _finishEditingNode(context, node),
                    autofocus: true,
                  )
                : GestureDetector(
                    onDoubleTap: () => _startEditingNode(node),
                    child: Center(
                      child: Text(
                        node.content,
                        style: TextStyle(
                          color: node.textColor,
                          fontWeight: node.isBold ? FontWeight.bold : FontWeight.normal,
                          fontSize: node.fontSize,
                          fontFamily: node.fontFamily,
                          fontStyle: node.isItalic ? FontStyle.italic : FontStyle.normal,
                          decoration: node.isUnderlined ? TextDecoration.underline : null,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 10,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
          ),
          if (isSelected || _connectionStartNode?.id == node.id) ..._buildConnectionHandles(context, state, node),
          if (isSelected) ..._buildResizeHandles(context, node),
          if (isMultiSelected)
            Positioned(
              top: -5,
              right: -5,
              child: Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: Colors.cyan,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: Center(
                  child: Text(
                    '${state.selectedNodeIds.length}',
                    style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  List<Widget> _buildConnectionHandles(BuildContext context, DiagramLoaded state, DiagramNode node) {
    const handleSize = 14.0;
    const positions = [
      (x: 0.5, y: 0.0),
      (x: 0.5, y: 1.0),
      (x: 0.0, y: 0.5),
      (x: 1.0, y: 0.5),
      (x: 0.0, y: 0.0),
      (x: 1.0, y: 0.0),
      (x: 0.0, y: 1.0),
      (x: 1.0, y: 1.0),
    ];

    return positions.map((pos) {
      final x = node.width * pos.x - handleSize / 2;
      final y = node.height * pos.y - handleSize / 2;

      return Positioned(
        left: x,
        top: y,
        child: GestureDetector(
          onPanStart: (_) {
            setState(() {
              _connectionStartNode = node;
            });
            context.read<DiagramBloc>().add(SelectNodeEvent(nodeId: node.id));
          },
          onPanUpdate: (details) {
            setState(() {
              _connectionPreviewEnd = details.globalPosition;
            });
          },
          onPanEnd: (details) {
            final globalPos = details.globalPosition;
            final transform = _transformController.value;
            final invertedTransform = Matrix4.inverted(transform);
            final canvasPos = MatrixUtils.transformPoint(invertedTransform, globalPos);

            // Get the current state to access nodes
            final bloc = context.read<DiagramBloc>();
            final diagramState = bloc.state;
            
            if (diagramState is DiagramLoaded) {
              for (final targetNode in diagramState.nodes.where((n) => n.id != node.id)) {
                final nodeLeft = targetNode.position.dx;
                final nodeTop = targetNode.position.dy;
                final nodeRight = nodeLeft + targetNode.width;
                final nodeBottom = nodeTop + targetNode.height;

                if (canvasPos.dx >= nodeLeft - 20 && 
                    canvasPos.dx <= nodeRight + 20 &&
                    canvasPos.dy >= nodeTop - 20 && 
                    canvasPos.dy <= nodeBottom + 20) {
                  context.read<DiagramBloc>().add(
                    CreateConnectionEvent(
                      fromNodeId: node.id,
                      toNodeId: targetNode.id,
                    ),
                  );
                  break;
                }
              }
            }

            setState(() {
              _connectionStartNode = null;
              _connectionPreviewEnd = null;
            });
          },
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            child: Container(
              width: handleSize,
              height: handleSize,
              decoration: BoxDecoration(
                color: Colors.cyan.withOpacity(0.8),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2.5),
              ),
            ),
          ),
        ),
      );
    }).toList();
  }

  List<Widget> _buildResizeHandles(BuildContext context, DiagramNode node) {
    const handleSize = 12.0;
    final handles = [
      {'x': 0.0, 'y': 0.0, 'type': 'nw'},
      {'x': 0.5, 'y': 0.0, 'type': 'n'},
      {'x': 1.0, 'y': 0.0, 'type': 'ne'},
      {'x': 0.0, 'y': 0.5, 'type': 'w'},
      {'x': 1.0, 'y': 0.5, 'type': 'e'},
      {'x': 0.0, 'y': 1.0, 'type': 'sw'},
      {'x': 0.5, 'y': 1.0, 'type': 's'},
      {'x': 1.0, 'y': 1.0, 'type': 'se'},
    ];

    return handles.map((handle) {
      final x = node.width * (handle['x'] as double) - handleSize / 2;
      final y = node.height * (handle['y'] as double) - handleSize / 2;
      final type = handle['type'] as String;

      return Positioned(
        left: x,
        top: y,
        child: GestureDetector(
          onPanStart: (details) {
            setState(() {
              _resizingNodeId = node.id;
              _resizeHandle = type;
              _resizeStartPos = details.globalPosition;
              _resizeStartSize = Size(node.width, node.height);
            });
          },
          onPanUpdate: (details) {
            if (_resizingNodeId == node.id) {
              _handleResize(context, node, details);
            }
          },
          onPanEnd: (details) {
            setState(() {
              _resizingNodeId = null;
              _resizeHandle = null;
              _resizeStartPos = null;
              _resizeStartSize = null;
            });
          },
          child: MouseRegion(
            cursor: _getResizeCursor(type),
            child: Container(
              width: handleSize,
              height: handleSize,
              decoration: BoxDecoration(
                color: Colors.cyan,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
            ),
          ),
        ),
      );
    }).toList();
  }

  MouseCursor _getResizeCursor(String type) {
    switch (type) {
      case 'n':
      case 's':
        return SystemMouseCursors.resizeUpDown;
      case 'e':
      case 'w':
        return SystemMouseCursors.resizeLeftRight;
      case 'ne':
      case 'sw':
        return SystemMouseCursors.resizeUpLeftDownRight;
      case 'nw':
      case 'se':
        return SystemMouseCursors.resizeUpRightDownLeft;
      default:
        return SystemMouseCursors.basic;
    }
  }

  void _handleResize(BuildContext context, DiagramNode node, DragUpdateDetails details) {
    if (_resizeHandle == null || _resizeStartPos == null || _resizeStartSize == null) return;
    
    final transform = _transformController.value;
    final invertedTransform = Matrix4.inverted(transform);
    final currentPos = MatrixUtils.transformPoint(invertedTransform, details.globalPosition);
    final startPos = MatrixUtils.transformPoint(invertedTransform, _resizeStartPos!);
    
    final delta = currentPos - startPos;
    var newWidth = _resizeStartSize!.width;
    var newHeight = _resizeStartSize!.height;
    var newX = node.position.dx;
    var newY = node.position.dy;
    
    switch (_resizeHandle) {
      case 'e':
        newWidth = (_resizeStartSize!.width + delta.dx).clamp(50.0, 1000.0);
        break;
      case 'w':
        newWidth = (_resizeStartSize!.width - delta.dx).clamp(50.0, 1000.0);
        newX = node.position.dx + (_resizeStartSize!.width - newWidth);
        break;
      case 's':
        newHeight = (_resizeStartSize!.height + delta.dy).clamp(50.0, 1000.0);
        break;
      case 'n':
        newHeight = (_resizeStartSize!.height - delta.dy).clamp(50.0, 1000.0);
        newY = node.position.dy + (_resizeStartSize!.height - newHeight);
        break;
      case 'se':
        newWidth = (_resizeStartSize!.width + delta.dx).clamp(50.0, 1000.0);
        newHeight = (_resizeStartSize!.height + delta.dy).clamp(50.0, 1000.0);
        break;
      case 'sw':
        newWidth = (_resizeStartSize!.width - delta.dx).clamp(50.0, 1000.0);
        newHeight = (_resizeStartSize!.height + delta.dy).clamp(50.0, 1000.0);
        newX = node.position.dx + (_resizeStartSize!.width - newWidth);
        break;
      case 'ne':
        newWidth = (_resizeStartSize!.width + delta.dx).clamp(50.0, 1000.0);
        newHeight = (_resizeStartSize!.height - delta.dy).clamp(50.0, 1000.0);
        newY = node.position.dy + (_resizeStartSize!.height - newHeight);
        break;
      case 'nw':
        newWidth = (_resizeStartSize!.width - delta.dx).clamp(50.0, 1000.0);
        newHeight = (_resizeStartSize!.height - delta.dy).clamp(50.0, 1000.0);
        newX = node.position.dx + (_resizeStartSize!.width - newWidth);
        newY = node.position.dy + (_resizeStartSize!.height - newHeight);
        break;
    }
    
    context.read<DiagramBloc>().add(
      UpdateNodeEvent(
        nodeId: node.id,
        position: Offset(newX, newY),
        width: newWidth,
        height: newHeight,
      ),
    );
  }

  Offset _globalToCanvas(Offset globalPos) {
    final transform = _transformController.value;
    final invertedTransform = Matrix4.inverted(transform);
    return MatrixUtils.transformPoint(invertedTransform, globalPos);
  }

  Widget _buildShapeContainer(DiagramNode node, bool isSelected) {
    // Use custom painter for complex shapes
    final needsCustomPainter = [
      ShapeType.triangle,
      ShapeType.hexagon,
      ShapeType.cylinder,
      ShapeType.parallelogram,
      ShapeType.ellipse,
      ShapeType.pentagon,
      ShapeType.octagon,
      ShapeType.star,
    ].contains(node.shapeType);

    if (needsCustomPainter) {
      return CustomPaint(
        painter: ShapePainter(node: node, isSelected: isSelected),
        size: Size(node.width, node.height),
      );
    }

    // Use BoxDecoration for simple shapes
    final decoration = _getShapeDecoration(node, isSelected);
    return Container(
      width: node.width,
      height: node.height,
      decoration: decoration,
    );
  }

  BoxDecoration _getShapeDecoration(DiagramNode node, bool isSelected) {
    final border = isSelected
      ? Border.all(color: Colors.cyan, width: 3)
      : Border.all(color: node.color, width: 2);

    final shadow = isSelected
      ? [BoxShadow(color: Colors.cyan.withOpacity(0.5), blurRadius: 15, spreadRadius: 5)]
      : [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 8, spreadRadius: 2)];

    switch (node.shapeType) {
      case ShapeType.circle:
        return BoxDecoration(
          shape: BoxShape.circle,
          color: node.color.withOpacity(0.2),
          border: border,
          boxShadow: shadow,
        );
      case ShapeType.roundedRect:
        return BoxDecoration(
          color: node.color.withOpacity(0.2),
          borderRadius: BorderRadius.circular(20),
          border: border,
          boxShadow: shadow,
        );
      case ShapeType.diamond:
        return BoxDecoration(
          color: node.color.withOpacity(0.2),
          border: border,
          boxShadow: shadow,
          shape: BoxShape.rectangle,
        );
      case ShapeType.textOnly:
        return BoxDecoration(
          color: Colors.transparent,
          border: border,
          boxShadow: shadow,
        );
      default:
        return BoxDecoration(
          color: node.color.withOpacity(0.2),
          borderRadius: BorderRadius.circular(8),
          border: border,
          boxShadow: shadow,
        );
    }
  }

  void _startEditingNode(DiagramNode node) {
    setState(() {
      _editingNodeId = node.id;
      _textController = TextEditingController(text: node.content);
    });
  }

  void _finishEditingNode(BuildContext context, DiagramNode node) {
    if (_textController != null) {
      context.read<DiagramBloc>().add(
        UpdateNodeEvent(
          nodeId: node.id,
          content: _textController!.text,
        ),
      );
      setState(() {
        _editingNodeId = null;
        _textController?.dispose();
        _textController = null;
      });
    }
  }

  void _startEditingConnection(BuildContext context, DiagramConnection conn) {
    _connectionLabelController = TextEditingController(text: conn.label);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Connection Label'),
        content: TextField(
          controller: _connectionLabelController,
          autofocus: true,
          onSubmitted: (value) {
            context.read<DiagramBloc>().add(
              UpdateConnectionEvent(connectionId: conn.id, label: value),
            );
            Navigator.pop(context);
            _connectionLabelController?.dispose();
            _connectionLabelController = null;
          },
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _connectionLabelController?.dispose();
              _connectionLabelController = null;
            },
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              context.read<DiagramBloc>().add(
                UpdateConnectionEvent(
                  connectionId: conn.id,
                  label: _connectionLabelController?.text ?? '',
                ),
              );
              Navigator.pop(context);
              _connectionLabelController?.dispose();
              _connectionLabelController = null;
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showNodeContextMenu(BuildContext context, DiagramNode node, Offset position) {
    showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(position.dx, position.dy, position.dx, position.dy),
      items: [
        const PopupMenuItem<String>(
          value: 'edit',
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.edit, color: Colors.white, size: 20),
              SizedBox(width: 12),
              Text('Edit', style: TextStyle(color: Colors.white)),
            ],
          ),
        ),
        const PopupMenuItem<String>(
          value: 'duplicate',
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.copy, color: Colors.white, size: 20),
              SizedBox(width: 12),
              Text('Duplicate', style: TextStyle(color: Colors.white)),
            ],
          ),
        ),
        const PopupMenuItem<String>(
          value: 'delete',
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.delete, color: Colors.redAccent, size: 20),
              SizedBox(width: 12),
              Text('Delete', style: TextStyle(color: Colors.redAccent)),
            ],
          ),
        ),
      ],
      color: const Color.fromARGB(200, 30, 30, 30),
    ).then((value) {
      if (value == 'edit') {
        context.read<DiagramBloc>().add(SelectNodeEvent(nodeId: node.id));
        context.read<DiagramBloc>().add(const ShowPropertiesPanelEvent(show: true));
      } else if (value == 'duplicate') {
        context.read<DiagramBloc>().add(SelectNodeEvent(nodeId: node.id));
        context.read<DiagramBloc>().add(const DuplicateSelectedEvent());
      } else if (value == 'delete') {
        context.read<DiagramBloc>().add(DeleteNodeEvent(nodeId: node.id));
      }
    });
  }

  void _handleKeyEvent(KeyEvent event) {
    if (event is KeyDownEvent) {
      final bloc = context.read<DiagramBloc>();
      final state = bloc.state;
      
      if (state is! DiagramLoaded) return;
      
      final isCtrl = event.logicalKey == LogicalKeyboardKey.metaLeft ||
                     event.logicalKey == LogicalKeyboardKey.metaRight ||
                     event.logicalKey == LogicalKeyboardKey.controlLeft ||
                     event.logicalKey == LogicalKeyboardKey.controlRight;
      
      // Ctrl/Cmd + C
      if (isCtrl && event.logicalKey == LogicalKeyboardKey.keyC) {
        bloc.add(const CopySelectedEvent());
      }
      // Ctrl/Cmd + V
      else if (isCtrl && event.logicalKey == LogicalKeyboardKey.keyV) {
        bloc.add(const PasteEvent());
      }
      // Ctrl/Cmd + Z
      else if (isCtrl && event.logicalKey == LogicalKeyboardKey.keyZ) {
        bloc.add(const UndoEvent());
      }
      // Ctrl/Cmd + Y
      else if (isCtrl && event.logicalKey == LogicalKeyboardKey.keyY) {
        bloc.add(const RedoEvent());
      }
      // Ctrl/Cmd + D
      else if (isCtrl && event.logicalKey == LogicalKeyboardKey.keyD) {
        bloc.add(const DuplicateSelectedEvent());
      }
      // Delete or Backspace
      else if (event.logicalKey == LogicalKeyboardKey.delete ||
               event.logicalKey == LogicalKeyboardKey.backspace) {
        if (state.selectedConnection != null) {
          bloc.add(DeleteConnectionEvent(connectionId: state.selectedConnection!.id));
        } else if (state.selectedNodeIds.isNotEmpty) {
          for (final nodeId in state.selectedNodeIds) {
            bloc.add(DeleteNodeEvent(nodeId: nodeId));
          }
        } else if (state.selectedNode != null) {
          bloc.add(DeleteNodeEvent(nodeId: state.selectedNode!.id));
        }
      }
      // Arrow keys for nudging
      else if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
        bloc.add(const NudgeNodesEvent(offset: Offset(-10, 0)));
      } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
        bloc.add(const NudgeNodesEvent(offset: Offset(10, 0)));
      } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
        bloc.add(const NudgeNodesEvent(offset: Offset(0, -10)));
      } else if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
        bloc.add(const NudgeNodesEvent(offset: Offset(0, 10)));
      }
    }
  }
}

