import 'dart:typed_data';

import 'package:flutter/material.dart';

import 'dart:ffi';
import 'dart:ui' as ui;

import 'widget.dart';

import '../core.dart';
import '../module/node.dart';

int Function(RawWidgetTrait) ffiPainter2GetStrokeWidth = core
    .lookup<NativeFunction<Int32 Function(RawWidgetTrait)>>(
        "ffi_painter2_get_stroke_width")
    .asFunction();
int Function(RawWidgetTrait) ffiPainter2GetColor = core
    .lookup<NativeFunction<Int32 Function(RawWidgetTrait)>>(
        "ffi_painter2_get_color")
    .asFunction();
double Function(RawWidgetTrait, double) ffiPainter2Paint = core
    .lookup<NativeFunction<Float Function(RawWidgetTrait, Float)>>(
        "ffi_painter2_paint")
    .asFunction();

const int pointsCount = 50;

class Painter2Widget extends ModuleWidget {
  Painter2Widget(Node n, RawNode m, RawWidget w) : super(n, m, w);

  double width = 100;
  double height = 100;

  ValueNotifier<Float32List> points = ValueNotifier(
    Float32List(pointsCount * 2),
  );

  int counter = 0;

  @override
  void tick() {
    if (counter % 10 == 0) {
      for (var i = 0; i < pointsCount * 2; i++) {
        if (i % 2 == 0) {
          points.value[i] = width * (i.toDouble() / 2) / pointsCount.toDouble();
        } else {
          var v = ffiPainter2Paint(
            widgetRaw.getTrait(),
            (i.toDouble() / 2) / pointsCount.toDouble(),
          );

          points.value[i] = (1.0 - v) * height;
        }
      }

      points.notifyListeners();
    } else {
      counter += 1;
    }
  }

  @override
  Widget build(BuildContext context) {
    Color color = intToColor(ffiPainter2GetColor(widgetRaw.getTrait()));
    int strokeWidth = ffiPainter2GetStrokeWidth(widgetRaw.getTrait());

    return LayoutBuilder(
      builder: (context, constraints) {
        width = constraints.maxWidth;
        height = constraints.maxHeight;
        return ClipRect(
          child: CustomPaint(
            painter: PlotterPainter(
              points: points,
              color: color,
              thickness: strokeWidth.toDouble(),
            ),
            child: const SizedBox.expand(),
          ),
        );
      },
    );
  }
}

class PlotterPainter extends CustomPainter {
  PlotterPainter({
    required this.points,
    required this.thickness,
    required this.color,
  }) : super(repaint: points) {
    p.strokeWidth = thickness;
    p.color = color;
  }

  final ValueNotifier<Float32List> points;
  double thickness;
  Color color;

  final Paint p = Paint()
    ..strokeWidth = 2
    ..strokeCap = StrokeCap.round;

  @override
  void paint(Canvas canvas, ui.Size size) {
    canvas.drawRawPoints(ui.PointMode.polygon, points.value, p);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}
