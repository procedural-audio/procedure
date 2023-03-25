import 'package:ffi/ffi.dart';
import 'package:flutter/material.dart';

import 'dart:ffi';
import 'dart:io';
import 'host.dart';
import 'module.dart';

// class Plugins {}

class Core {
  Core(this.raw);

  // Make sure this doesn't leak???
  final RawCore raw;
  // final Plugins plugins;
  // ValueNotifier<List<Plugin>> plugins;

  static Core create() {
    return Core(_ffiCreateHost());
  }

  static Core from(int addr) {
    return Core(_ffiHackConvert(addr));
  }

  bool load(String path) {
    var rawPath = path.toNativeUtf8();
    var status = _ffiCoreLoad(raw, rawPath);
    calloc.free(rawPath);
    return status;
  }

  bool save(String path) {
    var rawPath = path.toNativeUtf8();
    var status = _ffiCoreSave(raw, rawPath);
    calloc.free(rawPath);
    return status;
  }

  void refresh() {
    _ffiCoreRefresh(raw);
  }

  bool addModule(String name) {
    var rawPath = name.toNativeUtf8();
    var status = _ffiCoreAddModule(raw, rawPath);
    calloc.free(rawPath);
    return status;
  }

  bool removeNode(int i) {
    return _ffiCoreRemoveNode(raw, i);
  }

  int getNodeCount() {
    return _ffiCoreGetNodeCount(raw);
  }

  bool addConnector(int a, int b, int c, int d) {
    return _ffiCoreAddConnector(raw, a, b, c, d);
  }

  bool removeConnector(int a, int b) {
    return _ffiCoreRemoveConnector(raw, a, b);
  }

  int getConnectorCount() {
    return _ffiCoreGetConnectorCount(raw);
  }

  int getConnectorStartId(int a) {
    return _ffiCoreGetConnectorStartId(raw, a);
  }

  int getConnectorEndId(int a) {
    return _ffiCoreGetConnectorEndId(raw, a);
  }

  int getConnectorStartIndex(int a) {
    return _ffiCoreGetConnectorStartIndex(raw, a);
  }

  int getConnectorEndIndex(int a) {
    return _ffiCoreGetConnectorEndIndex(raw, a);
  }

  RawNode getNode(int a) {
    return _ffiCoreGetNode(raw, a);
  }

  int getModuleSpecCount() {
    return _ffiCoreGetModuleSpecCount(raw);
  }

  String getModuleSpecId(int a) {
    var rawId = _ffiCoreGetModuleSpecId(raw, a);
    var id = rawId.toDartString();
    calloc.free(rawId);
    return id;
  }

  String getModuleSpecPath(int a) {
    var rawId = _ffiCoreGetModuleSpecPath(raw, a);
    var id = rawId.toDartString();
    calloc.free(rawId);
    return id;
  }

  Color getModuleSpecColor(int a) {
    return Color(_ffiCoreGetModuleSpecColor(raw, a));
  }
}

var core = loadCoreLibrary();

DynamicLibrary loadCoreLibrary() {
  var executable = DynamicLibrary.executable();

  if (executable.providesSymbol("ffi_create_host")) {
    return executable;
  } else {
    DynamicLibrary library;

    if (Platform.isLinux) {
      library = DynamicLibrary.open(
          "/home/chase/github/nodus/build/out/core/release/libtonevision_core.so");

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

/* Global */

RawCore Function(int) _ffiHackConvert = core
    .lookup<NativeFunction<RawCore Function(Int64)>>("ffi_hack_convert")
    .asFunction();

RawCore Function() _ffiCreateHost = core
    .lookup<NativeFunction<RawCore Function()>>("ffi_create_host")
    .asFunction();

/* Core */

bool Function(RawCore, Pointer<Utf8>) _ffiCoreLoad = core
    .lookup<NativeFunction<Bool Function(RawCore, Pointer<Utf8>)>>(
        "ffi_host_load")
    .asFunction();
bool Function(RawCore, Pointer<Utf8>) _ffiCoreSave = core
    .lookup<NativeFunction<Bool Function(RawCore, Pointer<Utf8>)>>(
        "ffi_host_save")
    .asFunction();
void Function(RawCore) _ffiCoreRefresh = core
    .lookup<NativeFunction<Void Function(RawCore)>>("ffi_host_refresh")
    .asFunction();
bool Function(RawCore, Pointer<Utf8>) _ffiCoreAddModule = core
    .lookup<NativeFunction<Bool Function(RawCore, Pointer<Utf8>)>>(
        "ffi_host_add_module")
    .asFunction();
bool Function(RawCore, int) _ffiCoreRemoveNode = core
    .lookup<NativeFunction<Bool Function(RawCore, Int32)>>(
        "ffi_host_remove_node")
    .asFunction();
int Function(RawCore) _ffiCoreGetNodeCount = core
    .lookup<NativeFunction<Int64 Function(RawCore)>>("ffi_host_get_node_count")
    .asFunction();

/*FFIAudioPlugin Function(RawCore, Pointer<Utf8>) _ffiCoreCreatePlugin = core
    .lookup<NativeFunction<FFIAudioPlugin Function(RawCore, Pointer<Utf8>)>>(
        "ffi_host_create_plugin")
    .asFunction();*/

bool Function(RawCore, int, int, int, int) _ffiCoreAddConnector = core
    .lookup<NativeFunction<Bool Function(RawCore, Int32, Int32, Int32, Int32)>>(
        "ffi_host_add_connector")
    .asFunction();
bool Function(RawCore, int, int) _ffiCoreRemoveConnector = core
    .lookup<NativeFunction<Bool Function(RawCore, Int32, Int32)>>(
        "ffi_host_remove_connector")
    .asFunction();
int Function(RawCore) _ffiCoreGetConnectorCount = core
    .lookup<NativeFunction<Int64 Function(RawCore)>>(
        "ffi_host_get_connector_count")
    .asFunction();

int Function(RawCore, int) _ffiCoreGetConnectorStartId = core
    .lookup<NativeFunction<Int32 Function(RawCore, Int64)>>(
        "ffi_host_get_connector_start_id")
    .asFunction();
int Function(RawCore, int) _ffiCoreGetConnectorEndId = core
    .lookup<NativeFunction<Int32 Function(RawCore, Int64)>>(
        "ffi_host_get_connector_end_id")
    .asFunction();
int Function(RawCore, int) _ffiCoreGetConnectorStartIndex = core
    .lookup<NativeFunction<Int32 Function(RawCore, Int64)>>(
        "ffi_host_get_connector_start_index")
    .asFunction();
int Function(RawCore, int) _ffiCoreGetConnectorEndIndex = core
    .lookup<NativeFunction<Int32 Function(RawCore, Int64)>>(
        "ffi_host_get_connector_end_index")
    .asFunction();

RawNode Function(RawCore, int) _ffiCoreGetNode = core
    .lookup<NativeFunction<RawNode Function(RawCore, Int64)>>(
        "ffi_host_get_node")
    .asFunction();

/* Modules */

int Function(RawCore) _ffiCoreGetModuleSpecCount = core
    .lookup<NativeFunction<Int64 Function(RawCore)>>(
        "ffi_host_get_module_spec_count")
    .asFunction();
Pointer<Utf8> Function(RawCore, int) _ffiCoreGetModuleSpecId = core
    .lookup<NativeFunction<Pointer<Utf8> Function(RawCore, Int64)>>(
        "ffi_host_get_module_spec_id")
    .asFunction();

Pointer<Utf8> Function(RawCore, int) _ffiCoreGetModuleSpecPath = core
    .lookup<NativeFunction<Pointer<Utf8> Function(RawCore, Int64)>>(
        "ffi_host_get_module_spec_path")
    .asFunction();
int Function(RawCore, int) _ffiCoreGetModuleSpecColor = core
    .lookup<NativeFunction<Int64 Function(RawCore, Int32)>>(
        "ffi_host_get_module_spec_color")
    .asFunction();

/* Widget */

FFIWidgetTrait Function(FFIWidget) _ffiWidgetGetTrait = core
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

void Function(FFIWidget, int) _ffiKnobSetValue = core
    .lookup<NativeFunction<Void Function(FFIWidget, Int32)>>(
        "ffi_knob_set_value")
    .asFunction();

class FFIBuffer extends Struct {
  external Pointer<Float> pointer;

  @Int64()
  external int length;
}

class RawCore extends Struct {
  @Int64()
  external int pointer;
}

class FFIAudioPlugin extends Struct {
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
    return _ffiWidgetGetTrait(this);
  }
}

class FFIWidgetTrait extends Struct {
  external FFIWidgetPointer pointer;

  @Int64()
  external int metadata;
}

class RawPlugin extends Struct {
  @Int64()
  external int pointer;

  static RawPlugin? from(DynamicLibrary library) {
    if (library.providesSymbol("export_plugin")) {
      RawPlugin Function() exportPlugin = library
          .lookup<NativeFunction<RawPlugin Function()>>("export_plugin")
          .asFunction();

      return exportPlugin();
    } else {
      print("Couldn't find export in plugin");
    }

    return null;
  }

  String getName() {
    var rawName = ffiPluginGetName(this);
    var name = rawName.toDartString();
    calloc.free(rawName);
    return name;
  }

  int getVersion() {
    return ffiPluginGetVersion(this);
  }

  int getModuleCount() {
    return ffiPluginGetModuleCount(this);
  }

  RawModuleInfo getModuleInfo(int index) {
    return ffiPluginGetModuleInfo(this, index);
  }
}

Pointer<Utf8> Function(RawPlugin) ffiPluginGetName = core
    .lookup<NativeFunction<Pointer<Utf8> Function(RawPlugin)>>(
        "ffi_plugin_get_name")
    .asFunction();
int Function(RawPlugin) ffiPluginGetVersion = core
    .lookup<NativeFunction<Int64 Function(RawPlugin)>>("ffi_plugin_get_version")
    .asFunction();
int Function(RawPlugin) ffiPluginGetModuleCount = core
    .lookup<NativeFunction<Int64 Function(RawPlugin)>>(
        "ffi_plugin_get_module_info_count")
    .asFunction();
RawModuleInfo Function(RawPlugin, int) ffiPluginGetModuleInfo = core
    .lookup<NativeFunction<RawModuleInfo Function(RawPlugin, Int64)>>(
        "ffi_plugin_get_module_info")
    .asFunction();

class RawModuleInfo extends Struct {
  @Int64()
  external int pointer;

  String getModuleId() {
    var rawId = ffiModuleInfoGetId(this);
    var id = rawId.toDartString();
    calloc.free(rawId);
    return id;
  }

  String getModulePath() {
    var rawPath = ffiModuleInfoGetPath(this);
    var path = rawPath.toDartString();
    calloc.free(rawPath);
    return path;
  }

  Color getModuleColor() {
    return Color(ffiModuleInfoGetColor(this));
  }
}

Pointer<Utf8> Function(RawModuleInfo) ffiModuleInfoGetId = core
    .lookup<NativeFunction<Pointer<Utf8> Function(RawModuleInfo)>>(
        "ffi_module_info_get_id")
    .asFunction();
Pointer<Utf8> Function(RawModuleInfo) ffiModuleInfoGetPath = core
    .lookup<NativeFunction<Pointer<Utf8> Function(RawModuleInfo)>>(
        "ffi_module_info_get_path")
    .asFunction();
int Function(RawModuleInfo) ffiModuleInfoGetColor = core
    .lookup<NativeFunction<Int64 Function(RawModuleInfo)>>(
        "ffi_module_info_get_color")
    .asFunction();
