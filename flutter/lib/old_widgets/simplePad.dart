import 'package:flutter/material.dart';
import 'package:ffi/ffi.dart';
import '../patch/patch.dart';
import 'widget.dart';
import '../main.dart';
import 'dart:ui' as ui;
import 'dart:ffi';
import '../core.dart';
import '../module/node.dart';

import '../views/settings.dart';

var knobValue = "value".toNativeUtf8();
var colorValue = "color".toNativeUtf8();

//int Function(RawWidgetPointer) ffiKnobGetValue = core.lookup<NativeFunction<Int32 Function(RawWidgetPointer)>>("ffi_knob_get_value").asFunction();
void Function(RawWidgetPointer, bool) ffiSimplePadSetValue = core
    .lookup<NativeFunction<Void Function(RawWidgetPointer, Bool)>>(
        "ffi_simple_pad_set_value")
    .asFunction();
int Function(RawWidgetPointer) ffiSimplePadGetColor = core
    .lookup<NativeFunction<Int32 Function(RawWidgetPointer)>>(
        "ffi_simple_pad_get_color")
    .asFunction();

class SimplePadWidget extends ModuleWidget {
  SimplePadWidget(Node n, RawNode m, RawWidget w) : super(n, m, w);

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
