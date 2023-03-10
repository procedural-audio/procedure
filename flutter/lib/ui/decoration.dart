import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../host.dart';
import 'ui.dart';
import 'layout.dart';
import 'common.dart';

import 'dart:io';

class TextUIWidget extends UIWidget {
  TextUIWidget(Host host, UITree tree) : super(host, tree);

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
  List<UIWidget> getChildren() {
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
          toggleEditor();
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

/* Image Widget */

class ImageUIWidget extends UIWidget {
  ImageUIWidget(Host host, UITree tree) : super(host, tree);

  // String? path = "/home/chase/github/metasampler/content/assets/backgrounds/background_02.png";
  String? path =
      "/Users/chasekanipe/Github/content/assets/backgrounds/background_02.png";

  TransformData data = TransformData(
      width: null,
      height: null,
      left: 0,
      top: 0,
      alignment: Alignment.topLeft,
      padding: EdgeInsets.zero);

  @override
  final String name = "Image";

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
  List<UIWidget> getChildren() {
    return [];
  }

  @override
  Widget buildWidget(BuildContext context) {
    return TransformWidget(
        data: data,
        child: path != null
            ? Stack(fit: StackFit.expand, children: [
                Image.file(
                  File(path!),
                  repeat: ImageRepeat.noRepeat,
                  fit: BoxFit.fill,
                )
              ])
            : Container());
  }

  @override
  Widget buildWidgetEditing(BuildContext context) {
    return TransformWidgetEditing(
        data: data,
        onTap: () {
          toggleEditor();
        },
        onUpdate: (v) {
          data = v;
          setState(() {});
        },
        tree: tree,
        child: path != null
            ? Image.file(
                File(path!),
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
        data: data,
        onUpdate: (v) {
          data = v;
          setState(() {});
        },
        tree: tree,
      ),
      Section(
          title: "File",
          child: Row(children: [
            FileField(
              width: 260,
              extensions: const ["png", "jpg", "jpeg"],
              path: path,
              onChanged: (s) {
                path = s;
                setState(() {});
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
  final String name = "Icon";

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
  List<UIWidget> getChildren() {
    return [];
  }

  @override
  Widget buildWidget(BuildContext context) {
    return TransformWidget(
        data: data,
        child: path != null
            ? SvgPicture.file(
                File(path!),
                color: color,
              )
            : Container());
  }

  @override
  Widget buildWidgetEditing(BuildContext context) {
    return TransformWidgetEditing(
        data: data,
        onTap: () {
          toggleEditor();
        },
        onUpdate: (t) {
          data = t;
          setState(() {});
        },
        tree: tree,
        child: path != null
            ? SvgPicture.file(
                File(path!),
                color: color,
              )
            : Container());
  }

  @override
  Widget buildWidgetEditor(BuildContext context) {
    return Column(children: [
      EditorTitle("Icon"),
      TransformWidgetEditor(
        data: data,
        onUpdate: (v) {
          data = v;
          setState(() {});
        },
        tree: tree,
      ),
      Section(
          title: "Path",
          child: Row(children: [
            FileField(
              width: 260,
              path: path,
              extensions: const ["svg"],
              onChanged: (s) {
                path = s;
                setState(() {});
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
                color: color,
                onChanged: (color) {
                  color = color;
                  setState(() {});
                })
          ])),
    ]);
  }
}

/* Box Widget */

class BoxUIWidget extends UIWidget {
  BoxUIWidget(Host host, UITree tree) : super(host, tree);

  double borderRadius = 0.0;
  double borderThickness = 0.0;
  Color borderColor = Colors.grey;

  TransformData transform = TransformData(
      width: null,
      height: null,
      left: 0,
      top: 0,
      alignment: Alignment.topLeft,
      padding: EdgeInsets.zero);

  Color color = Colors.grey;

  @override
  String name = "Box";

  @override
  Map<String, dynamic> getJson() {
    return {
      "transform": transform.toJson(),
      "borderRadius": borderRadius,
      "borderThickness": borderThickness,
      "borderColor": borderColor.value,
      "color": color.value,
    };
  }

  @override
  void setJson(Map<String, dynamic> json) {
    transform = TransformData.fromJson(json["transform"]);
    borderRadius = json["borderRadius"];
    borderThickness = json["borderThickness"];
    borderColor = Color(json["borderColor"]);
    color = Color(json["color"]);
  }

  @override
  List<UIWidget> getChildren() {
    return [];
  }

  @override
  Widget buildWidget(BuildContext context) {
    return TransformWidget(
        data: transform,
        child: Container(
            decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.all(Radius.circular(borderRadius)),
                border:
                    Border.all(color: borderColor, width: borderThickness))));
  }

  @override
  Widget buildWidgetEditing(BuildContext context) {
    return TransformWidgetEditing(
        data: transform,
        onTap: () {
          toggleEditor();
        },
        onUpdate: (transform) {
          transform = transform;
          setState(() {});
        },
        tree: tree,
        child: Container(
            decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.all(Radius.circular(borderRadius)),
                border:
                    Border.all(color: borderColor, width: borderThickness))));
  }

  @override
  Widget buildWidgetEditor(BuildContext context) {
    return Column(children: [
      EditorTitle("Container"),
      TransformWidgetEditor(
        data: transform,
        onUpdate: (transform) {
          transform = transform;
          setState(() {});
        },
        tree: tree,
      ),
      Section(
          title: "Style",
          child: Column(children: [
            FieldLabel(
                text: "Color",
                child: ColorField(
                    width: 150,
                    color: color,
                    onChanged: (c) {
                      color = c;
                      setState(() {});
                    }))
          ])),
      Section(
          title: "Border",
          child: Column(children: [
            FieldLabel(
                text: "Radius",
                child: Field(
                    label: "PX",
                    initialValue: borderRadius.toString(),
                    onChanged: (s) {
                      borderRadius = double.tryParse(s) ?? 0.0;
                      setState(() {});
                    })),
            FieldLabel(
                text: "Thickness",
                child: Field(
                    label: "PX",
                    initialValue: borderThickness.toString(),
                    onChanged: (s) {
                      borderThickness = double.tryParse(s) ?? 0.0;
                      setState(() {});
                    })),
            FieldLabel(
                text: "Color",
                child: ColorField(
                    width: 150,
                    color: color,
                    onChanged: (c) {
                      color = c;
                      setState(() {});
                    }))
          ]))
    ]);
  }
}
