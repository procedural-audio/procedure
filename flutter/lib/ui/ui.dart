import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:metasampler/ui/layout.dart';

import '../main.dart';

import 'decoration.dart';
import 'interactive.dart';

UIWidget? createUIWidget(App app, String name, UITree tree) {
  /* Layout Widgets */

  if (name == "Stack") {
    return StackUIWidget(app, tree);
  } else if (name == "Row") {
    return RowUIWidget(app, tree);
  } else if (name == "Column") {
    return ColumnUIWidget(app, tree);
  } else if (name == "Grid") {
    return GridUIWidget(app, tree);

    /* Decoration Widgets */
  } else if (name == "Text") {
    return TextUIWidget(app, tree);
  } else if (name == "Box") {
    return BoxUIWidget(app, tree);
  } else if (name == "Image") {
    return ImageUIWidget(app, tree);
  } else if (name == "Icon") {
    return IconUIWidget(app, tree);
  } else if (name == "Web View") {
    return WebViewUIWidget(app, tree);

    /* Interactive Widgets */
  } else if (name == "Button") {
    return ButtonUIWidget(app, tree);
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

class UITree {
  UITree(this.app);

  App app;

  ValueNotifier<bool> editing = ValueNotifier(false);
  ValueNotifier<UIWidget?> selected = ValueNotifier(null);

  void refresh() {
    editing.notifyListeners();
  }

  void deleteChild(UIWidget widget) {
    var root = app.project.value.ui.value;
    if (root != null) {
      if (!root.deleteChildRecursive(widget)) {
        print("Failed to delete item");
      }
    }

    if (selected.value == widget) {
      selected.value = null;
    }

    editing.notifyListeners();
  }
}

abstract class UIWidget extends StatelessWidget {
  UIWidget(this.app, this.tree);

  final App app;
  final UITree tree;

  abstract final String name;

  final ValueNotifier<int> notifier = ValueNotifier(0);

  void setState(VoidCallback f) {
    f();
    notifier.value = notifier.value + 1;
  }

  List<UIWidget> getChildren();

  void toggleEditor() {
    if (tree.selected.value == this) {
      tree.selected.value = null;
    } else {
      tree.selected.value = this;
    }
  }

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
              tree.selected.value = null;
              return buildWidget(context);
            }
          },
        );
      },
    );
  }

  Map<String, dynamic> getJson();
  void setJson(Map<String, dynamic> json);

  Widget buildWidget(BuildContext context);
  Widget buildWidgetEditing(BuildContext context);
  Widget buildWidgetEditor(BuildContext context);

  UIWidget? createChild(Map<String, dynamic>? json) {
    if (json == null) {
      return null;
    }

    var name = json["name"];
    var state = json["state"];

    var child = createUIWidget(app, name, tree);

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
