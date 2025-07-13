import 'package:flutter/material.dart';
import 'package:metasampler/bindings/api/patch.dart' as rust_patch;
import 'package:metasampler/utils.dart';

import 'dart:convert';

import '../plugin/plugin.dart';
import '../settings.dart';
import 'node.dart';

import 'patch.dart';

import '../bindings/api/endpoint.dart';
import '../project/theme.dart';

// Radius of a pin
const double pinRadius = 6;

class Pin extends StatefulWidget {
  Pin({
    required this.nodeId,
    required this.patch,
    required this.endpoint,
    required this.onAddConnector,
    required this.onRemoveConnections,
    required this.onNewCableDrag,
    required this.onNewCableSetStart,
    required this.onNewCableSetEnd,
    required this.onNewCableReset,
    required this.onAddNewCable,
  }) : super(key: UniqueKey()) {
    var annotation = jsonDecode(endpoint.annotation);
    var top = double.tryParse(annotation['pinTop'].toString()) ?? 0.0;

    // Get module to calculate offset
    var module = patch.getNodeModule(nodeId: nodeId);
    if (module != null) {
      // Initialize the pin offset
      if (endpoint.isInput) {
        offset = Offset(5, top);
      } else {
        offset = Offset(
            module.size.$1 * GlobalSettings.gridSize -
                (pinRadius * 2 + 10),
            top);
      }
    } else {
      offset = Offset(5, top);
    }
  }

  final int nodeId;
  final rust_patch.Patch patch;
  final NodeEndpoint endpoint;
  final void Function(Pin, Pin) onAddConnector;
  final void Function(Pin) onRemoveConnections;
  final void Function(Offset) onNewCableDrag;
  final void Function(Pin) onNewCableSetStart;
  final void Function(Pin?) onNewCableSetEnd;
  final VoidCallback onNewCableReset;
  final VoidCallback onAddNewCable;

  Offset offset = Offset(0, 0);

  @override
  _PinState createState() => _PinState();
}

class _PinState extends State<Pin> {
  bool hovering = false;
  bool dragging = false;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: widget.offset.dx,
      top: widget.offset.dy,
      child: MouseRegion(
        onEnter: (e) {
          // print("Setting new connector end");
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
          behavior: HitTestBehavior.opaque,
          onPanStart: (details) {
            setState(() {
              dragging = true;
            });
            widget.onNewCableSetStart(widget);
          },
          onPanUpdate: (details) {
            widget.onNewCableDrag(details.globalPosition);
          },
          onPanEnd: (details) {
            widget.onAddNewCable();
            setState(() {
              dragging = false;
            });
          },
          onPanCancel: () {
            widget.onNewCableReset();
            setState(() {
              dragging = false;
            });
          },
          onDoubleTap: () {
            widget.onRemoveConnections(widget);
          },
          child: Builder(
            builder: (context) {
              bool connected = false;
              // print("TODO fix conectors");
              /*for (var connector in widget.patch.connectors) {
                if (connector.start == widget || connector.end == widget) {
                  connected = true;
                  break;
                }
              }*/
              
              bool is_selected = false; // Simplified for now
                  var kind = widget.endpoint.kind;
                  var type = widget.endpoint.type;
                  return Container(
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
