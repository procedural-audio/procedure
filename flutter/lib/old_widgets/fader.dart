import 'package:flutter/material.dart';

import 'dart:math';
import 'dart:ffi';

import 'widget.dart';

import '../core.dart';
import '../module/node.dart';

double Function(RawWidgetTrait) ffiFaderGetValue = core
    .lookup<NativeFunction<Float Function(RawWidgetTrait)>>(
        "ffi_fader_get_value")
    .asFunction();
void Function(RawWidgetTrait, double) ffiFaderSetValue = core
    .lookup<NativeFunction<Void Function(RawWidgetTrait, Float)>>(
        "ffi_fader_set_value")
    .asFunction();
int Function(RawWidgetTrait) ffiFaderGetColor = core
    .lookup<NativeFunction<Int32 Function(RawWidgetTrait)>>(
        "ffi_fader_get_color")
    .asFunction();

class FaderWidget extends ModuleWidget {
  FaderWidget(Node n, RawNode m, RawWidget w) : super(n, m, w);

  double value = 0.5;
  String? labelText;

  @override
  Widget build(BuildContext context) {
    Color color = Color(ffiFaderGetColor(widgetRaw.getTrait()));

    return LayoutBuilder(
      builder: (context, constraints) {
        double value = ffiFaderGetValue(widgetRaw.getTrait());

        return GestureDetector(
          onTapDown: (e) {
            setState(() {
              double newValue =
                  1 - (e.localPosition.dy / constraints.maxHeight);
              ffiFaderSetValue(widgetRaw.getTrait(), newValue.clamp(0.0, 1.0));
            });
          },
          onPanUpdate: (e) {
            setState(() {
              double newValue =
                  1 - (e.localPosition.dy / constraints.maxHeight);
              ffiFaderSetValue(widgetRaw.getTrait(), newValue.clamp(0.0, 1.0));
            });
          },
          child: Container(
            width: constraints.maxWidth,
            height: constraints.maxHeight,
            alignment: Alignment.bottomCenter,
            child: Container(
              width: constraints.maxWidth,
              height: max(constraints.maxHeight * value, 0.1),
              decoration: BoxDecoration(
                color: color,
                borderRadius: const BorderRadius.all(
                  Radius.circular(3),
                ),
              ),
            ),
            decoration: BoxDecoration(
              border: Border.all(
                width: 2.0,
                color: const Color.fromRGBO(50, 50, 50, 1.0),
              ),
              borderRadius: const BorderRadius.all(
                Radius.circular(5),
              ),
            ),
          ),
        );
      },
    );
  }
}
