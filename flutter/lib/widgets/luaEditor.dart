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
import '../ui/code_editor/code_text_field.dart';

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

  /*final controller = CodeController(
    language: lua,
    stringMap: {
      "function":
          const TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
      "if": const TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
      "do": const TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
      "end": const TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
      "while": const TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
    },
  );*/

  @override
  Widget build(BuildContext context) {
    bool isOver = false;
    /*return CodeField(
        controller: controller,
        textStyle: const TextStyle(fontFamily: "SourceCode"));*/
    return Container(
        decoration: const BoxDecoration(
            color: Color.fromRGBO(20, 20, 20, 1.0),
            borderRadius: BorderRadius.all(Radius.circular(5))),
        child: Column(children: [
          Expanded(child: children[0]),
          Container(
              height: 16,
              decoration: const BoxDecoration(
                  color: Color.fromRGBO(20, 20, 20, 1.0),
                  borderRadius:
                      BorderRadius.vertical(bottom: Radius.circular(5))),
              child: Row(children: [
                const SizedBox(width: 4),
                const Icon(Icons.folder, size: 14, color: Colors.blue),
                const SizedBox(width: 4),
                MouseRegion(
                    onEnter: (e) {
                      setState(() {
                        isOver = true;
                      });
                    },
                    onExit: (e) {
                      setState(() {
                        isOver = false;
                      });
                    },
                    child: Container(
                        decoration: BoxDecoration(
                            color: isOver
                                ? const Color.fromRGBO(30, 30, 30, 1.0)
                                : const Color.fromRGBO(20, 20, 20, 1.0)),
                        child: const Text("~/scripts/multi-sampler/default.lua",
                            style:
                                TextStyle(fontSize: 10, color: Colors.grey)))),
                Expanded(child: Container()),
                const Text("Status:",
                    style: TextStyle(fontSize: 10, color: Colors.grey)),
                const SizedBox(width: 4),
                const Text("Running...",
                    style: TextStyle(fontSize: 10, color: Colors.green)),
                const SizedBox(width: 4),
              ]))
        ]));
  }
}
