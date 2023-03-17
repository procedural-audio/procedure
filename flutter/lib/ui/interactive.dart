import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter/services.dart';

import 'dart:ui' as ui;
import 'dart:typed_data';

import '../host.dart';
import '../views/variables.dart';
import 'ui.dart';
import 'common.dart';

// import 'package:flutter_inappwebview/flutter_inappwebview.dart';

class WebViewUIWidget extends UIWidget {
  WebViewUIWidget(Host host, UITree tree) : super(host, tree);

  @override
  final String name = "Web View";

  final GlobalKey webViewKey = GlobalKey();
  /*InAppWebViewSettings settings = InAppWebViewSettings(
      useShouldOverrideUrlLoading: true,
      mediaPlaybackRequiresUserGesture: false,
      allowsInlineMediaPlayback: true,
      iframeAllow: "camera; microphone",
      iframeAllowFullscreen: true);*/

  // InAppWebViewController? webViewController;

  TransformData data = TransformData(
      width: 100,
      height: 30,
      left: 0,
      top: 0,
      alignment: Alignment.topLeft,
      padding: EdgeInsets.zero);

  @override
  Map<String, dynamic> getJson() {
    return {"transform": data.toJson()};
  }

  @override
  void setJson(Map<String, dynamic> json) {
    data = TransformData.fromJson(json["transform"]);
  }

  @override
  List<UIWidget> getChildren() {
    return [];
  }

  @override
  Widget buildWidget(BuildContext context) {
    return Container();
    /*return TransformWidget(
      data: data,
      child: Container(
        color: Colors.blue,
        child: InAppWebView(
          key: webViewKey,
          initialUrlRequest: URLRequest(
              // url: WebUri("/Users/chasekanipe/Github/nodus/index.html")),
              url: WebUri("http://chasekanipe.com")),
          onWebViewCreated: (controller) {
            webViewController = controller;
          },
        ),
      ),
    );*/
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
      child: Container(color: Colors.red),
    );
  }

  @override
  Widget buildWidgetEditor(BuildContext context) {
    return Column(children: [
      EditorTitle("Web View"),
      TransformWidgetEditor(
          data: data,
          onUpdate: (t) {
            setState(() {
              data = t;
            });
          },
          tree: tree)
    ]);
  }
}

/* Knob Widget */

/*class KnobUIWidget extends UIWidget {
  KnobUIWidget(Host host, UITree tree) : super(host, tree);

  ValueNotifier<String?> varName = ValueNotifier(null);

  // Massive X large knob

  /*var style = KnobStyle(
    borderColor: Colors.grey.withOpacity(0.0),
    borderThickness: 4,
    backgroundColor: const Color.fromRGBO(160, 160, 160, 0.0),
    trackColor: const Color.fromRGBO(60, 60, 60, 1.0),
    trackThickness: 6,
    tickStart: 0.65,
    tickEnd: 0.76,
    tickThickness: 6.0,
    trackSpacing: 8.0,
    tickColor: const Color.fromRGBO(50, 50, 50, 1.0),
    knobColor: const Color.fromRGBO(50, 50, 50, 1.0),
    ringColor: const Color.fromRGBO(180, 180, 180, 1.0),
    ringThickness: 8.0,
    ringEdgeColor: const Color.fromRGBO(80, 80, 80, 1.0),
    ringEdgeThickness: 1.0,
    knobEdgeColor: const Color.fromRGBO(20, 20, 20, 1.0),
    knobEdgeThickness: 2.0,
    iconColor: const Color.fromRGBO(180, 180, 180, 1.0),
    iconPadding: 30,
    iconPath: "/home/chase/github/metasampler/content/assets/icons/speaker.svg"
  );*/

  // Vital Knob
  var style = KnobStyle(
      borderColor: Colors.grey.withOpacity(0.0),
      borderThickness: 6,
      borderSpacing: 0,
      backgroundColor: const Color.fromRGBO(30, 30, 30, 1.0),
      trackColor: const Color.fromRGBO(60, 60, 60, 1.0),
      trackThickness: 4,
      tickStart: 0.3,
      tickEnd: 0.78,
      tickThickness: 3.0,
      trackSpacing: 0.0,
      tickColor: Colors.white,
      knobColor: const Color.fromRGBO(30, 30, 30, 1.0),
      ringColor: const Color.fromRGBO(180, 180, 180, 0.0),
      ringThickness: 0.0,
      ringEdgeColor: const Color.fromRGBO(80, 80, 80, 1.0),
      ringEdgeThickness: 0.0,
      knobEdgeColor: const Color.fromRGBO(20, 20, 20, 1.0),
      knobEdgeThickness: 0.0,
      iconColor: const Color.fromRGBO(180, 180, 180, 0.0),
      iconPadding: 30,
      iconPath:
          "/home/chase/github/metasampler/content/assets/icons/speaker.svg",
      shadowBlurRadius: 0,
      shadowOffset: const Offset(0, 0),
      shadowColor: const Color.fromRGBO(0, 0, 0, 0.0));

  TransformData data = TransformData(
      width: 70,
      height: 70,
      left: 0,
      top: 0,
      alignment: Alignment.center,
      padding: EdgeInsets.zero);

  @override
  String getName() {
    return "Knob";
  }

  @override
  Map<String, dynamic> getJson() {
    return {
      "transform": data.toJson(),
      "style": style.toJson(),
      "varName": varName.value
    };
  }

  @override
  void setJson(Map<String, dynamic> json) {
    data = TransformData.fromJson(json["transform"]);
    style = KnobStyle.fromJson(json["style"]);
    varName.value = json["varName"];
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
  _KnobUIWidget createState() => _KnobUIWidget();
}

class _KnobUIWidget extends UIWidgetState<KnobUIWidget> {
  Future<ui.Image>? image;

  Future<ui.Image> _loadImage(String imagePath) async {
    ByteData bd = await rootBundle.load(imagePath);
    final Uint8List bytes = Uint8List.view(bd.buffer);
    final ui.Codec codec = await ui.instantiateImageCodec(bytes);
    final ui.Image image = (await codec.getNextFrame()).image;

    return image;
  }

  @override
  void initState() {
    super.initState();
    if (widget.style.imagePath != null) {
      image = _loadImage(widget.style.imagePath!);
    }
  }

  @override
  Widget buildWidget(BuildContext context) {
    return TransformWidget(
        data: widget.data,
        child: Knob(
            varName: widget.varName,
            style: widget.style,
            image: image,
            host: widget.host));
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
      child: Knob(
        varName: widget.varName,
        style: widget.style,
        image: image,
        host: widget.host,
      ),
    );
  }

  @override
  Widget buildWidgetEditor(BuildContext context) {
    return Column(children: [
      EditorTitle("Knob"),
      TransformWidgetEditor(
          data: widget.data,
          onUpdate: (t) {
            widget.data = t;
            refreshWidget();
          },
          tree: widget.tree),
      Section(
          title: "Variable",
          child: FieldLabel(
            text: "Value",
            child: VarField(varName: widget.varName, host: widget.host),
          )),
      Section(
          title: "Track",
          child: Column(children: [
            FieldLabel(
                text: "Primary",
                child: ColorField(
                    width: 150,
                    color: widget.style.valueColor,
                    onChanged: (c) {
                      widget.style.trackColor = c;
                      refreshWidget();
                    })),
            FieldLabel(
                text: "Secondary",
                child: ColorField(
                    width: 150,
                    color: widget.style.trackColor,
                    onChanged: (c) {
                      widget.style.trackColor = c;
                      refreshWidget();
                    })),
            FieldLabel(
                text: "Background",
                child: ColorField(
                    width: 150,
                    color: widget.style.backgroundColor,
                    onChanged: (c) {
                      widget.style.backgroundColor = c;
                      refreshWidget();
                    })),
            FieldLabel(
                text: "Thickness",
                child: Field(
                    label: "",
                    width: 60,
                    initialValue: widget.style.trackThickness.toString(),
                    onChanged: (v) {
                      widget.style.trackThickness = double.tryParse(v) ?? 0;
                      refreshWidget();
                    })),
            FieldLabel(
                text: "Spacing",
                child: Field(
                    label: "",
                    width: 60,
                    initialValue: widget.style.trackSpacing.toString(),
                    onChanged: (v) {
                      widget.style.trackSpacing = double.tryParse(v) ?? 0;
                      refreshWidget();
                    })),
            SubSection(
                title: "Border",
                child: Column(children: [
                  FieldLabel(
                      text: "Color",
                      child: ColorField(
                          width: 150,
                          color: widget.style.borderColor,
                          onChanged: (c) {
                            widget.style.borderColor = c;
                            refreshWidget();
                          })),
                  FieldLabel(
                      text: "Thickness",
                      child: Field(
                          label: "",
                          width: 60,
                          initialValue: widget.style.borderThickness.toString(),
                          onChanged: (v) {
                            widget.style.borderThickness =
                                double.tryParse(v) ?? 0;
                            refreshWidget();
                          })),
                  FieldLabel(
                      text: "Spacing",
                      child: Field(
                          label: "",
                          width: 60,
                          initialValue: widget.style.borderSpacing.toString(),
                          onChanged: (v) {
                            widget.style.borderSpacing =
                                double.tryParse(v) ?? 0;
                            refreshWidget();
                          }))
                ]))
          ]))
    ]);
  }
}

class KnobStyle {
  KnobStyle(
      {this.start = 0.1,
      this.end = 0.9,
      this.backgroundColor = const Color.fromRGBO(0, 0, 0, 0),
      this.borderColor = Colors.grey,
      this.borderThickness = 2.0,
      this.borderSpacing = 4.0,
      this.trackThickness = 4.0,
      this.trackSpacing = 4.0,
      this.trackColor = const Color.fromRGBO(0, 0, 0, 0),
      this.valueColor = Colors.blue,
      this.tickColor = Colors.white,
      this.tickThickness = 3.0,
      this.tickStart = 0.3,
      this.tickEnd = 0.9,
      this.knobColor = const Color.fromRGBO(40, 40, 40, 1.0),
      this.knobEdgeColor = const Color.fromRGBO(20, 20, 20, 1.0),
      this.knobEdgeThickness = 0.0,
      this.ringThickness = 2.0,
      this.ringColor = const Color.fromRGBO(30, 30, 30, 1.0),
      this.ringEdgeColor = const Color.fromRGBO(20, 20, 20, 1.0),
      this.ringEdgeThickness = 0.0,
      this.shadowColor = const Color.fromRGBO(0, 0, 0, 0.5),
      this.shadowOffset = const Offset(0, 10),
      this.shadowBlurRadius = 10,
      this.iconPath,
      this.iconColor = Colors.grey,
      this.iconPadding = 10,
      this.imagePath});

  static KnobStyle fromJson(Map<String, dynamic> json) {
    return KnobStyle(
        start: json["start"],
        end: json["end"],
        backgroundColor: colorFromHex(json["backgroundColor"])!,
        borderColor: colorFromHex(json["borderColor"])!,
        borderThickness: json["borderThickness"],
        borderSpacing: json["borderSpacing"],
        valueColor: colorFromHex(json["valueColor"])!,
        trackThickness: json["trackThickness"],
        trackSpacing: json["trackSpacing"],
        tickColor: colorFromHex(json["tickColor"])!,
        tickThickness: json["tickThickness"],
        tickStart: json["tickStart"],
        tickEnd: json["tickEnd"],
        trackColor: colorFromHex(json["trackColor"])!,
        knobColor: colorFromHex(json["knobColor"])!,
        ringThickness: json["ringThickness"],
        ringColor: colorFromHex(json["ringColor"])!,
        shadowColor: colorFromHex(json["shadowColor"])!,
        shadowOffset: Offset(json["shadowOffsetX"], json["shadowOffsetY"]),
        shadowBlurRadius: json["shadowBlurRadius"],
        ringEdgeColor: colorFromHex(json["ringEdgeColor"])!,
        ringEdgeThickness: json["ringEdgeThickness"],
        knobEdgeColor: colorFromHex(json["knobEdgeColor"])!,
        knobEdgeThickness: json["knobEdgeThickness"],
        iconPath: json["iconPath"],
        iconColor: colorFromHex(json["iconColor"])!,
        iconPadding: json["iconPadding"],
        imagePath: json["imagePath"]);
  }

  Map<String, dynamic> toJson() {
    return {
      "start": start,
      "end": end,
      "backgroundColor": backgroundColor.toHex(),
      "borderColor": borderColor.toHex(),
      "borderThickness": borderThickness,
      "borderSpacing": borderSpacing,
      "valueColor": valueColor.toHex(),
      "trackThickness": trackThickness,
      "trackSpacing": trackSpacing,
      "tickColor": tickColor.toHex(),
      "tickThickness": tickThickness,
      "tickStart": tickStart,
      "tickEnd": tickEnd,
      "trackColor": trackColor.toHex(),
      "knobColor": knobColor.toHex(),
      "ringThickness": ringThickness,
      "ringColor": ringColor.toHex(),
      "shadowColor": shadowColor.toHex(),
      "shadowOffsetX": shadowOffset.dx,
      "shadowOffsetY": shadowOffset.dy,
      "shadowBlurRadius": shadowBlurRadius,
      "ringEdgeColor": ringEdgeColor.toHex(),
      "ringEdgeThickness": ringEdgeThickness,
      "knobEdgeColor": knobEdgeColor.toHex(),
      "knobEdgeThickness": knobEdgeThickness,
      "iconPath": iconPath,
      "iconColor": iconColor.toHex(),
      "iconPadding": iconPadding,
      "imagePath": imagePath
    };
  }

  double start;
  double end;

  Color backgroundColor;

  Color borderColor;
  double borderThickness;
  double borderSpacing;

  Color valueColor;
  double trackThickness;
  double trackSpacing;

  Color tickColor;
  double tickThickness;
  double tickStart;
  double tickEnd;

  Color trackColor;

  Color knobColor;

  double ringThickness;
  Color ringColor;

  Color shadowColor;
  Offset shadowOffset;
  double shadowBlurRadius;

  Color ringEdgeColor;
  double ringEdgeThickness;

  Color knobEdgeColor;
  double knobEdgeThickness;

  String? iconPath;
  Color iconColor;
  double iconPadding;

  String? imagePath;
}

class Knob extends StatefulWidget {
  Knob(
      {required this.varName,
      required this.style,
      required this.image,
      required this.host});

  final ValueListenable<String?> varName;
  final KnobStyle style;
  final Future<ui.Image>? image;
  final Host host;

  @override
  State<Knob> createState() => _Knob();
}

class _Knob extends State<Knob> {
  ValueNotifier<dynamic> valueNotifier = ValueNotifier(0.0);

  @override
  Widget build(BuildContext context) {
    /*if (widget.style.imagePath != null) {
      return GestureDetector(
        onVerticalDragUpdate: (e) {
          setState(() {
            value -= e.delta.dy / 300;
            value = value.clamp(0, 1);
          });
        },
        child: FutureBuilder<ui.Image>(
          future: widget.image,
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              return CustomPaint(
                painter: ImageKnobPainter(snapshot.data!, value),
              );
            } else {
              return Container();
            }
          },
        ),
      );
    }*/

    // ^^^ SPRITE KNOB IMPLEMENTATION

    return Container(color: Colors.red);

    /*return ValueListenableBuilder<List<Var>>(
        valueListenable: widget.host.vars,
        builder: (context, vars, w) {
          return ValueListenableBuilder<String?>(
              valueListenable: widget.varName,
              builder: (context, name, w) {
                int? index;

                /*for (var v in vars) {
              if (v.name == name) {
                if (v.notifier.value is double) {
                  valueNotifier = v.notifier;
                  index = v.index;
                } else {
                  print("Variable is wrong type");
                  valueNotifier = ValueNotifier(valueNotifier.value);
                }
              }
            }*/

                return ValueListenableBuilder<dynamic>(
                    valueListenable: valueNotifier,
                    builder: (context, value, w) {
                      return GestureDetector(
                          onVerticalDragUpdate: (e) {
                            if (value is double) {
                              valueNotifier.value =
                                  (valueNotifier.value - e.delta.dy / 300)
                                      .clamp(0.0, 1.0);
                              if (index != null) {
                                // RawCoreSetVarValueFloat(widget.host.host, index, valueNotifier.value);
                              }
                            }
                          },
                          child: Container(
                              decoration: BoxDecoration(
                                  color: widget.style.backgroundColor,
                                  shape: BoxShape.circle),
                              child: Stack(fit: StackFit.expand, children: [
                                Arc(
                                    // Outer border
                                    start: widget.style.start,
                                    end: widget.style.end,
                                    thickness: widget.style.borderThickness,
                                    spacing: widget.style.borderSpacing,
                                    color: widget.style.borderColor,
                                    child:
                                        Stack(fit: StackFit.expand, children: [
                                      Arc(
                                        // Track
                                        start: widget.style.start,
                                        end: widget.style.end,
                                        thickness: widget.style.trackThickness,
                                        spacing: widget.style.trackSpacing,
                                        color: widget.style.trackColor,
                                      ),
                                      Arc(
                                        // Value
                                        start: widget.style.start,
                                        end: widget.style.start +
                                            (widget.style.end -
                                                    widget.style.start) *
                                                value,
                                        thickness: widget.style.trackThickness,
                                        spacing: widget.style.trackSpacing,
                                        color: widget.style.valueColor,
                                        /*child: Container(
                                  padding: EdgeInsets.all(widget.style.ringThickness),
                                  decoration: BoxDecoration(
                                    color: widget.style.ringColor,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: widget.style.ringEdgeColor,
                                      width: widget.style.ringEdgeThickness
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: widget.style.shadowColor,
                                        offset: widget.style.shadowOffset,
                                        blurRadius: widget.style.shadowBlurRadius
                                      )
                                    ]
                                  ),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: widget.style.knobColor,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: widget.style.knobEdgeColor,
                                        width: widget.style.knobEdgeThickness
                                      )
                                    ),
                                    child: Padding(
                                      padding: EdgeInsets.all(widget.style.iconPadding),
                                      child: widget.style.iconPath != null ? SvgPicture.file(
                                        File(widget.style.iconPath!),
                                        alignment: Alignment.center,
                                        color: widget.style.iconColor,
                                      ) : Container(),
                                    )
                                  )
                                )*/
                                      )
                                    ])),
                                CustomPaint(
                                  painter: TickPainter(
                                    value: value is double ? value : 0.0,
                                    start: widget.style.start,
                                    end: widget.style.end,
                                    thickness: widget.style.tickThickness,
                                    tickStart: widget.style.tickStart,
                                    tickEnd: widget.style.tickEnd,
                                    color: widget.style.tickColor,
                                  ),
                                )
                              ])));
                    });
              });
        });*/
  }
}

class Arc extends StatelessWidget {
  Arc(
      {required this.start,
      required this.end,
      required this.color,
      required this.thickness,
      required this.spacing,
      this.child})
      : super(key: UniqueKey());

  final double start;
  final double end;
  final Color color;
  final double thickness;
  final double spacing;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: ArcPainter(
        color: color,
        start: start,
        end: end,
        thickness: thickness,
      ),
      child: Padding(
        padding: EdgeInsets.all(thickness + spacing),
        child: child,
      ),
    );
  }
}

class ImageKnobPainter extends CustomPainter {
  ImageKnobPainter(this.image, this.value);

  ui.Image image;
  double value;

  @override
  void paint(Canvas canvas, ui.Size size) {
    print("Size is " + size.width.toString());

    if (value > 0.99) {
      value = 0.99;
    }

    double height = image.height / 128.0;
    int offset = (value * 128).toInt();

    Paint paint = Paint();
    paint.filterQuality = FilterQuality.medium;
    paint.isAntiAlias = true;

    canvas.drawImageRect(
        image,
        Rect.fromLTWH(0, height * offset, image.width + 0.0, height),
        Rect.fromLTWH(0, 0, size.width, size.height),
        paint);
  }

  @override
  bool shouldRepaint(ImageKnobPainter oldDelegate) {
    return value != oldDelegate.value;
  }
}

/* Slider Widget */

class SliderUIWidget extends UIWidget {
  SliderUIWidget(Host host, UITree tree) : super(host, tree);

  double value = 0.6;

  // Vital Knob
  var style = SliderStyle(
      trackBorderColor: Colors.grey.withOpacity(0.0),
      trackBorderThickness: 0,
      trackColor: const Color.fromRGBO(60, 60, 60, 1.0),
      trackSpacing: 0.0,
      knobColor: const Color.fromRGBO(30, 30, 30, 1.0),
      ringColor: const Color.fromRGBO(180, 180, 180, 0.0),
      ringThickness: 0.0,
      ringEdgeColor: const Color.fromRGBO(80, 80, 80, 1.0),
      ringEdgeThickness: 0.0,
      sliderEdgeColor: const Color.fromRGBO(20, 20, 20, 1.0),
      sliderEdgeThickness: 0.0,
      shadowBlurRadius: 0,
      shadowOffset: const Offset(0, 0),
      shadowColor: const Color.fromRGBO(0, 0, 0, 0.0));

  TransformData data = TransformData(
      width: 70,
      height: 70,
      left: 0,
      top: 0,
      alignment: Alignment.center,
      padding: EdgeInsets.zero);

  @override
  String getName() {
    return "Slider";
  }

  @override
  Map<String, dynamic> getJson() {
    return {"transform": data.toJson(), "style": style.toJson()};
  }

  @override
  void setJson(Map<String, dynamic> json) {
    data = TransformData.fromJson(json["transform"]);
    style = SliderStyle.fromJson(json["style"]);
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
  _SliderUIWidget createState() => _SliderUIWidget();
}

class _SliderUIWidget extends UIWidgetState<SliderUIWidget> {
  @override
  Widget buildWidget(BuildContext context) {
    return TransformWidget(
        data: widget.data,
        child: Slider(
          value: 0.6,
          style: widget.style,
        ));
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
      child: Slider(
        value: 0.6,
        style: widget.style,
      ),
    );
  }

  @override
  Widget buildWidgetEditor(BuildContext context) {
    return Column(children: [
      EditorTitle("Slider"),
      TransformWidgetEditor(
          data: widget.data,
          onUpdate: (t) {
            widget.data = t;
            refreshWidget();
          },
          tree: widget.tree),
      Section(
          title: "Slider",
          child: Column(children: [
            FieldLabel(
                text: "Color",
                child: ColorField(
                    width: 150,
                    color: widget.style.knobColor,
                    onChanged: (c) {
                      widget.style.knobColor = c;
                      refreshWidget();
                    })),
            FieldLabel(
                text: "Edge Color",
                child: ColorField(
                    width: 150,
                    color: widget.style.sliderEdgeColor,
                    onChanged: (c) {
                      widget.style.sliderEdgeColor = c;
                      refreshWidget();
                    })),
            FieldLabel(
                text: "Edge Thickness",
                child: Field(
                    label: "",
                    width: 60,
                    initialValue: widget.style.sliderEdgeThickness.toString(),
                    onChanged: (v) {
                      widget.style.sliderEdgeThickness =
                          double.tryParse(v) ?? 0;
                      refreshWidget();
                    })),
            SubSection(
                title: "Ring",
                child: Column(children: [
                  FieldLabel(
                      text: "Color",
                      child: ColorField(
                          width: 150,
                          color: widget.style.ringColor,
                          onChanged: (c) {
                            widget.style.ringColor = c;
                            refreshWidget();
                          })),
                  FieldLabel(
                      text: "Thickness",
                      child: Field(
                          label: "",
                          width: 60,
                          initialValue: widget.style.ringThickness.toString(),
                          onChanged: (v) {
                            widget.style.ringThickness =
                                double.tryParse(v) ?? 0;
                            refreshWidget();
                          })),
                  FieldLabel(
                      text: "Edge Color",
                      child: ColorField(
                          width: 150,
                          color: widget.style.ringEdgeColor,
                          onChanged: (c) {
                            widget.style.ringEdgeColor = c;
                            refreshWidget();
                          })),
                  FieldLabel(
                      text: "Edge Thickness",
                      child: Field(
                          label: "",
                          width: 60,
                          initialValue:
                              widget.style.ringEdgeThickness.toString(),
                          onChanged: (v) {
                            widget.style.ringEdgeThickness =
                                double.tryParse(v) ?? 0;
                            refreshWidget();
                          })),
                ]))
          ])),
      Section(
          title: "Track",
          child: Column(children: [
            FieldLabel(
                text: "Primary",
                child: ColorField(
                    width: 150,
                    color: widget.style.valueColor,
                    onChanged: (c) {
                      widget.style.valueColor = c;
                      refreshWidget();
                    })),
            FieldLabel(
                text: "Secondary",
                child: ColorField(
                    width: 150,
                    color: widget.style.trackColor,
                    onChanged: (c) {
                      widget.style.trackColor = c;
                      refreshWidget();
                    })),
            FieldLabel(
                text: "Spacing",
                child: Field(
                    label: "",
                    width: 60,
                    initialValue: widget.style.trackSpacing.toString(),
                    onChanged: (v) {
                      widget.style.trackSpacing = double.tryParse(v) ?? 0;
                      refreshWidget();
                    })),
            FieldLabel(
                text: "Corner Radius",
                child: Field(
                    label: "",
                    width: 60,
                    initialValue: widget.style.trackBorderRadius.toString(),
                    onChanged: (v) {
                      widget.style.trackBorderRadius = double.tryParse(v) ?? 0;
                      refreshWidget();
                    })),
            SubSection(
                title: "Border",
                child: Column(children: [
                  FieldLabel(
                      text: "Color",
                      child: ColorField(
                          width: 150,
                          color: widget.style.trackBorderColor,
                          onChanged: (c) {
                            widget.style.trackBorderColor = c;
                            refreshWidget();
                          })),
                  FieldLabel(
                      text: "Thickness",
                      child: Field(
                          label: "",
                          width: 60,
                          initialValue:
                              widget.style.trackBorderThickness.toString(),
                          onChanged: (v) {
                            widget.style.trackBorderThickness =
                                double.tryParse(v) ?? 0;
                            refreshWidget();
                          }))
                ]))
          ])),
      Section(
          title: "Shadow",
          child: Column(children: [
            FieldLabel(
                text: "Color",
                child: ColorField(
                    width: 150,
                    color: widget.style.shadowColor,
                    onChanged: (c) {
                      widget.style.shadowColor = c;
                      refreshWidget();
                    })),
            FieldLabel(
                text: "Blur Radius",
                child: Field(
                    label: "",
                    width: 60,
                    initialValue: widget.style.shadowBlurRadius.toString(),
                    onChanged: (v) {
                      widget.style.shadowBlurRadius = double.tryParse(v) ?? 0;
                      refreshWidget();
                    })),
            FieldLabel(
                text: "Offset",
                child: Row(children: [
                  Expanded(
                    child: Container(),
                  ),
                  Field(
                      label: "X",
                      width: 70,
                      initialValue: widget.style.shadowOffset.dx.toString(),
                      onChanged: (v) {
                        widget.style.shadowOffset = Offset(
                            widget.style.shadowOffset.dx,
                            double.tryParse(v) ?? 0);

                        refreshWidget();
                      }),
                  Field(
                      label: "Y",
                      width: 70,
                      initialValue: widget.style.shadowOffset.dy.toString(),
                      onChanged: (v) {
                        widget.style.shadowOffset = Offset(
                            widget.style.shadowOffset.dx,
                            double.tryParse(v) ?? 0);

                        refreshWidget();
                      })
                ]))
          ]))
    ]);
  }
}

class SliderStyle {
  SliderStyle({
    this.trackBorderColor = const Color.fromRGBO(0, 0, 0, 0),
    this.trackBorderThickness = 4.0,
    this.trackBorderRadius = 4.0,
    this.trackSpacing = 4.0,
    this.trackColor = const Color.fromRGBO(0, 0, 0, 0),
    this.valueColor = Colors.blue,
    this.knobColor = const Color.fromRGBO(40, 40, 40, 1.0),
    this.sliderEdgeColor = const Color.fromRGBO(20, 20, 20, 1.0),
    this.sliderEdgeThickness = 0.0,
    this.ringThickness = 2.0,
    this.ringColor = const Color.fromRGBO(30, 30, 30, 1.0),
    this.ringEdgeColor = const Color.fromRGBO(20, 20, 20, 1.0),
    this.ringEdgeThickness = 0.0,
    this.shadowColor = const Color.fromRGBO(0, 0, 0, 0.5),
    this.shadowOffset = const Offset(0, 10),
    this.shadowBlurRadius = 10,
  });

  static SliderStyle fromJson(Map<String, dynamic> json) {
    return SliderStyle(
      trackBorderColor: colorFromHex(json["trackBorderColor"])!,
      trackBorderThickness: json["trackBorderThickness"],
      trackBorderRadius: json["trackBorderRadius"],
      valueColor: colorFromHex(json["valueColor"])!,
      trackSpacing: json["trackSpacing"],
      trackColor: colorFromHex(json["trackColor"])!,
      knobColor: colorFromHex(json["knobColor"])!,
      ringThickness: json["ringThickness"],
      ringColor: colorFromHex(json["ringColor"])!,
      shadowColor: colorFromHex(json["shadowColor"])!,
      shadowOffset: Offset(json["shadowOffsetX"], json["shadowOffsetY"]),
      shadowBlurRadius: json["shadowBlurRadius"],
      ringEdgeColor: colorFromHex(json["ringEdgeColor"])!,
      ringEdgeThickness: json["ringEdgeThickness"],
      sliderEdgeColor: colorFromHex(json["sliderEdgeColor"])!,
      sliderEdgeThickness: json["sliderEdgeThickness"],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "trackBorderColor": trackBorderColor.toHex(),
      "trackBorderThickness": trackBorderThickness,
      "trackBorderRadius": trackBorderRadius,
      "valueColor": valueColor.toHex(),
      "trackSpacing": trackSpacing,
      "trackColor": trackColor.toHex(),
      "knobColor": knobColor.toHex(),
      "ringThickness": ringThickness,
      "ringColor": ringColor.toHex(),
      "shadowColor": shadowColor.toHex(),
      "shadowOffsetX": shadowOffset.dx,
      "shadowOffsetY": shadowOffset.dy,
      "shadowBlurRadius": shadowBlurRadius,
      "ringEdgeColor": ringEdgeColor.toHex(),
      "ringEdgeThickness": ringEdgeThickness,
      "sliderEdgeColor": sliderEdgeColor.toHex(),
      "sliderEdgeThickness": sliderEdgeThickness,
    };
  }

  Color trackBorderColor;

  double trackBorderThickness;
  double trackBorderRadius;

  Color valueColor;
  double trackSpacing;

  Color trackColor;

  Color knobColor;

  double ringThickness;
  Color ringColor;

  Color shadowColor;
  Offset shadowOffset;
  double shadowBlurRadius;

  Color ringEdgeColor;
  double ringEdgeThickness;

  Color sliderEdgeColor;
  double sliderEdgeThickness;
}

class Slider extends StatefulWidget {
  Slider({required this.value, required this.style});

  final double value;
  final SliderStyle style;

  @override
  State<Slider> createState() => _Slider();
}

class _Slider extends State<Slider> {
  late double value;

  @override
  void initState() {
    super.initState();
    value = widget.value;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      return GestureDetector(
        behavior: HitTestBehavior.translucent,
        onVerticalDragUpdate: (e) {
          setState(() {
            value = (constraints.maxHeight -
                    e.localPosition.dy.clamp(0, constraints.maxHeight)) /
                constraints.maxHeight;
          });
        },
        /*onTapDown: (e) {
            setState(() {
              value = (constraints.maxHeight - e.localPosition.dy.clamp(0, constraints.maxHeight)) / constraints.maxHeight;
            });
          },*/
        child: Stack(
          fit: StackFit.expand,
          children: [
            Container(
              width: constraints.maxWidth,
              height: constraints.maxHeight,
              color: widget.style.trackColor,
            ),
            Align(
                alignment: Alignment.bottomCenter,
                child: Container(
                  width: constraints.maxWidth,
                  height: constraints.maxHeight * value,
                  color: widget.style.valueColor,
                )),
            Padding(
              padding:
                  EdgeInsets.fromLTRB(0, 0, 0, constraints.maxHeight * value),
              child: Align(
                  alignment: Alignment.bottomCenter,
                  child: Container(
                      width: 40,
                      height: 40,
                      padding: EdgeInsets.all(widget.style.ringThickness),
                      decoration: BoxDecoration(
                          color: widget.style.ringColor,
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: widget.style.ringEdgeColor,
                              width: widget.style.ringEdgeThickness),
                          boxShadow: [
                            BoxShadow(
                                color: widget.style.shadowColor,
                                offset: widget.style.shadowOffset,
                                blurRadius: widget.style.shadowBlurRadius)
                          ]),
                      child: Container(
                          decoration: BoxDecoration(
                              color: widget.style.knobColor,
                              shape: BoxShape.circle,
                              border: Border.all(
                                  color: widget.style.sliderEdgeColor,
                                  width: widget.style.sliderEdgeThickness))))),
            )
          ],
        ),
      );
    });
  }
}

class ArcPainter extends CustomPainter {
  ArcPainter({
    required this.start,
    required this.end,
    required this.color,
    required this.thickness,
  });

  final double start;
  final double end;
  final Color color;
  final double thickness;

  @override
  void paint(Canvas canvas, Size size) {
    var paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = thickness;

    canvas.drawArc(
        Rect.fromCenter(
            center: Offset(size.width / 2, size.height / 2),
            width: size.width - thickness,
            height: size.height - thickness),
        (pi / 2 + start * 2 * pi),
        (end * 2 * pi) - (start * 2 * pi),
        false,
        paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

class TickPainter extends CustomPainter {
  TickPainter({
    required this.value,
    required this.start,
    required this.end,
    required this.color,
    required this.thickness,
    required this.tickStart,
    required this.tickEnd,
  });

  final double value;
  final double start;
  final double end;
  final Color color;
  final double thickness;
  final double tickStart;
  final double tickEnd;

  @override
  void paint(Canvas canvas, Size size) {
    var paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = thickness;

    var startOffset = Offset(
        size.width / 2 +
            cos(pi / 2 + 2 * pi * start + 2 * pi * value * (end - start)) *
                size.width /
                2 *
                tickStart,
        size.height / 2 +
            sin(pi / 2 + 2 * pi * start + 2 * pi * value * (end - start)) *
                size.height /
                2 *
                tickStart);

    var endOffset = Offset(
        size.width / 2 +
            cos(pi / 2 + 2 * pi * start + 2 * pi * value * (end - start)) *
                size.width /
                2 *
                tickEnd,
        size.height / 2 +
            sin(pi / 2 + 2 * pi * start + 2 * pi * value * (end - start)) *
                size.height /
                2 *
                tickEnd);

    canvas.drawLine(startOffset, endOffset, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
*/

/* Button Widget */

class ButtonUIWidget extends UIWidget {
  ButtonUIWidget(Host host, UITree tree) : super(host, tree);

  bool down = false;
  bool isToggle = false;

  // Vital Knob
  var style = ButtonStyle(down: null, up: null);

  TransformData data = TransformData(
      width: 70,
      height: 70,
      left: 0,
      top: 0,
      alignment: Alignment.center,
      padding: EdgeInsets.zero);

  @override
  final String name = "Button";

  @override
  Map<String, dynamic> getJson() {
    return {
      "isToggle": isToggle,
      "down": down,
      "transform": data.toJson(),
      "style": style.toJson()
    };
  }

  @override
  void setJson(Map<String, dynamic> json) {
    isToggle = json["isToggle"];
    down = json["down"];
    data = TransformData.fromJson(json["transform"]);
    style = ButtonStyle.fromJson(json["style"]);
  }

  @override
  List<UIWidget> getChildren() {
    return [];
  }

  @override
  Widget buildWidget(BuildContext context) {
    return TransformWidget(
        data: data,
        child: Button(
          down: down,
          style: style,
          onUpdate: (d) {
            if (isToggle) {
              if (d) {
                down = !down;
              }
            } else {
              down = d;
            }
            setState(() {});
          },
        ));
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
        child: Button(down: down, style: style, onUpdate: (v) {}));
  }

  @override
  Widget buildWidgetEditor(BuildContext context) {
    return Column(children: [
      EditorTitle("Button"),
      TransformWidgetEditor(
          data: data,
          onUpdate: (t) {
            data = t;
            setState(() {});
          },
          tree: tree),
      Section(
          title: "Style",
          child: Column(children: [
            FieldLabel(
                text: "Down",
                child: FileField(
                    path: style.down,
                    extensions: const ["jpg", "jpeg", "png"],
                    onChanged: (s) {
                      style.down = s;
                      setState(() {});
                    })),
            FieldLabel(
                text: "Up",
                child: FileField(
                    path: style.up,
                    extensions: const ["jpg", "jpeg", "png"],
                    onChanged: (s) {
                      style.up = s;
                      setState(() {});
                    })),
            FieldLabel(
                text: "Toggle",
                child: Padding(
                    padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
                    child: Checkbox(
                        value: isToggle,
                        onChanged: (b) {
                          if (b != null) {
                            isToggle = b;
                            setState(() {});
                          }
                        })))
          ])),
    ]);
  }
}

class ButtonStyle {
  ButtonStyle({required this.down, required this.up});

  static ButtonStyle fromJson(Map<String, dynamic> json) {
    return ButtonStyle(down: json["down"], up: json["up"]);
  }

  Map<String, dynamic> toJson() {
    return {"up": up, "down": down};
  }

  String? down;
  String? up;
}

class Button extends StatelessWidget {
  Button({required this.down, required this.onUpdate, required this.style});

  final bool down;
  final void Function(bool) onUpdate;
  final ButtonStyle style;

  @override
  Widget build(BuildContext context) {
    return Listener(onPointerDown: (e) {
      onUpdate(true);
    }, onPointerUp: (e) {
      onUpdate(false);
    }, child: Builder(builder: (context) {
      if (down) {
        if (style.down != null) {
          return Image.file(File(style.down!), fit: BoxFit.fill);
        } else {
          return Container(
            color: Colors.blue,
          );
        }
      } else {
        if (style.up != null) {
          return Image.file(File(style.up!), fit: BoxFit.fill);
        } else {
          return Container(
            color: Colors.grey,
          );
        }
      }
    }));
  }
}
