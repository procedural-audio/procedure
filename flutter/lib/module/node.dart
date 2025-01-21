import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:metasampler/module/module.dart';
import 'package:metasampler/module/pin.dart';
import 'package:metasampler/nodeWidgets/fader.dart';
import 'package:metasampler/nodeWidgets/textbox.dart';

import '../bindings/api/endpoint.dart';
import '../bindings/api/node.dart' as api;
import '../nodeWidgets/knob.dart';
import '../patch/patch.dart';

int NODE_ID = 1;

abstract class NodeWidget extends StatelessWidget {
  const NodeWidget(this.node, this.endpoint, {super.key});

  final Node node;
  final NodeEndpoint endpoint;

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

  static NodeWidget? from(Node node, NodeEndpoint endpoint) {
    Map<String, dynamic> map = jsonDecode(endpoint.annotation);

    if (map['widget'] != null) {
      String type = map['widget'];
      switch (type) {
        case "knob":
          return KnobWidget.from(node, endpoint, map);
        case "fader":
          return FaderWidget.from(node, endpoint, map);
        case "textbox":
          return TextboxWidget.from(node, endpoint, map);
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
    required this.onDrag,
  }) : super(key: UniqueKey()) {
    rawNode = api.Node.from(source: module.source, id: NODE_ID++)!;

    int pinIndex = 0;

    // Add input pins and widgets to list
    for (var endpoint in rawNode.inputs) {
      var widget = NodeWidget.from(this, endpoint);
      if (widget != null) {
        widgets.add(widget);

        // Skip pin creation if a widget was created
        pinIndex++;
        continue;
      }

      pins.add(
        Pin(
          index: pinIndex++,
          endpoint: endpoint,
          node: this,
          patch: patch,
          isInput: true,
          onAddConnector: onAddConnector,
          onRemoveConnections: onRemoveConnections,
        ),
      );
    }

    // Add output pins to list
    for (var endpoint in rawNode.outputs) {
      pins.add(
        Pin(
          index: pinIndex++,
          endpoint: endpoint,
          node: this,
          patch: patch,
          isInput: false,
          onAddConnector: onAddConnector,
          onRemoveConnections: onRemoveConnections,
        ),
      );
    }
  }

  final Module module;
  final Patch patch;
  final void Function(Pin, Pin) onAddConnector;
  final void Function(Pin) onRemoveConnections;
  final void Function(Offset) onDrag;
  late final api.Node rawNode;

  List<Pin> pins = [];
  List<NodeWidget> widgets = [];

  final ValueNotifier<Offset> position = ValueNotifier(const Offset(100, 100));

  void writeEndpoint(NodeEndpoint endpoint, dynamic value) {}
  dynamic readEndpoint(NodeEndpoint endpoint) {
    return null;
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

  void refreshSize() {}

  Map<String, dynamic> getState() {
    return {
      // "id": id,
      "x": position.value.dx,
      "y": position.value.dy,
      "widgets": widgets.map((widget) => widget.getState()).toList(),
    };
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
              if (patch.selectedNodes.value.contains(this)) {
                patch.selectedNodes.value = [];
              } else {
                patch.selectedNodes.value = [this];
              }
            },
            onPanStart: (details) {
              if (!patch.selectedNodes.value.contains(this)) {
                patch.selectedNodes.value = [this];
              }
            },
            onPanUpdate: (details) {
              var x = position.value.dx + details.delta.dx;
              var y = position.value.dy + details.delta.dy;
              position.value = Offset(x, y);
              onDrag(details.localPosition);
            },
            child: ValueListenableBuilder<List<Node>>(
              valueListenable: patch.selectedNodes,
              builder: (context, selectedNodes, child) {
                bool selected = selectedNodes.contains(this);
                return Container(
                  width: module.size.width,
                  height: module.size.height,
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
                            module.name,
                            style: TextStyle(
                              color: module.color,
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
