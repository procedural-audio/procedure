import 'package:flutter/material.dart';
import 'package:ffi/ffi.dart';
import '../host.dart';
import 'widget.dart';
import '../main.dart';
import 'dart:ffi';

class ButtonCanvas extends ModuleWidget {
  ButtonCanvas(Host h, FFINode m, FFIWidget w) : super(h, m, w);

  @override
  Widget build(BuildContext context) {
    print("TODO: FIX BUTTONCANVAS CANVASWIDGET ARGUMENTS");

    int x = 0;
    int y = 0;
    int width = 50;
    int height = 50;

    return Positioned(
      left: x + 0.0,
      top: y + 0.0,
      child: Container(
        width: width + 0.0,
        height: height + 0.0,
        decoration:
            const BoxDecoration(color: Colors.black, shape: BoxShape.rectangle),
      ),
    );
  }
}
