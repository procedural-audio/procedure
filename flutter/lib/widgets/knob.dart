import 'package:flutter/material.dart';
import 'package:ffi/ffi.dart';
import '../host.dart';
import '../views/variables.dart';
import 'widget.dart';
import '../main.dart';
import 'dart:ui' as ui;
import 'dart:ffi';
import 'canvas.dart';

import '../views/settings.dart';

var knobValue = "value".toNativeUtf8();
var colorValue = "color".toNativeUtf8();

//int Function(FFIWidgetPointer) ffiKnobGetValue = core.lookup<NativeFunction<Int32 Function(FFIWidgetPointer)>>("ffi_knob_get_value").asFunction();
void Function(FFIWidgetPointer, double) ffiKnobSetValue = core
    .lookup<NativeFunction<Void Function(FFIWidgetPointer, Float)>>(
        "ffi_knob_set_value")
    .asFunction();
Pointer<Utf8> Function(FFIWidgetPointer) ffiKnobGetLabel = core
    .lookup<NativeFunction<Pointer<Utf8> Function(FFIWidgetPointer)>>(
        "ffi_knob_get_label")
    .asFunction();
Pointer<Utf8> Function(FFIWidgetPointer) ffiKnobGetFeedback = core
    .lookup<NativeFunction<Pointer<Utf8> Function(FFIWidgetPointer)>>(
        "ffi_knob_get_feedback")
    .asFunction();
int Function(FFIWidgetPointer) ffiKnobGetColor = core
    .lookup<NativeFunction<Int32 Function(FFIWidgetPointer)>>(
        "ffi_knob_get_color")
    .asFunction();

class KnobWidget extends ModuleWidget {
  KnobWidget(Host h, FFINode m, FFIWidget w) : super(h, m, w);

  Color color = Colors.blue;
  double angle = 0;
  String labelText = "";
  bool hovering = false;
  bool dragging = false;

  @override
  bool canAcceptVars() {
    return true;
  }

  @override
  bool willAcceptVar(Var v) {
    return v.notifier.value is double;
  }

  @override
  void onVarUpdate(dynamic value) {
    setState(() {
      angle = value as double;
      ffiKnobSetValue(widgetRaw.pointer, angle);
    });
  }

  @override
  Widget build(BuildContext context) {
    var colorIndex = ffiKnobGetColor(widgetRaw.pointer);
    color = Color(colorIndex);

    if (hovering || dragging) {
      var labelRaw = ffiKnobGetFeedback(widgetRaw.pointer);
      labelText = labelRaw.toDartString();
      calloc.free(labelRaw);
    } else {
      var labelRaw = ffiKnobGetLabel(widgetRaw.pointer);
      labelText = labelRaw.toDartString();
      calloc.free(labelRaw);
    }

    int width = 50;
    int height = 50;

    return Stack(
      fit: StackFit.loose,
      alignment: Alignment.center,
      children: [
        Positioned(
          top: 4.0,
          left: 4.0,
          child: SizedBox(
            width: width + -1.0,
            height: height + 0.0,
            child: CustomPaint(
              painter: ArcPainter(
                startAngle: 2.2,
                endAngle: (angle - 0.5) * 5 + 2.5,
                color: color,
                shouldGlow: true,
              ),
            ),
          ),
        ),
        Positioned(
          top: 4.0,
          left: 4.0,
          child: SizedBox(
            width: width + -1.0,
            height: height + 0.0,
            child: CustomPaint(
              painter: ArcPainter(
                startAngle: (angle - 0.5) * 5 - 1.55,
                endAngle: 2.5 - (angle - 0.5) * 5,
                color: MyTheme.grey60,
                shouldGlow: false,
              ),
            ),
          ),
        ),
        Positioned(
          top: 9.0,
          left: 9.0,
          child: Stack(children: [
            Container(
              width: width - 10.0,
              height: height - 10.0,
              decoration: BoxDecoration(
                  color: const Color.fromRGBO(53, 53, 53, 1.0),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                        offset: const Offset(-1, -1),
                        color: Colors.white.withAlpha(50),
                        blurRadius: 1.0),
                    BoxShadow(
                        offset: const Offset(4, 4),
                        color: Colors.black.withAlpha(120),
                        blurRadius: 4.0)
                  ]),
              alignment: Alignment.topCenter,
            ),
            Transform.rotate(
              angle: (angle - 0.5) * 5,
              alignment: Alignment.center,
              child: Container(
                width: width - 10.0,
                height: height - 10.0,
                alignment: Alignment.topCenter,
                child: Container(
                  width: 2,
                  height: 12,
                  decoration: BoxDecoration(
                      color: Colors.blue.shade100,
                      shape: BoxShape.rectangle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blue.shade100,
                          blurRadius: 2.0,
                          spreadRadius: 0.5,
                        )
                      ]),
                ),
              ),
            )
          ]),
        ),
        Positioned(
          top: 2.0,
          left: 2.0,
          child: SizedBox(
            width: width + 20,
            height: height + 20,
            child: MouseRegion(
              onEnter: (details) {
                setState(() {
                  hovering = true;
                });
              },
              onExit: (details) {
                setState(() {
                  hovering = false;
                });
              },
              child: GestureDetector(
                  onVerticalDragStart: (details) {
                    setState(() {
                      dragging = true;
                    });
                  },
                  onVerticalDragEnd: (details) {
                    setState(() {
                      dragging = false;
                    });
                  },
                  onVerticalDragCancel: () {
                    setState(() {
                      dragging = false;
                    });
                  },
                  onVerticalDragUpdate: (details) => setState(
                        () {
                          // print(angle.toString());

                          angle += (-details.delta.dy / 60) / 5;

                          ffiKnobSetValue(widgetRaw.pointer, angle);

                          if (assignedVar.value != null) {
                            if (assignedVar.value!.notifier.value is double) {
                              assignedVar.value!.notifier.value = angle;
                            }
                          }

                          if (angle > 1) {
                            angle = 1.0;
                          } else if (angle < 0) {
                            angle = 0;
                          }

                          setState(() {
                            this.angle = angle;
                          });
                        },
                      )),
            ),
          ),
        ),
        Positioned(
          top: 52,
          child: SizedBox(
            height: 18,
            child: Text(
              labelText,
              style: TextStyle(
                  color: color,
                  fontSize: 14,
                  fontWeight: FontWeight.normal,
                  decoration: TextDecoration.none),
            ),
          ),
        )
      ],
    );
  }
}

class ArcPainter extends CustomPainter {
  ArcPainter(
      {required this.startAngle,
      required this.endAngle,
      required this.color,
      required this.shouldGlow});

  final double startAngle;
  final double endAngle;
  final Color color;
  final bool shouldGlow;

  @override
  void paint(Canvas canvas, ui.Size size) {
    var paint1 = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    canvas.drawArc(
        Rect.fromCenter(
            center: Offset(size.width / 2, size.height / 2),
            width: size.width,
            height: size.height),
        startAngle, //radians
        endAngle, //radians
        false,
        paint1);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

//int Function(FFIWidgetPointer) ffiKnobGetValue = core.lookup<NativeFunction<Int32 Function(FFIWidgetPointer)>>("ffi_knob_get_value").asFunction();
void Function(FFIWidgetPointer, double) ffiPaintedKnobSetValue = core
    .lookup<NativeFunction<Void Function(FFIWidgetPointer, Float)>>(
        "ffi_painted_knob_set_value")
    .asFunction();

class PaintedKnobWidget extends ModuleWidget {
  PaintedKnobWidget(Host h, FFINode m, FFIWidget w) : super(h, m, w);

  Color color = Colors.blue;
  double angle = 0;
  String? labelText;

  Pointer<CanvasFFI> canvasRaw = ffiNewCanvas(); // LEAK HERE

  @override
  Widget build(BuildContext context) {
    int width = 50;
    int height = 50;

    return Stack(
      fit: StackFit.loose,
      alignment: Alignment.center,
      children: [
        CustomPaint(
          painter: CanvasPainter(widgetRaw, canvasRaw),
        ),
        Positioned(
          top: 2.0,
          left: 2.0,
          child: SizedBox(
            width: width + 20,
            height: height + 20,
            child: GestureDetector(
              onVerticalDragUpdate: (details) => setState(() {
                // angle += -details.delta.dy / 60 * globals.zoom;
                // ^^^ changed this during refactor

                angle += -details.delta.dy / 60;

                ffiPaintedKnobSetValue(widgetRaw.pointer, (angle + 2.5) / 5);

                if (angle > 2.5) {
                  angle = 2.5;
                } else if (angle < -2.5) {
                  angle = -2.5;
                }

                setState(() {
                  this.angle = angle;
                });
              }),
            ),
          ),
        ),
      ],
    );
  }
}
