import 'package:ffi/ffi.dart';
import 'package:flutter/material.dart';

import 'dart:ffi';
import 'dart:async';
import 'dart:io';
import 'dart:convert';

import 'config.dart';
import 'main.dart';

import 'widgets/widget.dart';

import 'views/variables.dart';
import 'views/presets.dart';
import 'views/info.dart';

import 'module.dart';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:metasampler/host.dart';
import 'package:statsfl/statsfl.dart';

var core = getCore();
var api = FFIApi();

DynamicLibrary getCore() {
  var executable = DynamicLibrary.executable();

  if (executable.providesSymbol("ffi_create_host")) {
    return executable;
  } else {
    DynamicLibrary library;

    if (Platform.isLinux) {
      library = DynamicLibrary.open(
          "/home/chase/github/metasampler/build/package/linux/lib/libtonevision_core.so");

      if (library.providesSymbol("ffi_create_host")) {
        print("Loaded core dynamically");
        return library;
      } else {
        print("Failed to initialise core");
        exit(1);
      }
    } else if (Platform.isMacOS) {
      print("Using dylib from incorrect folder");
      library = DynamicLibrary.open(
          "/Users/chasekanipe/Github/nodus/build/out/core/release/libtonevision_core.dylib");

      if (library.providesSymbol("ffi_create_host")) {
        print("Loaded core dynamically");
        return library;
      } else {
        print("Failed to initialise core");
        exit(1);
      }
    } else {
      exit(1);
    }
  }
}

bool Function(FFIHost, Pointer<Utf8>) _loadInstrument = core
    .lookup<NativeFunction<Bool Function(FFIHost, Pointer<Utf8>)>>(
        "ffi_host_load")
    .asFunction();

bool Function(FFIHost, Pointer<Utf8>) _saveInstrument = core
    .lookup<NativeFunction<Bool Function(FFIHost, Pointer<Utf8>)>>(
        "ffi_host_save")
    .asFunction();

class FFIApi {
  /* Global */

  FFIHost Function() ffiCreateHost = core
      .lookup<NativeFunction<FFIHost Function()>>("ffi_create_host")
      .asFunction();

  /* Host */

  FFIHost Function(int) ffiHackConvert = core
      .lookup<NativeFunction<FFIHost Function(Int64)>>("ffi_hack_convert")
      .asFunction();

  void Function(FFIHost) ffiHostRefresh = core
      .lookup<NativeFunction<Void Function(FFIHost)>>("ffi_host_refresh")
      .asFunction();
  bool Function(FFIHost, Pointer<Utf8>) ffiHostAddModule = core
      .lookup<NativeFunction<Bool Function(FFIHost, Pointer<Utf8>)>>(
          "ffi_host_add_module")
      .asFunction();
  bool Function(FFIHost, int) ffiHostRemoveNode = core
      .lookup<NativeFunction<Bool Function(FFIHost, Int32)>>(
          "ffi_host_remove_node")
      .asFunction();
  int Function(FFIHost) ffiHostGetNodeCount = core
      .lookup<NativeFunction<Int64 Function(FFIHost)>>(
          "ffi_host_get_node_count")
      .asFunction();

  bool Function(FFIHost, int, int, int, int) ffiHostAddConnector = core
      .lookup<
          NativeFunction<
              Bool Function(FFIHost, Int32, Int32, Int32,
                  Int32)>>("ffi_host_add_connector")
      .asFunction();
  bool Function(FFIHost, int, int) ffiHostRemoveConnector = core
      .lookup<NativeFunction<Bool Function(FFIHost, Int32, Int32)>>(
          "ffi_host_remove_connector")
      .asFunction();
  int Function(FFIHost) ffiHostGetConnectorCount = core
      .lookup<NativeFunction<Int64 Function(FFIHost)>>(
          "ffi_host_get_connector_count")
      .asFunction();

  int Function(FFIHost) ffiHostGetConnectorStartId = core
      .lookup<NativeFunction<Int32 Function(FFIHost)>>(
          "ffi_host_get_connector_start_id")
      .asFunction();
  int Function(FFIHost) ffiHostGetConnectorEndId = core
      .lookup<NativeFunction<Int32 Function(FFIHost)>>(
          "ffi_host_get_connector_end_id")
      .asFunction();
  int Function(FFIHost) ffiHostGetConnectorStartIndex = core
      .lookup<NativeFunction<Int32 Function(FFIHost)>>(
          "ffi_host_get_connector_start_index")
      .asFunction();
  int Function(FFIHost) ffiHostGetConnectorEndIndex = core
      .lookup<NativeFunction<Int32 Function(FFIHost)>>(
          "ffi_host_get_connector_end_index")
      .asFunction();

  FFINode Function(FFIHost, int) ffiHostGetNode = core
      .lookup<NativeFunction<FFINode Function(FFIHost, Int64)>>(
          "ffi_host_get_node")
      .asFunction();

  /* Node */

  int Function(FFINode) ffiNodeGetId = core
      .lookup<NativeFunction<Int32 Function(FFINode)>>("ffi_node_get_id")
      .asFunction();
  Pointer<Utf8> Function(FFINode) ffiNodeGetName = core
      .lookup<NativeFunction<Pointer<Utf8> Function(FFINode)>>(
          "ffi_node_get_name")
      .asFunction();
  int Function(FFINode) ffiNodeGetColor = core
      .lookup<NativeFunction<Int32 Function(FFINode)>>("ffi_node_get_color")
      .asFunction();

  int Function(FFINode) ffiNodeGetX = core
      .lookup<NativeFunction<Int32 Function(FFINode)>>("ffi_node_get_x")
      .asFunction();
  int Function(FFINode) ffiNodeGetY = core
      .lookup<NativeFunction<Int32 Function(FFINode)>>("ffi_node_get_y")
      .asFunction();
  void Function(FFINode, int) ffiNodeSetX = core
      .lookup<NativeFunction<Void Function(FFINode, Int32)>>("ffi_node_set_x")
      .asFunction();
  void Function(FFINode, int) ffiNodeSetY = core
      .lookup<NativeFunction<Void Function(FFINode, Int32)>>("ffi_node_set_y")
      .asFunction();

  double Function(FFINode) ffiNodeGetWidth = core
      .lookup<NativeFunction<Float Function(FFINode)>>("ffi_node_get_width")
      .asFunction();
  double Function(FFINode) ffiNodeGetHeight = core
      .lookup<NativeFunction<Float Function(FFINode)>>("ffi_node_get_height")
      .asFunction();
  int Function(FFINode) ffiNodeGetMinWidth = core
      .lookup<NativeFunction<Int32 Function(FFINode)>>("ffi_node_get_min_width")
      .asFunction();
  int Function(FFINode) ffiNodeGetMinHeight = core
      .lookup<NativeFunction<Int32 Function(FFINode)>>(
          "ffi_node_get_min_height")
      .asFunction();
  int Function(FFINode) ffiNodeGetMaxWidth = core
      .lookup<NativeFunction<Int32 Function(FFINode)>>("ffi_node_get_max_width")
      .asFunction();
  int Function(FFINode) ffiNodeGetMaxHeight = core
      .lookup<NativeFunction<Int32 Function(FFINode)>>(
          "ffi_node_get_max_height")
      .asFunction();
  bool Function(FFINode) ffiNodeGetResizable = core
      .lookup<NativeFunction<Bool Function(FFINode)>>("ffi_node_get_resizable")
      .asFunction();

  int Function(FFINode) ffiNodeGetInputPinsCount = core
      .lookup<NativeFunction<Int32 Function(FFINode)>>(
          "ffi_node_get_input_pins_count")
      .asFunction();
  int Function(FFINode, int) ffiNodeGetInputPinType = core
      .lookup<NativeFunction<Int32 Function(FFINode, Int32)>>(
          "ffi_node_get_input_pin_type")
      .asFunction();
  Pointer<Utf8> Function(FFINode, int) ffiNodeGetInputPinName = core
      .lookup<NativeFunction<Pointer<Utf8> Function(FFINode, Int32)>>(
          "ffi_node_get_input_pin_name")
      .asFunction();
  int Function(FFINode, int) ffiNodeGetInputPinY = core
      .lookup<NativeFunction<Int32 Function(FFINode, Int32)>>(
          "ffi_node_get_input_pin_y")
      .asFunction();

  int Function(FFINode) ffiNodeGetOutputPinsCount = core
      .lookup<NativeFunction<Int32 Function(FFINode)>>(
          "ffi_node_get_output_pins_count")
      .asFunction();
  int Function(FFINode, int) ffiNodeGetOutputPinType = core
      .lookup<NativeFunction<Int32 Function(FFINode, Int32)>>(
          "ffi_node_get_output_pin_type")
      .asFunction();
  Pointer<Utf8> Function(FFINode, int) ffiNodeGetOutputPinName = core
      .lookup<NativeFunction<Pointer<Utf8> Function(FFINode, Int32)>>(
          "ffi_node_get_output_pin_name")
      .asFunction();
  int Function(FFINode, int) ffiNodeGetOutputPinY = core
      .lookup<NativeFunction<Int32 Function(FFINode, Int32)>>(
          "ffi_node_get_output_pin_y")
      .asFunction();

  FFIWidget Function(FFINode) ffiNodeGetWidgetRoot = core
      .lookup<NativeFunction<FFIWidget Function(FFINode)>>(
          "ffi_node_get_widget_root")
      .asFunction();
  bool Function(FFINode) ffiNodeShouldRebuild = core
      .lookup<NativeFunction<Bool Function(FFINode)>>("ffi_node_should_rebuild")
      .asFunction();

  void Function(FFINode, double) ffiNodeSetNodeWidth = core
      .lookup<NativeFunction<Void Function(FFINode, Float)>>(
          "ffi_node_set_width")
      .asFunction();
  void Function(FFINode, double) ffiNodeSetNodeHeight = core
      .lookup<NativeFunction<Void Function(FFINode, Float)>>(
          "ffi_node_set_height")
      .asFunction();

  /* Main widget stuff */

  double Function(FFINode) ffiNodeGetWidgetMainX = core
      .lookup<NativeFunction<Float Function(FFINode)>>("ffi_node_get_ui_x")
      .asFunction();
  double Function(FFINode) ffiNodeGetWidgetMainY = core
      .lookup<NativeFunction<Float Function(FFINode)>>("ffi_node_get_ui_y")
      .asFunction();
  void Function(FFINode, double) ffiNodeSetWidgetMainX = core
      .lookup<NativeFunction<Void Function(FFINode, Float)>>(
          "ffi_node_set_ui_x")
      .asFunction();
  void Function(FFINode, double) ffiNodeSetWidgetMainY = core
      .lookup<NativeFunction<Void Function(FFINode, Float)>>(
          "ffi_node_set_ui_y")
      .asFunction();

  double Function(FFINode) ffiNodeGetWidgetMainWidth = core
      .lookup<NativeFunction<Float Function(FFINode)>>("ffi_node_get_ui_width")
      .asFunction();
  double Function(FFINode) ffiNodeGetWidgetMainHeight = core
      .lookup<NativeFunction<Float Function(FFINode)>>("ffi_node_get_ui_height")
      .asFunction();
  void Function(FFINode, double) ffiNodeSetWidgetMainWidth = core
      .lookup<NativeFunction<Void Function(FFINode, Float)>>(
          "ffi_node_set_ui_width")
      .asFunction();
  void Function(FFINode, double) ffiNodeSetWidgetMainHeight = core
      .lookup<NativeFunction<Void Function(FFINode, Float)>>(
          "ffi_node_set_ui_height")
      .asFunction();

  FFIWidget Function(FFINode) ffiNodeGetWidgetMainRoot = core
      .lookup<NativeFunction<FFIWidget Function(FFINode)>>(
          "ffi_node_get_ui_root")
      .asFunction();

  /* Widget */

  FFIWidgetTrait Function(FFIWidget) ffiWidgetGetTrait = core
      .lookup<NativeFunction<FFIWidgetTrait Function(FFIWidget)>>(
          "ffi_widget_get_trait")
      .asFunction();
  Pointer<Utf8> Function(FFIWidget) ffiWidgetGetName = core
      .lookup<NativeFunction<Pointer<Utf8> Function(FFIWidget)>>(
          "ffi_widget_get_name")
      .asFunction();
  int Function(FFIWidget) ffiWidgetGetChildCount = core
      .lookup<NativeFunction<Int64 Function(FFIWidget)>>(
          "ffi_widget_get_child_count")
      .asFunction();
  FFIWidget Function(FFIWidget, int) ffiWidgetGetChild = core
      .lookup<NativeFunction<FFIWidget Function(FFIWidget, Int64)>>(
          "ffi_widget_get_child")
      .asFunction();

  void Function(FFIWidget, int) ffiKnobSetValue = core
      .lookup<NativeFunction<Void Function(FFIWidget, Int32)>>(
          "ffi_knob_set_value")
      .asFunction();
}

class FFIBuffer extends Struct {
  external Pointer<Float> pointer;

  @Int64()
  external int length;
}

class FFIHost extends Struct {
  @Int64()
  external int pointer;
}

class FFINode extends Struct {
  @Int64()
  external int pointer;
}

class FFIWidgetPointer extends Struct {
  @Int64()
  external int pointer;
}

class FFIWidget extends Struct {
  external FFIWidgetPointer pointer;

  @Int64()
  external int metadata;

  FFIWidgetTrait getTrait() {
    return api.ffiWidgetGetTrait(this);
  }
}

class FFIWidgetTrait extends Struct {
  external FFIWidgetPointer pointer;

  @Int64()
  external int metadata;
}

class AudioPlugins {
  final _channel =
      const BasicMessageChannel("AudioPlugins", JSONMessageCodec());

  ValueNotifier<int?> processAddress = ValueNotifier(null);

  ValueNotifier<List<String>> plugins = ValueNotifier([
    "Diva",
    "ValhallaRoom",
    "ValhallaDelay",
    "Kontakt",
    "Keyscape",
    "Omnisphere"
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

class Host extends ChangeNotifier {
  final FFIHost host;
  late Graph graph;

  ValueNotifier<List<Var>> vars = ValueNotifier([]);

  Globals globals = Globals();

  late Timer timer1;
  late Timer timer2;

  late AudioPlugins audioPlugins;

  Host(this.host) {
    graph = Graph(host, this);
    audioPlugins = AudioPlugins();

    timer1 = Timer.periodic(const Duration(milliseconds: 30), (timer) {
      for (var module in graph.moduleWidgets) {
        for (var widget in module.module.widgets) {
          callTickRecursive(widget);
        }
      }
    });

    timer2 = Timer.periodic(const Duration(milliseconds: 300), (Timer t) {
      var rebuilt = false;
      for (var i = 0; i < graph.moduleWidgets.length; i++) {
        if (api.ffiNodeShouldRebuild(graph.moduleWidgets[i].module.module)) {
          print("Rebuilt a module");
          var moduleRaw = graph.moduleWidgets[i].module.module;
          var module = Module(this, moduleRaw);
          graph.moduleWidgets[i] = ModuleContainerWidget(module, this);
          //globals.host.graph.moduleWidgets[i].refresh();
          gGridState?.refresh();
          rebuilt = true;
        }
      }

      if (rebuilt) {
        api.ffiHostRefresh(host);
        gGridState?.refresh();
      }
    });

    refreshVariables();
  }

  @override
  void dispose() {
    timer1.cancel();
    timer2.cancel();

    super.dispose();
  }

  void refreshVariables() {
    vars.value.clear();

    int count = ffiHostGetVarsCount(host);

    for (int i = 0; i < count; i++) {
      var nameRaw = ffiHostGetVarName(host, i);
      var name = nameRaw.toDartString();
      calloc.free(nameRaw);

      var groupRaw = ffiHostGetVarGroup(host, i);

      var type = ffiHostGetVarValueType(host, i);

      dynamic value;

      if (type == 0) {
        value = ffiHostGetVarValueFloat(host, i);
      } else if (type == 1) {
        value = ffiHostGetVarValueBool(host, i);
      } else {
        print("ERROR: Unsupported variable type");
      }

      if (groupRaw == nullptr) {
        vars.value.add(Var(this,
            index: i, name: name, group: "", notifier: ValueNotifier(value)));
      } else {
        var groupName = groupRaw.toDartString();
        calloc.free(groupRaw);

        vars.value.add(Var(this,
            index: i,
            name: name,
            group: groupName,
            notifier: ValueNotifier(value)));
      }
    }

    vars.notifyListeners();
  }

  bool load(String path) {
    Pointer<Utf8> pathRaw = path.toNativeUtf8();
    bool ret = _loadInstrument(host, pathRaw);
    calloc.free(pathRaw);
    return ret;
  }

  bool save(String path) {
    Pointer<Utf8> pathRaw = path.toNativeUtf8();
    bool ret = _saveInstrument(host, pathRaw);
    calloc.free(pathRaw);
    return ret;
  }

  void loadInstrument(String path) {
    print("Loading instrument at " + path);

    Directory presetsDir = Directory(path + "/presets");

    globals.instrument = InstrumentInfo(File(path).name, path);

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
      if (load(preset.path)) {
        graph.refresh();
        gGridState?.refresh();
        globals.preset = PresetInfo(preset.name, preset);

        var uiFile = File(globals.instrument.path + "/ui.json");

        var s = uiFile.readAsStringSync();
        var data = jsonDecode(s);

        globals.rootWidget?.setJson(data);
        print("SHOULD REFRESH TREE HERE");
        // globals.instrumentView.tree.refresh();

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

  void saveInstrument() {
    /* Save metadata */

    String json = jsonEncode(globals.instrument);

    Directory directory = Directory(globals.instrument.path);
    if (!directory.existsSync()) {
      directory.createSync();
    }

    Directory directory2 = Directory(globals.instrument.path + "/info");
    if (!directory2.existsSync()) {
      directory2.createSync();
    }

    File file = File(globals.instrument.path + "/info/info.json");
    if (!file.existsSync()) {
      file.createSync();
    }

    file.writeAsString(json);

    /* Save graph */

    save(globals.preset.file.path);

    /* Save UI */

    File uiFile = File(globals.instrument.path + "/ui.json");

    var data = globals.rootWidget?.getJson();

    if (data != null) {
      var s = jsonEncode(data);
      uiFile.writeAsStringSync(s);
      print("Writing UI:\n" + s);
    } else {
      print("Couldn't save UI");
    }
  }

  void refreshInstruments() async {
    List<InstrumentInfo> instruments = [];

    final instDir = Directory(contentPath + "/instruments");
    var dirs = await instDir.list(recursive: false).toList();

    for (var dir in dirs) {
      final File file = File(dir.path + "/info/info.json");
      if (await file.exists()) {
        var json = jsonDecode(await file.readAsString());
        instruments.add(InstrumentInfo.fromJson(json, dir.path));
      } else {
        print("Couldn't find json for " + dir.path);
      }
    }

    globals.instruments.value = instruments;
  }

  void refreshPresets() async {
    print("Refreshing presets");
    List<PresetDirectory> newPresetDirs = [];

    final presetsDir = Directory(globals.instrument.path + "/presets");

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
  var moduleWidgets = <ModuleContainerWidget>[];

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

      var module = Module(host, moduleRaw);

      moduleWidgets.add(ModuleContainerWidget(module, host));
      modules.add(module);
    }

    return ret;
  }

  void removeModule(int id) {
    modules.retainWhere((element) => element.id != id);
    moduleWidgets.retainWhere((element) => element.module.id != id);

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
    moduleWidgets.clear();
    connectors.clear();

    int moduleCount = api.ffiHostGetNodeCount(raw);

    for (int i = 0; i < moduleCount; i++) {
      var moduleRaw = api.ffiHostGetNode(raw, i);
      var module = Module(host, moduleRaw);
      moduleWidgets.add(ModuleContainerWidget(module, host));
      modules.add(module);
    }

    int connectorCount = api.ffiHostGetConnectorCount(raw);

    for (int i = 0; i < connectorCount; i++) {
      var start_id = api.ffiHostGetConnectorStartId(raw);
      var end_id = api.ffiHostGetConnectorEndId(raw);
      var start_index = api.ffiHostGetConnectorStartIndex(raw);
      var end_index = api.ffiHostGetConnectorEndIndex(raw);

      var type = IO.audio;

      for (var module in modules) {
        if (module.id == start_id) {
          type = module.pins[start_index].type;
        }
      }

      connectors.add(Connector(start_id, start_index, end_id, end_index, type));
    }
  }
}
