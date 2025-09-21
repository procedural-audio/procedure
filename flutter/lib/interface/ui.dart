import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:procedure/interface/layout.dart';
import 'package:procedure/interface/tree.dart';

import '../preset/info.dart';
import 'decoration.dart';
import 'interactive.dart';

import '../preset/preset.dart';

class UserInterface extends StatelessWidget {
  UserInterface(this.info, {super.key});

  late final InterfaceRoot root = InterfaceRoot(this);
  final PresetInfo info;
  final ValueNotifier<UIWidget?> selected = ValueNotifier(null);
  final ValueNotifier<bool> editing = ValueNotifier(false);
  final ScrollController scrollController =
      ScrollController(initialScrollOffset: 202);

  static Future<UserInterface?> load(PresetInfo info) async {
    File file = File(info.directory.path + "/interface.json");
    if (await file.exists()) {
      var interface = UserInterface(info);
      var contents = await file.readAsString();
      print("Loaded " + contents);
      Map<String, dynamic> json = jsonDecode(contents);
      interface.root.setJson(json);

      return interface;
    }

    return null;
  }

  Future<bool> save() async {
    print("Saving interface");
    var file = File(info.directory.path + "/interface.json");

    if (!await file.exists()) {
      await file.create();
    }

    String treeJson = jsonEncode(root.getJson());
    await file.writeAsString(treeJson);

    return true;
  }

  void toggleEditing() {
    editing.value = !editing.value;
  }

  bool deleteWidget(UIWidget widget) {
    print("TODO: Delete widget");
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: editing,
      builder: (context, editing, child) {
        if (!editing) {
          return root;
        } else {
          return Stack(
            children: [
              LayoutBuilder(
                builder: (context, constraints) {
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(200, 0, 200, 0),
                    child: Container(
                      decoration: const BoxDecoration(
                          border: Border.symmetric(
                        vertical: BorderSide(color: Colors.black, width: 2),
                      )),
                      child: Scrollbar(
                        thumbVisibility: true,
                        controller: scrollController,
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          controller: scrollController,
                          child: SizedBox(
                            width: constraints.maxWidth,
                            height: constraints.maxHeight,
                            child: root,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
              const Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                child: WidgetMenu(),
              ),
              Positioned(
                right: 0,
                top: 0,
                bottom: 0,
                child: SizedBox(
                  width: 200,
                  child: Column(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          alignment: Alignment.topLeft,
                          decoration: const BoxDecoration(
                            color: Color.fromRGBO(30, 30, 30, 1.0),
                          ),
                          child: WidgetTreeElement(
                            widget: root,
                            ui: this,
                          ),
                        ),
                      ),
                      Expanded(
                        child: WidgetEditorMenu(this),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        }
      },
    );
  }
}

UIWidget? createUIWidget(String name, UserInterface ui) {
  /* Layout Widgets */

  if (name == "Stack") {
    return StackUIWidget(ui);
  } else if (name == "Row") {
    return RowUIWidget(ui);
  } else if (name == "Column") {
    return ColumnUIWidget(ui);
  } else if (name == "Grid") {
    return GridUIWidget(ui);

    /* Decoration Widgets */
  } else if (name == "Text") {
    return TextUIWidget(ui);
  } else if (name == "Box") {
    return BoxUIWidget(ui);
  } else if (name == "Image") {
    return ImageUIWidget(ui);
  } else if (name == "Icon") {
    return IconUIWidget(ui);
  } else if (name == "Web View") {
    return WebViewUIWidget(ui);

    /* Interactive Widgets */
  } else if (name == "Button") {
    return ButtonUIWidget(ui);
    /*
  } else if (name == "Knob") {
    return KnobUIWidget(app, tree);
  } else if (name == "Slider") {
    return SliderUIWidget(app, tree);
  } else if (name == "Button") {
    return ButtonUIWidget(app, tree);

    /* Other Widgets */

  } else if (name == "Empty") {
    return EmptyUIWidget(app, tree);*/
  } else {
    return null;
  }
}

abstract class UIWidget extends StatelessWidget {
  UIWidget(this.ui, {super.key});

  abstract final String name;
  final UserInterface ui;
  final ValueNotifier<int> notifier = ValueNotifier(0);

  void setState(VoidCallback function) {
    function();
    notifier.value = notifier.value + 1;
  }

  List<UIWidget> getChildren();

  void toggleEditor() {
    if (ui.selected.value == this) {
      ui.selected.value = null;
    } else {
      ui.selected.value = this;
    }
  }

  Map<String, dynamic> getJson();
  void setJson(Map<String, dynamic> json);

  Widget buildWidget(BuildContext context);
  Widget buildWidgetEditing(BuildContext context);
  Widget buildWidgetEditor(BuildContext context);

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: ui.editing,
      builder: (context, editing, child) {
        if (editing) {
          return buildWidgetEditing(context);
        } else {
          return buildWidget(context);
        }
      },
    );
  }

  UIWidget? createChild(Map<String, dynamic>? json) {
    if (json == null) {
      return null;
    }

    var name = json["name"];
    var state = json["state"];

    var child = createUIWidget(name, ui);

    if (child != null) {
      if (state != null) {
        setState(() {
          child.setJson(state);
        });
        return child;
      } else {
        return child;
      }
    } else {
      return null;
    }
  }

  bool deleteChildRecursive(UIWidget item) {
    if (getChildren().remove(item)) {
      return true;
    } else {
      for (var child in getChildren()) {
        if (child.deleteChildRecursive(item)) {
          return true;
        }
      }
    }

    return false;
  }

  Map<String, dynamic>? saveChild(UIWidget? widget) {
    if (widget != null) {
      return {"name": widget.name, "state": widget.getJson()};
    } else {
      return null;
    }
  }

  List<UIWidget> createChildren(List<dynamic> json) {
    return json.map((j) => createChild(j)!).toList();
  }

  List<Map<String, dynamic>> saveChildren(List<UIWidget> children) {
    return children.map((child) => saveChild(child)!).toList();
  }
}
