import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:metasampler/settings.dart';

import '../bindings/api/endpoint.dart';
import '../plugin/plugin.dart';
import 'node.dart';
import 'pin.dart';
import 'patch.dart';

class Connector extends StatefulWidget {
  Connector({
    required this.start,
    required this.end,
    required this.patch,
  }) : super(key: UniqueKey());

  final Pin start;
  final Pin end;
  final Patch patch;

  Map<String, dynamic> getState() {
    return {
      "startNode": start.node.module.file.path,
      // "startIndex": start.,
      "endNode": end.node.module.file.path,
      // "endIndex": end.pinIndex,
    };
  }

  State<StatefulWidget> createState() => _Connector();
}

class _Connector extends State<Connector> with SingleTickerProviderStateMixin {

  late Ticker _ticker;
  late AnimationController _controller;
  ValueNotifier<double> sinceLastUpdate = ValueNotifier(0.0);

  int blocksPerDot = 20;

  @override
  void initState() {
    super.initState();

    // Ticker
    _ticker = createTicker((Duration elapsed) {
      if (_controller.isAnimating) {
        sinceLastUpdate.value += elapsed.inMilliseconds.toDouble() / _controller.duration!.inMilliseconds.toDouble();
      } else {
        if (widget.start.endpoint.feedbackValue()) {
          sinceLastUpdate.value = 0;
          _controller.forward(from: 0.0);
        }
      }
    });

    _ticker.start();

    // Animation
    var blocksPerSecond = widget.patch.sampleRate ~/ widget.patch.blockSize;
    var secondsPerBlock = 1.0 / blocksPerSecond;
    var millisecondsPerBlock = (1000 * secondsPerBlock).toInt();

    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: millisecondsPerBlock * blocksPerDot),
    );// ..repeat(reverse: false);
  }

  @override
  void dispose() {
    _ticker.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  void tick() {

  }

  void update() {
    _controller.value = 0.0;
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<Node>>(
      valueListenable: widget.patch.selectedNodes,
      builder: (context, selectedNodes, child) {
        bool focused = selectedNodes.contains(widget.start.node) ||
            selectedNodes.contains(widget.end.node);
        return ValueListenableBuilder<Offset>(
          valueListenable: widget.start.node.position,
          builder: (context, startModuleOffset, child) {
            return ValueListenableBuilder<Offset>(
              valueListenable: widget.end.node.position,
              builder: (context, endModuleOffset, child) {
                return CustomPaint(
                  painter: ConnectorPainter(
                    Offset(
                      widget.start.offset.dx +
                          roundToGrid(startModuleOffset.dx) +
                          pinRadius,
                      widget.start.offset.dy +
                          roundToGrid(startModuleOffset.dy) +
                          pinRadius,
                    ),
                    Offset(
                      widget.end.offset.dx +
                          roundToGrid(endModuleOffset.dx) +
                          pinRadius,
                      widget.end.offset.dy +
                          roundToGrid(endModuleOffset.dy) +
                          pinRadius,
                    ),
                    widget.patch.theme.getColor(widget.start.endpoint.type, widget.start.endpoint.kind),
                    focused,
                    _controller,
                    widget.start.endpoint.kind,
                    sinceLastUpdate,
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

class NewConnector extends StatefulWidget {
  Pin? start;
  final ValueNotifier<Offset?> offset = ValueNotifier(null);
  Pin? end;
  // AnimationController _controller = AnimationController(vsync: this);

  NewConnector({super.key});

  void setStart(Pin? pin) {
    start = pin;
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

  State<StatefulWidget> createState() => _NewConnector();
}

class _NewConnector extends State<NewConnector> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    )..repeat(reverse: false);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Offset?>(
      valueListenable: widget.offset,
      builder: (context, offset, child) {
        if (widget.start != null && offset != null) {
          var startOffset = Offset(
            widget.start!.offset.dx + widget.start!.node.position.value.dx + 15 / 2,
            widget.start!.offset.dy + widget.start!.node.position.value.dy + 15 / 2,
          );

          var endOffset = Offset(
            startOffset.dx + offset.dx - 15 / 2,
            startOffset.dy + offset.dy - 15 / 2,
          );

          return CustomPaint(
            painter: ConnectorPainter(
              startOffset,
              endOffset,
              widget.start!.patch.theme.getColor(widget.start!.endpoint.type, widget.start!.endpoint.kind),
              true,
              _controller,
              widget.start!.endpoint.kind,
              ValueNotifier(0.0),
            ),
          );
        } else {
          return Container();
        }
      },
    );
  }
}

class ConnectorPainter extends CustomPainter implements Listenable {
  ConnectorPainter(
    this.initialStart,
    this.initialEnd,
    this.color,
    this.focused,
    this.animation,
    this.kind,
    this.sinceLastUpdate
  ) : super(repaint: animation);

  Animation<double> animation;
  ValueNotifier<double> sinceLastUpdate;
  Offset initialStart;
  Offset initialEnd;
  Color color;
  bool focused;
  Random source = Random();
  EndpointKind kind;

  @override
  void paint(Canvas canvas, ui.Size size) {
    final paint = Paint()
      ..color = const Color.fromRGBO(255, 255, 255, 1.0)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    
    double activeOpacity = 1.0;
    double inactiveOpacity = 0.3;
    
    paint.color = color.withOpacity(focused ? activeOpacity : inactiveOpacity);

    Offset start = Offset(initialStart.dx + 9, initialStart.dy + 2);
    Offset end = Offset(initialEnd.dx - 3, initialEnd.dy + 2);

    double distance = (end - start).distance;
    double firstOffset = min(distance, 40);

    Offset start1 = Offset(start.dx + firstOffset, start.dy);
    Offset end1 = Offset(end.dx - firstOffset, end.dy);
    Offset center = Offset((start.dx + end.dx) / 2, (start.dy + end.dy) / 2);

    // Draw path
    Path path = Path();
    path.moveTo(start.dx, start.dy);
    path.quadraticBezierTo(start1.dx + 10, start1.dy, center.dx, center.dy);
    path.quadraticBezierTo(end1.dx - 10, end1.dy, end.dx, end.dy);
    canvas.drawPath(path, paint);

    double totalLength = pathLength(path);

    if (totalLength > GlobalSettings.gridSize) {
      if (kind == EndpointKind.value && animation.isAnimating) {
        final animationPaint = Paint()
          ..color = color
          ..style = PaintingStyle.fill
          ..strokeWidth = 3;

        animationPaint.color = color.withOpacity(1.0 - (animation.value * (activeOpacity - inactiveOpacity)));

        double segmentLength = 50;
        double segmentCount = totalLength / segmentLength;
        double segmentFraction = segmentLength / totalLength;

        for (int i = 0; i < segmentCount.ceil(); i++) {
          double fraction = (animation.value / segmentCount) + i.toDouble() * segmentFraction;

          // Don't draw past total length
          if (fraction < 1.0) {
            // Draw animated point
            var point = pointAlongMultipleContours(path, fraction);
            if (point != null) {
              canvas.drawCircle(point, 2.0, animationPaint);
            }
          }
        }
      } else if (kind == EndpointKind.stream) {
        double totalOffset = 8.0;
        double step = 2.0;

        final animationPaint = Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = step;

        for (double offset = -totalOffset; offset <= totalOffset; offset += step) {
          double distance = 1.0 - sqrt(pow(offset, 2)).toDouble() / totalOffset;
          animationPaint.color = color.withOpacity(animation.value * distance);
          Path path = Path();

          path.moveTo(start.dx, start.dy + offset);

          if (start.dy >= end.dy) {
            path.quadraticBezierTo(start1.dx + 10, start1.dy + offset, center.dx + offset, center.dy + offset);
            path.quadraticBezierTo(end1.dx - 10, end1.dy + offset, end.dx, end.dy + offset);
          } else {
            path.quadraticBezierTo(start1.dx + 10, start1.dy + offset, center.dx + offset, center.dy + offset);
            path.quadraticBezierTo(end1.dx - 10, end1.dy + offset, end.dx, end.dy + offset);
          }

          canvas.drawPath(path, animationPaint);
        }
      }
    }
  }

  double pathLength(Path path) {
    final pathMetrics = path.computeMetrics(forceClosed: false).toList();
    double totalLength = 0;
    for (final pm in pathMetrics) {
      totalLength += pm.length;
    }

    return totalLength;
  }

  Offset? pointAlongMultipleContours(Path path, double fraction) {
    if (fraction < 0.0) fraction = 0.0;
    if (fraction > 1.0) fraction = 1.0;

    // 1. Compute all metrics and total length.
    final pathMetrics = path.computeMetrics(forceClosed: false).toList();
    double totalLength = 0;
    for (final pm in pathMetrics) {
      totalLength += pm.length;
    }

    // 2. Convert fraction -> absolute distance.
    final targetDistance = totalLength * fraction;

    // 3. Find which contour (PathMetric) contains that targetDistance.
    double runningLength = 0.0;
    for (final pm in pathMetrics) {
      // If this segment contains the target distance
      if (targetDistance <= runningLength + pm.length) {
        final distanceWithinSegment = targetDistance - runningLength;
        // 4. Get the tangent for the offset within this contour
        final tangent = pm.getTangentForOffset(distanceWithinSegment);
        return tangent?.position;
      }
      runningLength += pm.length;
    }

    // If fraction == 1.0, or something else happened, just return last point of last contour.
    final lastMetric = pathMetrics.last;
    return lastMetric.getTangentForOffset(lastMetric.length)?.position;
  }

  @override
  bool shouldRepaint(ConnectorPainter oldDelegate) {
    // return true;
    return oldDelegate.initialStart.dx != initialStart.dx ||
        oldDelegate.initialStart.dy != initialStart.dy ||
        oldDelegate.initialEnd.dx != initialEnd.dy ||
        oldDelegate.initialEnd.dy != initialEnd.dy ||
        oldDelegate.color != color;
  }
}
