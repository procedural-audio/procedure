import 'package:flutter/material.dart';
import 'package:ffi/ffi.dart';

import 'dart:ffi';

import 'widget.dart';

import '../core.dart';
import '../module.dart';

Pointer<Utf8> Function(RawWidgetTrait) ffiDisplayGetText = core
    .lookup<NativeFunction<Pointer<Utf8> Function(RawWidgetTrait)>>(
        "ffi_display_get_text")
    .asFunction();

class DisplayWidget extends ModuleWidget {
  DisplayWidget(Node n, RawNode m, RawWidget w) : super(n, m, w);

  ValueNotifier<String> text = ValueNotifier("");

  @override
  void tick() {
    var temp = ffiDisplayGetText(widgetRaw.getTrait());
    if (temp.address != 0) {
      text.value = temp.toDartString();
      calloc.free(temp);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: const Color.fromRGBO(20, 20, 20, 1.0),
        borderRadius: BorderRadius.circular(5),
      ),
      child: ValueListenableBuilder<String>(
        valueListenable: text,
        builder: (context, text, child) {
          return Text(
            text,
            textAlign: TextAlign.right,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.red,
            ),
          );
        },
      ),
    );
  }
}
