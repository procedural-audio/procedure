import 'package:flutter/material.dart';
import 'package:ffi/ffi.dart';
import 'package:flutter_highlight/themes/monokai-sublime.dart';
import 'package:highlight/languages/lua.dart';
import 'package:metasampler/ui/code_editor/code_text_field.dart';
import '../patch.dart';
import 'widget.dart';
import '../main.dart';
import 'dart:ui' as ui;
import 'dart:ffi';
import '../ui/code_editor/code_text_field.dart';
import '../core.dart';
import '../module.dart';

/*double Function(RawWidgetPointer) ffiSliderGetValue = core
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
    .asFunction();*/

class LuaEditorWidget extends ModuleWidget {
  LuaEditorWidget(Node n, RawNode m, RawWidget w) : super(n, m, w);

  @override
  Widget build(BuildContext context) {
    bool isOver = false;
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
