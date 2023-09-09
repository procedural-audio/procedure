///
//  Generated code. Do not modify.
//  source: protocol.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,constant_identifier_names,directives_ordering,library_prefixes,non_constant_identifier_names,prefer_final_fields,return_of_invalid_type,unnecessary_const,unnecessary_import,unnecessary_this,unused_import,unused_shown_name

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

class Status extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'Status', package: const $pb.PackageName(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'workstation.core'), createEmptyInstance: create)
    ..aOB(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'status')
    ..hasRequiredFields = false
  ;

  Status._() : super();
  factory Status({
    $core.bool? status,
  }) {
    final _result = create();
    if (status != null) {
      _result.status = status;
    }
    return _result;
  }
  factory Status.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory Status.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  Status clone() => Status()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  Status copyWith(void Function(Status) updates) => super.copyWith((message) => updates(message as Status)) as Status; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static Status create() => Status._();
  Status createEmptyInstance() => create();
  static $pb.PbList<Status> createRepeated() => $pb.PbList<Status>();
  @$core.pragma('dart2js:noInline')
  static Status getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Status>(create);
  static Status? _defaultInstance;

  @$pb.TagNumber(1)
  $core.bool get status => $_getBF(0);
  @$pb.TagNumber(1)
  set status($core.bool v) { $_setBool(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasStatus() => $_has(0);
  @$pb.TagNumber(1)
  void clearStatus() => clearField(1);
}

enum CoreMsg_Kind {
  patch, 
  module, 
  widget, 
  notSet
}

class CoreMsg extends $pb.GeneratedMessage {
  static const $core.Map<$core.int, CoreMsg_Kind> _CoreMsg_KindByTag = {
    1 : CoreMsg_Kind.patch,
    2 : CoreMsg_Kind.module,
    3 : CoreMsg_Kind.widget,
    0 : CoreMsg_Kind.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'CoreMsg', package: const $pb.PackageName(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'workstation.core'), createEmptyInstance: create)
    ..oo(0, [1, 2, 3])
    ..aOM<PatchMsg>(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'patch', subBuilder: PatchMsg.create)
    ..aOM<ModuleMsg>(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'module', subBuilder: ModuleMsg.create)
    ..aOM<WidgetMsg>(3, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'widget', subBuilder: WidgetMsg.create)
    ..hasRequiredFields = false
  ;

  CoreMsg._() : super();
  factory CoreMsg({
    PatchMsg? patch,
    ModuleMsg? module,
    WidgetMsg? widget,
  }) {
    final _result = create();
    if (patch != null) {
      _result.patch = patch;
    }
    if (module != null) {
      _result.module = module;
    }
    if (widget != null) {
      _result.widget = widget;
    }
    return _result;
  }
  factory CoreMsg.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory CoreMsg.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  CoreMsg clone() => CoreMsg()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  CoreMsg copyWith(void Function(CoreMsg) updates) => super.copyWith((message) => updates(message as CoreMsg)) as CoreMsg; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static CoreMsg create() => CoreMsg._();
  CoreMsg createEmptyInstance() => create();
  static $pb.PbList<CoreMsg> createRepeated() => $pb.PbList<CoreMsg>();
  @$core.pragma('dart2js:noInline')
  static CoreMsg getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<CoreMsg>(create);
  static CoreMsg? _defaultInstance;

  CoreMsg_Kind whichKind() => _CoreMsg_KindByTag[$_whichOneof(0)]!;
  void clearKind() => clearField($_whichOneof(0));

  @$pb.TagNumber(1)
  PatchMsg get patch => $_getN(0);
  @$pb.TagNumber(1)
  set patch(PatchMsg v) { setField(1, v); }
  @$pb.TagNumber(1)
  $core.bool hasPatch() => $_has(0);
  @$pb.TagNumber(1)
  void clearPatch() => clearField(1);
  @$pb.TagNumber(1)
  PatchMsg ensurePatch() => $_ensure(0);

  @$pb.TagNumber(2)
  ModuleMsg get module => $_getN(1);
  @$pb.TagNumber(2)
  set module(ModuleMsg v) { setField(2, v); }
  @$pb.TagNumber(2)
  $core.bool hasModule() => $_has(1);
  @$pb.TagNumber(2)
  void clearModule() => clearField(2);
  @$pb.TagNumber(2)
  ModuleMsg ensureModule() => $_ensure(1);

  @$pb.TagNumber(3)
  WidgetMsg get widget => $_getN(2);
  @$pb.TagNumber(3)
  set widget(WidgetMsg v) { setField(3, v); }
  @$pb.TagNumber(3)
  $core.bool hasWidget() => $_has(2);
  @$pb.TagNumber(3)
  void clearWidget() => clearField(3);
  @$pb.TagNumber(3)
  WidgetMsg ensureWidget() => $_ensure(2);
}

enum PatchMsg_Cmd {
  add, 
  remove, 
  notSet
}

class PatchMsg extends $pb.GeneratedMessage {
  static const $core.Map<$core.int, PatchMsg_Cmd> _PatchMsg_CmdByTag = {
    1 : PatchMsg_Cmd.add,
    2 : PatchMsg_Cmd.remove,
    0 : PatchMsg_Cmd.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'PatchMsg', package: const $pb.PackageName(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'workstation.core'), createEmptyInstance: create)
    ..oo(0, [1, 2])
    ..aOM<AddModule>(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'add', subBuilder: AddModule.create)
    ..aOM<RemoveModule>(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'remove', subBuilder: RemoveModule.create)
    ..hasRequiredFields = false
  ;

  PatchMsg._() : super();
  factory PatchMsg({
    AddModule? add,
    RemoveModule? remove,
  }) {
    final _result = create();
    if (add != null) {
      _result.add = add;
    }
    if (remove != null) {
      _result.remove = remove;
    }
    return _result;
  }
  factory PatchMsg.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory PatchMsg.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  PatchMsg clone() => PatchMsg()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  PatchMsg copyWith(void Function(PatchMsg) updates) => super.copyWith((message) => updates(message as PatchMsg)) as PatchMsg; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static PatchMsg create() => PatchMsg._();
  PatchMsg createEmptyInstance() => create();
  static $pb.PbList<PatchMsg> createRepeated() => $pb.PbList<PatchMsg>();
  @$core.pragma('dart2js:noInline')
  static PatchMsg getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<PatchMsg>(create);
  static PatchMsg? _defaultInstance;

  PatchMsg_Cmd whichCmd() => _PatchMsg_CmdByTag[$_whichOneof(0)]!;
  void clearCmd() => clearField($_whichOneof(0));

  @$pb.TagNumber(1)
  AddModule get add => $_getN(0);
  @$pb.TagNumber(1)
  set add(AddModule v) { setField(1, v); }
  @$pb.TagNumber(1)
  $core.bool hasAdd() => $_has(0);
  @$pb.TagNumber(1)
  void clearAdd() => clearField(1);
  @$pb.TagNumber(1)
  AddModule ensureAdd() => $_ensure(0);

  @$pb.TagNumber(2)
  RemoveModule get remove => $_getN(1);
  @$pb.TagNumber(2)
  set remove(RemoveModule v) { setField(2, v); }
  @$pb.TagNumber(2)
  $core.bool hasRemove() => $_has(1);
  @$pb.TagNumber(2)
  void clearRemove() => clearField(2);
  @$pb.TagNumber(2)
  RemoveModule ensureRemove() => $_ensure(1);
}

class AddModule extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'AddModule', package: const $pb.PackageName(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'workstation.core'), createEmptyInstance: create)
    ..aOS(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'name')
    ..a<$core.int>(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'x', $pb.PbFieldType.O3)
    ..a<$core.int>(3, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'y', $pb.PbFieldType.O3)
    ..hasRequiredFields = false
  ;

  AddModule._() : super();
  factory AddModule({
    $core.String? name,
    $core.int? x,
    $core.int? y,
  }) {
    final _result = create();
    if (name != null) {
      _result.name = name;
    }
    if (x != null) {
      _result.x = x;
    }
    if (y != null) {
      _result.y = y;
    }
    return _result;
  }
  factory AddModule.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory AddModule.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  AddModule clone() => AddModule()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  AddModule copyWith(void Function(AddModule) updates) => super.copyWith((message) => updates(message as AddModule)) as AddModule; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static AddModule create() => AddModule._();
  AddModule createEmptyInstance() => create();
  static $pb.PbList<AddModule> createRepeated() => $pb.PbList<AddModule>();
  @$core.pragma('dart2js:noInline')
  static AddModule getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<AddModule>(create);
  static AddModule? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get name => $_getSZ(0);
  @$pb.TagNumber(1)
  set name($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasName() => $_has(0);
  @$pb.TagNumber(1)
  void clearName() => clearField(1);

  @$pb.TagNumber(2)
  $core.int get x => $_getIZ(1);
  @$pb.TagNumber(2)
  set x($core.int v) { $_setSignedInt32(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasX() => $_has(1);
  @$pb.TagNumber(2)
  void clearX() => clearField(2);

  @$pb.TagNumber(3)
  $core.int get y => $_getIZ(2);
  @$pb.TagNumber(3)
  set y($core.int v) { $_setSignedInt32(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasY() => $_has(2);
  @$pb.TagNumber(3)
  void clearY() => clearField(3);
}

class RemoveModule extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'RemoveModule', package: const $pb.PackageName(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'workstation.core'), createEmptyInstance: create)
    ..a<$core.int>(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'id', $pb.PbFieldType.O3)
    ..hasRequiredFields = false
  ;

  RemoveModule._() : super();
  factory RemoveModule({
    $core.int? id,
  }) {
    final _result = create();
    if (id != null) {
      _result.id = id;
    }
    return _result;
  }
  factory RemoveModule.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory RemoveModule.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  RemoveModule clone() => RemoveModule()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  RemoveModule copyWith(void Function(RemoveModule) updates) => super.copyWith((message) => updates(message as RemoveModule)) as RemoveModule; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static RemoveModule create() => RemoveModule._();
  RemoveModule createEmptyInstance() => create();
  static $pb.PbList<RemoveModule> createRepeated() => $pb.PbList<RemoveModule>();
  @$core.pragma('dart2js:noInline')
  static RemoveModule getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<RemoveModule>(create);
  static RemoveModule? _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get id => $_getIZ(0);
  @$pb.TagNumber(1)
  set id($core.int v) { $_setSignedInt32(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => clearField(1);
}

class ModuleMsg extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'ModuleMsg', package: const $pb.PackageName(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'workstation.core'), createEmptyInstance: create)
    ..aOS(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'data')
    ..hasRequiredFields = false
  ;

  ModuleMsg._() : super();
  factory ModuleMsg({
    $core.String? data,
  }) {
    final _result = create();
    if (data != null) {
      _result.data = data;
    }
    return _result;
  }
  factory ModuleMsg.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory ModuleMsg.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  ModuleMsg clone() => ModuleMsg()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  ModuleMsg copyWith(void Function(ModuleMsg) updates) => super.copyWith((message) => updates(message as ModuleMsg)) as ModuleMsg; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static ModuleMsg create() => ModuleMsg._();
  ModuleMsg createEmptyInstance() => create();
  static $pb.PbList<ModuleMsg> createRepeated() => $pb.PbList<ModuleMsg>();
  @$core.pragma('dart2js:noInline')
  static ModuleMsg getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ModuleMsg>(create);
  static ModuleMsg? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get data => $_getSZ(0);
  @$pb.TagNumber(1)
  set data($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasData() => $_has(0);
  @$pb.TagNumber(1)
  void clearData() => clearField(1);
}

class WidgetMsg extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'WidgetMsg', package: const $pb.PackageName(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'workstation.core'), createEmptyInstance: create)
    ..aOS(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'data')
    ..hasRequiredFields = false
  ;

  WidgetMsg._() : super();
  factory WidgetMsg({
    $core.String? data,
  }) {
    final _result = create();
    if (data != null) {
      _result.data = data;
    }
    return _result;
  }
  factory WidgetMsg.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory WidgetMsg.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  WidgetMsg clone() => WidgetMsg()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  WidgetMsg copyWith(void Function(WidgetMsg) updates) => super.copyWith((message) => updates(message as WidgetMsg)) as WidgetMsg; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static WidgetMsg create() => WidgetMsg._();
  WidgetMsg createEmptyInstance() => create();
  static $pb.PbList<WidgetMsg> createRepeated() => $pb.PbList<WidgetMsg>();
  @$core.pragma('dart2js:noInline')
  static WidgetMsg getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<WidgetMsg>(create);
  static WidgetMsg? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get data => $_getSZ(0);
  @$pb.TagNumber(1)
  set data($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasData() => $_has(0);
  @$pb.TagNumber(1)
  void clearData() => clearField(1);
}

class LoadGraph extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'LoadGraph', package: const $pb.PackageName(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'workstation.core'), createEmptyInstance: create)
    ..aOS(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'path')
    ..hasRequiredFields = false
  ;

  LoadGraph._() : super();
  factory LoadGraph({
    $core.String? path,
  }) {
    final _result = create();
    if (path != null) {
      _result.path = path;
    }
    return _result;
  }
  factory LoadGraph.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory LoadGraph.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  LoadGraph clone() => LoadGraph()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  LoadGraph copyWith(void Function(LoadGraph) updates) => super.copyWith((message) => updates(message as LoadGraph)) as LoadGraph; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static LoadGraph create() => LoadGraph._();
  LoadGraph createEmptyInstance() => create();
  static $pb.PbList<LoadGraph> createRepeated() => $pb.PbList<LoadGraph>();
  @$core.pragma('dart2js:noInline')
  static LoadGraph getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<LoadGraph>(create);
  static LoadGraph? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get path => $_getSZ(0);
  @$pb.TagNumber(1)
  set path($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasPath() => $_has(0);
  @$pb.TagNumber(1)
  void clearPath() => clearField(1);
}

