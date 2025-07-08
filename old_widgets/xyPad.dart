import 'package:flutter/material.dart';

import 'dart:ffi';
import 'dart:ui' as ui;

import 'widget.dart';

import '../core.dart';
import '../module/node.dart';

double Function(RawWidgetPointer) ffiXYPadGetX = core
    .lookup<NativeFunction<Float Function(RawWidgetPointer)>>(
        "ffi_xy_pad_get_x")
    .asFunction();
double Function(RawWidgetPointer) ffiXYPadGetY = core
    .lookup<NativeFunction<Float Function(RawWidgetPointer)>>(
        "ffi_xy_pad_get_y")
    .asFunction();
double Function(RawWidgetPointer, double) ffiXYPadSetX = core
    .lookup<NativeFunction<Float Function(RawWidgetPointer, Float)>>(
        "ffi_xy_pad_set_x")
    .asFunction();
double Function(RawWidgetPointer, double) ffiXYPadSetY = core
    .lookup<NativeFunction<Float Function(RawWidgetPointer, Float)>>(
        "ffi_xy_pad_set_y")
    .asFunction();

class XYPadWidget extends ModuleWidget {
  XYPadWidget(Node n, RawNode m, RawWidget w) : super(n, m, w);

  void update(double x, double y) {
    setState(() {
      ffiXYPadSetX(widgetRaw.pointer, x.clamp(0.0, 1.0));
      ffiXYPadSetY(widgetRaw.pointer, 1.0 - y.clamp(0.0, 1.0));
    });
  }

  @override
  Widget build(BuildContext context) {
    double x = ffiXYPadGetX(widgetRaw.pointer);
    double y = 1.0 - ffiXYPadGetY(widgetRaw.pointer);

    return LayoutBuilder(
      builder: (context, constraints) {
        return Container(
          width: constraints.maxWidth,
          height: constraints.maxHeight,
          decoration: const BoxDecoration(
            color: Color.fromRGBO(20, 20, 20, 1.0),
            borderRadius: BorderRadius.all(Radius.circular(5)),
          ),
          child: GestureDetector(
            onTapDown: (e) => update(
              e.localPosition.dx / constraints.maxWidth,
              e.localPosition.dy / constraints.maxHeight,
            ),
            onPanUpdate: (e) => update(
              e.localPosition.dx / constraints.maxWidth,
              e.localPosition.dy / constraints.maxHeight,
            ),
            child: CustomPaint(
              painter: XYPadPainter(x, y),
            ),
          ),
        );
      },
    );
  }
}

class XYPadPainter extends CustomPainter {
  XYPadPainter(this.x, this.y);

  double x;
  double y;

  @override
  void paint(Canvas canvas, ui.Size size) {
    Paint paint = Paint()
      ..strokeWidth = 1.0
      ..color = const Color.fromRGBO(40, 40, 40, 1.0);

    canvas.drawLine(
      Offset(size.width / 2, 10),
      Offset(size.width / 2, size.height / 2 - 10),
      paint,
    );

    canvas.drawLine(
      Offset(size.width / 2, size.height / 2 + 10),
      Offset(size.width / 2, size.height - 10),
      paint,
    );

    canvas.drawLine(
      Offset(10, size.height / 2),
      Offset(size.width / 2 - 10, size.height / 2),
      paint,
    );

    canvas.drawLine(
      Offset(size.width / 2 + 10, size.height / 2),
      Offset(size.width - 10, size.height / 2),
      paint,
    );

    paint = Paint()
      ..strokeWidth = 1.0
      ..color = const Color.fromRGBO(100, 100, 100, 1.0);

    canvas.drawCircle(Offset(x * size.width, y * size.height), 10, paint);

    paint = Paint()
      ..strokeWidth = 1.0
      ..color = const Color.fromRGBO(150, 150, 150, 1.0);

    canvas.drawCircle(Offset(x * size.width, y * size.height), 8, paint);
  }

  @override
  bool shouldRepaint(covariant XYPadPainter oldDelegate) {
    return oldDelegate.x != x || oldDelegate.y != y;
  }
}
