import 'package:flutter/material.dart';
import 'package:procedure/bindings/api/node.dart' as rust_node;
import 'package:procedure/bindings/api/endpoint.dart';

import 'dart:convert';

import '../settings.dart';
import '../project/theme.dart';

// Radius of a pin
const double pinRadius = 6;

class Pin extends StatefulWidget {
  Pin({
    required this.node,
    required this.endpoint,
    required this.isConnected,
    required this.onAddConnector,
    required this.onRemoveConnections,
    required this.onNewCableDrag,
    required this.onNewCableSetStart,
    required this.onNewCableSetEnd,
    required this.onNewCableReset,
    required this.onAddNewCable,
  }) : offset = _calculateOffset(node, endpoint),
       super(key: ValueKey('pin_${node.module.title}_${endpoint.annotation}_${endpoint.isInput}'));
  
  static Offset _calculateOffset(rust_node.Node node, NodeEndpoint endpoint) {
    var annotation = jsonDecode(endpoint.annotation);
    var top = double.tryParse(annotation['pinTop'].toString()) ?? 0.0;

    // Initialize the pin offset
    if (endpoint.isInput) {
      return Offset(5, top);
    } else {
      return Offset(
          node.module.size.$1 * GlobalSettings.gridSize -
              (pinRadius * 2 + 10),
          top);
    }
  }

  final rust_node.Node node;
  final NodeEndpoint endpoint;
  final bool Function(rust_node.Node, NodeEndpoint) isConnected;
  final void Function(Pin, Pin) onAddConnector;
  final void Function(Pin) onRemoveConnections;
  final void Function(Offset) onNewCableDrag;
  final void Function(Pin) onNewCableSetStart;
  final void Function(Pin?) onNewCableSetEnd;
  final VoidCallback onNewCableReset;
  final VoidCallback onAddNewCable;

  final Offset offset;

  @override
  _PinState createState() => _PinState();
}

class _PinState extends State<Pin> {
  bool hovering = false;
  bool dragging = false;

  // This will be passed from parent widget that manages the cables list
  bool _isPinConnected() {
    return widget.isConnected(widget.node, widget.endpoint);
  }

  @override
  Widget build(BuildContext context) {
    // Endpoint is now directly available
    var endpoint = widget.endpoint;

    return Positioned(
      left: widget.offset.dx,
      top: widget.offset.dy,
        child: MouseRegion(
          onEnter: (e) {
            widget.onNewCableSetEnd(widget);
            setState(() {
              hovering = true;
            });
          },
          onExit: (e) {
            widget.onNewCableSetEnd(null);
            setState(() {
              hovering = false;
            });
          },
          child: GestureDetector(
            behavior: HitTestBehavior.opaque, // Be more assertive in claiming gestures
            onPanStart: (details) {
              print("Pin pan start");
              setState(() {
                dragging = true;
              });
              widget.onNewCableSetStart(widget);
            },
            onPanUpdate: (details) {
              widget.onNewCableDrag(details.globalPosition);
            },
            onPanEnd: (details) {
              print("Pin pan end");
              setState(() {
                dragging = false; // ✅ Fixed: Now using setState
              });
              widget.onAddNewCable();
            },
            onPanCancel: () {
              setState(() {
                dragging = false; // ✅ Fixed: Now using setState
              });
              widget.onNewCableReset();
            },
            onDoubleTap: () {
              widget.onRemoveConnections(widget);
            },
          child: Builder(
            builder: (context) {
              // Check if this pin has any connected cables
              bool connected = _isPinConnected();
              
              bool is_selected = false; // Simplified for now
              var kind = endpoint.kind;
              var type = endpoint.type;

              Map<String, dynamic> ann = {};
              try { ann = jsonDecode(endpoint.annotation); } catch (_) {}
              final String epName = (ann['name'] is String) ? ann['name'] as String : '';
              final String tooltipText = epName.isNotEmpty ? '$type - $epName' : type;

              final bool isInput = endpoint.isInput;
              final double dx = isInput ? -(140.0) : (pinRadius * 2 + 8);
              final Alignment align = isInput ? Alignment.centerRight : Alignment.centerLeft;

              return Stack(
                clipBehavior: Clip.none,
                children: [
                  SizedBox(
                    width: pinRadius * 2,
                    height: pinRadius * 2,
                    child: CustomPaint(
                      painter: PinPainter(
                        color: ProjectTheme.getColor(type),
                        shape: ProjectTheme.getShape(kind),
                        selected: is_selected,
                        hovering: hovering,
                        dragging: dragging,
                        connected: connected,
                      ),
                    ),
                  ),
                  if (hovering)
                    Positioned(
                      left: dx,
                      top: -6,
                      child: Align(
                        alignment: align,
                        child: Container(
                          constraints: const BoxConstraints(maxWidth: 180),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color.fromRGBO(30, 30, 30, 0.95),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: const Color.fromRGBO(60, 60, 60, 1.0), width: 1),
                          ),
                          child: Text(
                            tooltipText,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class PinPainter extends CustomPainter {
  PinPainter({
    required this.color,
    required this.shape,
    required this.selected,
    required this.hovering,
    required this.dragging,
    required this.connected,
  });

  final Color color;
  final PinShape shape;
  final bool selected;
  final bool hovering;
  final bool dragging;
  final bool connected;

  @override
  void paint(Canvas canvas, Size size) {
    var paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    var center = Offset(size.width / 2, size.height / 2);
    var radius = size.width / 2;

    Path path = Path();

    switch (shape) {
      case PinShape.circle:
        path.addOval(Rect.fromCircle(center: center, radius: radius));
        break;
      case PinShape.triangle:
        final corner = pinRadius / 3;
        // Define the three corners of a triangle
        final p1 = Offset(center.dx - radius, center.dy - radius);
        final p2 = Offset(center.dx - radius, center.dy + radius);
        final p3 = Offset(center.dx + radius, center.dy);

        // Start at the center
        path.moveTo(p1.dx, p1.dy + radius);

        // Bottom-left corner
        path.lineTo(p2.dx, p2.dy - corner);
        path.quadraticBezierTo(p2.dx, p2.dy, p2.dx + corner, p2.dy);

        // Right-center corner
        path.lineTo(p3.dx - corner, p3.dy + corner);
        path.quadraticBezierTo(
            p3.dx + corner, p3.dy, p3.dx - corner, p3.dy - corner);

        // Top-left corner
        path.lineTo(p1.dx + corner, p1.dy);
        path.quadraticBezierTo(p1.dx, p1.dy, p1.dx, p1.dy + corner);

        // Return to the center
        path.lineTo(p1.dx, p1.dy + radius);

        break;
      case PinShape.square:
        var rect = Rect.fromCircle(center: center, radius: radius);
        path.addRRect(RRect.fromRectAndRadius(rect, Radius.circular(3)));
        break;
      case PinShape.diamond:
        final corner = pinRadius / 6;
        // Top corner
        path.moveTo(center.dx + corner, corner);
        path.quadraticBezierTo(center.dx, 0, center.dx - corner, corner);

        // Left corner
        path.lineTo(corner, center.dy - corner);
        path.quadraticBezierTo(0.0, center.dy, corner, center.dy + corner);

        // Bottom corner
        path.lineTo(center.dx - corner, size.height - corner);
        path.quadraticBezierTo(
            center.dx, size.height, center.dx + corner, size.height - corner);

        // Right corner
        path.lineTo(size.width - corner, center.dy + corner);
        path.quadraticBezierTo(
            size.width, center.dy, size.width - corner, center.dy - corner);

        path.lineTo(center.dx + corner, corner);

        /*path.moveTo(center.dx, 0.0);
        path.lineTo(0.0, center.dy);
        path.lineTo(center.dx, size.height);
        path.lineTo(size.width, center.dy);
        path.lineTo(center.dx, 0.0);*/
        break;
      case PinShape.unknown:
        var l = size.width / 4;
        var r = size.width * 3 / 4;
        var t = size.width / 4;
        var b = size.width * 3 / 4;

        path.moveTo(l, t);
        path.lineTo(r, b);
        path.moveTo(l, b);
        path.lineTo(r, t);
        break;
    }

    if (hovering || dragging || (selected && connected)) {
      canvas.drawPath(path, paint);
      paint.style = PaintingStyle.fill;
      canvas.drawPath(path, paint);
    } else if (connected) {
      canvas.drawPath(path, paint);
      paint.color = color.withValues(alpha: 0.5);
      paint.style = PaintingStyle.fill;
      canvas.drawPath(path, paint);
    } else {
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
