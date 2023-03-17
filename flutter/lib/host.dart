import 'package:ffi/ffi.dart';
import 'package:flutter/material.dart';

import 'dart:ffi';
import 'dart:async';
import 'dart:io';
import 'dart:convert';

import 'main.dart';
import 'config.dart';
import 'module.dart';

import 'views/variables.dart';
import 'views/presets.dart';
import 'views/info.dart';

import '../config.dart';
import 'core.dart';

import 'package:flutter/services.dart';

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

class Library {
  Library(Directory directory) {
    projects = Projects(Directory(directory.path + "/projects"));
    assets = Assets(Directory(directory.path + "/assets"));
  }

  late Projects projects;
  late Assets assets;

  static Library platformDefault() {
    if (Platform.isMacOS) {
      return Library(Directory("/Users/chasekanipe/Github/library/"));
    }

    print("Library not supported on platform");
    exit(1);
  }
}

// HOW TO MAKE THIS ASYNC COMPATIBLE ???

class Projects {
  Projects(this.directory);

  final Directory directory;

  Project? load(String name) {
    // loadAsync(name);
    print("Loading project");
    return null;
  }
}

class ProjectInfo {
  ProjectInfo({required this.directory, required this.name});

  Directory directory;
  String name;
}

class Project {
  Project(this.info);

  ProjectInfo info;
  List<Patch> patches = [];
  List<UserInterface> uis = [];
}

class Assets {
  Assets(this.directory);

  final Directory directory;

  Image? loadImage(String name) {
    print("Loading image asset");
    return null;
  }
}

class UserInterface {
  UserInterface(this.path);

  String path;
  List<Patch> patches = [];
  List<Preset> presets = [];
}

class Patch {
  Patch(this.path);

  String path;
}

/* HOST */

class Host extends ChangeNotifier {
  final FFIHost host;

  Library library = Library.platformDefault();

  /* Old */

  late Graph graph;
  late Vars vars;
  late Timer ticker;
  late AudioPlugins audioPlugins;

  Globals globals = Globals();

  var patch = ValueNotifier(
    PatchInfo.loadSync(contentPath + "instruments/NewInstrument"),
  );

  var patches = ValueNotifier(<PatchInfo>[]);

  ValueNotifier<List<ModuleSpec>> moduleSpecs = ValueNotifier([]);

  Host(this.host) {
    graph = Graph(host, this);
    vars = Vars(this);
    audioPlugins = AudioPlugins();

    ticker = Timer.periodic(const Duration(milliseconds: 30), (timer) {
      for (var module in graph.modules) {
        for (var widget in module.widgets) {
          callTickRecursive(widget);
        }
      }
    });

    refreshInstruments();
    refreshModuleSpecs();

    /*timer2 = Timer.periodic(const Duration(milliseconds: 300), (Timer t) {
      var rebuilt = false;
      for (var i = 0; i < graph.moduleWidgets.length; i++) {
        if (api.ffiNodeShouldRebuild(graph.moduleWidgets[i].module.module)) {
          print("Rebuilt a module");
          // var moduleRaw = graph.moduleWidgets[i].module.module;
          var module = Module(this, moduleRaw);
          gGridState?.refresh();
          rebuilt = true;
        }
      }

      if (rebuilt) {
        api.ffiHostRefresh(host);
        gGridState?.refresh();
      }
    });*/
  }

  void tick(Timer timer) {}

  @override
  void dispose() {
    ticker.cancel();
    super.dispose();
  }

  void refreshModuleSpecs() {
    List<ModuleSpec> specs = [];
    var count = api.ffiHostGetModuleSpecCount(host);

    for (int i = 0; i < count; i++) {
      var rawId = api.ffiHostGetModuleSpecId(host, i);
      var rawPath = api.ffiHostGetModuleSpecPath(host, i);
      var color = Color(api.ffiHostGetModuleSpecColor(host, i));

      specs
          .add(ModuleSpec(rawId.toDartString(), rawPath.toDartString(), color));

      calloc.free(rawId);
      calloc.free(rawPath);
    }

    moduleSpecs.value = specs;
  }

  bool loadHost(String path) {
    Pointer<Utf8> pathRaw = path.toNativeUtf8();
    bool ret = _loadHost(host, pathRaw);
    calloc.free(pathRaw);
    return ret;
  }

  bool saveHost(String path) {
    Pointer<Utf8> pathRaw = path.toNativeUtf8();
    bool ret = _saveHost(host, pathRaw);
    calloc.free(pathRaw);
    return ret;
  }

  void loadInstrument(String path) {
    print("Loading instrument at " + path);

    Directory presetsDir = Directory(path + "/presets");

    loadedInstrument.value = PatchInfo(File(path).name, path);

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
    List<PatchInfo> instruments = [];

    final instDir = Directory(contentPath + "/instruments");
    var dirs = await instDir.list(recursive: false).toList();

    for (var dir in dirs) {
      final File file = File(dir.path + "/info/info.json");
      if (await file.exists()) {
        print("Parsing " + file.path);
        var json = jsonDecode(await file.readAsString());
        instruments.add(PatchInfo.fromJson(json, dir.path));
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
}

extension FileExtention on FileSystemEntity {
  String get name {
    return path.split("/").last;
  }
}

class Instrument {
  final preset = Preset();
}

class Preset {}

class Graph {
  var modules = <Module>[];
  var connectors = <Connector>[];

  final FFIHost raw;
  Host host;

  Graph(this.raw, this.host) {
    refresh();
  }

  bool addModule(String name, Offset addPosition) {
    var buffer = name.toNativeUtf8();
    var ret = api.ffiHostAddModule(raw, buffer);
    calloc.free(buffer);

    if (ret) {
      var moduleRaw = api.ffiHostGetNode(raw, api.ffiHostGetNodeCount(raw) - 1);

      var x = addPosition.dx.toInt() - api.ffiNodeGetWidth(moduleRaw) ~/ 2;
      var y = addPosition.dy.toInt() - api.ffiNodeGetHeight(moduleRaw) ~/ 2;

      api.ffiNodeSetX(moduleRaw, x);
      api.ffiNodeSetY(moduleRaw, y);

      modules.add(Module(host, moduleRaw));
    }

    return ret;
  }

  void removeModule(int id) {
    modules.retainWhere((element) => element.id != id);

    connectors.retainWhere((element) => element.start.moduleId != id);
    connectors.retainWhere((element) => element.end.moduleId != id);

    api.ffiHostRemoveNode(raw, id);
  }

  bool addConnection(Connector c) {
    if (api.ffiHostAddConnector(
        raw, c.start.moduleId, c.start.index, c.end.moduleId, c.end.index)) {
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
    api.ffiHostRemoveConnector(raw, moduleId, pinIndex);
  }

  void refresh() {
    modules.clear();
    connectors.clear();

    int moduleCount = api.ffiHostGetNodeCount(raw);

    for (int i = 0; i < moduleCount; i++) {
      var moduleRaw = api.ffiHostGetNode(raw, i);
      var module = Module(host, moduleRaw);
      modules.add(module);
    }

    int connectorCount = api.ffiHostGetConnectorCount(raw);

    for (int i = 0; i < connectorCount; i++) {
      var startId = api.ffiHostGetConnectorStartId(raw, i);
      var endId = api.ffiHostGetConnectorEndId(raw, i);
      var startIndex = api.ffiHostGetConnectorStartIndex(raw, i);
      var endIndex = api.ffiHostGetConnectorEndIndex(raw, i);

      var type = IO.audio;

      for (var module in modules) {
        if (module.id == startId) {
          type = module.pins[startIndex].type;
        }
      }

      connectors.add(Connector(startId, startIndex, endId, endIndex, type));
    }
  }
}
