import 'package:flutter/material.dart';
import 'package:metasampler/ui/common.dart';
import 'package:metasampler/ui/ui.dart';

import 'host.dart';
import 'ui/layout.dart';
import 'main.dart';

class InstrumentView extends StatefulWidget {
  InstrumentView(this.host) {
    tree = UITree(host);
  }

  Host host;
  late UITree tree;

  @override
  State<InstrumentView> createState() => _InstrumentView();
}

class _InstrumentView extends State<InstrumentView> {
  // ValueNotifier<Widget Function(BuildContext)?> editorBuilder = ValueNotifier(null);
  // File file = File("/home/chase/github/metasampler/content/temp.ui");

  late Widget display;

  @override
  void initState() {
    display = UIDisplay(widget.tree, widget.host);

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
        valueListenable: widget.tree.editing,
        builder: (context, editing, child) {
          if (editing) {
            return Container(
                color: Colors.black,
                child: Row(mainAxisSize: MainAxisSize.max, children: [
                  WidgetMenu(),
                  Expanded(
                    child: Container(
                      alignment: Alignment.center,
                      color: Colors.black,
                      child: display,
                    ),
                  ),
                  Column(
                    children: [
                      Expanded(child: WidgetTreeMenu(widget.tree, widget.host)),
                      Expanded(
                        child: WidgetEditorMenu(widget.tree),
                      ),
                    ],
                  )
                ]));
          } else {
            return Container(
              alignment: Alignment.center,
              color: Colors.black,
              child: display,
            );
          }
        });
  }
}

class UIDisplay extends StatefulWidget {
  UIDisplay(this.tree, this.host);

  UITree tree;
  Host host;

  @override
  State<UIDisplay> createState() => _UIDisplay();
}

class _UIDisplay extends State<UIDisplay> {
  final ScrollController horizontal = ScrollController();
  final ScrollController vertical = ScrollController();

  @override
  Widget build(BuildContext context) {
    widget.host.globals.rootWidget ??= RootWidget(widget.host, widget.tree);

    return LayoutBuilder(builder: (context, constraints) {
      return Scrollbar(
          controller: vertical,
          thumbVisibility: true,
          trackVisibility: true,
          child: Scrollbar(
              controller: horizontal,
              thumbVisibility: true,
              trackVisibility: true,
              notificationPredicate: (notif) => notif.depth == 1,
              child: SingleChildScrollView(
                  controller: vertical,
                  child: SingleChildScrollView(
                      controller: horizontal,
                      scrollDirection: Axis.horizontal,
                      child: Container(
                        width: 1000,
                        height: 1000,
                        alignment: Alignment.center,
                        color: Colors.grey,
                        child: widget.host.globals.rootWidget,
                      )))));
    });
  }
}

class WidgetTreeMenu extends StatefulWidget {
  WidgetTreeMenu(this.tree, this.host);

  UITree tree;
  Host host;

  @override
  State<WidgetTreeMenu> createState() => _WidgetTreeMenu();
}

class _WidgetTreeMenu extends State<WidgetTreeMenu> {
  ScrollController controller = ScrollController();

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
        valueListenable: widget.tree.editing,
        builder: (context, value, child) {
          return ValueListenableBuilder(
              valueListenable: widget.tree.selected,
              builder: (context, selectedWidget, child) {
                return Container(
                    width: 300,
                    padding: const EdgeInsets.all(10),
                    color: const Color.fromRGBO(30, 30, 30, 1.0),
                    child: ListTileTheme(
                        dense: true,
                        child: Column(children: [
                          EditorTitle("Widget Tree"),
                          Expanded(
                              child: SingleChildScrollView(
                                  controller: controller,
                                  child: widget.host.globals.rootWidget != null
                                      ? WidgetTreeElement(
                                          widget:
                                              widget.host.globals.rootWidget!,
                                          tree: widget.tree)
                                      : Container()))
                        ])));
              });
        });
  }
}

class WidgetTreeElement extends StatelessWidget {
  WidgetTreeElement({required this.widget, required this.tree});

  UIWidget widget;
  UITree tree;

  @override
  Widget build(BuildContext context) {
    List<UIWidget> children = [];

    for (var child in widget.getChildren()) {
      if (child.name != "Empty") {
        children.add(child);
      }
    }

    return Padding(
        padding: const EdgeInsets.fromLTRB(0, 0, 0, 5),
        child: ExpansionTile(
          maintainState: true,
          initiallyExpanded: true,
          textColor: widget == tree.selected.value ? Colors.blue : Colors.white,
          collapsedTextColor:
              widget == tree.selected.value ? Colors.blue : Colors.grey,
          iconColor: Colors.grey,
          collapsedIconColor: Colors.grey,
          backgroundColor: const Color.fromRGBO(20, 20, 20, 1.0),
          collapsedBackgroundColor: const Color.fromRGBO(30, 30, 30, 1.0),
          tilePadding: const EdgeInsets.fromLTRB(15, 0, 10, 0),
          shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(10))),
          collapsedShape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(10))),
          onExpansionChanged: (v) {
            tree.selected.value = widget;
          },
          title: Row(children: [
            Text(
              widget.name,
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
            widget.name == "Empty" || widget.name == "Root"
                ? Container()
                : IconButton(
                    icon: const Icon(
                      Icons.delete,
                      color: Colors.grey,
                      size: 14,
                    ),
                    onPressed: () {
                      tree.deleteChild(widget);
                    },
                  )
          ]),
          children: [
            Padding(
                padding: const EdgeInsets.fromLTRB(10, 0, 0, 0),
                child: Column(
                    children: children.map((child) {
                  return WidgetTreeElement(
                    widget: child,
                    tree: tree,
                  );
                }).toList()))
          ],
        ));
  }
}

class WidgetEditorMenu extends StatefulWidget {
  WidgetEditorMenu(this.tree);

  UITree tree;

  @override
  State<WidgetEditorMenu> createState() => _WidgetEditorMenu();
}

class _WidgetEditorMenu extends State<WidgetEditorMenu> {
  ScrollController controller = ScrollController();

  @override
  Widget build(BuildContext context) {
    return Container(
        width: 300,
        color: const Color.fromRGBO(30, 30, 30, 1.0),
        child: ValueListenableBuilder<UIWidget?>(
            valueListenable: widget.tree.selected,
            builder: (context, selectedWidget, child) {
              if (selectedWidget == null) {
                return Container();
              } else {
                return SingleChildScrollView(
                    controller: controller,
                    child: ValueListenableBuilder<int>(
                        valueListenable: selectedWidget.notifier,
                        builder: (context, i, child) {
                          return selectedWidget.buildWidgetEditor(context);
                        }));
              }
            }));
  }
}

class WidgetMenu extends StatefulWidget {
  @override
  State<WidgetMenu> createState() => _WidgetMenu();
}

class _WidgetMenu extends State<WidgetMenu> {
  ScrollController controller = ScrollController();

  @override
  Widget build(BuildContext context) {
    return Container(
        width: 300,
        color: const Color.fromRGBO(30, 30, 30, 1.0),
        padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
        child: Column(children: [
          EditorTitle("Widgets"),
          Expanded(
              child: SingleChildScrollView(
                  controller: controller,
                  child: Column(children: [
                    WidgetMenuSection(title: "Layout", children: [
                      WidgetMenuElement("Stack", Icons.stacked_bar_chart),
                      WidgetMenuElement("Row", Icons.table_rows),
                      WidgetMenuElement("Column", Icons.table_rows),
                      WidgetMenuElement("Grid", Icons.grid_4x4),
                    ]),
                    WidgetMenuSection(title: "Decoration", children: [
                      WidgetMenuElement("Box", Icons.add_box),
                      WidgetMenuElement("Text", Icons.text_fields),
                      WidgetMenuElement("Image", Icons.image),
                      WidgetMenuElement("Icon", Icons.picture_as_pdf),
                      // WidgetMenuElement("Polygon", Icons.picture_as_pdf),
                      // WidgetMenuElement("Square", Icons.picture_as_pdf),
                      // WidgetMenuElement("Line", Icons.picture_as_pdf),
                    ]),
                    WidgetMenuSection(title: "Interactive", children: [
                      WidgetMenuElement("Web View", Icons.window),
                      WidgetMenuElement("Dropdown", Icons.list),
                      WidgetMenuElement("Knob", Icons.king_bed_outlined),
                      WidgetMenuElement("Slider", Icons.slideshow_rounded),
                      WidgetMenuElement("Button", Icons.radio_button_checked),
                      WidgetMenuElement("Envelope", Icons.graphic_eq),
                      // WidgetMenuElement("Mod Source", Icons.graphic_eq),
                    ]),
                    WidgetMenuSection(title: "Metering", children: [
                      WidgetMenuElement("RMS", Icons.king_bed_outlined),
                      WidgetMenuElement("Spectrum", Icons.slideshow_rounded),
                      WidgetMenuElement(
                          "Oscilliscope", Icons.radio_button_checked),
                      WidgetMenuElement("Meter", Icons.padding),
                    ])
                  ])))
        ]));
  }
}

class WidgetMenuSection extends StatelessWidget {
  WidgetMenuSection({required this.title, required this.children});

  String title;
  List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Section(
        title: title,
        child: GridView.count(
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          crossAxisCount: 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: children,
        ));
  }
}

class WidgetMenuElement extends StatefulWidget {
  WidgetMenuElement(this.text, this.iconData);

  String text;
  IconData iconData;

  @override
  State<WidgetMenuElement> createState() => _WidgetMenuElement();
}

class _WidgetMenuElement extends State<WidgetMenuElement> {
  bool hovering = false;

  @override
  Widget build(BuildContext context) {
    var icon = Container(
        width: 80,
        height: 80,
        alignment: Alignment.center,
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(5.0),
            border: Border.all(
                color: hovering
                    ? Colors.blue
                    : const Color.fromRGBO(60, 60, 60, 1.0),
                width: 2.0)),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(
            widget.iconData,
            size: 32,
            color: hovering ? Colors.blue : Colors.grey,
          ),
          Container(
              height: 20,
              alignment: Alignment.bottomCenter,
              child: Text(widget.text,
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      fontFamily: DefaultTextStyle.of(context).style.fontFamily,
                      decoration: TextDecoration.none,
                      color: hovering ? Colors.blue : Colors.grey)))
        ]));

    return MouseRegion(
        onEnter: (e) => setState(() {
              hovering = true;
            }),
        onExit: (e) => setState(() {
              hovering = false;
            }),
        child: GestureDetector(
            onTap: () {
              print("Clicked " + widget.text);
            },
            child: Draggable<String>(
              feedback: icon,
              child: icon,
              data: widget.text,
            )));
  }
}
