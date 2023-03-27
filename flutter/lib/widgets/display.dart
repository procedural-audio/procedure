import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'widget.dart';
import 'dart:io';
import 'dart:ffi';
import '../patch.dart';

import 'package:ffi/ffi.dart';

import '../main.dart';
import '../core.dart';
import '../module.dart';

Pointer<Utf8> Function(RawWidgetTrait) ffiDisplayGetText = core
    .lookup<NativeFunction<Pointer<Utf8> Function(RawWidgetTrait)>>(
        "ffi_display_get_text")
    .asFunction();

class DisplayWidget extends ModuleWidget {
  DisplayWidget(RawNode m, RawWidget w) : super(m, w);

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
            borderRadius: BorderRadius.circular(5)),
        child: ValueListenableBuilder<String>(
          valueListenable: text,
          builder: (context, text, child) {
            return Text(
              text,
              textAlign: TextAlign.right,
              style: const TextStyle(fontSize: 16, color: Colors.red),
            );
          },
        ));
  }
}
