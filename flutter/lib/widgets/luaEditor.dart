import 'package:flutter/material.dart';
import 'package:ffi/ffi.dart';
import 'package:flutter_highlight/themes/monokai-sublime.dart';
import 'package:highlight/languages/lua.dart';
import 'package:metasampler/ui/code_editor/code_text_field.dart';
import '../host.dart';
import 'widget.dart';
import '../main.dart';
import 'dart:ui' as ui;
import 'dart:ffi';

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

  final controller = CodeController(
    language: lua,
    stringMap: {
      "function":
          const TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
      "if": const TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
      "do": const TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
      "end": const TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
      "while": const TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
    },
  );

  @override
  Widget build(BuildContext context) {
    return CodeField(
        controller: controller,
        textStyle: const TextStyle(fontFamily: "SourceCode"));
  }
}
