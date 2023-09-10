///
//  Generated code. Do not modify.
//  source: protocol.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,constant_identifier_names,directives_ordering,library_prefixes,non_constant_identifier_names,prefer_final_fields,return_of_invalid_type,unnecessary_const,unnecessary_import,unnecessary_this,unused_import,unused_shown_name

import 'dart:async' as $async;

import 'dart:core' as $core;

import 'package:grpc/service_api.dart' as $grpc;
import 'protocol.pb.dart' as $0;
export 'protocol.pb.dart';

class CoreProtocolClient extends $grpc.Client {
  static final _$dispatch = $grpc.ClientMethod<$0.CoreMsg, $0.Status>(
      '/workstation.core.CoreProtocol/Dispatch',
      ($0.CoreMsg value) => value.writeToBuffer(),
      ($core.List<$core.int> value) => $0.Status.fromBuffer(value));
  static final _$getModule = $grpc.ClientMethod<$0.Int, $0.Status>(
      '/workstation.core.CoreProtocol/GetModule',
      ($0.Int value) => value.writeToBuffer(),
      ($core.List<$core.int> value) => $0.Status.fromBuffer(value));

  CoreProtocolClient($grpc.ClientChannel channel,
      {$grpc.CallOptions? options,
      $core.Iterable<$grpc.ClientInterceptor>? interceptors})
      : super(channel, options: options, interceptors: interceptors);

  $grpc.ResponseFuture<$0.Status> dispatch($0.CoreMsg request,
      {$grpc.CallOptions? options}) {
    return $createUnaryCall(_$dispatch, request, options: options);
  }

  $grpc.ResponseFuture<$0.Status> getModule($0.Int request,
      {$grpc.CallOptions? options}) {
    return $createUnaryCall(_$getModule, request, options: options);
  }
}

abstract class CoreProtocolServiceBase extends $grpc.Service {
  $core.String get $name => 'workstation.core.CoreProtocol';

  CoreProtocolServiceBase() {
    $addMethod($grpc.ServiceMethod<$0.CoreMsg, $0.Status>(
        'Dispatch',
        dispatch_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.CoreMsg.fromBuffer(value),
        ($0.Status value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.Int, $0.Status>(
        'GetModule',
        getModule_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.Int.fromBuffer(value),
        ($0.Status value) => value.writeToBuffer()));
  }

  $async.Future<$0.Status> dispatch_Pre(
      $grpc.ServiceCall call, $async.Future<$0.CoreMsg> request) async {
    return dispatch(call, await request);
  }

  $async.Future<$0.Status> getModule_Pre(
      $grpc.ServiceCall call, $async.Future<$0.Int> request) async {
    return getModule(call, await request);
  }

  $async.Future<$0.Status> dispatch($grpc.ServiceCall call, $0.CoreMsg request);
  $async.Future<$0.Status> getModule($grpc.ServiceCall call, $0.Int request);
}
