import 'package:flutter/material.dart';
import 'dart:ffi';

import '../patch.dart';
import 'widget.dart';
import '../core.dart';
import '../module.dart';
import '../main.dart';

void Function(RawWidgetTrait, double, double) ffiMouseListenerOnDown = core
    .lookup<NativeFunction<Void Function(RawWidgetTrait, Float, Float)>>(
        "ffi_mouse_listener_on_down")
    .asFunction();
void Function(RawWidgetTrait, double, double) ffiMouseListenerOnUp = core
    .lookup<NativeFunction<Void Function(RawWidgetTrait, Float, Float)>>(
        "ffi_mouse_listener_on_up")
    .asFunction();
void Function(RawWidgetTrait, double, double) ffiMouseListenerOnDrag = core
    .lookup<NativeFunction<Void Function(RawWidgetTrait, Float, Float)>>(
        "ffi_mouse_listener_on_drag")
    .asFunction();

class MouseListenerWidget extends ModuleWidget {
  MouseListenerWidget(Node n, RawNode m, RawWidget w) : super(n, m, w);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (e) {
        double x = e.localPosition.dx;
        double y = e.localPosition.dy;
        setState(() {
          ffiMouseListenerOnDown(widgetRaw.getTrait(), x, y);
        });
      },
      onTapUp: (e) {
        double x = e.localPosition.dx;
        double y = e.localPosition.dy;
        setState(() {
          ffiMouseListenerOnUp(widgetRaw.getTrait(), x, y);
        });
      },
      onTapCancel: () {},
      onPanStart: (e) {
        double x = e.localPosition.dx;
        double y = e.localPosition.dy;
        setState(() {
          ffiMouseListenerOnDrag(widgetRaw.getTrait(), x, y);
        });
      },
      onPanUpdate: (e) {
        double x = e.localPosition.dx;
        double y = e.localPosition.dy;
        setState(() {
          ffiMouseListenerOnDrag(widgetRaw.getTrait(), x, y);
        });
      },
      child: children[0],
    );
  }
}
