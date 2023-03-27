import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'widget.dart';
import 'dart:io';
import 'dart:ffi';
import '../patch.dart';

import 'package:ffi/ffi.dart';

import '../config.dart';

import '../main.dart';
import '../core.dart';
import '../module.dart';

bool Function(RawWidgetPointer) ffiSvgButtonGetPressed = core
    .lookup<NativeFunction<Bool Function(RawWidgetPointer)>>(
        "ffi_svg_button_get_pressed")
    .asFunction();
void Function(RawWidgetPointer, bool) ffiSvgButtonSetPressed = core
    .lookup<NativeFunction<Void Function(RawWidgetPointer, Bool)>>(
        "ffi_svg_button_set_pressed")
    .asFunction();
int Function(RawWidgetPointer) ffiSvgButtonGetColor = core
    .lookup<NativeFunction<Int32 Function(RawWidgetPointer)>>(
        "ffi_svg_button_get_color")
    .asFunction();
Pointer<Utf8> Function(RawWidgetPointer) ffiSvgButtonGetPath = core
    .lookup<NativeFunction<Pointer<Utf8> Function(RawWidgetPointer)>>(
        "ffi_svg_button_get_path")
    .asFunction();
void Function(RawWidgetPointer, bool) ffiSvgButtonOnChanged = core
    .lookup<NativeFunction<Void Function(RawWidgetPointer, Bool)>>(
        "ffi_svg_button_on_changed")
    .asFunction();

class ButtonSVG extends ModuleWidget {
  ButtonSVG(RawNode m, RawWidget w) : super(m, w) {
    var pathRaw = ffiSvgButtonGetPath(widgetRaw.pointer);
    path = contentPath + "/assets/icons/" + pathRaw.toDartString();
    calloc.free(pathRaw);
  }

  bool mouseOver = false;
  late String path;

  @override
  Widget build(BuildContext context) {
    Color color = intToColor(ffiSvgButtonGetColor(widgetRaw.pointer));
    bool active = ffiSvgButtonGetPressed(widgetRaw.pointer);

    return Container(
        padding: const EdgeInsets.all(5),
        child: Stack(children: [
          SvgPicture.file(
            File(path),
            color: mouseOver
                ? color
                : active
                    ? color
                    : color.withAlpha(100),
          ),
          MouseRegion(onEnter: (event) {
            setState(() {
              mouseOver = true;
            });
          }, onExit: (event) {
            setState(() {
              mouseOver = false;
            });
          }),
          GestureDetector(onTap: () {
            ffiSvgButtonOnChanged(widgetRaw.pointer, !active);
            refresh();
          })
        ]));
  }
}

int Function(RawWidgetTrait) ffiSvgGetColor = core
    .lookup<NativeFunction<Int32 Function(RawWidgetTrait)>>("ffi_svg_get_color")
    .asFunction();
Pointer<Utf8> Function(RawWidgetTrait) ffiSvgGetPath = core
    .lookup<NativeFunction<Pointer<Utf8> Function(RawWidgetTrait)>>(
        "ffi_svg_get_path")
    .asFunction();

class SvgWidget extends ModuleWidget {
  SvgWidget(RawNode m, RawWidget w) : super(m, w) {
    var pathRaw = ffiSvgGetPath(widgetRaw.getTrait());
    path = contentPath + "/assets/icons/" + pathRaw.toDartString();
    calloc.free(pathRaw);
  }

  String path = "";

  @override
  Widget build(BuildContext context) {
    Color color = intToColor(ffiSvgGetColor(widgetRaw.getTrait()));

    return SvgPicture.file(
      File(path),
      color: color,
    );
  }
}
