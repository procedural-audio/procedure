import 'dart:math';

import 'package:flutter/material.dart';
import 'package:ffi/ffi.dart';
import 'package:flutter/services.dart';

import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'dart:ffi';
import 'dart:ui' as ui;

import 'core.dart';
import 'projects.dart';
import 'module.dart';
import 'plugins.dart';

import 'views/right_click.dart';

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

class Images {
  Images(this.directory);

  final Directory directory;

  Image? loadImage(String name) {
    print("Loading image asset");
    return null;
  }
}

extension FileExtention on FileSystemEntity {
  String get name {
    return path.split("/").last;
  }
}

RawPatch Function() _ffiCreatePatch = core
    .lookup<NativeFunction<RawPatch Function()>>("ffi_create_patch")
    .asFunction();
bool Function(RawPatch, RawPlugins, Pointer<Utf8>) _ffiPatchLoad = core
    .lookup<NativeFunction<Bool Function(RawPatch, RawPlugins, Pointer<Utf8>)>>(
        "ffi_patch_load")
    .asFunction();
bool Function(RawPatch, Pointer<Utf8>) _ffiPatchSave = core
    .lookup<NativeFunction<Bool Function(RawPatch, Pointer<Utf8>)>>(
        "ffi_patch_save")
    .asFunction();
Pointer<Void> Function(RawPatch) _ffiPatchGetState = core
    .lookup<NativeFunction<Pointer<Void> Function(RawPatch)>>(
        "ffi_patch_get_state")
    .asFunction();
void Function(RawPatch, RawPlugins, Pointer<Void>) _ffiPatchSetState = core
    .lookup<NativeFunction<Void Function(RawPatch, RawPlugins, Pointer<Void>)>>(
        "ffi_patch_set_state")
    .asFunction();
void Function(RawPatch) _ffiPatchDestroy = core
    .lookup<NativeFunction<Void Function(RawPatch)>>("ffi_patch_destroy")
    .asFunction();
RawNode Function(RawPatch, RawPlugins, Pointer<Utf8>) _ffiPatchAddModule = core
    .lookup<
        NativeFunction<
            RawNode Function(
                RawPatch, RawPlugins, Pointer<Utf8>)>>("ffi_patch_add_module")
    .asFunction();
bool Function(RawPatch, int) _ffiPatchRemoveNode = core
    .lookup<NativeFunction<Bool Function(RawPatch, Int32)>>(
        "ffi_patch_remove_node")
    .asFunction();
int Function(RawPatch) _ffiPatchGetNodeCount = core
    .lookup<NativeFunction<Int64 Function(RawPatch)>>(
        "ffi_patch_get_node_count")
    .asFunction();
RawNode Function(RawPatch, int) _ffiPatchGetNode = core
    .lookup<NativeFunction<RawNode Function(RawPatch, Int64)>>(
        "ffi_patch_get_node")
    .asFunction();
int Function(RawPatch) _ffiPatchGetConnectorCount = core
    .lookup<NativeFunction<Int64 Function(RawPatch)>>(
        "ffi_patch_get_connector_count")
    .asFunction();
RawConnector Function(RawPatch, int) _ffiPatchGetConnector = core
    .lookup<NativeFunction<RawConnector Function(RawPatch, Int64)>>(
        "ffi_patch_get_connector")
    .asFunction();
bool Function(RawPatch, int, int, int, int) _ffiPatchAddConnector = core
    .lookup<
        NativeFunction<
            Bool Function(RawPatch, Int32, Int32, Int32,
                Int32)>>("ffi_patch_add_connector")
    .asFunction();
void Function(RawPatch, int, int) _ffiPatchRemoveConnector = core
    .lookup<NativeFunction<Void Function(RawPatch, Int32, Int32)>>(
        "ffi_patch_remove_connector")
    .asFunction();

// TODO: Make sure this isn't leaked
class RawPatch extends Struct {
  @Int64()
  external int pointer;

  static RawPatch create() {
    return _ffiCreatePatch();
  }

  /*static RawPatch? from(File file) {
    var patch = RawPatch.create();

    if (patch.load(file.path)) {
      return patch;
    }

    return null;
  }*/

  bool load(File file, Plugins plugins) {
    var rawPath = file.path.toNativeUtf8();
    var success = _ffiPatchLoad(this, plugins.rawPlugins, rawPath);
    calloc.free(rawPath);
    return success;
  }

  bool save(File file) {
    var rawPath = file.path.toNativeUtf8();
    var success = _ffiPatchSave(this, rawPath);
    calloc.free(rawPath);
    return success;
  }

  RawNode addModule(String id) {
    var rawId = id.toNativeUtf8();
    RawNode rawNode = _ffiPatchAddModule(this, PLUGINS.rawPlugins, rawId);
    calloc.free(rawId);
    return rawNode;
  }

  int getNodeCount() {
    return _ffiPatchGetNodeCount(this);
  }

  RawNode getNode(int id) {
    return _ffiPatchGetNode(this, id);
  }

  int getConnectorCount() {
    return _ffiPatchGetConnectorCount(this);
  }

  RawConnector getConnector(int index) {
    return _ffiPatchGetConnector(this, index);
  }

  bool addConnector(int startId, int startIndex, int endId, int endIndex) {
    return _ffiPatchAddConnector(this, startId, startIndex, endId, endIndex);
  }

  void removeConnector(int nodeId, int pinIndex) {
    return _ffiPatchRemoveConnector(this, nodeId, pinIndex);
  }

  Pointer<Void> getState() {
    return _ffiPatchGetState(this);
  }

  bool removeNode(int id) {
    return _ffiPatchRemoveNode(this, id);
  }

  void setState(Pointer<Void> state) {
    _ffiPatchSetState(this, PLUGINS.rawPlugins, state);
  }
}

class RawConnector extends Struct {
  @Int32()
  external int startId;
  @Int32()
  external int startIndex;
  @Int32()
  external int endId;
  @Int32()
  external int endIndex;
}

class PatchInfo {
  PatchInfo({
    required this.directory,
    required this.name,
    required this.description,
  });

  static PatchInfo blank(Directory directory) {
    return PatchInfo(
      directory: Directory(directory.path + "/New Patch"),
      name: ValueNotifier("New Patch"),
      description: ValueNotifier("New patch description"),
    );
  }

  static Future<PatchInfo?> load(Directory directory) async {
    if (await directory.exists()) {
      File file = File(directory.path + "/info.json");
      if (await file.exists()) {
        var contents = await file.readAsString();
        var json = jsonDecode(contents);

        return PatchInfo(
          directory: directory,
          name: ValueNotifier(json["name"] ?? "Some Name"),
          description: ValueNotifier(json["description"] ?? "Some Description"),
        );
      }
    }

    return null;
  }

  Future<bool> save() async {
    if (!await directory.exists()) {
      await directory.create();
    }

    print("Saving patch info");

    File file = File(directory.path + "/info.json");
    await file.writeAsString(jsonEncode({
      "name": name.value,
      "description": description.value,
    }));

    return true;
  }

  final Directory directory;
  final ValueNotifier<String> name;
  final ValueNotifier<String> description;
}

class Patch extends StatefulWidget {
  Patch({
    required this.rawPatch,
    required this.info,
  }) : super(key: UniqueKey());

  final RawPatch rawPatch;
  final PatchInfo info;
  final NewConnector newConnector = NewConnector();
  bool shouldTick = true;

  static Patch from(PatchInfo info) {
    return Patch(
      info: info,
      rawPatch: RawPatch.create(),
    );
  }

  static Future<Patch?> load(PatchInfo info, Plugins plugins) async {
    var rawPatch = RawPatch.create();
    var file = File(info.directory.path + "/patch.json");

    if (!file.existsSync()) {
      return null;
    }

    if (rawPatch.load(file, plugins)) {
      return Patch(
        rawPatch: rawPatch,
        info: info,
      );
    }

    return null;
  }

  Future<bool> save() async {
    var file = File(info.directory.path + "/patch.json");
    rawPatch.save(file);
    await info.save();
    return true;
  }

  void disableTick() {
    shouldTick = false;
  }

  void enableTick() {
    shouldTick = true;
  }

  @override
  _Patch createState() => _Patch();
}

class _Patch extends State<Patch> {
  final List<Node> nodes = [];
  final List<Connector> connectors = [];
  final ValueNotifier<List<Node>> selectedNodes = ValueNotifier([]);

  TransformationController controller = TransformationController();
  Offset rightClickOffset = Offset.zero;
  Offset moduleAddPosition = Offset.zero;
  bool showRightClickMenu = false;
  late Timer timer;
  final focusNode = FocusNode();

  void tick(Timer t) {
    if (widget.shouldTick) {
      for (var node in nodes) {
        for (var widget in node.widgets) {
          callTickRecursive(widget);
        }
      }
    }
  }

  @override
  void initState() {
    super.initState();

    timer = Timer.periodic(
      const Duration(milliseconds: 20),
      tick,
    );

    var count = widget.rawPatch.getNodeCount();
    for (var i = 0; i < count; i++) {
      var rawNode = widget.rawPatch.getNode(i);
      nodes.add(
        Node(
          rawNode: rawNode,
          patch: widget,
          connectors: connectors,
          selectedNodes: selectedNodes,
          onAddConnector: (start, end) {
            addConnector(start, end);
            setState(() {});
          },
          onRemoveConnector: (nodeId, pinIndex) {
            removeConnector(nodeId, pinIndex);
            setState(() {});
          },
          onDrag: (offset) {
            setState(() {});
          },
        ),
      );
    }

    count = widget.rawPatch.getConnectorCount();
    for (var i = 0; i < count; i++) {
      var rawConnector = widget.rawPatch.getConnector(i);
      for (var startNode in nodes) {
        if (startNode.id == rawConnector.startId) {
          var startPin = startNode.pins[rawConnector.startIndex];
          for (var endNode in nodes) {
            if (endNode.id == rawConnector.endId) {
              var endPin = endNode.pins[rawConnector.endIndex];
              connectors.add(Connector(
                start: startPin,
                end: endPin,
                type: startPin.type,
                selectedNodes: selectedNodes,
              ));
            }
          }
        }
      }
    }
  }

  @override
  void dispose() {
    super.dispose();
    nodes.clear();
    connectors.clear();
    timer.cancel();
  }

  void addModule(String id, Offset position) {
    var rawNode = widget.rawPatch.addModule(id);
    rawNode.setX(position.dx);
    rawNode.setY(position.dy);
  }

  void addConnector(Pin start, Pin end) {
    if (widget.rawPatch.addConnector(
      start.nodeId,
      start.pinIndex,
      end.nodeId,
      end.pinIndex,
    )) {
      for (var node in nodes) {
        node.refreshSize();
      }
    }
  }

  void removeConnector(int nodeId, int pinIndex) {
    widget.rawPatch.removeConnector(nodeId, pinIndex);
    connectors.removeWhere(
      (e) =>
          (e.start.nodeId == nodeId && e.start.pinIndex == pinIndex) ||
          (e.end.nodeId == nodeId && e.end.pinIndex == pinIndex),
    );

    for (var node in nodes) {
      node.refreshSize();
    }
  }

  @override
  Widget build(BuildContext context) {
    var nodeCount = widget.rawPatch.getNodeCount();
    for (int i = 0; i < nodeCount; i++) {
      if (i >= nodes.length) {
        var rawNode = widget.rawPatch.getNode(i);
        var node = Node(
          rawNode: rawNode,
          patch: widget,
          connectors: connectors,
          selectedNodes: selectedNodes,
          onAddConnector: (start, end) {
            addConnector(start, end);
            setState(() {});
          },
          onRemoveConnector: (nodeId, pinIndex) {
            removeConnector(nodeId, pinIndex);
            setState(() {});
          },
          onDrag: (offset) {
            setState(() {});
          },
        );
        nodes.add(node);
      }
    }

    var connectorCount = widget.rawPatch.getConnectorCount();
    for (int i = 0; i < connectorCount; i++) {
      if (i >= connectors.length) {
        var rawConnector = widget.rawPatch.getConnector(i);

        for (var startNode in nodes) {
          if (startNode.id == rawConnector.startId) {
            for (var endNode in nodes) {
              if (endNode.id == rawConnector.endId) {
                var startPin = startNode.pins[rawConnector.startIndex];
                var endPin = endNode.pins[rawConnector.endIndex];

                var connector = Connector(
                  start: startPin,
                  end: endPin,
                  type: startPin.type,
                  selectedNodes: selectedNodes,
                );

                connectors.add(connector);
              }
            }
          }
        }
      }
    }

    return GestureDetector(
      onSecondaryTapDown: (details) {
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

              if (selectedNodes.value.isNotEmpty) {
                selectedNodes.value = [];
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

                  if (selectedNodes.value.isNotEmpty) {
                    selectedNodes.value = [];
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
                      for (var node in selectedNodes.value) {
                        widget.rawPatch.removeNode(node.id);
                        nodes.removeWhere((n) => n.id == node.id);
                        connectors.removeWhere((c) =>
                            c.start.nodeId == node.id ||
                            c.end.nodeId == node.id);
                      }

                      selectedNodes.value = [];
                      setState(() {});
                    }
                  },
                  child: SizedBox(
                    width: 10000,
                    height: 10000,
                    child: CustomPaint(
                      painter: Grid(),
                      child: Listener(
                        child: Stack(
                          children: <Widget>[widget.newConnector] +
                              nodes +
                              connectors,
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
                  addModule(info.id, moduleAddPosition);
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

class ConnectorPainter extends CustomPainter {
  ConnectorPainter(this.initialStart, this.initialEnd, this.type, this.focused);

  Offset initialStart;
  Offset initialEnd;
  IO type;
  bool focused;

  @override
  void paint(Canvas canvas, ui.Size size) {
    final paint = Paint()
      ..color = const Color.fromRGBO(255, 255, 255, 1.0)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    if (type == IO.audio) {
      paint.color = Colors.blue.withOpacity(focused ? 1.0 : 0.3);
    } else if (type == IO.midi) {
      paint.color = Colors.green.withOpacity(focused ? 1.0 : 0.3);
    } else if (type == IO.control) {
      paint.color = Colors.red.withOpacity(focused ? 1.0 : 0.3);
    } else if (type == IO.time) {
      paint.color = Colors.deepPurpleAccent.withOpacity(focused ? 1.0 : 0.3);
    }

    Offset start = Offset(initialStart.dx + 9, initialStart.dy + 2);
    Offset end = Offset(initialEnd.dx - 3, initialEnd.dy + 2);

    double distance = (end - start).distance;
    double firstOffset = min(distance, 40);

    Offset start1 = Offset(start.dx + firstOffset, start.dy);
    Offset end1 = Offset(end.dx - firstOffset, end.dy);
    Offset center = Offset((start.dx + end.dx) / 2, (start.dy + end.dy) / 2);

    Path path = Path();

    path.moveTo(start.dx, start.dy);
    path.quadraticBezierTo(start1.dx + 10, start1.dy, center.dx, center.dy);

    path.moveTo(end.dx, end.dy);
    path.quadraticBezierTo(end1.dx - 10, end1.dy, center.dx, center.dy);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(ConnectorPainter oldDelegate) {
    return oldDelegate.initialStart.dx != initialStart.dx ||
        oldDelegate.initialStart.dy != initialStart.dy ||
        oldDelegate.initialEnd.dx != initialEnd.dy ||
        oldDelegate.initialEnd.dy != initialEnd.dy ||
        oldDelegate.type != type;
  }
}

class Connector extends StatelessWidget {
  Connector({
    required this.start,
    required this.end,
    required this.type,
    required this.selectedNodes,
  }) : super(key: UniqueKey());

  final Pin start;
  final Pin end;
  final IO type;
  final ValueNotifier<List<Node>> selectedNodes;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<Node>>(
      valueListenable: selectedNodes,
      builder: (context, selectedNodes, child) {
        bool focused = selectedNodes.contains(start.node) ||
            selectedNodes.contains(end.node);
        return ValueListenableBuilder<Offset>(
          valueListenable: start.node.position,
          builder: (context, startModuleOffset, child) {
            return ValueListenableBuilder<Offset>(
              valueListenable: end.node.position,
              builder: (context, endModuleOffset, child) {
                return CustomPaint(
                  painter: ConnectorPainter(
                    Offset(
                      start.offset.dx + startModuleOffset.dx + 15 / 2,
                      start.offset.dy + startModuleOffset.dy + 15 / 2,
                    ),
                    Offset(
                      end.offset.dx + endModuleOffset.dx + 15 / 2,
                      end.offset.dy + endModuleOffset.dy + 15 / 2,
                    ),
                    type,
                    focused,
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}

class NewConnector extends StatelessWidget {
  Pin? start;
  final ValueNotifier<Offset?> offset = ValueNotifier(null);
  Pin? end;
  IO type = IO.audio;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Offset?>(
      valueListenable: offset,
      builder: (context, offset, child) {
        if (start != null && offset != null) {
          var startOffset = Offset(
            start!.offset.dx + start!.node.position.value.dx + 15 / 2,
            start!.offset.dy + start!.node.position.value.dy + 15 / 2,
          );

          var endOffset = Offset(
            startOffset.dx + offset.dx - 15 / 2,
            startOffset.dy + offset.dy - 15 / 2,
          );

          return CustomPaint(
            painter: ConnectorPainter(startOffset, endOffset, type, true),
          );
        } else {
          return Container();
        }
      },
    );
  }
}

class Grid extends CustomPainter {
  @override
  void paint(Canvas canvas, ui.Size size) {
    const spacing = 25;
    final paint = Paint()
      ..color = const Color.fromRGBO(25, 25, 25, 1.0)
      ..strokeWidth = 1;

    for (double i = 0; i < size.width; i += spacing) {
      final p1 = Offset(i, 0);
      final p2 = Offset(i, size.height);

      canvas.drawLine(p1, p2, paint);
    }

    for (double i = 0; i < size.height; i += spacing) {
      final p1 = Offset(0, i);
      final p2 = Offset(size.width, i);

      canvas.drawLine(p1, p2, paint);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return false;
  }
}
