import 'package:flutter/material.dart';
import 'package:ffi/ffi.dart';
import 'package:flutter/services.dart';
import 'dart:ffi';
import '../host.dart';
import 'widget.dart';
import '../common.dart';

void Function(FFIWidgetTrait, Pointer<Utf8>) ffiSearchableDropdownOnSelect = core
    .lookup<NativeFunction<Void Function(FFIWidgetTrait, Pointer<Utf8>)>>(
        "ffi_searchable_dropdown_on_select")
    .asFunction();

class SearchableDropdownWidget extends ModuleWidget {
  SearchableDropdownWidget(Host h, FFINode m, FFIWidget w) : super(h, m, w) {
    /*int widgetCount = ffiDropdownGetElementCount(widgetRaw.pointer);
    for (int i = 0; i < widgetCount; i++) {
      Pointer<Utf8> nameRaw = ffiDropdownGetElement(widgetRaw.pointer, i);
      String name = nameRaw.toDartString();
      calloc.free(nameRaw);

      elements.add(name);
    }*/
  }

  void handler(String name) async {
    var rawName = name.toNativeUtf8();
    ffiSearchableDropdownOnSelect(widgetRaw.getTrait(), rawName);
    calloc.free(rawName);
  }

  @override
  Widget build(BuildContext context) {
    return SearchableDropdown(
      value: "Element 1",
      categories: [
        Category(
          name: "Category 1",
          elements: [
            CategoryElement("Element 1"),
            CategoryElement("Element 2"),
            CategoryElement("Element 3"),
            CategoryElement("Element 4"),
          ]
        ),
        Category(
          name: "Category 2",
          elements: [
            CategoryElement("Element 5"),
            CategoryElement("Element 6"),
            CategoryElement("Element 7"),
            CategoryElement("Element 8"),
          ]
        )
      ],
      onSelect: (element) {
        print("Selected " + element.toString());

        if (element != null) {
          handler(element);
        }
      },
    );
  }
}
