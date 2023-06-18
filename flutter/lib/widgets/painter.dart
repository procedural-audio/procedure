import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'widget.dart';
import 'dart:io';
import 'dart:ffi';
import '../patch.dart';

import 'package:ffi/ffi.dart';
import 'dart:ui' as ui;
import '../core.dart';
import '../module.dart';
import '../main.dart';

bool Function(RawWidgetTrait) ffiPainterShouldRepaint = core
    .lookup<NativeFunction<Bool Function(RawWidgetTrait)>>(
        "ffi_painter_repaint")
    .asFunction();
void Function(RawWidgetTrait, Pointer<CanvasFFI>) ffiPainterPaint = core
    .lookup<NativeFunction<Void Function(RawWidgetTrait, Pointer<CanvasFFI>)>>(
        "ffi_painter_paint")
    .asFunction();
Pointer<CanvasFFI> Function() ffiNewCanvas = core
    .lookup<NativeFunction<Pointer<CanvasFFI> Function()>>("ffi_new_canvas")
    .asFunction();
void Function(Pointer<CanvasFFI>) ffiCanvasDelete = core
    .lookup<NativeFunction<Void Function(Pointer<CanvasFFI>)>>(
        "ffi_canvas_delete")
    .asFunction();
Pointer<PaintAction> Function(Pointer<CanvasFFI>) ffiCanvasGetActions = core
    .lookup<NativeFunction<Pointer<PaintAction> Function(Pointer<CanvasFFI>)>>(
        "ffi_canvas_get_actions")
    .asFunction();
int Function(Pointer<CanvasFFI>) ffiCanvasGetActionsCount = core
    .lookup<NativeFunction<Int64 Function(Pointer<CanvasFFI>)>>(
        "ffi_canvas_get_actions_count")
    .asFunction();

class PainterWidget extends ModuleWidget {
  PainterWidget(Node n, RawNode m, RawWidget w) : super(n, m, w);

  late Pointer<CanvasFFI> canvasRaw;

  @override
  void initState() {
    canvasRaw = ffiNewCanvas();
  }

  @override
  void dispose() {
    super.dispose();
    ffiCanvasDelete(canvasRaw);
  }

  @override
  void tick() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: ui.Size.infinite,
      painter: CanvasPainter(widgetRaw, canvasRaw),
      child: const SizedBox.expand(),
    );
  }
}

class PairFFI extends Struct {
  @Float()
  external double x;

  @Float()
  external double y;
}

class PairFFIList extends Struct {
  external Pointer<PairFFI> pointer;

  @Int64()
  external int len;

  @Int64()
  external int capacity;
}

class CanvasFFI extends Struct {
  @Int64()
  external int pointer;

  @Int64()
  external int len;

  @Int64()
  external int capacity;

  @Float()
  external double width;

  @Float()
  external double height;
}

class PaintFFI extends Struct {
  @Int32()
  external int color;

  @Float()
  external double width;
}

class PaintAction extends Struct {
  @Int32()
  external int action;

  @Float()
  external double f1;

  @Float()
  external double f2;

  @Float()
  external double f3;

  @Float()
  external double f4;

  @Float()
  external double f5;

  external Pointer<PairFFIList> p1;

  external PaintFFI paint;

  external PairFFIList points;
}

class CanvasPainter extends CustomPainter {
  CanvasPainter(this.widgetRaw, this.canvasRaw);

  RawWidget widgetRaw;
  Pointer<CanvasFFI> canvasRaw;
  Paint p = Paint();

  @override
  bool hitTest(Offset position) {
    // TODO: Make this user determined
    return false;
  }

  @override
  void paint(Canvas canvas, ui.Size size) {
    canvasRaw.ref.width = size.width;
    canvasRaw.ref.height = size.height;
    ffiPainterPaint(widgetRaw.getTrait(), canvasRaw);

    Pointer<PaintAction> actionsRaw = ffiCanvasGetActions(canvasRaw);
    int count = ffiCanvasGetActionsCount(canvasRaw);

    for (int i = 0; i < count; i++) {
      var action = actionsRaw.elementAt(i);

      p.color = intToColor(action.ref.paint.color);
      p.strokeWidth = action.ref.paint.width;

      if (action.ref.action == 0) {
        // Draw circle
        canvas.drawCircle(
          Offset(action.ref.f1, action.ref.f2),
          action.ref.f3,
          p,
        );
      } else if (action.ref.action == 1) {
        // Draw rect
        canvas.drawRect(
            Rect.fromLTWH(
              action.ref.f1,
              action.ref.f2,
              action.ref.f3,
              action.ref.f4,
            ),
            p);
      } else if (action.ref.action == 2) {
        // Draw rrect
        canvas.drawRRect(
            RRect.fromLTRBR(
              action.ref.f1,
              action.ref.f2,
              action.ref.f3,
              action.ref.f4,
              Radius.circular(action.ref.f5),
            ),
            p);
      } else if (action.ref.action == 3) {
        // Fill
        canvas.drawRect(
          Rect.fromLTWH(0, 0, size.width, size.height),
          p,
        );
      } else if (action.ref.action == 4) {
        // Draw line
        canvas.drawLine(
          Offset(action.ref.f1, action.ref.f2),
          Offset(action.ref.f3, action.ref.f4),
          p,
        );
      } else if (action.ref.action == 5) {
        // Points
        Pointer<Float> rawList = action.ref.points.pointer.cast<Float>();
        Float32List rawPoints = rawList.asTypedList(action.ref.points.len * 2);
        canvas.drawRawPoints(ui.PointMode.points, rawPoints, p);
      } else if (action.ref.action == 6) {
        // Path
        Pointer<Float> rawList = action.ref.points.pointer.cast<Float>();
        Float32List rawPoints = rawList.asTypedList(action.ref.points.len * 2);
        canvas.drawRawPoints(ui.PointMode.lines, rawPoints, p);
      } else if (action.ref.action == 7) {
        // Polygon
        Pointer<Float> rawList = action.ref.points.pointer.cast<Float>();
        Float32List rawPoints = rawList.asTypedList(action.ref.points.len * 2);
        canvas.drawRawPoints(ui.PointMode.polygon, rawPoints, p);
      } else if (action.ref.action == 8) {
        // Raw fast draw points
      }
    }
  }

  @override
  bool shouldRepaint(covariant CanvasPainter oldDelegate) {
    return ffiPainterShouldRepaint(widgetRaw.getTrait());
  }
}
