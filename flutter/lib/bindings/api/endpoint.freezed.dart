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
mixin _$EndpointType {
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
    required TResult Function(EndpointType_Stream value) stream,
    required TResult Function(EndpointType_Value value) value,
    required TResult Function(EndpointType_Event value) event,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(EndpointType_Stream value)? stream,
    TResult? Function(EndpointType_Value value)? value,
    TResult? Function(EndpointType_Event value)? event,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(EndpointType_Stream value)? stream,
    TResult Function(EndpointType_Value value)? value,
    TResult Function(EndpointType_Event value)? event,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $EndpointTypeCopyWith<$Res> {
  factory $EndpointTypeCopyWith(
          EndpointType value, $Res Function(EndpointType) then) =
      _$EndpointTypeCopyWithImpl<$Res, EndpointType>;
}

/// @nodoc
class _$EndpointTypeCopyWithImpl<$Res, $Val extends EndpointType>
    implements $EndpointTypeCopyWith<$Res> {
  _$EndpointTypeCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of EndpointType
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc
abstract class _$$EndpointType_StreamImplCopyWith<$Res> {
  factory _$$EndpointType_StreamImplCopyWith(_$EndpointType_StreamImpl value,
          $Res Function(_$EndpointType_StreamImpl) then) =
      __$$EndpointType_StreamImplCopyWithImpl<$Res>;
  @useResult
  $Res call({StreamType field0});
}

/// @nodoc
class __$$EndpointType_StreamImplCopyWithImpl<$Res>
    extends _$EndpointTypeCopyWithImpl<$Res, _$EndpointType_StreamImpl>
    implements _$$EndpointType_StreamImplCopyWith<$Res> {
  __$$EndpointType_StreamImplCopyWithImpl(_$EndpointType_StreamImpl _value,
      $Res Function(_$EndpointType_StreamImpl) _then)
      : super(_value, _then);

  /// Create a copy of EndpointType
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? field0 = null,
  }) {
    return _then(_$EndpointType_StreamImpl(
      null == field0
          ? _value.field0
          : field0 // ignore: cast_nullable_to_non_nullable
              as StreamType,
    ));
  }
}

/// @nodoc

class _$EndpointType_StreamImpl extends EndpointType_Stream {
  const _$EndpointType_StreamImpl(this.field0) : super._();

  @override
  final StreamType field0;

  @override
  String toString() {
    return 'EndpointType.stream(field0: $field0)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$EndpointType_StreamImpl &&
            (identical(other.field0, field0) || other.field0 == field0));
  }

  @override
  int get hashCode => Object.hash(runtimeType, field0);

  /// Create a copy of EndpointType
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$EndpointType_StreamImplCopyWith<_$EndpointType_StreamImpl> get copyWith =>
      __$$EndpointType_StreamImplCopyWithImpl<_$EndpointType_StreamImpl>(
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
    required TResult Function(EndpointType_Stream value) stream,
    required TResult Function(EndpointType_Value value) value,
    required TResult Function(EndpointType_Event value) event,
  }) {
    return stream(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(EndpointType_Stream value)? stream,
    TResult? Function(EndpointType_Value value)? value,
    TResult? Function(EndpointType_Event value)? event,
  }) {
    return stream?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(EndpointType_Stream value)? stream,
    TResult Function(EndpointType_Value value)? value,
    TResult Function(EndpointType_Event value)? event,
    required TResult orElse(),
  }) {
    if (stream != null) {
      return stream(this);
    }
    return orElse();
  }
}

abstract class EndpointType_Stream extends EndpointType {
  const factory EndpointType_Stream(final StreamType field0) =
      _$EndpointType_StreamImpl;
  const EndpointType_Stream._() : super._();

  @override
  StreamType get field0;

  /// Create a copy of EndpointType
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$EndpointType_StreamImplCopyWith<_$EndpointType_StreamImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$EndpointType_ValueImplCopyWith<$Res> {
  factory _$$EndpointType_ValueImplCopyWith(_$EndpointType_ValueImpl value,
          $Res Function(_$EndpointType_ValueImpl) then) =
      __$$EndpointType_ValueImplCopyWithImpl<$Res>;
  @useResult
  $Res call({ValueType field0});
}

/// @nodoc
class __$$EndpointType_ValueImplCopyWithImpl<$Res>
    extends _$EndpointTypeCopyWithImpl<$Res, _$EndpointType_ValueImpl>
    implements _$$EndpointType_ValueImplCopyWith<$Res> {
  __$$EndpointType_ValueImplCopyWithImpl(_$EndpointType_ValueImpl _value,
      $Res Function(_$EndpointType_ValueImpl) _then)
      : super(_value, _then);

  /// Create a copy of EndpointType
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? field0 = null,
  }) {
    return _then(_$EndpointType_ValueImpl(
      null == field0
          ? _value.field0
          : field0 // ignore: cast_nullable_to_non_nullable
              as ValueType,
    ));
  }
}

/// @nodoc

class _$EndpointType_ValueImpl extends EndpointType_Value {
  const _$EndpointType_ValueImpl(this.field0) : super._();

  @override
  final ValueType field0;

  @override
  String toString() {
    return 'EndpointType.value(field0: $field0)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$EndpointType_ValueImpl &&
            (identical(other.field0, field0) || other.field0 == field0));
  }

  @override
  int get hashCode => Object.hash(runtimeType, field0);

  /// Create a copy of EndpointType
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$EndpointType_ValueImplCopyWith<_$EndpointType_ValueImpl> get copyWith =>
      __$$EndpointType_ValueImplCopyWithImpl<_$EndpointType_ValueImpl>(
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
    required TResult Function(EndpointType_Stream value) stream,
    required TResult Function(EndpointType_Value value) value,
    required TResult Function(EndpointType_Event value) event,
  }) {
    return value(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(EndpointType_Stream value)? stream,
    TResult? Function(EndpointType_Value value)? value,
    TResult? Function(EndpointType_Event value)? event,
  }) {
    return value?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(EndpointType_Stream value)? stream,
    TResult Function(EndpointType_Value value)? value,
    TResult Function(EndpointType_Event value)? event,
    required TResult orElse(),
  }) {
    if (value != null) {
      return value(this);
    }
    return orElse();
  }
}

abstract class EndpointType_Value extends EndpointType {
  const factory EndpointType_Value(final ValueType field0) =
      _$EndpointType_ValueImpl;
  const EndpointType_Value._() : super._();

  @override
  ValueType get field0;

  /// Create a copy of EndpointType
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$EndpointType_ValueImplCopyWith<_$EndpointType_ValueImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$EndpointType_EventImplCopyWith<$Res> {
  factory _$$EndpointType_EventImplCopyWith(_$EndpointType_EventImpl value,
          $Res Function(_$EndpointType_EventImpl) then) =
      __$$EndpointType_EventImplCopyWithImpl<$Res>;
  @useResult
  $Res call({EventType field0});
}

/// @nodoc
class __$$EndpointType_EventImplCopyWithImpl<$Res>
    extends _$EndpointTypeCopyWithImpl<$Res, _$EndpointType_EventImpl>
    implements _$$EndpointType_EventImplCopyWith<$Res> {
  __$$EndpointType_EventImplCopyWithImpl(_$EndpointType_EventImpl _value,
      $Res Function(_$EndpointType_EventImpl) _then)
      : super(_value, _then);

  /// Create a copy of EndpointType
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? field0 = null,
  }) {
    return _then(_$EndpointType_EventImpl(
      null == field0
          ? _value.field0
          : field0 // ignore: cast_nullable_to_non_nullable
              as EventType,
    ));
  }
}

/// @nodoc

class _$EndpointType_EventImpl extends EndpointType_Event {
  const _$EndpointType_EventImpl(this.field0) : super._();

  @override
  final EventType field0;

  @override
  String toString() {
    return 'EndpointType.event(field0: $field0)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$EndpointType_EventImpl &&
            (identical(other.field0, field0) || other.field0 == field0));
  }

  @override
  int get hashCode => Object.hash(runtimeType, field0);

  /// Create a copy of EndpointType
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$EndpointType_EventImplCopyWith<_$EndpointType_EventImpl> get copyWith =>
      __$$EndpointType_EventImplCopyWithImpl<_$EndpointType_EventImpl>(
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
    required TResult Function(EndpointType_Stream value) stream,
    required TResult Function(EndpointType_Value value) value,
    required TResult Function(EndpointType_Event value) event,
  }) {
    return event(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(EndpointType_Stream value)? stream,
    TResult? Function(EndpointType_Value value)? value,
    TResult? Function(EndpointType_Event value)? event,
  }) {
    return event?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(EndpointType_Stream value)? stream,
    TResult Function(EndpointType_Value value)? value,
    TResult Function(EndpointType_Event value)? event,
    required TResult orElse(),
  }) {
    if (event != null) {
      return event(this);
    }
    return orElse();
  }
}

abstract class EndpointType_Event extends EndpointType {
  const factory EndpointType_Event(final EventType field0) =
      _$EndpointType_EventImpl;
  const EndpointType_Event._() : super._();

  @override
  EventType get field0;

  /// Create a copy of EndpointType
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$EndpointType_EventImplCopyWith<_$EndpointType_EventImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
