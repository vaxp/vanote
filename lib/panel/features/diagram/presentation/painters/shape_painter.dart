import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../domain/entities/diagram_node.dart';

class ShapePainter extends CustomPainter {
  final DiagramNode node;
  final bool isSelected;

  ShapePainter({
    required this.node,
    required this.isSelected,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = node.color.withOpacity(0.2)
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = isSelected ? Colors.cyan : node.color
      ..style = PaintingStyle.stroke
      ..strokeWidth = isSelected ? 3.0 : 2.0;

    final path = _getShapePath(size);
    
    // Draw fill
    canvas.drawPath(path, paint);
    
    // Draw border
    canvas.drawPath(path, borderPaint);
    
    // Draw shadow
    if (isSelected) {
      final shadowPaint = Paint()
        ..color = Colors.cyan.withOpacity(0.5)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 15);
      canvas.drawPath(path, shadowPaint);
    }
  }

  Path _getShapePath(Size size) {
    switch (node.shapeType) {
      case ShapeType.triangle:
        return _trianglePath(size);
      case ShapeType.hexagon:
        return _hexagonPath(size);
      case ShapeType.cylinder:
        return _cylinderPath(size);
      case ShapeType.parallelogram:
        return _parallelogramPath(size);
      case ShapeType.ellipse:
        return _ellipsePath(size);
      case ShapeType.pentagon:
        return _polygonPath(size, 5);
      case ShapeType.octagon:
        return _polygonPath(size, 8);
      case ShapeType.star:
        return _starPath(size);
      default:
        return Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height));
    }
  }

  Path _trianglePath(Size size) {
    final path = Path();
    path.moveTo(size.width / 2, 0);
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();
    return path;
  }

  Path _hexagonPath(Size size) {
    final path = Path();
    final centerX = size.width / 2;
    final centerY = size.height / 2;
    final radius = math.min(size.width, size.height) / 2;
    
    for (int i = 0; i < 6; i++) {
      final angle = (math.pi / 3) * i - math.pi / 2;
      final x = centerX + radius * math.cos(angle);
      final y = centerY + radius * math.sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    return path;
  }

  Path _cylinderPath(Size size) {
    final path = Path();
    final ellipseHeight = size.height * 0.15;
    
    // Top ellipse
    path.addOval(Rect.fromLTWH(0, 0, size.width, ellipseHeight * 2));
    
    // Left side
    path.moveTo(0, ellipseHeight);
    path.lineTo(0, size.height - ellipseHeight);
    
    // Bottom ellipse
    path.addOval(Rect.fromLTWH(0, size.height - ellipseHeight * 2, size.width, ellipseHeight * 2));
    
    // Right side
    path.moveTo(size.width, ellipseHeight);
    path.lineTo(size.width, size.height - ellipseHeight);
    
    return path;
  }

  Path _parallelogramPath(Size size) {
    final path = Path();
    final offset = size.width * 0.2;
    path.moveTo(offset, 0);
    path.lineTo(size.width, 0);
    path.lineTo(size.width - offset, size.height);
    path.lineTo(0, size.height);
    path.close();
    return path;
  }

  Path _ellipsePath(Size size) {
    return Path()..addOval(Rect.fromLTWH(0, 0, size.width, size.height));
  }

  Path _polygonPath(Size size, int sides) {
    final path = Path();
    final centerX = size.width / 2;
    final centerY = size.height / 2;
    final radius = math.min(size.width, size.height) / 2;
    
    for (int i = 0; i < sides; i++) {
      final angle = (2 * math.pi / sides) * i - math.pi / 2;
      final x = centerX + radius * math.cos(angle);
      final y = centerY + radius * math.sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    return path;
  }

  Path _starPath(Size size) {
    final path = Path();
    final centerX = size.width / 2;
    final centerY = size.height / 2;
    final outerRadius = math.min(size.width, size.height) / 2;
    final innerRadius = outerRadius * 0.5;
    final points = 5;
    
    for (int i = 0; i < points * 2; i++) {
      final angle = (math.pi / points) * i - math.pi / 2;
      final radius = i.isEven ? outerRadius : innerRadius;
      final x = centerX + radius * math.cos(angle);
      final y = centerY + radius * math.sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    return path;
  }

  @override
  bool shouldRepaint(ShapePainter oldDelegate) {
    return oldDelegate.node.shapeType != node.shapeType ||
        oldDelegate.node.color != node.color ||
        oldDelegate.isSelected != isSelected ||
        oldDelegate.node.width != node.width ||
        oldDelegate.node.height != node.height;
  }
}

