import 'package:flutter/material.dart';
import 'package:ffi/ffi.dart';
import '../patch.dart';
import 'widget.dart';
import '../main.dart';
import 'dart:ui' as ui;
import 'dart:ffi';
import '../core.dart';
import '../module.dart';

double Function(RawWidgetPointer) ffiFaderGetValue = core
    .lookup<NativeFunction<Float Function(RawWidgetPointer)>>(
        "ffi_fader_get_value")
    .asFunction();
void Function(RawWidgetPointer, double) ffiFaderSetValue = core
    .lookup<NativeFunction<Void Function(RawWidgetPointer, Float)>>(
        "ffi_fader_set_value")
    .asFunction();
Pointer<Utf8> Function(RawWidgetPointer) ffiFaderGetLabel = core
    .lookup<NativeFunction<Pointer<Utf8> Function(RawWidgetPointer)>>(
        "ffi_fader_get_label")
    .asFunction();
int Function(RawWidgetPointer) ffiFaderGetColor = core
    .lookup<NativeFunction<Int32 Function(RawWidgetPointer)>>(
        "ffi_fader_get_color")
    .asFunction();

class FaderWidget extends ModuleWidget {
  FaderWidget(RawNode m, RawWidget w) : super(m, w);

  double value = 0.5;
  String? labelText;

  @override
  Widget build(BuildContext context) {
    Color color = Color(ffiFaderGetColor(widgetRaw.pointer));

    var labelRaw = ffiFaderGetLabel(widgetRaw.pointer);
    var labelText = labelRaw.toDartString();
    calloc.free(labelRaw);

    return LayoutBuilder(builder: (context, constraints) {
      double value = ffiFaderGetValue(widgetRaw.pointer);

      return GestureDetector(
        onTapDown: (e) {
          setState(() {
            double newValue = 1 - (e.localPosition.dy / constraints.maxHeight);
            ffiFaderSetValue(widgetRaw.pointer, newValue);
          });
        },
        onPanUpdate: (e) {
          setState(() {
            double newValue = 1 - (e.localPosition.dy / constraints.maxHeight);
            ffiFaderSetValue(widgetRaw.pointer, newValue);
          });
        },
        child: Container(
          width: constraints.maxWidth,
          height: constraints.maxHeight,
          alignment: Alignment.bottomCenter,
          child: Container(
            width: constraints.maxWidth,
            height: constraints.maxHeight * value,
            decoration: BoxDecoration(
                color: color,
                borderRadius: const BorderRadius.all(Radius.circular(3))),
          ),
          decoration: BoxDecoration(
              border: Border.all(
                color: color,
                width: 2.0,
              ),
              borderRadius: const BorderRadius.all(Radius.circular(5))),
        ),
      );
    });
  }
}
