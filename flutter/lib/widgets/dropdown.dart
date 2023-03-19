import 'package:flutter/material.dart';
import 'package:ffi/ffi.dart';
import 'dart:ffi';
import '../host.dart';
import 'widget.dart';
import '../core.dart';
import '../module.dart';
import '../main.dart';

int Function(FFIWidgetPointer) ffiDropdownGetColor = core
    .lookup<NativeFunction<Int32 Function(FFIWidgetPointer)>>(
        "ffi_dropdown_get_color")
    .asFunction();
int Function(FFIWidgetPointer) ffiDropdownGetElementCount = core
    .lookup<NativeFunction<Int64 Function(FFIWidgetPointer)>>(
        "ffi_dropdown_get_element_count")
    .asFunction();
Pointer<Utf8> Function(FFIWidgetPointer, int) ffiDropdownGetElement = core
    .lookup<NativeFunction<Pointer<Utf8> Function(FFIWidgetPointer, Int64)>>(
        "ffi_dropdown_get_element")
    .asFunction();
int Function(FFIWidgetPointer) ffiDropdownGetIndex = core
    .lookup<NativeFunction<Int64 Function(FFIWidgetPointer)>>(
        "ffi_dropdown_get_index")
    .asFunction();
void Function(FFIWidgetPointer, int) ffiDropdownSetIndex = core
    .lookup<NativeFunction<Void Function(FFIWidgetPointer, Int64)>>(
        "ffi_dropdown_set_index")
    .asFunction();

class DropdownWidget extends ModuleWidget {
  DropdownWidget(App a, RawNode m, FFIWidget w) : super(a, m, w) {
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
            print("v not null");
            for (int i = 0; i < elements.length; i++) {
              if (v == elements[i]) {
                ffiDropdownSetIndex(widgetRaw.pointer, i);
                setState(() {});
              }
            }
          } else {
            print("v is null");
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

class Dropdown extends StatefulWidget {
  Dropdown(
      {required this.value,
      required this.items,
      required this.onChanged,
      required this.color,
      Key? key})
      : super(key: key);

  List<String> items;
  String value;
  void Function(int) onChanged;
  final Color color;

  @override
  State<Dropdown> createState() =>
      _DropdownState(value: value, items: items, onChanged: onChanged);
}

class _DropdownState extends State<Dropdown> {
  List<String> items;
  String value;
  void Function(int) onChanged;

  _DropdownState(
      {required this.value, required this.items, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return ButtonTheme(
      padding: const EdgeInsets.all(0),
      layoutBehavior: ButtonBarLayoutBehavior.constrained,
      child: DropdownButton<String>(
        value: value,
        iconEnabledColor: widget.color,
        iconDisabledColor: const Color.fromRGBO(30, 30, 30, 1.0),
        focusColor: const Color.fromRGBO(40, 40, 40, 1.0),
        icon: const Icon(
          Icons.keyboard_arrow_down,
        ),
        elevation: 14,
        style: TextStyle(
          color: widget.color,
          fontSize: 14,
        ),
        dropdownColor: const Color.fromRGBO(30, 30, 30, 1.0),
        iconSize: 14,
        itemHeight: 48,
        underline: Container(
          height: 1,
          color: widget.color,
        ),
        onChanged: (String? newValue) {
          int i = 0;

          for (var item in items) {
            if (item == newValue!) {
              onChanged(i);
            }

            i++;
          }

          setState(() {
            value = newValue!;
          });
        },
        isDense: false,
        items: items.map<DropdownMenuItem<String>>((String value) {
          return DropdownMenuItem<String>(
            value: value,
            child: Text(
              value,
              style: TextStyle(
                color: widget.color,
                fontSize: 14,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
