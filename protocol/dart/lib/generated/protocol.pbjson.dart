//
//  Generated code. Do not modify.
//  source: protocol.proto
//
// @dart = 2.12

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_final_fields
// ignore_for_file: unnecessary_import, unnecessary_this, unused_import

import 'dart:convert' as $convert;
import 'dart:core' as $core;
import 'dart:typed_data' as $typed_data;

@$core.Deprecated('Use statusDescriptor instead')
const Status$json = {
  '1': 'Status',
  '2': [
    {'1': 'status', '3': 1, '4': 1, '5': 8, '10': 'status'},
  ],
};

/// Descriptor for `Status`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List statusDescriptor = $convert.base64Decode(
    'CgZTdGF0dXMSFgoGc3RhdHVzGAEgASgIUgZzdGF0dXM=');

@$core.Deprecated('Use coreMsgDescriptor instead')
const CoreMsg$json = {
  '1': 'CoreMsg',
  '2': [
    {'1': 'patch', '3': 1, '4': 1, '5': 11, '6': '.workstation.core.PatchMsg', '9': 0, '10': 'patch'},
    {'1': 'module', '3': 2, '4': 1, '5': 11, '6': '.workstation.core.ModuleMsg', '9': 0, '10': 'module'},
    {'1': 'widget', '3': 3, '4': 1, '5': 11, '6': '.workstation.core.WidgetMsg', '9': 0, '10': 'widget'},
  ],
  '8': [
    {'1': 'kind'},
  ],
};

/// Descriptor for `CoreMsg`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List coreMsgDescriptor = $convert.base64Decode(
    'CgdDb3JlTXNnEjIKBXBhdGNoGAEgASgLMhoud29ya3N0YXRpb24uY29yZS5QYXRjaE1zZ0gAUg'
    'VwYXRjaBI1CgZtb2R1bGUYAiABKAsyGy53b3Jrc3RhdGlvbi5jb3JlLk1vZHVsZU1zZ0gAUgZt'
    'b2R1bGUSNQoGd2lkZ2V0GAMgASgLMhsud29ya3N0YXRpb24uY29yZS5XaWRnZXRNc2dIAFIGd2'
    'lkZ2V0QgYKBGtpbmQ=');

@$core.Deprecated('Use patchMsgDescriptor instead')
const PatchMsg$json = {
  '1': 'PatchMsg',
  '2': [
    {'1': 'add', '3': 1, '4': 1, '5': 11, '6': '.workstation.core.AddModule', '9': 0, '10': 'add'},
    {'1': 'remove', '3': 2, '4': 1, '5': 11, '6': '.workstation.core.RemoveModule', '9': 0, '10': 'remove'},
  ],
  '8': [
    {'1': 'cmd'},
  ],
};

/// Descriptor for `PatchMsg`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List patchMsgDescriptor = $convert.base64Decode(
    'CghQYXRjaE1zZxIvCgNhZGQYASABKAsyGy53b3Jrc3RhdGlvbi5jb3JlLkFkZE1vZHVsZUgAUg'
    'NhZGQSOAoGcmVtb3ZlGAIgASgLMh4ud29ya3N0YXRpb24uY29yZS5SZW1vdmVNb2R1bGVIAFIG'
    'cmVtb3ZlQgUKA2NtZA==');

@$core.Deprecated('Use addModuleDescriptor instead')
const AddModule$json = {
  '1': 'AddModule',
  '2': [
    {'1': 'name', '3': 1, '4': 1, '5': 9, '10': 'name'},
    {'1': 'x', '3': 2, '4': 1, '5': 5, '10': 'x'},
    {'1': 'y', '3': 3, '4': 1, '5': 5, '10': 'y'},
  ],
};

/// Descriptor for `AddModule`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List addModuleDescriptor = $convert.base64Decode(
    'CglBZGRNb2R1bGUSEgoEbmFtZRgBIAEoCVIEbmFtZRIMCgF4GAIgASgFUgF4EgwKAXkYAyABKA'
    'VSAXk=');

@$core.Deprecated('Use removeModuleDescriptor instead')
const RemoveModule$json = {
  '1': 'RemoveModule',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 5, '10': 'id'},
  ],
};

/// Descriptor for `RemoveModule`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List removeModuleDescriptor = $convert.base64Decode(
    'CgxSZW1vdmVNb2R1bGUSDgoCaWQYASABKAVSAmlk');

@$core.Deprecated('Use moduleMsgDescriptor instead')
const ModuleMsg$json = {
  '1': 'ModuleMsg',
  '2': [
    {'1': 'data', '3': 1, '4': 1, '5': 9, '10': 'data'},
  ],
};

/// Descriptor for `ModuleMsg`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List moduleMsgDescriptor = $convert.base64Decode(
    'CglNb2R1bGVNc2cSEgoEZGF0YRgBIAEoCVIEZGF0YQ==');

@$core.Deprecated('Use widgetMsgDescriptor instead')
const WidgetMsg$json = {
  '1': 'WidgetMsg',
  '2': [
    {'1': 'data', '3': 1, '4': 1, '5': 9, '10': 'data'},
  ],
};

/// Descriptor for `WidgetMsg`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List widgetMsgDescriptor = $convert.base64Decode(
    'CglXaWRnZXRNc2cSEgoEZGF0YRgBIAEoCVIEZGF0YQ==');

@$core.Deprecated('Use loadGraphDescriptor instead')
const LoadGraph$json = {
  '1': 'LoadGraph',
  '2': [
    {'1': 'path', '3': 1, '4': 1, '5': 9, '10': 'path'},
  ],
};

/// Descriptor for `LoadGraph`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List loadGraphDescriptor = $convert.base64Decode(
    'CglMb2FkR3JhcGgSEgoEcGF0aBgBIAEoCVIEcGF0aA==');

