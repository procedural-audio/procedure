import 'dart:ffi';
import 'dart:io';

import 'package:ffi/ffi.dart';
import 'package:metasampler/settings.dart';

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
}
