import 'dart:ui' as ui;
import 'dart:ffi';
import 'dart:async';

import 'package:flutter/material.dart';

import '../host.dart';

import 'widget.dart';
import '../core.dart';
import '../module.dart';

double Function(FFIWidgetPointer) ffiLevelMeterGetLeft = core
    .lookup<NativeFunction<Float Function(FFIWidgetPointer)>>(
        "ffi_level_meter_get_left")
    .asFunction();
double Function(FFIWidgetPointer) ffiLevelMeterGetRight = core
    .lookup<NativeFunction<Float Function(FFIWidgetPointer)>>(
        "ffi_level_meter_get_right")
    .asFunction();

int Function(FFIWidgetPointer) ffiLevelMeterGetColor1 = core
    .lookup<NativeFunction<Int32 Function(FFIWidgetPointer)>>(
        "ffi_level_meter_get_color_1")
    .asFunction();
int Function(FFIWidgetPointer) ffiLevelMeterGetColor2 = core
    .lookup<NativeFunction<Int32 Function(FFIWidgetPointer)>>(
        "ffi_level_meter_get_color_2")
    .asFunction();

class LevelMeterWidget extends ModuleWidget {
  LevelMeterWidget(Host h, RawNode m, FFIWidget w) : super(h, m, w) {
    color1 = Color(ffiLevelMeterGetColor1(widgetRaw.pointer));
    color2 = Color(ffiLevelMeterGetColor2(widgetRaw.pointer));
  }

  late Color color1;
  late Color color2;

  double left = 0.0;
  double right = 0.0;

  late Timer timer;

  @override
  void initState() {
    timer = Timer.periodic(const Duration(milliseconds: 32), (timer) {
      setState(() {
        left = ffiLevelMeterGetLeft(widgetRaw.pointer);
        right = ffiLevelMeterGetRight(widgetRaw.pointer);
      });
    });
  }

  @override
  void dispose() {
    timer.cancel();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
        width: 200,
        height: 1000,
        child: CustomPaint(
          painter: KnobPainter(left: left, right: right),
        ));
  }
}

class KnobPainter extends CustomPainter {
  KnobPainter({required this.left, required this.right});

  double left;
  double right;

  @override
  void paint(Canvas canvas, ui.Size size) {
    if (left > 1) {
      left = 1;
    }

    if (right > 1) {
      right = 1;
    }

    if (left < 0) {
      left = 0;
    }

    if (right < 0) {
      right = 0;
    }

    Paint paint = Paint()..color = Colors.blue;

    canvas.drawRect(
        Rect.fromLTWH(
            0, size.height * (1.0 - left), size.width / 2, size.height * left),
        paint);

    canvas.drawRect(
        Rect.fromLTWH(size.width / 2, size.height * (1.0 - right),
            size.width / 2, size.height * right),
        paint);
  }

  @override
  bool shouldRepaint(KnobPainter oldDelegate) {
    return left != oldDelegate.left || right != oldDelegate.right;
  }
}
