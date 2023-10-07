import 'package:ffi/ffi.dart';
import 'package:flutter/material.dart';

import 'widget.dart';
import 'dart:ffi';

import 'dart:ui' as ui;
import '../core.dart';
import '../module.dart';

Pointer<Utf8> Function(RawWidgetPointer) ffiSampleViewerGetBufferPath = core
    .lookup<NativeFunction<Pointer<Utf8> Function(RawWidgetPointer)>>(
        "ffi_sample_viewer_get_buffer_path")
    .asFunction();
int Function(RawWidgetPointer) ffiSampleViewerGetBufferLength = core
    .lookup<NativeFunction<Int64 Function(RawWidgetPointer)>>(
        "ffi_sample_viewer_get_buffer_length")
    .asFunction();
double Function(RawWidgetPointer, int) ffiSampleViewerGetSampleLeft = core
    .lookup<NativeFunction<Float Function(RawWidgetPointer, Int64)>>(
        "ffi_sample_viewer_get_sample_left")
    .asFunction();
double Function(RawWidgetPointer, int) ffiSampleViewerGetSampleRight = core
    .lookup<NativeFunction<Float Function(RawWidgetPointer, Int64)>>(
        "ffi_sample_viewer_get_sample_right")
    .asFunction();

class SampleViewerWidget extends ModuleWidget {
  SampleViewerWidget(Node n, RawNode m, RawWidget w) : super(n, m, w) {
    refreshBuffer();
  }

  List<double> leftBuffer = [0.0];
  List<double> rightBuffer = [0.0];

  bool loadingSample = false;

  String path = "";

  @override
  void refresh() {
    var rawPath = ffiSampleViewerGetBufferPath(widgetRaw.pointer);
    var newPath = rawPath.toDartString();

    if (newPath != path) {
      path = newPath;
      refreshBuffer();
    }

    calloc.free(rawPath);
  }

  void refreshBuffer() {
    leftBuffer.clear();
    rightBuffer.clear();

    int count = 300;
    int length = ffiSampleViewerGetBufferLength(widgetRaw.pointer);

    for (int i = 0; i < count; i++) {
      int index = (length ~/ count) * i;

      double left = ffiSampleViewerGetSampleLeft(widgetRaw.pointer, index);
      double right = ffiSampleViewerGetSampleRight(widgetRaw.pointer, index);

      leftBuffer.add(left * 1.0);
      rightBuffer.add(right * 1.0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.maxFinite,
      height: double.maxFinite,
      decoration: const BoxDecoration(
        color: Color.fromRGBO(20, 20, 20, 1.0),
        borderRadius: BorderRadius.all(
          Radius.circular(5),
        ),
      ),
      child: CustomPaint(
        painter: SamplePainter(
          leftBuffer: leftBuffer,
          rightBuffer: rightBuffer,
        ),
      ),
    );
  }
}

class SamplePainter extends CustomPainter {
  SamplePainter({
    required this.leftBuffer,
    required this.rightBuffer,
  });

  List<double> leftBuffer;
  List<double> rightBuffer;

  @override
  void paint(Canvas canvas, ui.Size size) {
    Paint paint = Paint()
      ..color = Colors.blue
      ..strokeWidth = 2.0
      ..style = PaintingStyle.fill;

    int red = 0;

    /* Draw left buffers */

    List<Offset> points = [];

    red += 30;
    paint.color = paint.color.withRed(red);

    for (int i = 0; i < leftBuffer.length; i++) {
      double x = i * (size.width / leftBuffer.length);
      double y = size.height * leftBuffer[i] * 0.5;

      if (y > 0) {
        y = -y;
      }

      Offset end = Offset(x, y + size.height * 0.5);
      points.add(end);
    }

    canvas.drawPoints(ui.PointMode.polygon, points, paint);
    points.clear();

    /* Draw right buffers */

    paint = Paint()
      ..color = Colors.blue
      ..strokeWidth = 2.0
      ..style = PaintingStyle.fill;

    red = 0;

    points.clear();

    red += 30;
    paint.color = paint.color.withRed(red);

    for (int i = 0; i < rightBuffer.length; i++) {
      double x = i * (size.width / rightBuffer.length);
      double y = size.height * rightBuffer[i] * 0.5;

      if (y < 0) {
        y = -y;
      }

      Offset end = Offset(x, y + size.height * 0.5);

      points.add(end);
    }

    canvas.drawPoints(ui.PointMode.polygon, points, paint);
    points.clear();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}
