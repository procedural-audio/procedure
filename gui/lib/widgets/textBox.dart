import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'widget.dart';
import 'dart:io';
import 'dart:ffi';

import '../main.dart';
import '../host.dart';

double Function(FFIWidgetPointer) ffiFloatBoxGetValue = core
    .lookup<NativeFunction<Float Function(FFIWidgetPointer)>>(
        "ffi_float_box_get_value")
    .asFunction();

void Function(FFIWidgetPointer, double) ffiFloatBoxSetValue = core
    .lookup<NativeFunction<Void Function(FFIWidgetPointer, Float)>>(
        "ffi_float_box_set_value")
    .asFunction();

class FloatBox extends ModuleWidget {
  FloatBox(Host h, FFINode m, FFIWidget w) : super(h, m, w) {
    value = ffiFloatBoxGetValue(widgetRaw.pointer).toString();
  }

  bool mouseOver = false;
  String value = "0.0";

  @override
  Widget build(BuildContext context) {
    double v = double.tryParse(value) ?? 0.0;

    ffiFloatBoxSetValue(widgetRaw.pointer, v);

    return TextField(
      onChanged: (String v) {
        setState(() {
          value = v;
        });
      },
      style: const TextStyle(color: Colors.red, fontSize: 16),
      decoration: const InputDecoration(
          border: OutlineInputBorder(),
          contentPadding: EdgeInsets.all(5.0),
          focusColor: Colors.red,
          fillColor: Color.fromRGBO(20, 20, 20, 1.0),
          iconColor: Colors.red),
    );
  }
}
