import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:metasampler/module/info.dart';
import 'package:metasampler/views/presets.dart';

import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import '../bindings/api/module.dart';
import '../module/pin.dart';
import 'connector.dart';
import '../projects.dart';
import '../module/node.dart';
import 'right_click.dart';

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

/*RawPatch Function() _ffiCreatePatch = core
    .lookup<NativeFunction<RawPatch Function()>>("ffi_create_patch")
    .asFunction();
/*bool Function(RawPatch, RawPlugins, Pointer<Utf8>) _ffiPatchLoad = core
    .lookup<NativeFunction<Bool Function(RawPatch, RawPlugins, Pointer<Utf8>)>>(
        "ffi_patch_load")
    .asFunction();*/
bool Function(RawPatch, Pointer<Utf8>) _ffiPatchSave = core
    .lookup<NativeFunction<Bool Function(RawPatch, Pointer<Utf8>)>>(
        "ffi_patch_save")
    .asFunction();
Pointer<Void> Function(RawPatch) _ffiPatchGetState = core
    .lookup<NativeFunction<Pointer<Void> Function(RawPatch)>>(
        "ffi_patch_get_state")
    .asFunction();
/*void Function(RawPatch, RawPlugins, Pointer<Void>) _ffiPatchSetState = core
    .lookup<NativeFunction<Void Function(RawPatch, RawPlugins, Pointer<Void>)>>(
        "ffi_patch_set_state")
    .asFunction();*/
void Function(RawPatch) _ffiPatchDestroy = core
    .lookup<NativeFunction<Void Function(RawPatch)>>("ffi_patch_destroy")
    .asFunction();
/*RawNode Function(RawPatch, RawPlugins, Pointer<Utf8>) _ffiPatchAddModule = core
    .lookup<
        NativeFunction<
            RawNode Function(
                RawPatch, RawPlugins, Pointer<Utf8>)>>("ffi_patch_add_module")
    .asFunction();*/
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
final class RawPatch extends Struct {
  @Int64()
  external int pointer;

  static RawPatch create() {
    return _ffiCreatePatch();
  }

  bool load(File file, Plugins plugins) {
    /*var rawPath = file.path.toNativeUtf8();
    var success = _ffiPatchLoad(this, plugins.rawPlugins, rawPath);
    calloc.free(rawPath);
    return success;*/
    return false;
  }

  bool save(File file) {
    var rawPath = file.path.toNativeUtf8();
    var success = _ffiPatchSave(this, rawPath);
    calloc.free(rawPath);
    return success;
  }

  /*RawNode addModule(String id) {
    var rawId = id.toNativeUtf8();
    RawNode rawNode = _ffiPatchAddModule(this, PLUGINS.rawPlugins, rawId);
    calloc.free(rawId);
    return rawNode;
  }*/

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
    // _ffiPatchSetState(this, PLUGINS.rawPlugins, state);
  }
}

final class RawConnector extends Struct {
  @Int32()
  external int startId;
  @Int32()
  external int startIndex;
  @Int32()
  external int endId;
  @Int32()
  external int endIndex;
}
*/
class Patch extends StatefulWidget {
  Patch({
    // required this.rawPatch,
    required this.info,
  }) : super(key: UniqueKey());

  final List<Node> nodes = [];
  final List<Connector> connectors = [];
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
    // var rawPatch = RawPatch.create();
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

  void refreshUserInterface(ModuleInfo info) {
    print("Refreshing user interface");
    for (var node in nodes) {
      node.refreshUserInterface();
    }
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
      "nodes": nodes.map((e) => {e.info.path, e.getState()}).toList(),
      "connectors": connectors.map((e) => e.toJson()).toList(),
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

    /*widget.moveToValue.addListener(() {
      print("MOVE VALUE LISTENER");
      moveTo(widget.moveToValue.value);
    });

    animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    )..addListener(() {
        print("Moving 3");
        controller.value = animation.value;
      });

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
    }*/
  }

  @override
  void dispose() {
    super.dispose();
    controller.dispose();
    // timer.cancel();
  }

  void addModule(Module info, Offset position) {
    var node = Node(
      info: info,
      patch: widget,
      connectors: widget.connectors,
      selectedNodes: widget.selectedNodes,
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

    widget.nodes.add(node);
  }

  void addConnector(Pin start, Pin end) {
    var connector = Connector(
      start: start,
      end: end,
      type: start.type,
      selectedNodes: widget.selectedNodes,
    );

    widget.connectors.add(connector);
  }

  void removeConnector(int nodeId, int pinIndex) {
    // widget.rawPatch.removeConnector(nodeId, pinIndex);
    widget.connectors.removeWhere(
      (e) =>
          (e.start.nodeId == nodeId && e.start.pinIndex == pinIndex) ||
          (e.end.nodeId == nodeId && e.end.pinIndex == pinIndex),
    );

    for (var node in widget.nodes) {
      node.refreshSize();
    }
  }

  @override
  Widget build(BuildContext context) {
    /*var nodeCount = widget.rawPatch.getNodeCount();
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
    }*/

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
                      for (var node in widget.selectedNodes.value) {
                        // widget.rawPatch.removeNode(node.id);
                        widget.nodes.removeWhere((n) => n.id == node.id);
                        widget.connectors.removeWhere((c) =>
                            c.start.nodeId == node.id ||
                            c.end.nodeId == node.id);
                      }

                      widget.selectedNodes.value = [];
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
                              widget.nodes +
                              widget.connectors,
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
