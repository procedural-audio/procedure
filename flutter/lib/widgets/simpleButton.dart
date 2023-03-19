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

void Function(FFIWidgetPointer, bool) ffiSimpleButtonSetValue = core
    .lookup<NativeFunction<Void Function(FFIWidgetPointer, Bool)>>(
        "ffi_simple_button_set_value")
    .asFunction();
Pointer<Utf8> Function(FFIWidgetPointer) ffiSimpleButtonGetLabel = core
    .lookup<NativeFunction<Pointer<Utf8> Function(FFIWidgetPointer)>>(
        "ffi_simple_button_get_label")
    .asFunction();
int Function(FFIWidgetPointer) ffiSimpleButtonGetColor = core
    .lookup<NativeFunction<Int32 Function(FFIWidgetPointer)>>(
        "ffi_simple_button_get_color")
    .asFunction();
bool Function(FFIWidgetPointer) ffiSimpleButtonGetToggle = core
    .lookup<NativeFunction<Bool Function(FFIWidgetPointer)>>(
        "ffi_simple_button_get_toggle")
    .asFunction();

class SimpleButtonWidget extends ModuleWidget {
  SimpleButtonWidget(App a, RawNode m, FFIWidget w) : super(a, m, w);

  Color color = Colors.blue;
  bool value = false;
  String? labelText;

  @override
  Widget build(BuildContext context) {
    var toggle = ffiSimpleButtonGetToggle(widgetRaw.pointer);
    var colorIndex = ffiSimpleButtonGetColor(widgetRaw.pointer);
    color = Color(colorIndex);

    var labelRaw = ffiSimpleButtonGetLabel(widgetRaw.pointer);
    var labelText = labelRaw.toDartString();
    calloc.free(labelRaw);

    print("Building simple button");

    return GestureDetector(
        onTap: () {},
        child: Listener(
            onPointerDown: (e) {
              if (toggle) {
                ffiSimpleButtonSetValue(widgetRaw.pointer, !value);

                setState(() {
                  value = !value;
                });
              } else {
                ffiSimpleButtonSetValue(widgetRaw.pointer, true);

                setState(() {
                  value = true;
                });
              }
            },
            onPointerUp: (e) {
              if (!toggle) {
                ffiSimpleButtonSetValue(widgetRaw.pointer, false);

                setState(() {
                  value = false;
                });
              }
            },
            onPointerCancel: (e) {
              if (!toggle) {
                ffiSimpleButtonSetValue(widgetRaw.pointer, false);

                setState(() {
                  value = false;
                });
              }
            },
            child: Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                  // color: Colors.grey,
                  border: Border.all(
                    color: value ? color : color.withAlpha(100),
                    width: 3.0,
                  ),
                  borderRadius: BorderRadius.circular(25 / 2)),
              child: Center(
                child: Text(
                  labelText,
                  style: TextStyle(color: color, fontSize: 16),
                ),
              ),
            )));
  }
}
