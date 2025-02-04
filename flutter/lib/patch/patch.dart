import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:metasampler/patch/module.dart';
import 'package:metasampler/views/presets.dart';

import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import '../settings.dart';
import 'pin.dart';
import '../plugins.dart';
import 'connector.dart';
import '../projects.dart';
import 'node.dart';
import 'right_click.dart';

import '../bindings/api/graph.dart' as api;

/* LIBRARY */

class Assets {
  Assets(String path) {
    projects = Projects(Directory(path + "projects"));
  }

  late final Projects projects;

  static Assets platformDefault() {
    if (Platform.isMacOS) {
      return Assets("/Users/chasekanipe/Github/assets/");
    } else if (Platform.isLinux) {
      return Assets("/home/chase/github/assets/");
    }

    print("Assets not found in default platform location");
    exit(1);
  }
}

extension FileExtention on FileSystemEntity {
  String get name {
    return path.split("/").last;
  }
}

class Patch extends StatefulWidget {
  Patch({
    // required this.rawPatch,
    required this.info,
  }) : super(key: UniqueKey());

  final ValueNotifier<List<Node>> nodes = ValueNotifier([]);
  final ValueNotifier<List<Connector>> connectors = ValueNotifier([]);
  final ValueNotifier<List<Node>> selectedNodes = ValueNotifier([]);

  // final RawPatch rawPatch;
  final PresetInfo info;
  final NewConnector newConnector = NewConnector();
  final ValueNotifier<Offset> moveToValue = ValueNotifier(Offset.zero);

  static Patch from(PresetInfo info) {
    return Patch(
      info: info,
      // rawPatch: RawPatch.create(),
    );
  }

  static Future<Patch?> load(PresetInfo info) async {
    var file = File(info.directory.path + "/patch.json");

    if (!await file.exists()) {
      return null;
    }

    print("Skipping Patch.load");
    return Patch(
      // rawPatch: rawPatch,
      info: info,
    );
  }

  Future<bool> save() async {
    print("Saving patch");
    var file = File(info.directory.path + "/patch.json");
    print("Skipping patch save");
    // rawPatch.save(file);
    return true;
  }

  void moveTo(double x, double y) {
    print("MOVE TO IN PATCH");
    moveToValue.value = Offset(x, y);
  }

  void addNewConnector() {
    if (newConnector.start != null && newConnector.end != null) {
      newConnector.start!
          .onAddConnector(newConnector.start!, newConnector.end!);
    }

    newConnector.reset();
  }

  Map<String, dynamic> getState() {
    return {
      // "nodes": nodes.value.map((e) => {e.module.path, e.getState()}).toList(),
      // "connectors": connectors.value.map((e) => e.toJson()).toList(),
    };
  }

  @override
  _Patch createState() => _Patch();
}

class _Patch extends State<Patch> with SingleTickerProviderStateMixin {
  final TransformationController controller = TransformationController();
  late AnimationController animationController;
  Animation<Matrix4> animation = AlwaysStoppedAnimation(Matrix4.identity());

  Offset rightClickOffset = Offset.zero;
  Offset moduleAddPosition = Offset.zero;
  bool showRightClickMenu = false;
  // late Timer timer;
  final focusNode = FocusNode();
  late final Ticker _ticker;

  @override
  void initState() {
    super.initState();

    Plugins.modules.addListener(onModuleListChanged);

    _ticker = createTicker(tick);
    _ticker.start();
  }

  @override
  void dispose() {
    controller.dispose();
    Plugins.modules.removeListener(onModuleListChanged);

    _ticker.dispose();

    super.dispose();
  }

  void removeNode(Node node) {
    // Remove the node
    widget.nodes.value = widget.nodes.value.where((n) => n != node).toList();

    // Remove any connectors to the node
    widget.connectors.value = widget.connectors.value.where((c) {
      return c.start.node != node && c.end.node != node;
    }).toList();

    updatePlayback();
  }

  void onModuleListChanged() {
    // Replace any nodes that have updated modules
    for (var module in Plugins.modules.value) {
      for (int j = 0; j < widget.nodes.value.length; j++) {
        var node = widget.nodes.value[j];
        if (node.module.name == module.name && node.module != module) {
          print("Replacing a patch node");
          Offset position = node.position.value;
          removeNode(node);
          addModule(module, position);
          j--;
        }
      }
    }

    // Remove any nodes that are no longer in the module list
    /*int i = 0;
    while (i < widget.nodes.value.length) {
      var node = widget.nodes.value[i];
      if (!Plugins.modules.value.contains(node.module)) {
        print("Removing node");
        removeNode(node);
      } else {
        i++;
      }
    }*/
  }

  void tick(Duration elapsed) {
    for (var node in widget.nodes.value) {
      for (var widget in node.widgets) {
        widget.tick(elapsed);
      }
    }
  }

  void moveTo(Offset offset) {
    print("LAST MOVING");
    animation = Matrix4Tween(
      begin: controller.value,
      end: Matrix4.translationValues(
        -offset.dx + MediaQuery.of(context).size.width / 2,
        -offset.dy + MediaQuery.of(context).size.height / 2,
        0,
      ),
    ).chain(CurveTween(curve: Curves.decelerate)).animate(animationController);

    animationController.forward(from: 0);
  }

  void updatePlayback() {
    // Create a new graph
    var graph = api.Graph.new();

    // Add all the cables to the graph
    for (var connector in widget.connectors.value) {
      // Skip if either node is null
      if (connector.start.node.rawNode == null ||
          connector.end.node.rawNode == null) continue;

      graph.addCable(
        srcNode: connector.start.node.rawNode!,
        srcEndpoint: connector.start.endpoint,
        dstNode: connector.end.node.rawNode!,
        dstEndpoint: connector.end.endpoint,
      );
    }

    // Add all the nodes to the graph
    for (var node in widget.nodes.value) {
      // Skip if node is null
      if (node.rawNode == null) continue;

      graph.addNode(node: node.rawNode!);
    }

    // Update the playback graph
    api.setPatch(graph: graph);
  }

  void addModule(Module module, Offset p) {
    Offset position = Offset(roundToGrid(p.dx), roundToGrid(p.dy));
    var node = Node(
      module: module,
      patch: widget,
      onAddConnector: (start, end) {
        addConnector(start, end);
        setState(() {});
      },
      onRemoveConnections: (pin) {
        removeConnectionsTo(pin);
        setState(() {});
      },
      position: position,
    );

    widget.nodes.value = [...widget.nodes.value, node];

    updatePlayback();
  }

  void addConnector(Pin start, Pin end) {
    var connector = Connector(
      start: start,
      end: end,
      type: start.endpoint.type,
      patch: widget,
    );

    widget.connectors.value = [...widget.connectors.value, connector];
    updatePlayback();
  }

  void removeConnectionsTo(Pin pin) {
    widget.connectors.value.removeWhere(
      (e) => e.start == pin || e.end == pin,
    );

    updatePlayback();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onSecondaryTapDown: (details) {
        // Offset offset = controller.toScene(details.localPosition);
        // moveTo(offset);

        setState(() {
          rightClickOffset = details.localPosition;
          showRightClickMenu = true;
        });
      },
      child: Stack(
        children: [
          InteractiveViewer(
            minScale: 0.2,
            maxScale: 1.5,
            panEnabled: true,
            scaleEnabled: true,
            clipBehavior: Clip.hardEdge,
            constrained: false,
            transformationController: controller,
            onInteractionUpdate: (details) {
              if (showRightClickMenu) {
                setState(() {
                  showRightClickMenu = false;
                });
              }

              if (widget.selectedNodes.value.isNotEmpty) {
                widget.selectedNodes.value = [];
              }
            },
            child: Listener(
              onPointerDown: (e) {
                moduleAddPosition = e.localPosition;
              },
              child: GestureDetector(
                onTap: () {
                  if (showRightClickMenu) {
                    setState(() {
                      showRightClickMenu = false;
                    });
                  }

                  if (widget.selectedNodes.value.isNotEmpty) {
                    widget.selectedNodes.value = [];
                  }
                },
                child: KeyboardListener(
                  focusNode: focusNode,
                  autofocus: true,
                  onKeyEvent: (e) {
                    if (e.logicalKey == LogicalKeyboardKey.delete ||
                        e.logicalKey == LogicalKeyboardKey.backspace) {
                      print("Get key delete");
                      /*for (var node in widget.selectedNodes.value) {
                        // widget.rawPatch.removeNode(node.id);
                        widget.nodes.removeWhere((n) => n.id == node.id);
                        widget.connectors.removeWhere((c) =>
                            c.start.nodeId == node.id ||
                            c.end.nodeId == node.id);
                      }*/

                      // widget.selectedNodes.value = [];
                      setState(() {});
                    }
                  },
                  child: SizedBox(
                    width: 10000,
                    height: 10000,
                    child: CustomPaint(
                      painter: Grid(),
                      child: Listener(
                        // Listen for new nodes
                        child: ValueListenableBuilder<List<Node>>(
                          valueListenable: widget.nodes,
                          builder: (context, nodes, child) {
                            // Listen for new connectors
                            return ValueListenableBuilder<List<Connector>>(
                              valueListenable: widget.connectors,
                              builder: (context, connectors, child) {
                                return Stack(
                                  children: <Widget>[widget.newConnector] +
                                      nodes +
                                      connectors,
                                );
                              },
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Visibility(
            visible: showRightClickMenu,
            child: Positioned(
              left: rightClickOffset.dx,
              top: rightClickOffset.dy,
              child: RightClickView(
                onAddModule: (info) {
                  addModule(info, moduleAddPosition);
                  setState(() {
                    showRightClickMenu = false;
                  });
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class Grid extends CustomPainter {
  Grid();

  @override
  void paint(Canvas canvas, ui.Size size) {
    final paint = Paint()
      ..color = const Color.fromRGBO(25, 25, 25, 1.0)
      ..strokeWidth = 1;

    for (double i = 0;
        i < size.width;
        i += GlobalSettings.gridSize.toDouble()) {
      var p1 = Offset(i, 0);
      var p2 = Offset(i, size.height);
      canvas.drawLine(p1, p2, paint);
    }

    for (double i = 0;
        i < size.height;
        i += GlobalSettings.gridSize.toDouble()) {
      var p1 = Offset(0, i);
      var p2 = Offset(size.width, i);
      canvas.drawLine(p1, p2, paint);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return false;
  }
}
