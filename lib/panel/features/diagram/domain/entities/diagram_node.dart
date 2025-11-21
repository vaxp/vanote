import 'package:flutter/material.dart';
import 'dart:math' as math;

enum ShapeType { 
  rectangle, 
  circle, 
  diamond, 
  roundedRect, 
  triangle, 
  hexagon,
  cylinder,
  parallelogram,
  textOnly,
  ellipse,
  pentagon,
  octagon,
  star,
}

class DiagramNode {
  String id;
  Offset position;
  String content;
  Color color;
  ShapeType shapeType;
  double width;
  double height;
  String fontFamily;
  double fontSize;
  bool isSelected;
  bool isBold;
  bool isItalic;
  bool isUnderlined;
  Color textColor;

  DiagramNode({
    required this.id,
    required this.position,
    required this.content,
    this.color = const Color(0xFFBB9AF7),
    this.shapeType = ShapeType.rectangle,
    this.width = 220,
    this.height = 120,
    this.fontFamily = 'Roboto',
    this.fontSize = 16,
    this.isSelected = false,
    this.isBold = false,
    this.isItalic = false,
    this.isUnderlined = false,
    this.textColor = Colors.white,
  });

  Offset get center => Offset(position.dx + width / 2, position.dy + height / 2);

  Offset getConnectionPoint(Offset targetPos) {
    final center = this.center;
    final dx = targetPos.dx - center.dx;
    final dy = targetPos.dy - center.dy;
    final distance = (dx * dx + dy * dy) == 0 ? 0 : math.sqrt(dx * dx + dy * dy);
    
    if (distance == 0) {
      return Offset(center.dx + width / 2, center.dy);
    }

    // For circular shapes (circle, ellipse), use radius
    if (shapeType == ShapeType.circle || shapeType == ShapeType.ellipse) {
      final radius = math.min(width, height) / 2;
      final ratio = radius / distance;
      return Offset(center.dx + dx * ratio, center.dy + dy * ratio);
    }

    // For complex shapes, calculate intersection with bounding box
    final ratio = [width / 2, height / 2].reduce((a, b) => a < b ? a : b) / distance;
    final intersectionX = center.dx + dx * ratio;
    final intersectionY = center.dy + dy * ratio;
    
    // For parallelogram, adjust for the slanted sides
    if (shapeType == ShapeType.parallelogram) {
      // Use bounding box edges for connection points
      if (dx.abs() > dy.abs()) {
        // Horizontal connection
        return Offset(dx > 0 ? position.dx + width : position.dx, intersectionY);
      } else {
        // Vertical connection
        return Offset(intersectionX, dy > 0 ? position.dy + height : position.dy);
      }
    }
    
    return Offset(intersectionX, intersectionY);
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'position': {'dx': position.dx, 'dy': position.dy},
    'content': content,
    'color': color.value,
    'shapeType': shapeType.toString(),
    'width': width,
    'height': height,
    'fontFamily': fontFamily,
    'fontSize': fontSize,
    'isBold': isBold,
    'isItalic': isItalic,
    'isUnderlined': isUnderlined,
    'textColor': textColor.value,
  };

  factory DiagramNode.fromJson(Map<String, dynamic> json) {
    final pos = json['position'] as Map<String, dynamic>;
    return DiagramNode(
      id: json['id'],
      position: Offset(pos['dx']?.toDouble() ?? 0, pos['dy']?.toDouble() ?? 0),
      content: json['content'],
      color: Color(json['color'] ?? 0xFFBB9AF7),
      shapeType: ShapeType.values.firstWhere(
        (e) => e.toString() == json['shapeType'],
        orElse: () => ShapeType.rectangle,
      ),
      width: json['width']?.toDouble() ?? 220,
      height: json['height']?.toDouble() ?? 120,
      fontFamily: json['fontFamily'] ?? 'Roboto',
      fontSize: json['fontSize']?.toDouble() ?? 16,
      isBold: json['isBold'] ?? false,
      isItalic: json['isItalic'] ?? false,
      isUnderlined: json['isUnderlined'] ?? false,
      textColor: Color(json['textColor'] ?? Colors.white.value),
    );
  }

  DiagramNode copyWith({
    String? id,
    Offset? position,
    String? content,
    Color? color,
    ShapeType? shapeType,
    double? width,
    double? height,
    String? fontFamily,
    double? fontSize,
    bool? isSelected,
    bool? isBold,
    bool? isItalic,
    bool? isUnderlined,
    Color? textColor,
  }) {
    return DiagramNode(
      id: id ?? this.id,
      position: position ?? this.position,
      content: content ?? this.content,
      color: color ?? this.color,
      shapeType: shapeType ?? this.shapeType,
      width: width ?? this.width,
      height: height ?? this.height,
      fontFamily: fontFamily ?? this.fontFamily,
      fontSize: fontSize ?? this.fontSize,
      isSelected: isSelected ?? this.isSelected,
      isBold: isBold ?? this.isBold,
      isItalic: isItalic ?? this.isItalic,
      isUnderlined: isUnderlined ?? this.isUnderlined,
      textColor: textColor ?? this.textColor,
    );
  }
}
