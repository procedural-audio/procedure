import 'package:flutter/material.dart';
import 'package:ffi/ffi.dart';

import 'dart:io';
import 'dart:ffi';

import '../host.dart';
import 'widget.dart';
import '../core.dart';
import '../module.dart';

Pointer<Utf8> Function(FFIWidgetPointer) ffiTextGetText = core
    .lookup<NativeFunction<Pointer<Utf8> Function(FFIWidgetPointer)>>(
        "ffi_text_get_text")
    .asFunction();

int Function(FFIWidgetPointer) ffiTextGetColor = core
    .lookup<NativeFunction<Int32 Function(FFIWidgetPointer)>>(
        "ffi_text_get_color")
    .asFunction();

int Function(FFIWidgetPointer) ffiTextGetSize = core
    .lookup<NativeFunction<Int32 Function(FFIWidgetPointer)>>(
        "ffi_text_get_size")
    .asFunction();

class TextWidget extends ModuleWidget {
  TextWidget(Host h, RawNode m, FFIWidget w) : super(h, m, w);

  @override
  Widget build(BuildContext context) {
    var textRaw = ffiTextGetText(widgetRaw.pointer);
    var text = textRaw.toDartString();
    calloc.free(textRaw);

    var color = intToColor(ffiTextGetColor(widgetRaw.pointer));
    int size = ffiTextGetSize(widgetRaw.pointer);

    return Text(
      text,
      style: TextStyle(
        color: color,
        fontSize: size.toDouble()
      )
    );
  }
}
