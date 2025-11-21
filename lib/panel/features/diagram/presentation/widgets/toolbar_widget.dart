import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:file_picker/file_picker.dart';
import '../bloc/diagram_bloc.dart';
import '../bloc/diagram_event.dart';
import '../bloc/diagram_state.dart';
import '../../data/services/export_service.dart';
import 'canvas_widget.dart';

class ToolbarWidget extends StatelessWidget {
  final GlobalKey<CanvasWidgetState>? canvasKey;
  
  const ToolbarWidget({Key? key, this.canvasKey}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DiagramBloc, DiagramState>(
      builder: (context, state) {
        final canUndo = state is DiagramLoaded && state.historyIndex > 0;
        final canRedo = state is DiagramLoaded && state.historyIndex < state.historyLength - 1;
        final canDelete = state is DiagramLoaded && 
            (state.selectedNodeIds.isNotEmpty || 
             state.selectedNode != null || 
             state.selectedConnection != null);

        return Container(
          width: 100,
          color: const Color.fromARGB(41, 0, 0, 0),
          child: SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 15),
              // Shape buttons
              _toolbarButton(
                Icons.rectangle_outlined,
                'Rectangle',
                () => context.read<DiagramBloc>().add(
                  const AddNodeEvent(type: 'Box', shapeType: 'ShapeType.rectangle'),
                ),
              ),
              _toolbarButton(
                Icons.circle_outlined,
                'Circle',
                () => context.read<DiagramBloc>().add(
                  const AddNodeEvent(type: 'Circle', shapeType: 'ShapeType.circle'),
                ),
              ),
              _toolbarButton(
                Icons.diamond_outlined,
                'Diamond',
                () => context.read<DiagramBloc>().add(
                  const AddNodeEvent(type: 'Decision', shapeType: 'ShapeType.diamond'),
                ),
              ),
              _toolbarButton(
                Icons.rounded_corner,
                'Rounded',
                () => context.read<DiagramBloc>().add(
                  const AddNodeEvent(type: 'Rounded', shapeType: 'ShapeType.roundedRect'),
                ),
              ),
              _toolbarButton(
                Icons.change_history,
                'Triangle',
                () => context.read<DiagramBloc>().add(
                  const AddNodeEvent(type: 'Triangle', shapeType: 'ShapeType.triangle'),
                ),
              ),
              _toolbarButton(
                Icons.hexagon,
                'Hexagon',
                () => context.read<DiagramBloc>().add(
                  const AddNodeEvent(type: 'Hexagon', shapeType: 'ShapeType.hexagon'),
                ),
              ),
              _toolbarButton(
                Icons.invert_colors,
                'Cylinder',
                () => context.read<DiagramBloc>().add(
                  const AddNodeEvent(type: 'Cylinder', shapeType: 'ShapeType.cylinder'),
                ),
              ),
              _toolbarButton(
                Icons.crop_rotate,
                'Parallelogram',
                () => context.read<DiagramBloc>().add(
                  const AddNodeEvent(type: 'Parallelogram', shapeType: 'ShapeType.parallelogram'),
                ),
              ),
              _toolbarButton(
                Icons.text_fields,
                'Text Only',
                () => context.read<DiagramBloc>().add(
                  const AddNodeEvent(type: 'Text', shapeType: 'ShapeType.textOnly'),
                ),
              ),
              _toolbarButton(
                Icons.radio_button_unchecked,
                'Ellipse',
                () => context.read<DiagramBloc>().add(
                  const AddNodeEvent(type: 'Ellipse', shapeType: 'ShapeType.ellipse'),
                ),
              ),
              _toolbarButton(
                Icons.pentagon,
                'Pentagon',
                () => context.read<DiagramBloc>().add(
                  const AddNodeEvent(type: 'Pentagon', shapeType: 'ShapeType.pentagon'),
                ),
              ),
              _toolbarButton(
                Icons.stop,
                'Octagon',
                () => context.read<DiagramBloc>().add(
                  const AddNodeEvent(type: 'Octagon', shapeType: 'ShapeType.octagon'),
                ),
              ),
              _toolbarButton(
                Icons.star,
                'Star',
                () => context.read<DiagramBloc>().add(
                  const AddNodeEvent(type: 'Star', shapeType: 'ShapeType.star'),
                ),
              ),
              const SizedBox(height: 8),
              // Page size selector
              _pageSizeButton(context),
              const Divider(color: Color.fromARGB(55, 0, 0, 0)),
              // Zoom controls
              _toolbarButton(
                Icons.zoom_in,
                'Zoom In',
                () {}, // Handled by InteractiveViewer in canvas
              ),
              _toolbarButton(
                Icons.zoom_out,
                'Zoom Out',
                () {}, // Handled by InteractiveViewer in canvas
              ),
              _toolbarButton(
                Icons.fit_screen,
                'Fit',
                () {}, // Handled by InteractiveViewer in canvas
              ),
              const Divider(color: Color.fromARGB(55, 0, 0, 0)),
              // Edit controls
              _toolbarButton(
                Icons.undo,
                'Undo',
                canUndo
                    ? () => context.read<DiagramBloc>().add(const UndoEvent())
                    : null,
              ),
              _toolbarButton(
                Icons.redo,
                'Redo',
                canRedo
                    ? () => context.read<DiagramBloc>().add(const RedoEvent())
                    : null,
              ),
              _toolbarButton(
                Icons.delete,
                'Delete',
                canDelete
                    ? () {
                        // ignore: unnecessary_cast
                        final loadedState = state as DiagramLoaded;
                        if (loadedState.selectedNodeIds.isNotEmpty) {
                          for (final nodeId in loadedState.selectedNodeIds) {
                            context.read<DiagramBloc>().add(DeleteNodeEvent(nodeId: nodeId));
                          }
                        } else if (loadedState.selectedNode != null) {
                          context.read<DiagramBloc>().add(DeleteNodeEvent(nodeId: loadedState.selectedNode!.id));
                        } else if (loadedState.selectedConnection != null) {
                          context.read<DiagramBloc>().add(DeleteConnectionEvent(connectionId: loadedState.selectedConnection!.id));
                        }
                      }
                    : null,
              ),
              const Divider(color: Color.fromARGB(55, 0, 0, 0)),
              // Copy/Paste
              _toolbarButton(
                Icons.copy,
                'Copy (Ctrl+C)',
                state is DiagramLoaded && (state.selectedNodeIds.isNotEmpty || state.selectedNode != null)
                    ? () => context.read<DiagramBloc>().add(const CopySelectedEvent())
                    : null,
              ),
              _toolbarButton(
                Icons.paste,
                'Paste (Ctrl+V)',
                () => context.read<DiagramBloc>().add(const PasteEvent()),
              ),
              _toolbarButton(
                Icons.content_copy,
                'Duplicate (Ctrl+D)',
                state is DiagramLoaded && (state.selectedNodeIds.isNotEmpty || state.selectedNode != null)
                    ? () => context.read<DiagramBloc>().add(const DuplicateSelectedEvent())
                    : null,
              ),
              const Divider(color: Color.fromARGB(55, 0, 0, 0)),
              // Alignment tools
              _alignmentButton(context, state),
              const Divider(color: Color.fromARGB(55, 0, 0, 0)),
              // Grid controls
              _toolbarButton(
                Icons.grid_on,
                'Toggle Grid',
                () => context.read<DiagramBloc>().add(const ToggleGridEvent()),
              ),
              _toolbarButton(
                Icons.grid_4x4,
                'Snap to Grid',
                () => context.read<DiagramBloc>().add(const ToggleSnapToGridEvent()),
              ),
              const Divider(color: Color.fromARGB(55, 0, 0, 0)),
              const SizedBox(height: 20),
              // File operations
              _toolbarButton(
                Icons.save,
                'Save',
                () => _showSaveDialog(context, state),
              ),
              _toolbarButton(
                Icons.file_open,
                'Load',
                () => _showLoadDialog(context),
              ),
              _toolbarButton(
                Icons.download,
                'Export',
                () => _showExportDialog(context),
              ),
              const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _toolbarButton(IconData icon, String label, VoidCallback? onTap) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 8.0),
      child: Tooltip(
        message: label,
        child: GestureDetector(
          onTap: onTap,
          child: Opacity(
            opacity: onTap != null ? 1.0 : 0.5,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color.fromARGB(255, 61, 124, 126),
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(icon, color: Colors.white, size: 26),
            ),
          ),
        ),
      ),
    );
  }

  Widget _pageSizeButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 8.0),
      child: PopupMenuButton<String>(
        tooltip: 'Page Size',
        color: const Color.fromARGB(66, 0, 0, 0),
        onSelected: (value) {
          switch (value) {
            case 'A4_P':
              context
                  .read<DiagramBloc>()
                  .add(const SetCanvasSizeEvent(width: 794, height: 1123));
              break;
            case 'A4_L':
              context
                  .read<DiagramBloc>()
                  .add(const SetCanvasSizeEvent(width: 1123, height: 794));
              break;
            case 'A3':
              context
                  .read<DiagramBloc>()
                  .add(const SetCanvasSizeEvent(width: 1123, height: 1587));
              break;
            case 'Letter':
              context
                  .read<DiagramBloc>()
                  .add(const SetCanvasSizeEvent(width: 816, height: 1056));
              break;
            case 'Free':
            default:
              context
                  .read<DiagramBloc>()
                  .add(const SetCanvasSizeEvent(width: 5000, height: 5000));
              break;
          }
        },
        itemBuilder: (context) => [
          const PopupMenuItem(value: 'Free', child: Text('Free (infinite)')),
          const PopupMenuItem(value: 'A4_P', child: Text('A4 (Portrait)')),
          const PopupMenuItem(value: 'A4_L', child: Text('A4 (Landscape)')),
          const PopupMenuItem(value: 'A3', child: Text('A3')),
          const PopupMenuItem(value: 'Letter', child: Text('Letter')),
        ],
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: const Color.fromARGB(255, 61, 124, 126),
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: const Icon(Icons.insert_drive_file, color: Colors.white, size: 26),
        ),
      ),
    );
  }

  Widget _alignmentButton(BuildContext context, DiagramState state) {
    final canAlign = state is DiagramLoaded && state.selectedNodeIds.length >= 2;
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 8.0),
      child: PopupMenuButton<AlignmentType>(
        tooltip: 'Align Nodes',
        enabled: canAlign,
        color: const Color(0xFF2A2B36),
        onSelected: (alignment) {
          context.read<DiagramBloc>().add(AlignNodesEvent(alignmentType: alignment));
        },
        itemBuilder: (context) => [
          const PopupMenuItem(
            value: AlignmentType.left,
            child: Row(children: [Icon(Icons.format_align_left, size: 20), SizedBox(width: 8), Text('Align Left')]),
          ),
          const PopupMenuItem(
            value: AlignmentType.right,
            child: Row(children: [Icon(Icons.format_align_right, size: 20), SizedBox(width: 8), Text('Align Right')]),
          ),
          const PopupMenuItem(
            value: AlignmentType.center,
            child: Row(children: [Icon(Icons.format_align_center, size: 20), SizedBox(width: 8), Text('Align Center')]),
          ),
          const PopupMenuItem(
            value: AlignmentType.top,
            child: Row(children: [Icon(Icons.vertical_align_top, size: 20), SizedBox(width: 8), Text('Align Top')]),
          ),
          const PopupMenuItem(
            value: AlignmentType.bottom,
            child: Row(children: [Icon(Icons.vertical_align_bottom, size: 20), SizedBox(width: 8), Text('Align Bottom')]),
          ),
          const PopupMenuItem(
            value: AlignmentType.distributeH,
            child: Row(children: [Icon(Icons.view_column, size: 20), SizedBox(width: 8), Text('Distribute Horizontally')]),
          ),
          const PopupMenuItem(
            value: AlignmentType.distributeV,
            child: Row(children: [Icon(Icons.view_agenda, size: 20), SizedBox(width: 8), Text('Distribute Vertically')]),
          ),
        ],
        child: Opacity(
          opacity: canAlign ? 1.0 : 0.5,
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color.fromARGB(255, 61, 124, 126),
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(Icons.format_align_center, color: Colors.white, size: 26),
          ),
        ),
      ),
    );
  }

  void _showSaveDialog(BuildContext context, DiagramState state) async {
    if (state is! DiagramLoaded) return;
    
    final result = await FilePicker.platform.saveFile(
      dialogTitle: 'Save Diagram',
      fileName: 'diagram.json',
      type: FileType.custom,
      allowedExtensions: ['json'],
    );
    
    if (result != null) {
      // Ensure .json extension is added
      String filePath = result;
      if (!filePath.toLowerCase().endsWith('.json')) {
        filePath = '$filePath.json';
      }
      
      context.read<DiagramBloc>().add(SaveDiagramEvent(filePath: filePath));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Diagram saved successfully!')),
        );
      }
    }
  }

  void _showLoadDialog(BuildContext context) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );
    
    if (result != null && result.files.single.path != null) {
      context.read<DiagramBloc>().add(LoadDiagramEvent(filePath: result.files.single.path));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Diagram loaded successfully!')),
        );
      }
    }
  }

  void _showExportDialog(BuildContext context) {
    final state = context.read<DiagramBloc>().state;
    if (state is! DiagramLoaded) return;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Export Diagram'),
        backgroundColor: const Color(0xFF2A2B36),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.image, color: Colors.white70),
              title: const Text('Export as PNG', style: TextStyle(color: Colors.white70)),
              onTap: () async {
                Navigator.pop(context);
                final canvasState = canvasKey?.currentState;
                if (canvasState != null) {
                  await ExportService.exportAsPng(
                    canvasState.screenshotController,
                    context,
                  );
                } else {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Failed to access canvas')),
                    );
                  }
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.picture_as_pdf, color: Colors.white70),
              title: const Text('Export as PDF', style: TextStyle(color: Colors.white70)),
              onTap: () async {
                Navigator.pop(context);
                final canvasState = canvasKey?.currentState;
                if (canvasState != null) {
                  await ExportService.exportAsPdf(
                    canvasState.screenshotController,
                    context,
                    state.nodes,
                    state.connections,
                    state.canvasWidth,
                    state.canvasHeight,
                  );
                } else {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Failed to access canvas')),
                    );
                  }
                }
              },
            ),
          ],
        ),
        titleTextStyle: const TextStyle(color: Colors.white),
      ),
    );
  }
}
