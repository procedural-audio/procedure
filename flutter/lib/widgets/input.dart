import 'package:ffi/ffi.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'widget.dart';
import 'dart:io';
import 'dart:ffi';

import '../main.dart';
import '../host.dart';

Pointer<Utf8> Function(FFIWidgetTrait) ffiInputGetValue = core
    .lookup<NativeFunction<Pointer<Utf8> Function(FFIWidgetTrait)>>(
        "ffi_input_get_value")
    .asFunction();

Pointer<Utf8> Function(FFIWidgetTrait, Pointer<Utf8>) ffiInputSetValue = core
    .lookup<
        NativeFunction<
            Pointer<Utf8> Function(
                FFIWidgetTrait, Pointer<Utf8>)>>("ffi_input_set_value")
    .asFunction();

class InputWidget extends ModuleWidget {
  InputWidget(Host h, FFINode m, FFIWidget w) : super(h, m, w);

  TextEditingController controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    print("BUILD INPUT WIDGET");

    var temp = ffiInputGetValue(widgetRaw.getTrait());
    String value = temp.toDartString();
    calloc.free(temp);

    controller.text = value;

    return TextField(
      controller: controller,
      onChanged: (String v) {
        var temp = v.toNativeUtf8();
        var error = ffiInputSetValue(widgetRaw.getTrait(), temp);
        calloc.free(temp);

        if (error != nullptr) {
          print("Error: " + error.toDartString());
          calloc.free(error);
        }
      },
      cursorColor: Colors.grey,
      style: const TextStyle(color: Colors.red, fontSize: 16),
      decoration: const InputDecoration(
        filled: true,
        border: OutlineInputBorder(),
        contentPadding: EdgeInsets.all(5.0),
        fillColor: Color.fromRGBO(20, 20, 20, 1.0),
        focusColor: Colors.red,
        iconColor: Colors.red,
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(
            color: Color.fromRGBO(60, 60, 60, 1.0),
            width: 2.0
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(
            color: Colors.red,
            width: 2.0
          )
        )
      )
    );
  }
}