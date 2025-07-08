import 'package:flutter/material.dart';
import '../patch/patch.dart';
import 'widget.dart';
import 'dart:ffi';
import 'dart:ui' as ui;
import '../core.dart';
import '../module/node.dart';
import '../main.dart';

RawWidget Function(RawWidgetTrait, int) ffiTabsGetTabChild = core
    .lookup<NativeFunction<RawWidget Function(RawWidgetTrait, Int64)>>(
        "ffi_tabs_get_tab_child")
    .asFunction();

int Function(RawWidgetTrait) ffiTabsGetTabCount = core
    .lookup<NativeFunction<Int64 Function(RawWidgetTrait)>>(
        "ffi_tabs_get_tab_count")
    .asFunction();

class TabsWidget extends ModuleWidget {
  TabsWidget(Node n, RawNode m, RawWidget w) : super(n, m, w) {
    int count = ffiTabsGetTabCount(w.getTrait());

    for (int i = 0; i < count; i++) {
      ModuleWidget? widget = createWidget(
        node,
        m,
        ffiTabsGetTabChild(w.getTrait(), i),
      );

      if (widget != null) {
        widgets.add(widget);

        icons.add(
          const SizedBox(
            height: 30,
            child: Tab(icon: Icon(Icons.piano, size: 20)),
          ),
        );
      }
    }
  }

  bool hovering = false;
  bool clicking = false;

  List<ModuleWidget> widgets = [];
  List<Widget> icons = [];

  @override
  Widget createEditor(BuildContext context) {
    return Container();
  }

  @override
  void tick() {
    super.tick();
    for (var child in widgets) {
      child.tick();
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      initialIndex: 0,
      length: widgets.length,
      child: Scaffold(
        backgroundColor: const Color.fromRGBO(30, 30, 30, 1.0),
        appBar: AppBar(
          toolbarHeight: 0,
          foregroundColor: Colors.red,
          backgroundColor: const Color.fromRGBO(50, 50, 50, 1.0),
          bottom: PreferredSize(
            preferredSize: const ui.Size(200, 32),
            child: Container(
              child: TabBar(
                isScrollable: false,
                indicatorSize: TabBarIndicatorSize.label,
                tabs: icons,
              ),
            ),
          ),
        ),
        body: TabBarView(
            physics: const NeverScrollableScrollPhysics(), children: widgets),
      ),
    );
  }
}
