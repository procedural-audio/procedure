import 'package:flutter/material.dart';
import 'package:metasampler/module/info.dart';
import 'package:metasampler/module/pin.dart';
import 'package:yaml/yaml.dart';

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
    required this.module,
    required this.patch,
    required this.onAddConnector,
    required this.onRemoveConnector,
    required this.onDrag,
  }) : super(key: UniqueKey());

  final Module module;
  final Patch patch;
  final void Function(Pin, Pin) onAddConnector;
  final void Function(int, int) onRemoveConnector;
  final void Function(Offset) onDrag;

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

  void refreshSize() {}

  Map<String, dynamic> getState() {
    return {
      // "id": id,
      "x": position.value.dx,
      "y": position.value.dy,
      "widgets": widgets.value.map((widget) => widget.getState()).toList(),
    };
  }

  @override
  Widget build(BuildContext context) {
    List<Pin> pins = [];

    for (var endpoint in module.inputs) {
      print("Building input pin");
      pins.add(Pin(
        endpoint: endpoint,
        node: this,
        patch: patch,
        isInput: true,
        onAddConnector: onAddConnector,
        onRemoveConnector: onRemoveConnector,
      ));
    }

    for (var endpoint in module.outputs) {
      print("Building output pin");
      pins.add(Pin(
        endpoint: endpoint,
        node: this,
        patch: patch,
        isInput: false,
        onAddConnector: onAddConnector,
        onRemoveConnector: onRemoveConnector,
      ));
    }

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
