import 'package:flutter/material.dart';

import 'dart:convert';

import '../settings.dart';
import 'node.dart';

import 'patch.dart';
import 'connector.dart';

import '../bindings/api/endpoint.dart';

// Radius of a pin
const double pinRadius = 6;

// Convert an endpoint to a color
Color endpointToColor(NodeEndpoint endpoint) {
  Color color = Colors.grey;

  // Switch on the endpoint kind
  switch (endpoint.kind) {
    // Stream types
    case EndpointKind.stream:
      color = Colors.blue;
      break;

    // Event and value types
    case EndpointKind.event || EndpointKind.value:
      endpoint.type.when(
        float: () => color = Colors.red,
        int: () => color = Colors.red,
        bool: () => color = Colors.red,
        object: (a) => color = Colors.green,
        unsupported: () => color = Color.fromRGBO(50, 50, 50, 1.0),
        void_: () => color = Colors.grey,
      );

      break;
  }

  return color;
}

class Pin extends StatefulWidget {
  Pin({
    required this.node,
    required this.endpoint,
    required this.patch,
    required this.onAddConnector,
    required this.onRemoveConnections,
  }) : super(key: UniqueKey()) {
    var annotation = jsonDecode(endpoint.annotation);
    var top = double.tryParse(annotation['pinTop'].toString()) ?? 0.0;

    // Initialize the pin offset
    if (endpoint.isInput()) {
      offset = Offset(5, top);
    } else {
      offset = Offset(
          node.module.size.width * GlobalSettings.gridSize -
              (pinRadius * 2 + 10),
          top);
    }

    // Initialize the pin color
    color = endpointToColor(endpoint);
  }

  final NodeEndpoint endpoint;
  final Node node;
  final Patch patch;
  final void Function(Pin, Pin) onAddConnector;
  final void Function(Pin) onRemoveConnections;

  Offset offset = Offset(0, 0);
  Color color = Colors.white;

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
          widget.node.patch.newConnector.setEnd(widget);
          setState(() {
            hovering = true;
          });
        },
        onExit: (e) {
          widget.node.patch.newConnector.setEnd(null);
          setState(() {
            hovering = false;
          });
        },
        child: GestureDetector(
          onPanStart: (details) {
            dragging = true;
            if (widget.endpoint.isInput()) {
              widget.node.patch.newConnector.onDrag(details.localPosition);
            } else {
              widget.node.patch.newConnector.setStart(widget);
            }
          },
          onPanUpdate: (details) {
            widget.node.patch.newConnector.onDrag(details.localPosition);
          },
          onPanEnd: (details) {
            widget.node.patch.addNewConnector();
            setState(() {
              dragging = false;
            });
          },
          onPanCancel: () {
            widget.node.patch.newConnector.reset();
            setState(() {
              dragging = false;
            });
          },
          onDoubleTap: () {
            widget.onRemoveConnections(widget);
          },
          child: ValueListenableBuilder<List<Connector>>(
            valueListenable: widget.patch.connectors,
            builder: (context, connectors, child) {
              bool connected = false;
              for (var connector in connectors) {
                if (connector.start == widget || connector.end == widget) {
                  connected = true;
                  break;
                }
              }

              return ValueListenableBuilder<List<Node>>(
                valueListenable: widget.patch.selectedNodes,
                builder: (context, selectedNodes, child) {
                  bool is_selected = selectedNodes.contains(widget.node);

                  return Container(
                    width: pinRadius * 2,
                    height: pinRadius * 2,
                    child: CustomPaint(
                      painter: PinPainter(
                        color: widget.color,
                        kind: widget.endpoint.kind,
                        selected: is_selected,
                        hovering: hovering,
                        dragging: dragging,
                        connected: connected,
                      ),
                    ),
                  );
                },
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
    required this.kind,
    required this.selected,
    required this.hovering,
    required this.dragging,
    required this.connected,
  });

  final Color color;
  final EndpointKind kind;
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

    switch (kind) {
      case EndpointKind.stream:
        path.addOval(Rect.fromCircle(center: center, radius: radius));
        break;
      case EndpointKind.event:
        final cornerRadius = pinRadius / 3; // Adjust for more/less rounding

        // Define the three corners of a triangle
        final p1 = Offset(center.dx - radius, center.dy - radius);
        final p2 = Offset(center.dx - radius, center.dy + radius);
        final p3 = Offset(center.dx + radius, center.dy);

        // Start at the center
        path.moveTo(p1.dx, p1.dy + radius);

        // Bottom-left corner
        path.lineTo(p2.dx, p2.dy - cornerRadius);
        path.quadraticBezierTo(p2.dx, p2.dy, p2.dx + cornerRadius, p2.dy);

        // Right-center corner
        path.lineTo(p3.dx - cornerRadius, p3.dy + cornerRadius);
        path.quadraticBezierTo(p3.dx + cornerRadius, p3.dy,
            p3.dx - cornerRadius, p3.dy - cornerRadius);

        // Top-left corner
        path.lineTo(p1.dx + cornerRadius, p1.dy);
        path.quadraticBezierTo(p1.dx, p1.dy, p1.dx, p1.dy + cornerRadius);

        // Return to the center
        path.lineTo(p1.dx, p1.dy + radius);

        break;
      case EndpointKind.value:
        var rect = Rect.fromCircle(center: center, radius: radius);
        path.addRRect(RRect.fromRectAndRadius(rect, Radius.circular(3)));
        break;
    }

    if (hovering || dragging || (selected && connected)) {
      canvas.drawPath(path, paint);
      paint.style = PaintingStyle.fill;
      canvas.drawPath(path, paint);
    } else if (connected) {
      canvas.drawPath(path, paint);
      paint.color = color.withOpacity(0.5);
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
