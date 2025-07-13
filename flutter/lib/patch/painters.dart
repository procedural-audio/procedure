import 'package:flutter/material.dart';
import 'package:metasampler/bindings/api/patch.dart' as api;
import 'dart:ui' as ui;
import 'dart:math';
import '../settings.dart';
import 'pin.dart';
import '../bindings/api/cable.dart';
import '../bindings/api/endpoint.dart';
import '../project/theme.dart';


class GridPainter extends CustomPainter {
  GridPainter();

  @override
  void paint(Canvas canvas, ui.Size size) {
    final paint = Paint()
      ..color = const Color.fromRGBO(25, 25, 25, 1.0)
      ..strokeWidth = 1;

    for (double i = 0;
        i < size.width;
        i += GlobalSettings.gridSize.toDouble()) {
      var p1 = Offset(i, 0);
      var p2 = Offset(i, size.height);
      canvas.drawLine(p1, p2, paint);
    }

    for (double i = 0;
        i < size.height;
        i += GlobalSettings.gridSize.toDouble()) {
      var p1 = Offset(0, i);
      var p2 = Offset(size.width, i);
      canvas.drawLine(p1, p2, paint);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return false;
  }
}

class CablePainter extends CustomPainter {
  final api.Patch patch;
  
  CablePainter({
    required this.patch, 
    Listenable? repaint,
  }) : super(repaint: repaint);

  @override
  void paint(Canvas canvas, ui.Size size) {
    for (var cable in patch.cables) {
      _paintCable(canvas, cable);
    }
  }
  
  void _paintCable(Canvas canvas, Cable cable) {
    // Get the source and destination nodes
    var sourceNode = cable.source.node;
    var destNode = cable.destination.node;
    
    // Find the pins for this cable
    var sourcePin = cable.source.endpoint;
    var destPin = cable.destination.endpoint;

    // Calculate start and end positions using quantized positions for existing cables
    Offset startPos = Offset(
      sourcePin.position.$1 + _getQuantizedX(sourceNode.position.$1) + 15 / 2,
      sourcePin.position.$2 + _getQuantizedY(sourceNode.position.$2) + 15 / 2,
    );
    
    Offset endPos = Offset(
      destPin.position.$1 + _getQuantizedX(destNode.position.$1) + 15 / 2,
      destPin.position.$2 + _getQuantizedY(destNode.position.$2) + 15 / 2,
    );
    
    // Get color for this endpoint type
    Color color = ProjectTheme.getColor(cable.source.endpoint.type);
    
    // Paint the cable using the same style as the original ConnectorPainter
    _paintCablePath(canvas, startPos, endPos, color, cable.source.endpoint.kind);
  }
  
  void _paintCablePath(Canvas canvas, Offset start, Offset end, Color color, EndpointKind kind) {
    final paint = Paint()
      ..color = const Color.fromRGBO(255, 255, 255, 1.0)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    
    double inactiveOpacity = 0.3;
    
    paint.color = color.withValues(alpha: inactiveOpacity); // Default to inactive for now
    
    // Adjust offsets similar to original ConnectorPainter
    Offset adjustedStart = Offset(start.dx + 9, start.dy + 2);
    Offset adjustedEnd = Offset(end.dx - 3, end.dy + 2);
    
    double distance = (adjustedEnd - adjustedStart).distance;
    double firstOffset = min(distance, 40);
    
    Offset start1 = Offset(adjustedStart.dx + firstOffset, adjustedStart.dy);
    Offset end1 = Offset(adjustedEnd.dx - firstOffset, adjustedEnd.dy);
    Offset center = Offset((adjustedStart.dx + adjustedEnd.dx) / 2, (adjustedStart.dy + adjustedEnd.dy) / 2);
    
    // Draw the main cable path
    Path path = Path();
    path.moveTo(adjustedStart.dx, adjustedStart.dy);
    path.quadraticBezierTo(start1.dx + 10, start1.dy, center.dx, center.dy);
    path.quadraticBezierTo(end1.dx - 10, end1.dy, adjustedEnd.dx, adjustedEnd.dy);
    canvas.drawPath(path, paint);
    
    // Note: Animation effects are simplified for now since we don't have animation controllers here
    // This could be enhanced later with a ticker or animation system
  }
  
  
  // Helper methods to get quantized positions (same as used in NodeEditor)
  double _getQuantizedX(double x) {
    return (x / GlobalSettings.gridSize).roundToDouble() * GlobalSettings.gridSize;
  }
  
  double _getQuantizedY(double y) {
    return (y / GlobalSettings.gridSize).roundToDouble() * GlobalSettings.gridSize;
  }
  
  @override
  bool shouldRepaint(CablePainter oldDelegate) {
    // Repaint if cables or nodes have changed
    // The Listenable passed to super() handles position changes
    return patch.cables != oldDelegate.patch.cables || patch.nodes != oldDelegate.patch.nodes;
  }
}

class NewCablePainter extends CustomPainter {
  final Pin startPin;
  final Offset endOffset;
  
  NewCablePainter({required this.startPin, required this.endOffset});

  @override
  void paint(Canvas canvas, ui.Size size) {
    // Calculate start position from pin
    var nodePosition = startPin.patch.getNodePosition(nodeId: startPin.nodeId) ?? (0.0, 0.0);
    Offset startPos = Offset(
      startPin.offset.dx + nodePosition.$1 + 15 / 2,
      startPin.offset.dy + nodePosition.$2 + 15 / 2,
    );
    
    // Get color for this endpoint type
    Color color = ProjectTheme.getColor(startPin.endpoint.type);
    
    // Paint the cable using the same style as the original ConnectorPainter
    _paintCablePath(canvas, startPos, endOffset, color);
  }
  
  void _paintCablePath(Canvas canvas, Offset start, Offset end, Color color) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    
    // Adjust offsets similar to original ConnectorPainter
    Offset adjustedStart = Offset(start.dx + 9, start.dy + 2);
    Offset adjustedEnd = Offset(end.dx - 3, end.dy + 2);
    
    double distance = (adjustedEnd - adjustedStart).distance;
    double firstOffset = min(distance, 40);
    
    Offset start1 = Offset(adjustedStart.dx + firstOffset, adjustedStart.dy);
    Offset end1 = Offset(adjustedEnd.dx - firstOffset, adjustedEnd.dy);
    Offset center = Offset((adjustedStart.dx + adjustedEnd.dx) / 2, (adjustedStart.dy + adjustedEnd.dy) / 2);
    
    // Draw the main cable path
    Path path = Path();
    path.moveTo(adjustedStart.dx, adjustedStart.dy);
    path.quadraticBezierTo(start1.dx + 10, start1.dy, center.dx, center.dy);
    path.quadraticBezierTo(end1.dx - 10, end1.dy, adjustedEnd.dx, adjustedEnd.dy);
    canvas.drawPath(path, paint);
  }
  
  @override
  bool shouldRepaint(NewCablePainter oldDelegate) {
    return startPin != oldDelegate.startPin || endOffset != oldDelegate.endOffset;
  }
}