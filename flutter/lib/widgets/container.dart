import 'package:flutter/material.dart';
import 'package:ffi/ffi.dart';
import 'package:metasampler/views/settings.dart';

import 'dart:io';
import 'dart:ffi';

import '../host.dart';
import 'widget.dart';

var knobValue = "value".toNativeUtf8();
var colorValue = "color".toNativeUtf8();

int Function(FFIWidgetPointer) ffiContainerGetWidth = core
    .lookup<NativeFunction<Int32 Function(FFIWidgetPointer)>>(
        "ffi_container_get_width")
    .asFunction();
int Function(FFIWidgetPointer) ffiContainerGetHeight = core
    .lookup<NativeFunction<Int32 Function(FFIWidgetPointer)>>(
        "ffi_container_get_height")
    .asFunction();
int Function(FFIWidgetPointer) ffiContainerGetColor = core
    .lookup<NativeFunction<Int32 Function(FFIWidgetPointer)>>(
        "ffi_container_get_color")
    .asFunction();
int Function(FFIWidgetPointer) ffiContainerGetBorderRadius = core
    .lookup<NativeFunction<Int32 Function(FFIWidgetPointer)>>(
        "ffi_container_get_border_radius")
    .asFunction();
int Function(FFIWidgetPointer) ffiContainerGetBorderColor = core
    .lookup<NativeFunction<Int32 Function(FFIWidgetPointer)>>(
        "ffi_container_get_border_color")
    .asFunction();
int Function(FFIWidgetPointer) ffiContainerGetBorderThickness = core
    .lookup<NativeFunction<Int32 Function(FFIWidgetPointer)>>(
        "ffi_container_get_border_thickness")
    .asFunction();

class ContainerWidget extends ModuleWidget {
  ContainerWidget(Host h, FFINode m, FFIWidget w) : super(h, m, w) {
    width = ffiContainerGetWidth(w.pointer);
    height = ffiContainerGetHeight(w.pointer);
    color = Color(ffiContainerGetColor(w.pointer));
    borderRadius = ffiContainerGetBorderRadius(w.pointer);
    borderColor = Color(ffiContainerGetBorderColor(w.pointer));
    borderThickness = ffiContainerGetBorderThickness(w.pointer);
  }

  late int width;
  late int height;
  late Color color;
  late int borderRadius;
  late Color borderColor;
  late int borderThickness;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width + 0.0,
      height: height + 0.0,
      decoration: BoxDecoration(
          color: color,
          border: Border.all(
            color: borderColor,
            width: borderThickness + 0.0,
          ),
          borderRadius: BorderRadius.circular(borderRadius + 0.0)),
      child: children[0],
    );
  }
}
