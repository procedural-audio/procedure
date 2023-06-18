import 'package:flutter/material.dart';

import 'widget.dart';
import 'dart:ffi';
import '../patch.dart';
import '../core.dart';
import '../module.dart';
import '../main.dart';

int Function(RawWidgetTrait) ffiButtonGetColor = core
    .lookup<NativeFunction<Int32 Function(RawWidgetTrait)>>(
        "ffi_button_get_color")
    .asFunction();
void Function(RawWidgetTrait, bool) ffiButtonOnPressed = core
    .lookup<NativeFunction<Void Function(RawWidgetTrait, Bool)>>(
        "ffi_button_on_pressed")
    .asFunction();

class ButtonWidget extends ModuleWidget {
  ButtonWidget(Node n, RawNode m, RawWidget w) : super(n, m, w) {
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
