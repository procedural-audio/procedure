import 'package:flutter/material.dart';
import 'package:metasampler/bindings/api/node.dart' as rust_node;
import 'dart:ui' as ui;
import 'dart:math';
import 'dart:convert';
import '../settings.dart';
import 'pin.dart';
import '../bindings/api/cable.dart';
import '../bindings/api/endpoint.dart';
import '../bindings/api/module.dart';
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
  final List<rust_node.Node> nodes;
  final List<Cable> cables;
  
  CablePainter({
    required this.nodes,
    required this.cables, 
    Listenable? repaint,
  }) : super(repaint: repaint);

  @override
  void paint(Canvas canvas, ui.Size size) {
    for (var cable in cables) {
      _paintCable(canvas, cable);
    }
  }
  
  void _paintCable(Canvas canvas, Cable cable) {
    // Get the current positions from the nodes list
    var sourceNode = nodes.firstWhere((n) => n.id == cable.source.node.id, orElse: () => cable.source.node);
    var destNode = nodes.firstWhere((n) => n.id == cable.destination.node.id, orElse: () => cable.destination.node);
    
    var sourceNodePos = sourceNode.position;
    var destNodePos = destNode.position;

    double snap(double v) {
      final g = GlobalSettings.gridSize.toDouble();
      return (v / g).roundToDouble() * g;
    }
    
    // Get modules to calculate pin offsets
    var sourceModule = sourceNode.module;
    var destModule = destNode.module;
    
    // Find the endpoint indices to match the pins
    var sourceEndpointIndex = _findEndpointIndex(cable.source.node.id, cable.source.endpoint, false);
    var destEndpointIndex = _findEndpointIndex(cable.destination.node.id, cable.destination.endpoint, true);
    
    if (sourceEndpointIndex == null || destEndpointIndex == null) {
      return; // Skip if endpoints not found
    }
    
    // Calculate pin offsets based on endpoint annotations
    var sourceOffset = _calculatePinOffset(cable.source.endpoint, sourceModule, false);
    var destOffset = _calculatePinOffset(cable.destination.endpoint, destModule, true);

    // Calculate start and end positions using current node positions
    Offset startPos = Offset(
      sourceOffset.dx + snap(sourceNodePos.$1) + pinRadius,
      sourceOffset.dy + snap(sourceNodePos.$2) + pinRadius,
    );
    
    Offset endPos = Offset(
      destOffset.dx + snap(destNodePos.$1) + pinRadius,
      destOffset.dy + snap(destNodePos.$2) + pinRadius,
    );
    
    // Get color for this endpoint type
    Color color = ProjectTheme.getColor(cable.source.endpoint.type);
    
    // Paint the cable using the same style as the original ConnectorPainter
    _paintCablePath(canvas, startPos, endPos, color, cable.source.endpoint.kind);
  }
  
  int? _findEndpointIndex(int nodeId, NodeEndpoint endpoint, bool isInput) {
    var node = nodes.firstWhere((n) => n.id == nodeId, orElse: () => throw Exception('Node not found'));
    var endpoints = isInput 
        ? node.getInputs()
        : node.getOutputs();
        
    for (int i = 0; i < endpoints.length; i++) {
      if (endpoints[i].type == endpoint.type && 
          endpoints[i].annotation == endpoint.annotation) {
        return i;
      }
    }
    return null;
  }
  
  Offset _calculatePinOffset(NodeEndpoint endpoint, Module module, bool isInput) {
    var annotation = jsonDecode(endpoint.annotation);
    var top = double.tryParse(annotation['pinTop'].toString()) ?? 0.0;
    
    if (isInput) {
      return Offset(5, top);
    } else {
      return Offset(
        module.size.$1 * GlobalSettings.gridSize - (pinRadius * 2 + 10),
        top
      );
    }
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
  
  
  @override
  bool shouldRepaint(CablePainter oldDelegate) {
    // Repaint if cables or nodes have changed
    // The Listenable passed to super() handles position changes
    return cables != oldDelegate.cables || nodes != oldDelegate.nodes;
  }
}

class NewCablePainter extends CustomPainter {
  final Pin startPin;
  final Offset endOffset;
  final TransformationController transformationController;
  
  NewCablePainter({
    required this.startPin, 
    required this.endOffset,
    required this.transformationController,
  });

  @override
  void paint(Canvas canvas, ui.Size size) {
    // Calculate start position from pin (in scene coordinates)
    var nodePosition = startPin.node.position;
    double snap(double v) {
      final g = GlobalSettings.gridSize.toDouble();
      return (v / g).roundToDouble() * g;
    }
    Offset startPos = Offset(
      startPin.offset.dx + snap(nodePosition.$1) + 15 / 2,
      startPin.offset.dy + snap(nodePosition.$2) + 15 / 2,
    );
    
    // Convert global end offset to scene coordinates
    Offset sceneEndOffset = transformationController.toScene(endOffset);
    
    // Get the endpoint to determine color
    var endpoint = startPin.endpoint;
    
    // Get color for this endpoint type
    Color color = ProjectTheme.getColor(endpoint.type);
    
    // Paint the cable using the same style as the original ConnectorPainter
    _paintCablePath(canvas, startPos, sceneEndOffset, color);
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