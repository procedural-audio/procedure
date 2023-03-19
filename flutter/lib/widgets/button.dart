import 'package:flutter/material.dart';

import 'widget.dart';
import 'dart:ffi';
import '../host.dart';
import '../core.dart';
import '../module.dart';
import '../main.dart';

int Function(FFIWidgetTrait) ffiButtonGetColor = core
    .lookup<NativeFunction<Int32 Function(FFIWidgetTrait)>>(
        "ffi_button_get_color")
    .asFunction();
void Function(FFIWidgetTrait, bool) ffiButtonOnPressed = core
    .lookup<NativeFunction<Void Function(FFIWidgetTrait, Bool)>>(
        "ffi_button_on_pressed")
    .asFunction();

class ButtonWidget extends ModuleWidget {
  ButtonWidget(App a, RawNode m, FFIWidget w) : super(a, m, w) {
    color = intToColor(ffiButtonGetColor(widgetRaw.getTrait()));
  }

  bool mouseOver = false;
  bool down = false;
  Color color = Colors.grey;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
        onTap: () {},
        child: Listener(
            onPointerDown: (e) {
              setState(() {
                ffiButtonOnPressed(widgetRaw.getTrait(), true);
              });
            },
            onPointerUp: (e) {
              setState(() {
                ffiButtonOnPressed(widgetRaw.getTrait(), false);
              });
            },
            onPointerCancel: (e) {
              setState(() {
                ffiButtonOnPressed(widgetRaw.getTrait(), false);
              });
            },
            child: MouseRegion(
                onEnter: (event) {
                  setState(() {
                    mouseOver = true;
                  });
                },
                onExit: (event) {
                  setState(() {
                    mouseOver = false;
                  });
                },
                child: Container(
                    decoration: BoxDecoration(
                        color: color,
                        borderRadius:
                            const BorderRadius.all(Radius.circular(5)))))));
  }
}
