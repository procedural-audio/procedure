import 'package:flutter/material.dart';
import 'package:ffi/ffi.dart';
import '../host.dart';
import 'widget.dart';
import '../main.dart';
import 'dart:ui' as ui;
import 'dart:ffi';
import '../core.dart';
import '../module.dart';

import '../views/settings.dart';

var knobValue = "value".toNativeUtf8();
var colorValue = "color".toNativeUtf8();

//int Function(FFIWidgetPointer) ffiKnobGetValue = core.lookup<NativeFunction<Int32 Function(FFIWidgetPointer)>>("ffi_knob_get_value").asFunction();
void Function(FFIWidgetPointer, bool) ffiSimpleSwitchSetValue = core
    .lookup<NativeFunction<Void Function(FFIWidgetPointer, Bool)>>(
        "ffi_simple_switch_set_value")
    .asFunction();
Pointer<Utf8> Function(FFIWidgetPointer) ffiSimpleSwitchGetLabel = core
    .lookup<NativeFunction<Pointer<Utf8> Function(FFIWidgetPointer)>>(
        "ffi_simple_switch_get_label")
    .asFunction();
int Function(FFIWidgetPointer) ffiSimpleSwitchGetColor = core
    .lookup<NativeFunction<Int32 Function(FFIWidgetPointer)>>(
        "ffi_simple_switch_get_color")
    .asFunction();

class SimpleSwitchWidget extends ModuleWidget {
  SimpleSwitchWidget(App a, RawNode m, FFIWidget w) : super(a, m, w);

  Color color = Colors.blue;
  bool value = false;
  String? labelText;

  @override
  Widget build(BuildContext context) {
    var colorIndex = ffiSimpleSwitchGetColor(widgetRaw.pointer);
    color = Color(colorIndex);

    var labelRaw = ffiSimpleSwitchGetLabel(widgetRaw.pointer);
    var labelText = labelRaw.toDartString();
    calloc.free(labelRaw);

    return Stack(children: [
      //SliderTheme(data: data, child: child)
      Switch(
          value: value,
          onChanged: (v) {
            ffiSimpleSwitchSetValue(widgetRaw.pointer, value);

            setState(() {
              value = v;
            });
          })
    ]);
  }
}
