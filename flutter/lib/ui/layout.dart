import 'package:flutter/material.dart';

import '../host.dart';
import 'common.dart';
import 'ui.dart';
import '../main.dart';

class UserInterface extends UIWidget {
  UserInterface(App app, UITree tree) : super(app, tree);

  @override
  final String name = "Root";

  double? width;
  double? height;
  Color color = const Color.fromRGBO(40, 40, 40, 1.0);
  List<UIWidget> children = [];

  @override
  Map<String, dynamic> getJson() {
    return {
      "width": width,
      "height": height,
      "color": color.value,
      "children": saveChildren(children)
    };
  }

  @override
  void setJson(Map<String, dynamic> json) {
    width = json["width"];
    height = json["height"];
    color = Color(json["color"]);
    children = createChildren(json["children"]);
  }

  @override
  List<UIWidget> getChildren() {
    return children;
  }

  @override
  Widget buildWidget(BuildContext context) {
    return Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
            color: color,
            borderRadius: const BorderRadius.all(Radius.circular(5))),
        child: Stack(fit: StackFit.expand, children: children));
  }

  @override
  Widget buildWidgetEditing(BuildContext context) {
    return Container(
        decoration: const BoxDecoration(boxShadow: [
          BoxShadow(
              blurRadius: 10,
              spreadRadius: 10,
              offset: Offset(5, 5),
              color: Color.fromRGBO(0, 0, 0, 0.3))
        ]),
        child: Column(children: [
          Container(
              height: 30,
              decoration: const BoxDecoration(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(5)),
                  color: Color.fromRGBO(60, 60, 60, 1.0)),
              child: Row(children: [
                const SizedBox(width: 10),
                Container(
                  width: 12,
                  height: 12,
                  decoration: const BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.all(Radius.circular(10))),
                ),
                const SizedBox(width: 10),
                Container(
                  width: 12,
                  height: 12,
                  decoration: const BoxDecoration(
                      color: Colors.yellow,
                      borderRadius: BorderRadius.all(Radius.circular(10))),
                ),
                const SizedBox(width: 10),
                Container(
                  width: 12,
                  height: 12,
                  decoration: const BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.all(Radius.circular(10))),
                )
              ])),
          Container(height: 1, color: const Color.fromRGBO(20, 20, 20, 1.0)),
          Expanded(
              child: Container(
                  width: width,
                  height: height,
                  decoration: BoxDecoration(
                      color: color,
                      borderRadius: const BorderRadius.vertical(
                          bottom: Radius.circular(5))),
                  child: GestureDetector(
                      onTap: () {
                        toggleEditor();
                      },
                      child: ChildDragTarget(
                        tree: tree,
                        onAddChild: (child) {
                          print("Adding child");
                          children.add(child);
                          setState(() {});
                        },
                        child: Stack(fit: StackFit.expand, children: children),
                        app: app,
                      ))))
        ]));
  }

  @override
  Widget buildWidgetEditor(BuildContext context) {
    return Column(children: [
      EditorTitle("Root"),
      Section(
          title: "Layout",
          child: Row(children: [
            Field(
              label: "WIDTH",
              initialValue: width == null ? "" : width.toString(),
              onChanged: (s) {
                setState(() {
                  width = double.tryParse(s);
                });
              },
            ),
            Field(
                label: "HEIGHT",
                initialValue: height == null ? "" : height.toString(),
                onChanged: (s) {
                  setState(() {
                    height = double.tryParse(s);
                  });
                })
          ])),
      Section(
          title: "Style",
          child: Column(children: [
            FieldLabel(
                text: "Color",
                child: ColorField(
                  width: 150,
                  color: color,
                  onChanged: (c) {
                    setState(() {
                      color = c;
                    });
                  },
                ))
          ]))
    ]);
  }
}

/* Stack Widget */

class StackUIWidget extends UIWidget {
  StackUIWidget(App app, UITree tree) : super(app, tree);

  @override
  final String name = "Stack";

  List<UIWidget> children = [];

  TransformData transform = TransformData(
      width: null,
      height: null,
      left: 0,
      top: 0,
      alignment: Alignment.topLeft,
      padding: EdgeInsets.zero);

  @override
  Map<String, dynamic> getJson() {
    return {
      "transform": transform.toJson(),
      "children": saveChildren(children)
    };
  }

  @override
  void setJson(Map<String, dynamic> json) {
    transform = TransformData.fromJson(json["transform"]);
    children = createChildren(json["children"]);
  }

  @override
  List<UIWidget> getChildren() {
    return children;
  }

  @override
  Widget buildWidget(BuildContext context) {
    return TransformWidget(
      data: transform,
      child: Stack(
        children: children,
      ),
    );
  }

  @override
  Widget buildWidgetEditing(BuildContext context) {
    return TransformWidgetEditing(
        data: transform,
        onTap: () {
          toggleEditor();
        },
        onUpdate: (t) {
          transform = t;
          setState(() {});
        },
        tree: tree,
        child: Stack(
            children: <Widget>[
                  ChildDragTarget(
                    onAddChild: (child) {
                      children.add(child);
                      setState(() {});
                    },
                    child: null,
                    tree: tree,
                    app: app,
                  )
                ] +
                children));
  }

  @override
  Widget buildWidgetEditor(BuildContext context) {
    return Column(children: [
      EditorTitle("Stack"),
      TransformWidgetEditor(
        data: transform,
        onUpdate: (transform) {
          transform = transform;
          setState(() {});
        },
        tree: tree,
      ),
    ]);
  }
}

/* Row Widget */

class RowUIWidget extends UIWidget {
  RowUIWidget(App app, UITree tree) : super(app, tree);

  List<UIWidget> children = [];

  TransformData transform = TransformData(
      width: null,
      height: null,
      left: 0,
      top: 0,
      alignment: Alignment.topLeft,
      padding: EdgeInsets.zero);

  int columns = 2;
  EdgeInsets padding = EdgeInsets.zero;

  @override
  final String name = "Row";

  @override
  Map<String, dynamic> getJson() {
    while (children.length > columns) {
      children.removeLast();
    }

    return {
      "transform": transform.toJson(),
      "padding_left": padding.left,
      "padding_right": padding.right,
      "padding_top": padding.top,
      "padding_bottom": padding.bottom,
      "columns": columns,
      "children": saveChildren(children),
    };
  }

  @override
  List<UIWidget> getChildren() {
    return children;
  }

  @override
  void setJson(Map<String, dynamic> json) {
    padding = EdgeInsets.fromLTRB(json["padding_left"], json["padding_right"],
        json["padding_top"], json["padding_bottom"]);

    columns = json["columns"];
    children = createChildren(json["children"]);
    transform = TransformData.fromJson(json["transform"]);
  }

  @override
  Widget buildWidget(BuildContext context) {
    while (children.length < columns) {
      children.add(EmptyUIWidget(app, tree));
    }

    while (children.length > columns) {
      children.removeLast();
    }

    return GestureDetector(
        onTap: () {
          toggleEditor();
        },
        child: TransformWidget(
            data: transform,
            child: Row(
                children: children.sublist(0, columns).map((child) {
              return Expanded(
                  child: Padding(
                padding: padding,
                child: child,
              ));
            }).toList())));
  }

  @override
  Widget buildWidgetEditing(BuildContext context) {
    while (children.length < columns) {
      children.add(EmptyUIWidget(app, tree));
    }

    while (children.length > columns) {
      children.removeLast();
    }

    return TransformWidgetEditing(
        data: transform,
        onTap: () {
          toggleEditor();
        },
        onUpdate: (data) {
          transform = data;
          setState(() {});
        },
        tree: tree,
        child: Row(
            children: children.sublist(0, columns).asMap().entries.map((entry) {
          var index = entry.key;
          var child = entry.value;

          return Expanded(
              child: ChildDragTarget(
            onAddChild: (newChild) {
              children[index] = newChild;
              setState(() {});
            },
            child: Padding(
              padding: padding,
              child: child,
            ),
            tree: tree,
            app: app,
          ));
        }).toList()));
  }

  @override
  Widget buildWidgetEditor(BuildContext context) {
    return Column(children: [
      EditorTitle("Row"),
      TransformWidgetEditor(
        data: transform,
        onUpdate: (t) {
          transform = t;
          setState(() {});
        },
        tree: tree,
      ),
      Section(
          title: "Layout",
          child: FieldLabel(
              text: "Columns",
              child: Field(
                width: 50,
                initialValue: columns.toString(),
                label: "",
                onChanged: (s) {
                  columns = int.tryParse(s) ?? 2;

                  while (children.length < columns) {
                    children.add(EmptyUIWidget(app, tree));
                  }

                  while (children.length > columns) {
                    children.removeLast();
                  }

                  setState(() {});
                },
              ))),
      Section(
          title: "Padding",
          child: Column(children: [
            Row(children: [
              Field(
                  label: "LEFT",
                  initialValue: padding.left.toString(),
                  onChanged: (s) {
                    padding = EdgeInsets.fromLTRB(double.tryParse(s) ?? 0.0,
                        padding.top, padding.right, padding.bottom);

                    setState(() {});
                  }),
              Field(
                  label: "RIGHT",
                  initialValue: padding.right.toString(),
                  onChanged: (s) {
                    padding = EdgeInsets.fromLTRB(padding.left, padding.top,
                        double.tryParse(s) ?? 0.0, padding.bottom);

                    setState(() {});
                  })
            ]),
            Row(children: [
              Field(
                  label: "TOP",
                  initialValue: padding.top.toString(),
                  onChanged: (s) {
                    padding = EdgeInsets.fromLTRB(
                        padding.left,
                        double.tryParse(s) ?? 0.0,
                        padding.right,
                        padding.bottom);

                    setState(() {});
                  }),
              Field(
                  label: "BOTTOM",
                  initialValue: padding.bottom.toString(),
                  onChanged: (s) {
                    padding = EdgeInsets.fromLTRB(
                      padding.left,
                      padding.top,
                      padding.right,
                      double.tryParse(s) ?? 0.0,
                    );

                    setState(() {});
                  })
            ])
          ]))
    ]);
  }
}

class ColumnUIWidget extends UIWidget {
  ColumnUIWidget(App app, UITree tree) : super(app, tree);

  List<UIWidget> children = [];

  TransformData transform = TransformData(
      width: null,
      height: null,
      left: 0,
      top: 0,
      alignment: Alignment.topLeft,
      padding: EdgeInsets.zero);

  int columns = 2;
  EdgeInsets padding = EdgeInsets.zero;

  @override
  final String name = "Column";

  @override
  Map<String, dynamic> getJson() {
    while (children.length > columns) {
      children.removeLast();
    }

    return {
      "transform": transform.toJson(),
      "padding_left": padding.left,
      "padding_right": padding.right,
      "padding_top": padding.top,
      "padding_bottom": padding.bottom,
      "columns": columns,
      "children": saveChildren(children),
    };
  }

  @override
  List<UIWidget> getChildren() {
    return children;
  }

  @override
  void setJson(Map<String, dynamic> json) {
    padding = EdgeInsets.fromLTRB(json["padding_left"], json["padding_right"],
        json["padding_top"], json["padding_bottom"]);

    columns = json["columns"];
    children = createChildren(json["children"]);
    transform = TransformData.fromJson(json["transform"]);
  }

  @override
  Widget buildWidget(BuildContext context) {
    while (children.length < columns) {
      children.add(EmptyUIWidget(app, tree));
    }

    while (children.length > columns) {
      children.removeLast();
    }

    return GestureDetector(
        onTap: () {
          toggleEditor();
        },
        child: TransformWidget(
            data: transform,
            child: Column(
                children: children.sublist(0, columns).map((child) {
              return Expanded(
                  child: Padding(
                padding: padding,
                child: child,
              ));
            }).toList())));
  }

  @override
  Widget buildWidgetEditing(BuildContext context) {
    while (children.length < columns) {
      children.add(EmptyUIWidget(app, tree));
    }

    while (children.length > columns) {
      children.removeLast();
    }

    return TransformWidgetEditing(
        data: transform,
        onTap: () {
          toggleEditor();
        },
        onUpdate: (data) {
          transform = data;
          setState(() {});
        },
        tree: tree,
        child: Column(
            children: children.sublist(0, columns).asMap().entries.map((entry) {
          var index = entry.key;
          var child = entry.value;

          return Expanded(
              child: ChildDragTarget(
            onAddChild: (newChild) {
              children[index] = newChild;
              setState(() {});
            },
            child: Padding(
              padding: padding,
              child: child,
            ),
            tree: tree,
            app: app,
          ));
        }).toList()));
  }

  @override
  Widget buildWidgetEditor(BuildContext context) {
    return Column(children: [
      EditorTitle("Column"),
      TransformWidgetEditor(
        data: transform,
        onUpdate: (t) {
          transform = t;
          setState(() {});
        },
        tree: tree,
      ),
      Section(
          title: "Layout",
          child: FieldLabel(
              text: "Columns",
              child: Field(
                width: 50,
                initialValue: columns.toString(),
                label: "",
                onChanged: (s) {
                  columns = int.tryParse(s) ?? 2;

                  while (children.length < columns) {
                    children.add(EmptyUIWidget(app, tree));
                  }

                  while (children.length > columns) {
                    children.removeLast();
                  }

                  setState(() {});
                },
              ))),
      Section(
          title: "Padding",
          child: Column(children: [
            Row(children: [
              Field(
                  label: "LEFT",
                  initialValue: padding.left.toString(),
                  onChanged: (s) {
                    padding = EdgeInsets.fromLTRB(double.tryParse(s) ?? 0.0,
                        padding.top, padding.right, padding.bottom);

                    setState(() {});
                  }),
              Field(
                  label: "RIGHT",
                  initialValue: padding.right.toString(),
                  onChanged: (s) {
                    padding = EdgeInsets.fromLTRB(padding.left, padding.top,
                        double.tryParse(s) ?? 0.0, padding.bottom);

                    setState(() {});
                  })
            ]),
            Row(children: [
              Field(
                  label: "TOP",
                  initialValue: padding.top.toString(),
                  onChanged: (s) {
                    padding = EdgeInsets.fromLTRB(
                        padding.left,
                        double.tryParse(s) ?? 0.0,
                        padding.right,
                        padding.bottom);

                    setState(() {});
                  }),
              Field(
                  label: "BOTTOM",
                  initialValue: padding.bottom.toString(),
                  onChanged: (s) {
                    padding = EdgeInsets.fromLTRB(
                      padding.left,
                      padding.top,
                      padding.right,
                      double.tryParse(s) ?? 0.0,
                    );

                    setState(() {});
                  })
            ])
          ]))
    ]);
  }
}

class EmptyUIWidget extends UIWidget {
  EmptyUIWidget(App app, UITree tree) : super(app, tree);

  @override
  String name = "Empty";

  @override
  List<UIWidget> getChildren() {
    return [];
  }

  @override
  Map<String, dynamic> getJson() {
    return {};
  }

  @override
  void setJson(Map<String, dynamic> json) {}

  @override
  Widget buildWidget(BuildContext context) {
    return IgnorePointer(child: Container());
  }

  @override
  Widget buildWidgetEditing(BuildContext context) {
    return IgnorePointer(child: Container());
  }

  @override
  Widget buildWidgetEditor(BuildContext context) {
    return IgnorePointer(child: Container());
  }
}

/* Grid Widget */

class GridUIWidget extends UIWidget {
  GridUIWidget(App app, UITree tree) : super(app, tree);

  TransformData transform = TransformData(
      width: null,
      height: null,
      left: 0,
      top: 0,
      alignment: Alignment.topLeft,
      padding: EdgeInsets.zero);

  List<UIWidget> children = [];
  int rows = 2;
  int columns = 2;
  EdgeInsets padding = EdgeInsets.zero;

  @override
  final String name = "Grid";

  @override
  Map<String, dynamic> getJson() {
    while (children.length > columns * rows) {
      children.removeLast();
    }

    return {
      "transform": transform.toJson(),
      "padding_left": padding.left,
      "padding_right": padding.right,
      "padding_top": padding.top,
      "padding_bottom": padding.bottom,
      "rows": rows,
      "columns": columns,
      "children": saveChildren(children),
    };
  }

  @override
  void setJson(Map<String, dynamic> json) {
    padding = EdgeInsets.fromLTRB(json["padding_left"], json["padding_right"],
        json["padding_top"], json["padding_bottom"]);
    rows = json["rows"];
    columns = json["columns"];
    children = createChildren(json["children"]);
    transform = TransformData.fromJson(json["transform"]);
  }

  @override
  List<UIWidget> getChildren() {
    return children;
  }

  @override
  bool deleteChildRecursive(UIWidget item) {
    var children = getChildren();
    if (children.contains(item)) {
      for (int i = 0; i < children.length; i++) {
        if (children[i] == item) {
          children[i] = EmptyUIWidget(app, tree);
          return true;
        }
      }
    } else {
      for (var child in children) {
        if (child.deleteChildRecursive(item)) {
          return true;
        }
      }
    }

    return false;
  }

  @override
  Widget buildWidget(BuildContext context) {
    while (children.length < rows * columns) {
      children.add(EmptyUIWidget(app, tree));
    }

    while (children.length > rows * columns) {
      children.removeLast();
    }

    return TransformWidget(
        data: transform,
        child: LayoutBuilder(builder: (context, constraints) {
          return GridView.count(
              crossAxisCount: rows,
              childAspectRatio: constraints.maxWidth /
                  constraints.maxHeight *
                  (columns / rows),
              children: children.sublist(0, rows * columns).map((child) {
                return Padding(
                  padding: padding,
                  child: child,
                );
              }).toList());
        }));
  }

  @override
  Widget buildWidgetEditing(BuildContext context) {
    while (children.length < rows * columns) {
      children.add(EmptyUIWidget(app, tree));
    }

    while (children.length > rows * columns) {
      children.removeLast();
    }

    return TransformWidgetEditing(
        data: transform,
        onTap: () {
          toggleEditor();
        },
        onUpdate: (t) {
          transform = t;
          setState(() {});
        },
        tree: tree,
        child: LayoutBuilder(builder: (context, constraints) {
          return GridView.count(
              crossAxisCount: rows,
              childAspectRatio: constraints.maxWidth /
                  constraints.maxHeight *
                  (columns / rows),
              children: children
                  .sublist(0, rows * columns)
                  .asMap()
                  .entries
                  .map((entry) {
                var index = entry.key;
                var child = entry.value;

                return ChildDragTarget(
                    onAddChild: (newChild) {
                      children[index] = newChild;
                      setState(() {});
                    },
                    child: Padding(
                      padding: padding,
                      child: child,
                    ),
                    tree: tree,
                    app: app);
              }).toList());
        }));
  }

  @override
  Widget buildWidgetEditor(BuildContext context) {
    return Column(children: [
      EditorTitle("Grid"),
      TransformWidgetEditor(
        data: transform,
        onUpdate: (t) {
          transform = t;
          setState(() {});
        },
        tree: tree,
      ),
      Section(
          title: "Layout",
          child: Row(children: [
            Field(
              label: "COLS",
              initialValue: rows.toString(),
              onChanged: (s) {
                rows = int.tryParse(s) ?? 2;
                setState(() {});
              },
            ),
            Field(
              label: "ROWS",
              initialValue: columns.toString(),
              onChanged: (s) {
                columns = int.tryParse(s) ?? 2;
                setState(() {});
              },
            ),
          ])),
      Section(
          title: "Padding",
          child: Column(children: [
            Row(children: [
              Field(
                label: "LEFT",
                initialValue: padding.left.toString(),
                onChanged: (s) {
                  padding = EdgeInsets.fromLTRB(double.tryParse(s) ?? 0.0,
                      padding.top, padding.right, padding.bottom);

                  setState(() {});
                },
              ),
              Field(
                label: "RIGHT",
                initialValue: padding.right.toString(),
                onChanged: (s) {
                  padding = EdgeInsets.fromLTRB(padding.left, padding.top,
                      double.tryParse(s) ?? 0.0, padding.bottom);

                  setState(() {});
                },
              ),
            ]),
            Row(children: [
              Field(
                label: "TOP",
                initialValue: padding.top.toString(),
                onChanged: (s) {
                  padding = EdgeInsets.fromLTRB(padding.left,
                      double.tryParse(s) ?? 0.0, padding.right, padding.bottom);

                  setState(() {});
                },
              ),
              Field(
                label: "BOTTOM",
                initialValue: padding.bottom.toString(),
                onChanged: (s) {
                  padding = EdgeInsets.fromLTRB(
                    padding.left,
                    padding.top,
                    padding.right,
                    double.tryParse(s) ?? 0.0,
                  );

                  setState(() {});
                },
              ),
            ]),
          ])),
    ]);
  }
}
