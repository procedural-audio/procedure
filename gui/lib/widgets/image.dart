import 'package:flutter/material.dart';
import 'package:ffi/ffi.dart';

import 'dart:io';
import 'dart:ffi';

import '../host.dart';
import 'widget.dart';

var knobValue = "value".toNativeUtf8();
var colorValue = "color".toNativeUtf8();

Pointer<Utf8> Function(FFIWidgetPointer) ffiImageGetPath = core
    .lookup<NativeFunction<Pointer<Utf8> Function(FFIWidgetPointer)>>(
        "ffi_image_get_path")
    .asFunction();

class ImageWidget extends ModuleWidget {
  ImageWidget(Host h, FFINode m, FFIWidget w) : super(h, m, w);

  Color color = Colors.blue;
  double value = 0.5;
  String? labelText;

  @override
  Widget createEditor(BuildContext context) {
    return Container(
      width: 150,
      height: 100,
      color: Colors.black,
    );
  }

  @override
  Widget build(BuildContext context) {
    var labelRaw = ffiImageGetPath(widgetRaw.pointer);
    var labelText = labelRaw.toDartString();
    calloc.free(labelRaw);

    return Image.file(
      File(labelText),
      fit: BoxFit.fill,
    );
  }
}
