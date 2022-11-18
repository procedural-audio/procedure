import 'package:flutter/material.dart';
import 'package:ffi/ffi.dart';
import 'package:flutter_svg/svg.dart';
import '../host.dart';
import '../views/variables.dart';
import 'widget.dart';
import 'dart:ffi';
import 'dart:io';
import '../config.dart';

int Function(FFIWidgetPointer) ffiButtonGridGetIndex = core
    .lookup<NativeFunction<Int64 Function(FFIWidgetPointer)>>(
        "ffi_button_grid_get_index")
    .asFunction();
void Function(FFIWidgetPointer, int) ffiButtonGridSetIndex = core
    .lookup<NativeFunction<Void Function(FFIWidgetPointer, Int64)>>(
        "ffi_button_grid_set_index")
    .asFunction();
int Function(FFIWidgetPointer) ffiButtonGridGetColor = core
    .lookup<NativeFunction<Int32 Function(FFIWidgetPointer)>>(
        "ffi_button_grid_get_color")
    .asFunction();
int Function(FFIWidgetPointer) ffiButtonGridGetRowCount = core
    .lookup<NativeFunction<Int64 Function(FFIWidgetPointer)>>(
        "ffi_button_grid_get_row_count")
    .asFunction();
int Function(FFIWidgetPointer) ffiButtonGridGetIconCount = core
    .lookup<NativeFunction<Int64 Function(FFIWidgetPointer)>>(
        "ffi_button_grid_get_icon_count")
    .asFunction();
Pointer<Utf8> Function(FFIWidgetPointer, int) ffiButtonGridIconGetPath = core
    .lookup<NativeFunction<Pointer<Utf8> Function(FFIWidgetPointer, Int64)>>(
        "ffi_button_grid_icon_get_path")
    .asFunction();

class ButtonGridWidget extends ModuleWidget {
  ButtonGridWidget(Host h, FFINode m, FFIWidget w) : super(h, m, w) {
    color = intToColor(ffiButtonGridGetColor(widgetRaw.pointer));
    rowCount = ffiButtonGridGetRowCount(widgetRaw.pointer);

    int iconCount = ffiButtonGridGetIconCount(w.pointer);
    for (int i = 0; i < iconCount; i++) {
      var rawPath = ffiButtonGridIconGetPath(w.pointer, i);
      var path = rawPath.toDartString();
      calloc.free(rawPath);

      paths.add(path);
    }
  }

  List<String> paths = [];
  late Color color;
  late int rowCount;

  int hoverIndex = -1;

  @override
  bool canAcceptVars() {
    return true;
  }

  @override
  bool willAcceptVar(Var v) {
    return v.notifier.value is int;
  }

  @override
  void onVarUpdate(dynamic value) {
    ffiButtonGridSetIndex(widgetRaw.pointer, value as int);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> icons = [];

    var index = ffiButtonGridGetIndex(widgetRaw.pointer);
    for (int i = 0; i < paths.length; i++) {
      icons.add(MouseRegion(
          onEnter: (e) {
            setState(() {
              hoverIndex = i;
            });
          },
          onExit: (e) {
            if (hoverIndex == i) {
              setState(() {
                hoverIndex = -1;
              });
            }
          },
          child: GestureDetector(
              onTap: () {
                ffiButtonGridSetIndex(widgetRaw.pointer, i);
                if (assignedVar.value != null) {
                  if (assignedVar.value!.notifier.value is int) {
                    assignedVar.value!.notifier.value = i;
                  }
                }
                setState(() {});
              },
              child: Padding(
                  padding: const EdgeInsets.all(5),
                  child: SvgPicture.file(
                      File(contentPath + "/assets/icons/" + paths[i]),
                      color: i == index
                          ? color
                          : (hoverIndex == i
                              ? color.withOpacity(0.6)
                              : color.withOpacity(0.3)))))));
    }

    return GridView.count(
        crossAxisCount: paths.length ~/ rowCount, children: icons);
  }
}
