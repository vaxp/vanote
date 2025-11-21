import 'package:flutter/material.dart';

enum ConnectionStyle { straight, curved, orthogonal, elbow }

class DiagramConnection {
  String id;
  String fromNodeId;
  String toNodeId;
  String label;
  Color color;
  double strokeWidth;
  bool hasArrow;
  ConnectionStyle style;
  Offset? labelPosition; // For custom label positioning

  DiagramConnection({
    required this.id,
    required this.fromNodeId,
    required this.toNodeId,
    this.label = '',
    this.color = const Color.fromARGB(255, 61, 124, 126),
    this.strokeWidth = 2.0,
    this.hasArrow = true,
    this.style = ConnectionStyle.straight,
    this.labelPosition,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'fromNodeId': fromNodeId,
    'toNodeId': toNodeId,
    'label': label,
    'color': color.value,
    'strokeWidth': strokeWidth,
    'hasArrow': hasArrow,
    'style': style.toString(),
    'labelPosition': labelPosition != null
        ? {'dx': labelPosition!.dx, 'dy': labelPosition!.dy}
        : null,
  };

  factory DiagramConnection.fromJson(Map<String, dynamic> json) {
    final labelPos = json['labelPosition'] as Map<String, dynamic>?;
    return DiagramConnection(
      id: json['id'],
      fromNodeId: json['fromNodeId'],
      toNodeId: json['toNodeId'],
      label: json['label'] ?? '',
      color: Color(json['color'] ?? 0xFF3D7C7E),
      strokeWidth: json['strokeWidth'] ?? 2.0,
      hasArrow: json['hasArrow'] ?? true,
      style: ConnectionStyle.values.firstWhere(
        (e) => e.toString() == json['style'],
        orElse: () => ConnectionStyle.straight,
      ),
      labelPosition: labelPos != null
          ? Offset(labelPos['dx']?.toDouble() ?? 0, labelPos['dy']?.toDouble() ?? 0)
          : null,
    );
  }

  DiagramConnection copyWith({
    String? id,
    String? fromNodeId,
    String? toNodeId,
    String? label,
    Color? color,
    double? strokeWidth,
    bool? hasArrow,
    ConnectionStyle? style,
    Offset? labelPosition,
  }) {
    return DiagramConnection(
      id: id ?? this.id,
      fromNodeId: fromNodeId ?? this.fromNodeId,
      toNodeId: toNodeId ?? this.toNodeId,
      label: label ?? this.label,
      color: color ?? this.color,
      strokeWidth: strokeWidth ?? this.strokeWidth,
      hasArrow: hasArrow ?? this.hasArrow,
      style: style ?? this.style,
      labelPosition: labelPosition ?? this.labelPosition,
    );
  }
}
