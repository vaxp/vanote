import 'package:flutter/material.dart';

// Diagram Events
abstract class DiagramEvent {
  const DiagramEvent();
}

class AddNodeEvent extends DiagramEvent {
  final String type;
  final String shapeType;

  const AddNodeEvent({required this.type, required this.shapeType});
}

class DeleteNodeEvent extends DiagramEvent {
  final String nodeId;

  const DeleteNodeEvent({required this.nodeId});
}

class SelectNodeEvent extends DiagramEvent {
  final String? nodeId;

  const SelectNodeEvent({required this.nodeId});
}

class UpdateNodeEvent extends DiagramEvent {
  final String nodeId;
  final String? content;
  final Offset? position;
  final double? width;
  final double? height;
  final String? fontFamily;
  final double? fontSize;
  final Color? color;
  final String? shapeType;
  final bool? isBold;
  final bool? isItalic;
  final bool? isUnderlined;
  final Color? textColor;

  const UpdateNodeEvent({
    required this.nodeId,
    this.content,
    this.position,
    this.width,
    this.height,
    this.fontFamily,
    this.fontSize,
    this.color,
    this.shapeType,
    this.isBold,
    this.isItalic,
    this.isUnderlined,
    this.textColor,
  });
}

class CreateConnectionEvent extends DiagramEvent {
  final String fromNodeId;
  final String toNodeId;

  const CreateConnectionEvent({
    required this.fromNodeId,
    required this.toNodeId,
  });
}

class DeleteConnectionEvent extends DiagramEvent {
  final String connectionId;

  const DeleteConnectionEvent({required this.connectionId});
}

class SetCanvasSizeEvent extends DiagramEvent {
  final double width;
  final double height;

  const SetCanvasSizeEvent({required this.width, required this.height});
}

class UndoEvent extends DiagramEvent {
  const UndoEvent();
}

class RedoEvent extends DiagramEvent {
  const RedoEvent();
}

class ShowPropertiesPanelEvent extends DiagramEvent {
  final bool show;

  const ShowPropertiesPanelEvent({required this.show});
}

class LoadDemoDiagramEvent extends DiagramEvent {
  const LoadDemoDiagramEvent();
}

// Connection events
class SelectConnectionEvent extends DiagramEvent {
  final String? connectionId;

  const SelectConnectionEvent({required this.connectionId});
}

class UpdateConnectionEvent extends DiagramEvent {
  final String connectionId;
  final String? label;
  final Color? color;
  final double? strokeWidth;
  final bool? hasArrow;
  final String? style;
  final Offset? labelPosition;

  const UpdateConnectionEvent({
    required this.connectionId,
    this.label,
    this.color,
    this.strokeWidth,
    this.hasArrow,
    this.style,
    this.labelPosition,
  });
}

// Multi-select events
class SelectMultipleNodesEvent extends DiagramEvent {
  final List<String> nodeIds;
  final bool addToSelection;

  const SelectMultipleNodesEvent({
    required this.nodeIds,
    this.addToSelection = false,
  });
}

class ClearSelectionEvent extends DiagramEvent {
  const ClearSelectionEvent();
}

// Copy/Paste events
class CopySelectedEvent extends DiagramEvent {
  const CopySelectedEvent();
}

class PasteEvent extends DiagramEvent {
  final Offset? position;

  const PasteEvent({this.position});
}

class DuplicateSelectedEvent extends DiagramEvent {
  const DuplicateSelectedEvent();
}

// Alignment events
enum AlignmentType { left, right, center, top, bottom, distributeH, distributeV }

class AlignNodesEvent extends DiagramEvent {
  final AlignmentType alignmentType;

  const AlignNodesEvent({required this.alignmentType});
}

// Nudge events
class NudgeNodesEvent extends DiagramEvent {
  final Offset offset;

  const NudgeNodesEvent({required this.offset});
}

// Save/Load events
class SaveDiagramEvent extends DiagramEvent {
  final String? filePath;

  const SaveDiagramEvent({this.filePath});
}

class LoadDiagramEvent extends DiagramEvent {
  final String? filePath;

  const LoadDiagramEvent({this.filePath});
}

// Export events
enum ExportFormat { png, svg, pdf }

class ExportDiagramEvent extends DiagramEvent {
  final ExportFormat format;
  final String? filePath;

  const ExportDiagramEvent({required this.format, this.filePath});
}

// Search events
class SearchNodesEvent extends DiagramEvent {
  final String query;

  const SearchNodesEvent({required this.query});
}

class NavigateToNodeEvent extends DiagramEvent {
  final String nodeId;

  const NavigateToNodeEvent({required this.nodeId});
}

// Zoom events
class ZoomInEvent extends DiagramEvent {
  const ZoomInEvent();
}

class ZoomOutEvent extends DiagramEvent {
  const ZoomOutEvent();
}

class ZoomToFitEvent extends DiagramEvent {
  const ZoomToFitEvent();
}

class SetZoomEvent extends DiagramEvent {
  final double zoom;

  const SetZoomEvent({required this.zoom});
}

// Grid events
class ToggleGridEvent extends DiagramEvent {
  const ToggleGridEvent();
}

class ToggleSnapToGridEvent extends DiagramEvent {
  const ToggleSnapToGridEvent();
}

class SetGridSizeEvent extends DiagramEvent {
  final double size;

  const SetGridSizeEvent({required this.size});
}

// Template events
class LoadTemplateEvent extends DiagramEvent {
  final String templateName;

  const LoadTemplateEvent({required this.templateName});
}

class SaveAsTemplateEvent extends DiagramEvent {
  final String templateName;

  const SaveAsTemplateEvent({required this.templateName});
}
