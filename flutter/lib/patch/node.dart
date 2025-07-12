import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:metasampler/patch/module.dart';
import 'package:metasampler/patch/pin.dart';
import 'package:metasampler/patch/widgets/fader.dart';
import 'package:metasampler/patch/widgets/textbox.dart';

import '../bindings/api/endpoint.dart';
import '../bindings/api/node.dart' as api;
import '../plugin/plugin.dart';
import '../settings.dart';
import 'widgets/knob.dart';
import 'patch.dart';
import 'widgets/led.dart';
import 'widgets/scope.dart';
import 'connector.dart';

int NODE_ID = 1;

double roundToGrid(double x) {
  return (x / GlobalSettings.gridSize).roundToDouble() *
      GlobalSettings.gridSize;
}

abstract class NodeWidget extends StatelessWidget {
  const NodeWidget(this.node, this.endpoint, {super.key});

  final Node node;
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
      Node node, NodeEndpoint endpoint, Map<String, dynamic> map) {
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

class Node extends StatelessWidget {
  Node({
    required this.module,
    required this.patch,
    required this.onAddConnector,
    required this.onRemoveConnections,
    required Offset position,
    required this.newConnector,
    required this.onNewConnectorDrag,
    required this.onNewConnectorSetStart,
    required this.onNewConnectorSetEnd,
    required this.onNewConnectorReset,
    required this.onAddNewConnector,
  }) : super(key: UniqueKey()) {
    // Set the initial node position
    this.position.value = position;

    List<String> source = []; // Plugins.lib();
    source.add(module.source);
    rawNode = api.Node.from(source: source, id: NODE_ID++);
    if (rawNode != null) {
      // Add input pins and widgets to list
      for (var endpoint in rawNode!.inputs) {
        Map<String, dynamic> annotations = jsonDecode(endpoint.annotation);

        print("Endpoint: ${endpoint.type}");

        // Skip pin if it's an external endpoint
        if (annotations.containsKey("external")) {
          continue;
        }

        // Skip pin creation if a widget was created
        if (annotations.containsKey("widget")) {
          var widget = NodeWidget.from(this, endpoint, annotations);
          if (widget != null) {
            widgets.add(widget);
          }

          continue;
        }

        pins.add(
          Pin(
            endpoint: endpoint,
            node: this,
            patch: patch,
            onAddConnector: onAddConnector,
            onRemoveConnections: onRemoveConnections,
            newConnector: newConnector,
            onNewConnectorDrag: onNewConnectorDrag,
            onNewConnectorSetStart: onNewConnectorSetStart,
            onNewConnectorSetEnd: onNewConnectorSetEnd,
            onNewConnectorReset: onNewConnectorReset,
            onAddNewConnector: onAddNewConnector,
          ),
        );
      }

      // Add output pins to list
      for (var endpoint in rawNode!.outputs) {
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
          var widget = NodeWidget.from(this, endpoint, annotations);
          if (widget != null) {
            widgets.add(widget);
          }

          continue;
        }

        pins.add(
          Pin(
            endpoint: endpoint,
            node: this,
            patch: patch,
            onAddConnector: onAddConnector,
            onRemoveConnections: onRemoveConnections,
            newConnector: newConnector,
            onNewConnectorDrag: onNewConnectorDrag,
            onNewConnectorSetStart: onNewConnectorSetStart,
            onNewConnectorSetEnd: onNewConnectorSetEnd,
            onNewConnectorReset: onNewConnectorReset,
            onAddNewConnector: onAddNewConnector,
          ),
        );
      }
    }
  }

  final Module module;
  final Patch patch;
  final void Function(Pin, Pin) onAddConnector;
  final void Function(Pin) onRemoveConnections;
  final NewConnector newConnector;
  final void Function(Offset) onNewConnectorDrag;
  final void Function(Pin) onNewConnectorSetStart;
  final void Function(Pin?) onNewConnectorSetEnd;
  final VoidCallback onNewConnectorReset;
  final VoidCallback onAddNewConnector;
  api.Node? rawNode;

  List<Pin> pins = [];
  List<NodeWidget> widgets = [];

  final ValueNotifier<Offset> position = ValueNotifier(const Offset(100, 100));

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

  void refreshSize() {}

  Node? fromState(Map<String, dynamic> state) {
    /*var module = Module.fromState(state["module"]);
    var position = Offset(state["x"], state["y"]);

    return Node(
      module: module,
      patch: patch,
    );*/
  }

  Map<String, dynamic> getState() {
    return {
      "module": module.getState(),
      // "id": rawNode!.id,
      "x": position.value.dx,
      "y": position.value.dy,
    };
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Offset>(
      valueListenable: position,
      builder: (context, p, child) {
        return Positioned(
          left: roundToGrid(p.dx),
          top: roundToGrid(p.dy),
          child: GestureDetector(
            onTap: () {
              /*if (patch.selectedNodes.value.contains(this)) {
                patch.selectedNodes.value = [];
              } else {
                patch.selectedNodes.value = [this];
              }*/
            },
            onPanStart: (details) {
              /*if (!patch.selectedNodes.value.contains(this)) {
                patch.selectedNodes.value = [this];
              }*/
            },
            onPanUpdate: (details) {
              var x = position.value.dx + details.delta.dx;
              var y = position.value.dy + details.delta.dy;
              position.value = Offset(x, y);
            },
            onPanEnd: (details) {
              var x = roundToGrid(position.value.dx);
              var y = roundToGrid(position.value.dy);
              position.value = Offset(x, y);
            },
            child: Container(
              width: module.size.width * GlobalSettings.gridSize - 1.0,
              height: module.size.height * GlobalSettings.gridSize - 1.0,
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
                        module.title ?? "",
                        style: TextStyle(
                          color: module.titleColor ?? Colors.grey,
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
                        color: module.iconColor ?? Colors.grey,
                      ),
                    ),
                  ),
                  Stack(
                    fit: StackFit.expand,
                    children: <Widget>[] + widgets + pins,
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
