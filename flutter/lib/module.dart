import 'package:ffi/ffi.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import 'dart:ffi';
import 'dart:async';
import 'dart:io';
import 'dart:convert';

import 'config.dart';
import 'main.dart';

import 'widgets/widget.dart';

import 'views/variables.dart';
import 'views/presets.dart';
import 'views/info.dart';

import 'host.dart';
import 'views/settings.dart';

class Module {
  var id = 1;
  var name = "Name";
  var position = const Offset(100, 100);
  var size = const Offset(250, 250);
  var pins = <Pin>[];
  var widgets = <ModuleWidget>[];
  var widgetsMain = <ModuleWidget>[];
  var color = Color(0x0);

  final FFINode module;

  final Host host;

  Module(this.host, this.module) {
    print("Creating module now");

    id = api.ffiNodeGetId(module);
    print("  id: " + id.toString());
    position =
        Offset(api.ffiNodeGetX(module) + 0.0, api.ffiNodeGetY(module) + 0.0);
    size = Offset(
        api.ffiNodeGetWidth(module) + 0.0, api.ffiNodeGetHeight(module) + 0.0);

    int inputsCount = api.ffiNodeGetInputPinsCount(module);
    int outputsCount = api.ffiNodeGetOutputPinsCount(module);

    var tempName = api.ffiNodeGetName(module);
    name = tempName.toDartString();
    calloc.free(tempName);

    int tempColor = api.ffiNodeGetColor(module);
    color = Color(tempColor);

    for (int i = 0; i < inputsCount; i++) {
      var pin = Pin();

      pin.moduleId = id;
      pin.index = i;

      var nameRaw = api.ffiNodeGetInputPinName(module, i);
      pin.name = nameRaw.toDartString();
      calloc.free(nameRaw);

      var kind = api.ffiNodeGetInputPinType(module, i);

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
        pin.offset = Offset(10, 0.0 + api.ffiNodeGetInputPinY(module, i));
      }

      pin.isInput = true;
      pins.add(pin);
    }

    for (int i = 0; i < outputsCount; i++) {
      var pin = Pin();

      pin.moduleId = id;
      pin.index = i + inputsCount;

      var nameRaw = api.ffiNodeGetOutputPinName(module, i);
      pin.name = nameRaw.toDartString();
      calloc.free(nameRaw);

      var kind = api.ffiNodeGetOutputPinType(module, i);

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
        pin.offset =
            Offset(size.dx - 25, 0.0 + api.ffiNodeGetOutputPinY(module, i));
      }

      pin.isInput = false;
      pins.add(pin);
    }

    var widgetRaw = api.ffiNodeGetWidgetRoot(module);
    var widget = createWidget(host, module, widgetRaw);
    if (widget != null) {
      widgets.add(widget);
    }

    var widgetMainRaw = api.ffiNodeGetWidgetMainRoot(module);
    if (widgetMainRaw.metadata != 0) {
      print("Adding widget to main view");
      var widget = createWidget(host, module, widgetMainRaw);
      if (widget != null) {
        widgetsMain.add(widget);
      }
    }
  }
}

class Connector {
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
}

enum IO { audio, midi, control, time, external }

class Pin {
  var moduleId = 1;
  var index = 1;
  var type = IO.audio;
  var offset = const Offset(15, 15);
  var isInput = true;
  String name = "Unknown";
}

class ModuleContainerWidget extends StatefulWidget {
  ModuleContainerWidget(Module m, this.host) : super(key: UniqueKey()) {
    module = m;
    state = _ModuleContainerState(module);
  }

  Host host;

  late Module module;
  late _ModuleContainerState state;

  void refresh() {
    state.refresh();
  }

  @override
  State<StatefulWidget> createState() {
    return state;
  }
}

class _ModuleContainerState extends State<ModuleContainerWidget> {
  _ModuleContainerState(this.module);

  late Module module;

  void refresh() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    bool resizable = api.ffiNodeGetResizable(module.module);
    //print("Building module container");
    // PERFORMANCE ISSUE: THIS GETS CALLED TOO OFTEN

    var width = api.ffiNodeGetWidth(module.module);
    var height = api.ffiNodeGetHeight(module.module);

    final widgets = <Widget>[];

    widgets.addAll(module.widgets);

    widgets.add(Container(
        padding: const EdgeInsets.all(10),
        child: Align(
            alignment: Alignment.topCenter,
            child: Text(
              module.name,
              style: TextStyle(
                  color: module.color,
                  fontSize: 16,
                  fontWeight: FontWeight.normal,
                  decoration: TextDecoration.none),
            ))));

    for (var pin in module.pins) {
      if (pin.isInput) {
        if (pin.type != IO.external) {
          widgets.add(PinWidget(module.id, pin.index, pin.type, 10,
              pin.offset.dy, pin.name, pin.isInput, widget.host));
        }
      } else {
        pin.offset = Offset(width - 25, pin.offset.dy);

        if (pin.type != IO.external) {
          widgets.add(PinWidget(module.id, pin.index, pin.type, width - 25,
              pin.offset.dy, pin.name, pin.isInput, widget.host));
        }
      }
    }

    final moduleWidget = Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: MyTheme.greyMid,
          borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(10),
              topRight: Radius.circular(10),
              bottomLeft: Radius.circular(10),
              bottomRight: Radius.circular(10)),
          boxShadow: widget.host.globals.selectedModule == module.id
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
                                  var m = widget.host.globals.zoom * 10;

                                  var w = width + details.delta.dx * m;
                                  var h = height + details.delta.dy * m;

                                  var minWidth =
                                      api.ffiNodeGetMinWidth(module.module);
                                  var maxWidth =
                                      api.ffiNodeGetMaxWidth(module.module);
                                  var minHeight =
                                      api.ffiNodeGetMinHeight(module.module);
                                  var maxHeight =
                                      api.ffiNodeGetMaxHeight(module.module);

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

                                  api.ffiNodeSetNodeWidth(module.module, w);
                                  api.ffiNodeSetNodeHeight(module.module, h);
                                  module.size = Offset(w, h);
                                });
                              },
                            ),
                          ))
                    ])
                  : []),
        ));

    return Positioned(
        left: module.position.dx,
        top: module.position.dy,
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          // Can't do this. Might accidentally delete when playing pads
          /*onDoubleTap: () {
          globals.host.instrument.preset.graph.removeModule(module.id);
          gGridState?.refresh();
        },*/
          onTap: () {
            print("Tap module");
            if (widget.host.globals.selectedModule == module.id) {
              widget.host.globals.selectedModule = -1;
              refresh();
            } else {
              var oldModule = widget.host.globals.selectedModule;
              widget.host.globals.selectedModule = module.id;

              for (var moduleWidget in widget.host.graph.moduleWidgets) {
                if (moduleWidget.module.id == oldModule) {
                  moduleWidget.refresh();
                }
              }

              refresh();
            }
          },
          onSecondaryTap: () {
            print("Secondary tap module");
          },
          onPanUpdate: (details) {
            api.ffiNodeSetX(module.module, module.position.dx.toInt());
            api.ffiNodeSetY(module.module, module.position.dy.toInt());

            setState(() {
              module.position = Offset(module.position.dx + details.delta.dx,
                  module.position.dy + details.delta.dy);
            });
          },
          child: moduleWidget,
        ));
  }
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
              fontWeight: FontWeight.w300),
        ),
      ),
      decoration: BoxDecoration(
          color: Colors.grey.withOpacity(0.2),
          border: Border.all(
            color: const Color.fromRGBO(50, 50, 50, 1.0),
            width: 0.0,
          ),
          borderRadius: BorderRadius.circular(5)),
    );
  }
}

class PinWidget extends StatefulWidget {
  PinWidget(int moduleId1, int pinIndex1, IO io1, double x1, double y1,
      String n, bool isInput, this.host)
      : super(key: UniqueKey()) {
    io = io1;
    x = x1;
    y = y1;
    moduleId = moduleId1;
    pinIndex = pinIndex1;
    name = n;
    input = isInput;
  }

  Host host;

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

    for (var connector in widget.host.graph.connectors) {
      if (connector.start.moduleId == widget.moduleId &&
          connector.start.index == widget.pinIndex) {
        connected = true;
      }
      if (connector.end.moduleId == widget.moduleId &&
          connector.end.index == widget.pinIndex) {
        connected = true;
      }
    }

    var glowing = dragging || hovering || connected;

    return Positioned(
      left: widget.x,
      top: widget.y,
      child: Container(
        width: 15,
        height: 15,
        child: MouseRegion(
            onEnter: (PointerEnterEvent event) {
              widget.host.globals.pinLabel.value = widget.name;

              if (widget.input) {
                widget.host.globals.labelPosition = Offset(
                    event.position.dx -
                        50 -
                        widget.host.globals.pinLabel.value.length * 7,
                    event.position.dy - 15);
              } else {
                widget.host.globals.labelPosition =
                    Offset(event.position.dx + 30, event.position.dy - 15);
              }

              setState(() {
                hovering = true;
                widget.host.globals.tempConnector?.hoveringId = widget.moduleId;
                widget.host.globals.tempConnector?.hoveringIndex =
                    widget.pinIndex;
              });
            },
            onExit: (PointerExitEvent event) {
              widget.host.globals.pinLabel.value = "";

              setState(() {
                hovering = false;
                widget.host.globals.tempConnector?.hoveringId = -1;
                widget.host.globals.tempConnector?.hoveringIndex = -1;
              });
            },
            child: GestureDetector(
              onPanStart: (details) {
                setState(() {
                  dragging = true;
                  widget.host.globals.tempConnector = TempConnector();
                  widget.host.globals.tempConnector?.moduleId = widget.moduleId;
                  widget.host.globals.tempConnector?.pinIndex = widget.pinIndex;
                  widget.host.globals.tempConnector?.type = widget.io;
                });
              },
              onPanUpdate: (details) {
                widget.host.globals.tempConnector?.endX =
                    details.localPosition.dx;
                widget.host.globals.tempConnector?.endY =
                    details.localPosition.dy;
                gTempConnectorState?.refresh();
              },
              onPanEnd: (details) {
                var c = widget.host.globals.tempConnector ?? TempConnector();
                if (c.hoveringId != -1) {
                  if (widget.host.graph.addConnection(Connector(c.moduleId,
                      c.pinIndex, c.hoveringId, c.hoveringIndex, c.type))) {
                    gConnectorsState?.refreshConnectors();
                  }
                }

                widget.host.globals.tempConnector = null;
                gTempConnectorState?.refresh();

                setState(() {
                  dragging = false;
                });
              },
              onDoubleTap: () {
                widget.host.graph
                    .removeConnection(widget.moduleId, widget.pinIndex);
                gConnectorsState?.refreshConnectors();
              },
            )),
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
}
