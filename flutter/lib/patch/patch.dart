import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:metasampler/bindings/api/cable.dart';
import 'package:metasampler/module/module.dart';
import 'package:metasampler/views/presets.dart';

import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import '../module/pin.dart';
import 'connector.dart';
import '../projects.dart';
import '../module/node.dart';
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
  bool shouldTick = true;

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

    /*if (rawPatch.load(file, plugins)) {
      return Patch(
        rawPatch: rawPatch,
        info: info,
      );
    }*/

    return null;
  }

  Future<bool> save() async {
    print("Saving patch");
    var file = File(info.directory.path + "/patch.json");
    print("Skipping patch save");
    // rawPatch.save(file);
    return true;
  }

  void disableTick() {
    shouldTick = false;
  }

  void enableTick() {
    shouldTick = true;
  }

  void moveTo(double x, double y) {
    print("MOVE TO IN PATCH");
    moveToValue.value = Offset(x, y);
  }

  /*void refreshUserInterface(ModuleInfo info) {
    print("Refreshing user interface");
    for (var node in nodes) {
      node.refreshUserInterface();
    }
  }*/

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

  void tick(Timer t) {
    /*if (widget.shouldTick) {
      for (var node in nodes) {
        for (var widget in node.widgets) {
          // callTickRecursive(widget);
        }
      }
    }*/
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

  @override
  void initState() {
    super.initState();

    print("Skipping patch initState");
  }

  @override
  void dispose() {
    super.dispose();
    controller.dispose();
    // timer.cancel();
  }

  void updateGraph() {
    // Create a new graph
    var graph = api.Graph.new();

    // Add all the cables to the graph
    for (var connector in widget.connectors.value) {
      var startId = connector.start.node.id;
      var startIndex = connector.start.index;
      var endId = connector.end.node.id;
      var endIndex = connector.end.index;

      var source = Connection(nodeId: startId, pinIndex: startIndex);
      var end = Connection(nodeId: endId, pinIndex: endIndex);

      var cable = Cable(source: source, destination: end);
      graph.addCable(cable: cable);
    }

    // Add all the nodes to the graph
    for (var node in widget.nodes.value) {
      graph.addNode(node: node.rawNode);
    }

    // Update the playback graph
    api.setPatch(graph: graph);
  }

  void addModule(Module module, Offset position) {
    var node = Node(
      module: module,
      patch: widget,
      onAddConnector: (start, end) {
        addConnector(start, end);
        setState(() {});
      },
      onRemoveConnections: (pin) {
        removeConnections(pin);
        setState(() {});
      },
      onDrag: (offset) {
        setState(() {});
      },
    );

    widget.nodes.value.add(node);
    widget.nodes.notifyListeners();
    updateGraph();
  }

  void addConnector(Pin start, Pin end) {
    var connector = Connector(
      start: start,
      end: end,
      type: start.endpoint.type,
      patch: widget,
    );

    widget.connectors.value.add(connector);
    widget.connectors.notifyListeners();
    updateGraph();
  }

  void removeConnections(Pin pin) {
    widget.connectors.value.removeWhere(
      (e) => e.start == pin || e.end == pin,
    );

    /*for (var node in widget.nodes.value) {
      node.refreshSize();
    }*/

    updateGraph();
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
                    print("Got key event");
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
          // PopupWindow(),
        ],
      ),
    );
  }
}

class Grid extends CustomPainter {
  @override
  void paint(Canvas canvas, ui.Size size) {
    const spacing = 30;
    final paint = Paint()
      ..color = const Color.fromRGBO(25, 25, 25, 1.0)
      ..strokeWidth = 2;

    List<Offset> points = [];
    for (double i = 0; i < size.width; i += spacing) {
      for (double j = 0; j < size.height; j += spacing) {
        points.add(Offset(i, j));
      }
    }

    canvas.drawPoints(ui.PointMode.points, points, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return false;
  }
}
