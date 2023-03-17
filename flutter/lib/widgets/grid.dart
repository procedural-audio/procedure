import 'package:flutter/material.dart';

import 'widget.dart';
import 'dart:io';
import 'dart:ffi';
import '../host.dart';

import 'package:ffi/ffi.dart';

import '../main.dart';
import '../core.dart';
import '../module.dart';

int Function(FFIWidgetPointer) ffiGridGetColumns = core
    .lookup<NativeFunction<Int64 Function(FFIWidgetPointer)>>(
        "ffi_grid_get_columns")
    .asFunction();

class GridWidget extends ModuleWidget {
  GridWidget(Host h, RawNode m, FFIWidget w) : super(h, m, w);

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: ffiGridGetColumns(widgetRaw.pointer),
      children: children,
    );
  }
}

/* ========== Grid Builfer ========== */

int Function(FFIWidgetTrait) ffiGridBuilderGetCount = core
    .lookup<NativeFunction<Int64 Function(FFIWidgetTrait)>>(
        "ffi_grid_builder_trait_get_count")
    .asFunction();
int Function(FFIWidgetTrait) ffiGridBuilderGetColumns = core
    .lookup<NativeFunction<Int64 Function(FFIWidgetTrait)>>(
        "ffi_grid_builder_trait_get_columns")
    .asFunction();
FFIWidget Function(FFIWidgetTrait, int) ffiGridBuilderCreateChild = core
    .lookup<NativeFunction<FFIWidget Function(FFIWidgetTrait, Int64)>>(
        "ffi_grid_builder_trait_create_child")
    .asFunction();
void Function(FFIWidget) ffiGridBuilderDestroyChild = core
    .lookup<NativeFunction<Void Function(FFIWidget)>>(
        "ffi_grid_builder_trait_destroy_child")
    .asFunction();

class GridBuilderWidget extends ModuleWidget {
  GridBuilderWidget(Host h, RawNode m, FFIWidget w) : super(h, m, w);

  List<ModuleWidget> childWidgets = [];

  @override
  void initState() {
    print("New gridbuilder state");
    var trait = widgetRaw.getTrait();

    int count = ffiGridBuilderGetCount(trait);

    for (int i = 0; i < count; i++) {
      var widget = createWidget(host,
          moduleRaw, ffiGridBuilderCreateChild(widgetRaw.getTrait(), i));

      if (widget != null) {
        childWidgets.add(widget);
      }
    }
  }

  @override
  void refreshRecursive() {
    state.refresh();
    for (var child in childWidgets) {
      child.refreshRecursive();
    }
  }

  @override
  void dispose() {
    // CHECK IF THIS DISPOSE GETS CALLED AND WORKS
    while (childWidgets.isNotEmpty) {
      ffiGridBuilderDestroyChild(childWidgets.removeLast().widgetRaw);
    }
  }

  @override
  Widget build(BuildContext context) {
    var trait = widgetRaw.getTrait();
    int columns = ffiGridBuilderGetColumns(trait);

    return LayoutBuilder(builder: (context, constraints) {
      return GridView.count(
          crossAxisCount: columns,
          childAspectRatio: (constraints.maxWidth / columns) /
              (constraints.maxHeight / (childWidgets.length / columns)),
          children: childWidgets);
    });
  }
}
