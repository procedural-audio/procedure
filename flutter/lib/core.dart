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
