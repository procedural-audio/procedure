import 'package:ffi/ffi.dart';

import 'dart:ffi';
import 'dart:io';

class Core {
  Core(this.raw);

  FFIHost raw;

  static Core create() {
    return Core(_ffiCreateHost());
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

FFIHost Function() _ffiCreateHost = core
    .lookup<NativeFunction<FFIHost Function()>>("ffi_create_host")
    .asFunction();

FFIHost Function(int) _ffiHackConvert = core
    .lookup<NativeFunction<FFIHost Function(Int64)>>("ffi_hack_convert")
    .asFunction();

/* Core */

bool Function(FFIHost, Pointer<Utf8>) _ffiCoreLoad = core
    .lookup<NativeFunction<Bool Function(FFIHost, Pointer<Utf8>)>>(
        "ffi_host_load")
    .asFunction();
bool Function(FFIHost, Pointer<Utf8>) _ffiCoreSave = core
    .lookup<NativeFunction<Bool Function(FFIHost, Pointer<Utf8>)>>(
        "ffi_host_save")
    .asFunction();
void Function(FFIHost) _ffiCoreRefresh = core
    .lookup<NativeFunction<Void Function(FFIHost)>>("ffi_host_refresh")
    .asFunction();
bool Function(FFIHost, Pointer<Utf8>) _ffiCoreAddModule = core
    .lookup<NativeFunction<Bool Function(FFIHost, Pointer<Utf8>)>>(
        "ffi_host_add_module")
    .asFunction();
bool Function(FFIHost, int) _ffiHostRemoveNode = core
    .lookup<NativeFunction<Bool Function(FFIHost, Int32)>>(
        "ffi_host_remove_node")
    .asFunction();
int Function(FFIHost) _ffiHostGetNodeCount = core
    .lookup<NativeFunction<Int64 Function(FFIHost)>>("ffi_host_get_node_count")
    .asFunction();
FFIAudioPlugin Function(FFIHost, Pointer<Utf8>) _ffiHostCreatePlugin = core
    .lookup<NativeFunction<FFIAudioPlugin Function(FFIHost, Pointer<Utf8>)>>(
        "ffi_host_create_plugin")
    .asFunction();

bool Function(FFIHost, int, int, int, int) _ffiHostAddConnector = core
    .lookup<NativeFunction<Bool Function(FFIHost, Int32, Int32, Int32, Int32)>>(
        "ffi_host_add_connector")
    .asFunction();
bool Function(FFIHost, int, int) _ffiHostRemoveConnector = core
    .lookup<NativeFunction<Bool Function(FFIHost, Int32, Int32)>>(
        "ffi_host_remove_connector")
    .asFunction();
int Function(FFIHost) _ffiHostGetConnectorCount = core
    .lookup<NativeFunction<Int64 Function(FFIHost)>>(
        "ffi_host_get_connector_count")
    .asFunction();

int Function(FFIHost, int) _ffiHostGetConnectorStartId = core
    .lookup<NativeFunction<Int32 Function(FFIHost, Int64)>>(
        "ffi_host_get_connector_start_id")
    .asFunction();
int Function(FFIHost, int) _ffiHostGetConnectorEndId = core
    .lookup<NativeFunction<Int32 Function(FFIHost, Int64)>>(
        "ffi_host_get_connector_end_id")
    .asFunction();
int Function(FFIHost, int) _ffiHostGetConnectorStartIndex = core
    .lookup<NativeFunction<Int32 Function(FFIHost, Int64)>>(
        "ffi_host_get_connector_start_index")
    .asFunction();
int Function(FFIHost, int) _ffiHostGetConnectorEndIndex = core
    .lookup<NativeFunction<Int32 Function(FFIHost, Int64)>>(
        "ffi_host_get_connector_end_index")
    .asFunction();

FFINode Function(FFIHost, int) _ffiHostGetNode = core
    .lookup<NativeFunction<FFINode Function(FFIHost, Int64)>>(
        "ffi_host_get_node")
    .asFunction();

/* Modules */

int Function(FFIHost) _ffiHostGetModuleSpecCount = core
    .lookup<NativeFunction<Int64 Function(FFIHost)>>(
        "ffi_host_get_module_spec_count")
    .asFunction();
Pointer<Utf8> Function(FFIHost, int) _ffiHostGetModuleSpecId = core
    .lookup<NativeFunction<Pointer<Utf8> Function(FFIHost, Int64)>>(
        "ffi_host_get_module_spec_id")
    .asFunction();
Pointer<Utf8> Function(FFIHost, int) _ffiHostGetModuleSpecPath = core
    .lookup<NativeFunction<Pointer<Utf8> Function(FFIHost, Int64)>>(
        "ffi_host_get_module_spec_path")
    .asFunction();
int Function(FFIHost, int) _ffiHostGetModuleSpecColor = core
    .lookup<NativeFunction<Int64 Function(FFIHost, Int32)>>(
        "ffi_host_get_module_spec_color")
    .asFunction();

/* Node */

int Function(FFINode) _ffiNodeGetId = core
    .lookup<NativeFunction<Int32 Function(FFINode)>>("ffi_node_get_id")
    .asFunction();
Pointer<Utf8> Function(FFINode) _ffiNodeGetName = core
    .lookup<NativeFunction<Pointer<Utf8> Function(FFINode)>>(
        "ffi_node_get_name")
    .asFunction();
int Function(FFINode) _ffiNodeGetColor = core
    .lookup<NativeFunction<Int32 Function(FFINode)>>("ffi_node_get_color")
    .asFunction();

int Function(FFINode) _ffiNodeGetX = core
    .lookup<NativeFunction<Int32 Function(FFINode)>>("ffi_node_get_x")
    .asFunction();
int Function(FFINode) _ffiNodeGetY = core
    .lookup<NativeFunction<Int32 Function(FFINode)>>("ffi_node_get_y")
    .asFunction();
void Function(FFINode, int) _ffiNodeSetX = core
    .lookup<NativeFunction<Void Function(FFINode, Int32)>>("ffi_node_set_x")
    .asFunction();
void Function(FFINode, int) _ffiNodeSetY = core
    .lookup<NativeFunction<Void Function(FFINode, Int32)>>("ffi_node_set_y")
    .asFunction();

double Function(FFINode) _ffiNodeGetWidth = core
    .lookup<NativeFunction<Float Function(FFINode)>>("ffi_node_get_width")
    .asFunction();
double Function(FFINode) _ffiNodeGetHeight = core
    .lookup<NativeFunction<Float Function(FFINode)>>("ffi_node_get_height")
    .asFunction();
int Function(FFINode) _ffiNodeGetMinWidth = core
    .lookup<NativeFunction<Int32 Function(FFINode)>>("ffi_node_get_min_width")
    .asFunction();
int Function(FFINode) _ffiNodeGetMinHeight = core
    .lookup<NativeFunction<Int32 Function(FFINode)>>("ffi_node_get_min_height")
    .asFunction();
int Function(FFINode) _ffiNodeGetMaxWidth = core
    .lookup<NativeFunction<Int32 Function(FFINode)>>("ffi_node_get_max_width")
    .asFunction();
int Function(FFINode) _ffiNodeGetMaxHeight = core
    .lookup<NativeFunction<Int32 Function(FFINode)>>("ffi_node_get_max_height")
    .asFunction();
bool Function(FFINode) _ffiNodeGetResizable = core
    .lookup<NativeFunction<Bool Function(FFINode)>>("ffi_node_get_resizable")
    .asFunction();

int Function(FFINode) _ffiNodeGetInputPinsCount = core
    .lookup<NativeFunction<Int32 Function(FFINode)>>(
        "ffi_node_get_input_pins_count")
    .asFunction();
int Function(FFINode, int) _ffiNodeGetInputPinType = core
    .lookup<NativeFunction<Int32 Function(FFINode, Int32)>>(
        "ffi_node_get_input_pin_type")
    .asFunction();
Pointer<Utf8> Function(FFINode, int) _ffiNodeGetInputPinName = core
    .lookup<NativeFunction<Pointer<Utf8> Function(FFINode, Int32)>>(
        "ffi_node_get_input_pin_name")
    .asFunction();
int Function(FFINode, int) _ffiNodeGetInputPinY = core
    .lookup<NativeFunction<Int32 Function(FFINode, Int32)>>(
        "ffi_node_get_input_pin_y")
    .asFunction();

int Function(FFINode) _ffiNodeGetOutputPinsCount = core
    .lookup<NativeFunction<Int32 Function(FFINode)>>(
        "ffi_node_get_output_pins_count")
    .asFunction();
int Function(FFINode, int) _ffiNodeGetOutputPinType = core
    .lookup<NativeFunction<Int32 Function(FFINode, Int32)>>(
        "ffi_node_get_output_pin_type")
    .asFunction();
Pointer<Utf8> Function(FFINode, int) _ffiNodeGetOutputPinName = core
    .lookup<NativeFunction<Pointer<Utf8> Function(FFINode, Int32)>>(
        "ffi_node_get_output_pin_name")
    .asFunction();
int Function(FFINode, int) _ffiNodeGetOutputPinY = core
    .lookup<NativeFunction<Int32 Function(FFINode, Int32)>>(
        "ffi_node_get_output_pin_y")
    .asFunction();

FFIWidget Function(FFINode) _ffiNodeGetWidgetRoot = core
    .lookup<NativeFunction<FFIWidget Function(FFINode)>>(
        "ffi_node_get_widget_root")
    .asFunction();
bool Function(FFINode) _ffiNodeShouldRebuild = core
    .lookup<NativeFunction<Bool Function(FFINode)>>("ffi_node_should_rebuild")
    .asFunction();

void Function(FFINode, double) _ffiNodeSetNodeWidth = core
    .lookup<NativeFunction<Void Function(FFINode, Float)>>("ffi_node_set_width")
    .asFunction();
void Function(FFINode, double) _ffiNodeSetNodeHeight = core
    .lookup<NativeFunction<Void Function(FFINode, Float)>>(
        "ffi_node_set_height")
    .asFunction();

/* Widget */

FFIWidgetTrait Function(FFIWidget) _ffiWidgetGetTrait = core
    .lookup<NativeFunction<FFIWidgetTrait Function(FFIWidget)>>(
        "ffi_widget_get_trait")
    .asFunction();
Pointer<Utf8> Function(FFIWidget) _ffiWidgetGetName = core
    .lookup<NativeFunction<Pointer<Utf8> Function(FFIWidget)>>(
        "ffi_widget_get_name")
    .asFunction();
int Function(FFIWidget) _ffiWidgetGetChildCount = core
    .lookup<NativeFunction<Int64 Function(FFIWidget)>>(
        "ffi_widget_get_child_count")
    .asFunction();
FFIWidget Function(FFIWidget, int) _ffiWidgetGetChild = core
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

class FFIHost extends Struct {
  @Int64()
  external int pointer;
}

class FFINode extends Struct {
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
