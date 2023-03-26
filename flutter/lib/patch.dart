import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ffi/ffi.dart';

import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'dart:ffi';

import 'main.dart';
import 'core.dart';
import 'projects.dart';
import 'module.dart';

import 'views/info.dart';
import 'views/right_click.dart';

class AudioPluginsCategory {
  AudioPluginsCategory(this.name, this.plugins);

  String name;
  List<String> plugins;
}

class AudioPlugins {
  final _channel =
      const BasicMessageChannel("AudioPlugins", JSONMessageCodec());

  ValueNotifier<int?> processAddress = ValueNotifier(null);

  ValueNotifier<List<AudioPluginsCategory>> plugins = ValueNotifier([
    AudioPluginsCategory("Synths", ["Diva", "Omnisphere"]),
    AudioPluginsCategory("Samplers", ["Kontakt", "Keyscape"]),
    AudioPluginsCategory("Effects", ["ValhallaRoom", "ValhallaDelay"])
  ]);

  AudioPlugins() {
    _channel.setMessageHandler(messageHandler);
    _channel.send(jsonEncode({"message": "list plugins"}));
    _channel.send(jsonEncode({"message": "get process"}));
  }

  void createPlugin(int id, String name) {
    _channel
        .send(jsonEncode({"message": "create", "name": name, "module_id": id}));
  }

  void showPlugin(int id) {
    _channel.send(jsonEncode({"message": "show", "module_id": id}));
  }

  Future<String> messageHandler(dynamic message) async {
    if (message != null) {
      if (message is String) {
        if (message.contains("process addr")) {
          var num = message.split(" ").last;
          var addr = int.tryParse(num);

          if (addr != null) {
            print("Setting plugin process addr " + addr.toString());
            processAddress.value = addr;
          } else {
            print("Failed to parse plugin process addr");
          }
        } else {
          print("Recieved string message: " + message);
        }
      } else {
        print("Recieved other typed message: " + message.toString());
      }
    } else {
      print("Recieved null message");
    }

    return "Reply message";
  }
}

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

bool Function(RawPatch, Pointer<Utf8>) _ffiPatchAddModule = core
    .lookup<NativeFunction<Bool Function(RawPatch, Pointer<Utf8>)>>(
        "ffi_patch_add_module")
    .asFunction();

int Function(RawPatch) _ffiPatchGetNodeCount = core
    .lookup<NativeFunction<Int64 Function(RawPatch)>>(
        "ffi_patch_get_node_count")
    .asFunction();

RawNode Function(RawPatch, int) _ffiPatchGetNode = core
    .lookup<NativeFunction<RawNode Function(RawPatch, Int64)>>(
        "ffi_patch_get_node")
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

  bool addModule(String name) {
    var rawName = name.toNativeUtf8();
    bool success = _ffiPatchAddModule(this, rawName);
    calloc.free(rawName);
    return success;
  }

  int getNodeCount() {
    return _ffiPatchGetNodeCount(this);
  }

  RawNode getNode(int id) {
    return _ffiPatchGetNode(this, id);
  }
}

class Patch extends StatefulWidget {
  Patch(this.app, this.info) {
    _patch.load(info.path);
    refresh();
  }

  final App app;
  final PatchInfo info;
  final RawPatch _patch = RawPatch.create(); // TODO: Fix leak

  var connectors = <Connector>[];
  ValueNotifier<List<Module>> modules = ValueNotifier([]);

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
}
