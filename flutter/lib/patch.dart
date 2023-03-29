import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ffi/ffi.dart';

import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'dart:ffi';
import 'dart:ui' as ui;

import 'main.dart';
import 'core.dart';
import 'projects.dart';
import 'module.dart';
import 'plugins.dart';

import 'views/info.dart';
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
      return Assets("/home/chase/github/content/");
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
bool Function(RawPatch, Pointer<Utf8>) _ffiPatchLoad = core
    .lookup<NativeFunction<Bool Function(RawPatch, Pointer<Utf8>)>>(
        "ffi_patch_load")
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

  static RawPatch from(String path) {
    var patch = RawPatch.create();
    patch.load(path);
    return patch;
  }

  bool load(String path) {
    var rawPath = path.toNativeUtf8();
    var success = _ffiPatchLoad(this, rawPath);
    calloc.free(rawPath);
    return success;
  }

  RawNode addModule(String id) {
    var rawId = id.toNativeUtf8();
    RawNode rawNode = _ffiPatchAddModule(this, PLUGINS.rawPlugin, rawId);
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
    _ffiPatchRemoveConnector(this, nodeId, pinIndex);
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
    required this.path,
    required this.name,
    required this.description,
  });

  /*static PatchInfo blank() {
    return PatchInfo(
      path:
          "/Users/chasekanipe/Github/assets/projects/NewProject/patches/Patch 1.json",
      name: ValueNotifier("New Patch"),
      description: ValueNotifier("Blank patch description"),
    );
  }*/

  static Future<PatchInfo?> from(String path) async {
    File file = File(path);
    if (await file.exists()) {
      var contents = await file.readAsString();
      var json = jsonDecode(contents);

      return PatchInfo(
        path: path,
        name: json["name"],
        description: json["description"],
      );
    }

    return null;
  }

  Future<Patch?> load() async {
    print("Load not implemented for patch");
    return null;
  }

  final String path;
  final ValueNotifier<String> name;
  final ValueNotifier<String> description;
}

class Patch extends StatefulWidget {
  Patch({
    required this.rawPatch,
    required this.path,
    required this.name,
    required this.description,
  });

  final RawPatch rawPatch;
  final ValueNotifier<String> path;
  final ValueNotifier<String> name;
  final ValueNotifier<String> description;
  final NewConnector newConnector = NewConnector();

  static Patch blank() {
    return Patch.create(
      "/Users/chasekanipe/Github/assets/projects/NewProject/patches/New Patch.json",
      "New Patch",
      "Blank patch description",
    );
  }

  static Patch create(String path, String name, String description) {
    return Patch(
      rawPatch: RawPatch.create(),
      path: ValueNotifier(path),
      name: ValueNotifier(name),
      description: ValueNotifier(description),
    );
  }

  @override
  _Patch createState() => _Patch();
}

class _Patch extends State<Patch> {
  List<Node> nodes = [];
  List<Connector> connectors = [];

  TransformationController controller = TransformationController();
  Offset rightClickOffset = Offset.zero;
  bool showRightClickMenu = false;

  @override
  void initState() {
    super.initState();
    var count = widget.rawPatch.getNodeCount();
    for (var i = 0; i < count; i++) {
      var rawNode = widget.rawPatch.getNode(i);
      nodes.add(
        Node(
          rawNode: rawNode,
          patch: widget,
          onAddConnector: (start, end) {
            addConnector(start, end);
            setState(() {});
          },
          onRemoveConnector: (nodeId, pinIndex) {
            widget.rawPatch.removeConnector(nodeId, pinIndex);
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
  }

  void addModule(String id) {
    var rawNode = widget.rawPatch.addModule(id);
    // var node = Node(rawNode, widget);
    // nodes.add(node);
  }

  void addConnector(Pin start, Pin end) {
    var connector = Connector(
      start: start,
      end: end,
      type: start.type,
    );

    if (widget.rawPatch.addConnector(
      start.nodeId,
      start.pinIndex,
      end.nodeId,
      end.pinIndex,
    )) {
      connectors.add(connector);
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
          onAddConnector: (start, end) {
            addConnector(start, end);
            setState(() {});
          },
          onRemoveConnector: (nodeId, pinIndex) {
            widget.rawPatch.removeConnector(nodeId, pinIndex);
            connectors.removeWhere(
              (element) =>
                  (element.start.nodeId == nodeId &&
                      element.start.pinIndex == pinIndex) ||
                  (element.end.nodeId == nodeId &&
                      element.end.pinIndex == pinIndex),
            );
            setState(() {});
          },
          onDrag: (offset) {
            setState(() {});
          },
        );
        nodes.add(node);
      }
    }

    return GestureDetector(
      onTapDown: (details) {
        setState(() {
          showRightClickMenu = false;
        });
      },
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
            },
            child: GestureDetector(
              child: SizedBox(
                width: 10000,
                height: 10000,
                child: CustomPaint(
                  painter: Grid(),
                  child: Stack(
                    children:
                        <Widget>[widget.newConnector] + nodes + connectors,
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
                addPosition: rightClickOffset,
                onAddModule: (info) {
                  addModule(info.id);
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
  ConnectorPainter(this.start, this.end, this.type);

  Offset start;
  Offset end;
  IO type;

  @override
  void paint(Canvas canvas, ui.Size size) {
    final paint = Paint()
      ..color = const Color.fromRGBO(255, 255, 255, 1.0)
      ..strokeWidth = 3;

    if (type == IO.audio) {
      paint.color = Colors.blue;
    } else if (type == IO.midi) {
      paint.color = Colors.green;
    } else if (type == IO.control) {
      paint.color = Colors.red;
    } else if (type == IO.time) {
      paint.color = Colors.deepPurpleAccent;
    }

    canvas.drawLine(start, end, paint);
  }

  @override
  bool shouldRepaint(ConnectorPainter oldDelegate) {
    return oldDelegate.start.dx != start.dx ||
        oldDelegate.start.dy != start.dy ||
        oldDelegate.end.dx != end.dy ||
        oldDelegate.end.dy != end.dy ||
        oldDelegate.type != type;
  }
}

class Connector extends StatelessWidget {
  Connector({
    required this.start,
    required this.end,
    required this.type,
  });

  final Pin start;
  final Pin end;
  final IO type;

  @override
  Widget build(BuildContext context) {
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
              ),
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
            painter: ConnectorPainter(startOffset, endOffset, type),
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

/*class Patch extends StatefulWidget {
  Patch(this.app, this.info) {
    _patch.load(info.path);
    refresh();
  }

  final App app;
  final PatchInfo info;
  final RawPatch _patch = RawPatch.create(); // TODO: Fix leak

  var connectors = <Connector>[];
  ValueNotifier<List<Node>> nodes = ValueNotifier([]);

  // Rename to node???
  bool addModule2(String name) {
    /*_patch.addModule(name);*/
    /* plugins.createModule(name); */

    return true;
  }

  /* Old Methods */

  bool addModule(String name, Offset addPosition) {
    var ret = app.core.addModule(name);

    if (ret) {
      var moduleRaw = app.core.getNode(app.core.getNodeCount() - 1);

      var x = addPosition.dx.toInt() - moduleRaw.getWidth() ~/ 2;
      var y = addPosition.dy.toInt() - moduleRaw.getHeight() ~/ 2;

      moduleRaw.setX(x);
      moduleRaw.setY(y);

      modules.value.add(Module(app, moduleRaw));
    }

    return ret;
  }

  void removeModule(int id) {
    modules.value.retainWhere((element) => element.id != id);
    connectors.retainWhere((element) => element.start.moduleId != id);
    connectors.retainWhere((element) => element.end.moduleId != id);
    app.core.removeNode(id);
  }

  bool addConnection(Connector c) {
    if (app.core.addConnector(
        c.start.moduleId, c.start.index, c.end.moduleId, c.end.index)) {
      connectors.add(c);
      return true;
    }

    return false;
  }

  void removeConnection(int moduleId, int pinIndex) {
    connectors.retainWhere((element) => !(element.start.moduleId == moduleId &&
        element.start.index == pinIndex));
    connectors.retainWhere((element) =>
        !(element.end.moduleId == moduleId && element.end.index == pinIndex));
    app.core.removeConnector(moduleId, pinIndex);
  }

  void refresh() {
    modules.value.clear();
    connectors.clear();

    int moduleCount = app.core.getNodeCount();

    for (int i = 0; i < moduleCount; i++) {
      var moduleRaw = app.core.getNode(i);
      var module = Module(app, moduleRaw);
      modules.value.add(module);
    }

    int connectorCount = app.core.getConnectorCount();

    for (int i = 0; i < connectorCount; i++) {
      var startId = app.core.getConnectorStartId(i);
      var endId = app.core.getConnectorEndId(i);
      var startIndex = app.core.getConnectorStartIndex(i);
      var endIndex = app.core.getConnectorEndIndex(i);

      var type = IO.audio;

      for (var module in modules.value) {
        if (module.id == startId) {
          type = module.pins[startIndex].type;
        }
      }

      connectors.add(Connector(startId, startIndex, endId, endIndex, type));
    }
  }

  @override
  State<Patch> createState() => _Patch();
}

class _Patch extends State<Patch> {
  late Grid grid;

  var mouseOffset = const Offset(0, 0);
  var righttClickOffset = const Offset(0, 0);
  var rightClickVisible = false;
  var moduleMenuVisible = false;

  var wheelVisible = false;
  List<String> wheelModules = [];

  FocusNode focusNode = FocusNode();

  TransformationController controller = TransformationController();

  double zoom = 1.0;

  @override
  void initState() {
    grid = Grid(widget.app);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    FocusScope.of(context).requestFocus(focusNode);

    return RawKeyboardListener(
      focusNode: focusNode,
      /*onKey: (event) {
          if (rightClickVisible) {
            return;
          }

          if (event.data.physicalKey == PhysicalKeyboardKey.keyS) {
            if (event.runtimeType == RawKeyDownEvent) {
              setState(() {
                wheelVisible = true;
                wheelModules = ["Sampler", "Simpler", "Granular", "Looper"];
              });
            } else {
              setState(() {
                wheelVisible = false;
              });
            }
          } else if (event.data.physicalKey == PhysicalKeyboardKey.keyO) {
            if (event.runtimeType == RawKeyDownEvent) {
              setState(() {
                wheelVisible = true;
                wheelModules = [
                  "Digital",
                  "Analog",
                  "Noise",
                  "Wavetable",
                  "Additive",
                  "Polygon"
                ];
              });
            } else {
              setState(() {
                wheelVisible = false;
              });
            }
          } else if (event.data.physicalKey == PhysicalKeyboardKey.keyF) {
            if (event.runtimeType == RawKeyDownEvent) {
              setState(() {
                wheelVisible = true;
                wheelModules = ["Sampler", "Analog Osc"];
              });
            } else {
              setState(() {
                wheelVisible = false;
              });
            }
          }
        },*/
      child: ClipRect(
        child: Stack(
          fit: StackFit.loose,
          children: [
            InteractiveViewer(
              transformationController: controller,
              child: grid,
              minScale: 0.1,
              maxScale: 1.5,
              panEnabled: true,
              scaleEnabled: true, // widget.app.patchingScaleEnabled,
              clipBehavior: Clip.none,
              constrained: false,
              onInteractionUpdate: (details) {
                setState(() {
                  zoom *= details.scale;
                  if (zoom < 0.1) {
                    zoom = 0.1;
                  } else if (zoom > 1.5) {
                    zoom = 1.5;
                  }
                });
              },
            ),
            GestureDetector(
              // Right click menu region
              behavior: HitTestBehavior.translucent,
              onSecondaryTap: () {
                print("Secondary tap right-click menu");

                if (widget.app.selectedModule.value == -1) {
                  righttClickOffset = mouseOffset;
                  setState(() {
                    rightClickVisible = true;
                  });
                } else {
                  righttClickOffset = mouseOffset;
                  setState(() {
                    moduleMenuVisible = true;
                  });
                }
              },
            ),
            Visibility(
              // Right click menu
              visible: rightClickVisible,
              child: Positioned(
                left: righttClickOffset.dx,
                top: righttClickOffset.dy,
                child: RightClickView(
                  widget.app,
                  specs: widget.app.moduleSpecs,
                  addPosition: Offset(
                    righttClickOffset.dx - controller.value.getTranslation().x,
                    righttClickOffset.dy - controller.value.getTranslation().y,
                  ),
                ),
              ),
            ),
            Visibility(
              // Right click menu
              visible: moduleMenuVisible,
              child: Positioned(
                left: righttClickOffset.dx,
                top: righttClickOffset.dy,
                child: ModuleMenu(),
              ),
            ),
            Listener(
              // Hide right-click menu
              behavior: HitTestBehavior.translucent,
              onPointerDown: (event) {
                if (rightClickVisible && widget.app.patchingScaleEnabled) {
                  setState(() {
                    rightClickVisible = false;
                  });
                } else if (moduleMenuVisible &&
                    widget.app.patchingScaleEnabled) {
                  setState(() {
                    moduleMenuVisible = false;
                  });
                }
              },
            ),
            Visibility(
              // Module wheel
              visible: wheelVisible,
              child: Positioned(
                left: mouseOffset.dx - 150,
                top: mouseOffset.dy - 100,
                child: ModuleWheel(wheelModules),
              ),
            ),
            MouseRegion(
              opaque: false,
              onHover: (event) {
                mouseOffset = event.localPosition;
                // print(mouseOffset.toString());
              },
            ),
            ValueListenableBuilder<String>(
              valueListenable: widget.app.pinLabel,
              builder: (context, value, w) {
                return Visibility(
                  visible: value != "",
                  child: Positioned(
                    left: widget.app.labelPosition.dx,
                    top: widget.app.labelPosition.dy,
                    child: PinLabel(value),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}*/
