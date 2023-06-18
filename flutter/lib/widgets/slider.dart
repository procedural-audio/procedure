import 'package:flutter/material.dart';
import 'package:ffi/ffi.dart';
import '../patch.dart';
import 'widget.dart';
import '../main.dart';
import 'dart:ui' as ui;
import 'dart:ffi';
import '../core.dart';
import '../module.dart';

double Function(RawWidgetPointer) ffiSliderGetValue = core
    .lookup<NativeFunction<Float Function(RawWidgetPointer)>>(
        "ffi_slider_get_value")
    .asFunction();
int Function(RawWidgetPointer) ffiSliderGetDivisions = core
    .lookup<NativeFunction<Int32 Function(RawWidgetPointer)>>(
        "ffi_slider_get_divisions")
    .asFunction();
void Function(RawWidgetPointer, double) ffiSliderSetValue = core
    .lookup<NativeFunction<Void Function(RawWidgetPointer, Float)>>(
        "ffi_slider_set_value")
    .asFunction();
int Function(RawWidgetPointer) ffiSliderGetColor = core
    .lookup<NativeFunction<Int32 Function(RawWidgetPointer)>>(
        "ffi_slider_get_color")
    .asFunction();
/*Pointer<Utf8> Function(RawWidgetPointer) ffiSimpleFaderGetLabel = core
    .lookup<NativeFunction<Pointer<Utf8> Function(RawWidgetPointer)>>(
        "ffi_simple_fader_get_label")
    .asFunction();*/

class SliderWidget extends ModuleWidget {
  SliderWidget(Node n, RawNode m, RawWidget w) : super(n, m, w);

  Color color = Colors.blue;
  double value = 0.5;
  String? labelText;

  @override
  Widget build(BuildContext context) {
    Color color = Color(ffiSliderGetColor(widgetRaw.pointer));
    double value = ffiSliderGetValue(widgetRaw.pointer);
    int divisions = ffiSliderGetDivisions(widgetRaw.pointer);

    /*var labelRaw = ffiSimpleFaderGetLabel(widgetRaw.pointer);
    var labelText = labelRaw.toDartString();
    calloc.free(labelRaw);*/

    return SliderTheme(
        data: const SliderThemeData(trackHeight: 1),
        child: Slider(
          value: value,
          min: 0.0,
          max: 1.0,
          divisions: divisions,
          activeColor: color,
          inactiveColor: color.withOpacity(0.3),
          thumbColor: Color.fromRGBO(
              (color.red.toDouble() * 1.2).toInt(),
              (color.green.toDouble() * 1.2).toInt(),
              (color.blue.toDouble() * 1.2).toInt(),
              1.0),
          label: ((value * 10).roundToDouble() / 10).toString(),
          onChanged: (double v) {
            setState(() {
              ffiSliderSetValue(widgetRaw.pointer, v);
            });
          },
        ));
  }
}

double Function(RawWidgetPointer) ffiRangeSliderGetMinValue = core
    .lookup<NativeFunction<Float Function(RawWidgetPointer)>>(
        "ffi_range_slider_get_min_value")
    .asFunction();
double Function(RawWidgetPointer) ffiRangeSliderGetMaxValue = core
    .lookup<NativeFunction<Float Function(RawWidgetPointer)>>(
        "ffi_range_slider_get_max_value")
    .asFunction();
void Function(RawWidgetPointer, double) ffiRangeSliderSetMinValue = core
    .lookup<NativeFunction<Void Function(RawWidgetPointer, Float)>>(
        "ffi_range_slider_set_min_value")
    .asFunction();
void Function(RawWidgetPointer, double) ffiRangeSliderSetMaxValue = core
    .lookup<NativeFunction<Void Function(RawWidgetPointer, Float)>>(
        "ffi_range_slider_set_max_value")
    .asFunction();
int Function(RawWidgetPointer) ffiRangeSliderGetDivisions = core
    .lookup<NativeFunction<Int32 Function(RawWidgetPointer)>>(
        "ffi_range_slider_get_divisions")
    .asFunction();
int Function(RawWidgetPointer) ffiRangeSliderGetColor = core
    .lookup<NativeFunction<Int32 Function(RawWidgetPointer)>>(
        "ffi_range_slider_get_color")
    .asFunction();

class RangeSliderWidget extends ModuleWidget {
  RangeSliderWidget(Node n, RawNode m, RawWidget w) : super(n, m, w);

  Color color = Colors.blue;
  double value = 0.5;
  String? labelText;

  @override
  Widget build(BuildContext context) {
    Color color = Color(ffiRangeSliderGetColor(widgetRaw.pointer));
    double minValue = ffiRangeSliderGetMinValue(widgetRaw.pointer);
    double maxValue = ffiRangeSliderGetMaxValue(widgetRaw.pointer);
    int divisions = ffiRangeSliderGetDivisions(widgetRaw.pointer);

    return SliderTheme(
        data: const SliderThemeData(trackHeight: 1),
        child: RangeSlider(
          values: RangeValues(minValue, maxValue),
          min: 0.0,
          max: 1.0,
          divisions: divisions,
          activeColor: color,
          inactiveColor: color.withOpacity(0.3),
          /*thumbColor: Color.fromRGBO(
              (color.red.toDouble() * 1.2).toInt(),
              (color.green.toDouble() * 1.2).toInt(),
              (color.blue.toDouble() * 1.2).toInt(),
              1.0),*/
          // label: ((value * 10).roundToDouble() / 10).toString(),
          onChanged: (range) {
            setState(() {
              ffiRangeSliderSetMinValue(widgetRaw.pointer, range.start);
              ffiRangeSliderSetMaxValue(widgetRaw.pointer, range.end);
            });
          },
        ));
  }
}
