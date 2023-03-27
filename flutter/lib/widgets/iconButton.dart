import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'widget.dart';
import 'dart:ffi';
import '../patch.dart';
import '../core.dart';
import '../module.dart';
import '../main.dart';

void Function(RawWidgetTrait, bool) ffiIconButtonPressed = core
    .lookup<NativeFunction<Void Function(RawWidgetTrait, Bool)>>(
        "ffi_icon_button_pressed")
    .asFunction();

class IconButtonWidget extends ModuleWidget {
  IconButtonWidget(RawNode m, RawWidget w) : super(m, w);

  bool mouseOver = false;

  @override
  Widget build(BuildContext context) {
    return Container(
        decoration: BoxDecoration(
            color: mouseOver
                ? const Color.fromRGBO(30, 30, 30, 1.0)
                : const Color.fromRGBO(20, 20, 20, 1.0),
            borderRadius: const BorderRadius.all(Radius.circular(5))),
        child: GestureDetector(
            onTap: () {},
            child: Listener(
                onPointerDown: (e) {
                  ffiIconButtonPressed(widgetRaw.getTrait(), true);
                },
                onPointerUp: (e) {
                  ffiIconButtonPressed(widgetRaw.getTrait(), false);
                },
                onPointerCancel: (e) {
                  ffiIconButtonPressed(widgetRaw.getTrait(), false);
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
                    child: const Icon(
                      Icons.access_alarm,
                      color: Color.fromRGBO(200, 200, 200, 1.0),
                      size: 20,
                    )))));
  }
}
