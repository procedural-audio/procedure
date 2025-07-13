import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:metasampler/patch/pin.dart';
import 'package:metasampler/patch/widgets/fader.dart';
import 'package:metasampler/patch/widgets/textbox.dart';
import 'package:metasampler/project/theme.dart';

import '../bindings/api/endpoint.dart';
import '../bindings/api/node.dart' as rust_node;
import '../settings.dart';
import 'widgets/knob.dart';
import 'widgets/led.dart';
import 'widgets/scope.dart';

int NODE_ID = 1;

double roundToGrid(double x) {
  return (x / GlobalSettings.gridSize).roundToDouble() *
      GlobalSettings.gridSize;
}

abstract class NodeWidget extends StatelessWidget {
  const NodeWidget(this.node, this.endpoint, {super.key});

  final NodeEditor node;
  final NodeEndpoint endpoint;

  void tick(Duration elapsed) {}

  void writeFloat(double value) {
    try {
      endpoint.writeFloat(v: value);
    } catch (e) {
      print("Failed to write float to endpoint: $e");
    }
  }

  void writeInt(int value) {
    try {
      endpoint.writeInt(v: value);
    } catch (e) {
      print("Failed to write int to endpoint: $e");
    }
  }

  void writeBool(bool value) {
    try {
      endpoint.writeBool(b: value);
    } catch (e) {
      print("Failed to write bool to endpoint: $e");
    }
  }

  double? readFloat() {
    try {
      return endpoint.readFloat();
    } catch (e) {
      print("Failed to read float from endpoint: $e");
    }

    return 0.0;
  }

  int? readInt() {
    try {
      return endpoint.readInt();
    } catch (e) {
      print("Failed to read float from endpoint: $e");
    }

    return 0;
  }

  bool? readBool() {
    try {
      return endpoint.readBool();
    } catch (e) {
      print("Failed to read float from endpoint: $e");
    }

    return false;
  }

  static NodeWidget? from(
      NodeEditor node, NodeEndpoint endpoint, Map<String, dynamic> map) {
    if (map['widget'] != null) {
      String type = map['widget'];
      switch (type) {
        case "knob":
          return KnobWidget.from(node, endpoint, map);
        case "fader":
          return FaderWidget.from(node, endpoint, map);
        case "textbox":
          return TextboxWidget.from(node, endpoint, map);
        case "scope":
          return ScopeWidget.from(node, endpoint, map);
        case "led":
          return LedWidget.from(node, endpoint, map);
        default:
          print("Unknown widget type: $type");
      }
    }

    return null;
  }

  Map<String, dynamic> getState();
  void setState(Map<String, dynamic> state);
}

class NodeEditor extends StatefulWidget {
  NodeEditor({
    Key? key,
    required this.node,
    required this.onSave,
    required this.onAddConnector,
    required this.onRemoveConnections,
    required this.onNewCableDrag,
    required this.onNewCableSetStart,
    required this.onNewCableSetEnd,
    required this.onNewCableReset,
    required this.onAddNewCable,
  }) : super(key: key);

  final rust_node.Node node;
  final VoidCallback onSave;
  final void Function(Pin, Pin) onAddConnector;
  final void Function(Pin) onRemoveConnections;
  final void Function(Offset) onNewCableDrag;
  final void Function(Pin) onNewCableSetStart;
  final void Function(Pin?) onNewCableSetEnd;
  final VoidCallback onNewCableReset;
  final VoidCallback onAddNewCable;

  @override
  NodeEditorState createState() => NodeEditorState();
}

class NodeEditorState extends State<NodeEditor> {
  bool _isDragging = false;

  List<Widget> _buildPinsAndWidgets() {
    List<Widget> children = [];

    // Add input pins and widgets to list
    for (var endpoint in widget.node.getInputs()) {
      Map<String, dynamic> annotations = jsonDecode(endpoint.annotation);

      print("Endpoint: ${endpoint.type}");

      // Skip pin if it's an external endpoint
      if (annotations.containsKey("external")) {
        continue;
      }

      // Skip pin creation if a widget was created
      if (annotations.containsKey("widget")) {
        var nodeWidget = NodeWidget.from(widget, endpoint, annotations);
        if (nodeWidget != null) {
          children.add(nodeWidget);
        }

        continue;
      }

      children.add(
        Pin(
          endpoint: endpoint,
          node: widget.node,
          onAddConnector: widget.onAddConnector,
          onRemoveConnections: widget.onRemoveConnections,
          onNewCableDrag: widget.onNewCableDrag,
          onNewCableSetStart: widget.onNewCableSetStart,
          onNewCableSetEnd: widget.onNewCableSetEnd,
          onNewCableReset: widget.onNewCableReset,
          onAddNewCable: widget.onAddNewCable,
        ),
      );
    }

    // Add output pins to list
    for (var endpoint in widget.node.getOutputs()) {
      Map<String, dynamic> annotations = jsonDecode(endpoint.annotation);

      print("Endpoint: ${endpoint.type}");

      // Skip pin if it's a string endpoint
      if (endpoint.type.contains("string")) {
        continue;
      }

      // Skip pin if it's an external endpoint
      if (annotations.containsKey("external")) {
        continue;
      }

      // Skip pin creation if a widget was created
      if (annotations.containsKey("widget")) {
        var nodeWidget = NodeWidget.from(widget, endpoint, annotations);
        if (nodeWidget != null) {
          children.add(nodeWidget);
        }

        continue;
      }

      children.add(
        Pin(
          endpoint: endpoint,
          node: widget.node,
          onAddConnector: widget.onAddConnector,
          onRemoveConnections: widget.onRemoveConnections,
          onNewCableDrag: widget.onNewCableDrag,
          onNewCableSetStart: widget.onNewCableSetStart,
          onNewCableSetEnd: widget.onNewCableSetEnd,
          onNewCableReset: widget.onNewCableReset,
          onAddNewCable: widget.onAddNewCable,
        ),
      );
    }

    return children;
  }

  void tick() {
    // for (var widget in widgets) {
    // widget.tick();
    // }
  }

  void refreshUserInterface() {
    List<NodeWidget> newWidgets = [];

    print("Refreshing node widgets");

    /*for (var plugin in Plugins.list().value) {
      for (var moduleInfo in plugin.modules().value) {
        if (moduleInfo.path == info.path) {
          for (var widgetInfo in moduleInfo.widgetInfos) {
            newWidgets.add(widgetInfo.createWidget());
          }
        }
      }
    }*/
  }

  @override
  Widget build(BuildContext context) {
    // Always use current Rust node position
    var currentPosition = Offset(widget.node.position.$1, widget.node.position.$2);
    
    return Positioned(
      left: roundToGrid(currentPosition.dx),
      top: roundToGrid(currentPosition.dy),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onPanStart: (details) {
          // Start dragging - no state needed since we update position directly
        },
        onPanUpdate: (details) {
          // Update Rust node position immediately
          var newPosition = Offset(
            widget.node.position.$1 + details.delta.dx,
            widget.node.position.$2 + details.delta.dy,
          );
          widget.node.setPosition(position: (newPosition.dx, newPosition.dy));
        },
        onPanEnd: (details) {
          // Quantize to grid
          var x = roundToGrid(widget.node.position.$1);
          var y = roundToGrid(widget.node.position.$2);
          
          widget.node.setPosition(position: (x, y));
          widget.onSave();
        },
        child: Container(
              width: widget.node.module.size.$1 * GlobalSettings.gridSize - 1.0,
              height: widget.node.module.size.$2 * GlobalSettings.gridSize - 1.0,
              decoration: BoxDecoration(
                color: const Color.fromRGBO(40, 40, 40, 1.0),
                borderRadius: const BorderRadius.all(Radius.circular(10)),
                border: Border.all(
                  width: 2,
                  color: const Color.fromRGBO(40, 40, 40, 1.0),
                ),
              ),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Align(
                    alignment: Alignment.topCenter,
                    child: Padding(
                      padding: const EdgeInsets.all(5),
                      child: Text(
                        widget.node.module.title ?? "",
                        style: TextStyle(
                          color: colorFromString(widget.node.module.titleColor ?? "") ?? Colors.grey,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                  Visibility(
                    visible: widget.node.module.icon != null,
                    child: Align(
                      alignment: Alignment.center,
                      child: SvgPicture.string(
                        widget.node.module.icon ?? "",
                        width: (widget.node.module.iconSize ?? 24).toDouble(),
                        height: (widget.node.module.iconSize ?? 24).toDouble(),
                        color: colorFromString(widget.node.module.iconColor ?? "") ?? Colors.grey,
                      ),
                    ),
                  ),
                  Stack(
                    fit: StackFit.expand,
                    children: _buildPinsAndWidgets(),
                  )
                ],
              ),
            ),
        ),
      );
  }
}
