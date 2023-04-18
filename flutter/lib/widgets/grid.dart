import 'package:flutter/material.dart';

import 'dart:ffi';

import 'widget.dart';

import '../core.dart';
import '../module.dart';

int Function(RawWidgetPointer) ffiGridGetColumns = core
    .lookup<NativeFunction<Int64 Function(RawWidgetPointer)>>(
        "ffi_grid_get_columns")
    .asFunction();

class GridWidget extends ModuleWidget {
  GridWidget(RawNode m, RawWidget w) : super(m, w);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SizedBox(
          width: constraints.maxWidth,
          height: constraints.maxHeight,
          child: GridView.count(
            crossAxisCount: ffiGridGetColumns(widgetRaw.pointer),
            childAspectRatio: constraints.maxHeight / constraints.maxWidth,
            children: children,
          ),
        );
      },
    );
  }
}

/* ========== Grid Builfer ========== */

int Function(RawWidgetTrait) ffiGridBuilderGetCount = core
    .lookup<NativeFunction<Int64 Function(RawWidgetTrait)>>(
        "ffi_grid_builder_trait_get_count")
    .asFunction();
int Function(RawWidgetTrait) ffiGridBuilderGetColumns = core
    .lookup<NativeFunction<Int64 Function(RawWidgetTrait)>>(
        "ffi_grid_builder_trait_get_columns")
    .asFunction();
RawWidget Function(RawWidgetTrait, int) ffiGridBuilderCreateChild = core
    .lookup<NativeFunction<RawWidget Function(RawWidgetTrait, Int64)>>(
        "ffi_grid_builder_trait_create_child")
    .asFunction();
void Function(RawWidget) ffiGridBuilderDestroyChild = core
    .lookup<NativeFunction<Void Function(RawWidget)>>(
        "ffi_grid_builder_trait_destroy_child")
    .asFunction();

class GridBuilderWidget extends ModuleWidget {
  GridBuilderWidget(RawNode m, RawWidget w) : super(m, w);

  List<ModuleWidget> childWidgets = [];

  @override
  void initState() {
    var trait = widgetRaw.getTrait();

    int count = ffiGridBuilderGetCount(trait);

    for (int i = 0; i < count; i++) {
      var widget = createWidget(
        moduleRaw,
        ffiGridBuilderCreateChild(widgetRaw.getTrait(), i),
      );

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

    return LayoutBuilder(
      builder: (context, constraints) {
        return GridView.count(
          crossAxisCount: columns,
          childAspectRatio: (constraints.maxWidth / columns) /
              (constraints.maxHeight / (childWidgets.length / columns)),
          children: childWidgets,
        );
      },
    );
  }
}
