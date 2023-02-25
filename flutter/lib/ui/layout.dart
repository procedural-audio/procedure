import 'package:flutter/material.dart';

import '../host.dart';
import 'common.dart';
import 'ui.dart';
import '../main.dart';

class RootWidget extends UIWidget2 {
  RootWidget(Host host, UITree tree) : super(host, tree);

  @override
  final String name = "Root";

  double? width;
  double? height;
  Color color = const Color.fromRGBO(40, 40, 40, 1.0);
  List<UIWidget2> children = [];

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
  List<UIWidget2> getChildren() {
    return children;
  }

  @override
  Widget buildWidget(BuildContext context) {
    return Container(
        width: width,
        height: height,
        color: color,
        child: Stack(fit: StackFit.expand, children: children));
  }

  @override
  Widget buildWidgetEditing(BuildContext context) {
    return Container(
        width: width,
        height: height,
        color: color,
        child: GestureDetector(
            onTap: () {
              // toggleEditor();
            },
            child: ChildDragTarget(
              tree: tree,
              onAddChild: (child) {
                print("Adding child");
                children.add(child);
                setState(() {});
              },
              child: Stack(fit: StackFit.expand, children: children),
              host: host,
            )));
  }

  @override
  Widget buildWidgetEditor(BuildContext context) {
    return Container();
  }
}

/* Root Widget */

/*class RootWidget extends UIWidget {
  RootWidget(Host host, UITree tree) : super(host, tree);

  double? width;
  double? height;
  Color color = const Color.fromRGBO(40, 40, 40, 1.0);
  List<UIWidget> children = [];

  @override
  String getName() {
    return "Root";
  }

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
  String getCode() {
    return "";
  }

  @override
  List<UIWidget> getChildren() {
    return children;
  }

  @override
  void deleteChildRecursive(UIWidget widget) {
    if (!children.remove(widget)) {
      for (var child in children) {
        child.deleteChildRecursive(widget);
      }
    }
  }

  @override
  _RootWidget createState() => _RootWidget();
}

class _RootWidget extends UIWidgetState<RootWidget> {
  @override
  Widget buildWidget(BuildContext context) {
    return Container(
        width: widget.width,
        height: widget.height,
        color: widget.color,
        child: Stack(fit: StackFit.expand, children: widget.children));
  }

  @override
  Widget buildWidgetEditing(BuildContext context) {
    return Container(
        width: widget.width,
        height: widget.height,
        color: widget.color,
        child: GestureDetector(
            onTap: () {
              toggleEditor();
            },
            child: ChildDragTarget(
              tree: widget.tree,
              onAddChild: (child) {
                widget.children.add(child);
                refreshWidget();
              },
              child: Stack(fit: StackFit.expand, children: widget.children),
              host: widget.host,
            )));
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
              initialValue: widget.width == null ? "" : widget.width.toString(),
              onChanged: (s) {
                setState(() {
                  widget.width = double.tryParse(s);
                });
              },
            ),
            Field(
                label: "HEIGHT",
                initialValue:
                    widget.height == null ? "" : widget.height.toString(),
                onChanged: (s) {
                  setState(() {
                    widget.height = double.tryParse(s);
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
                  color: widget.color,
                  onChanged: (color) {
                    setState(() {
                      widget.color = color;
                    });
                  },
                ))
          ]))
    ]);
  }
}*/

/* Row Widget */

/*class RowUIWidget extends UIWidget {
  RowUIWidget(Host host, UITree tree) : super(host, tree);

  List<UIWidget> children = [];

  TransformData transform = TransformData(
    width: null,
    height: null,
    left: 0,
    top: 0,
    alignment: Alignment.topLeft,
    padding: EdgeInsets.zero
  );

  int columns = 2;
  EdgeInsets padding = EdgeInsets.zero;

  @override
  String getName() {
    return "Row";
  }

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
  void setJson(Map<String, dynamic> json) {
    padding = EdgeInsets.fromLTRB(json["padding_left"], json["padding_right"], json["padding_top"], json["padding_bottom"]);
    columns = json["columns"];
    children = createChildren(json["children"]);
    transform = TransformData.fromJson(json["transform"]);
  }

  @override
  String getCode() {
    return "";
  }

  @override
  List<UIWidget> getChildren() {
    return children;
  }

  @override
  void deleteChildRecursive(UIWidget widget) {
    bool removed = false;

    for (int i = 0; i < children.length; i++) {
      if (children[i] == widget) {
        children[i] = EmptyUIWidget(host, tree);
        removed = true;
      }
    }

    if (!removed) {
      for (var child in children) {
        child.deleteChildRecursive(widget);
      }
    }
  }

  @override
  _RowUIWidget createState() => _RowUIWidget();
}

class _RowUIWidget extends UIWidgetState<RowUIWidget> {
  @override
  Widget buildWidget(BuildContext context) {
    while (widget.children.length < widget.columns) {
      widget.children.add(EmptyUIWidget(widget.host, widget.tree));
    }

    while (widget.children.length > widget.columns) {
      widget.children.removeLast();
    }

    return GestureDetector(
      onTap: () {
        toggleEditor();
      },
      child: TransformWidget(
        data: widget.transform,
        child: Row(
          children: widget.children.sublist(0, widget.columns).map((child) {
            return Expanded(
              child: Padding(
                padding: widget.padding,
                child: child,
              )
            );
          }).toList()
        )
      )
    );
  }

  @override
  Widget buildWidgetEditing(BuildContext context) {
    while (widget.children.length < widget.columns) {
      widget.children.add(EmptyUIWidget(widget.host, widget.tree));
    }

    while (widget.children.length > widget.columns) {
      widget.children.removeLast();
    }

    return TransformWidgetEditing(
      data: widget.transform,
      onTap: () {
        toggleEditor();
      },
      onUpdate: (data) {
        widget.transform = data;
        refreshWidget();
      },
      tree: widget.tree,
      child: Row(
        children: widget.children.sublist(0, widget.columns).asMap().entries.map((entry) {
          var index = entry.key;
          var child = entry.value;

          return Expanded(
            child: ChildDragTarget(
              onAddChild: (newChild) {
                widget.children[index] = newChild;
                refreshWidget();
              },
              child: Padding(
                padding: widget.padding,
                child: child,
              ),
              tree: widget.tree,
              host: widget.host,
            )
          );
        }).toList()
      )
    );
  }

  @override
  Widget buildWidgetEditor(BuildContext context) {
    return Column(
      children: [
        EditorTitle("Row"),
        TransformWidgetEditor(
          data: widget.transform,
          onUpdate: (t) {
            widget.transform = t;
            refreshWidget();
          },
          tree: widget.tree,
        ),
        Section(
          title: "Layout",
          child: FieldLabel(
            text: "Columns",
            child: Field(
              width: 50,
              initialValue: widget.columns.toString(),
              label: "",
              onChanged: (s) {
                widget.columns = int.tryParse(s) ?? 2;

                while (widget.children.length < widget.columns) {
                  widget.children.add(EmptyUIWidget(widget.host, widget.tree));
                }

                while (widget.children.length > widget.columns) {
                  widget.children.removeLast();
                }

                refreshWidget();
              },
            )
          )
        ),
        Section(
          title: "Padding",
          child: Column(
            children: [
              Row(
                children: [
                  Field(
                    label: "LEFT",
                    initialValue: widget.padding.left.toString(),
                    onChanged: (s) {
                      widget.padding = EdgeInsets.fromLTRB(
                        double.tryParse(s) ?? 0.0,
                        widget.padding.top,
                        widget.padding.right,
                        widget.padding.bottom
                      );

                      refreshWidget();
                    },
                  ),
                  Field(
                    label: "RIGHT",
                    initialValue: widget.padding.right.toString(),
                    onChanged: (s) {
                      widget.padding = EdgeInsets.fromLTRB(
                        widget.padding. left,
                        widget.padding.top,
                        double.tryParse(s) ?? 0.0,
                        widget.padding.bottom
                      );

                      refreshWidget();
                    },
                  ),
                ]
              ),
              Row(
                children: [
                  Field(
                    label: "TOP",
                    initialValue: widget.padding.top.toString(),
                    onChanged: (s) {
                      widget.padding = EdgeInsets.fromLTRB(
                        widget.padding.left,
                        double.tryParse(s) ?? 0.0,
                        widget.padding.right,
                        widget.padding.bottom
                      );

                      refreshWidget();
                    },
                  ),
                  Field(
                    label: "BOTTOM",
                    initialValue: widget.padding.bottom.toString(),
                    onChanged: (s) {
                      widget.padding = EdgeInsets.fromLTRB(
                        widget.padding. left,
                        widget.padding.top,
                        widget.padding.right,
                        double.tryParse(s) ?? 0.0,
                      );

                      refreshWidget();
                    },
                  ),
                ]
              ),
            ]
          )
        ),
      ]
    );
  }
}

/* Column Widget */

class ColumnUIWidget extends UIWidget {
  ColumnUIWidget(Host host, UITree tree) : super(host, tree);

  List<UIWidget> children = [];
  int rows = 2;
  EdgeInsets padding = EdgeInsets.zero;

  TransformData transform = TransformData(
    width: null,
    height: null,
    left: 0,
    top: 0,
    alignment: Alignment.topLeft,
    padding: EdgeInsets.zero
  );

  @override
  String getName() {
    return "Column";
  }

  @override
  Map<String, dynamic> getJson() {
    while (children.length > rows) {
      children.removeLast();
    }

    return {
      "transform": transform.toJson(),
      "padding_left": padding.left,
      "padding_right": padding.right,
      "padding_top": padding.top,
      "padding_bottom": padding.bottom,
      "rows": rows,
      "children": saveChildren(children),
    };
  }

  @override
  void setJson(Map<String, dynamic> json) {
    padding = EdgeInsets.fromLTRB(json["padding_left"], json["padding_right"], json["padding_top"], json["padding_bottom"]);
    rows = json["rows"];
    children = createChildren(json["children"]);
    transform = TransformData.fromJson(json["transform"]);
  }

  @override
  String getCode() {
    return "";
  }

  @override
  List<UIWidget> getChildren() {
    return children;
  }

  @override
  void deleteChildRecursive(UIWidget widget) {
    bool removed = false;

    for (int i = 0; i < children.length; i++) {
      if (children[i] == widget) {
        children[i] = EmptyUIWidget(host, tree);
        removed = true;
      }
    }

    if (!removed) {
      for (var child in children) {
        child.deleteChildRecursive(widget);
      }
    }
  }

  @override
  _ColumnUIWidget createState() => _ColumnUIWidget();
}

class _ColumnUIWidget extends UIWidgetState<ColumnUIWidget> {
  @override
  Widget buildWidget(BuildContext context) {
    while (widget.children.length < widget.rows) {
      widget.children.add(EmptyUIWidget(widget.host, widget.tree));
    }

    while (widget.children.length > widget.rows) {
      widget.children.removeLast();
    }

    return TransformWidget(
      data: widget.transform,
      child: Column(
        children: widget.children.sublist(0, widget.rows).map((child) {
          return Expanded(
            child: Padding(
              padding: widget.padding,
              child: child,
            )
          );
        }).toList()
      )
    );
  }

  @override
  Widget buildWidgetEditing(BuildContext context) {
    while (widget.children.length < widget.rows) {
      widget.children.add(EmptyUIWidget(widget.host, widget.tree));
    }

    while (widget.children.length > widget.rows) {
      widget.children.removeLast();
    }

    return TransformWidgetEditing(
      data: widget.transform,
      onTap: () {
        toggleEditor();
      },
      onUpdate: (t) {
        widget.transform = t;
        refreshWidget();
      },
      tree: widget.tree,
      child: Column(
        children: widget.children.sublist(0, widget.rows).asMap().entries.map((entry) {
          var index = entry.key;
          var child = entry.value;

          return Expanded(
            child: ChildDragTarget(
              onAddChild: (newChild) {
                widget.children[index] = newChild;
                refreshWidget();
              },
              child: Padding(
                padding: widget.padding,
                child: child,
              ),
              tree: widget.tree,
              host: widget.host
            )
          );
        }).toList()
      )
    );
  }

  @override
  Widget buildWidgetEditor(BuildContext context) {
    return Column(
      children: [
        EditorTitle("Column"),
        TransformWidgetEditor(
          data: widget.transform,
          onUpdate: (t) {
            widget.transform = t;
            refreshWidget();
          },
          tree: widget.tree,
        ),
        Section(
          title: "Layout",
          child: FieldLabel(
            text: "Rows",
            child: Field(
              width: 50,
              initialValue: widget.rows.toString(),
              label: "",
              onChanged: (s) {
                widget.rows = int.tryParse(s) ?? 2;

                while (widget.children.length < widget.rows) {
                  widget.children.add(EmptyUIWidget(widget.host, widget.tree));
                }

                while (widget.children.length > widget.rows) {
                  widget.children.removeLast();
                }

                refreshWidget();
              },
            )
          )
        ),
        Section(
          title: "Padding",
          child: Column(
            children: [
              Row(
                children: [
                  Field(
                    label: "LEFT",
                    initialValue: widget.padding.left.toString(),
                    onChanged: (s) {
                      widget.padding = EdgeInsets.fromLTRB(
                        double.tryParse(s) ?? 0.0,
                        widget.padding.top,
                        widget.padding.right,
                        widget.padding.bottom
                      );

                      refreshWidget();
                    },
                  ),
                  Field(
                    label: "RIGHT",
                    initialValue: widget.padding.right.toString(),
                    onChanged: (s) {
                      widget.padding = EdgeInsets.fromLTRB(
                        widget.padding. left,
                        widget.padding.top,
                        double.tryParse(s) ?? 0.0,
                        widget.padding.bottom
                      );

                      refreshWidget();
                    },
                  ),
                ]
              ),
              Row(
                children: [
                  Field(
                    label: "TOP",
                    initialValue: widget.padding.top.toString(),
                    onChanged: (s) {
                      widget.padding = EdgeInsets.fromLTRB(
                        widget.padding.left,
                        double.tryParse(s) ?? 0.0,
                        widget.padding.right,
                        widget.padding.bottom
                      );

                      refreshWidget();
                    },
                  ),
                  Field(
                    label: "BOTTOM",
                    initialValue: widget.padding.bottom.toString(),
                    onChanged: (s) {
                      widget.padding = EdgeInsets.fromLTRB(
                        widget.padding. left,
                        widget.padding.top,
                        widget.padding.right,
                        double.tryParse(s) ?? 0.0,
                      );

                      refreshWidget();
                    },
                  ),
                ]
              ),
            ]
          )
        ),
      ]
    );
  }
}

/* Grid Widget */

class GridUIWidget extends UIWidget {
  GridUIWidget(Host host, UITree tree) : super(host, tree);

  TransformData transform = TransformData(
    width: null,
    height: null,
    left: 0,
    top: 0,
    alignment: Alignment.topLeft,
    padding: EdgeInsets.zero
  );

  List<UIWidget> children = [];
  int rows = 2;
  int columns = 2;
  EdgeInsets padding = EdgeInsets.zero;

  @override
  String getName() {
    return "Grid";
  }

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
    padding = EdgeInsets.fromLTRB(json["padding_left"], json["padding_right"], json["padding_top"], json["padding_bottom"]);
    rows = json["rows"];
    columns = json["columns"];
    children = createChildren(json["children"]);
    transform = TransformData.fromJson(json["transform"]);
  }

  @override
  String getCode() {
    return "";
  }

  @override
  List<UIWidget> getChildren() {
    return children;
  }

  @override
  void deleteChildRecursive(UIWidget widget) {
    bool removed = false;

    for (int i = 0; i < children.length; i++) {
      if (children[i] == widget) {
        children[i] = EmptyUIWidget(host, tree);
        removed = true;
      }
    }

    if (!removed) {
      for (var child in children) {
        child.deleteChildRecursive(widget);
      }
    }
  }

  @override
  _GridUIWidget createState() => _GridUIWidget();
}

class _GridUIWidget extends UIWidgetState<GridUIWidget> {
  @override
  Widget buildWidget(BuildContext context) {
    while (widget.children.length < widget.rows * widget.columns) {
      widget.children.add(EmptyUIWidget(widget.host, widget.tree));
    }

    while (widget.children.length > widget.rows * widget.columns) {
      widget.children.removeLast();
    }

    return TransformWidget(
      data: widget.transform,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return GridView.count(
            crossAxisCount: widget.rows,
            childAspectRatio: constraints.maxWidth / constraints.maxHeight * (widget.columns / widget.rows),
            children: widget.children.sublist(0, widget.rows * widget.columns).map((child) {
              return Padding(
                padding: widget.padding,
                child: child,
              );
            }).toList()
          );
        }
      )
    );

  }

  @override
  Widget buildWidgetEditing(BuildContext context) {
    while (widget.children.length < widget.rows * widget.columns) {
      widget.children.add(EmptyUIWidget(widget.host, widget.tree));
    }

    while (widget.children.length > widget.rows * widget.columns) {
      widget.children.removeLast();
    }

    return TransformWidgetEditing(
      data: widget.transform,
      onTap: () {
        toggleEditor();
      },
      onUpdate: (t) {
        widget.transform = t;
        refreshWidget();
      },
      tree: widget.tree,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return GridView.count(
            crossAxisCount: widget.rows,
            childAspectRatio: constraints.maxWidth / constraints.maxHeight * (widget.columns / widget.rows),
            children: widget.children.sublist(0, widget.rows * widget.columns).asMap().entries.map((entry) {
              var index = entry.key;
              var child = entry.value;

              return ChildDragTarget(
                onAddChild: (newChild) {
                  widget.children[index] = newChild;
                  refreshWidget();
                },
                child: Padding(
                  padding: widget.padding,
                  child: child,
                ),
                tree: widget.tree,
                host: widget.host
              );
            }).toList()
          );
        }
      )
    );
  }

  @override
  Widget buildWidgetEditor(BuildContext context) {
    return Column(
      children: [
        EditorTitle("Grid"),
        TransformWidgetEditor(
          data: widget.transform,
          onUpdate: (t) {
            widget.transform = t;
            refreshWidget();
          },
          tree: widget.tree,
        ),
        Section(
          title: "Layout",
          child: Row(
            children: [
              Field(
                label: "COLS",
                initialValue: widget.rows.toString(),
                onChanged: (s) {
                  widget.rows = int.tryParse(s) ?? 2;
                  refreshWidget();
                },
              ),
              Field(
                label: "ROWS",
                initialValue: widget.columns.toString(),
                onChanged: (s) {
                  widget.columns = int.tryParse(s) ?? 2;
                  refreshWidget();
                },
              ),
            ]
          )
        ),
        Section(
          title: "Padding",
          child: Column(
            children: [
              Row(
                children: [
                  Field(
                    label: "LEFT",
                    initialValue: widget.padding.left.toString(),
                    onChanged: (s) {
                      widget.padding = EdgeInsets.fromLTRB(
                        double.tryParse(s) ?? 0.0,
                        widget.padding.top,
                        widget.padding.right,
                        widget.padding.bottom
                      );

                      refreshWidget();
                    },
                  ),
                  Field(
                    label: "RIGHT",
                    initialValue: widget.padding.right.toString(),
                    onChanged: (s) {
                      widget.padding = EdgeInsets.fromLTRB(
                        widget.padding. left,
                        widget.padding.top,
                        double.tryParse(s) ?? 0.0,
                        widget.padding.bottom
                      );

                      refreshWidget();
                    },
                  ),
                ]
              ),
              Row(
                children: [
                  Field(
                    label: "TOP",
                    initialValue: widget.padding.top.toString(),
                    onChanged: (s) {
                      widget.padding = EdgeInsets.fromLTRB(
                        widget.padding.left,
                        double.tryParse(s) ?? 0.0,
                        widget.padding.right,
                        widget.padding.bottom
                      );

                      refreshWidget();
                    },
                  ),
                  Field(
                    label: "BOTTOM",
                    initialValue: widget.padding.bottom.toString(),
                    onChanged: (s) {
                      widget.padding = EdgeInsets.fromLTRB(
                        widget.padding. left,
                        widget.padding.top,
                        widget.padding.right,
                        double.tryParse(s) ?? 0.0,
                      );

                      refreshWidget();
                    },
                  ),
                ]
              ),
            ]
          )
        ),
      ]
    );
  }
}

/* Stack Widget */

class StackUIWidget extends UIWidget {
  StackUIWidget(Host host, UITree tree) : super(host, tree);

  TransformData transform = TransformData(
    width: null,
    height: null,
    left: 0,
    top: 0,
    alignment: Alignment.topLeft,
    padding: EdgeInsets.zero
  );

  List<UIWidget> children = [];

  @override
  String getName() {
    return "Stack";
  }

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
  String getCode() {
    return "";
  }

  @override
  List<UIWidget> getChildren() {
    return children;
  }

  @override
  void deleteChildRecursive(UIWidget widget) {
    if (!children.remove(widget)) {
      for (var child in children) {
        child.deleteChildRecursive(widget);
      }
    }
  }

  @override
  _StackUIWidget createState() => _StackUIWidget();
}

class _StackUIWidget extends UIWidgetState<StackUIWidget> {
  @override
  Widget buildWidget(BuildContext context) {
    return TransformWidget(
      data: widget.transform,
      child: Stack(
        children: widget.children,
      ),
    );
  }

  @override
  Widget buildWidgetEditing(BuildContext context) {
    return TransformWidgetEditing(
      data: widget.transform,
      onTap: () {
        toggleEditor();
      },
      onUpdate: (transform) {
        widget.transform = transform;
        refreshWidget();
      },
      tree: widget.tree,
      child: Stack(
        children: <Widget>[
          ChildDragTarget(
            onAddChild: (child) {
              widget.children.add(child);
              refreshWidget();
            },
            child: null,
            tree: widget.tree,
            host: widget.host,
          )
        ] + widget.children
      )
    );
  }

  @override
  Widget buildWidgetEditor(BuildContext context) {
    return Column(
      children: [
        EditorTitle("Stack"),
        TransformWidgetEditor(
          data: widget.transform,
          onUpdate: (transform) {
            widget.transform = transform;
            refreshWidget();
          },
          tree: widget.tree,
        ),
      ]
    );
  }
}

class EmptyUIWidget extends UIWidget {
  EmptyUIWidget(Host host, UITree tree) : super(host, tree);

  @override
  String getName() {
    return "Empty";
  }

  @override
  Map<String, dynamic> getJson() {
    return {};
  }

  @override
  void setJson(Map<String, dynamic> json) {
  }

  @override
  String getCode() {
    return "";
  }

  @override
  List<UIWidget> getChildren() {
    return [];
  }

  @override
  void deleteChildRecursive(UIWidget widget) {
  }

  @override
  _EmptyUIWidget createState() => _EmptyUIWidget();
}

class _EmptyUIWidget extends UIWidgetState<EmptyUIWidget> {
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
*/