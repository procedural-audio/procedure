import 'package:flutter/material.dart';
import 'package:procedure_ui/interface/common.dart';
import 'package:procedure_ui/interface/ui.dart';

class WidgetTreeElement extends StatelessWidget {
  WidgetTreeElement({super.key, required this.widget, required this.ui});

  UIWidget widget;
  // UITree tree;
  UserInterface ui;

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
        // subtitle: Icon(Icons.expand_more, size: 14),
        maintainState: true,
        initiallyExpanded: true,
        textColor: widget == ui.selected.value ? Colors.blue : Colors.white,
        collapsedTextColor:
            widget == ui.selected.value ? Colors.blue : Colors.grey,
        iconColor: Colors.grey,
        collapsedIconColor: Colors.grey,
        backgroundColor: const Color.fromRGBO(20, 20, 20, 1.0),
        collapsedBackgroundColor: const Color.fromRGBO(30, 30, 30, 1.0),
        tilePadding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(
            Radius.circular(5),
          ),
        ),
        collapsedShape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(
            Radius.circular(5),
          ),
        ),
        trailing: const Icon(
          Icons.arrow_drop_down,
          size: 20,
        ),
        onExpansionChanged: (v) {
          ui.selected.value = widget;
        },
        title: Row(
          children: [
            Text(
              widget.name,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
              ),
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
                      ui.deleteWidget(widget);
                    },
                  ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 0, 0, 0),
            child: Column(
              children: children.map(
                (child) {
                  return WidgetTreeElement(
                    widget: child,
                    ui: ui,
                  );
                },
              ).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class WidgetEditorMenu extends StatefulWidget {
  WidgetEditorMenu(this.ui, {super.key});

  UserInterface ui;

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
        valueListenable: widget.ui.selected,
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
                },
              ),
            );
          }
        },
      ),
    );
  }
}

class WidgetMenu extends StatefulWidget {
  const WidgetMenu({super.key});

  @override
  State<WidgetMenu> createState() => _WidgetMenu();
}

class _WidgetMenu extends State<WidgetMenu> {
  ScrollController controller = ScrollController();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 200,
      color: const Color.fromRGBO(30, 30, 30, 1.0),
      padding: const EdgeInsets.fromLTRB(5, 0, 5, 0),
      child: Column(
        children: [
          EditorTitle("Widgets"),
          Expanded(
            child: SingleChildScrollView(
              controller: controller,
              child: Column(
                children: [
                  WidgetMenuSection(
                    title: "Layout",
                    children: [
                      WidgetMenuElement("Stack", Icons.stacked_bar_chart),
                      WidgetMenuElement("Row", Icons.table_rows),
                      WidgetMenuElement("Column", Icons.table_rows),
                      WidgetMenuElement("Grid", Icons.grid_4x4),
                    ],
                  ),
                  WidgetMenuSection(
                    title: "Decoration",
                    children: [
                      WidgetMenuElement("Box", Icons.add_box),
                      WidgetMenuElement("Text", Icons.text_fields),
                      WidgetMenuElement("Image", Icons.image),
                      WidgetMenuElement("Icon", Icons.picture_as_pdf),
                      // WidgetMenuElement("Text Edit", Icons.text_fields),
                      // WidgetMenuElement("Line", Icons.add_box),
                    ],
                  ),
                  WidgetMenuSection(
                    title: "Interactive",
                    children: [
                      WidgetMenuElement("Knob", Icons.king_bed_outlined),
                      WidgetMenuElement("Slider", Icons.slideshow_rounded),
                      WidgetMenuElement("Button", Icons.radio_button_checked),
                      WidgetMenuElement("Dropdown", Icons.list),
                      WidgetMenuElement("Envelope", Icons.graphic_eq),
                    ],
                  ),
                  WidgetMenuSection(
                    title: "Metering",
                    children: [
                      WidgetMenuElement("RMS", Icons.king_bed_outlined),
                      WidgetMenuElement("Spectrum", Icons.slideshow_rounded),
                      WidgetMenuElement("Scope", Icons.radio_button_checked),
                      WidgetMenuElement("Meter", Icons.padding),
                    ],
                  ),
                  WidgetMenuSection(
                    title: "Other",
                    children: [
                      WidgetMenuElement("Web View", Icons.window),
                    ],
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class WidgetMenuSection extends StatelessWidget {
  WidgetMenuSection({super.key, required this.title, required this.children});

  String title;
  List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Section(
      title: title,
      child: GridView.count(
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        children: children,
      ),
    );
  }
}

class WidgetMenuElement extends StatefulWidget {
  WidgetMenuElement(this.text, this.iconData, {super.key});

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
          color: hovering ? Colors.blue : const Color.fromRGBO(60, 60, 60, 1.0),
          width: 2.0,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            widget.iconData,
            size: 24,
            color: hovering ? Colors.blue : Colors.grey,
          ),
          Container(
            height: 20,
            alignment: Alignment.bottomCenter,
            child: Text(
              widget.text,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                fontFamily: DefaultTextStyle.of(context).style.fontFamily,
                decoration: TextDecoration.none,
                color: hovering ? Colors.blue : Colors.grey,
              ),
            ),
          ),
        ],
      ),
    );

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
        ),
      ),
    );
  }
}
