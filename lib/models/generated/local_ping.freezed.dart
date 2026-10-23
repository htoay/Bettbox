// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of '../local_ping.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$LocalPingReply {

 int get seq;@JsonKey(unknownEnumValue: LocalPingStatus.error) LocalPingStatus get status; double get rtt; int get ttl; int get bytes;
/// Create a copy of LocalPingReply
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LocalPingReplyCopyWith<LocalPingReply> get copyWith => _$LocalPingReplyCopyWithImpl<LocalPingReply>(this as LocalPingReply, _$identity);

  /// Serializes this LocalPingReply to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LocalPingReply&&(identical(other.seq, seq) || other.seq == seq)&&(identical(other.status, status) || other.status == status)&&(identical(other.rtt, rtt) || other.rtt == rtt)&&(identical(other.ttl, ttl) || other.ttl == ttl)&&(identical(other.bytes, bytes) || other.bytes == bytes));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,seq,status,rtt,ttl,bytes);

@override
String toString() {
  return 'LocalPingReply(seq: $seq, status: $status, rtt: $rtt, ttl: $ttl, bytes: $bytes)';
}


}

/// @nodoc
abstract mixin class $LocalPingReplyCopyWith<$Res>  {
  factory $LocalPingReplyCopyWith(LocalPingReply value, $Res Function(LocalPingReply) _then) = _$LocalPingReplyCopyWithImpl;
@useResult
$Res call({
 int seq,@JsonKey(unknownEnumValue: LocalPingStatus.error) LocalPingStatus status, double rtt, int ttl, int bytes
});




}
/// @nodoc
class _$LocalPingReplyCopyWithImpl<$Res>
    implements $LocalPingReplyCopyWith<$Res> {
  _$LocalPingReplyCopyWithImpl(this._self, this._then);

  final LocalPingReply _self;
  final $Res Function(LocalPingReply) _then;

/// Create a copy of LocalPingReply
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? seq = null,Object? status = null,Object? rtt = null,Object? ttl = null,Object? bytes = null,}) {
  return _then(LocalPingReply(
seq: null == seq ? _self.seq : seq // ignore: cast_nullable_to_non_nullable
as int,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as LocalPingStatus,rtt: null == rtt ? _self.rtt : rtt // ignore: cast_nullable_to_non_nullable
as double,ttl: null == ttl ? _self.ttl : ttl // ignore: cast_nullable_to_non_nullable
as int,bytes: null == bytes ? _self.bytes : bytes // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [LocalPingReply].
extension LocalPingReplyPatterns on LocalPingReply {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _LocalPingReply value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _LocalPingReply() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _LocalPingReply value)  $default,){
final _that = this;
switch (_that) {
case _LocalPingReply():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _LocalPingReply value)?  $default,){
final _that = this;
switch (_that) {
case _LocalPingReply() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int seq, @JsonKey(unknownEnumValue: LocalPingStatus.error)  LocalPingStatus status,  double rtt,  int ttl,  int bytes)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _LocalPingReply() when $default != null:
return $default(_that.seq,_that.status,_that.rtt,_that.ttl,_that.bytes);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int seq, @JsonKey(unknownEnumValue: LocalPingStatus.error)  LocalPingStatus status,  double rtt,  int ttl,  int bytes)  $default,) {final _that = this;
switch (_that) {
case _LocalPingReply():
return $default(_that.seq,_that.status,_that.rtt,_that.ttl,_that.bytes);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int seq, @JsonKey(unknownEnumValue: LocalPingStatus.error)  LocalPingStatus status,  double rtt,  int ttl,  int bytes)?  $default,) {final _that = this;
switch (_that) {
case _LocalPingReply() when $default != null:
return $default(_that.seq,_that.status,_that.rtt,_that.ttl,_that.bytes);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _LocalPingReply implements LocalPingReply {
  const _LocalPingReply({this.seq = 0, @JsonKey(unknownEnumValue: LocalPingStatus.error) this.status = LocalPingStatus.error, this.rtt = 0, this.ttl = 0, this.bytes = 0});
  factory _LocalPingReply.fromJson(Map<String, dynamic> json) => _$LocalPingReplyFromJson(json);

@override@JsonKey() final  int seq;
@override@JsonKey(unknownEnumValue: LocalPingStatus.error) final  LocalPingStatus status;
@override@JsonKey() final  double rtt;
@override@JsonKey() final  int ttl;
@override@JsonKey() final  int bytes;

/// Create a copy of LocalPingReply
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LocalPingReplyCopyWith<_LocalPingReply> get copyWith => __$LocalPingReplyCopyWithImpl<_LocalPingReply>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$LocalPingReplyToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _LocalPingReply&&(identical(other.seq, seq) || other.seq == seq)&&(identical(other.status, status) || other.status == status)&&(identical(other.rtt, rtt) || other.rtt == rtt)&&(identical(other.ttl, ttl) || other.ttl == ttl)&&(identical(other.bytes, bytes) || other.bytes == bytes));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,seq,status,rtt,ttl,bytes);

@override
String toString() {
  return 'LocalPingReply(seq: $seq, status: $status, rtt: $rtt, ttl: $ttl, bytes: $bytes)';
}


}

/// @nodoc
abstract mixin class _$LocalPingReplyCopyWith<$Res> implements $LocalPingReplyCopyWith<$Res> {
  factory _$LocalPingReplyCopyWith(_LocalPingReply value, $Res Function(_LocalPingReply) _then) = __$LocalPingReplyCopyWithImpl;
@override @useResult
$Res call({
 int seq,@JsonKey(unknownEnumValue: LocalPingStatus.error) LocalPingStatus status, double rtt, int ttl, int bytes
});




}
/// @nodoc
class __$LocalPingReplyCopyWithImpl<$Res>
    implements _$LocalPingReplyCopyWith<$Res> {
  __$LocalPingReplyCopyWithImpl(this._self, this._then);

  final _LocalPingReply _self;
  final $Res Function(_LocalPingReply) _then;

/// Create a copy of LocalPingReply
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? seq = null,Object? status = null,Object? rtt = null,Object? ttl = null,Object? bytes = null,}) {
  return _then(_LocalPingReply(
seq: null == seq ? _self.seq : seq // ignore: cast_nullable_to_non_nullable
as int,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as LocalPingStatus,rtt: null == rtt ? _self.rtt : rtt // ignore: cast_nullable_to_non_nullable
as double,ttl: null == ttl ? _self.ttl : ttl // ignore: cast_nullable_to_non_nullable
as int,bytes: null == bytes ? _self.bytes : bytes // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$LocalPingState {

 int get session;@JsonKey(unknownEnumValue: LocalPingPhase.done) LocalPingPhase get phase; String get target; String get address;@JsonKey(unknownEnumValue: LocalPingProtocol.icmp) LocalPingProtocol get protocol; int get port; int get size; int get count; int get interval; int get sent; double get elapsed; LocalPingReply? get reply; List<LocalPingReply> get replies; String get error;
/// Create a copy of LocalPingState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LocalPingStateCopyWith<LocalPingState> get copyWith => _$LocalPingStateCopyWithImpl<LocalPingState>(this as LocalPingState, _$identity);

  /// Serializes this LocalPingState to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LocalPingState&&(identical(other.session, session) || other.session == session)&&(identical(other.phase, phase) || other.phase == phase)&&(identical(other.target, target) || other.target == target)&&(identical(other.address, address) || other.address == address)&&(identical(other.protocol, protocol) || other.protocol == protocol)&&(identical(other.port, port) || other.port == port)&&(identical(other.size, size) || other.size == size)&&(identical(other.count, count) || other.count == count)&&(identical(other.interval, interval) || other.interval == interval)&&(identical(other.sent, sent) || other.sent == sent)&&(identical(other.elapsed, elapsed) || other.elapsed == elapsed)&&(identical(other.reply, reply) || other.reply == reply)&&const DeepCollectionEquality().equals(other.replies, replies)&&(identical(other.error, error) || other.error == error));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,session,phase,target,address,protocol,port,size,count,interval,sent,elapsed,reply,const DeepCollectionEquality().hash(replies),error);

@override
String toString() {
  return 'LocalPingState(session: $session, phase: $phase, target: $target, address: $address, protocol: $protocol, port: $port, size: $size, count: $count, interval: $interval, sent: $sent, elapsed: $elapsed, reply: $reply, replies: $replies, error: $error)';
}


}

/// @nodoc
abstract mixin class $LocalPingStateCopyWith<$Res>  {
  factory $LocalPingStateCopyWith(LocalPingState value, $Res Function(LocalPingState) _then) = _$LocalPingStateCopyWithImpl;
@useResult
$Res call({
 int session,@JsonKey(unknownEnumValue: LocalPingPhase.done) LocalPingPhase phase, String target, String address,@JsonKey(unknownEnumValue: LocalPingProtocol.icmp) LocalPingProtocol protocol, int port, int size, int count, int interval, int sent, double elapsed, LocalPingReply? reply, List<LocalPingReply> replies, String error
});


$LocalPingReplyCopyWith<$Res>? get reply;

}
/// @nodoc
class _$LocalPingStateCopyWithImpl<$Res>
    implements $LocalPingStateCopyWith<$Res> {
  _$LocalPingStateCopyWithImpl(this._self, this._then);

  final LocalPingState _self;
  final $Res Function(LocalPingState) _then;

/// Create a copy of LocalPingState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? session = null,Object? phase = null,Object? target = null,Object? address = null,Object? protocol = null,Object? port = null,Object? size = null,Object? count = null,Object? interval = null,Object? sent = null,Object? elapsed = null,Object? reply = freezed,Object? replies = null,Object? error = null,}) {
  return _then(LocalPingState(
session: null == session ? _self.session : session // ignore: cast_nullable_to_non_nullable
as int,phase: null == phase ? _self.phase : phase // ignore: cast_nullable_to_non_nullable
as LocalPingPhase,target: null == target ? _self.target : target // ignore: cast_nullable_to_non_nullable
as String,address: null == address ? _self.address : address // ignore: cast_nullable_to_non_nullable
as String,protocol: null == protocol ? _self.protocol : protocol // ignore: cast_nullable_to_non_nullable
as LocalPingProtocol,port: null == port ? _self.port : port // ignore: cast_nullable_to_non_nullable
as int,size: null == size ? _self.size : size // ignore: cast_nullable_to_non_nullable
as int,count: null == count ? _self.count : count // ignore: cast_nullable_to_non_nullable
as int,interval: null == interval ? _self.interval : interval // ignore: cast_nullable_to_non_nullable
as int,sent: null == sent ? _self.sent : sent // ignore: cast_nullable_to_non_nullable
as int,elapsed: null == elapsed ? _self.elapsed : elapsed // ignore: cast_nullable_to_non_nullable
as double,reply: freezed == reply ? _self.reply : reply // ignore: cast_nullable_to_non_nullable
as LocalPingReply?,replies: null == replies ? _self.replies : replies // ignore: cast_nullable_to_non_nullable
as List<LocalPingReply>,error: null == error ? _self.error : error // ignore: cast_nullable_to_non_nullable
as String,
  ));
}
/// Create a copy of LocalPingState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$LocalPingReplyCopyWith<$Res>? get reply {
    if (_self.reply == null) {
    return null;
  }

  return $LocalPingReplyCopyWith<$Res>(_self.reply!, (value) {
    return _then(_self.copyWith(reply: value));
  });
}
}


/// Adds pattern-matching-related methods to [LocalPingState].
extension LocalPingStatePatterns on LocalPingState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _LocalPingState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _LocalPingState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _LocalPingState value)  $default,){
final _that = this;
switch (_that) {
case _LocalPingState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _LocalPingState value)?  $default,){
final _that = this;
switch (_that) {
case _LocalPingState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int session, @JsonKey(unknownEnumValue: LocalPingPhase.done)  LocalPingPhase phase,  String target,  String address, @JsonKey(unknownEnumValue: LocalPingProtocol.icmp)  LocalPingProtocol protocol,  int port,  int size,  int count,  int interval,  int sent,  double elapsed,  LocalPingReply? reply,  List<LocalPingReply> replies,  String error)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _LocalPingState() when $default != null:
return $default(_that.session,_that.phase,_that.target,_that.address,_that.protocol,_that.port,_that.size,_that.count,_that.interval,_that.sent,_that.elapsed,_that.reply,_that.replies,_that.error);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int session, @JsonKey(unknownEnumValue: LocalPingPhase.done)  LocalPingPhase phase,  String target,  String address, @JsonKey(unknownEnumValue: LocalPingProtocol.icmp)  LocalPingProtocol protocol,  int port,  int size,  int count,  int interval,  int sent,  double elapsed,  LocalPingReply? reply,  List<LocalPingReply> replies,  String error)  $default,) {final _that = this;
switch (_that) {
case _LocalPingState():
return $default(_that.session,_that.phase,_that.target,_that.address,_that.protocol,_that.port,_that.size,_that.count,_that.interval,_that.sent,_that.elapsed,_that.reply,_that.replies,_that.error);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int session, @JsonKey(unknownEnumValue: LocalPingPhase.done)  LocalPingPhase phase,  String target,  String address, @JsonKey(unknownEnumValue: LocalPingProtocol.icmp)  LocalPingProtocol protocol,  int port,  int size,  int count,  int interval,  int sent,  double elapsed,  LocalPingReply? reply,  List<LocalPingReply> replies,  String error)?  $default,) {final _that = this;
switch (_that) {
case _LocalPingState() when $default != null:
return $default(_that.session,_that.phase,_that.target,_that.address,_that.protocol,_that.port,_that.size,_that.count,_that.interval,_that.sent,_that.elapsed,_that.reply,_that.replies,_that.error);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _LocalPingState implements LocalPingState {
  const _LocalPingState({this.session = 0, @JsonKey(unknownEnumValue: LocalPingPhase.done) this.phase = LocalPingPhase.resolving, this.target = '', this.address = '', @JsonKey(unknownEnumValue: LocalPingProtocol.icmp) this.protocol = LocalPingProtocol.icmp, this.port = 0, this.size = 0, this.count = 0, this.interval = 0, this.sent = 0, this.elapsed = 0, this.reply,  List<LocalPingReply> replies = const [], this.error = ''}): _replies = replies;
  factory _LocalPingState.fromJson(Map<String, dynamic> json) => _$LocalPingStateFromJson(json);

@override@JsonKey() final  int session;
@override@JsonKey(unknownEnumValue: LocalPingPhase.done) final  LocalPingPhase phase;
@override@JsonKey() final  String target;
@override@JsonKey() final  String address;
@override@JsonKey(unknownEnumValue: LocalPingProtocol.icmp) final  LocalPingProtocol protocol;
@override@JsonKey() final  int port;
@override@JsonKey() final  int size;
@override@JsonKey() final  int count;
@override@JsonKey() final  int interval;
@override@JsonKey() final  int sent;
@override@JsonKey() final  double elapsed;
@override final  LocalPingReply? reply;
 final  List<LocalPingReply> _replies;
@override@JsonKey() List<LocalPingReply> get replies {
  if (_replies is EqualUnmodifiableListView) return _replies;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_replies);
}

@override@JsonKey() final  String error;

/// Create a copy of LocalPingState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LocalPingStateCopyWith<_LocalPingState> get copyWith => __$LocalPingStateCopyWithImpl<_LocalPingState>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$LocalPingStateToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _LocalPingState&&(identical(other.session, session) || other.session == session)&&(identical(other.phase, phase) || other.phase == phase)&&(identical(other.target, target) || other.target == target)&&(identical(other.address, address) || other.address == address)&&(identical(other.protocol, protocol) || other.protocol == protocol)&&(identical(other.port, port) || other.port == port)&&(identical(other.size, size) || other.size == size)&&(identical(other.count, count) || other.count == count)&&(identical(other.interval, interval) || other.interval == interval)&&(identical(other.sent, sent) || other.sent == sent)&&(identical(other.elapsed, elapsed) || other.elapsed == elapsed)&&(identical(other.reply, reply) || other.reply == reply)&&const DeepCollectionEquality().equals(other._replies, _replies)&&(identical(other.error, error) || other.error == error));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,session,phase,target,address,protocol,port,size,count,interval,sent,elapsed,reply,const DeepCollectionEquality().hash(_replies),error);

@override
String toString() {
  return 'LocalPingState(session: $session, phase: $phase, target: $target, address: $address, protocol: $protocol, port: $port, size: $size, count: $count, interval: $interval, sent: $sent, elapsed: $elapsed, reply: $reply, replies: $replies, error: $error)';
}


}

/// @nodoc
abstract mixin class _$LocalPingStateCopyWith<$Res> implements $LocalPingStateCopyWith<$Res> {
  factory _$LocalPingStateCopyWith(_LocalPingState value, $Res Function(_LocalPingState) _then) = __$LocalPingStateCopyWithImpl;
@override @useResult
$Res call({
 int session,@JsonKey(unknownEnumValue: LocalPingPhase.done) LocalPingPhase phase, String target, String address,@JsonKey(unknownEnumValue: LocalPingProtocol.icmp) LocalPingProtocol protocol, int port, int size, int count, int interval, int sent, double elapsed, LocalPingReply? reply, List<LocalPingReply> replies, String error
});


@override $LocalPingReplyCopyWith<$Res>? get reply;

}
/// @nodoc
class __$LocalPingStateCopyWithImpl<$Res>
    implements _$LocalPingStateCopyWith<$Res> {
  __$LocalPingStateCopyWithImpl(this._self, this._then);

  final _LocalPingState _self;
  final $Res Function(_LocalPingState) _then;

/// Create a copy of LocalPingState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? session = null,Object? phase = null,Object? target = null,Object? address = null,Object? protocol = null,Object? port = null,Object? size = null,Object? count = null,Object? interval = null,Object? sent = null,Object? elapsed = null,Object? reply = freezed,Object? replies = null,Object? error = null,}) {
  return _then(_LocalPingState(
session: null == session ? _self.session : session // ignore: cast_nullable_to_non_nullable
as int,phase: null == phase ? _self.phase : phase // ignore: cast_nullable_to_non_nullable
as LocalPingPhase,target: null == target ? _self.target : target // ignore: cast_nullable_to_non_nullable
as String,address: null == address ? _self.address : address // ignore: cast_nullable_to_non_nullable
as String,protocol: null == protocol ? _self.protocol : protocol // ignore: cast_nullable_to_non_nullable
as LocalPingProtocol,port: null == port ? _self.port : port // ignore: cast_nullable_to_non_nullable
as int,size: null == size ? _self.size : size // ignore: cast_nullable_to_non_nullable
as int,count: null == count ? _self.count : count // ignore: cast_nullable_to_non_nullable
as int,interval: null == interval ? _self.interval : interval // ignore: cast_nullable_to_non_nullable
as int,sent: null == sent ? _self.sent : sent // ignore: cast_nullable_to_non_nullable
as int,elapsed: null == elapsed ? _self.elapsed : elapsed // ignore: cast_nullable_to_non_nullable
as double,reply: freezed == reply ? _self.reply : reply // ignore: cast_nullable_to_non_nullable
as LocalPingReply?,replies: null == replies ? _self._replies : replies // ignore: cast_nullable_to_non_nullable
as List<LocalPingReply>,error: null == error ? _self.error : error // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

/// Create a copy of LocalPingState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$LocalPingReplyCopyWith<$Res>? get reply {
    if (_self.reply == null) {
    return null;
  }

  return $LocalPingReplyCopyWith<$Res>(_self.reply!, (value) {
    return _then(_self.copyWith(reply: value));
  });
}
}


/// @nodoc
mixin _$LocalPingOptions {

@JsonKey(unknownEnumValue: LocalPingProtocol.icmp) LocalPingProtocol get protocol; int get count; int get interval; int get size; int get tcpPort; int get udpPort;
/// Create a copy of LocalPingOptions
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LocalPingOptionsCopyWith<LocalPingOptions> get copyWith => _$LocalPingOptionsCopyWithImpl<LocalPingOptions>(this as LocalPingOptions, _$identity);

  /// Serializes this LocalPingOptions to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LocalPingOptions&&(identical(other.protocol, protocol) || other.protocol == protocol)&&(identical(other.count, count) || other.count == count)&&(identical(other.interval, interval) || other.interval == interval)&&(identical(other.size, size) || other.size == size)&&(identical(other.tcpPort, tcpPort) || other.tcpPort == tcpPort)&&(identical(other.udpPort, udpPort) || other.udpPort == udpPort));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,protocol,count,interval,size,tcpPort,udpPort);

@override
String toString() {
  return 'LocalPingOptions(protocol: $protocol, count: $count, interval: $interval, size: $size, tcpPort: $tcpPort, udpPort: $udpPort)';
}


}

/// @nodoc
abstract mixin class $LocalPingOptionsCopyWith<$Res>  {
  factory $LocalPingOptionsCopyWith(LocalPingOptions value, $Res Function(LocalPingOptions) _then) = _$LocalPingOptionsCopyWithImpl;
@useResult
$Res call({
@JsonKey(unknownEnumValue: LocalPingProtocol.icmp) LocalPingProtocol protocol, int count, int interval, int size, int tcpPort, int udpPort
});




}
/// @nodoc
class _$LocalPingOptionsCopyWithImpl<$Res>
    implements $LocalPingOptionsCopyWith<$Res> {
  _$LocalPingOptionsCopyWithImpl(this._self, this._then);

  final LocalPingOptions _self;
  final $Res Function(LocalPingOptions) _then;

/// Create a copy of LocalPingOptions
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? protocol = null,Object? count = null,Object? interval = null,Object? size = null,Object? tcpPort = null,Object? udpPort = null,}) {
  return _then(LocalPingOptions(
protocol: null == protocol ? _self.protocol : protocol // ignore: cast_nullable_to_non_nullable
as LocalPingProtocol,count: null == count ? _self.count : count // ignore: cast_nullable_to_non_nullable
as int,interval: null == interval ? _self.interval : interval // ignore: cast_nullable_to_non_nullable
as int,size: null == size ? _self.size : size // ignore: cast_nullable_to_non_nullable
as int,tcpPort: null == tcpPort ? _self.tcpPort : tcpPort // ignore: cast_nullable_to_non_nullable
as int,udpPort: null == udpPort ? _self.udpPort : udpPort // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [LocalPingOptions].
extension LocalPingOptionsPatterns on LocalPingOptions {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _LocalPingOptions value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _LocalPingOptions() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _LocalPingOptions value)  $default,){
final _that = this;
switch (_that) {
case _LocalPingOptions():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _LocalPingOptions value)?  $default,){
final _that = this;
switch (_that) {
case _LocalPingOptions() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(unknownEnumValue: LocalPingProtocol.icmp)  LocalPingProtocol protocol,  int count,  int interval,  int size,  int tcpPort,  int udpPort)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _LocalPingOptions() when $default != null:
return $default(_that.protocol,_that.count,_that.interval,_that.size,_that.tcpPort,_that.udpPort);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(unknownEnumValue: LocalPingProtocol.icmp)  LocalPingProtocol protocol,  int count,  int interval,  int size,  int tcpPort,  int udpPort)  $default,) {final _that = this;
switch (_that) {
case _LocalPingOptions():
return $default(_that.protocol,_that.count,_that.interval,_that.size,_that.tcpPort,_that.udpPort);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(unknownEnumValue: LocalPingProtocol.icmp)  LocalPingProtocol protocol,  int count,  int interval,  int size,  int tcpPort,  int udpPort)?  $default,) {final _that = this;
switch (_that) {
case _LocalPingOptions() when $default != null:
return $default(_that.protocol,_that.count,_that.interval,_that.size,_that.tcpPort,_that.udpPort);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _LocalPingOptions implements LocalPingOptions {
  const _LocalPingOptions({@JsonKey(unknownEnumValue: LocalPingProtocol.icmp) this.protocol = LocalPingProtocol.icmp, this.count = 10, this.interval = 1000, this.size = 56, this.tcpPort = 443, this.udpPort = 53});
  factory _LocalPingOptions.fromJson(Map<String, dynamic> json) => _$LocalPingOptionsFromJson(json);

@override@JsonKey(unknownEnumValue: LocalPingProtocol.icmp) final  LocalPingProtocol protocol;
@override@JsonKey() final  int count;
@override@JsonKey() final  int interval;
@override@JsonKey() final  int size;
@override@JsonKey() final  int tcpPort;
@override@JsonKey() final  int udpPort;

/// Create a copy of LocalPingOptions
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LocalPingOptionsCopyWith<_LocalPingOptions> get copyWith => __$LocalPingOptionsCopyWithImpl<_LocalPingOptions>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$LocalPingOptionsToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _LocalPingOptions&&(identical(other.protocol, protocol) || other.protocol == protocol)&&(identical(other.count, count) || other.count == count)&&(identical(other.interval, interval) || other.interval == interval)&&(identical(other.size, size) || other.size == size)&&(identical(other.tcpPort, tcpPort) || other.tcpPort == tcpPort)&&(identical(other.udpPort, udpPort) || other.udpPort == udpPort));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,protocol,count,interval,size,tcpPort,udpPort);

@override
String toString() {
  return 'LocalPingOptions(protocol: $protocol, count: $count, interval: $interval, size: $size, tcpPort: $tcpPort, udpPort: $udpPort)';
}


}

/// @nodoc
abstract mixin class _$LocalPingOptionsCopyWith<$Res> implements $LocalPingOptionsCopyWith<$Res> {
  factory _$LocalPingOptionsCopyWith(_LocalPingOptions value, $Res Function(_LocalPingOptions) _then) = __$LocalPingOptionsCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(unknownEnumValue: LocalPingProtocol.icmp) LocalPingProtocol protocol, int count, int interval, int size, int tcpPort, int udpPort
});




}
/// @nodoc
class __$LocalPingOptionsCopyWithImpl<$Res>
    implements _$LocalPingOptionsCopyWith<$Res> {
  __$LocalPingOptionsCopyWithImpl(this._self, this._then);

  final _LocalPingOptions _self;
  final $Res Function(_LocalPingOptions) _then;

/// Create a copy of LocalPingOptions
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? protocol = null,Object? count = null,Object? interval = null,Object? size = null,Object? tcpPort = null,Object? udpPort = null,}) {
  return _then(_LocalPingOptions(
protocol: null == protocol ? _self.protocol : protocol // ignore: cast_nullable_to_non_nullable
as LocalPingProtocol,count: null == count ? _self.count : count // ignore: cast_nullable_to_non_nullable
as int,interval: null == interval ? _self.interval : interval // ignore: cast_nullable_to_non_nullable
as int,size: null == size ? _self.size : size // ignore: cast_nullable_to_non_nullable
as int,tcpPort: null == tcpPort ? _self.tcpPort : tcpPort // ignore: cast_nullable_to_non_nullable
as int,udpPort: null == udpPort ? _self.udpPort : udpPort // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
