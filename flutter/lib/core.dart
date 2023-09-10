import 'dart:developer';
import 'dart:ffi';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:ffi/ffi.dart';
import 'package:grpc/src/server/call.dart';
import 'package:metasampler/settings.dart';
import 'package:pa_protocol/pa_protocol.dart';

import 'module.dart';
import 'patch.dart';

void test1() {
  var msg = CoreMsg(
    patch: null,
    module: null,
    widget: null,
  );

  msg.ensureModule();
}

/*class CoreProtocolThing extends CoreProtocolServiceBase {
  @override
  Future<Status> dispatch(ServiceCall call, CoreMsg request) {
    return Future.value(Status.create());
  }
}*/

class Temp extends ServiceCall {
  @override
  // TODO: implement clientCertificate
  X509Certificate? get clientCertificate => throw UnimplementedError();

  @override
  // TODO: implement clientMetadata
  Map<String, String>? get clientMetadata => throw UnimplementedError();

  @override
  // TODO: implement deadline
  DateTime? get deadline => throw UnimplementedError();

  @override
  // TODO: implement headers
  Map<String, String>? get headers => throw UnimplementedError();

  @override
  // TODO: implement isCanceled
  bool get isCanceled => throw UnimplementedError();

  @override
  // TODO: implement isTimedOut
  bool get isTimedOut => throw UnimplementedError();

  @override
  void sendHeaders() {
    // TODO: implement sendHeaders
  }

  @override
  void sendTrailers({int? status, String? message}) {
    // TODO: implement sendTrailers
  }

  @override
  // TODO: implement trailers
  Map<String, String>? get trailers => throw UnimplementedError();

  @override
  // TODO: implement remoteAddress
  InternetAddress? get remoteAddress => throw UnimplementedError();
}

class Core extends CoreProtocolServiceBase {
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

  void dispatchTest() {
    var msg = CoreMsg(
        patch: PatchMsg(
          add: AddModule(
            name: "module_name",
            x: 0,
            y: 0,
          ),
        ),
        module: null,
        widget: null);

    dispatch(Temp(), msg);
  }

  @override
  Future<Status> dispatch(ServiceCall call, CoreMsg request) {
    var buffer = request.writeToBuffer();
    final pointer = calloc<Uint8>(buffer.length);

    for (int i = 0; i < buffer.length; i++) {
      pointer[i] = buffer[i];
    }

    _ffiDispatch(pointer);

    calloc.free(pointer);

    return Future.value(Status.create());
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

  void setPatch(Patch? patch) {
    if (patch != null) {
      _ffiCoreSetPatch(raw, patch.rawPatch);
    } else {
      _ffiCoreSetPatchNull(raw, Pointer.fromAddress(0));
    }
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

var core = DynamicLibrary.open(Settings2.coreLibraryDirectory());

/* Global */
int Function(Pointer<Uint8>) _ffiDispatch = core
    .lookup<NativeFunction<Int32 Function(Pointer<Uint8>)>>("ffi_dispatch")
    .asFunction();

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
void Function(RawCore, Pointer<NativeType>) _ffiCoreSetPatchNull = core
    .lookup<NativeFunction<Void Function(RawCore, Pointer<NativeType>)>>(
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
