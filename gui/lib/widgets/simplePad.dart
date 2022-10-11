import 'package:flutter/material.dart';
import 'package:ffi/ffi.dart';
import '../host.dart';
import 'widget.dart';
import '../main.dart';
import 'dart:ui' as ui;
import 'dart:ffi';
import 'canvas.dart';

import '../views/settings.dart';

var knobValue = "value".toNativeUtf8();
var colorValue = "color".toNativeUtf8();

//int Function(FFIWidgetPointer) ffiKnobGetValue = core.lookup<NativeFunction<Int32 Function(FFIWidgetPointer)>>("ffi_knob_get_value").asFunction();
void Function(FFIWidgetPointer, bool) ffiSimplePadSetValue = core
    .lookup<NativeFunction<Void Function(FFIWidgetPointer, Bool)>>(
        "ffi_simple_pad_set_value")
    .asFunction();
int Function(FFIWidgetPointer) ffiSimplePadGetColor = core
    .lookup<NativeFunction<Int32 Function(FFIWidgetPointer)>>(
        "ffi_simple_pad_get_color")
    .asFunction();

class SimplePadWidget extends ModuleWidget {
  SimplePadWidget(Host h, FFINode m, FFIWidget w) : super(h, m, w);

  Color color = Colors.blue;
  bool value = false;
  String? labelText;

  @override
  Widget build(BuildContext context) {
    var colorIndex = ffiSimplePadGetColor(widgetRaw.pointer);
    color = Color(colorIndex);

    return Stack(children: [
      Container(
        decoration: BoxDecoration(
            color: value ? color : color.withAlpha(100),
            border: Border.all(
              color: value ? color : color.withAlpha(100),
              width: 3.0,
            ),
            borderRadius: BorderRadius.circular(10)),
      ),
      GestureDetector(
        onTapDown: (v) {
          ffiSimplePadSetValue(widgetRaw.pointer, true);

          setState(() {
            value = true;
          });
        },
        onTapUp: (v) {
          ffiSimplePadSetValue(widgetRaw.pointer, false);

          setState(() {
            value = false;
          });
        },
        onTapCancel: () {
          ffiSimplePadSetValue(widgetRaw.pointer, false);

          setState(() {
            value = false;
          });
        },
      )
    ]);
  }
}
