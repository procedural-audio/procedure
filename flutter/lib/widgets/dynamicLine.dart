import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:ffi/ffi.dart';

import 'dart:ffi';

import '../host.dart';
import 'widget.dart';
import '../core.dart';
import '../module.dart';
import '../main.dart';

double Function(FFIWidgetPointer) ffiDynamicLineGetValue = core
    .lookup<NativeFunction<Float Function(FFIWidgetPointer)>>(
        "ffi_dynamic_line_get_value")
    .asFunction();
double Function(FFIWidgetPointer) ffiDynamicLineGetWidth = core
    .lookup<NativeFunction<Float Function(FFIWidgetPointer)>>(
        "ffi_dynamic_line_get_width")
    .asFunction();
int Function(FFIWidgetPointer) ffiDynamicLineGetColor = core
    .lookup<NativeFunction<Int32 Function(FFIWidgetPointer)>>(
        "ffi_dynamic_line_get_color")
    .asFunction();

class DynamicLineWidget extends ModuleWidget {
  DynamicLineWidget(App a, RawNode m, FFIWidget w) : super(a, m, w) {
    color = Color(ffiDynamicLineGetColor(w.pointer));
  }

  late Color color;
  int count = 50;
  List<double> values = [];

  @override
  void tick() {
    while (values.length < count) {
      values.add(1.0);
    }

    double value = ffiDynamicLineGetValue(widgetRaw.pointer);
    if (value > 1.0) {
      value = 1.0;
    }

    if (value < 0.0) {
      value = 0.0;
    }
    ;
    values.add(1.0 - value);
    values.removeAt(0);

    refresh();
  }

  @override
  Widget build(BuildContext context) {
    double width = ffiDynamicLineGetWidth(widgetRaw.pointer);

    return CustomPaint(
        size: const ui.Size(250, 150),
        painter: DynamicLinePainter(values, count, width, color));
  }
}

class DynamicLinePainter extends CustomPainter {
  DynamicLinePainter(this.values, this.count, this.width, this.color);

  List<double> values;
  Color color;
  int count;
  double width;

  List<Offset> points = [];

  @override
  void paint(Canvas canvas, ui.Size size) {
    Paint paint = Paint()
      ..strokeWidth = width
      ..style = PaintingStyle.stroke
      ..color = color;

    while (points.length < count) {
      points.add(const Offset(0.0, 0.0));
    }

    for (int i = count - 1; i >= 0; i--) {
      double x = i * (size.width / count);
      if (i < values.length) {
        points[i] = Offset(x, values[i] * size.height);
      }
    }

    Path path = Path();

    path.moveTo(points[0].dx, points[0].dy);

    for (int i = 0; i < count - 2; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
