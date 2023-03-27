import 'package:ffi/ffi.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import 'dart:ffi';

import 'main.dart';
import 'patch.dart';

import 'widgets/widget.dart';
import 'views/variables.dart';
import 'views/settings.dart';

import 'core.dart';

class ModuleInfo extends StatelessWidget {
  ModuleInfo(this.rawInfo, this.id, this.name, this.path, this.color);

  static ModuleInfo from(RawModuleInfo rawInfo) {
    print("Found module " + rawInfo.getModulePath().join("/"));

    return ModuleInfo(
      rawInfo,
      rawInfo.getModuleId(),
      rawInfo.getModuleName(),
      rawInfo.getModulePath(),
      rawInfo.getModuleColor(),
    );
  }

  RawModuleInfo rawInfo;
  final String id;
  final String name;
  List<String> path;
  Color color;

  /*RawModule create() {
    return ffiModuleInfoCreate(rawInfo);
  }*/

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(5),
      child: Row(
        children: [
          Container(
            width: 20,
            height: 10,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            name,
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

class Node extends StatelessWidget {
  Node(this.rawNode) {
    print("Creating module now");

    id = rawNode.getId();
    position.value = Offset(rawNode.getX() + 0.0, rawNode.getY() + 0.0);
    size = Offset(rawNode.getWidth() + 0.0, rawNode.getHeight() + 0.0);
    name = rawNode.getName();
    color = rawNode.getColor();

    int inputsCount = rawNode.getInputPinsCount();
    int outputsCount = rawNode.getOutputPinsCount();

    /*for (int i = 0; i < inputsCount; i++) {
      var pin = Pin();

      pin.moduleId = id;
      pin.index = i;
      pin.name = raw.getInputPinName(i);
      var kind = raw.getInputPinType(i);

      if (kind == 1) {
        pin.type = IO.audio;
      } else if (kind == 2) {
        pin.type = IO.midi;
      } else if (kind == 3) {
        pin.type = IO.control;
      } else if (kind == 4) {
        pin.type = IO.time;
      } else if (kind == 5) {
        pin.type = IO.external;
      }

      if (pin.type != IO.external) {
        pin.offset = Offset(10, 0.0 + raw.getInputPinY(i));
      }

      pin.isInput = true;
      pins.add(pin);
    }

    for (int i = 0; i < outputsCount; i++) {
      var pin = Pin();

      pin.moduleId = id;
      pin.index = i + inputsCount;

      var name = raw.getOutputPinName(i);
      var kind = raw.getOutputPinType(i);

      if (kind == 1) {
        pin.type = IO.audio;
      } else if (kind == 2) {
        pin.type = IO.midi;
      } else if (kind == 3) {
        pin.type = IO.control;
      } else if (kind == 4) {
        pin.type = IO.time;
      } else {
        pin.type = IO.external;
      }

      if (pin.type != IO.external) {
        pin.offset = Offset(size.dx - 25, 0.0 + raw.getOutputPinY(i));
      }

      pin.isInput = false;
      pins.add(pin);
    }*/

    var widgetRaw = rawNode.getWidgetRoot();
    var widget = createWidget(rawNode, widgetRaw);
    if (widget != null) {
      widgets.add(widget);
    }
  }

  final RawNode rawNode;
  int id = 1;
  String name = "Name";
  Color color = Colors.grey;
  Offset size = const Offset(250, 250);
  ValueNotifier<Offset> position = ValueNotifier(const Offset(100, 100));
  // List<Pin> pins = <Pin>[];
  List<ModuleWidget> widgets = <ModuleWidget>[];

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Offset>(
      valueListenable: position,
      builder: (context, p, child) {
        return Positioned(
          left: p.dx,
          top: p.dy,
          child: GestureDetector(
            onPanUpdate: (details) {
              var x = rawNode.getX() + details.delta.dx;
              var y = rawNode.getY() + details.delta.dy;
              rawNode.setX(x);
              rawNode.setY(y);
              position.value = Offset(x, y);
            },
            child: Container(
              width: size.dx,
              height: size.dy,
              decoration: const BoxDecoration(
                color: Color.fromRGBO(40, 40, 40, 1.0),
                borderRadius: BorderRadius.all(Radius.circular(10)),
              ),
              child: Stack(
                children: [
                  Align(
                    alignment: Alignment.topCenter,
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Text(
                        name,
                        style: TextStyle(
                          color: color,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                  Stack(
                    children: widgets,
                  )
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/*class Module extends StatefulWidget {
  var id = 1;
  var name = "Name";
  var position = const Offset(100, 100);
  var size = const Offset(250, 250);
  var pins = <Pin>[];
  var widgets = <ModuleWidget>[];
  var color = Color(0x0);

  final RawNode raw;
  final App app;

  Module(this.app, this.raw) {
    print("Creating module now");

    id = raw.getId();
    position = Offset(raw.getX() + 0.0, raw.getY() + 0.0);
    size = Offset(raw.getWidth() + 0.0, raw.getHeight() + 0.0);

    int inputsCount = raw.getInputPinsCount();
    int outputsCount = raw.getOutputPinsCount();
    String name = raw.getName();
    Color color = raw.getColor();

    for (int i = 0; i < inputsCount; i++) {
      var pin = Pin();

      pin.moduleId = id;
      pin.index = i;
      pin.name = raw.getInputPinName(i);
      var kind = raw.getInputPinType(i);

      if (kind == 1) {
        pin.type = IO.audio;
      } else if (kind == 2) {
        pin.type = IO.midi;
      } else if (kind == 3) {
        pin.type = IO.control;
      } else if (kind == 4) {
        pin.type = IO.time;
      } else if (kind == 5) {
        pin.type = IO.external;
      }

      if (pin.type != IO.external) {
        pin.offset = Offset(10, 0.0 + raw.getInputPinY(i));
      }

      pin.isInput = true;
      pins.add(pin);
    }

    for (int i = 0; i < outputsCount; i++) {
      var pin = Pin();

      pin.moduleId = id;
      pin.index = i + inputsCount;

      var name = raw.getOutputPinName(i);
      var kind = raw.getOutputPinType(i);

      if (kind == 1) {
        pin.type = IO.audio;
      } else if (kind == 2) {
        pin.type = IO.midi;
      } else if (kind == 3) {
        pin.type = IO.control;
      } else if (kind == 4) {
        pin.type = IO.time;
      } else {
        pin.type = IO.external;
      }

      if (pin.type != IO.external) {
        pin.offset = Offset(size.dx - 25, 0.0 + raw.getOutputPinY(i));
      }

      pin.isInput = false;
      pins.add(pin);
    }

    var widgetRaw = raw.getWidgetRoot();
    var widget = createWidget(app, raw, widgetRaw);
    if (widget != null) {
      widgets.add(widget);
    }
  }

  @override
  State<Module> createState() => _Module();
}

class _Module extends State<Module> {
  @override
  Widget build(BuildContext context) {
    bool resizable = widget.raw.getResizable();
    var width = widget.raw.getWidth();
    var height = widget.raw.getHeight();

    final inputPins = <PinWidget>[];
    final outputPins = <PinWidget>[];
    final widgets = <Widget>[];

    widgets.addAll(widget.widgets);

    widgets.add(Container(
        padding: const EdgeInsets.all(10),
        child: Align(
            alignment: Alignment.topCenter,
            child: Text(
              widget.name,
              style: TextStyle(
                  color: widget.color,
                  fontSize: 16,
                  fontWeight: FontWeight.normal,
                  decoration: TextDecoration.none),
            ))));

    /*
    Dropdown elements:
     - Module info
     - Duplicate
     - Delete

    */

    /*widgets.add(Align(
        alignment: Alignment.topCenter,
        child: Container(
          padding: const EdgeInsets.fromLTRB(35, 7, 35, 0),
          child: SearchableDropdown(
              value: widget.name,
              onSelect: (s) {},
              decoration: const BoxDecoration(),
              titleStyle: TextStyle(color: widget.color, fontSize: 16),
              categories: [
                Category(name: "Category 1", elements: [
                  CategoryElement("Element 1"),
                  CategoryElement("Element 2"),
                  CategoryElement("Element 3"),
                  CategoryElement("Element 4"),
                ]),
                Category(name: "Category 2", elements: [
                  CategoryElement("Element 5"),
                  CategoryElement("Element 6"),
                  CategoryElement("Element 7"),
                  CategoryElement("Element 8"),
                ])
              ]),
        )));*/

    for (var pin in widget.pins) {
      if (pin.isInput) {
        if (pin.type != IO.external) {
          inputPins.add(PinWidget(
            widget.id,
            pin.index,
            pin.type,
            10,
            pin.offset.dy,
            pin.name,
            pin.isInput,
            widget.app,
          ));
        }
      } else {
        pin.offset = Offset(width - 25, pin.offset.dy);

        if (pin.type != IO.external) {
          outputPins.add(PinWidget(
            widget.id,
            pin.index,
            pin.type,
            width - 25,
            pin.offset.dy,
            pin.name,
            pin.isInput,
            widget.app,
          ));
        }
      }
    }

    return Positioned(
      left: widget.position.dx,
      top: widget.position.dy,
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () {
          print("TODO: Tap module");
          /*if (widget.app.selectedModule == widget.id) {
                widget.app.selectedModule = -1;
                setState(() {});
              } else {
                var oldModule = widget.app.selectedModule;
                widget.app.selectedModule = widget.id;

                for (var moduleWidget in widget.app.graph.moduleWidgets) {
                  if (moduleWidget.module.id == oldModule) {
                    moduleWidget.refresh();
                  }
                }

                setState(() {});
              }*/
        },
        onSecondaryTap: () {
          print("Secondary tap module");
        },
        onPanUpdate: (details) {
          widget.raw.setX(widget.position.dx.toInt());
          widget.raw.setY(widget.position.dy.toInt());

          setState(() {
            widget.position = Offset(widget.position.dx + details.delta.dx,
                widget.position.dy + details.delta.dy);
          });
        },
        child: DragTarget<Var>(
          builder: (context, candidateData, rejectedData) {
            return Container(
              width: width,
              height: height,
              decoration: BoxDecoration(
                color: MyTheme.greyMid,
                borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(10),
                    topRight: Radius.circular(10),
                    bottomLeft: Radius.circular(10),
                    bottomRight: Radius.circular(10)),
                boxShadow: widget.app.selectedModule == widget.id
                    ? [
                        BoxShadow(
                            color: Colors.white.withOpacity(0.5),
                            spreadRadius: 2,
                            blurRadius: 0,
                            offset: const Offset(0, 0)),
                        BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            spreadRadius: 5,
                            blurRadius: 15,
                            offset: const Offset(0, 5)),
                      ]
                    : [
                        BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            spreadRadius: 5,
                            blurRadius: 15,
                            offset: const Offset(0, 5)),
                      ],
              ),
              child: Stack(
                fit: StackFit.expand,
                children: widgets +
                    inputPins +
                    outputPins +
                    (resizable
                        ? ([
                            Align(
                              alignment: Alignment.bottomRight,
                              child: SizedBox(
                                width: 30,
                                height: 30,
                                child: GestureDetector(
                                  child: const Icon(
                                    Icons.drag_indicator,
                                    color: Colors.grey,
                                  ),
                                  onPanUpdate: (details) {
                                    setState(() {
                                      var m = widget.app.zoom * 10;

                                      var w = width + details.delta.dx * m;
                                      var h = height + details.delta.dy * m;

                                      var minWidth = widget.raw.getMinWidth();
                                      var maxWidth = widget.raw.getMaxWidth();
                                      var minHeight = widget.raw.getMinHeight();
                                      var maxHeight = widget.raw.getMaxHeight();

                                      if (w < minWidth) {
                                        w = minWidth.toDouble();
                                      }

                                      if (w > maxWidth) {
                                        w = maxWidth.toDouble();
                                      }

                                      if (h < minHeight) {
                                        h = minHeight.toDouble();
                                      }

                                      if (h > maxHeight) {
                                        h = maxHeight.toDouble();
                                      }

                                      widget.raw.setWidth(w);
                                      widget.raw.setHeight(h);

                                      widget.size = Offset(w, h);
                                    });
                                  },
                                ),
                              ),
                            ),
                          ])
                        : []),
              ),
            );
          },
        ),
      ),
    );
  }
}*/

/*class Connector {
  var start = Pin();
  var end = Pin();
  var type = IO.audio;

  Connector(int startId, int startIndex, int endId, int endIndex, IO t) {
    start.moduleId = startId;
    start.index = startIndex;
    end.moduleId = endId;
    end.index = endIndex;
    type = t;
  }
}*/

enum IO { audio, midi, control, time, external }

/*class Pin {
  var moduleId = 1;
  var index = 1;
  var type = IO.audio;
  var offset = const Offset(15, 15);
  var isInput = true;
  String name = "Unknown";
}

class PinLabel extends StatelessWidget {
  PinLabel(this.name);

  String name;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 5, 10, 5),
      height: 30,
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          name,
          style: TextStyle(
            color: Colors.white.withOpacity(0.8),
            fontWeight: FontWeight.w300,
          ),
        ),
      ),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.2),
        border: Border.all(
          color: const Color.fromRGBO(50, 50, 50, 1.0),
          width: 0.0,
        ),
        borderRadius: BorderRadius.circular(5),
      ),
    );
  }
}

class PinWidget extends StatefulWidget {
  PinWidget(
    int moduleId1,
    int pinIndex1,
    IO io1,
    double x1,
    double y1,
    String n,
    bool isInput,
    this.app,
  ) : super(key: UniqueKey()) {
    io = io1;
    x = x1;
    y = y1;
    moduleId = moduleId1;
    pinIndex = pinIndex1;
    name = n;
    input = isInput;
  }

  App app;

  double x = 0;
  double y = 0;
  IO io = IO.audio;
  var moduleId = -1;
  var pinIndex = -1;
  bool input = true;

  late String name;

  @override
  State<StatefulWidget> createState() => _PinState();
}

class _PinState extends State<PinWidget> {
  bool dragging = false;
  bool hovering = false;

  @override
  Widget build(BuildContext context) {
    var color = MyTheme.audio;

    var connected = false;

    if (widget.io == IO.midi) {
      color = Colors.green;
    } else if (widget.io == IO.control) {
      color = Colors.red;
    } else if (widget.io == IO.time) {
      color = Colors.deepPurpleAccent;
    }

    /*for (var connector in widget.app.project.value.patch.value.connectors) {
      if (connector.start.moduleId == widget.moduleId &&
          connector.start.index == widget.pinIndex) {
        connected = true;
      }
      if (connector.end.moduleId == widget.moduleId &&
          connector.end.index == widget.pinIndex) {
        connected = true;
      }
    }*/

    var glowing = dragging || hovering || connected;

    return Positioned(
      left: widget.x,
      top: widget.y,
      child: Container(
        width: 15,
        height: 15,
        child: MouseRegion(
          onEnter: (PointerEnterEvent event) {
            widget.app.pinLabel.value = widget.name;

            if (widget.input) {
              widget.app.labelPosition = Offset(
                  event.position.dx - 50 - widget.app.pinLabel.value.length * 7,
                  event.position.dy - 15);
            } else {
              widget.app.labelPosition =
                  Offset(event.position.dx + 30, event.position.dy - 15);
            }

            setState(() {
              hovering = true;
              widget.app.tempConnector?.hoveringId = widget.moduleId;
              widget.app.tempConnector?.hoveringIndex = widget.pinIndex;
            });
          },
          onExit: (PointerExitEvent event) {
            widget.app.pinLabel.value = "";

            setState(() {
              hovering = false;
              widget.app.tempConnector?.hoveringId = -1;
              widget.app.tempConnector?.hoveringIndex = -1;
            });
          },
          child: GestureDetector(
            onPanStart: (details) {
              setState(() {
                dragging = true;
                widget.app.tempConnector = TempConnector();
                widget.app.tempConnector?.moduleId = widget.moduleId;
                widget.app.tempConnector?.pinIndex = widget.pinIndex;
                widget.app.tempConnector?.type = widget.io;
              });
            },
            onPanUpdate: (details) {
              widget.app.tempConnector?.endX = details.localPosition.dx;
              widget.app.tempConnector?.endY = details.localPosition.dy;
              gTempConnectorState?.refresh();
            },
            onPanEnd: (details) {
              var c = widget.app.tempConnector ?? TempConnector();
              if (c.hoveringId != -1) {
                /*if (widget.app.project.value.patch.value.addConnection(
                    Connector(c.moduleId, c.pinIndex, c.hoveringId,
                        c.hoveringIndex, c.type))) {
                  gConnectorsState?.refreshConnectors();
                }*/
              }

              widget.app.tempConnector = null;
              gTempConnectorState?.refresh();

              setState(() {
                dragging = false;
              });
            },
            onDoubleTap: () {
              /*widget.app.project.value.patch.value
                  .removeConnection(widget.moduleId, widget.pinIndex);
              gConnectorsState?.refreshConnectors();*/
            },
          ),
        ),
        decoration: !glowing
            ? BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(width: 2, color: color),
              )
            : BoxDecoration(
                shape: BoxShape.circle,
                color: color,
              ),
      ),
    );
  }
}*/

class RawNode extends Struct {
  @Int64()
  external int pointer;

  int getId() {
    return _ffiNodeGetId(this);
  }

  String getName() {
    var rawName = _ffiNodeGetName(this);
    var name = rawName.toDartString();
    calloc.free(rawName);
    return name;
  }

  Color getColor() {
    return Color(_ffiNodeGetColor(this));
  }

  double getX() {
    return _ffiNodeGetX(this);
  }

  double getY() {
    return _ffiNodeGetY(this);
  }

  void setX(double i) {
    _ffiNodeSetX(this, i);
  }

  void setY(double i) {
    _ffiNodeSetY(this, i);
  }

  double getWidth() {
    return _ffiNodeGetWidth(this);
  }

  double getHeight() {
    return _ffiNodeGetHeight(this);
  }

  int getMinWidth() {
    return _ffiNodeGetMinWidth(this);
  }

  int getMaxWidth() {
    return _ffiNodeGetMaxWidth(this);
  }

  int getMinHeight() {
    return _ffiNodeGetMinHeight(this);
  }

  int getMaxHeight() {
    return _ffiNodeGetMaxHeight(this);
  }

  bool getResizable() {
    return _ffiNodeGetResizable(this);
  }

  int getInputPinsCount() {
    return _ffiNodeGetInputPinsCount(this);
  }

  int getInputPinType(int i) {
    return _ffiNodeGetInputPinType(this, i);
  }

  int getInputPinY(int i) {
    return _ffiNodeGetInputPinY(this, i);
  }

  String getInputPinName(int i) {
    var rawName = _ffiNodeGetInputPinName(this, i);
    var name = rawName.toDartString();
    calloc.free(rawName);
    return name;
  }

  int getOutputPinsCount() {
    return _ffiNodeGetOutputPinsCount(this);
  }

  int getOutputPinType(int i) {
    return _ffiNodeGetOutputPinType(this, i);
  }

  int getOutputPinY(int i) {
    return _ffiNodeGetOutputPinY(this, i);
  }

  String getOutputPinName(int i) {
    var rawName = _ffiNodeGetOutputPinName(this, i);
    var name = rawName.toDartString();
    calloc.free(rawName);
    return name;
  }

  RawWidget getWidgetRoot() {
    return _ffiNodeGetWidgetRoot(this);
  }

  bool shouldRebuild() {
    return _ffiNodeShouldRebuild(this);
  }

  void setWidth(double width) {
    _ffiNodeSetNodeWidth(this, width);
  }

  void setHeight(double height) {
    _ffiNodeSetNodeHeight(this, height);
  }
}

int Function(RawNode) _ffiNodeGetId = core
    .lookup<NativeFunction<Int32 Function(RawNode)>>("ffi_node_get_id")
    .asFunction();
Pointer<Utf8> Function(RawNode) _ffiNodeGetName = core
    .lookup<NativeFunction<Pointer<Utf8> Function(RawNode)>>(
        "ffi_node_get_name")
    .asFunction();
int Function(RawNode) _ffiNodeGetColor = core
    .lookup<NativeFunction<Int32 Function(RawNode)>>("ffi_node_get_color")
    .asFunction();

double Function(RawNode) _ffiNodeGetX = core
    .lookup<NativeFunction<Double Function(RawNode)>>("ffi_node_get_x")
    .asFunction();
double Function(RawNode) _ffiNodeGetY = core
    .lookup<NativeFunction<Double Function(RawNode)>>("ffi_node_get_y")
    .asFunction();
void Function(RawNode, double) _ffiNodeSetX = core
    .lookup<NativeFunction<Void Function(RawNode, Double)>>("ffi_node_set_x")
    .asFunction();
void Function(RawNode, double) _ffiNodeSetY = core
    .lookup<NativeFunction<Void Function(RawNode, Double)>>("ffi_node_set_y")
    .asFunction();

double Function(RawNode) _ffiNodeGetWidth = core
    .lookup<NativeFunction<Float Function(RawNode)>>("ffi_node_get_width")
    .asFunction();
double Function(RawNode) _ffiNodeGetHeight = core
    .lookup<NativeFunction<Float Function(RawNode)>>("ffi_node_get_height")
    .asFunction();
int Function(RawNode) _ffiNodeGetMinWidth = core
    .lookup<NativeFunction<Int32 Function(RawNode)>>("ffi_node_get_min_width")
    .asFunction();
int Function(RawNode) _ffiNodeGetMinHeight = core
    .lookup<NativeFunction<Int32 Function(RawNode)>>("ffi_node_get_min_height")
    .asFunction();
int Function(RawNode) _ffiNodeGetMaxWidth = core
    .lookup<NativeFunction<Int32 Function(RawNode)>>("ffi_node_get_max_width")
    .asFunction();
int Function(RawNode) _ffiNodeGetMaxHeight = core
    .lookup<NativeFunction<Int32 Function(RawNode)>>("ffi_node_get_max_height")
    .asFunction();
bool Function(RawNode) _ffiNodeGetResizable = core
    .lookup<NativeFunction<Bool Function(RawNode)>>("ffi_node_get_resizable")
    .asFunction();

int Function(RawNode) _ffiNodeGetInputPinsCount = core
    .lookup<NativeFunction<Int32 Function(RawNode)>>(
        "ffi_node_get_input_pins_count")
    .asFunction();
int Function(RawNode, int) _ffiNodeGetInputPinType = core
    .lookup<NativeFunction<Int32 Function(RawNode, Int32)>>(
        "ffi_node_get_input_pin_type")
    .asFunction();
Pointer<Utf8> Function(RawNode, int) _ffiNodeGetInputPinName = core
    .lookup<NativeFunction<Pointer<Utf8> Function(RawNode, Int32)>>(
        "ffi_node_get_input_pin_name")
    .asFunction();
int Function(RawNode, int) _ffiNodeGetInputPinY = core
    .lookup<NativeFunction<Int32 Function(RawNode, Int32)>>(
        "ffi_node_get_input_pin_y")
    .asFunction();

int Function(RawNode) _ffiNodeGetOutputPinsCount = core
    .lookup<NativeFunction<Int32 Function(RawNode)>>(
        "ffi_node_get_output_pins_count")
    .asFunction();
int Function(RawNode, int) _ffiNodeGetOutputPinType = core
    .lookup<NativeFunction<Int32 Function(RawNode, Int32)>>(
        "ffi_node_get_output_pin_type")
    .asFunction();
Pointer<Utf8> Function(RawNode, int) _ffiNodeGetOutputPinName = core
    .lookup<NativeFunction<Pointer<Utf8> Function(RawNode, Int32)>>(
        "ffi_node_get_output_pin_name")
    .asFunction();
int Function(RawNode, int) _ffiNodeGetOutputPinY = core
    .lookup<NativeFunction<Int32 Function(RawNode, Int32)>>(
        "ffi_node_get_output_pin_y")
    .asFunction();

RawWidget Function(RawNode) _ffiNodeGetWidgetRoot = core
    .lookup<NativeFunction<RawWidget Function(RawNode)>>(
        "ffi_node_get_widget_root")
    .asFunction();
bool Function(RawNode) _ffiNodeShouldRebuild = core
    .lookup<NativeFunction<Bool Function(RawNode)>>("ffi_node_should_rebuild")
    .asFunction();

void Function(RawNode, double) _ffiNodeSetNodeWidth = core
    .lookup<NativeFunction<Void Function(RawNode, Float)>>("ffi_node_set_width")
    .asFunction();
void Function(RawNode, double) _ffiNodeSetNodeHeight = core
    .lookup<NativeFunction<Void Function(RawNode, Float)>>(
        "ffi_node_set_height")
    .asFunction();
