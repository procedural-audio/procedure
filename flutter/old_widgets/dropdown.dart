import 'package:flutter/material.dart';
import 'package:ffi/ffi.dart';
import 'dart:ffi';
import 'widget.dart';
import '../core.dart';
import '../module/node.dart';

int Function(RawWidgetPointer) ffiDropdownGetColor = core
    .lookup<NativeFunction<Int32 Function(RawWidgetPointer)>>(
        "ffi_dropdown_get_color")
    .asFunction();
int Function(RawWidgetPointer) ffiDropdownGetElementCount = core
    .lookup<NativeFunction<Int64 Function(RawWidgetPointer)>>(
        "ffi_dropdown_get_element_count")
    .asFunction();
Pointer<Utf8> Function(RawWidgetPointer, int) ffiDropdownGetElement = core
    .lookup<NativeFunction<Pointer<Utf8> Function(RawWidgetPointer, Int64)>>(
        "ffi_dropdown_get_element")
    .asFunction();
int Function(RawWidgetPointer) ffiDropdownGetIndex = core
    .lookup<NativeFunction<Int64 Function(RawWidgetPointer)>>(
        "ffi_dropdown_get_index")
    .asFunction();
void Function(RawWidgetPointer, int) ffiDropdownSetIndex = core
    .lookup<NativeFunction<Void Function(RawWidgetPointer, Int64)>>(
        "ffi_dropdown_set_index")
    .asFunction();

class DropdownWidget extends ModuleWidget {
  DropdownWidget(Node n, RawNode m, RawWidget w) : super(n, m, w) {
    int widgetCount = ffiDropdownGetElementCount(widgetRaw.pointer);
    for (int i = 0; i < widgetCount; i++) {
      Pointer<Utf8> nameRaw = ffiDropdownGetElement(widgetRaw.pointer, i);
      String name = nameRaw.toDartString();
      calloc.free(nameRaw);

      elements.add(name);
    }

    color = intToColor(ffiDropdownGetColor(widgetRaw.pointer));
  }

  List<String> elements = [];
  late Color color;

  @override
  Widget build(BuildContext context) {
    String value = "";

    if (elements.isNotEmpty) {
      value = elements[ffiDropdownGetIndex(widgetRaw.pointer)];
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(10, 5, 5, 5),
      decoration: BoxDecoration(
          border: Border.all(
              color: const Color.fromRGBO(60, 60, 60, 1.0), width: 1.0),
          color: const Color.fromRGBO(30, 30, 30, 1.0),
          borderRadius: BorderRadius.circular(5)),
      child: DropdownButton<String>(
        value: value,
        isExpanded: true,
        items: elements
            .map((String e) => DropdownMenuItem(
                value: e,
                child: Text(
                  e,
                  style: TextStyle(color: color, fontSize: 14),
                )))
            .toList(),
        onChanged: (v) {
          if (v != null) {
            for (int i = 0; i < elements.length; i++) {
              if (v == elements[i]) {
                ffiDropdownSetIndex(widgetRaw.pointer, i);
                setState(() {});
              }
            }
          }
        },
        isDense: true,
        icon: Icon(Icons.arrow_drop_down, color: color),
        dropdownColor: const Color.fromRGBO(20, 20, 20, 1.0),
        iconSize: 20,
        underline: const SizedBox(),
      ),
    );

    /*return Container(
      color: const Color.fromRGBO(60, 60, 60, 1.0),
      child: Dropdown(
          value: value,
          items: elements,
          onChanged: (index) {
            ffiDropdownOnChanged(widgetRaw.pointer, index);
          },
          color: color),
    );*/
  }
}
