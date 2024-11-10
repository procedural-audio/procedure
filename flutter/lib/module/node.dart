import 'package:flutter/material.dart';
import 'package:metasampler/module/info.dart';
import 'package:metasampler/module/pin.dart';
import 'package:metasampler/plugins.dart';
import 'package:yaml/yaml.dart';

import '../bindings/api/module.dart';
import '../patch/connector.dart';
import '../patch/patch.dart';

abstract class NodeWidget extends StatelessWidget {
  const NodeWidget(this.map, {super.key});

  final YamlMap map;

  Map<String, dynamic> getState();
  void setState(Map<String, dynamic> state);
}

class Node extends StatelessWidget {
  Node({
    required this.info,
    required this.patch,
    required this.connectors,
    required this.selectedNodes,
    required this.onAddConnector,
    required this.onRemoveConnector,
    required this.onDrag,
  }) : super(key: UniqueKey()) {
    /*size = Offset(info.width.toDouble(), info.height.toDouble());
    name = info.name;

    for (var widgetInfo in info.widgetInfos) {
      widgets.value.add(widgetInfo.createWidget());
    }*/
  }

  final Module info;
  final Patch patch;
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
  ValueNotifier<List<NodeWidget>> widgets = ValueNotifier([]);

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

    // TODO: Copy widget state

    widgets.value = newWidgets;
  }

  void refreshSize() {
    /*var newSize = Offset(
      rawNode.getWidth(patch) + 0.0,
      rawNode.getHeight(patch) + 0.0,
    );

    if (newSize.dx != size.dx || newSize.dy != size.dy) {
      size = newSize;
      position.notifyListeners();
    }*/
  }

  Map<String, dynamic> getState() {
    return {
      "id": id,
      "x": position.value.dx,
      "y": position.value.dy,
      "widgets": widgets.value.map((widget) => widget.getState()).toList(),
    };
  }

  @override
  Widget build(BuildContext context) {
    List<Pin> pins = [];
    int i = 0;

    /*for (var inputInfo in info.inputInfos) {
      i += 1;
      pins.add(Pin(
        node: this,
        nodeId: id,
        pinIndex: i - 1,
        offset: Offset(5, inputInfo.top.toDouble()),
        type: inputInfo.type,
        isInput: true,
        connectors: connectors,
        selectedNodes: selectedNodes,
        onAddConnector: onAddConnector,
        onRemoveConnector: onRemoveConnector,
      ));
    }

    for (var outputInfo in info.outputInfos) {
      i += 1;
      pins.add(Pin(
        node: this,
        nodeId: id,
        pinIndex: i - 1,
        offset: Offset(size.dx - 25, outputInfo.top.toDouble()),
        type: outputInfo.type,
        isInput: true,
        connectors: connectors,
        selectedNodes: selectedNodes,
        onAddConnector: onAddConnector,
        onRemoveConnector: onRemoveConnector,
      ));
    }*/

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
              var x = position.value.dx + details.delta.dx;
              var y = position.value.dy + details.delta.dy;
              // rawNode.setX(x);
              // rawNode.setY(y);
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
                      ValueListenableBuilder(
                        valueListenable: widgets,
                        builder: (context, w, child) {
                          return Stack(
                            fit: StackFit.expand,
                            children: <Widget>[] + widgets.value + pins,
                          );
                        },
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
