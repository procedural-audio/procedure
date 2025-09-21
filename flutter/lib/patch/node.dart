import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:procedure/patch/pin.dart';
import 'package:procedure/patch/widgets/fader.dart';
import 'package:procedure/patch/widgets/textbox.dart';
import 'package:procedure/project/theme.dart';
import 'package:procedure/style/colors.dart';

import '../bindings/api/endpoint.dart';
import '../bindings/api/node.dart' as rust_node;
import '../settings.dart';
import 'widgets/knob.dart';
import 'widgets/led.dart';
import 'widgets/scope.dart';

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
    required this.isEndpointConnected,
    required this.onAddConnector,
    required this.onRemoveConnections,
    required this.onNewCableDrag,
    required this.onNewCableSetStart,
    required this.onNewCableSetEnd,
    required this.onNewCableReset,
    required this.onAddNewCable,
    required this.isSelected,
    required this.onToggleSelection,
    this.onCableRepaintNeeded,
    required this.onPositionChanged,
  }) : super(key: key);

  final rust_node.Node node;
  final VoidCallback onSave;
  final bool Function(rust_node.Node, NodeEndpoint) isEndpointConnected;
  final void Function(Pin, Pin) onAddConnector;
  final void Function(Pin) onRemoveConnections;
  final void Function(Offset) onNewCableDrag;
  final void Function(Pin) onNewCableSetStart;
  final void Function(Pin?) onNewCableSetEnd;
  final VoidCallback onNewCableReset;
  final VoidCallback onAddNewCable;
  final bool isSelected;
  final void Function(rust_node.Node) onToggleSelection;
  final VoidCallback? onCableRepaintNeeded;
  final void Function(rust_node.Node) onPositionChanged;

  @override
  _NodeEditorState createState() => _NodeEditorState();
}

class _NodeEditorState extends State<NodeEditor> {

  Widget _buildNodeContainer() {
    // Get module directly from node
    var module = widget.node.module;
    
    return Container(
      width: module.size.$1 * GlobalSettings.gridSize - 1.0,
      height: module.size.$2 * GlobalSettings.gridSize - 1.0,
      decoration: BoxDecoration(
        color: AppColors.element,
        borderRadius: const BorderRadius.all(Radius.circular(10)),
        border: Border.all(
          width: widget.isSelected ? 3 : 2,
          color: widget.isSelected 
              ? const Color.fromRGBO(150, 150, 150, 1.0) // Grey border for selected
              : const Color.fromRGBO(40, 40, 40, 1.0),
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
                module.title ?? "",
                style: TextStyle(
                  color: colorFromString(module.color ?? "") ?? Colors.grey,
                  fontSize: 16,
                ),
              ),
            ),
          ),
          Visibility(
            visible: module.moduleIcon != null,
            child: Align(
              alignment: Alignment.center,
              child: SvgPicture.string(
                module.moduleIcon ?? "",
                width: 24,
                height: 24,
                color: colorFromString(module.color ?? "") ?? Colors.grey,
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildPinsAndWidgets() {
    List<Widget> children = [];

    // Add input pins and widgets to list
    var inputs = widget.node.getInputs();
    for (var endpoint in inputs) {
      Map<String, dynamic> annotations = jsonDecode(endpoint.annotation);

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
          node: widget.node,
          endpoint: endpoint,
          isConnected: widget.isEndpointConnected,
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
    var outputs = widget.node.getOutputs();
    for (var endpoint in outputs) {
      Map<String, dynamic> annotations = jsonDecode(endpoint.annotation);

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
          node: widget.node,
          endpoint: endpoint,
          isConnected: widget.isEndpointConnected,
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

  

  @override
  Widget build(BuildContext context) {
    // Get current position and module directly from node
    var position = widget.node.position;
    var module = widget.node.module;
    
    var nodeSize = Size(
      module.size.$1 * GlobalSettings.gridSize - 1.0,
      module.size.$2 * GlobalSettings.gridSize - 1.0
    );
    
    return Positioned(
      left: roundToGrid(position.$1),
      top: roundToGrid(position.$2),
      child: SizedBox(
        width: nodeSize.width,
        height: nodeSize.height,
        child: Stack(
          children: [
            // Draggable background layer
            GestureDetector(
              onTap: () {
                // Toggle selection
                setState(() {
                  widget.onToggleSelection(widget.node);
                });
              },
              onPanStart: (details) {
              },
              onPanUpdate: (details) {
                var currentPos = widget.node.position;
                var x = currentPos.$1 + details.delta.dx;
                var y = currentPos.$2 + details.delta.dy;
                widget.node.setPosition(position: (x, y));
                setState(() {});
                // Notify parent to repaint cables
                widget.onCableRepaintNeeded?.call();
              },
              onPanEnd: (details) {
                var currentPos = widget.node.position;
                var x = roundToGrid(currentPos.$1);
                var y = roundToGrid(currentPos.$2);
                
                widget.node.setPosition(position: (x, y));
                widget.onPositionChanged(widget.node);
                widget.onSave();

              },
              child: _buildNodeContainer(),
            ),
            // Pins layer on top - not affected by node dragging
            Stack(
              children: _buildPinsAndWidgets(),
            ),
          ],
        ),
      ),
    );
  }
}
