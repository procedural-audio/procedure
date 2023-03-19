import 'package:flutter/material.dart';
import 'dart:ffi';

import '../host.dart';
import 'widget.dart';
import '../core.dart';
import '../module.dart';
import '../main.dart';

class StackWidget extends ModuleWidget {
  StackWidget(App a, RawNode m, FFIWidget w) : super(a, m, w);

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: children,
    );
  }
}

class RowWidget extends ModuleWidget {
  RowWidget(App a, RawNode m, FFIWidget w) : super(a, m, w);

  @override
  Widget build(BuildContext context) {
    return Row(
        mainAxisSize: MainAxisSize.max,
        children: children.map((e) => Expanded(child: e)).toList());
  }
}

class ColumnWidget extends ModuleWidget {
  ColumnWidget(App a, RawNode m, FFIWidget w) : super(a, m, w);

  @override
  Widget build(BuildContext context) {
    return Column(
        mainAxisSize: MainAxisSize.max,
        children: children.map((e) => Expanded(child: e)).toList());
  }
}

int Function(FFIWidget) ffiPositionedGetX = core
    .lookup<NativeFunction<Int32 Function(FFIWidget)>>("ffi_positioned_get_x")
    .asFunction();
int Function(FFIWidget) ffiPositionedGetY = core
    .lookup<NativeFunction<Int32 Function(FFIWidget)>>("ffi_positioned_get_y")
    .asFunction();

class PositionedWidget extends ModuleWidget {
  PositionedWidget(App a, RawNode m, FFIWidget w) : super(a, m, w);

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: ffiPositionedGetX(widgetRaw) + 0.0,
      top: ffiPositionedGetY(widgetRaw) + 0.0,
      child: children[0],
    );
  }
}

int Function(FFIWidget) ffiSizedBoxGetWidth = core
    .lookup<NativeFunction<Int32 Function(FFIWidget)>>(
        "ffi_sized_box_get_width")
    .asFunction();
int Function(FFIWidget) ffiSizedBoxGetHeight = core
    .lookup<NativeFunction<Int32 Function(FFIWidget)>>(
        "ffi_sized_box_get_height")
    .asFunction();

class SizedBoxWidget extends ModuleWidget {
  SizedBoxWidget(App a, RawNode m, FFIWidget w) : super(a, m, w);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: ffiSizedBoxGetWidth(widgetRaw) + 0.0,
      height: ffiSizedBoxGetHeight(widgetRaw) + 0.0,
      child: children[0],
    );
  }
}

int Function(FFIWidgetPointer) ffiTransformGetX = core
    .lookup<NativeFunction<Int32 Function(FFIWidgetPointer)>>(
        "ffi_transform_get_x")
    .asFunction();
int Function(FFIWidgetPointer) ffiTransformGetY = core
    .lookup<NativeFunction<Int32 Function(FFIWidgetPointer)>>(
        "ffi_transform_get_y")
    .asFunction();
int Function(FFIWidgetPointer) ffiTransformGetWidth = core
    .lookup<NativeFunction<Int32 Function(FFIWidgetPointer)>>(
        "ffi_transform_get_width")
    .asFunction();
int Function(FFIWidgetPointer) ffiTransformGetHeight = core
    .lookup<NativeFunction<Int32 Function(FFIWidgetPointer)>>(
        "ffi_transform_get_height")
    .asFunction();

class TransformWidget extends ModuleWidget {
  TransformWidget(App a, RawNode m, FFIWidget w) : super(a, m, w);

  @override
  Widget build(BuildContext context) {
    return Positioned(
        left: ffiTransformGetX(widgetRaw.pointer) + 0.0,
        top: ffiTransformGetY(widgetRaw.pointer) + 0.0,
        child: SizedBox(
          width: ffiTransformGetWidth(widgetRaw.pointer) + 0.0,
          height: ffiTransformGetHeight(widgetRaw.pointer) + 0.0,
          child: children[0],
        ));
  }
}

int Function(FFIWidgetPointer) ffiPaddingGetLeft = core
    .lookup<NativeFunction<Int32 Function(FFIWidgetPointer)>>(
        "ffi_padding_get_left")
    .asFunction();
int Function(FFIWidgetPointer) ffiPaddingGetTop = core
    .lookup<NativeFunction<Int32 Function(FFIWidgetPointer)>>(
        "ffi_padding_get_top")
    .asFunction();
int Function(FFIWidgetPointer) ffiPaddingGetRight = core
    .lookup<NativeFunction<Int32 Function(FFIWidgetPointer)>>(
        "ffi_padding_get_right")
    .asFunction();
int Function(FFIWidgetPointer) ffiPaddingGetBottom = core
    .lookup<NativeFunction<Int32 Function(FFIWidgetPointer)>>(
        "ffi_padding_get_bottom")
    .asFunction();

class PaddingWidget extends ModuleWidget {
  PaddingWidget(App a, RawNode m, FFIWidget w) : super(a, m, w);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        ffiPaddingGetLeft(widgetRaw.pointer).toDouble(),
        ffiPaddingGetTop(widgetRaw.pointer).toDouble(),
        ffiPaddingGetRight(widgetRaw.pointer).toDouble(),
        ffiPaddingGetBottom(widgetRaw.pointer).toDouble(),
      ),
      child: children[0],
    );
  }
}
