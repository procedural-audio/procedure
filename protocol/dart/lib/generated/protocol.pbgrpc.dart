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
  static final _$sayHello = $grpc.ClientMethod<$0.CoreMsg, $0.Status>(
      '/workstation.core.CoreProtocol/SayHello',
      ($0.CoreMsg value) => value.writeToBuffer(),
      ($core.List<$core.int> value) => $0.Status.fromBuffer(value));

  CoreProtocolClient($grpc.ClientChannel channel,
      {$grpc.CallOptions? options,
      $core.Iterable<$grpc.ClientInterceptor>? interceptors})
      : super(channel, options: options, interceptors: interceptors);

  $grpc.ResponseFuture<$0.Status> sayHello($0.CoreMsg request,
      {$grpc.CallOptions? options}) {
    return $createUnaryCall(_$sayHello, request, options: options);
  }
}

abstract class CoreProtocolServiceBase extends $grpc.Service {
  $core.String get $name => 'workstation.core.CoreProtocol';

  CoreProtocolServiceBase() {
    $addMethod($grpc.ServiceMethod<$0.CoreMsg, $0.Status>(
        'SayHello',
        sayHello_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.CoreMsg.fromBuffer(value),
        ($0.Status value) => value.writeToBuffer()));
  }

  $async.Future<$0.Status> sayHello_Pre(
      $grpc.ServiceCall call, $async.Future<$0.CoreMsg> request) async {
    return sayHello(call, await request);
  }

  $async.Future<$0.Status> sayHello($grpc.ServiceCall call, $0.CoreMsg request);
}
