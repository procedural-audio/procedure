import 'package:flutter/material.dart';

import 'dart:ffi';

import 'widget.dart';

import '../core.dart';
import '../module.dart';

bool Function(RawWidgetTrait) ffiRefreshGetShouldRefresh = core
    .lookup<NativeFunction<Bool Function(RawWidgetTrait)>>(
        "ffi_refresh_get_should_refresh")
    .asFunction();

void Function(RawWidgetTrait, bool) ffiRefreshSetShouldRefresh = core
    .lookup<NativeFunction<Void Function(RawWidgetTrait, Bool)>>(
        "ffi_refresh_set_should_refresh")
    .asFunction();

class RefreshWidget extends ModuleWidget {
  RefreshWidget(RawNode m, RawWidget w) : super(m, w);

  void refreshCallback() {
    children[0].refreshRecursive();
  }

  @override
  void tick() {
    if (ffiRefreshGetShouldRefresh(widgetRaw.getTrait())) {
      ffiRefreshSetShouldRefresh(widgetRaw.getTrait(), false);
      refreshCallback();
    }
  }

  @override
  Widget build(BuildContext context) {
    return children[0];
  }
}

/*bool Function(RawWidgetTrait) ffiRebuildGetShouldRefresh = core
    .lookup<NativeFunction<Bool Function(RawWidgetTrait)>>(
        "ffi_rebuild_get_should_refresh")
    .asFunction();

void Function(RawWidgetTrait, bool) ffiRebuildSetShouldRefresh = core
    .lookup<NativeFunction<Void Function(RawWidgetTrait, Bool)>>(
        "ffi_rebuild_set_should_refresh")
    .asFunction();

class RebuildWidget extends ModuleWidget {
  RebuildWidget(RawNode m, RawWidget w) : super(m, w);

  void rebuildCallback() {
    var newChild = RebuildWidget(moduleRaw, widgetRaw);
    children[0] = newChild.children[0];
    refresh();
  }

  @override
  void tick() {
    if (ffiRebuildGetShouldRefresh(widgetRaw.getTrait())) {
      ffiRebuildSetShouldRefresh(widgetRaw.getTrait(), false);
      rebuildCallback();
    }
  }

  @override
  Widget build(BuildContext context) {
    return children[0];
  }
}*/

int Function(RawWidgetPointer) ffiIndicatorGetColor = core
    .lookup<NativeFunction<Int32 Function(RawWidgetPointer)>>(
        "ffi_indicator_get_color")
    .asFunction();

class IndicatorWidget extends ModuleWidget {
  IndicatorWidget(RawNode m, RawWidget w) : super(m, w);

  @override
  Widget build(BuildContext context) {
    var color = Color(ffiIndicatorGetColor(widgetRaw.pointer));

    return Container(
      decoration: BoxDecoration(
          color: color,
          borderRadius: const BorderRadius.all(Radius.circular(3))),
    );
  }
}
