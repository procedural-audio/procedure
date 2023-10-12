import 'package:ffi/ffi.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'dart:ffi';

import 'patch.dart';
import 'core.dart';

import 'widgets/widget.dart';

class Pin extends StatefulWidget {
  Pin({
    required this.node,
    required this.nodeId,
    required this.pinIndex,
    required this.offset,
    required this.type,
    required this.isInput,
    required this.connectors,
    required this.selectedNodes,
    required this.onAddConnector,
    required this.onRemoveConnector,
  }) : super(key: UniqueKey());

  final Node node;
  final int nodeId;
  final int pinIndex;
  final Offset offset;
  final IO type;
  final bool isInput;
  final List<Connector> connectors;
  final ValueNotifier<List<Node>> selectedNodes;
  final void Function(Pin, Pin) onAddConnector;
  final void Function(int, int) onRemoveConnector;

  @override
  _PinState createState() => _PinState();
}

class _PinState extends State<Pin> {
  bool hovering = false;
  bool dragging = false;

  @override
  Widget build(BuildContext context) {
    if (widget.type == IO.external) {
      return Container();
    }

    var color = Colors.white;

    if (widget.type == IO.audio) {
      color = Colors.blue;
    } else if (widget.type == IO.midi) {
      color = Colors.green;
    } else if (widget.type == IO.control) {
      color = Colors.red;
    } else if (widget.type == IO.time) {
      color = Colors.deepPurpleAccent;
    }

    bool connected = false;
    for (var connector in widget.connectors) {
      if (connector.start == widget || connector.end == widget) {
        connected = true;
        break;
      }
    }

    return Positioned(
      left: widget.offset.dx,
      top: widget.offset.dy,
      child: MouseRegion(
        onEnter: (e) {
          widget.node.patch.newConnector.end = widget;

          setState(() {
            hovering = true;
          });
        },
        onExit: (e) {
          widget.node.patch.newConnector.end = null;

          setState(() {
            hovering = false;
          });
        },
        child: GestureDetector(
          onPanStart: (details) {
            dragging = true;
            if (!widget.isInput) {
              widget.node.patch.newConnector.offset.value = Offset.zero;
            } else {
              print("Started drag on output node");
            }
          },
          onPanUpdate: (details) {
            if (!widget.isInput) {
              widget.node.patch.newConnector.start = widget;
              widget.node.patch.newConnector.offset.value =
                  details.localPosition;
              widget.node.patch.newConnector.type = widget.type;
            } else {
              // print("Updated drag on output node");
            }
          },
          onPanEnd: (details) {
            if (widget.node.patch.newConnector.start != null &&
                widget.node.patch.newConnector.end != null) {
              widget.onAddConnector(
                widget.node.patch.newConnector.start!,
                widget.node.patch.newConnector.end!,
              );
            } else {
              print("Connector has no end");
            }

            widget.node.patch.newConnector.start = null;
            widget.node.patch.newConnector.end = null;
            widget.node.patch.newConnector.offset.value = null;
            setState(() {
              dragging = false;
            });
          },
          onPanCancel: () {
            widget.node.patch.newConnector.start = null;
            widget.node.patch.newConnector.end = null;
            widget.node.patch.newConnector.offset.value = null;
            setState(() {
              dragging = false;
            });
          },
          onDoubleTap: () {
            widget.onRemoveConnector(widget.nodeId, widget.pinIndex);
          },
          child: ValueListenableBuilder<List<Node>>(
            valueListenable: widget.selectedNodes,
            builder: (context, selectedNodes, child) {
              bool selected = selectedNodes.contains(widget.node);
              return Container(
                width: 15,
                height: 15,
                decoration: BoxDecoration(
                  color: hovering || dragging || connected
                      ? (selected || hovering ? color : color.withOpacity(0.5))
                      : Colors.transparent,
                  border: Border.all(
                    color: color,
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

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
              color: Color.fromRGBO(200, 200, 200, 1.0),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

class Node extends StatelessWidget {
  Node({
    required this.rawNode,
    required this.patch,
    required this.connectors,
    required this.selectedNodes,
    required this.onAddConnector,
    required this.onRemoveConnector,
    required this.onDrag,
  }) : super(key: UniqueKey()) {
    id = rawNode.getId();
    position.value = Offset(rawNode.getX() + 0.0, rawNode.getY() + 0.0);
    name = rawNode.getName();
    color = rawNode.getColor();

    refreshSize();

    int inputsCount = rawNode.getInputPinsCount();
    for (int i = 0; i < inputsCount; i++) {
      var type = rawNode.getInputPinType(i);
      var offset = Offset(10, 0.0 + rawNode.getInputPinY(i));
      pins.add(
        Pin(
          offset: offset,
          nodeId: id,
          pinIndex: i,
          type: type,
          isInput: true,
          node: this,
          selectedNodes: selectedNodes,
          connectors: connectors,
          onAddConnector: onAddConnector,
          onRemoveConnector: (nodeId, pinIndex) {
            onRemoveConnector(nodeId, pinIndex);
          },
        ),
      );
    }

    int outputsCount = rawNode.getOutputPinsCount();
    for (int i = 0; i < outputsCount; i++) {
      var type = rawNode.getOutputPinType(i);
      var x = rawNode.getWidth(patch) - 25;
      var offset = Offset(x, 0.0 + rawNode.getOutputPinY(i));
      pins.add(
        Pin(
          offset: offset,
          nodeId: id,
          pinIndex: i + inputsCount,
          type: type,
          isInput: false,
          node: this,
          selectedNodes: selectedNodes,
          connectors: connectors,
          onAddConnector: onAddConnector,
          onRemoveConnector: (nodeId, pinIndex) {
            onRemoveConnector(nodeId, pinIndex);
          },
        ),
      );
    }

    var widgetRaw = rawNode.getWidgetRoot();
    var widget = createWidget(this, rawNode, widgetRaw);
    if (widget != null) {
      widgets.add(widget);
    } else {
      print("Failed to create root widget");
    }
  }

  final Patch patch;
  final RawNode rawNode;
  final List<Connector> connectors;
  final ValueNotifier<List<Node>> selectedNodes;
  final void Function(Pin, Pin) onAddConnector;
  final void Function(int, int) onRemoveConnector;
  final void Function(Offset) onDrag;

  int id = 1;
  String name = "Name";
  Color color = Colors.grey;
  Offset size = const Offset(250, 250);
  ValueNotifier<Offset> position = ValueNotifier(const Offset(100, 100));
  List<Pin> pins = [];
  List<ModuleWidget> widgets = <ModuleWidget>[];

  void tick() {
    for (var widget in widgets) {
      widget.tick();
    }
  }

  void refreshSize() {
    var newSize = Offset(
      rawNode.getWidth(patch) + 0.0,
      rawNode.getHeight(patch) + 0.0,
    );

    if (newSize.dx != size.dx || newSize.dy != size.dy) {
      size = newSize;
      position.notifyListeners();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Offset>(
      valueListenable: position,
      builder: (context, p, child) {
        return Positioned(
          left: p.dx,
          top: p.dy,
          child: GestureDetector(
            onTap: () {
              if (selectedNodes.value.contains(this)) {
                selectedNodes.value = [];
              } else {
                selectedNodes.value = [this];
              }
            },
            onPanStart: (details) {
              if (!selectedNodes.value.contains(this)) {
                selectedNodes.value = [this];
              }
            },
            onPanUpdate: (details) {
              var x = rawNode.getX() + details.delta.dx;
              var y = rawNode.getY() + details.delta.dy;
              rawNode.setX(x);
              rawNode.setY(y);
              position.value = Offset(x, y);
              onDrag(details.localPosition);
            },
            child: ValueListenableBuilder<List<Node>>(
              valueListenable: selectedNodes,
              builder: (context, selectedNodes, child) {
                bool selected = selectedNodes.contains(this);
                return Container(
                  width: size.dx,
                  height: size.dy,
                  decoration: BoxDecoration(
                    color: const Color.fromRGBO(40, 40, 40, 1.0),
                    borderRadius: const BorderRadius.all(Radius.circular(10)),
                    border: Border.all(
                      width: 2,
                      color: selected
                          ? const Color.fromRGBO(140, 140, 140, 1.0)
                          : const Color.fromRGBO(40, 40, 40, 1.0),
                    ),
                  ),
                  child: Stack(
                    fit: StackFit.expand,
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
                        fit: StackFit.expand,
                        children: <Widget>[] + widgets + pins,
                      )
                    ],
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}

void callTickRecursive(ModuleWidget widget) {
  widget.tick();

  for (var child in widget.children) {
    callTickRecursive(child);
  }
}

enum IO { audio, midi, control, time, external }

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

  double getWidth(Patch patch) {
    return _ffiNodeGetWidth(this, patch.rawPatch);
  }

  double getHeight(Patch patch) {
    return _ffiNodeGetHeight(this, patch.rawPatch);
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

  IO getInputPinType(int i) {
    var kind = _ffiNodeGetInputPinType(this, i);
    if (kind == 1) {
      return IO.audio;
    } else if (kind == 2) {
      return IO.midi;
    } else if (kind == 3) {
      return IO.control;
    } else if (kind == 4) {
      return IO.time;
    } else {
      return IO.external;
    }
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

  IO getOutputPinType(int i) {
    var kind = _ffiNodeGetOutputPinType(this, i);
    if (kind == 1) {
      return IO.audio;
    } else if (kind == 2) {
      return IO.midi;
    } else if (kind == 3) {
      return IO.control;
    } else if (kind == 4) {
      return IO.time;
    } else {
      return IO.external;
    }
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

double Function(RawNode, RawPatch) _ffiNodeGetWidth = core
    .lookup<NativeFunction<Float Function(RawNode, RawPatch)>>(
        "ffi_node_get_width")
    .asFunction();
double Function(RawNode, RawPatch) _ffiNodeGetHeight = core
    .lookup<NativeFunction<Float Function(RawNode, RawPatch)>>(
        "ffi_node_get_height")
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
