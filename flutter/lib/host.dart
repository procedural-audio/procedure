import 'package:flutter/material.dart';

import 'dart:async';
import 'dart:io';
import 'dart:convert';

import 'main.dart';
import 'config.dart';
import 'module.dart';

import 'views/variables.dart';
import 'views/presets.dart';
import 'views/info.dart';

import 'core.dart';

import 'package:flutter/services.dart';
import 'ui/layout.dart';
import 'views/settings.dart';
import '../main.dart';
import 'views/right_click.dart';

/*
class Globals {
  ValueNotifier<String> pinLabel = ValueNotifier("");
  Offset labelPosition = const Offset(0.0, 0.0);

  /* Instruments */

  ValueNotifier<List<ProjectInfo>> instruments = ValueNotifier([]);
  PresetInfo preset = PresetInfo(
      "Untitled Instrument",
      File(
          "/Users/chasekanipe/Github/content/instruments/Untitled Instrument"));

  List<ProjectInfo> instruments2 = [];
  ValueNotifier<Widget?> selectedWidgetEditor = ValueNotifier(null);

  /* Patching View */

  double zoom = 1.0;
  TempConnector? tempConnector;
  int selectedModule = -1;

  bool patchingScaleEnabled = true;
  Settings settings = Settings();
  RootWidget? rootWidget;
}*/

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

class ModuleSpec {
  ModuleSpec(this.id, this.path, this.color);

  String id;
  String path;
  Color color;
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

class Projects {
  Projects(this.directory) {
    scan();
  }

  final Directory directory;

  final ValueNotifier<List<ProjectInfo>> _projects = ValueNotifier([]);

  Future<Project?> load(String name) async {
    return null;
  }

  ValueNotifier<List<ProjectInfo>> list() {
    return _projects;
  }

  void scan() async {
    var list = await directory.list().toList();
    _projects.value = [];

    for (var item in list) {
      var projectInfo = await ProjectInfo.from(item.path);
      if (projectInfo != null) {
        _projects.value.add(projectInfo);
        _projects.notifyListeners();
      }
    }
  }

  bool contains(String name) {
    for (var project in _projects.value) {
      if (project.name == name) {
        return true;
      }
    }

    return false;
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

/* HOST */

/*class Host extends ChangeNotifier {
  Host({required this.core, required this.assets}) {
    // graph = Graph(core.raw, this);
    // vars = Vars(this);

    ticker = Timer.periodic(const Duration(milliseconds: 30), (timer) {
      for (var module in graph.modules) {
        for (var widget in module.widgets) {
          callTickRecursive(widget);
        }
      }
    });

    refreshInstruments();
    refreshModuleSpecs();
  }

  Core core;
  Assets assets;

  late Graph graph;
  late Vars vars;
  late Timer ticker;

  Globals globals = Globals();

  var loadedInstrument = ValueNotifier(
    ProjectInfo.loadSync(contentPath + "instruments/NewInstrument"),
  );

  var patches = ValueNotifier(<ProjectInfo>[]);
  ValueNotifier<List<ModuleSpec>> moduleSpecs = ValueNotifier([]);

  void tick(Timer timer) {}

  @override
  void dispose() {
    ticker.cancel();
    super.dispose();
  }

  void refreshModuleSpecs() {
    List<ModuleSpec> specs = [];
    var count = core.getModuleSpecCount();

    for (int i = 0; i < count; i++) {
      var id = core.getModuleSpecId(i);
      var path = core.getModuleSpecPath(i);
      var color = core.getModuleSpecColor(i);
      specs.add(ModuleSpec(id, path, color));
    }

    moduleSpecs.value = specs;
  }

  bool loadHost(String path) {
    return core.load(path);
    // Pointer<Utf8> pathRaw = path.toNativeUtf8();
    // bool ret = _loadHost(host, pathRaw);
    // calloc.free(pathRaw);
    // return ret;
  }

  bool saveHost(String path) {
    return core.save(path);
    // Pointer<Utf8> pathRaw = path.toNativeUtf8();
    // bool ret = _saveHost(host, pathRaw);
    // calloc.free(pathRaw);
    // return ret;
  }

  void loadInstrument(String path) {
    print("Loading instrument at " + path);

    Directory presetsDir = Directory(path + "/presets");

    loadedInstrument.value = ProjectInfo.loadSync(path);

    if (!presetsDir.existsSync()) {
      presetsDir.createSync();
    }

    PresetInfo preset = PresetInfo("Untitled Preset",
        File(presetsDir.path + "/Untitled Category/Untitled Preset"));

    for (var presetDirEntry in presetsDir.listSync().toList()) {
      var presetDir = Directory(presetDirEntry.path);

      if (presetDir.existsSync()) {
        for (var presetEntry in presetDir.listSync().toList()) {
          File presetFile = File(presetEntry.path);
          if (presetFile.existsSync()) {
            if (loadPreset(presetFile)) {
              refreshPresets();
              return;
            }
          }
        }
      }
    }

    preset.file.createSync(recursive: true);
    globals.preset = preset;

    refreshPresets();

    print("Loaded instrument at " + path);
  }

  bool loadPreset(File preset) {
    print("Loading preset at " + preset.path);

    if (preset.existsSync()) {
      if (loadHost(preset.path)) {
        graph.refresh();
        gGridState?.refresh();
        globals.preset = PresetInfo(preset.name, preset);

        var uiFile = File(loadedInstrument.value.path + "/ui.json");

        var s = uiFile.readAsStringSync();
        var data = jsonDecode(s);

        globals.rootWidget?.setJson(data);
        globals.rootWidget?.tree.refresh();

        print("Loaded UI:");
        print(data);

        return true;
      } else {
        print("Failed to load preset at " + preset.path);
      }
    } else {
      print("Couldn't find preset at " + preset.path);
    }

    return false;
  }

  void save() {
    String path = loadedInstrument.value.path;

    // Create instrument directory
    Directory directory = Directory(path);
    if (!directory.existsSync()) {
      directory.createSync();
    }

    // Create info directory
    Directory directory2 = Directory(path + "/info");
    if (!directory2.existsSync()) {
      directory2.createSync();
    }

    // Create info json
    File file = File(path + "/info/info.json");
    if (!file.existsSync()) {
      file.createSync();
    }

    // Write instrument info
    String json = jsonEncode(loadedInstrument.value);
    file.writeAsString(json);
    print("Saved instrument to " + path);
    print(json);

    // Save preset graph
    saveHost(globals.preset.file.path);

    // Save UI
    File uiFile = File(path + "/ui.json");
    var data = globals.rootWidget?.getJson();

    if (data != null) {
      var s = jsonEncode(data);
      uiFile.writeAsStringSync(s);
      print("Saved UI to " + path + "/ui.json");
      print(s);
    } else {
      print("Couldn't save UI");
    }
  }

  void refreshInstruments() async {
    List<ProjectInfo> instruments = [];

    final instDir = Directory(contentPath + "/instruments");
    var dirs = await instDir.list(recursive: false).toList();

    for (var dir in dirs) {
      final File file = File(dir.path + "/info/info.json");
      if (await file.exists()) {
        print("Parsing " + file.path);
        var json = jsonDecode(await file.readAsString());
        instruments.add(ProjectInfo.fromJson(dir.path, json));
      } else {
        print("Couldn't find json for " + dir.path);
      }
    }

    globals.instruments.value = instruments;
  }

  void refreshPresets() async {
    print("Refreshing presets");
    List<PresetDirectory> newPresetDirs = [];

    final presetsDir = Directory(loadedInstrument.value.path + "/presets");

    if (await presetsDir.exists()) {
      var dirs = await presetsDir.list(recursive: false).toList();

      for (var entry in dirs) {
        Directory dir = Directory(entry.path);

        if (await dir.exists()) {
          List<PresetInfo> presets = [];

          var presetFiles = await dir.list(recursive: false).toList();

          for (var presetEntry in presetFiles) {
            File file = File(presetEntry.path);

            if (await file.exists()) {
              presets.add(PresetInfo(file.name, file));
            }
          }

          newPresetDirs.add(PresetDirectory(
              name: dir.name, path: dir.path, presets: presets));
        }
      }
    }

    presetDirs = newPresetDirs;
    print("SHOUDL REFRESH HERE");
    // globals.window.presetsView.refresh();
  }
}*/

extension FileExtention on FileSystemEntity {
  String get name {
    return path.split("/").last;
  }
}

class Patch extends StatefulWidget {
  var modules = <Module>[];
  var connectors = <Connector>[];

  PatchInfo info;
  App app;

  Patch(this.app, this.info) {
    refresh();
  }

  bool addModule(String name, Offset addPosition) {
    var ret = app.core.addModule(name);

    if (ret) {
      var moduleRaw = app.core.getNode(app.core.getNodeCount() - 1);

      var x = addPosition.dx.toInt() - moduleRaw.getWidth() ~/ 2;
      var y = addPosition.dy.toInt() - moduleRaw.getHeight() ~/ 2;

      moduleRaw.setX(x);
      moduleRaw.setY(y);

      modules.add(Module(app, moduleRaw));
    }

    return ret;
  }

  void removeModule(int id) {
    modules.retainWhere((element) => element.id != id);
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
    modules.clear();
    connectors.clear();

    int moduleCount = app.core.getNodeCount();

    for (int i = 0; i < moduleCount; i++) {
      var moduleRaw = app.core.getNode(i);
      var module = Module(app, moduleRaw);
      modules.add(module);
    }

    int connectorCount = app.core.getConnectorCount();

    for (int i = 0; i < connectorCount; i++) {
      var startId = app.core.getConnectorStartId(i);
      var endId = app.core.getConnectorEndId(i);
      var startIndex = app.core.getConnectorStartIndex(i);
      var endIndex = app.core.getConnectorEndIndex(i);

      var type = IO.audio;

      for (var module in modules) {
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
