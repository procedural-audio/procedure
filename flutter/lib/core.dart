import 'package:flutter/material.dart';
import 'package:ffi/ffi.dart';

import 'dart:ffi';
import 'dart:io';
import 'module.dart';
import 'patch.dart';

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

  /*bool addModule(String name) {
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
  }*/

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

  void setPatch(Patch patch) {
    _ffiCoreSetPatch(raw, patch.rawPatch);
  }

  /*int getModuleSpecCount() {
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
  }*/
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
void Function(RawCore, RawPatch) _ffiCoreSetPatch = core
    .lookup<NativeFunction<Void Function(RawCore, RawPatch)>>(
        "ffi_core_set_patch")
    .asFunction();
void Function(RawCore) _ffiCoreRefresh = core
    .lookup<NativeFunction<Void Function(RawCore)>>("ffi_host_refresh")
    .asFunction();
/*bool Function(RawCore, Pointer<Utf8>) _ffiCoreAddModule = core
    .lookup<NativeFunction<Bool Function(RawCore, Pointer<Utf8>)>>(
        "ffi_host_add_module")
    .asFunction();
bool Function(RawCore, int) _ffiCoreRemoveNode = core
    .lookup<NativeFunction<Bool Function(RawCore, Int32)>>(
        "ffi_host_remove_node")
    .asFunction();
int Function(RawCore) _ffiCoreGetNodeCount = core
    .lookup<NativeFunction<Int64 Function(RawCore)>>("ffi_host_get_node_count")
    .asFunction();*/

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

/*int Function(RawCore) _ffiCoreGetModuleSpecCount = core
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
    .asFunction();*/

/* Widget */

RawWidgetTrait Function(RawWidget) _ffiWidgetGetTrait = core
    .lookup<NativeFunction<RawWidgetTrait Function(RawWidget)>>(
        "ffi_widget_get_trait")
    .asFunction();
Pointer<Utf8> Function(RawWidget) ffiWidgetGetName = core
    .lookup<NativeFunction<Pointer<Utf8> Function(RawWidget)>>(
        "ffi_widget_get_name")
    .asFunction();
int Function(RawWidget) ffiWidgetGetChildCount = core
    .lookup<NativeFunction<Int64 Function(RawWidget)>>(
        "ffi_widget_get_child_count")
    .asFunction();
RawWidget Function(RawWidget, int) ffiWidgetGetChild = core
    .lookup<NativeFunction<RawWidget Function(RawWidget, Int64)>>(
        "ffi_widget_get_child")
    .asFunction();
void Function(RawWidget, int) _ffiKnobSetValue = core
    .lookup<NativeFunction<Void Function(RawWidget, Int32)>>(
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

class RawWidgetPointer extends Struct {
  @Int64()
  external int pointer;
}

class RawWidget extends Struct {
  external RawWidgetPointer pointer;

  @Int64()
  external int metadata;

  RawWidgetTrait getTrait() {
    return _ffiWidgetGetTrait(this);
  }
}

class RawWidgetTrait extends Struct {
  external RawWidgetPointer pointer;

  @Int64()
  external int metadata;
}

class RawModule extends Struct {
  @Int64()
  external int pointer1;

  @Int64()
  external int pointer2;
}

class RawModuleInfo extends Struct {
  @Int64()
  external int pointer;

  /// Returns the id of the module
  String getModuleId() {
    var rawId = ffiModuleInfoGetId(this);
    var id = rawId.toDartString();
    calloc.free(rawId);
    return id;
  }

  /// Returns the title of the module
  String getModuleName() {
    return getModulePath().last;
  }

  /// Returns the path of the module
  List<String> getModulePath() {
    List<String> path = [];
    int count = ffiModuleInfoGetPathElementsCount(this);
    for (int i = 0; i < count; i++) {
      var rawElement = ffiModuleInfoGetPathElement(this, i);
      var element = rawElement.toDartString();
      calloc.free(rawElement);
      path.add(element);
    }

    return path;
  }

  /// Returns the color of the module
  Color getModuleColor() {
    return Color(ffiModuleInfoGetColor(this));
  }

  /// Creates a new module
  /*RawModule create() {
    return ffiModuleInfoCreate(this);
  }*/
}

Pointer<Utf8> Function(RawModuleInfo) ffiModuleInfoGetId = core
    .lookup<NativeFunction<Pointer<Utf8> Function(RawModuleInfo)>>(
        "ffi_module_info_get_id")
    .asFunction();
Pointer<Utf8> Function(RawModuleInfo) ffiModuleInfoGetName = core
    .lookup<NativeFunction<Pointer<Utf8> Function(RawModuleInfo)>>(
        "ffi_module_info_get_name")
    .asFunction();
int Function(RawModuleInfo) ffiModuleInfoGetPathElementsCount = core
    .lookup<NativeFunction<Int64 Function(RawModuleInfo)>>(
        "ffi_module_info_get_path_elements_count")
    .asFunction();
Pointer<Utf8> Function(RawModuleInfo, int) ffiModuleInfoGetPathElement = core
    .lookup<NativeFunction<Pointer<Utf8> Function(RawModuleInfo, Int64)>>(
        "ffi_module_info_get_path_element")
    .asFunction();
int Function(RawModuleInfo) ffiModuleInfoGetColor = core
    .lookup<NativeFunction<Int64 Function(RawModuleInfo)>>(
        "ffi_module_info_get_color")
    .asFunction();
/*RawModule Function(RawModuleInfo) ffiModuleInfoCreate = core
    .lookup<NativeFunction<RawModule Function(RawModuleInfo)>>(
        "ffi_module_info_create")
    .asFunction();*/
