import 'dart:ffi';
import 'dart:io';

import 'package:ffi/ffi.dart';
// import 'package:grpc/grpc.dart';
import 'package:metasampler/settings.dart';
// import 'package:pa_protocol/pa_protocol.dart';


@Int64()
typedef NativeFunctionPointer = Void Function(Int32);

typedef DartFunctionPointer = void Function(int);

final class CoreApi extends Struct {
  external Pointer<NativeFunction<Pointer<Utf8> Function()>> getVersion;
}

class Core {
  static String version = "0.1.0";

  static DynamicLibrary library = DynamicLibrary.open(
    Settings2.coreLibraryDirectory(),
  );

  static CoreApi coreApi = Core.getApi();

  static CoreApi getApi() {
    CoreApi Function() getApi = library
        .lookup<NativeFunction<CoreApi Function()>>("get_api")
        .asFunction();

    if (getApi.hashCode == 0) {
      print("Fatal error: Core API not found");
      exit(0);
    }

    return getApi();
  }

  /*static Core setApi(CoreApi coreApi) {
    if (version != coreApi.getVersion()) {
      print("Fatal error: Core version mismatch");
      exit(0);
    }

    return core;
  }

  Core(this.coreApi);*/

  static String getVersion() {
    Pointer<Utf8> Function() rawGetVersion = coreApi.getVersion.asFunction();
    var rawVersion = rawGetVersion();
    var version = rawVersion.toDartString();
    calloc.free(rawVersion);

    return version;
  }

  // extends CoreProtocolServiceBase {
  // Core(this.raw) {}

  // Make sure this doesn't leak???
  // final RawCore raw;
  // final Plugins plugins;
  // ValueNotifier<List<Plugin>> plugins;

  /*static Core create() {
    return Core(_ffiCreateHost());
  }

  static Core from(int addr) {
    return Core(_ffiHackConvert(addr));
  }*/

  /*@override
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

  @override
  Future<Status> getModule(ServiceCall call, Int request) {
    // TODO: implement getModule
    throw UnimplementedError();
  }*/

  bool load(String path) {
    print("Skipping Core.load");
    // var rawPath = path.toNativeUtf8();
    // var status = _ffiCoreLoad(raw, rawPath);
    // calloc.free(rawPath);
    // return status;

    return true;
  }

  bool save(String path) {
    print("Skipping Core.save");
    // var rawPath = path.toNativeUtf8();
    // var status = _ffiCoreSave(raw, rawPath);
    // calloc.free(rawPath);
    // return status;

    return true;
  }

  /*void refresh() {
    _ffiCoreRefresh(raw);
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

  void setPatch(Patch? patch) {
    if (patch != null) {
      _ffiCoreSetPatch(raw, patch.rawPatch);
    } else {
      _ffiCoreSetPatchNull(raw, Pointer.fromAddress(0));
    }
  }*/
}

/* Global */

/*int Function(Pointer<Uint8>) _ffiDispatch = core
    .lookup<NativeFunction<Int32 Function(Pointer<Uint8>)>>("ffi_dispatch")
    .asFunction();

RawCore Function(int) _ffiHackConvert = core
    .lookup<NativeFunction<RawCore Function(Int64)>>("ffi_hack_convert")
    .asFunction();
RawCore Function() _ffiCreateHost = core
    .lookup<NativeFunction<RawCore Function()>>("ffi_create_host")
    .asFunction();

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

final class FFIBuffer extends Struct {
  external Pointer<Float> pointer;

  @Int64()
  external int length;
}

final class RawCore extends Struct {
  @Int64()
  external int pointer;
}

final class FFIAudioPlugin extends Struct {
  @Int64()
  external int pointer;
}

final class RawWidgetPointer extends Struct {
  @Int64()
  external int pointer;
}

final class RawWidget extends Struct {
  external RawWidgetPointer pointer;

  @Int64()
  external int metadata;

  RawWidgetTrait getTrait() {
    return _ffiWidgetGetTrait(this);
  }
}

final class RawWidgetTrait extends Struct {
  external RawWidgetPointer pointer;

  @Int64()
  external int metadata;
}

final class RawModule extends Struct {
  @Int64()
  external int pointer1;

  @Int64()
  external int pointer2;
}

final class RawModuleInfo extends Struct {
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
    /*List<String> path = [];
    int count = ffiModuleInfoGetPathElementsCount(this);
    for (int i = 0; i < count; i++) {
      var rawElement = ffiModuleInfoGetPathElement(this, i);
      var element = rawElement.toDartString();
      calloc.free(rawElement);
      path.add(element);
    }

    return path;*/
    print("Skipping RawModule.getModulePath");
    return [];
  }

  /// Returns the color of the module
  Color getModuleColor() {
    return Color(ffiModuleInfoGetColor(this));
  }
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
*/
