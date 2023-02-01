import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'widget.dart';
import 'dart:io';
import 'dart:ffi';
import '../host.dart';

import 'package:ffi/ffi.dart';

import '../config.dart';

import '../main.dart';

bool Function(FFIWidgetPointer) ffiSvgButtonGetPressed = core
    .lookup<NativeFunction<Bool Function(FFIWidgetPointer)>>(
        "ffi_svg_button_get_pressed")
    .asFunction();
void Function(FFIWidgetPointer, bool) ffiSvgButtonSetPressed = core
    .lookup<NativeFunction<Void Function(FFIWidgetPointer, Bool)>>(
        "ffi_svg_button_set_pressed")
    .asFunction();
int Function(FFIWidgetPointer) ffiSvgButtonGetColor = core
    .lookup<NativeFunction<Int32 Function(FFIWidgetPointer)>>(
        "ffi_svg_button_get_color")
    .asFunction();
Pointer<Utf8> Function(FFIWidgetPointer) ffiSvgButtonGetPath = core
    .lookup<NativeFunction<Pointer<Utf8> Function(FFIWidgetPointer)>>(
        "ffi_svg_button_get_path")
    .asFunction();
void Function(FFIWidgetPointer, bool) ffiSvgButtonOnChanged = core
    .lookup<NativeFunction<Void Function(FFIWidgetPointer, Bool)>>(
        "ffi_svg_button_on_changed")
    .asFunction();

class ButtonSVG extends ModuleWidget {
  ButtonSVG(Host h, FFINode m, FFIWidget w) : super(h, m, w) {
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

int Function(FFIWidgetTrait) ffiSvgGetColor = core
    .lookup<NativeFunction<Int32 Function(FFIWidgetTrait)>>("ffi_svg_get_color")
    .asFunction();
Pointer<Utf8> Function(FFIWidgetTrait) ffiSvgGetPath = core
    .lookup<NativeFunction<Pointer<Utf8> Function(FFIWidgetTrait)>>(
        "ffi_svg_get_path")
    .asFunction();

class SvgWidget extends ModuleWidget {
  SvgWidget(Host h, FFINode m, FFIWidget w) : super(h, m, w) {
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
