import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:metasampler/ui/layout.dart';

import 'decoration.dart';
import 'interactive.dart';

import '../views/presets.dart';

class UserInterface extends StatelessWidget {
  UserInterface(this.info, {super.key});

  late final RootWidget root = RootWidget(this);
  final PresetInfo info;
  final ValueNotifier<UIWidget?> selected = ValueNotifier(null);
  final ValueNotifier<bool> editing = ValueNotifier(false);

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
          return Padding(
            padding: const EdgeInsets.fromLTRB(200, 80, 200, 80),
            child: Container(
              decoration: const BoxDecoration(
                boxShadow: [
                  BoxShadow(
                    blurRadius: 10,
                    spreadRadius: 10,
                    offset: Offset(5, 5),
                    color: Color.fromRGBO(0, 0, 0, 0.3),
                  )
                ],
              ),
              child: Column(
                children: [
                  Container(
                    height: 30,
                    decoration: const BoxDecoration(
                        borderRadius: BorderRadius.vertical(top: Radius.circular(5)),
                        color: Color.fromRGBO(60, 60, 60, 1.0)),
                    child: Row(
                      children: [
                        const SizedBox(width: 10),
                        Container(
                          width: 12,
                          height: 12,
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.all(Radius.circular(10)),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Container(
                          width: 12,
                          height: 12,
                          decoration: const BoxDecoration(
                            color: Colors.yellow,
                            borderRadius: BorderRadius.all(Radius.circular(10)),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Container(
                          width: 12,
                          height: 12,
                          decoration: const BoxDecoration(
                            color: Colors.green,
                            borderRadius: BorderRadius.all(Radius.circular(10)),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    height: 1,
                    color: const Color.fromRGBO(20, 20, 20, 1.0),
                  ),
                  Expanded(
                    child: root
                  ),
                ],
              ),
            ),
          );
        }
      }
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
  UIWidget(this.ui);

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
