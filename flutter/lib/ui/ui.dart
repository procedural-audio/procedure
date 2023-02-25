import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

import '../host.dart';
import 'decoration.dart';
import 'interactive.dart';

UIWidget2? createUIWidget(Host host, String name, UITree tree) {
  /* Layout Widgets */

  if (name == "Text") {
    return TextUIWidget2(host, tree);
  } else if (name == "Web View") {
    return WebViewUIWidget(host, tree);
    /*if (name == "Stack") {
    return StackUIWidget(host, tree);
    } else if (name == "Row") {
    return RowUIWidget(host, tree);
  } else if (name == "Column") {
    return ColumnUIWidget(host, tree);
  } else if (name == "Grid") {
    return GridUIWidget(host, tree);

    /* Decoration Widgets */

    /*} else if (name == "Box") {
    return BoxUIWidget(host, tree);
  } else if (name == "Text") {
    return TextUIWidget(host, tree);
  } else if (name == "Image") {
    return ImageUIWidget(host, tree);
  } else if (name == "Icon") {
    return IconUIWidget(host, tree);*/

    /* Interactive Widgets */

  } else if (name == "Knob") {
    return KnobUIWidget(host, tree);
  } else if (name == "Slider") {
    return SliderUIWidget(host, tree);
  } else if (name == "Button") {
    return ButtonUIWidget(host, tree);

    /* Other Widgets */

  } else if (name == "Empty") {
    return EmptyUIWidget(host, tree);*/
  } else {
    return null;
  }
}

class UITree {
  UITree(this.host);

  Host host;

  ValueNotifier<bool> editing = ValueNotifier(false);
  ValueNotifier<Widget Function(BuildContext)?> editorBuilder =
      ValueNotifier(null);

  void refresh() {
    editing.notifyListeners();
  }

  void delete(UIWidget2 widget) {
    // host.globals.rootWidget?.deleteChildRecursive(widget);
    editorBuilder.value = null;
    editing.notifyListeners();
  }
}

abstract class UIWidget2 extends StatelessWidget {
  UIWidget2(this.host, this.tree) {
    // state = ValueNotifier(newState());
  }

  final Host host;
  final UITree tree;

  abstract final String name;

  final ValueNotifier<int> notifier = ValueNotifier(0);

  void setState(VoidCallback f) {
    f();
    notifier.value = notifier.value + 1;
  }

  List<UIWidget2> getChildren();

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
        valueListenable: tree.editing,
        builder: (context, editing, child) {
          return ValueListenableBuilder(
              valueListenable: notifier,
              builder: (context, value, child) {
                if (editing) {
                  return buildWidgetEditing(context);
                } else {
                  tree.editorBuilder.value = null;
                  return buildWidget(context);
                }
              });
        });
  }

  Map<String, dynamic> getJson();
  void setJson(Map<String, dynamic> json);

  Widget buildWidget(BuildContext context);
  Widget buildWidgetEditing(BuildContext context);
  Widget buildWidgetEditor(BuildContext context);

  UIWidget2? createChild(Map<String, dynamic>? json) {
    if (json == null) {
      return null;
    }

    var name = json["name"];
    var state = json["state"];

    var child = createUIWidget(host, name, tree);

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

  Map<String, dynamic>? saveChild(UIWidget2? widget) {
    if (widget != null) {
      return {"name": widget.name, "state": widget.getJson()};
    } else {
      return null;
    }
  }

  List<UIWidget2> createChildren(List<dynamic> json) {
    return json.map((j) => createChild(j)!).toList();
  }

  List<Map<String, dynamic>> saveChildren(List<UIWidget2> children) {
    return children.map((child) => saveChild(child)!).toList();
  }
}

/*abstract class UIWidget extends StatefulWidget {
  UIWidget(this.host, this.tree) : super(key: UniqueKey());

  Host host;
  UITree tree;

  String getName();

  ValueNotifier<int> editRefresher = ValueNotifier(0);

  Map<String, dynamic> getJson();
  void setJson(Map<String, dynamic> json);

  String getCode();

  UIWidget? createChild(Map<String, dynamic>? json) {
    if (json == null) {
      return null;
    }

    var name = json["name"];
    var state = json["state"];

    var child = createUIWidget(host, name, tree);

    if (child != null) {
      if (state != null) {
        child.setJson(state);
        return child;
      } else {
        return child;
      }
    } else {
      return null;
    }
  }

  Map<String, dynamic>? saveChild(UIWidget? widget) {
    if (widget != null) {
      return {"name": widget.getName(), "state": widget.getJson()};
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

  void refresh() {
    editRefresher.notifyListeners();
  }

  void deleteChildRecursive(UIWidget widget);

  List<UIWidget> getChildren();

  @override
  UIWidgetState createState();
}

abstract class UIWidgetState<T extends UIWidget> extends State<T> {
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
        valueListenable: widget.tree.editing,
        builder: (context, editing, child) {
          if (editing) {
            return ValueListenableBuilder(
                valueListenable: widget.editRefresher,
                builder: (context, value, child) {
                  return buildWidgetEditing(context);
                });
          } else {
            widget.tree.editorBuilder.value = null;
            return buildWidget(context);
          }
        });
  }

  void refreshWidget() {
    widget.refresh();
  }

  void refreshEditor() {
    widget.tree.editorBuilder.notifyListeners();
  }

  Widget buildWidget(BuildContext context);
  Widget buildWidgetEditing(BuildContext context);
  Widget buildWidgetEditor(BuildContext context);

  void toggleEditor() {
    if (widget.tree.editorBuilder.value == buildWidgetEditor) {
      widget.tree.editorBuilder.value = null;
    } else {
      widget.tree.editorBuilder.value = buildWidgetEditor;
    }
  }
}*/
