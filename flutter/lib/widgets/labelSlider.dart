import 'package:flutter/material.dart';
import 'package:ffi/ffi.dart';

import 'dart:ui' as ui;
import 'dart:ffi';

import 'widget.dart';

import '../core.dart';
import '../module.dart';

double Function(RawWidgetPointer) ffiLabelSliderGetValue = core
    .lookup<NativeFunction<Float Function(RawWidgetPointer)>>(
        "ffi_label_slider_get_value")
    .asFunction();
void Function(RawWidgetPointer, double) ffiLabelSliderSetValue = core
    .lookup<NativeFunction<Void Function(RawWidgetPointer, Float)>>(
        "ffi_label_slider_set_value")
    .asFunction();
int Function(RawWidgetPointer) ffiLabelSliderGetColor = core
    .lookup<NativeFunction<Int32 Function(RawWidgetPointer)>>(
        "ffi_label_slider_get_color")
    .asFunction();

Pointer<Utf8> Function(RawWidgetPointer) ffiLabelSliderGetText = core
    .lookup<NativeFunction<Pointer<Utf8> Function(RawWidgetPointer)>>(
        "ffi_label_slider_get_text")
    .asFunction();

class LabelSliderWidget extends ModuleWidget {
  LabelSliderWidget(Node n, RawNode m, RawWidget w) : super(n, m, w);

  Color color = Colors.blue;
  String labelText = "";

  bool hovering = false;
  bool dragging = false;

  @override
  Widget build(BuildContext context) {
    Color color = Color(ffiLabelSliderGetColor(widgetRaw.pointer));
    double value = ffiLabelSliderGetValue(widgetRaw.pointer);

    Pointer<Utf8> rawText = ffiLabelSliderGetText(widgetRaw.pointer);
    String text = rawText.toDartString();
    calloc.free(rawText);

    return Text(
      text,
      style: TextStyle(
        color: color,
        fontSize: 14,
      ),
    );
  }
}
