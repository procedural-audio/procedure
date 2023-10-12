import 'package:flutter/material.dart';
import 'dart:ffi';

import 'widget.dart';
import '../core.dart';
import '../module.dart';

class RowWidget extends ModuleWidget {
  RowWidget(Node n, RawNode m, RawWidget w) : super(n, m, w);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.max,
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: children.map((e) => e).toList(),
    );
  }
}

class ColumnWidget extends ModuleWidget {
  ColumnWidget(Node n, RawNode m, RawWidget w) : super(n, m, w);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.max,
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: children.map((e) => e).toList(),
    );
  }
}

class StackWidget extends ModuleWidget {
  StackWidget(Node n, RawNode m, RawWidget w) : super(n, m, w);

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: children,
    );
  }
}

class ExpandedWidget extends ModuleWidget {
  ExpandedWidget(Node n, RawNode m, RawWidget w) : super(n, m, w);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: children[0],
    );
  }
}

int Function(RawWidget) ffiPositionedGetX = core
    .lookup<NativeFunction<Int32 Function(RawWidget)>>("ffi_positioned_get_x")
    .asFunction();
int Function(RawWidget) ffiPositionedGetY = core
    .lookup<NativeFunction<Int32 Function(RawWidget)>>("ffi_positioned_get_y")
    .asFunction();

class PositionedWidget extends ModuleWidget {
  PositionedWidget(Node n, RawNode m, RawWidget w) : super(n, m, w);

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: ffiPositionedGetX(widgetRaw) + 0.0,
      top: ffiPositionedGetY(widgetRaw) + 0.0,
      child: children[0],
    );
  }
}

int Function(RawWidget) ffiSizedBoxGetWidth = core
    .lookup<NativeFunction<Int32 Function(RawWidget)>>(
        "ffi_sized_box_get_width")
    .asFunction();
int Function(RawWidget) ffiSizedBoxGetHeight = core
    .lookup<NativeFunction<Int32 Function(RawWidget)>>(
        "ffi_sized_box_get_height")
    .asFunction();

class SizedBoxWidget extends ModuleWidget {
  SizedBoxWidget(Node n, RawNode m, RawWidget w) : super(n, m, w);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: ffiSizedBoxGetWidth(widgetRaw) + 0.0,
      height: ffiSizedBoxGetHeight(widgetRaw) + 0.0,
      child: children[0],
    );
  }
}

int Function(RawWidgetPointer) ffiTransformGetX = core
    .lookup<NativeFunction<Int32 Function(RawWidgetPointer)>>(
        "ffi_transform_get_x")
    .asFunction();
int Function(RawWidgetPointer) ffiTransformGetY = core
    .lookup<NativeFunction<Int32 Function(RawWidgetPointer)>>(
        "ffi_transform_get_y")
    .asFunction();
int Function(RawWidgetPointer) ffiTransformGetWidth = core
    .lookup<NativeFunction<Int32 Function(RawWidgetPointer)>>(
        "ffi_transform_get_width")
    .asFunction();
int Function(RawWidgetPointer) ffiTransformGetHeight = core
    .lookup<NativeFunction<Int32 Function(RawWidgetPointer)>>(
        "ffi_transform_get_height")
    .asFunction();

class TransformWidget extends ModuleWidget {
  TransformWidget(Node n, RawNode m, RawWidget w) : super(n, m, w);

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

int Function(RawWidgetPointer) ffiPaddingGetLeft = core
    .lookup<NativeFunction<Int32 Function(RawWidgetPointer)>>(
        "ffi_padding_get_left")
    .asFunction();
int Function(RawWidgetPointer) ffiPaddingGetTop = core
    .lookup<NativeFunction<Int32 Function(RawWidgetPointer)>>(
        "ffi_padding_get_top")
    .asFunction();
int Function(RawWidgetPointer) ffiPaddingGetRight = core
    .lookup<NativeFunction<Int32 Function(RawWidgetPointer)>>(
        "ffi_padding_get_right")
    .asFunction();
int Function(RawWidgetPointer) ffiPaddingGetBottom = core
    .lookup<NativeFunction<Int32 Function(RawWidgetPointer)>>(
        "ffi_padding_get_bottom")
    .asFunction();

class PaddingWidget extends ModuleWidget {
  PaddingWidget(Node n, RawNode m, RawWidget w) : super(n, m, w);

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
