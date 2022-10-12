import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'widget.dart';
import 'dart:io';
import 'dart:ffi';
import '../host.dart';

import 'package:ffi/ffi.dart';

import '../main.dart';

bool Function(FFIWidgetTrait) ffiButtonGetPressed = core
    .lookup<NativeFunction<Bool Function(FFIWidgetTrait)>>(
        "ffi_button_get_pressed")
    .asFunction();
bool Function(FFIWidgetTrait) ffiButtonGetToggle = core
    .lookup<NativeFunction<Bool Function(FFIWidgetTrait)>>(
        "ffi_button_get_toggle")
    .asFunction();
void Function(FFIWidgetTrait, bool) ffiButtonOnChanged = core
    .lookup<NativeFunction<Void Function(FFIWidgetTrait, Bool)>>(
        "ffi_button_on_changed")
    .asFunction();

class ButtonWidget extends ModuleWidget {
  ButtonWidget(Host h, FFINode m, FFIWidget w) : super(h, m, w);

  bool mouseOver = false;

  @override
  Widget build(BuildContext context) {
    bool pressed = ffiButtonGetPressed(widgetRaw.getTrait());
    bool toggle = ffiButtonGetToggle(widgetRaw.getTrait());

    return Container(
      padding: const EdgeInsets.all(5),
      child: Stack(
          fit: StackFit.expand,
          children: <Widget>[] +
              children +
              [
                GestureDetector(
                  onTap: () {
                    print("Caught tap");
                  },
                ),
                Listener(
                  onPointerDown: (e) {
                    if (toggle) {
                      ffiButtonOnChanged(widgetRaw.getTrait(), !pressed);
                      setState(() {
                        for (var c in children) {
                          c.refresh();
                        }
                      });
                    } else {
                      ffiButtonOnChanged(widgetRaw.getTrait(), true);
                      setState(() {
                        for (var c in children) {
                          c.refresh();
                        }
                      });
                    }
                  },
                  onPointerUp: (e) {
                    if (!toggle) {
                      ffiButtonOnChanged(widgetRaw.getTrait(), false);
                      setState(() {
                        for (var c in children) {
                          c.refresh();
                        }
                      });
                    }
                  },
                  onPointerCancel: (e) {
                    if (!toggle) {
                      ffiButtonOnChanged(widgetRaw.getTrait(), false);
                      setState(() {
                        for (var c in children) {
                          c.refresh();
                        }
                      });
                    }
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
                  ),
                )
              ]),
    );
  }
}
