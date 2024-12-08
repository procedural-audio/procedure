import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../bindings/api/endpoint.dart';
import '../module/module.dart';
import '../module/node.dart';
import '../module/pin.dart';
import 'patch.dart';

class Connector extends StatelessWidget {
  Connector({
    required this.start,
    required this.end,
    required this.type,
    required this.patch,
  }) : super(key: UniqueKey());

  final Pin start;
  final Pin end;
  final EndpointType type;
  final Patch patch;

  Map<String, dynamic> toJson() {
    return {
      // "startId": start.nodeId,
      // "startIndex": start.pinIndex,
      // "endId": end.nodeId,
      // "endIndex": end.pinIndex,
      "type": type.toString(),
    };
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<Node>>(
      valueListenable: patch.selectedNodes,
      builder: (context, selectedNodes, child) {
        bool focused = selectedNodes.contains(start.node) ||
            selectedNodes.contains(end.node);
        return ValueListenableBuilder<Offset>(
          valueListenable: start.node.position,
          builder: (context, startModuleOffset, child) {
            return ValueListenableBuilder<Offset>(
              valueListenable: end.node.position,
              builder: (context, endModuleOffset, child) {
                return CustomPaint(
                  painter: ConnectorPainter(
                    Offset(
                      start.offset.dx + startModuleOffset.dx + 15 / 2,
                      start.offset.dy + startModuleOffset.dy + 15 / 2,
                    ),
                    Offset(
                      end.offset.dx + endModuleOffset.dx + 15 / 2,
                      end.offset.dy + endModuleOffset.dy + 15 / 2,
                    ),
                    start.color,
                    focused,
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}

class NewConnector extends StatelessWidget {
  Pin? start;
  final ValueNotifier<Offset?> offset = ValueNotifier(null);
  Pin? end;
  EndpointType type = EndpointType.stream(StreamType.float32);

  NewConnector({super.key});

  void setStart(Pin? pin) {
    start = pin;
    if (pin != null) {
      type = pin.endpoint.type;
    }
  }

  void setEnd(Pin? pin) {
    end = pin;
  }

  void onDrag(Offset offset) {
    this.offset.value = offset;
  }

  void reset() {
    start = null;
    end = null;
    offset.value = null;
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Offset?>(
      valueListenable: offset,
      builder: (context, offset, child) {
        if (start != null && offset != null) {
          var startOffset = Offset(
            start!.offset.dx + start!.node.position.value.dx + 15 / 2,
            start!.offset.dy + start!.node.position.value.dy + 15 / 2,
          );

          var endOffset = Offset(
            startOffset.dx + offset.dx - 15 / 2,
            startOffset.dy + offset.dy - 15 / 2,
          );

          return CustomPaint(
            painter: ConnectorPainter(
              startOffset,
              endOffset,
              start!.color,
              true,
            ),
          );
        } else {
          return Container();
        }
      },
    );
  }
}

class ConnectorPainter extends CustomPainter {
  ConnectorPainter(
    this.initialStart,
    this.initialEnd,
    this.color,
    this.focused,
  );

  Offset initialStart;
  Offset initialEnd;
  Color color;
  bool focused;

  @override
  void paint(Canvas canvas, ui.Size size) {
    final paint = Paint()
      ..color = const Color.fromRGBO(255, 255, 255, 1.0)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    paint.color = color.withOpacity(focused ? 1.0 : 0.3);

    Offset start = Offset(initialStart.dx + 9, initialStart.dy + 2);
    Offset end = Offset(initialEnd.dx - 3, initialEnd.dy + 2);

    double distance = (end - start).distance;
    double firstOffset = min(distance, 40);

    Offset start1 = Offset(start.dx + firstOffset, start.dy);
    Offset end1 = Offset(end.dx - firstOffset, end.dy);
    Offset center = Offset((start.dx + end.dx) / 2, (start.dy + end.dy) / 2);

    Path path = Path();

    path.moveTo(start.dx, start.dy);
    path.quadraticBezierTo(start1.dx + 10, start1.dy, center.dx, center.dy);

    path.moveTo(end.dx, end.dy);
    path.quadraticBezierTo(end1.dx - 10, end1.dy, center.dx, center.dy);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(ConnectorPainter oldDelegate) {
    return oldDelegate.initialStart.dx != initialStart.dx ||
        oldDelegate.initialStart.dy != initialStart.dy ||
        oldDelegate.initialEnd.dx != initialEnd.dy ||
        oldDelegate.initialEnd.dy != initialEnd.dy ||
        oldDelegate.color != color;
  }
}
