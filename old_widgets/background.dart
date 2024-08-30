import 'package:flutter/material.dart';
import 'package:ffi/ffi.dart';

import 'dart:ffi';

import 'widget.dart';

import '../core.dart';
import '../module/node.dart';

int Function(RawWidgetTrait) ffiBackgroundGetColor = core
    .lookup<NativeFunction<Int32 Function(RawWidgetTrait)>>(
        "ffi_background_get_color")
    .asFunction();
int Function(RawWidgetTrait) ffiBackgroundGetBorderRadius = core
    .lookup<NativeFunction<Int32 Function(RawWidgetTrait)>>(
        "ffi_background_get_border_radius")
    .asFunction();
int Function(RawWidgetTrait) ffiBackgroundGetBorderWidth = core
    .lookup<NativeFunction<Int32 Function(RawWidgetTrait)>>(
        "ffi_background_get_border_width")
    .asFunction();
int Function(RawWidgetTrait) ffiBackgroundGetBorderColor = core
    .lookup<NativeFunction<Int32 Function(RawWidgetTrait)>>(
        "ffi_background_get_border_color")
    .asFunction();

class BackgroundWidget extends ModuleWidget {
  BackgroundWidget(Node n, RawNode m, RawWidget w) : super(n, m, w);

  @override
  Widget build(BuildContext context) {
    int color = ffiBackgroundGetColor(widgetRaw.getTrait());
    int borderRadius = ffiBackgroundGetBorderRadius(widgetRaw.getTrait());
    int borderWidth = ffiBackgroundGetBorderWidth(widgetRaw.getTrait());
    int borderColor = ffiBackgroundGetBorderColor(widgetRaw.getTrait());

    return Container(
      decoration: BoxDecoration(
        color: intToColor(color),
        border: Border.all(
          width: borderWidth.toDouble(),
          color:
              borderWidth == 0 ? Colors.transparent : intToColor(borderColor),
        ),
        borderRadius: BorderRadius.circular(
          borderRadius.toDouble(),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(
          borderRadius.toDouble(),
        ),
        child: children[0],
      ),
    );
  }
}
