import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:metasampler/patch/pin.dart';
import 'package:metasampler/patch/widgets/fader.dart';
import 'package:metasampler/patch/widgets/textbox.dart';
import 'package:metasampler/project/theme.dart';
import 'package:metasampler/style/colors.dart';

import '../bindings/api/endpoint.dart';
import '../bindings/api/patch.dart' as rust_patch;
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
    required this.nodeId,
    required this.patch,
    required this.onSave,
    required this.onAddConnector,
    required this.onRemoveConnections,
    required this.onNewCableDrag,
    required this.onNewCableSetStart,
    required this.onNewCableSetEnd,
    required this.onNewCableReset,
    required this.onAddNewCable,
  }) : super(key: key);

  final int nodeId;
  final rust_patch.Patch patch;
  final VoidCallback onSave;
  final void Function(Pin, Pin) onAddConnector;
  final void Function(Pin) onRemoveConnections;
  final void Function(Offset) onNewCableDrag;
  final void Function(Pin) onNewCableSetStart;
  final void Function(Pin?) onNewCableSetEnd;
  final VoidCallback onNewCableReset;
  final VoidCallback onAddNewCable;

  @override
  _NodeEditorState createState() => _NodeEditorState();
}

class _NodeEditorState extends State<NodeEditor> {
  bool _isDragging = false;

  Widget _buildNodeContainer() {
    // Get module from patch
    var module = widget.patch.getNodeModule(nodeId: widget.nodeId);
    if (module == null) {
      return Container(); // Node not found
    }
    
    return Container(
      width: module.size.$1 * GlobalSettings.gridSize - 1.0,
      height: module.size.$2 * GlobalSettings.gridSize - 1.0,
      decoration: BoxDecoration(
        color: AppColors.element,
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
                module.title ?? "",
                style: TextStyle(
                  color: colorFromString(module.titleColor ?? "") ?? Colors.grey,
                  fontSize: 16,
                ),
              ),
            ),
          ),
          Visibility(
            visible: module.icon != null,
            child: Align(
              alignment: Alignment.center,
              child: SvgPicture.string(
                module.icon ?? "",
                width: (module.iconSize ?? 24).toDouble(),
                height: (module.iconSize ?? 24).toDouble(),
                color: colorFromString(module.iconColor ?? "") ?? Colors.grey,
              ),
            ),
          ),
          Stack(
            fit: StackFit.expand,
            children: _buildPinsAndWidgets(),
          )
        ],
      ),
    );
  }

  List<Widget> _buildPinsAndWidgets() {
    List<Widget> children = [];

    // Add input pins and widgets to list
    for (var endpoint in widget.patch.getNodeInputs(nodeId: widget.nodeId)) {
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
          endpoint: endpoint,
          nodeId: widget.nodeId,
          patch: widget.patch,
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
    for (var endpoint in widget.patch.getNodeOutputs(nodeId: widget.nodeId)) {
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
          endpoint: endpoint,
          nodeId: widget.nodeId,
          patch: widget.patch,
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
    // Get current position from patch
    var position = widget.patch.getNodePosition(nodeId: widget.nodeId);
    if (position == null) {
      return Container(); // Node not found
    }
    
    return Positioned(
      left: roundToGrid(position.$1),
      top: roundToGrid(position.$2),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onPanStart: (details) {
          setState(() {
            _isDragging = true;
          });
        },
        onPanUpdate: (details) {
          var currentPos = widget.patch.getNodePosition(nodeId: widget.nodeId);
          if (currentPos != null) {
            var x = currentPos.$1 + details.delta.dx;
            var y = currentPos.$2 + details.delta.dy;
            widget.patch.updateNodePosition(nodeId: widget.nodeId, position: (x, y));
            setState(() {});
          }
        },
        onPanEnd: (details) {
          var currentPos = widget.patch.getNodePosition(nodeId: widget.nodeId);
          if (currentPos != null) {
            var x = roundToGrid(currentPos.$1);
            var y = roundToGrid(currentPos.$2);
            
            widget.patch.updateNodePosition(nodeId: widget.nodeId, position: (x, y));
            widget.onSave();

            setState(() {
              _isDragging = false;
            });
          }
        },
        child: _buildNodeContainer(),
      ),
    );
  }
}
