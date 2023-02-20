import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'widget.dart';
import 'dart:io';
import 'dart:ffi';
import '../host.dart';

import 'package:ffi/ffi.dart';
import 'dart:ui' as ui;

bool Function(FFIWidgetTrait) ffiPainterShouldPaint = core
    .lookup<NativeFunction<Bool Function(FFIWidgetTrait)>>(
        "ffi_painter_should_paint")
    .asFunction();
void Function(FFIWidgetTrait, Pointer<CanvasFFI>) ffiPainterPaint = core
    .lookup<NativeFunction<Void Function(FFIWidgetTrait, Pointer<CanvasFFI>)>>(
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
  PainterWidget(Host h, FFINode m, FFIWidget w) : super(h, m, w);

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
        child: const SizedBox.expand());
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

  @Float()
  external double f6;

  external PaintFFI paint;

  external PairFFIList points;
}

class CanvasPainter extends CustomPainter {
  CanvasPainter(this.widgetRaw, this.canvasRaw);

  FFIWidget widgetRaw;
  Pointer<CanvasFFI> canvasRaw;

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

    Paint paint = Paint();

    for (int i = 0; i < count; i++) {
      var action = actionsRaw.elementAt(i);

      paint.color = intToColor(action.ref.paint.color);
      paint.strokeWidth = action.ref.paint.width;

      if (action.ref.action == 0) {
        canvas.drawCircle(
            Offset(action.ref.f1, action.ref.f2), action.ref.f3, paint);
      } else if (action.ref.action == 1) {
        canvas.drawRect(
            Rect.fromLTWH(
                action.ref.f1, action.ref.f2, action.ref.f3, action.ref.f4),
            paint);
      } else if (action.ref.action == 2) {
        canvas.drawRRect(
            RRect.fromLTRBR(action.ref.f1, action.ref.f2, action.ref.f3,
                action.ref.f4, Radius.circular(action.ref.f5)),
            paint);
      } else if (action.ref.action == 3) {
        canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
      } else if (action.ref.action == 4) {
        List<Offset> list = [];

        for (int j = 0; j < action.ref.points.len; j++) {
          Pointer<PairFFI> pair = action.ref.points.pointer.elementAt(j);
          list.add(Offset(pair.ref.x, pair.ref.y));
        }

        canvas.drawPoints(ui.PointMode.polygon, list, paint);
      } else if (action.ref.action == 5) {
        canvas.drawLine(Offset(action.ref.f1, action.ref.f2),
            Offset(action.ref.f3, action.ref.f4), paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
