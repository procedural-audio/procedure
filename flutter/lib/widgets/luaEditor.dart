import 'package:flutter/material.dart';
import 'package:ffi/ffi.dart';
import '../host.dart';
import 'widget.dart';
import '../main.dart';
import 'dart:ui' as ui;
import 'dart:ffi';
import '../ui/code_editor/editor.dart';

/*double Function(FFIWidgetPointer) ffiSliderGetValue = core
    .lookup<NativeFunction<Float Function(FFIWidgetPointer)>>(
        "ffi_slider_get_value")
    .asFunction();
int Function(FFIWidgetPointer) ffiSliderGetDivisions = core
    .lookup<NativeFunction<Int32 Function(FFIWidgetPointer)>>(
        "ffi_slider_get_divisions")
    .asFunction();
void Function(FFIWidgetPointer, double) ffiSliderSetValue = core
    .lookup<NativeFunction<Void Function(FFIWidgetPointer, Float)>>(
        "ffi_slider_set_value")
    .asFunction();
int Function(FFIWidgetPointer) ffiSliderGetColor = core
    .lookup<NativeFunction<Int32 Function(FFIWidgetPointer)>>(
        "ffi_slider_get_color")
    .asFunction();*/

class LuaEditorWidget extends ModuleWidget {
  LuaEditorWidget(Host h, FFINode m, FFIWidget w) : super(h, m, w);

  @override
  Widget build(BuildContext context) {
    return Editor();
  }
}
