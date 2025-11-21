import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../domain/entities/diagram_connection.dart';

class GridPainter extends CustomPainter {
  final double gridSize;
  final bool showGrid;

  GridPainter({this.gridSize = 30.0, this.showGrid = true});

  @override
  void paint(Canvas canvas, Size size) {
    if (!showGrid) return;
    
    final paint = Paint()
      ..color = Colors.grey.withOpacity(0.2)
      ..strokeWidth = 0.5;

    for (double x = 0; x < size.width; x += gridSize) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += gridSize) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(GridPainter oldDelegate) {
    return oldDelegate.gridSize != gridSize || oldDelegate.showGrid != showGrid;
  }
}

class ConnectionPainter extends CustomPainter {
  final Offset fromPos;
  final Offset toPos;
  final Color color;
  final String label;
  final double strokeWidth;
  final ConnectionStyle style;
  final bool hasArrow;
  final bool isSelected;
  final Offset? labelPosition;

  ConnectionPainter({
    required this.fromPos,
    required this.toPos,
    required this.color,
    required this.label,
    this.strokeWidth = 2.0,
    this.style = ConnectionStyle.straight,
    this.hasArrow = true,
    this.isSelected = false,
    this.labelPosition,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = isSelected ? Colors.cyan : color
      ..strokeWidth = isSelected ? strokeWidth + 1 : strokeWidth
      ..strokeCap = StrokeCap.round;

    Path path;
    Offset labelPos;

    switch (style) {
      case ConnectionStyle.straight:
        canvas.drawLine(fromPos, toPos, paint);
        labelPos = labelPosition ?? (fromPos + (toPos - fromPos) / 2);
        break;
        
      case ConnectionStyle.curved:
        final controlPoint1 = Offset(
          fromPos.dx + (toPos.dx - fromPos.dx) * 0.5,
          fromPos.dy,
        );
        final controlPoint2 = Offset(
          fromPos.dx + (toPos.dx - fromPos.dx) * 0.5,
          toPos.dy,
        );
        path = Path()
          ..moveTo(fromPos.dx, fromPos.dy)
          ..cubicTo(
            controlPoint1.dx, controlPoint1.dy,
            controlPoint2.dx, controlPoint2.dy,
            toPos.dx, toPos.dy,
          );
        canvas.drawPath(path, paint);
        labelPos = labelPosition ?? _getPointOnCurve(path, 0.5);
        break;
        
      case ConnectionStyle.orthogonal:
        final midX = fromPos.dx + (toPos.dx - fromPos.dx) / 2;
        path = Path()
          ..moveTo(fromPos.dx, fromPos.dy)
          ..lineTo(midX, fromPos.dy)
          ..lineTo(midX, toPos.dy)
          ..lineTo(toPos.dx, toPos.dy);
        canvas.drawPath(path, paint);
        labelPos = labelPosition ?? Offset(midX, (fromPos.dy + toPos.dy) / 2);
        break;
        
      case ConnectionStyle.elbow:
        final dx = (toPos.dx - fromPos.dx).abs();
        final dy = (toPos.dy - fromPos.dy).abs();
        final elbowX = fromPos.dx + (dx < dy ? 0 : (toPos.dx > fromPos.dx ? dx / 2 : -dx / 2));
        final elbowY = fromPos.dy + (dx >= dy ? 0 : (toPos.dy > fromPos.dy ? dy / 2 : -dy / 2));
        path = Path()
          ..moveTo(fromPos.dx, fromPos.dy)
          ..lineTo(elbowX, fromPos.dy)
          ..lineTo(elbowX, elbowY)
          ..lineTo(toPos.dx, elbowY)
          ..lineTo(toPos.dx, toPos.dy);
        canvas.drawPath(path, paint);
        labelPos = labelPosition ?? Offset(elbowX, elbowY);
        break;
    }

    // Draw arrow
    if (hasArrow) {
      final arrowSize = 12.0 + (strokeWidth * 2);
      final angle = math.atan2(toPos.dy - fromPos.dy, toPos.dx - fromPos.dx);
      
      // For curved/orthogonal, calculate angle at endpoint
      double arrowAngle = angle;
      if (style == ConnectionStyle.orthogonal || style == ConnectionStyle.elbow) {
        // Calculate angle based on last segment
        final lastSegmentStart = style == ConnectionStyle.orthogonal
            ? Offset((fromPos.dx + toPos.dx) / 2, toPos.dy)
            : Offset(toPos.dx, (fromPos.dy + toPos.dy) / 2);
        arrowAngle = math.atan2(toPos.dy - lastSegmentStart.dy, toPos.dx - lastSegmentStart.dx);
      }
      
      final arrowPoint1 = toPos - Offset(
        arrowSize * math.cos(arrowAngle - math.pi / 6),
        arrowSize * math.sin(arrowAngle - math.pi / 6),
      );
      final arrowPoint2 = toPos - Offset(
        arrowSize * math.cos(arrowAngle + math.pi / 6),
        arrowSize * math.sin(arrowAngle + math.pi / 6),
      );

      final arrowPaint = Paint()
        ..color = isSelected ? Colors.cyan : color
        ..strokeWidth = strokeWidth + 0.5;

      canvas.drawLine(toPos, arrowPoint1, arrowPaint);
      canvas.drawLine(toPos, arrowPoint2, arrowPaint);
    }

    // Draw label
    if (label.isNotEmpty) {
      final textPainter = TextPainter(
        text: TextSpan(
          text: label,
          style: TextStyle(
            color: isSelected ? Colors.cyan : Colors.white70,
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        labelPos - Offset(textPainter.width / 2, textPainter.height / 2),
      );
    }
  }

  Offset _getPointOnCurve(Path path, double t) {
    final metrics = path.computeMetrics().first;
    final length = metrics.length;
    final point = metrics.getTangentForOffset(length * t)?.position;
    return point ?? (fromPos + (toPos - fromPos) / 2);
  }

  @override
  bool shouldRepaint(ConnectionPainter oldDelegate) {
    return oldDelegate.fromPos != fromPos ||
        oldDelegate.toPos != toPos ||
        oldDelegate.color != color ||
        oldDelegate.label != label ||
        oldDelegate.style != style ||
        oldDelegate.hasArrow != hasArrow ||
        oldDelegate.isSelected != isSelected ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}
