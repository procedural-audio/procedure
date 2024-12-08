// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'endpoint.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$EndpointKind {
  Enum get field0 => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(StreamType field0) stream,
    required TResult Function(ValueType field0) value,
    required TResult Function(EventType field0) event,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(StreamType field0)? stream,
    TResult? Function(ValueType field0)? value,
    TResult? Function(EventType field0)? event,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(StreamType field0)? stream,
    TResult Function(ValueType field0)? value,
    TResult Function(EventType field0)? event,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(EndpointKind_Stream value) stream,
    required TResult Function(EndpointKind_Value value) value,
    required TResult Function(EndpointKind_Event value) event,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(EndpointKind_Stream value)? stream,
    TResult? Function(EndpointKind_Value value)? value,
    TResult? Function(EndpointKind_Event value)? event,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(EndpointKind_Stream value)? stream,
    TResult Function(EndpointKind_Value value)? value,
    TResult Function(EndpointKind_Event value)? event,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $EndpointKindCopyWith<$Res> {
  factory $EndpointKindCopyWith(
          EndpointKind value, $Res Function(EndpointKind) then) =
      _$EndpointKindCopyWithImpl<$Res, EndpointKind>;
}

/// @nodoc
class _$EndpointKindCopyWithImpl<$Res, $Val extends EndpointKind>
    implements $EndpointKindCopyWith<$Res> {
  _$EndpointKindCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of EndpointKind
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc
abstract class _$$EndpointKind_StreamImplCopyWith<$Res> {
  factory _$$EndpointKind_StreamImplCopyWith(_$EndpointKind_StreamImpl value,
          $Res Function(_$EndpointKind_StreamImpl) then) =
      __$$EndpointKind_StreamImplCopyWithImpl<$Res>;
  @useResult
  $Res call({StreamType field0});
}

/// @nodoc
class __$$EndpointKind_StreamImplCopyWithImpl<$Res>
    extends _$EndpointKindCopyWithImpl<$Res, _$EndpointKind_StreamImpl>
    implements _$$EndpointKind_StreamImplCopyWith<$Res> {
  __$$EndpointKind_StreamImplCopyWithImpl(_$EndpointKind_StreamImpl _value,
      $Res Function(_$EndpointKind_StreamImpl) _then)
      : super(_value, _then);

  /// Create a copy of EndpointKind
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? field0 = null,
  }) {
    return _then(_$EndpointKind_StreamImpl(
      null == field0
          ? _value.field0
          : field0 // ignore: cast_nullable_to_non_nullable
              as StreamType,
    ));
  }
}

/// @nodoc

class _$EndpointKind_StreamImpl extends EndpointKind_Stream {
  const _$EndpointKind_StreamImpl(this.field0) : super._();

  @override
  final StreamType field0;

  @override
  String toString() {
    return 'EndpointKind.stream(field0: $field0)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$EndpointKind_StreamImpl &&
            (identical(other.field0, field0) || other.field0 == field0));
  }

  @override
  int get hashCode => Object.hash(runtimeType, field0);

  /// Create a copy of EndpointKind
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$EndpointKind_StreamImplCopyWith<_$EndpointKind_StreamImpl> get copyWith =>
      __$$EndpointKind_StreamImplCopyWithImpl<_$EndpointKind_StreamImpl>(
          this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(StreamType field0) stream,
    required TResult Function(ValueType field0) value,
    required TResult Function(EventType field0) event,
  }) {
    return stream(field0);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(StreamType field0)? stream,
    TResult? Function(ValueType field0)? value,
    TResult? Function(EventType field0)? event,
  }) {
    return stream?.call(field0);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(StreamType field0)? stream,
    TResult Function(ValueType field0)? value,
    TResult Function(EventType field0)? event,
    required TResult orElse(),
  }) {
    if (stream != null) {
      return stream(field0);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(EndpointKind_Stream value) stream,
    required TResult Function(EndpointKind_Value value) value,
    required TResult Function(EndpointKind_Event value) event,
  }) {
    return stream(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(EndpointKind_Stream value)? stream,
    TResult? Function(EndpointKind_Value value)? value,
    TResult? Function(EndpointKind_Event value)? event,
  }) {
    return stream?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(EndpointKind_Stream value)? stream,
    TResult Function(EndpointKind_Value value)? value,
    TResult Function(EndpointKind_Event value)? event,
    required TResult orElse(),
  }) {
    if (stream != null) {
      return stream(this);
    }
    return orElse();
  }
}

abstract class EndpointKind_Stream extends EndpointKind {
  const factory EndpointKind_Stream(final StreamType field0) =
      _$EndpointKind_StreamImpl;
  const EndpointKind_Stream._() : super._();

  @override
  StreamType get field0;

  /// Create a copy of EndpointKind
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$EndpointKind_StreamImplCopyWith<_$EndpointKind_StreamImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$EndpointKind_ValueImplCopyWith<$Res> {
  factory _$$EndpointKind_ValueImplCopyWith(_$EndpointKind_ValueImpl value,
          $Res Function(_$EndpointKind_ValueImpl) then) =
      __$$EndpointKind_ValueImplCopyWithImpl<$Res>;
  @useResult
  $Res call({ValueType field0});
}

/// @nodoc
class __$$EndpointKind_ValueImplCopyWithImpl<$Res>
    extends _$EndpointKindCopyWithImpl<$Res, _$EndpointKind_ValueImpl>
    implements _$$EndpointKind_ValueImplCopyWith<$Res> {
  __$$EndpointKind_ValueImplCopyWithImpl(_$EndpointKind_ValueImpl _value,
      $Res Function(_$EndpointKind_ValueImpl) _then)
      : super(_value, _then);

  /// Create a copy of EndpointKind
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? field0 = null,
  }) {
    return _then(_$EndpointKind_ValueImpl(
      null == field0
          ? _value.field0
          : field0 // ignore: cast_nullable_to_non_nullable
              as ValueType,
    ));
  }
}

/// @nodoc

class _$EndpointKind_ValueImpl extends EndpointKind_Value {
  const _$EndpointKind_ValueImpl(this.field0) : super._();

  @override
  final ValueType field0;

  @override
  String toString() {
    return 'EndpointKind.value(field0: $field0)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$EndpointKind_ValueImpl &&
            (identical(other.field0, field0) || other.field0 == field0));
  }

  @override
  int get hashCode => Object.hash(runtimeType, field0);

  /// Create a copy of EndpointKind
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$EndpointKind_ValueImplCopyWith<_$EndpointKind_ValueImpl> get copyWith =>
      __$$EndpointKind_ValueImplCopyWithImpl<_$EndpointKind_ValueImpl>(
          this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(StreamType field0) stream,
    required TResult Function(ValueType field0) value,
    required TResult Function(EventType field0) event,
  }) {
    return value(field0);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(StreamType field0)? stream,
    TResult? Function(ValueType field0)? value,
    TResult? Function(EventType field0)? event,
  }) {
    return value?.call(field0);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(StreamType field0)? stream,
    TResult Function(ValueType field0)? value,
    TResult Function(EventType field0)? event,
    required TResult orElse(),
  }) {
    if (value != null) {
      return value(field0);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(EndpointKind_Stream value) stream,
    required TResult Function(EndpointKind_Value value) value,
    required TResult Function(EndpointKind_Event value) event,
  }) {
    return value(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(EndpointKind_Stream value)? stream,
    TResult? Function(EndpointKind_Value value)? value,
    TResult? Function(EndpointKind_Event value)? event,
  }) {
    return value?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(EndpointKind_Stream value)? stream,
    TResult Function(EndpointKind_Value value)? value,
    TResult Function(EndpointKind_Event value)? event,
    required TResult orElse(),
  }) {
    if (value != null) {
      return value(this);
    }
    return orElse();
  }
}

abstract class EndpointKind_Value extends EndpointKind {
  const factory EndpointKind_Value(final ValueType field0) =
      _$EndpointKind_ValueImpl;
  const EndpointKind_Value._() : super._();

  @override
  ValueType get field0;

  /// Create a copy of EndpointKind
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$EndpointKind_ValueImplCopyWith<_$EndpointKind_ValueImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$EndpointKind_EventImplCopyWith<$Res> {
  factory _$$EndpointKind_EventImplCopyWith(_$EndpointKind_EventImpl value,
          $Res Function(_$EndpointKind_EventImpl) then) =
      __$$EndpointKind_EventImplCopyWithImpl<$Res>;
  @useResult
  $Res call({EventType field0});
}

/// @nodoc
class __$$EndpointKind_EventImplCopyWithImpl<$Res>
    extends _$EndpointKindCopyWithImpl<$Res, _$EndpointKind_EventImpl>
    implements _$$EndpointKind_EventImplCopyWith<$Res> {
  __$$EndpointKind_EventImplCopyWithImpl(_$EndpointKind_EventImpl _value,
      $Res Function(_$EndpointKind_EventImpl) _then)
      : super(_value, _then);

  /// Create a copy of EndpointKind
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? field0 = null,
  }) {
    return _then(_$EndpointKind_EventImpl(
      null == field0
          ? _value.field0
          : field0 // ignore: cast_nullable_to_non_nullable
              as EventType,
    ));
  }
}

/// @nodoc

class _$EndpointKind_EventImpl extends EndpointKind_Event {
  const _$EndpointKind_EventImpl(this.field0) : super._();

  @override
  final EventType field0;

  @override
  String toString() {
    return 'EndpointKind.event(field0: $field0)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$EndpointKind_EventImpl &&
            (identical(other.field0, field0) || other.field0 == field0));
  }

  @override
  int get hashCode => Object.hash(runtimeType, field0);

  /// Create a copy of EndpointKind
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$EndpointKind_EventImplCopyWith<_$EndpointKind_EventImpl> get copyWith =>
      __$$EndpointKind_EventImplCopyWithImpl<_$EndpointKind_EventImpl>(
          this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(StreamType field0) stream,
    required TResult Function(ValueType field0) value,
    required TResult Function(EventType field0) event,
  }) {
    return event(field0);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(StreamType field0)? stream,
    TResult? Function(ValueType field0)? value,
    TResult? Function(EventType field0)? event,
  }) {
    return event?.call(field0);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(StreamType field0)? stream,
    TResult Function(ValueType field0)? value,
    TResult Function(EventType field0)? event,
    required TResult orElse(),
  }) {
    if (event != null) {
      return event(field0);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(EndpointKind_Stream value) stream,
    required TResult Function(EndpointKind_Value value) value,
    required TResult Function(EndpointKind_Event value) event,
  }) {
    return event(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(EndpointKind_Stream value)? stream,
    TResult? Function(EndpointKind_Value value)? value,
    TResult? Function(EndpointKind_Event value)? event,
  }) {
    return event?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(EndpointKind_Stream value)? stream,
    TResult Function(EndpointKind_Value value)? value,
    TResult Function(EndpointKind_Event value)? event,
    required TResult orElse(),
  }) {
    if (event != null) {
      return event(this);
    }
    return orElse();
  }
}

abstract class EndpointKind_Event extends EndpointKind {
  const factory EndpointKind_Event(final EventType field0) =
      _$EndpointKind_EventImpl;
  const EndpointKind_Event._() : super._();

  @override
  EventType get field0;

  /// Create a copy of EndpointKind
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$EndpointKind_EventImplCopyWith<_$EndpointKind_EventImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
