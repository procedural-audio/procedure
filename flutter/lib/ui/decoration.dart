import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../host.dart';
import 'ui.dart';
import 'layout.dart';
import 'common.dart';

import 'dart:io';

class TextUIWidget2 extends UIWidget2 {
  TextUIWidget2(Host host, UITree tree) : super(host, tree);

  @override
  final String name = "Text";

  String text = "Text Here";
  double size = 14;
  Color color = Colors.white;

  TransformData data = TransformData(
      width: 100,
      height: 30,
      left: 0,
      top: 0,
      alignment: Alignment.topLeft,
      padding: EdgeInsets.zero);

  @override
  Map<String, dynamic> getJson() {
    return {
      "text": text,
      "size": size,
      "color": color.value,
      "transform": data.toJson()
    };
  }

  @override
  void setJson(Map<String, dynamic> json) {
    text = json["text"];
    size = json["size"];
    color = Color(json["color"]);
    data = TransformData.fromJson(json["transform"]);
  }

  @override
  List<UIWidget2> getChildren() {
    return [];
  }

  @override
  Widget buildWidget(BuildContext context) {
    return TransformWidget(
        data: data,
        child: Text(text,
            textAlign: TextAlign.center,
            style: TextStyle(color: color, fontSize: size)));
  }

  @override
  Widget buildWidgetEditing(BuildContext context) {
    return TransformWidgetEditing(
        data: data,
        onTap: () {
          // state.notifyListeners();
        },
        onUpdate: (t) {
          setState(() {
            data = t;
          });
        },
        tree: tree,
        child: Text(text,
            textAlign: TextAlign.center,
            style: TextStyle(color: color, fontSize: size)));
  }

  @override
  Widget buildWidgetEditor(BuildContext context) {
    return Column(children: [
      EditorTitle("Text"),
      TransformWidgetEditor(
          data: data,
          onUpdate: (t) {
            setState(() {
              data = t;
            });
          },
          tree: tree),
      Section(
          title: "Text",
          child: Row(children: [
            Field(
              width: 260,
              label: "",
              initialValue: text,
              onChanged: (s) {
                setState(() {
                  text = s;
                });
              },
            )
          ])),
      Section(
          title: "Style",
          child: Column(children: [
            FieldLabel(
                text: "Font Size",
                child: Field(
                  width: 60,
                  label: "",
                  initialValue: size.toString(),
                  onChanged: (s) {
                    var newSize = double.tryParse(s);

                    if (newSize != null) {
                      size = newSize;
                    }

                    setState(() {});
                  },
                )),
            FieldLabel(
                text: "Color",
                child: ColorField(
                    width: 160,
                    color: color,
                    onChanged: (c) {
                      setState(() {
                        color = c;
                      });
                    }))
          ]))
    ]);
  }
}

/*class TextUIWidget extends UIWidget {
  TextUIWidget(Host host, UITree tree) : super(host, tree);

  String text = "Text Here";
  double size = 14;
  Color color = Colors.white;

  TransformData data = TransformData(
      width: 100,
      height: 30,
      left: 0,
      top: 0,
      alignment: Alignment.topLeft,
      padding: EdgeInsets.zero);

  @override
  String getName() {
    return "Text";
  }

  @override
  Map<String, dynamic> getJson() {
    return {
      "text": text,
      "size": size,
      "color": color.value,
      "transform": data.toJson()
    };
  }

  @override
  void setJson(Map<String, dynamic> json) {
    text = json["text"];
    size = json["size"];
    color = Color(json["color"]);
    data = TransformData.fromJson(json["transform"]);
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
  void deleteChildRecursive(UIWidget widget) {}

  @override
  _TextUIWidget createState() => _TextUIWidget();
}

class _TextUIWidget extends UIWidgetState<TextUIWidget> {
  @override
  Widget buildWidget(BuildContext context) {
    return TransformWidget(
        data: widget.data,
        child: Text(widget.text,
            textAlign: TextAlign.center,
            style: TextStyle(color: widget.color, fontSize: widget.size)));
  }

  @override
  Widget buildWidgetEditing(BuildContext context) {
    return TransformWidgetEditing(
        data: widget.data,
        onTap: () {
          toggleEditor();
        },
        onUpdate: (t) {
          widget.data = t;
          refreshWidget();
        },
        tree: widget.tree,
        child: Text(widget.text,
            textAlign: TextAlign.center,
            style: TextStyle(color: widget.color, fontSize: widget.size)));
  }

  @override
  Widget buildWidgetEditor(BuildContext context) {
    return Column(children: [
      EditorTitle("Text"),
      TransformWidgetEditor(
          data: widget.data,
          onUpdate: (t) {
            widget.data = t;
            refreshWidget();
          },
          tree: widget.tree),
      Section(
          title: "Text",
          child: Row(children: [
            Field(
              width: 260,
              label: "",
              initialValue: widget.text,
              onChanged: (s) {
                widget.text = s;
                refreshWidget();
              },
            )
          ])),
      Section(
          title: "Style",
          child: Column(children: [
            FieldLabel(
                text: "Font Size",
                child: Field(
                  width: 60,
                  label: "",
                  initialValue: widget.size.toString(),
                  onChanged: (s) {
                    var size = double.tryParse(s);

                    if (size != null) {
                      widget.size = size;
                    }

                    refreshWidget();
                  },
                )),
            FieldLabel(
                text: "Color",
                child: ColorField(
                    width: 160,
                    color: widget.color,
                    onChanged: (color) {
                      widget.color = color;
                      refreshWidget();
                    }))
          ])),
    ]);
  }
}

/* Image Widget */

class ImageUIWidget extends UIWidget {
  ImageUIWidget(Host host, UITree tree) : super(host, tree);

  String? path =
      "/home/chase/github/metasampler/content/assets/backgrounds/background_02.png";

  TransformData data = TransformData(
      width: null,
      height: null,
      left: 0,
      top: 0,
      alignment: Alignment.topLeft,
      padding: EdgeInsets.zero);

  @override
  String getName() {
    return "Image";
  }

  @override
  Map<String, dynamic> getJson() {
    return {"path": path, "transform": data.toJson()};
  }

  @override
  void setJson(Map<String, dynamic> json) {
    path = json["path"];
    data = TransformData.fromJson(json["transform"]);
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
  void deleteChildRecursive(UIWidget widget) {}

  @override
  _ImageUIWidget createState() => _ImageUIWidget();
}

class _ImageUIWidget extends UIWidgetState<ImageUIWidget> {
  @override
  Widget buildWidget(BuildContext context) {
    return TransformWidget(
        data: widget.data,
        child: widget.path != null
            ? Stack(fit: StackFit.expand, children: [
                Image.file(
                  File(widget.path!),
                  repeat: ImageRepeat.noRepeat,
                  fit: BoxFit.fill,
                )
              ])
            : Container());
  }

  @override
  Widget buildWidgetEditing(BuildContext context) {
    return TransformWidgetEditing(
        data: widget.data,
        onTap: () {
          toggleEditor();
        },
        onUpdate: (v) {
          widget.data = v;
          refreshWidget();
        },
        tree: widget.tree,
        child: widget.path != null
            ? Image.file(
                File(widget.path!),
                repeat: ImageRepeat.noRepeat,
                fit: BoxFit.fill,
              )
            : Container());
  }

  @override
  Widget buildWidgetEditor(BuildContext context) {
    return Column(children: [
      EditorTitle("Image"),
      TransformWidgetEditor(
        data: widget.data,
        onUpdate: (v) {
          widget.data = v;
          refreshWidget();
        },
        tree: widget.tree,
      ),
      Section(
          title: "File",
          child: Row(children: [
            FileField(
              width: 260,
              extensions: const ["png", "jpg", "jpeg"],
              path: widget.path,
              onChanged: (s) {
                widget.path = s;
                refreshWidget();
              },
            )
          ])),
      Section(
          title: "Style",
          child: Column(children: [
            FieldLabel(
              text: "Mode",
              child: Container(),
            )
          ])),
    ]);
  }
}

/* Icon Widget */

class IconUIWidget extends UIWidget {
  IconUIWidget(Host host, UITree tree) : super(host, tree);

  String? path =
      "/home/chase/github/metasampler/content/assets/icons/clock.svg";
  Color color = Colors.grey;

  TransformData data = TransformData(
      width: null,
      height: null,
      left: 0,
      top: 0,
      alignment: Alignment.topLeft,
      padding: EdgeInsets.zero);

  @override
  String getName() {
    return "Icon";
  }

  @override
  Map<String, dynamic> getJson() {
    return {"path": path, "transform": data};
  }

  @override
  void setJson(Map<String, dynamic> json) {
    path = json["path"];
    data = json["transform"];
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
  void deleteChildRecursive(UIWidget widget) {}

  @override
  _IconUIWidget createState() => _IconUIWidget();
}

class _IconUIWidget extends UIWidgetState<IconUIWidget> {
  @override
  Widget buildWidget(BuildContext context) {
    return TransformWidget(
        data: widget.data,
        child: widget.path != null
            ? SvgPicture.file(
                File(widget.path!),
                color: widget.color,
              )
            : Container());
  }

  @override
  Widget buildWidgetEditing(BuildContext context) {
    return TransformWidgetEditing(
        data: widget.data,
        onTap: () {
          toggleEditor();
        },
        onUpdate: (t) {
          widget.data = t;
          refreshWidget();
        },
        tree: widget.tree,
        child: widget.path != null
            ? SvgPicture.file(
                File(widget.path!),
                color: widget.color,
              )
            : Container());
  }

  @override
  Widget buildWidgetEditor(BuildContext context) {
    return Column(children: [
      EditorTitle("Icon"),
      TransformWidgetEditor(
        data: widget.data,
        onUpdate: (v) {
          widget.data = v;
          refreshWidget();
        },
        tree: widget.tree,
      ),
      Section(
          title: "Path",
          child: Row(children: [
            FileField(
              width: 260,
              path: widget.path,
              extensions: const ["svg"],
              onChanged: (s) {
                widget.path = s;
                refreshWidget();
              },
            )
          ])),
      Section(
          title: "Style",
          child: Column(children: [
            FieldLabel(
              text: "Mode",
              child: Container(),
            ),
            ColorField(
                width: 160,
                color: widget.color,
                onChanged: (color) {
                  widget.color = color;
                  refreshWidget();
                })
          ])),
    ]);
  }
}

/* Box Widget */

class BoxUIWidget extends UIWidget {
  BoxUIWidget(Host host, UITree tree) : super(host, tree);

  TransformData transform = TransformData(
      width: null,
      height: null,
      left: 0,
      top: 0,
      alignment: Alignment.topLeft,
      padding: EdgeInsets.zero);

  Color color = Colors.grey;

  @override
  String getName() {
    return "Box";
  }

  @override
  Map<String, dynamic> getJson() {
    return {
      "transform": transform.toJson(),
      "color": color.value,
    };
  }

  @override
  void setJson(Map<String, dynamic> json) {
    transform = TransformData.fromJson(json["transform"]);
    color = Color(json["color"]);
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
  void deleteChildRecursive(UIWidget widget) {}

  @override
  _BoxUIWidget createState() => _BoxUIWidget();
}

class _BoxUIWidget extends UIWidgetState<BoxUIWidget> {
  @override
  Widget buildWidget(BuildContext context) {
    return TransformWidget(
      data: widget.transform,
      child: Container(
        color: widget.color,
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
        child: Container(
          color: widget.color,
        ));
  }

  @override
  Widget buildWidgetEditor(BuildContext context) {
    return Column(children: [
      EditorTitle("Container"),
      TransformWidgetEditor(
        data: widget.transform,
        onUpdate: (transform) {
          widget.transform = transform;
          refreshWidget();
        },
        tree: widget.tree,
      ),
      Section(
          title: "Style",
          child: Column(children: [
            FieldLabel(
                text: "Color",
                child: ColorField(
                  width: 150,
                  color: widget.color,
                  onChanged: (color) {
                    widget.color = color;
                    refreshWidget();
                  },
                ))
          ]))
    ]);
  }
}
*/
