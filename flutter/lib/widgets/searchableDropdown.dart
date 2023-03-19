import 'package:flutter/material.dart';
import 'package:ffi/ffi.dart';
import 'package:flutter/services.dart';
import 'dart:ffi';
import '../host.dart';
import 'widget.dart';
import '../common.dart';
import '../core.dart';
import '../module.dart';
import '../main.dart';

void Function(FFIWidgetTrait, Pointer<Utf8>) ffiSearchableDropdownOnSelect =
    core
        .lookup<NativeFunction<Void Function(FFIWidgetTrait, Pointer<Utf8>)>>(
            "ffi_searchable_dropdown_on_select")
        .asFunction();

class SearchableDropdownWidget extends ModuleWidget {
  SearchableDropdownWidget(App a, RawNode m, FFIWidget w) : super(a, m, w) {
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
      width: 150,
      height: 30,
      titleStyle: const TextStyle(
          color: Color.fromRGBO(200, 200, 200, 1.0), fontSize: 14),
      value: "Element 1",
      categories: [
        Category(name: "Valhalla", elements: [
          CategoryElement("ValhallaRoom"),
          CategoryElement("ValhallaDelay"),
          CategoryElement("ValhallaShimmer"),
        ]),
        Category(name: "u-he", elements: [
          CategoryElement("Diva"),
          CategoryElement("Zebra2"),
          CategoryElement("Repro-1"),
        ]),
        Category(name: "Other", elements: [
          CategoryElement("Kontakt"),
          CategoryElement("Keyscape"),
          CategoryElement("Omnisphere"),
          CategoryElement("Vital"),
        ])
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
