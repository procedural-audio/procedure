import 'package:flutter/material.dart';

import '../host.dart';
import 'widget.dart';
import 'dart:ffi';
import '../core.dart';
import '../module.dart';

bool Function(FFIWidgetTrait) ffiRefreshGetShouldRefresh = core
    .lookup<NativeFunction<Bool Function(FFIWidgetTrait)>>(
        "ffi_refresh_get_should_refresh")
    .asFunction();

void Function(FFIWidgetTrait, bool) ffiRefreshSetShouldRefresh = core
    .lookup<NativeFunction<Void Function(FFIWidgetTrait, Bool)>>(
        "ffi_refresh_set_should_refresh")
    .asFunction();

class RefreshWidget extends ModuleWidget {
  RefreshWidget(Host h, RawNode m, FFIWidget w) : super(h, m, w);

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

bool Function(FFIWidgetTrait) ffiRebuildGetShouldRefresh = core
    .lookup<NativeFunction<Bool Function(FFIWidgetTrait)>>(
        "ffi_rebuild_get_should_refresh")
    .asFunction();

void Function(FFIWidgetTrait, bool) ffiRebuildSetShouldRefresh = core
    .lookup<NativeFunction<Void Function(FFIWidgetTrait, Bool)>>(
        "ffi_rebuild_set_should_refresh")
    .asFunction();

class RebuildWidget extends ModuleWidget {
  RebuildWidget(Host h, RawNode m, FFIWidget w) : super(h, m, w);

  void rebuildCallback() {
    var newChild = RebuildWidget(host, moduleRaw, widgetRaw);
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
}

int Function(FFIWidgetPointer) ffiIndicatorGetColor = core
    .lookup<NativeFunction<Int32 Function(FFIWidgetPointer)>>(
        "ffi_indicator_get_color")
    .asFunction();

class IndicatorWidget extends ModuleWidget {
  IndicatorWidget(Host h, RawNode m, FFIWidget w) : super(h, m, w);

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
