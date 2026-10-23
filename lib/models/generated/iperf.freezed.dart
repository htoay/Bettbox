// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of '../iperf.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$IperfFlow {

 double get bytes; double get bitrate; int get retransmits; double get jitter; int get lost; int get packets;@JsonKey(name: 'rtt-min') double get rttMin;@JsonKey(name: 'rtt-mean') double get rttMean;@JsonKey(name: 'rtt-max') double get rttMax;
/// Create a copy of IperfFlow
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$IperfFlowCopyWith<IperfFlow> get copyWith => _$IperfFlowCopyWithImpl<IperfFlow>(this as IperfFlow, _$identity);

  /// Serializes this IperfFlow to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is IperfFlow&&(identical(other.bytes, bytes) || other.bytes == bytes)&&(identical(other.bitrate, bitrate) || other.bitrate == bitrate)&&(identical(other.retransmits, retransmits) || other.retransmits == retransmits)&&(identical(other.jitter, jitter) || other.jitter == jitter)&&(identical(other.lost, lost) || other.lost == lost)&&(identical(other.packets, packets) || other.packets == packets)&&(identical(other.rttMin, rttMin) || other.rttMin == rttMin)&&(identical(other.rttMean, rttMean) || other.rttMean == rttMean)&&(identical(other.rttMax, rttMax) || other.rttMax == rttMax));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,bytes,bitrate,retransmits,jitter,lost,packets,rttMin,rttMean,rttMax);

@override
String toString() {
  return 'IperfFlow(bytes: $bytes, bitrate: $bitrate, retransmits: $retransmits, jitter: $jitter, lost: $lost, packets: $packets, rttMin: $rttMin, rttMean: $rttMean, rttMax: $rttMax)';
}


}

/// @nodoc
abstract mixin class $IperfFlowCopyWith<$Res>  {
  factory $IperfFlowCopyWith(IperfFlow value, $Res Function(IperfFlow) _then) = _$IperfFlowCopyWithImpl;
@useResult
$Res call({
 double bytes, double bitrate, int retransmits, double jitter, int lost, int packets,@JsonKey(name: 'rtt-min') double rttMin,@JsonKey(name: 'rtt-mean') double rttMean,@JsonKey(name: 'rtt-max') double rttMax
});




}
/// @nodoc
class _$IperfFlowCopyWithImpl<$Res>
    implements $IperfFlowCopyWith<$Res> {
  _$IperfFlowCopyWithImpl(this._self, this._then);

  final IperfFlow _self;
  final $Res Function(IperfFlow) _then;

/// Create a copy of IperfFlow
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? bytes = null,Object? bitrate = null,Object? retransmits = null,Object? jitter = null,Object? lost = null,Object? packets = null,Object? rttMin = null,Object? rttMean = null,Object? rttMax = null,}) {
  return _then(IperfFlow(
bytes: null == bytes ? _self.bytes : bytes // ignore: cast_nullable_to_non_nullable
as double,bitrate: null == bitrate ? _self.bitrate : bitrate // ignore: cast_nullable_to_non_nullable
as double,retransmits: null == retransmits ? _self.retransmits : retransmits // ignore: cast_nullable_to_non_nullable
as int,jitter: null == jitter ? _self.jitter : jitter // ignore: cast_nullable_to_non_nullable
as double,lost: null == lost ? _self.lost : lost // ignore: cast_nullable_to_non_nullable
as int,packets: null == packets ? _self.packets : packets // ignore: cast_nullable_to_non_nullable
as int,rttMin: null == rttMin ? _self.rttMin : rttMin // ignore: cast_nullable_to_non_nullable
as double,rttMean: null == rttMean ? _self.rttMean : rttMean // ignore: cast_nullable_to_non_nullable
as double,rttMax: null == rttMax ? _self.rttMax : rttMax // ignore: cast_nullable_to_non_nullable
as double,
  ));
}

}


/// Adds pattern-matching-related methods to [IperfFlow].
extension IperfFlowPatterns on IperfFlow {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _IperfFlow value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _IperfFlow() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _IperfFlow value)  $default,){
final _that = this;
switch (_that) {
case _IperfFlow():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _IperfFlow value)?  $default,){
final _that = this;
switch (_that) {
case _IperfFlow() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( double bytes,  double bitrate,  int retransmits,  double jitter,  int lost,  int packets, @JsonKey(name: 'rtt-min')  double rttMin, @JsonKey(name: 'rtt-mean')  double rttMean, @JsonKey(name: 'rtt-max')  double rttMax)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _IperfFlow() when $default != null:
return $default(_that.bytes,_that.bitrate,_that.retransmits,_that.jitter,_that.lost,_that.packets,_that.rttMin,_that.rttMean,_that.rttMax);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( double bytes,  double bitrate,  int retransmits,  double jitter,  int lost,  int packets, @JsonKey(name: 'rtt-min')  double rttMin, @JsonKey(name: 'rtt-mean')  double rttMean, @JsonKey(name: 'rtt-max')  double rttMax)  $default,) {final _that = this;
switch (_that) {
case _IperfFlow():
return $default(_that.bytes,_that.bitrate,_that.retransmits,_that.jitter,_that.lost,_that.packets,_that.rttMin,_that.rttMean,_that.rttMax);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( double bytes,  double bitrate,  int retransmits,  double jitter,  int lost,  int packets, @JsonKey(name: 'rtt-min')  double rttMin, @JsonKey(name: 'rtt-mean')  double rttMean, @JsonKey(name: 'rtt-max')  double rttMax)?  $default,) {final _that = this;
switch (_that) {
case _IperfFlow() when $default != null:
return $default(_that.bytes,_that.bitrate,_that.retransmits,_that.jitter,_that.lost,_that.packets,_that.rttMin,_that.rttMean,_that.rttMax);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _IperfFlow implements IperfFlow {
  const _IperfFlow({this.bytes = 0, this.bitrate = 0, this.retransmits = -1, this.jitter = 0, this.lost = 0, this.packets = 0, @JsonKey(name: 'rtt-min') this.rttMin = 0, @JsonKey(name: 'rtt-mean') this.rttMean = 0, @JsonKey(name: 'rtt-max') this.rttMax = 0});
  factory _IperfFlow.fromJson(Map<String, dynamic> json) => _$IperfFlowFromJson(json);

@override@JsonKey() final  double bytes;
@override@JsonKey() final  double bitrate;
@override@JsonKey() final  int retransmits;
@override@JsonKey() final  double jitter;
@override@JsonKey() final  int lost;
@override@JsonKey() final  int packets;
@override@JsonKey(name: 'rtt-min') final  double rttMin;
@override@JsonKey(name: 'rtt-mean') final  double rttMean;
@override@JsonKey(name: 'rtt-max') final  double rttMax;

/// Create a copy of IperfFlow
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$IperfFlowCopyWith<_IperfFlow> get copyWith => __$IperfFlowCopyWithImpl<_IperfFlow>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$IperfFlowToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _IperfFlow&&(identical(other.bytes, bytes) || other.bytes == bytes)&&(identical(other.bitrate, bitrate) || other.bitrate == bitrate)&&(identical(other.retransmits, retransmits) || other.retransmits == retransmits)&&(identical(other.jitter, jitter) || other.jitter == jitter)&&(identical(other.lost, lost) || other.lost == lost)&&(identical(other.packets, packets) || other.packets == packets)&&(identical(other.rttMin, rttMin) || other.rttMin == rttMin)&&(identical(other.rttMean, rttMean) || other.rttMean == rttMean)&&(identical(other.rttMax, rttMax) || other.rttMax == rttMax));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,bytes,bitrate,retransmits,jitter,lost,packets,rttMin,rttMean,rttMax);

@override
String toString() {
  return 'IperfFlow(bytes: $bytes, bitrate: $bitrate, retransmits: $retransmits, jitter: $jitter, lost: $lost, packets: $packets, rttMin: $rttMin, rttMean: $rttMean, rttMax: $rttMax)';
}


}

/// @nodoc
abstract mixin class _$IperfFlowCopyWith<$Res> implements $IperfFlowCopyWith<$Res> {
  factory _$IperfFlowCopyWith(_IperfFlow value, $Res Function(_IperfFlow) _then) = __$IperfFlowCopyWithImpl;
@override @useResult
$Res call({
 double bytes, double bitrate, int retransmits, double jitter, int lost, int packets,@JsonKey(name: 'rtt-min') double rttMin,@JsonKey(name: 'rtt-mean') double rttMean,@JsonKey(name: 'rtt-max') double rttMax
});




}
/// @nodoc
class __$IperfFlowCopyWithImpl<$Res>
    implements _$IperfFlowCopyWith<$Res> {
  __$IperfFlowCopyWithImpl(this._self, this._then);

  final _IperfFlow _self;
  final $Res Function(_IperfFlow) _then;

/// Create a copy of IperfFlow
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? bytes = null,Object? bitrate = null,Object? retransmits = null,Object? jitter = null,Object? lost = null,Object? packets = null,Object? rttMin = null,Object? rttMean = null,Object? rttMax = null,}) {
  return _then(_IperfFlow(
bytes: null == bytes ? _self.bytes : bytes // ignore: cast_nullable_to_non_nullable
as double,bitrate: null == bitrate ? _self.bitrate : bitrate // ignore: cast_nullable_to_non_nullable
as double,retransmits: null == retransmits ? _self.retransmits : retransmits // ignore: cast_nullable_to_non_nullable
as int,jitter: null == jitter ? _self.jitter : jitter // ignore: cast_nullable_to_non_nullable
as double,lost: null == lost ? _self.lost : lost // ignore: cast_nullable_to_non_nullable
as int,packets: null == packets ? _self.packets : packets // ignore: cast_nullable_to_non_nullable
as int,rttMin: null == rttMin ? _self.rttMin : rttMin // ignore: cast_nullable_to_non_nullable
as double,rttMean: null == rttMean ? _self.rttMean : rttMean // ignore: cast_nullable_to_non_nullable
as double,rttMax: null == rttMax ? _self.rttMax : rttMax // ignore: cast_nullable_to_non_nullable
as double,
  ));
}


}


/// @nodoc
mixin _$IperfState {

@JsonKey(unknownEnumValue: IperfRole.client) IperfRole get role; int get session;@JsonKey(unknownEnumValue: IperfPhase.connecting) IperfPhase get phase; String get peer;@JsonKey(unknownEnumValue: IperfProtocol.tcp) IperfProtocol get protocol;@JsonKey(unknownEnumValue: IperfDirection.upload) IperfDirection get direction; int get parallel; double get duration; double get elapsed; double get upload; double get download;@JsonKey(name: 'upload-result') IperfFlow? get uploadResult;@JsonKey(name: 'download-result') IperfFlow? get downloadResult; String get error;
/// Create a copy of IperfState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$IperfStateCopyWith<IperfState> get copyWith => _$IperfStateCopyWithImpl<IperfState>(this as IperfState, _$identity);

  /// Serializes this IperfState to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is IperfState&&(identical(other.role, role) || other.role == role)&&(identical(other.session, session) || other.session == session)&&(identical(other.phase, phase) || other.phase == phase)&&(identical(other.peer, peer) || other.peer == peer)&&(identical(other.protocol, protocol) || other.protocol == protocol)&&(identical(other.direction, direction) || other.direction == direction)&&(identical(other.parallel, parallel) || other.parallel == parallel)&&(identical(other.duration, duration) || other.duration == duration)&&(identical(other.elapsed, elapsed) || other.elapsed == elapsed)&&(identical(other.upload, upload) || other.upload == upload)&&(identical(other.download, download) || other.download == download)&&(identical(other.uploadResult, uploadResult) || other.uploadResult == uploadResult)&&(identical(other.downloadResult, downloadResult) || other.downloadResult == downloadResult)&&(identical(other.error, error) || other.error == error));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,role,session,phase,peer,protocol,direction,parallel,duration,elapsed,upload,download,uploadResult,downloadResult,error);

@override
String toString() {
  return 'IperfState(role: $role, session: $session, phase: $phase, peer: $peer, protocol: $protocol, direction: $direction, parallel: $parallel, duration: $duration, elapsed: $elapsed, upload: $upload, download: $download, uploadResult: $uploadResult, downloadResult: $downloadResult, error: $error)';
}


}

/// @nodoc
abstract mixin class $IperfStateCopyWith<$Res>  {
  factory $IperfStateCopyWith(IperfState value, $Res Function(IperfState) _then) = _$IperfStateCopyWithImpl;
@useResult
$Res call({
@JsonKey(unknownEnumValue: IperfRole.client) IperfRole role, int session,@JsonKey(unknownEnumValue: IperfPhase.connecting) IperfPhase phase, String peer,@JsonKey(unknownEnumValue: IperfProtocol.tcp) IperfProtocol protocol,@JsonKey(unknownEnumValue: IperfDirection.upload) IperfDirection direction, int parallel, double duration, double elapsed, double upload, double download,@JsonKey(name: 'upload-result') IperfFlow? uploadResult,@JsonKey(name: 'download-result') IperfFlow? downloadResult, String error
});


$IperfFlowCopyWith<$Res>? get uploadResult;$IperfFlowCopyWith<$Res>? get downloadResult;

}
/// @nodoc
class _$IperfStateCopyWithImpl<$Res>
    implements $IperfStateCopyWith<$Res> {
  _$IperfStateCopyWithImpl(this._self, this._then);

  final IperfState _self;
  final $Res Function(IperfState) _then;

/// Create a copy of IperfState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? role = null,Object? session = null,Object? phase = null,Object? peer = null,Object? protocol = null,Object? direction = null,Object? parallel = null,Object? duration = null,Object? elapsed = null,Object? upload = null,Object? download = null,Object? uploadResult = freezed,Object? downloadResult = freezed,Object? error = null,}) {
  return _then(IperfState(
role: null == role ? _self.role : role // ignore: cast_nullable_to_non_nullable
as IperfRole,session: null == session ? _self.session : session // ignore: cast_nullable_to_non_nullable
as int,phase: null == phase ? _self.phase : phase // ignore: cast_nullable_to_non_nullable
as IperfPhase,peer: null == peer ? _self.peer : peer // ignore: cast_nullable_to_non_nullable
as String,protocol: null == protocol ? _self.protocol : protocol // ignore: cast_nullable_to_non_nullable
as IperfProtocol,direction: null == direction ? _self.direction : direction // ignore: cast_nullable_to_non_nullable
as IperfDirection,parallel: null == parallel ? _self.parallel : parallel // ignore: cast_nullable_to_non_nullable
as int,duration: null == duration ? _self.duration : duration // ignore: cast_nullable_to_non_nullable
as double,elapsed: null == elapsed ? _self.elapsed : elapsed // ignore: cast_nullable_to_non_nullable
as double,upload: null == upload ? _self.upload : upload // ignore: cast_nullable_to_non_nullable
as double,download: null == download ? _self.download : download // ignore: cast_nullable_to_non_nullable
as double,uploadResult: freezed == uploadResult ? _self.uploadResult : uploadResult // ignore: cast_nullable_to_non_nullable
as IperfFlow?,downloadResult: freezed == downloadResult ? _self.downloadResult : downloadResult // ignore: cast_nullable_to_non_nullable
as IperfFlow?,error: null == error ? _self.error : error // ignore: cast_nullable_to_non_nullable
as String,
  ));
}
/// Create a copy of IperfState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$IperfFlowCopyWith<$Res>? get uploadResult {
    if (_self.uploadResult == null) {
    return null;
  }

  return $IperfFlowCopyWith<$Res>(_self.uploadResult!, (value) {
    return _then(_self.copyWith(uploadResult: value));
  });
}/// Create a copy of IperfState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$IperfFlowCopyWith<$Res>? get downloadResult {
    if (_self.downloadResult == null) {
    return null;
  }

  return $IperfFlowCopyWith<$Res>(_self.downloadResult!, (value) {
    return _then(_self.copyWith(downloadResult: value));
  });
}
}


/// Adds pattern-matching-related methods to [IperfState].
extension IperfStatePatterns on IperfState {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _IperfState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _IperfState() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _IperfState value)  $default,){
final _that = this;
switch (_that) {
case _IperfState():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _IperfState value)?  $default,){
final _that = this;
switch (_that) {
case _IperfState() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(unknownEnumValue: IperfRole.client)  IperfRole role,  int session, @JsonKey(unknownEnumValue: IperfPhase.connecting)  IperfPhase phase,  String peer, @JsonKey(unknownEnumValue: IperfProtocol.tcp)  IperfProtocol protocol, @JsonKey(unknownEnumValue: IperfDirection.upload)  IperfDirection direction,  int parallel,  double duration,  double elapsed,  double upload,  double download, @JsonKey(name: 'upload-result')  IperfFlow? uploadResult, @JsonKey(name: 'download-result')  IperfFlow? downloadResult,  String error)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _IperfState() when $default != null:
return $default(_that.role,_that.session,_that.phase,_that.peer,_that.protocol,_that.direction,_that.parallel,_that.duration,_that.elapsed,_that.upload,_that.download,_that.uploadResult,_that.downloadResult,_that.error);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(unknownEnumValue: IperfRole.client)  IperfRole role,  int session, @JsonKey(unknownEnumValue: IperfPhase.connecting)  IperfPhase phase,  String peer, @JsonKey(unknownEnumValue: IperfProtocol.tcp)  IperfProtocol protocol, @JsonKey(unknownEnumValue: IperfDirection.upload)  IperfDirection direction,  int parallel,  double duration,  double elapsed,  double upload,  double download, @JsonKey(name: 'upload-result')  IperfFlow? uploadResult, @JsonKey(name: 'download-result')  IperfFlow? downloadResult,  String error)  $default,) {final _that = this;
switch (_that) {
case _IperfState():
return $default(_that.role,_that.session,_that.phase,_that.peer,_that.protocol,_that.direction,_that.parallel,_that.duration,_that.elapsed,_that.upload,_that.download,_that.uploadResult,_that.downloadResult,_that.error);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(unknownEnumValue: IperfRole.client)  IperfRole role,  int session, @JsonKey(unknownEnumValue: IperfPhase.connecting)  IperfPhase phase,  String peer, @JsonKey(unknownEnumValue: IperfProtocol.tcp)  IperfProtocol protocol, @JsonKey(unknownEnumValue: IperfDirection.upload)  IperfDirection direction,  int parallel,  double duration,  double elapsed,  double upload,  double download, @JsonKey(name: 'upload-result')  IperfFlow? uploadResult, @JsonKey(name: 'download-result')  IperfFlow? downloadResult,  String error)?  $default,) {final _that = this;
switch (_that) {
case _IperfState() when $default != null:
return $default(_that.role,_that.session,_that.phase,_that.peer,_that.protocol,_that.direction,_that.parallel,_that.duration,_that.elapsed,_that.upload,_that.download,_that.uploadResult,_that.downloadResult,_that.error);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _IperfState implements IperfState {
  const _IperfState({@JsonKey(unknownEnumValue: IperfRole.client) this.role = IperfRole.client, this.session = 0, @JsonKey(unknownEnumValue: IperfPhase.connecting) this.phase = IperfPhase.connecting, this.peer = '', @JsonKey(unknownEnumValue: IperfProtocol.tcp) this.protocol = IperfProtocol.tcp, @JsonKey(unknownEnumValue: IperfDirection.upload) this.direction = IperfDirection.upload, this.parallel = 1, this.duration = 0, this.elapsed = 0, this.upload = 0, this.download = 0, @JsonKey(name: 'upload-result') this.uploadResult, @JsonKey(name: 'download-result') this.downloadResult, this.error = ''});
  factory _IperfState.fromJson(Map<String, dynamic> json) => _$IperfStateFromJson(json);

@override@JsonKey(unknownEnumValue: IperfRole.client) final  IperfRole role;
@override@JsonKey() final  int session;
@override@JsonKey(unknownEnumValue: IperfPhase.connecting) final  IperfPhase phase;
@override@JsonKey() final  String peer;
@override@JsonKey(unknownEnumValue: IperfProtocol.tcp) final  IperfProtocol protocol;
@override@JsonKey(unknownEnumValue: IperfDirection.upload) final  IperfDirection direction;
@override@JsonKey() final  int parallel;
@override@JsonKey() final  double duration;
@override@JsonKey() final  double elapsed;
@override@JsonKey() final  double upload;
@override@JsonKey() final  double download;
@override@JsonKey(name: 'upload-result') final  IperfFlow? uploadResult;
@override@JsonKey(name: 'download-result') final  IperfFlow? downloadResult;
@override@JsonKey() final  String error;

/// Create a copy of IperfState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$IperfStateCopyWith<_IperfState> get copyWith => __$IperfStateCopyWithImpl<_IperfState>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$IperfStateToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _IperfState&&(identical(other.role, role) || other.role == role)&&(identical(other.session, session) || other.session == session)&&(identical(other.phase, phase) || other.phase == phase)&&(identical(other.peer, peer) || other.peer == peer)&&(identical(other.protocol, protocol) || other.protocol == protocol)&&(identical(other.direction, direction) || other.direction == direction)&&(identical(other.parallel, parallel) || other.parallel == parallel)&&(identical(other.duration, duration) || other.duration == duration)&&(identical(other.elapsed, elapsed) || other.elapsed == elapsed)&&(identical(other.upload, upload) || other.upload == upload)&&(identical(other.download, download) || other.download == download)&&(identical(other.uploadResult, uploadResult) || other.uploadResult == uploadResult)&&(identical(other.downloadResult, downloadResult) || other.downloadResult == downloadResult)&&(identical(other.error, error) || other.error == error));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,role,session,phase,peer,protocol,direction,parallel,duration,elapsed,upload,download,uploadResult,downloadResult,error);

@override
String toString() {
  return 'IperfState(role: $role, session: $session, phase: $phase, peer: $peer, protocol: $protocol, direction: $direction, parallel: $parallel, duration: $duration, elapsed: $elapsed, upload: $upload, download: $download, uploadResult: $uploadResult, downloadResult: $downloadResult, error: $error)';
}


}

/// @nodoc
abstract mixin class _$IperfStateCopyWith<$Res> implements $IperfStateCopyWith<$Res> {
  factory _$IperfStateCopyWith(_IperfState value, $Res Function(_IperfState) _then) = __$IperfStateCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(unknownEnumValue: IperfRole.client) IperfRole role, int session,@JsonKey(unknownEnumValue: IperfPhase.connecting) IperfPhase phase, String peer,@JsonKey(unknownEnumValue: IperfProtocol.tcp) IperfProtocol protocol,@JsonKey(unknownEnumValue: IperfDirection.upload) IperfDirection direction, int parallel, double duration, double elapsed, double upload, double download,@JsonKey(name: 'upload-result') IperfFlow? uploadResult,@JsonKey(name: 'download-result') IperfFlow? downloadResult, String error
});


@override $IperfFlowCopyWith<$Res>? get uploadResult;@override $IperfFlowCopyWith<$Res>? get downloadResult;

}
/// @nodoc
class __$IperfStateCopyWithImpl<$Res>
    implements _$IperfStateCopyWith<$Res> {
  __$IperfStateCopyWithImpl(this._self, this._then);

  final _IperfState _self;
  final $Res Function(_IperfState) _then;

/// Create a copy of IperfState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? role = null,Object? session = null,Object? phase = null,Object? peer = null,Object? protocol = null,Object? direction = null,Object? parallel = null,Object? duration = null,Object? elapsed = null,Object? upload = null,Object? download = null,Object? uploadResult = freezed,Object? downloadResult = freezed,Object? error = null,}) {
  return _then(_IperfState(
role: null == role ? _self.role : role // ignore: cast_nullable_to_non_nullable
as IperfRole,session: null == session ? _self.session : session // ignore: cast_nullable_to_non_nullable
as int,phase: null == phase ? _self.phase : phase // ignore: cast_nullable_to_non_nullable
as IperfPhase,peer: null == peer ? _self.peer : peer // ignore: cast_nullable_to_non_nullable
as String,protocol: null == protocol ? _self.protocol : protocol // ignore: cast_nullable_to_non_nullable
as IperfProtocol,direction: null == direction ? _self.direction : direction // ignore: cast_nullable_to_non_nullable
as IperfDirection,parallel: null == parallel ? _self.parallel : parallel // ignore: cast_nullable_to_non_nullable
as int,duration: null == duration ? _self.duration : duration // ignore: cast_nullable_to_non_nullable
as double,elapsed: null == elapsed ? _self.elapsed : elapsed // ignore: cast_nullable_to_non_nullable
as double,upload: null == upload ? _self.upload : upload // ignore: cast_nullable_to_non_nullable
as double,download: null == download ? _self.download : download // ignore: cast_nullable_to_non_nullable
as double,uploadResult: freezed == uploadResult ? _self.uploadResult : uploadResult // ignore: cast_nullable_to_non_nullable
as IperfFlow?,downloadResult: freezed == downloadResult ? _self.downloadResult : downloadResult // ignore: cast_nullable_to_non_nullable
as IperfFlow?,error: null == error ? _self.error : error // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

/// Create a copy of IperfState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$IperfFlowCopyWith<$Res>? get uploadResult {
    if (_self.uploadResult == null) {
    return null;
  }

  return $IperfFlowCopyWith<$Res>(_self.uploadResult!, (value) {
    return _then(_self.copyWith(uploadResult: value));
  });
}/// Create a copy of IperfState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$IperfFlowCopyWith<$Res>? get downloadResult {
    if (_self.downloadResult == null) {
    return null;
  }

  return $IperfFlowCopyWith<$Res>(_self.downloadResult!, (value) {
    return _then(_self.copyWith(downloadResult: value));
  });
}
}


/// @nodoc
mixin _$IperfServerInfo {

 int get port; bool get udp; String get error;
/// Create a copy of IperfServerInfo
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$IperfServerInfoCopyWith<IperfServerInfo> get copyWith => _$IperfServerInfoCopyWithImpl<IperfServerInfo>(this as IperfServerInfo, _$identity);

  /// Serializes this IperfServerInfo to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is IperfServerInfo&&(identical(other.port, port) || other.port == port)&&(identical(other.udp, udp) || other.udp == udp)&&(identical(other.error, error) || other.error == error));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,port,udp,error);

@override
String toString() {
  return 'IperfServerInfo(port: $port, udp: $udp, error: $error)';
}


}

/// @nodoc
abstract mixin class $IperfServerInfoCopyWith<$Res>  {
  factory $IperfServerInfoCopyWith(IperfServerInfo value, $Res Function(IperfServerInfo) _then) = _$IperfServerInfoCopyWithImpl;
@useResult
$Res call({
 int port, bool udp, String error
});




}
/// @nodoc
class _$IperfServerInfoCopyWithImpl<$Res>
    implements $IperfServerInfoCopyWith<$Res> {
  _$IperfServerInfoCopyWithImpl(this._self, this._then);

  final IperfServerInfo _self;
  final $Res Function(IperfServerInfo) _then;

/// Create a copy of IperfServerInfo
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? port = null,Object? udp = null,Object? error = null,}) {
  return _then(IperfServerInfo(
port: null == port ? _self.port : port // ignore: cast_nullable_to_non_nullable
as int,udp: null == udp ? _self.udp : udp // ignore: cast_nullable_to_non_nullable
as bool,error: null == error ? _self.error : error // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [IperfServerInfo].
extension IperfServerInfoPatterns on IperfServerInfo {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _IperfServerInfo value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _IperfServerInfo() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _IperfServerInfo value)  $default,){
final _that = this;
switch (_that) {
case _IperfServerInfo():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _IperfServerInfo value)?  $default,){
final _that = this;
switch (_that) {
case _IperfServerInfo() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int port,  bool udp,  String error)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _IperfServerInfo() when $default != null:
return $default(_that.port,_that.udp,_that.error);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int port,  bool udp,  String error)  $default,) {final _that = this;
switch (_that) {
case _IperfServerInfo():
return $default(_that.port,_that.udp,_that.error);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int port,  bool udp,  String error)?  $default,) {final _that = this;
switch (_that) {
case _IperfServerInfo() when $default != null:
return $default(_that.port,_that.udp,_that.error);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _IperfServerInfo implements IperfServerInfo {
  const _IperfServerInfo({this.port = 0, this.udp = false, this.error = ''});
  factory _IperfServerInfo.fromJson(Map<String, dynamic> json) => _$IperfServerInfoFromJson(json);

@override@JsonKey() final  int port;
@override@JsonKey() final  bool udp;
@override@JsonKey() final  String error;

/// Create a copy of IperfServerInfo
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$IperfServerInfoCopyWith<_IperfServerInfo> get copyWith => __$IperfServerInfoCopyWithImpl<_IperfServerInfo>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$IperfServerInfoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _IperfServerInfo&&(identical(other.port, port) || other.port == port)&&(identical(other.udp, udp) || other.udp == udp)&&(identical(other.error, error) || other.error == error));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,port,udp,error);

@override
String toString() {
  return 'IperfServerInfo(port: $port, udp: $udp, error: $error)';
}


}

/// @nodoc
abstract mixin class _$IperfServerInfoCopyWith<$Res> implements $IperfServerInfoCopyWith<$Res> {
  factory _$IperfServerInfoCopyWith(_IperfServerInfo value, $Res Function(_IperfServerInfo) _then) = __$IperfServerInfoCopyWithImpl;
@override @useResult
$Res call({
 int port, bool udp, String error
});




}
/// @nodoc
class __$IperfServerInfoCopyWithImpl<$Res>
    implements _$IperfServerInfoCopyWith<$Res> {
  __$IperfServerInfoCopyWithImpl(this._self, this._then);

  final _IperfServerInfo _self;
  final $Res Function(_IperfServerInfo) _then;

/// Create a copy of IperfServerInfo
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? port = null,Object? udp = null,Object? error = null,}) {
  return _then(_IperfServerInfo(
port: null == port ? _self.port : port // ignore: cast_nullable_to_non_nullable
as int,udp: null == udp ? _self.udp : udp // ignore: cast_nullable_to_non_nullable
as bool,error: null == error ? _self.error : error // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$IperfOptions {

@JsonKey(unknownEnumValue: IperfProtocol.tcp) IperfProtocol get protocol;@JsonKey(unknownEnumValue: IperfDirection.upload) IperfDirection get direction; int get parallel; int get duration; int get bandwidth; int get serverPort;
/// Create a copy of IperfOptions
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$IperfOptionsCopyWith<IperfOptions> get copyWith => _$IperfOptionsCopyWithImpl<IperfOptions>(this as IperfOptions, _$identity);

  /// Serializes this IperfOptions to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is IperfOptions&&(identical(other.protocol, protocol) || other.protocol == protocol)&&(identical(other.direction, direction) || other.direction == direction)&&(identical(other.parallel, parallel) || other.parallel == parallel)&&(identical(other.duration, duration) || other.duration == duration)&&(identical(other.bandwidth, bandwidth) || other.bandwidth == bandwidth)&&(identical(other.serverPort, serverPort) || other.serverPort == serverPort));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,protocol,direction,parallel,duration,bandwidth,serverPort);

@override
String toString() {
  return 'IperfOptions(protocol: $protocol, direction: $direction, parallel: $parallel, duration: $duration, bandwidth: $bandwidth, serverPort: $serverPort)';
}


}

/// @nodoc
abstract mixin class $IperfOptionsCopyWith<$Res>  {
  factory $IperfOptionsCopyWith(IperfOptions value, $Res Function(IperfOptions) _then) = _$IperfOptionsCopyWithImpl;
@useResult
$Res call({
@JsonKey(unknownEnumValue: IperfProtocol.tcp) IperfProtocol protocol,@JsonKey(unknownEnumValue: IperfDirection.upload) IperfDirection direction, int parallel, int duration, int bandwidth, int serverPort
});




}
/// @nodoc
class _$IperfOptionsCopyWithImpl<$Res>
    implements $IperfOptionsCopyWith<$Res> {
  _$IperfOptionsCopyWithImpl(this._self, this._then);

  final IperfOptions _self;
  final $Res Function(IperfOptions) _then;

/// Create a copy of IperfOptions
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? protocol = null,Object? direction = null,Object? parallel = null,Object? duration = null,Object? bandwidth = null,Object? serverPort = null,}) {
  return _then(IperfOptions(
protocol: null == protocol ? _self.protocol : protocol // ignore: cast_nullable_to_non_nullable
as IperfProtocol,direction: null == direction ? _self.direction : direction // ignore: cast_nullable_to_non_nullable
as IperfDirection,parallel: null == parallel ? _self.parallel : parallel // ignore: cast_nullable_to_non_nullable
as int,duration: null == duration ? _self.duration : duration // ignore: cast_nullable_to_non_nullable
as int,bandwidth: null == bandwidth ? _self.bandwidth : bandwidth // ignore: cast_nullable_to_non_nullable
as int,serverPort: null == serverPort ? _self.serverPort : serverPort // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [IperfOptions].
extension IperfOptionsPatterns on IperfOptions {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _IperfOptions value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _IperfOptions() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _IperfOptions value)  $default,){
final _that = this;
switch (_that) {
case _IperfOptions():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _IperfOptions value)?  $default,){
final _that = this;
switch (_that) {
case _IperfOptions() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(unknownEnumValue: IperfProtocol.tcp)  IperfProtocol protocol, @JsonKey(unknownEnumValue: IperfDirection.upload)  IperfDirection direction,  int parallel,  int duration,  int bandwidth,  int serverPort)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _IperfOptions() when $default != null:
return $default(_that.protocol,_that.direction,_that.parallel,_that.duration,_that.bandwidth,_that.serverPort);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(unknownEnumValue: IperfProtocol.tcp)  IperfProtocol protocol, @JsonKey(unknownEnumValue: IperfDirection.upload)  IperfDirection direction,  int parallel,  int duration,  int bandwidth,  int serverPort)  $default,) {final _that = this;
switch (_that) {
case _IperfOptions():
return $default(_that.protocol,_that.direction,_that.parallel,_that.duration,_that.bandwidth,_that.serverPort);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(unknownEnumValue: IperfProtocol.tcp)  IperfProtocol protocol, @JsonKey(unknownEnumValue: IperfDirection.upload)  IperfDirection direction,  int parallel,  int duration,  int bandwidth,  int serverPort)?  $default,) {final _that = this;
switch (_that) {
case _IperfOptions() when $default != null:
return $default(_that.protocol,_that.direction,_that.parallel,_that.duration,_that.bandwidth,_that.serverPort);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _IperfOptions implements IperfOptions {
  const _IperfOptions({@JsonKey(unknownEnumValue: IperfProtocol.tcp) this.protocol = IperfProtocol.tcp, @JsonKey(unknownEnumValue: IperfDirection.upload) this.direction = IperfDirection.upload, this.parallel = 1, this.duration = 10, this.bandwidth = 100, this.serverPort = 5201});
  factory _IperfOptions.fromJson(Map<String, dynamic> json) => _$IperfOptionsFromJson(json);

@override@JsonKey(unknownEnumValue: IperfProtocol.tcp) final  IperfProtocol protocol;
@override@JsonKey(unknownEnumValue: IperfDirection.upload) final  IperfDirection direction;
@override@JsonKey() final  int parallel;
@override@JsonKey() final  int duration;
@override@JsonKey() final  int bandwidth;
@override@JsonKey() final  int serverPort;

/// Create a copy of IperfOptions
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$IperfOptionsCopyWith<_IperfOptions> get copyWith => __$IperfOptionsCopyWithImpl<_IperfOptions>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$IperfOptionsToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _IperfOptions&&(identical(other.protocol, protocol) || other.protocol == protocol)&&(identical(other.direction, direction) || other.direction == direction)&&(identical(other.parallel, parallel) || other.parallel == parallel)&&(identical(other.duration, duration) || other.duration == duration)&&(identical(other.bandwidth, bandwidth) || other.bandwidth == bandwidth)&&(identical(other.serverPort, serverPort) || other.serverPort == serverPort));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,protocol,direction,parallel,duration,bandwidth,serverPort);

@override
String toString() {
  return 'IperfOptions(protocol: $protocol, direction: $direction, parallel: $parallel, duration: $duration, bandwidth: $bandwidth, serverPort: $serverPort)';
}


}

/// @nodoc
abstract mixin class _$IperfOptionsCopyWith<$Res> implements $IperfOptionsCopyWith<$Res> {
  factory _$IperfOptionsCopyWith(_IperfOptions value, $Res Function(_IperfOptions) _then) = __$IperfOptionsCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(unknownEnumValue: IperfProtocol.tcp) IperfProtocol protocol,@JsonKey(unknownEnumValue: IperfDirection.upload) IperfDirection direction, int parallel, int duration, int bandwidth, int serverPort
});




}
/// @nodoc
class __$IperfOptionsCopyWithImpl<$Res>
    implements _$IperfOptionsCopyWith<$Res> {
  __$IperfOptionsCopyWithImpl(this._self, this._then);

  final _IperfOptions _self;
  final $Res Function(_IperfOptions) _then;

/// Create a copy of IperfOptions
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? protocol = null,Object? direction = null,Object? parallel = null,Object? duration = null,Object? bandwidth = null,Object? serverPort = null,}) {
  return _then(_IperfOptions(
protocol: null == protocol ? _self.protocol : protocol // ignore: cast_nullable_to_non_nullable
as IperfProtocol,direction: null == direction ? _self.direction : direction // ignore: cast_nullable_to_non_nullable
as IperfDirection,parallel: null == parallel ? _self.parallel : parallel // ignore: cast_nullable_to_non_nullable
as int,duration: null == duration ? _self.duration : duration // ignore: cast_nullable_to_non_nullable
as int,bandwidth: null == bandwidth ? _self.bandwidth : bandwidth // ignore: cast_nullable_to_non_nullable
as int,serverPort: null == serverPort ? _self.serverPort : serverPort // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
