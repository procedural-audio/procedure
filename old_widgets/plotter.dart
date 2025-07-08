import 'dart:typed_data';

import 'package:flutter/material.dart';

import 'dart:ffi';
import 'dart:ui' as ui;

import 'widget.dart';

import '../core.dart';
import '../module/node.dart';

double Function(RawWidgetPointer) ffiPlotterGetValue = core
    .lookup<NativeFunction<Float Function(RawWidgetPointer)>>(
        "ffi_plotter_get_value")
    .asFunction();
int Function(RawWidgetPointer) ffiPlotterGetColor = core
    .lookup<NativeFunction<Int32 Function(RawWidgetPointer)>>(
        "ffi_plotter_get_color")
    .asFunction();
double Function(RawWidgetPointer) ffiPlotterGetThickness = core
    .lookup<NativeFunction<Float Function(RawWidgetPointer)>>(
        "ffi_plotter_get_thickness")
    .asFunction();

const int pointsCount = 50;

class PlotterWidget extends ModuleWidget {
  PlotterWidget(Node n, RawNode m, RawWidget w) : super(n, m, w);

  double width = 100;
  double height = 100;

  ValueNotifier<Float32List> points = ValueNotifier(
    Float32List(pointsCount * 2),
  );

  int counter = 0;

  @override
  void tick() {
    if (counter % 10 == 0) {
      for (var i = pointsCount * 2 - 1; i >= 2; i--) {
        if (i % 2 == 0) {
          points.value[i] = width * (i.toDouble() / 2) / pointsCount.toDouble();
        } else {
          points.value[i] = points.value[i - 2];
        }
      }

      double value = ffiPlotterGetValue(widgetRaw.pointer);
      value = value.clamp(0.0, 1.0);
      value = (1 - value);
      value = value * height;

      points.value[0] = 0;
      points.value[1] = value;
      points.notifyListeners();
    } else {
      counter += 1;
    }
  }

  @override
  Widget build(BuildContext context) {
    Color color = intToColor(ffiPlotterGetColor(widgetRaw.pointer));
    double thickness = ffiPlotterGetThickness(widgetRaw.pointer);

    return LayoutBuilder(
      builder: (context, constraints) {
        width = constraints.maxWidth;
        height = constraints.maxHeight;
        return ClipRect(
          child: CustomPaint(
            painter: PlotterPainter(
              points: points,
              color: color,
              thickness: thickness,
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
