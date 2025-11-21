import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/diagram_node.dart';
import '../bloc/diagram_bloc.dart';
import '../bloc/diagram_event.dart';
import '../bloc/diagram_state.dart';
import '../painters/diagram_painters.dart';

class CanvasWidget extends StatefulWidget {
  const CanvasWidget({Key? key}) : super(key: key);

  @override
  State<CanvasWidget> createState() => _CanvasWidgetState();
}

class _CanvasWidgetState extends State<CanvasWidget> {
  late TransformationController _transformController;
  DiagramNode? _connectionStartNode;
  Offset? _connectionPreviewEnd;
  String? _editingNodeId;
  TextEditingController? _textController;

  @override
  void initState() {
    super.initState();
    _transformController = TransformationController();
  }

  @override
  void dispose() {
    _transformController.dispose();
    _textController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DiagramBloc, DiagramState>(
      builder: (context, state) {
        if (state is! DiagramLoaded) {
          return const Center(child: CircularProgressIndicator());
        }

        return GestureDetector(
          onTapDown: (details) {
            if (_connectionStartNode == null) {
              context.read<DiagramBloc>().add(const SelectNodeEvent(nodeId: null));
              context.read<DiagramBloc>().add(const ShowPropertiesPanelEvent(show: false));
            }
          },
          onSecondaryTapDown: (details) {
            context.read<DiagramBloc>().add(const SelectNodeEvent(nodeId: null));
            context.read<DiagramBloc>().add(const ShowPropertiesPanelEvent(show: false));
            _connectionStartNode = null;
            _connectionPreviewEnd = null;
          },
          onPanUpdate: (details) {
            if (_connectionStartNode != null) {
              setState(() {
                _connectionPreviewEnd = details.globalPosition;
              });
            }
          },
          child: InteractiveViewer(
            transformationController: _transformController,
            boundaryMargin: const EdgeInsets.all(double.infinity),
            minScale: 0.1,
            maxScale: 5.0,
            child: Container(
              width: state.canvasWidth,
              height: state.canvasHeight,
              decoration: BoxDecoration(
                color: const Color(0xFFFFFFFF),
                border: Border.all(color: const Color(0xFFCCCCCC)),
              ),
              child: Stack(
                children: [
                  // Grid
                  CustomPaint(
                    painter: GridPainter(),
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
                    return CustomPaint(
                      painter: ConnectionPainter(
                        fromPos: fromNode.getConnectionPoint(toNode.center),
                        toPos: toNode.getConnectionPoint(fromNode.center),
                        color: conn.color,
                        label: conn.label,
                        strokeWidth: 2.5,
                      ),
                      size: Size(state.canvasWidth, state.canvasHeight),
                    );
                  }).toList(),
                  // Connection preview
                  if (_connectionStartNode != null && _connectionPreviewEnd != null)
                    CustomPaint(
                      painter: ConnectionPainter(
                        fromPos: _connectionStartNode!.getConnectionPoint(_connectionPreviewEnd!),
                        toPos: _connectionPreviewEnd!,
                        color: const Color.fromARGB(255, 61, 124, 126),
                        label: '',
                        strokeWidth: 2.5,
                      ),
                      size: Size(state.canvasWidth, state.canvasHeight),
                    ),
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
        );
      },
    );
  }


  Widget _buildNodeWidget(BuildContext context, DiagramLoaded state, DiagramNode node) {
    final isSelected = state.selectedNode?.id == node.id;

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
          context.read<DiagramBloc>().add(SelectNodeEvent(nodeId: node.id));
        }
      },
      onPanUpdate: (details) {
        // Get pointer position in canvas coordinates
        final globalPos = details.globalPosition;
        final transform = _transformController.value;
        final invertedTransform = Matrix4.inverted(transform);
        final canvasPos = MatrixUtils.transformPoint(invertedTransform, globalPos);
        // Stick node's center to pointer
        final newPos = canvasPos - Offset(node.width / 2, node.height / 2);
        context.read<DiagramBloc>().add(
          UpdateNodeEvent(
            nodeId: node.id,
            position: newPos,
          ),
        );
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
          Container(
            width: node.width,
            height: node.height,
            decoration: _getShapeDecoration(node, isSelected),
            child: _editingNodeId == node.id
                ? TextField(
                    controller: _textController,
                    style: const TextStyle(color: Colors.white, fontSize: 16),
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
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: node.fontSize,
                          fontFamily: node.fontFamily,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
          ),
          if (isSelected || _connectionStartNode?.id == node.id)
            ..._buildConnectionHandles(context, node),
        ],
      ),
    );
  }

  List<Widget> _buildConnectionHandles(BuildContext context, DiagramNode node) {
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
            final diagramState = bloc.state as DiagramLoaded;

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

  void _showNodeContextMenu(BuildContext context, DiagramNode node, Offset position) {
    showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(position.dx, position.dy, position.dx, position.dy),
      items: [
        PopupMenuItem<String>(
          value: 'edit',
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(Icons.edit, color: Colors.white, size: 20),
              SizedBox(width: 12),
              Text('Edit', style: TextStyle(color: Colors.white)),
            ],
          ),
        ),
        PopupMenuItem<String>(
          value: 'delete',
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(Icons.delete, color: Colors.redAccent, size: 20),
              SizedBox(width: 12),
              Text('Delete', style: TextStyle(color: Colors.redAccent)),
            ],
          ),
        ),
      ],
      color: const Color.fromARGB(66, 0, 0, 0),
    ).then((value) {
      if (value == 'edit') {
        context.read<DiagramBloc>().add(SelectNodeEvent(nodeId: node.id));
        context.read<DiagramBloc>().add(const ShowPropertiesPanelEvent(show: true));
      } else if (value == 'delete') {
        context.read<DiagramBloc>().add(DeleteNodeEvent(nodeId: node.id));
      }
    });
  }
}
