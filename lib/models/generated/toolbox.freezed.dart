// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of '../toolbox.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$RouteTraceStep {

 int get index; String get type; String get payload; String get adapter; bool get matched; bool get resolve; String get skipped; int get duration;
/// Create a copy of RouteTraceStep
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RouteTraceStepCopyWith<RouteTraceStep> get copyWith => _$RouteTraceStepCopyWithImpl<RouteTraceStep>(this as RouteTraceStep, _$identity);

  /// Serializes this RouteTraceStep to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RouteTraceStep&&(identical(other.index, index) || other.index == index)&&(identical(other.type, type) || other.type == type)&&(identical(other.payload, payload) || other.payload == payload)&&(identical(other.adapter, adapter) || other.adapter == adapter)&&(identical(other.matched, matched) || other.matched == matched)&&(identical(other.resolve, resolve) || other.resolve == resolve)&&(identical(other.skipped, skipped) || other.skipped == skipped)&&(identical(other.duration, duration) || other.duration == duration));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,index,type,payload,adapter,matched,resolve,skipped,duration);

@override
String toString() {
  return 'RouteTraceStep(index: $index, type: $type, payload: $payload, adapter: $adapter, matched: $matched, resolve: $resolve, skipped: $skipped, duration: $duration)';
}


}

/// @nodoc
abstract mixin class $RouteTraceStepCopyWith<$Res>  {
  factory $RouteTraceStepCopyWith(RouteTraceStep value, $Res Function(RouteTraceStep) _then) = _$RouteTraceStepCopyWithImpl;
@useResult
$Res call({
 int index, String type, String payload, String adapter, bool matched, bool resolve, String skipped, int duration
});




}
/// @nodoc
class _$RouteTraceStepCopyWithImpl<$Res>
    implements $RouteTraceStepCopyWith<$Res> {
  _$RouteTraceStepCopyWithImpl(this._self, this._then);

  final RouteTraceStep _self;
  final $Res Function(RouteTraceStep) _then;

/// Create a copy of RouteTraceStep
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? index = null,Object? type = null,Object? payload = null,Object? adapter = null,Object? matched = null,Object? resolve = null,Object? skipped = null,Object? duration = null,}) {
  return _then(RouteTraceStep(
index: null == index ? _self.index : index // ignore: cast_nullable_to_non_nullable
as int,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,payload: null == payload ? _self.payload : payload // ignore: cast_nullable_to_non_nullable
as String,adapter: null == adapter ? _self.adapter : adapter // ignore: cast_nullable_to_non_nullable
as String,matched: null == matched ? _self.matched : matched // ignore: cast_nullable_to_non_nullable
as bool,resolve: null == resolve ? _self.resolve : resolve // ignore: cast_nullable_to_non_nullable
as bool,skipped: null == skipped ? _self.skipped : skipped // ignore: cast_nullable_to_non_nullable
as String,duration: null == duration ? _self.duration : duration // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [RouteTraceStep].
extension RouteTraceStepPatterns on RouteTraceStep {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _RouteTraceStep value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _RouteTraceStep() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _RouteTraceStep value)  $default,){
final _that = this;
switch (_that) {
case _RouteTraceStep():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _RouteTraceStep value)?  $default,){
final _that = this;
switch (_that) {
case _RouteTraceStep() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int index,  String type,  String payload,  String adapter,  bool matched,  bool resolve,  String skipped,  int duration)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _RouteTraceStep() when $default != null:
return $default(_that.index,_that.type,_that.payload,_that.adapter,_that.matched,_that.resolve,_that.skipped,_that.duration);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int index,  String type,  String payload,  String adapter,  bool matched,  bool resolve,  String skipped,  int duration)  $default,) {final _that = this;
switch (_that) {
case _RouteTraceStep():
return $default(_that.index,_that.type,_that.payload,_that.adapter,_that.matched,_that.resolve,_that.skipped,_that.duration);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int index,  String type,  String payload,  String adapter,  bool matched,  bool resolve,  String skipped,  int duration)?  $default,) {final _that = this;
switch (_that) {
case _RouteTraceStep() when $default != null:
return $default(_that.index,_that.type,_that.payload,_that.adapter,_that.matched,_that.resolve,_that.skipped,_that.duration);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _RouteTraceStep implements RouteTraceStep {
  const _RouteTraceStep({this.index = 0, this.type = '', this.payload = '', this.adapter = '', this.matched = false, this.resolve = false, this.skipped = '', this.duration = 0});
  factory _RouteTraceStep.fromJson(Map<String, dynamic> json) => _$RouteTraceStepFromJson(json);

@override@JsonKey() final  int index;
@override@JsonKey() final  String type;
@override@JsonKey() final  String payload;
@override@JsonKey() final  String adapter;
@override@JsonKey() final  bool matched;
@override@JsonKey() final  bool resolve;
@override@JsonKey() final  String skipped;
@override@JsonKey() final  int duration;

/// Create a copy of RouteTraceStep
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RouteTraceStepCopyWith<_RouteTraceStep> get copyWith => __$RouteTraceStepCopyWithImpl<_RouteTraceStep>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$RouteTraceStepToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _RouteTraceStep&&(identical(other.index, index) || other.index == index)&&(identical(other.type, type) || other.type == type)&&(identical(other.payload, payload) || other.payload == payload)&&(identical(other.adapter, adapter) || other.adapter == adapter)&&(identical(other.matched, matched) || other.matched == matched)&&(identical(other.resolve, resolve) || other.resolve == resolve)&&(identical(other.skipped, skipped) || other.skipped == skipped)&&(identical(other.duration, duration) || other.duration == duration));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,index,type,payload,adapter,matched,resolve,skipped,duration);

@override
String toString() {
  return 'RouteTraceStep(index: $index, type: $type, payload: $payload, adapter: $adapter, matched: $matched, resolve: $resolve, skipped: $skipped, duration: $duration)';
}


}

/// @nodoc
abstract mixin class _$RouteTraceStepCopyWith<$Res> implements $RouteTraceStepCopyWith<$Res> {
  factory _$RouteTraceStepCopyWith(_RouteTraceStep value, $Res Function(_RouteTraceStep) _then) = __$RouteTraceStepCopyWithImpl;
@override @useResult
$Res call({
 int index, String type, String payload, String adapter, bool matched, bool resolve, String skipped, int duration
});




}
/// @nodoc
class __$RouteTraceStepCopyWithImpl<$Res>
    implements _$RouteTraceStepCopyWith<$Res> {
  __$RouteTraceStepCopyWithImpl(this._self, this._then);

  final _RouteTraceStep _self;
  final $Res Function(_RouteTraceStep) _then;

/// Create a copy of RouteTraceStep
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? index = null,Object? type = null,Object? payload = null,Object? adapter = null,Object? matched = null,Object? resolve = null,Object? skipped = null,Object? duration = null,}) {
  return _then(_RouteTraceStep(
index: null == index ? _self.index : index // ignore: cast_nullable_to_non_nullable
as int,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,payload: null == payload ? _self.payload : payload // ignore: cast_nullable_to_non_nullable
as String,adapter: null == adapter ? _self.adapter : adapter // ignore: cast_nullable_to_non_nullable
as String,matched: null == matched ? _self.matched : matched // ignore: cast_nullable_to_non_nullable
as bool,resolve: null == resolve ? _self.resolve : resolve // ignore: cast_nullable_to_non_nullable
as bool,skipped: null == skipped ? _self.skipped : skipped // ignore: cast_nullable_to_non_nullable
as String,duration: null == duration ? _self.duration : duration // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$RouteTraceChain {

 String get name; String get type;
/// Create a copy of RouteTraceChain
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RouteTraceChainCopyWith<RouteTraceChain> get copyWith => _$RouteTraceChainCopyWithImpl<RouteTraceChain>(this as RouteTraceChain, _$identity);

  /// Serializes this RouteTraceChain to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RouteTraceChain&&(identical(other.name, name) || other.name == name)&&(identical(other.type, type) || other.type == type));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,name,type);

@override
String toString() {
  return 'RouteTraceChain(name: $name, type: $type)';
}


}

/// @nodoc
abstract mixin class $RouteTraceChainCopyWith<$Res>  {
  factory $RouteTraceChainCopyWith(RouteTraceChain value, $Res Function(RouteTraceChain) _then) = _$RouteTraceChainCopyWithImpl;
@useResult
$Res call({
 String name, String type
});




}
/// @nodoc
class _$RouteTraceChainCopyWithImpl<$Res>
    implements $RouteTraceChainCopyWith<$Res> {
  _$RouteTraceChainCopyWithImpl(this._self, this._then);

  final RouteTraceChain _self;
  final $Res Function(RouteTraceChain) _then;

/// Create a copy of RouteTraceChain
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? name = null,Object? type = null,}) {
  return _then(RouteTraceChain(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [RouteTraceChain].
extension RouteTraceChainPatterns on RouteTraceChain {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _RouteTraceChain value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _RouteTraceChain() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _RouteTraceChain value)  $default,){
final _that = this;
switch (_that) {
case _RouteTraceChain():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _RouteTraceChain value)?  $default,){
final _that = this;
switch (_that) {
case _RouteTraceChain() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String name,  String type)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _RouteTraceChain() when $default != null:
return $default(_that.name,_that.type);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String name,  String type)  $default,) {final _that = this;
switch (_that) {
case _RouteTraceChain():
return $default(_that.name,_that.type);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String name,  String type)?  $default,) {final _that = this;
switch (_that) {
case _RouteTraceChain() when $default != null:
return $default(_that.name,_that.type);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _RouteTraceChain implements RouteTraceChain {
  const _RouteTraceChain({this.name = '', this.type = ''});
  factory _RouteTraceChain.fromJson(Map<String, dynamic> json) => _$RouteTraceChainFromJson(json);

@override@JsonKey() final  String name;
@override@JsonKey() final  String type;

/// Create a copy of RouteTraceChain
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RouteTraceChainCopyWith<_RouteTraceChain> get copyWith => __$RouteTraceChainCopyWithImpl<_RouteTraceChain>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$RouteTraceChainToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _RouteTraceChain&&(identical(other.name, name) || other.name == name)&&(identical(other.type, type) || other.type == type));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,name,type);

@override
String toString() {
  return 'RouteTraceChain(name: $name, type: $type)';
}


}

/// @nodoc
abstract mixin class _$RouteTraceChainCopyWith<$Res> implements $RouteTraceChainCopyWith<$Res> {
  factory _$RouteTraceChainCopyWith(_RouteTraceChain value, $Res Function(_RouteTraceChain) _then) = __$RouteTraceChainCopyWithImpl;
@override @useResult
$Res call({
 String name, String type
});




}
/// @nodoc
class __$RouteTraceChainCopyWithImpl<$Res>
    implements _$RouteTraceChainCopyWith<$Res> {
  __$RouteTraceChainCopyWithImpl(this._self, this._then);

  final _RouteTraceChain _self;
  final $Res Function(_RouteTraceChain) _then;

/// Create a copy of RouteTraceChain
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? name = null,Object? type = null,}) {
  return _then(_RouteTraceChain(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$RouteTraceResult {

 String get target; String get host; String get network; int get port; String get mode;@JsonKey(name: 'dns-mode') String get dnsMode;@JsonKey(name: 'hosts-ips') List<String> get hostsIps;@JsonKey(name: 'resolved-ips') List<String> get resolvedIps;@JsonKey(name: 'resolve-time') double get resolveTime;@JsonKey(name: 'resolve-error') String get resolveError;@JsonKey(name: 'resolved-by') int get resolvedBy;@JsonKey(name: 'dst-ip') String get dstIp; int get total; int get checked; bool get truncated; List<RouteTraceStep> get steps; RouteTraceStep? get matched; List<RouteTraceChain> get chains;@JsonKey(name: 'support-udp') bool get supportUdp;@JsonKey(name: 'match-time') double get matchTime;@JsonKey(name: 'fallback-direct') bool get fallbackDirect; String get error;
/// Create a copy of RouteTraceResult
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RouteTraceResultCopyWith<RouteTraceResult> get copyWith => _$RouteTraceResultCopyWithImpl<RouteTraceResult>(this as RouteTraceResult, _$identity);

  /// Serializes this RouteTraceResult to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RouteTraceResult&&(identical(other.target, target) || other.target == target)&&(identical(other.host, host) || other.host == host)&&(identical(other.network, network) || other.network == network)&&(identical(other.port, port) || other.port == port)&&(identical(other.mode, mode) || other.mode == mode)&&(identical(other.dnsMode, dnsMode) || other.dnsMode == dnsMode)&&const DeepCollectionEquality().equals(other.hostsIps, hostsIps)&&const DeepCollectionEquality().equals(other.resolvedIps, resolvedIps)&&(identical(other.resolveTime, resolveTime) || other.resolveTime == resolveTime)&&(identical(other.resolveError, resolveError) || other.resolveError == resolveError)&&(identical(other.resolvedBy, resolvedBy) || other.resolvedBy == resolvedBy)&&(identical(other.dstIp, dstIp) || other.dstIp == dstIp)&&(identical(other.total, total) || other.total == total)&&(identical(other.checked, checked) || other.checked == checked)&&(identical(other.truncated, truncated) || other.truncated == truncated)&&const DeepCollectionEquality().equals(other.steps, steps)&&(identical(other.matched, matched) || other.matched == matched)&&const DeepCollectionEquality().equals(other.chains, chains)&&(identical(other.supportUdp, supportUdp) || other.supportUdp == supportUdp)&&(identical(other.matchTime, matchTime) || other.matchTime == matchTime)&&(identical(other.fallbackDirect, fallbackDirect) || other.fallbackDirect == fallbackDirect)&&(identical(other.error, error) || other.error == error));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,target,host,network,port,mode,dnsMode,const DeepCollectionEquality().hash(hostsIps),const DeepCollectionEquality().hash(resolvedIps),resolveTime,resolveError,resolvedBy,dstIp,total,checked,truncated,const DeepCollectionEquality().hash(steps),matched,const DeepCollectionEquality().hash(chains),supportUdp,matchTime,fallbackDirect,error]);

@override
String toString() {
  return 'RouteTraceResult(target: $target, host: $host, network: $network, port: $port, mode: $mode, dnsMode: $dnsMode, hostsIps: $hostsIps, resolvedIps: $resolvedIps, resolveTime: $resolveTime, resolveError: $resolveError, resolvedBy: $resolvedBy, dstIp: $dstIp, total: $total, checked: $checked, truncated: $truncated, steps: $steps, matched: $matched, chains: $chains, supportUdp: $supportUdp, matchTime: $matchTime, fallbackDirect: $fallbackDirect, error: $error)';
}


}

/// @nodoc
abstract mixin class $RouteTraceResultCopyWith<$Res>  {
  factory $RouteTraceResultCopyWith(RouteTraceResult value, $Res Function(RouteTraceResult) _then) = _$RouteTraceResultCopyWithImpl;
@useResult
$Res call({
 String target, String host, String network, int port, String mode,@JsonKey(name: 'dns-mode') String dnsMode,@JsonKey(name: 'hosts-ips') List<String> hostsIps,@JsonKey(name: 'resolved-ips') List<String> resolvedIps,@JsonKey(name: 'resolve-time') double resolveTime,@JsonKey(name: 'resolve-error') String resolveError,@JsonKey(name: 'resolved-by') int resolvedBy,@JsonKey(name: 'dst-ip') String dstIp, int total, int checked, bool truncated, List<RouteTraceStep> steps, RouteTraceStep? matched, List<RouteTraceChain> chains,@JsonKey(name: 'support-udp') bool supportUdp,@JsonKey(name: 'match-time') double matchTime,@JsonKey(name: 'fallback-direct') bool fallbackDirect, String error
});


$RouteTraceStepCopyWith<$Res>? get matched;

}
/// @nodoc
class _$RouteTraceResultCopyWithImpl<$Res>
    implements $RouteTraceResultCopyWith<$Res> {
  _$RouteTraceResultCopyWithImpl(this._self, this._then);

  final RouteTraceResult _self;
  final $Res Function(RouteTraceResult) _then;

/// Create a copy of RouteTraceResult
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? target = null,Object? host = null,Object? network = null,Object? port = null,Object? mode = null,Object? dnsMode = null,Object? hostsIps = null,Object? resolvedIps = null,Object? resolveTime = null,Object? resolveError = null,Object? resolvedBy = null,Object? dstIp = null,Object? total = null,Object? checked = null,Object? truncated = null,Object? steps = null,Object? matched = freezed,Object? chains = null,Object? supportUdp = null,Object? matchTime = null,Object? fallbackDirect = null,Object? error = null,}) {
  return _then(RouteTraceResult(
target: null == target ? _self.target : target // ignore: cast_nullable_to_non_nullable
as String,host: null == host ? _self.host : host // ignore: cast_nullable_to_non_nullable
as String,network: null == network ? _self.network : network // ignore: cast_nullable_to_non_nullable
as String,port: null == port ? _self.port : port // ignore: cast_nullable_to_non_nullable
as int,mode: null == mode ? _self.mode : mode // ignore: cast_nullable_to_non_nullable
as String,dnsMode: null == dnsMode ? _self.dnsMode : dnsMode // ignore: cast_nullable_to_non_nullable
as String,hostsIps: null == hostsIps ? _self.hostsIps : hostsIps // ignore: cast_nullable_to_non_nullable
as List<String>,resolvedIps: null == resolvedIps ? _self.resolvedIps : resolvedIps // ignore: cast_nullable_to_non_nullable
as List<String>,resolveTime: null == resolveTime ? _self.resolveTime : resolveTime // ignore: cast_nullable_to_non_nullable
as double,resolveError: null == resolveError ? _self.resolveError : resolveError // ignore: cast_nullable_to_non_nullable
as String,resolvedBy: null == resolvedBy ? _self.resolvedBy : resolvedBy // ignore: cast_nullable_to_non_nullable
as int,dstIp: null == dstIp ? _self.dstIp : dstIp // ignore: cast_nullable_to_non_nullable
as String,total: null == total ? _self.total : total // ignore: cast_nullable_to_non_nullable
as int,checked: null == checked ? _self.checked : checked // ignore: cast_nullable_to_non_nullable
as int,truncated: null == truncated ? _self.truncated : truncated // ignore: cast_nullable_to_non_nullable
as bool,steps: null == steps ? _self.steps : steps // ignore: cast_nullable_to_non_nullable
as List<RouteTraceStep>,matched: freezed == matched ? _self.matched : matched // ignore: cast_nullable_to_non_nullable
as RouteTraceStep?,chains: null == chains ? _self.chains : chains // ignore: cast_nullable_to_non_nullable
as List<RouteTraceChain>,supportUdp: null == supportUdp ? _self.supportUdp : supportUdp // ignore: cast_nullable_to_non_nullable
as bool,matchTime: null == matchTime ? _self.matchTime : matchTime // ignore: cast_nullable_to_non_nullable
as double,fallbackDirect: null == fallbackDirect ? _self.fallbackDirect : fallbackDirect // ignore: cast_nullable_to_non_nullable
as bool,error: null == error ? _self.error : error // ignore: cast_nullable_to_non_nullable
as String,
  ));
}
/// Create a copy of RouteTraceResult
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$RouteTraceStepCopyWith<$Res>? get matched {
    if (_self.matched == null) {
    return null;
  }

  return $RouteTraceStepCopyWith<$Res>(_self.matched!, (value) {
    return _then(_self.copyWith(matched: value));
  });
}
}


/// Adds pattern-matching-related methods to [RouteTraceResult].
extension RouteTraceResultPatterns on RouteTraceResult {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _RouteTraceResult value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _RouteTraceResult() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _RouteTraceResult value)  $default,){
final _that = this;
switch (_that) {
case _RouteTraceResult():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _RouteTraceResult value)?  $default,){
final _that = this;
switch (_that) {
case _RouteTraceResult() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String target,  String host,  String network,  int port,  String mode, @JsonKey(name: 'dns-mode')  String dnsMode, @JsonKey(name: 'hosts-ips')  List<String> hostsIps, @JsonKey(name: 'resolved-ips')  List<String> resolvedIps, @JsonKey(name: 'resolve-time')  double resolveTime, @JsonKey(name: 'resolve-error')  String resolveError, @JsonKey(name: 'resolved-by')  int resolvedBy, @JsonKey(name: 'dst-ip')  String dstIp,  int total,  int checked,  bool truncated,  List<RouteTraceStep> steps,  RouteTraceStep? matched,  List<RouteTraceChain> chains, @JsonKey(name: 'support-udp')  bool supportUdp, @JsonKey(name: 'match-time')  double matchTime, @JsonKey(name: 'fallback-direct')  bool fallbackDirect,  String error)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _RouteTraceResult() when $default != null:
return $default(_that.target,_that.host,_that.network,_that.port,_that.mode,_that.dnsMode,_that.hostsIps,_that.resolvedIps,_that.resolveTime,_that.resolveError,_that.resolvedBy,_that.dstIp,_that.total,_that.checked,_that.truncated,_that.steps,_that.matched,_that.chains,_that.supportUdp,_that.matchTime,_that.fallbackDirect,_that.error);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String target,  String host,  String network,  int port,  String mode, @JsonKey(name: 'dns-mode')  String dnsMode, @JsonKey(name: 'hosts-ips')  List<String> hostsIps, @JsonKey(name: 'resolved-ips')  List<String> resolvedIps, @JsonKey(name: 'resolve-time')  double resolveTime, @JsonKey(name: 'resolve-error')  String resolveError, @JsonKey(name: 'resolved-by')  int resolvedBy, @JsonKey(name: 'dst-ip')  String dstIp,  int total,  int checked,  bool truncated,  List<RouteTraceStep> steps,  RouteTraceStep? matched,  List<RouteTraceChain> chains, @JsonKey(name: 'support-udp')  bool supportUdp, @JsonKey(name: 'match-time')  double matchTime, @JsonKey(name: 'fallback-direct')  bool fallbackDirect,  String error)  $default,) {final _that = this;
switch (_that) {
case _RouteTraceResult():
return $default(_that.target,_that.host,_that.network,_that.port,_that.mode,_that.dnsMode,_that.hostsIps,_that.resolvedIps,_that.resolveTime,_that.resolveError,_that.resolvedBy,_that.dstIp,_that.total,_that.checked,_that.truncated,_that.steps,_that.matched,_that.chains,_that.supportUdp,_that.matchTime,_that.fallbackDirect,_that.error);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String target,  String host,  String network,  int port,  String mode, @JsonKey(name: 'dns-mode')  String dnsMode, @JsonKey(name: 'hosts-ips')  List<String> hostsIps, @JsonKey(name: 'resolved-ips')  List<String> resolvedIps, @JsonKey(name: 'resolve-time')  double resolveTime, @JsonKey(name: 'resolve-error')  String resolveError, @JsonKey(name: 'resolved-by')  int resolvedBy, @JsonKey(name: 'dst-ip')  String dstIp,  int total,  int checked,  bool truncated,  List<RouteTraceStep> steps,  RouteTraceStep? matched,  List<RouteTraceChain> chains, @JsonKey(name: 'support-udp')  bool supportUdp, @JsonKey(name: 'match-time')  double matchTime, @JsonKey(name: 'fallback-direct')  bool fallbackDirect,  String error)?  $default,) {final _that = this;
switch (_that) {
case _RouteTraceResult() when $default != null:
return $default(_that.target,_that.host,_that.network,_that.port,_that.mode,_that.dnsMode,_that.hostsIps,_that.resolvedIps,_that.resolveTime,_that.resolveError,_that.resolvedBy,_that.dstIp,_that.total,_that.checked,_that.truncated,_that.steps,_that.matched,_that.chains,_that.supportUdp,_that.matchTime,_that.fallbackDirect,_that.error);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _RouteTraceResult implements RouteTraceResult {
  const _RouteTraceResult({this.target = '', this.host = '', this.network = 'tcp', this.port = 443, this.mode = '', @JsonKey(name: 'dns-mode') this.dnsMode = '', @JsonKey(name: 'hosts-ips')  List<String> hostsIps = const [], @JsonKey(name: 'resolved-ips')  List<String> resolvedIps = const [], @JsonKey(name: 'resolve-time') this.resolveTime = 0, @JsonKey(name: 'resolve-error') this.resolveError = '', @JsonKey(name: 'resolved-by') this.resolvedBy = -1, @JsonKey(name: 'dst-ip') this.dstIp = '', this.total = 0, this.checked = 0, this.truncated = false,  List<RouteTraceStep> steps = const [], this.matched,  List<RouteTraceChain> chains = const [], @JsonKey(name: 'support-udp') this.supportUdp = false, @JsonKey(name: 'match-time') this.matchTime = 0, @JsonKey(name: 'fallback-direct') this.fallbackDirect = false, this.error = ''}): _hostsIps = hostsIps,_resolvedIps = resolvedIps,_steps = steps,_chains = chains;
  factory _RouteTraceResult.fromJson(Map<String, dynamic> json) => _$RouteTraceResultFromJson(json);

@override@JsonKey() final  String target;
@override@JsonKey() final  String host;
@override@JsonKey() final  String network;
@override@JsonKey() final  int port;
@override@JsonKey() final  String mode;
@override@JsonKey(name: 'dns-mode') final  String dnsMode;
 final  List<String> _hostsIps;
@override@JsonKey(name: 'hosts-ips') List<String> get hostsIps {
  if (_hostsIps is EqualUnmodifiableListView) return _hostsIps;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_hostsIps);
}

 final  List<String> _resolvedIps;
@override@JsonKey(name: 'resolved-ips') List<String> get resolvedIps {
  if (_resolvedIps is EqualUnmodifiableListView) return _resolvedIps;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_resolvedIps);
}

@override@JsonKey(name: 'resolve-time') final  double resolveTime;
@override@JsonKey(name: 'resolve-error') final  String resolveError;
@override@JsonKey(name: 'resolved-by') final  int resolvedBy;
@override@JsonKey(name: 'dst-ip') final  String dstIp;
@override@JsonKey() final  int total;
@override@JsonKey() final  int checked;
@override@JsonKey() final  bool truncated;
 final  List<RouteTraceStep> _steps;
@override@JsonKey() List<RouteTraceStep> get steps {
  if (_steps is EqualUnmodifiableListView) return _steps;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_steps);
}

@override final  RouteTraceStep? matched;
 final  List<RouteTraceChain> _chains;
@override@JsonKey() List<RouteTraceChain> get chains {
  if (_chains is EqualUnmodifiableListView) return _chains;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_chains);
}

@override@JsonKey(name: 'support-udp') final  bool supportUdp;
@override@JsonKey(name: 'match-time') final  double matchTime;
@override@JsonKey(name: 'fallback-direct') final  bool fallbackDirect;
@override@JsonKey() final  String error;

/// Create a copy of RouteTraceResult
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RouteTraceResultCopyWith<_RouteTraceResult> get copyWith => __$RouteTraceResultCopyWithImpl<_RouteTraceResult>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$RouteTraceResultToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _RouteTraceResult&&(identical(other.target, target) || other.target == target)&&(identical(other.host, host) || other.host == host)&&(identical(other.network, network) || other.network == network)&&(identical(other.port, port) || other.port == port)&&(identical(other.mode, mode) || other.mode == mode)&&(identical(other.dnsMode, dnsMode) || other.dnsMode == dnsMode)&&const DeepCollectionEquality().equals(other._hostsIps, _hostsIps)&&const DeepCollectionEquality().equals(other._resolvedIps, _resolvedIps)&&(identical(other.resolveTime, resolveTime) || other.resolveTime == resolveTime)&&(identical(other.resolveError, resolveError) || other.resolveError == resolveError)&&(identical(other.resolvedBy, resolvedBy) || other.resolvedBy == resolvedBy)&&(identical(other.dstIp, dstIp) || other.dstIp == dstIp)&&(identical(other.total, total) || other.total == total)&&(identical(other.checked, checked) || other.checked == checked)&&(identical(other.truncated, truncated) || other.truncated == truncated)&&const DeepCollectionEquality().equals(other._steps, _steps)&&(identical(other.matched, matched) || other.matched == matched)&&const DeepCollectionEquality().equals(other._chains, _chains)&&(identical(other.supportUdp, supportUdp) || other.supportUdp == supportUdp)&&(identical(other.matchTime, matchTime) || other.matchTime == matchTime)&&(identical(other.fallbackDirect, fallbackDirect) || other.fallbackDirect == fallbackDirect)&&(identical(other.error, error) || other.error == error));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,target,host,network,port,mode,dnsMode,const DeepCollectionEquality().hash(_hostsIps),const DeepCollectionEquality().hash(_resolvedIps),resolveTime,resolveError,resolvedBy,dstIp,total,checked,truncated,const DeepCollectionEquality().hash(_steps),matched,const DeepCollectionEquality().hash(_chains),supportUdp,matchTime,fallbackDirect,error]);

@override
String toString() {
  return 'RouteTraceResult(target: $target, host: $host, network: $network, port: $port, mode: $mode, dnsMode: $dnsMode, hostsIps: $hostsIps, resolvedIps: $resolvedIps, resolveTime: $resolveTime, resolveError: $resolveError, resolvedBy: $resolvedBy, dstIp: $dstIp, total: $total, checked: $checked, truncated: $truncated, steps: $steps, matched: $matched, chains: $chains, supportUdp: $supportUdp, matchTime: $matchTime, fallbackDirect: $fallbackDirect, error: $error)';
}


}

/// @nodoc
abstract mixin class _$RouteTraceResultCopyWith<$Res> implements $RouteTraceResultCopyWith<$Res> {
  factory _$RouteTraceResultCopyWith(_RouteTraceResult value, $Res Function(_RouteTraceResult) _then) = __$RouteTraceResultCopyWithImpl;
@override @useResult
$Res call({
 String target, String host, String network, int port, String mode,@JsonKey(name: 'dns-mode') String dnsMode,@JsonKey(name: 'hosts-ips') List<String> hostsIps,@JsonKey(name: 'resolved-ips') List<String> resolvedIps,@JsonKey(name: 'resolve-time') double resolveTime,@JsonKey(name: 'resolve-error') String resolveError,@JsonKey(name: 'resolved-by') int resolvedBy,@JsonKey(name: 'dst-ip') String dstIp, int total, int checked, bool truncated, List<RouteTraceStep> steps, RouteTraceStep? matched, List<RouteTraceChain> chains,@JsonKey(name: 'support-udp') bool supportUdp,@JsonKey(name: 'match-time') double matchTime,@JsonKey(name: 'fallback-direct') bool fallbackDirect, String error
});


@override $RouteTraceStepCopyWith<$Res>? get matched;

}
/// @nodoc
class __$RouteTraceResultCopyWithImpl<$Res>
    implements _$RouteTraceResultCopyWith<$Res> {
  __$RouteTraceResultCopyWithImpl(this._self, this._then);

  final _RouteTraceResult _self;
  final $Res Function(_RouteTraceResult) _then;

/// Create a copy of RouteTraceResult
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? target = null,Object? host = null,Object? network = null,Object? port = null,Object? mode = null,Object? dnsMode = null,Object? hostsIps = null,Object? resolvedIps = null,Object? resolveTime = null,Object? resolveError = null,Object? resolvedBy = null,Object? dstIp = null,Object? total = null,Object? checked = null,Object? truncated = null,Object? steps = null,Object? matched = freezed,Object? chains = null,Object? supportUdp = null,Object? matchTime = null,Object? fallbackDirect = null,Object? error = null,}) {
  return _then(_RouteTraceResult(
target: null == target ? _self.target : target // ignore: cast_nullable_to_non_nullable
as String,host: null == host ? _self.host : host // ignore: cast_nullable_to_non_nullable
as String,network: null == network ? _self.network : network // ignore: cast_nullable_to_non_nullable
as String,port: null == port ? _self.port : port // ignore: cast_nullable_to_non_nullable
as int,mode: null == mode ? _self.mode : mode // ignore: cast_nullable_to_non_nullable
as String,dnsMode: null == dnsMode ? _self.dnsMode : dnsMode // ignore: cast_nullable_to_non_nullable
as String,hostsIps: null == hostsIps ? _self._hostsIps : hostsIps // ignore: cast_nullable_to_non_nullable
as List<String>,resolvedIps: null == resolvedIps ? _self._resolvedIps : resolvedIps // ignore: cast_nullable_to_non_nullable
as List<String>,resolveTime: null == resolveTime ? _self.resolveTime : resolveTime // ignore: cast_nullable_to_non_nullable
as double,resolveError: null == resolveError ? _self.resolveError : resolveError // ignore: cast_nullable_to_non_nullable
as String,resolvedBy: null == resolvedBy ? _self.resolvedBy : resolvedBy // ignore: cast_nullable_to_non_nullable
as int,dstIp: null == dstIp ? _self.dstIp : dstIp // ignore: cast_nullable_to_non_nullable
as String,total: null == total ? _self.total : total // ignore: cast_nullable_to_non_nullable
as int,checked: null == checked ? _self.checked : checked // ignore: cast_nullable_to_non_nullable
as int,truncated: null == truncated ? _self.truncated : truncated // ignore: cast_nullable_to_non_nullable
as bool,steps: null == steps ? _self._steps : steps // ignore: cast_nullable_to_non_nullable
as List<RouteTraceStep>,matched: freezed == matched ? _self.matched : matched // ignore: cast_nullable_to_non_nullable
as RouteTraceStep?,chains: null == chains ? _self._chains : chains // ignore: cast_nullable_to_non_nullable
as List<RouteTraceChain>,supportUdp: null == supportUdp ? _self.supportUdp : supportUdp // ignore: cast_nullable_to_non_nullable
as bool,matchTime: null == matchTime ? _self.matchTime : matchTime // ignore: cast_nullable_to_non_nullable
as double,fallbackDirect: null == fallbackDirect ? _self.fallbackDirect : fallbackDirect // ignore: cast_nullable_to_non_nullable
as bool,error: null == error ? _self.error : error // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

/// Create a copy of RouteTraceResult
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$RouteTraceStepCopyWith<$Res>? get matched {
    if (_self.matched == null) {
    return null;
  }

  return $RouteTraceStepCopyWith<$Res>(_self.matched!, (value) {
    return _then(_self.copyWith(matched: value));
  });
}
}


/// @nodoc
mixin _$DnsQueryRecord {

 String get name; String get type; int get ttl; String get data;
/// Create a copy of DnsQueryRecord
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DnsQueryRecordCopyWith<DnsQueryRecord> get copyWith => _$DnsQueryRecordCopyWithImpl<DnsQueryRecord>(this as DnsQueryRecord, _$identity);

  /// Serializes this DnsQueryRecord to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DnsQueryRecord&&(identical(other.name, name) || other.name == name)&&(identical(other.type, type) || other.type == type)&&(identical(other.ttl, ttl) || other.ttl == ttl)&&(identical(other.data, data) || other.data == data));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,name,type,ttl,data);

@override
String toString() {
  return 'DnsQueryRecord(name: $name, type: $type, ttl: $ttl, data: $data)';
}


}

/// @nodoc
abstract mixin class $DnsQueryRecordCopyWith<$Res>  {
  factory $DnsQueryRecordCopyWith(DnsQueryRecord value, $Res Function(DnsQueryRecord) _then) = _$DnsQueryRecordCopyWithImpl;
@useResult
$Res call({
 String name, String type, int ttl, String data
});




}
/// @nodoc
class _$DnsQueryRecordCopyWithImpl<$Res>
    implements $DnsQueryRecordCopyWith<$Res> {
  _$DnsQueryRecordCopyWithImpl(this._self, this._then);

  final DnsQueryRecord _self;
  final $Res Function(DnsQueryRecord) _then;

/// Create a copy of DnsQueryRecord
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? name = null,Object? type = null,Object? ttl = null,Object? data = null,}) {
  return _then(DnsQueryRecord(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,ttl: null == ttl ? _self.ttl : ttl // ignore: cast_nullable_to_non_nullable
as int,data: null == data ? _self.data : data // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [DnsQueryRecord].
extension DnsQueryRecordPatterns on DnsQueryRecord {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DnsQueryRecord value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DnsQueryRecord() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DnsQueryRecord value)  $default,){
final _that = this;
switch (_that) {
case _DnsQueryRecord():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DnsQueryRecord value)?  $default,){
final _that = this;
switch (_that) {
case _DnsQueryRecord() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String name,  String type,  int ttl,  String data)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DnsQueryRecord() when $default != null:
return $default(_that.name,_that.type,_that.ttl,_that.data);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String name,  String type,  int ttl,  String data)  $default,) {final _that = this;
switch (_that) {
case _DnsQueryRecord():
return $default(_that.name,_that.type,_that.ttl,_that.data);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String name,  String type,  int ttl,  String data)?  $default,) {final _that = this;
switch (_that) {
case _DnsQueryRecord() when $default != null:
return $default(_that.name,_that.type,_that.ttl,_that.data);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _DnsQueryRecord implements DnsQueryRecord {
  const _DnsQueryRecord({this.name = '', this.type = '', this.ttl = 0, this.data = ''});
  factory _DnsQueryRecord.fromJson(Map<String, dynamic> json) => _$DnsQueryRecordFromJson(json);

@override@JsonKey() final  String name;
@override@JsonKey() final  String type;
@override@JsonKey() final  int ttl;
@override@JsonKey() final  String data;

/// Create a copy of DnsQueryRecord
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DnsQueryRecordCopyWith<_DnsQueryRecord> get copyWith => __$DnsQueryRecordCopyWithImpl<_DnsQueryRecord>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$DnsQueryRecordToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DnsQueryRecord&&(identical(other.name, name) || other.name == name)&&(identical(other.type, type) || other.type == type)&&(identical(other.ttl, ttl) || other.ttl == ttl)&&(identical(other.data, data) || other.data == data));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,name,type,ttl,data);

@override
String toString() {
  return 'DnsQueryRecord(name: $name, type: $type, ttl: $ttl, data: $data)';
}


}

/// @nodoc
abstract mixin class _$DnsQueryRecordCopyWith<$Res> implements $DnsQueryRecordCopyWith<$Res> {
  factory _$DnsQueryRecordCopyWith(_DnsQueryRecord value, $Res Function(_DnsQueryRecord) _then) = __$DnsQueryRecordCopyWithImpl;
@override @useResult
$Res call({
 String name, String type, int ttl, String data
});




}
/// @nodoc
class __$DnsQueryRecordCopyWithImpl<$Res>
    implements _$DnsQueryRecordCopyWith<$Res> {
  __$DnsQueryRecordCopyWithImpl(this._self, this._then);

  final _DnsQueryRecord _self;
  final $Res Function(_DnsQueryRecord) _then;

/// Create a copy of DnsQueryRecord
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? name = null,Object? type = null,Object? ttl = null,Object? data = null,}) {
  return _then(_DnsQueryRecord(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,ttl: null == ttl ? _self.ttl : ttl // ignore: cast_nullable_to_non_nullable
as int,data: null == data ? _self.data : data // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$DnsQueryResult {

 String get domain; String get type; String get mode; String get server; String get rcode; List<DnsQueryRecord> get answers; double get elapsed; String get route; List<String> get hosts;@JsonKey(name: 'fake-ip-range') String get fakeIpRange;@JsonKey(name: 'filter-mode') String get filterMode; String get outbound;@JsonKey(name: 'outbound-type') String get outboundType; String get error;
/// Create a copy of DnsQueryResult
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DnsQueryResultCopyWith<DnsQueryResult> get copyWith => _$DnsQueryResultCopyWithImpl<DnsQueryResult>(this as DnsQueryResult, _$identity);

  /// Serializes this DnsQueryResult to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DnsQueryResult&&(identical(other.domain, domain) || other.domain == domain)&&(identical(other.type, type) || other.type == type)&&(identical(other.mode, mode) || other.mode == mode)&&(identical(other.server, server) || other.server == server)&&(identical(other.rcode, rcode) || other.rcode == rcode)&&const DeepCollectionEquality().equals(other.answers, answers)&&(identical(other.elapsed, elapsed) || other.elapsed == elapsed)&&(identical(other.route, route) || other.route == route)&&const DeepCollectionEquality().equals(other.hosts, hosts)&&(identical(other.fakeIpRange, fakeIpRange) || other.fakeIpRange == fakeIpRange)&&(identical(other.filterMode, filterMode) || other.filterMode == filterMode)&&(identical(other.outbound, outbound) || other.outbound == outbound)&&(identical(other.outboundType, outboundType) || other.outboundType == outboundType)&&(identical(other.error, error) || other.error == error));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,domain,type,mode,server,rcode,const DeepCollectionEquality().hash(answers),elapsed,route,const DeepCollectionEquality().hash(hosts),fakeIpRange,filterMode,outbound,outboundType,error);

@override
String toString() {
  return 'DnsQueryResult(domain: $domain, type: $type, mode: $mode, server: $server, rcode: $rcode, answers: $answers, elapsed: $elapsed, route: $route, hosts: $hosts, fakeIpRange: $fakeIpRange, filterMode: $filterMode, outbound: $outbound, outboundType: $outboundType, error: $error)';
}


}

/// @nodoc
abstract mixin class $DnsQueryResultCopyWith<$Res>  {
  factory $DnsQueryResultCopyWith(DnsQueryResult value, $Res Function(DnsQueryResult) _then) = _$DnsQueryResultCopyWithImpl;
@useResult
$Res call({
 String domain, String type, String mode, String server, String rcode, List<DnsQueryRecord> answers, double elapsed, String route, List<String> hosts,@JsonKey(name: 'fake-ip-range') String fakeIpRange,@JsonKey(name: 'filter-mode') String filterMode, String outbound,@JsonKey(name: 'outbound-type') String outboundType, String error
});




}
/// @nodoc
class _$DnsQueryResultCopyWithImpl<$Res>
    implements $DnsQueryResultCopyWith<$Res> {
  _$DnsQueryResultCopyWithImpl(this._self, this._then);

  final DnsQueryResult _self;
  final $Res Function(DnsQueryResult) _then;

/// Create a copy of DnsQueryResult
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? domain = null,Object? type = null,Object? mode = null,Object? server = null,Object? rcode = null,Object? answers = null,Object? elapsed = null,Object? route = null,Object? hosts = null,Object? fakeIpRange = null,Object? filterMode = null,Object? outbound = null,Object? outboundType = null,Object? error = null,}) {
  return _then(DnsQueryResult(
domain: null == domain ? _self.domain : domain // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,mode: null == mode ? _self.mode : mode // ignore: cast_nullable_to_non_nullable
as String,server: null == server ? _self.server : server // ignore: cast_nullable_to_non_nullable
as String,rcode: null == rcode ? _self.rcode : rcode // ignore: cast_nullable_to_non_nullable
as String,answers: null == answers ? _self.answers : answers // ignore: cast_nullable_to_non_nullable
as List<DnsQueryRecord>,elapsed: null == elapsed ? _self.elapsed : elapsed // ignore: cast_nullable_to_non_nullable
as double,route: null == route ? _self.route : route // ignore: cast_nullable_to_non_nullable
as String,hosts: null == hosts ? _self.hosts : hosts // ignore: cast_nullable_to_non_nullable
as List<String>,fakeIpRange: null == fakeIpRange ? _self.fakeIpRange : fakeIpRange // ignore: cast_nullable_to_non_nullable
as String,filterMode: null == filterMode ? _self.filterMode : filterMode // ignore: cast_nullable_to_non_nullable
as String,outbound: null == outbound ? _self.outbound : outbound // ignore: cast_nullable_to_non_nullable
as String,outboundType: null == outboundType ? _self.outboundType : outboundType // ignore: cast_nullable_to_non_nullable
as String,error: null == error ? _self.error : error // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [DnsQueryResult].
extension DnsQueryResultPatterns on DnsQueryResult {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DnsQueryResult value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DnsQueryResult() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DnsQueryResult value)  $default,){
final _that = this;
switch (_that) {
case _DnsQueryResult():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DnsQueryResult value)?  $default,){
final _that = this;
switch (_that) {
case _DnsQueryResult() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String domain,  String type,  String mode,  String server,  String rcode,  List<DnsQueryRecord> answers,  double elapsed,  String route,  List<String> hosts, @JsonKey(name: 'fake-ip-range')  String fakeIpRange, @JsonKey(name: 'filter-mode')  String filterMode,  String outbound, @JsonKey(name: 'outbound-type')  String outboundType,  String error)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DnsQueryResult() when $default != null:
return $default(_that.domain,_that.type,_that.mode,_that.server,_that.rcode,_that.answers,_that.elapsed,_that.route,_that.hosts,_that.fakeIpRange,_that.filterMode,_that.outbound,_that.outboundType,_that.error);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String domain,  String type,  String mode,  String server,  String rcode,  List<DnsQueryRecord> answers,  double elapsed,  String route,  List<String> hosts, @JsonKey(name: 'fake-ip-range')  String fakeIpRange, @JsonKey(name: 'filter-mode')  String filterMode,  String outbound, @JsonKey(name: 'outbound-type')  String outboundType,  String error)  $default,) {final _that = this;
switch (_that) {
case _DnsQueryResult():
return $default(_that.domain,_that.type,_that.mode,_that.server,_that.rcode,_that.answers,_that.elapsed,_that.route,_that.hosts,_that.fakeIpRange,_that.filterMode,_that.outbound,_that.outboundType,_that.error);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String domain,  String type,  String mode,  String server,  String rcode,  List<DnsQueryRecord> answers,  double elapsed,  String route,  List<String> hosts, @JsonKey(name: 'fake-ip-range')  String fakeIpRange, @JsonKey(name: 'filter-mode')  String filterMode,  String outbound, @JsonKey(name: 'outbound-type')  String outboundType,  String error)?  $default,) {final _that = this;
switch (_that) {
case _DnsQueryResult() when $default != null:
return $default(_that.domain,_that.type,_that.mode,_that.server,_that.rcode,_that.answers,_that.elapsed,_that.route,_that.hosts,_that.fakeIpRange,_that.filterMode,_that.outbound,_that.outboundType,_that.error);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _DnsQueryResult implements DnsQueryResult {
  const _DnsQueryResult({this.domain = '', this.type = 'A', this.mode = '', this.server = '', this.rcode = '',  List<DnsQueryRecord> answers = const [], this.elapsed = 0, this.route = '',  List<String> hosts = const [], @JsonKey(name: 'fake-ip-range') this.fakeIpRange = '', @JsonKey(name: 'filter-mode') this.filterMode = '', this.outbound = '', @JsonKey(name: 'outbound-type') this.outboundType = '', this.error = ''}): _answers = answers,_hosts = hosts;
  factory _DnsQueryResult.fromJson(Map<String, dynamic> json) => _$DnsQueryResultFromJson(json);

@override@JsonKey() final  String domain;
@override@JsonKey() final  String type;
@override@JsonKey() final  String mode;
@override@JsonKey() final  String server;
@override@JsonKey() final  String rcode;
 final  List<DnsQueryRecord> _answers;
@override@JsonKey() List<DnsQueryRecord> get answers {
  if (_answers is EqualUnmodifiableListView) return _answers;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_answers);
}

@override@JsonKey() final  double elapsed;
@override@JsonKey() final  String route;
 final  List<String> _hosts;
@override@JsonKey() List<String> get hosts {
  if (_hosts is EqualUnmodifiableListView) return _hosts;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_hosts);
}

@override@JsonKey(name: 'fake-ip-range') final  String fakeIpRange;
@override@JsonKey(name: 'filter-mode') final  String filterMode;
@override@JsonKey() final  String outbound;
@override@JsonKey(name: 'outbound-type') final  String outboundType;
@override@JsonKey() final  String error;

/// Create a copy of DnsQueryResult
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DnsQueryResultCopyWith<_DnsQueryResult> get copyWith => __$DnsQueryResultCopyWithImpl<_DnsQueryResult>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$DnsQueryResultToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DnsQueryResult&&(identical(other.domain, domain) || other.domain == domain)&&(identical(other.type, type) || other.type == type)&&(identical(other.mode, mode) || other.mode == mode)&&(identical(other.server, server) || other.server == server)&&(identical(other.rcode, rcode) || other.rcode == rcode)&&const DeepCollectionEquality().equals(other._answers, _answers)&&(identical(other.elapsed, elapsed) || other.elapsed == elapsed)&&(identical(other.route, route) || other.route == route)&&const DeepCollectionEquality().equals(other._hosts, _hosts)&&(identical(other.fakeIpRange, fakeIpRange) || other.fakeIpRange == fakeIpRange)&&(identical(other.filterMode, filterMode) || other.filterMode == filterMode)&&(identical(other.outbound, outbound) || other.outbound == outbound)&&(identical(other.outboundType, outboundType) || other.outboundType == outboundType)&&(identical(other.error, error) || other.error == error));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,domain,type,mode,server,rcode,const DeepCollectionEquality().hash(_answers),elapsed,route,const DeepCollectionEquality().hash(_hosts),fakeIpRange,filterMode,outbound,outboundType,error);

@override
String toString() {
  return 'DnsQueryResult(domain: $domain, type: $type, mode: $mode, server: $server, rcode: $rcode, answers: $answers, elapsed: $elapsed, route: $route, hosts: $hosts, fakeIpRange: $fakeIpRange, filterMode: $filterMode, outbound: $outbound, outboundType: $outboundType, error: $error)';
}


}

/// @nodoc
abstract mixin class _$DnsQueryResultCopyWith<$Res> implements $DnsQueryResultCopyWith<$Res> {
  factory _$DnsQueryResultCopyWith(_DnsQueryResult value, $Res Function(_DnsQueryResult) _then) = __$DnsQueryResultCopyWithImpl;
@override @useResult
$Res call({
 String domain, String type, String mode, String server, String rcode, List<DnsQueryRecord> answers, double elapsed, String route, List<String> hosts,@JsonKey(name: 'fake-ip-range') String fakeIpRange,@JsonKey(name: 'filter-mode') String filterMode, String outbound,@JsonKey(name: 'outbound-type') String outboundType, String error
});




}
/// @nodoc
class __$DnsQueryResultCopyWithImpl<$Res>
    implements _$DnsQueryResultCopyWith<$Res> {
  __$DnsQueryResultCopyWithImpl(this._self, this._then);

  final _DnsQueryResult _self;
  final $Res Function(_DnsQueryResult) _then;

/// Create a copy of DnsQueryResult
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? domain = null,Object? type = null,Object? mode = null,Object? server = null,Object? rcode = null,Object? answers = null,Object? elapsed = null,Object? route = null,Object? hosts = null,Object? fakeIpRange = null,Object? filterMode = null,Object? outbound = null,Object? outboundType = null,Object? error = null,}) {
  return _then(_DnsQueryResult(
domain: null == domain ? _self.domain : domain // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,mode: null == mode ? _self.mode : mode // ignore: cast_nullable_to_non_nullable
as String,server: null == server ? _self.server : server // ignore: cast_nullable_to_non_nullable
as String,rcode: null == rcode ? _self.rcode : rcode // ignore: cast_nullable_to_non_nullable
as String,answers: null == answers ? _self._answers : answers // ignore: cast_nullable_to_non_nullable
as List<DnsQueryRecord>,elapsed: null == elapsed ? _self.elapsed : elapsed // ignore: cast_nullable_to_non_nullable
as double,route: null == route ? _self.route : route // ignore: cast_nullable_to_non_nullable
as String,hosts: null == hosts ? _self._hosts : hosts // ignore: cast_nullable_to_non_nullable
as List<String>,fakeIpRange: null == fakeIpRange ? _self.fakeIpRange : fakeIpRange // ignore: cast_nullable_to_non_nullable
as String,filterMode: null == filterMode ? _self.filterMode : filterMode // ignore: cast_nullable_to_non_nullable
as String,outbound: null == outbound ? _self.outbound : outbound // ignore: cast_nullable_to_non_nullable
as String,outboundType: null == outboundType ? _self.outboundType : outboundType // ignore: cast_nullable_to_non_nullable
as String,error: null == error ? _self.error : error // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$MrsPrepareResult {

 String get version; int get geosite; int get geoip; bool get extracted; double get elapsed; String get error;
/// Create a copy of MrsPrepareResult
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MrsPrepareResultCopyWith<MrsPrepareResult> get copyWith => _$MrsPrepareResultCopyWithImpl<MrsPrepareResult>(this as MrsPrepareResult, _$identity);

  /// Serializes this MrsPrepareResult to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MrsPrepareResult&&(identical(other.version, version) || other.version == version)&&(identical(other.geosite, geosite) || other.geosite == geosite)&&(identical(other.geoip, geoip) || other.geoip == geoip)&&(identical(other.extracted, extracted) || other.extracted == extracted)&&(identical(other.elapsed, elapsed) || other.elapsed == elapsed)&&(identical(other.error, error) || other.error == error));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,version,geosite,geoip,extracted,elapsed,error);

@override
String toString() {
  return 'MrsPrepareResult(version: $version, geosite: $geosite, geoip: $geoip, extracted: $extracted, elapsed: $elapsed, error: $error)';
}


}

/// @nodoc
abstract mixin class $MrsPrepareResultCopyWith<$Res>  {
  factory $MrsPrepareResultCopyWith(MrsPrepareResult value, $Res Function(MrsPrepareResult) _then) = _$MrsPrepareResultCopyWithImpl;
@useResult
$Res call({
 String version, int geosite, int geoip, bool extracted, double elapsed, String error
});




}
/// @nodoc
class _$MrsPrepareResultCopyWithImpl<$Res>
    implements $MrsPrepareResultCopyWith<$Res> {
  _$MrsPrepareResultCopyWithImpl(this._self, this._then);

  final MrsPrepareResult _self;
  final $Res Function(MrsPrepareResult) _then;

/// Create a copy of MrsPrepareResult
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? version = null,Object? geosite = null,Object? geoip = null,Object? extracted = null,Object? elapsed = null,Object? error = null,}) {
  return _then(MrsPrepareResult(
version: null == version ? _self.version : version // ignore: cast_nullable_to_non_nullable
as String,geosite: null == geosite ? _self.geosite : geosite // ignore: cast_nullable_to_non_nullable
as int,geoip: null == geoip ? _self.geoip : geoip // ignore: cast_nullable_to_non_nullable
as int,extracted: null == extracted ? _self.extracted : extracted // ignore: cast_nullable_to_non_nullable
as bool,elapsed: null == elapsed ? _self.elapsed : elapsed // ignore: cast_nullable_to_non_nullable
as double,error: null == error ? _self.error : error // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [MrsPrepareResult].
extension MrsPrepareResultPatterns on MrsPrepareResult {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MrsPrepareResult value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MrsPrepareResult() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MrsPrepareResult value)  $default,){
final _that = this;
switch (_that) {
case _MrsPrepareResult():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MrsPrepareResult value)?  $default,){
final _that = this;
switch (_that) {
case _MrsPrepareResult() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String version,  int geosite,  int geoip,  bool extracted,  double elapsed,  String error)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MrsPrepareResult() when $default != null:
return $default(_that.version,_that.geosite,_that.geoip,_that.extracted,_that.elapsed,_that.error);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String version,  int geosite,  int geoip,  bool extracted,  double elapsed,  String error)  $default,) {final _that = this;
switch (_that) {
case _MrsPrepareResult():
return $default(_that.version,_that.geosite,_that.geoip,_that.extracted,_that.elapsed,_that.error);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String version,  int geosite,  int geoip,  bool extracted,  double elapsed,  String error)?  $default,) {final _that = this;
switch (_that) {
case _MrsPrepareResult() when $default != null:
return $default(_that.version,_that.geosite,_that.geoip,_that.extracted,_that.elapsed,_that.error);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _MrsPrepareResult implements MrsPrepareResult {
  const _MrsPrepareResult({this.version = '', this.geosite = 0, this.geoip = 0, this.extracted = false, this.elapsed = 0, this.error = ''});
  factory _MrsPrepareResult.fromJson(Map<String, dynamic> json) => _$MrsPrepareResultFromJson(json);

@override@JsonKey() final  String version;
@override@JsonKey() final  int geosite;
@override@JsonKey() final  int geoip;
@override@JsonKey() final  bool extracted;
@override@JsonKey() final  double elapsed;
@override@JsonKey() final  String error;

/// Create a copy of MrsPrepareResult
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MrsPrepareResultCopyWith<_MrsPrepareResult> get copyWith => __$MrsPrepareResultCopyWithImpl<_MrsPrepareResult>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$MrsPrepareResultToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _MrsPrepareResult&&(identical(other.version, version) || other.version == version)&&(identical(other.geosite, geosite) || other.geosite == geosite)&&(identical(other.geoip, geoip) || other.geoip == geoip)&&(identical(other.extracted, extracted) || other.extracted == extracted)&&(identical(other.elapsed, elapsed) || other.elapsed == elapsed)&&(identical(other.error, error) || other.error == error));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,version,geosite,geoip,extracted,elapsed,error);

@override
String toString() {
  return 'MrsPrepareResult(version: $version, geosite: $geosite, geoip: $geoip, extracted: $extracted, elapsed: $elapsed, error: $error)';
}


}

/// @nodoc
abstract mixin class _$MrsPrepareResultCopyWith<$Res> implements $MrsPrepareResultCopyWith<$Res> {
  factory _$MrsPrepareResultCopyWith(_MrsPrepareResult value, $Res Function(_MrsPrepareResult) _then) = __$MrsPrepareResultCopyWithImpl;
@override @useResult
$Res call({
 String version, int geosite, int geoip, bool extracted, double elapsed, String error
});




}
/// @nodoc
class __$MrsPrepareResultCopyWithImpl<$Res>
    implements _$MrsPrepareResultCopyWith<$Res> {
  __$MrsPrepareResultCopyWithImpl(this._self, this._then);

  final _MrsPrepareResult _self;
  final $Res Function(_MrsPrepareResult) _then;

/// Create a copy of MrsPrepareResult
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? version = null,Object? geosite = null,Object? geoip = null,Object? extracted = null,Object? elapsed = null,Object? error = null,}) {
  return _then(_MrsPrepareResult(
version: null == version ? _self.version : version // ignore: cast_nullable_to_non_nullable
as String,geosite: null == geosite ? _self.geosite : geosite // ignore: cast_nullable_to_non_nullable
as int,geoip: null == geoip ? _self.geoip : geoip // ignore: cast_nullable_to_non_nullable
as int,extracted: null == extracted ? _self.extracted : extracted // ignore: cast_nullable_to_non_nullable
as bool,elapsed: null == elapsed ? _self.elapsed : elapsed // ignore: cast_nullable_to_non_nullable
as double,error: null == error ? _self.error : error // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$MrsMatch {

 String get kind; String get name; String get file; int get count; String get via; bool get referenced;
/// Create a copy of MrsMatch
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MrsMatchCopyWith<MrsMatch> get copyWith => _$MrsMatchCopyWithImpl<MrsMatch>(this as MrsMatch, _$identity);

  /// Serializes this MrsMatch to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MrsMatch&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.name, name) || other.name == name)&&(identical(other.file, file) || other.file == file)&&(identical(other.count, count) || other.count == count)&&(identical(other.via, via) || other.via == via)&&(identical(other.referenced, referenced) || other.referenced == referenced));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,kind,name,file,count,via,referenced);

@override
String toString() {
  return 'MrsMatch(kind: $kind, name: $name, file: $file, count: $count, via: $via, referenced: $referenced)';
}


}

/// @nodoc
abstract mixin class $MrsMatchCopyWith<$Res>  {
  factory $MrsMatchCopyWith(MrsMatch value, $Res Function(MrsMatch) _then) = _$MrsMatchCopyWithImpl;
@useResult
$Res call({
 String kind, String name, String file, int count, String via, bool referenced
});




}
/// @nodoc
class _$MrsMatchCopyWithImpl<$Res>
    implements $MrsMatchCopyWith<$Res> {
  _$MrsMatchCopyWithImpl(this._self, this._then);

  final MrsMatch _self;
  final $Res Function(MrsMatch) _then;

/// Create a copy of MrsMatch
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? kind = null,Object? name = null,Object? file = null,Object? count = null,Object? via = null,Object? referenced = null,}) {
  return _then(MrsMatch(
kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,file: null == file ? _self.file : file // ignore: cast_nullable_to_non_nullable
as String,count: null == count ? _self.count : count // ignore: cast_nullable_to_non_nullable
as int,via: null == via ? _self.via : via // ignore: cast_nullable_to_non_nullable
as String,referenced: null == referenced ? _self.referenced : referenced // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [MrsMatch].
extension MrsMatchPatterns on MrsMatch {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MrsMatch value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MrsMatch() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MrsMatch value)  $default,){
final _that = this;
switch (_that) {
case _MrsMatch():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MrsMatch value)?  $default,){
final _that = this;
switch (_that) {
case _MrsMatch() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String kind,  String name,  String file,  int count,  String via,  bool referenced)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MrsMatch() when $default != null:
return $default(_that.kind,_that.name,_that.file,_that.count,_that.via,_that.referenced);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String kind,  String name,  String file,  int count,  String via,  bool referenced)  $default,) {final _that = this;
switch (_that) {
case _MrsMatch():
return $default(_that.kind,_that.name,_that.file,_that.count,_that.via,_that.referenced);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String kind,  String name,  String file,  int count,  String via,  bool referenced)?  $default,) {final _that = this;
switch (_that) {
case _MrsMatch() when $default != null:
return $default(_that.kind,_that.name,_that.file,_that.count,_that.via,_that.referenced);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _MrsMatch implements MrsMatch {
  const _MrsMatch({this.kind = '', this.name = '', this.file = '', this.count = 0, this.via = '', this.referenced = false});
  factory _MrsMatch.fromJson(Map<String, dynamic> json) => _$MrsMatchFromJson(json);

@override@JsonKey() final  String kind;
@override@JsonKey() final  String name;
@override@JsonKey() final  String file;
@override@JsonKey() final  int count;
@override@JsonKey() final  String via;
@override@JsonKey() final  bool referenced;

/// Create a copy of MrsMatch
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MrsMatchCopyWith<_MrsMatch> get copyWith => __$MrsMatchCopyWithImpl<_MrsMatch>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$MrsMatchToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _MrsMatch&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.name, name) || other.name == name)&&(identical(other.file, file) || other.file == file)&&(identical(other.count, count) || other.count == count)&&(identical(other.via, via) || other.via == via)&&(identical(other.referenced, referenced) || other.referenced == referenced));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,kind,name,file,count,via,referenced);

@override
String toString() {
  return 'MrsMatch(kind: $kind, name: $name, file: $file, count: $count, via: $via, referenced: $referenced)';
}


}

/// @nodoc
abstract mixin class _$MrsMatchCopyWith<$Res> implements $MrsMatchCopyWith<$Res> {
  factory _$MrsMatchCopyWith(_MrsMatch value, $Res Function(_MrsMatch) _then) = __$MrsMatchCopyWithImpl;
@override @useResult
$Res call({
 String kind, String name, String file, int count, String via, bool referenced
});




}
/// @nodoc
class __$MrsMatchCopyWithImpl<$Res>
    implements _$MrsMatchCopyWith<$Res> {
  __$MrsMatchCopyWithImpl(this._self, this._then);

  final _MrsMatch _self;
  final $Res Function(_MrsMatch) _then;

/// Create a copy of MrsMatch
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? kind = null,Object? name = null,Object? file = null,Object? count = null,Object? via = null,Object? referenced = null,}) {
  return _then(_MrsMatch(
kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,file: null == file ? _self.file : file // ignore: cast_nullable_to_non_nullable
as String,count: null == count ? _self.count : count // ignore: cast_nullable_to_non_nullable
as int,via: null == via ? _self.via : via // ignore: cast_nullable_to_non_nullable
as String,referenced: null == referenced ? _self.referenced : referenced // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}


/// @nodoc
mixin _$MrsLookupResult {

 String get target; String get host; List<String> get ips; List<MrsMatch> get matches; double get elapsed; String get error;
/// Create a copy of MrsLookupResult
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MrsLookupResultCopyWith<MrsLookupResult> get copyWith => _$MrsLookupResultCopyWithImpl<MrsLookupResult>(this as MrsLookupResult, _$identity);

  /// Serializes this MrsLookupResult to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MrsLookupResult&&(identical(other.target, target) || other.target == target)&&(identical(other.host, host) || other.host == host)&&const DeepCollectionEquality().equals(other.ips, ips)&&const DeepCollectionEquality().equals(other.matches, matches)&&(identical(other.elapsed, elapsed) || other.elapsed == elapsed)&&(identical(other.error, error) || other.error == error));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,target,host,const DeepCollectionEquality().hash(ips),const DeepCollectionEquality().hash(matches),elapsed,error);

@override
String toString() {
  return 'MrsLookupResult(target: $target, host: $host, ips: $ips, matches: $matches, elapsed: $elapsed, error: $error)';
}


}

/// @nodoc
abstract mixin class $MrsLookupResultCopyWith<$Res>  {
  factory $MrsLookupResultCopyWith(MrsLookupResult value, $Res Function(MrsLookupResult) _then) = _$MrsLookupResultCopyWithImpl;
@useResult
$Res call({
 String target, String host, List<String> ips, List<MrsMatch> matches, double elapsed, String error
});




}
/// @nodoc
class _$MrsLookupResultCopyWithImpl<$Res>
    implements $MrsLookupResultCopyWith<$Res> {
  _$MrsLookupResultCopyWithImpl(this._self, this._then);

  final MrsLookupResult _self;
  final $Res Function(MrsLookupResult) _then;

/// Create a copy of MrsLookupResult
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? target = null,Object? host = null,Object? ips = null,Object? matches = null,Object? elapsed = null,Object? error = null,}) {
  return _then(MrsLookupResult(
target: null == target ? _self.target : target // ignore: cast_nullable_to_non_nullable
as String,host: null == host ? _self.host : host // ignore: cast_nullable_to_non_nullable
as String,ips: null == ips ? _self.ips : ips // ignore: cast_nullable_to_non_nullable
as List<String>,matches: null == matches ? _self.matches : matches // ignore: cast_nullable_to_non_nullable
as List<MrsMatch>,elapsed: null == elapsed ? _self.elapsed : elapsed // ignore: cast_nullable_to_non_nullable
as double,error: null == error ? _self.error : error // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [MrsLookupResult].
extension MrsLookupResultPatterns on MrsLookupResult {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MrsLookupResult value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MrsLookupResult() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MrsLookupResult value)  $default,){
final _that = this;
switch (_that) {
case _MrsLookupResult():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MrsLookupResult value)?  $default,){
final _that = this;
switch (_that) {
case _MrsLookupResult() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String target,  String host,  List<String> ips,  List<MrsMatch> matches,  double elapsed,  String error)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MrsLookupResult() when $default != null:
return $default(_that.target,_that.host,_that.ips,_that.matches,_that.elapsed,_that.error);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String target,  String host,  List<String> ips,  List<MrsMatch> matches,  double elapsed,  String error)  $default,) {final _that = this;
switch (_that) {
case _MrsLookupResult():
return $default(_that.target,_that.host,_that.ips,_that.matches,_that.elapsed,_that.error);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String target,  String host,  List<String> ips,  List<MrsMatch> matches,  double elapsed,  String error)?  $default,) {final _that = this;
switch (_that) {
case _MrsLookupResult() when $default != null:
return $default(_that.target,_that.host,_that.ips,_that.matches,_that.elapsed,_that.error);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _MrsLookupResult implements MrsLookupResult {
  const _MrsLookupResult({this.target = '', this.host = '',  List<String> ips = const [],  List<MrsMatch> matches = const [], this.elapsed = 0, this.error = ''}): _ips = ips,_matches = matches;
  factory _MrsLookupResult.fromJson(Map<String, dynamic> json) => _$MrsLookupResultFromJson(json);

@override@JsonKey() final  String target;
@override@JsonKey() final  String host;
 final  List<String> _ips;
@override@JsonKey() List<String> get ips {
  if (_ips is EqualUnmodifiableListView) return _ips;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_ips);
}

 final  List<MrsMatch> _matches;
@override@JsonKey() List<MrsMatch> get matches {
  if (_matches is EqualUnmodifiableListView) return _matches;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_matches);
}

@override@JsonKey() final  double elapsed;
@override@JsonKey() final  String error;

/// Create a copy of MrsLookupResult
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MrsLookupResultCopyWith<_MrsLookupResult> get copyWith => __$MrsLookupResultCopyWithImpl<_MrsLookupResult>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$MrsLookupResultToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _MrsLookupResult&&(identical(other.target, target) || other.target == target)&&(identical(other.host, host) || other.host == host)&&const DeepCollectionEquality().equals(other._ips, _ips)&&const DeepCollectionEquality().equals(other._matches, _matches)&&(identical(other.elapsed, elapsed) || other.elapsed == elapsed)&&(identical(other.error, error) || other.error == error));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,target,host,const DeepCollectionEquality().hash(_ips),const DeepCollectionEquality().hash(_matches),elapsed,error);

@override
String toString() {
  return 'MrsLookupResult(target: $target, host: $host, ips: $ips, matches: $matches, elapsed: $elapsed, error: $error)';
}


}

/// @nodoc
abstract mixin class _$MrsLookupResultCopyWith<$Res> implements $MrsLookupResultCopyWith<$Res> {
  factory _$MrsLookupResultCopyWith(_MrsLookupResult value, $Res Function(_MrsLookupResult) _then) = __$MrsLookupResultCopyWithImpl;
@override @useResult
$Res call({
 String target, String host, List<String> ips, List<MrsMatch> matches, double elapsed, String error
});




}
/// @nodoc
class __$MrsLookupResultCopyWithImpl<$Res>
    implements _$MrsLookupResultCopyWith<$Res> {
  __$MrsLookupResultCopyWithImpl(this._self, this._then);

  final _MrsLookupResult _self;
  final $Res Function(_MrsLookupResult) _then;

/// Create a copy of MrsLookupResult
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? target = null,Object? host = null,Object? ips = null,Object? matches = null,Object? elapsed = null,Object? error = null,}) {
  return _then(_MrsLookupResult(
target: null == target ? _self.target : target // ignore: cast_nullable_to_non_nullable
as String,host: null == host ? _self.host : host // ignore: cast_nullable_to_non_nullable
as String,ips: null == ips ? _self._ips : ips // ignore: cast_nullable_to_non_nullable
as List<String>,matches: null == matches ? _self._matches : matches // ignore: cast_nullable_to_non_nullable
as List<MrsMatch>,elapsed: null == elapsed ? _self.elapsed : elapsed // ignore: cast_nullable_to_non_nullable
as double,error: null == error ? _self.error : error // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$AgeCryptResult {

 String get data; String get error;
/// Create a copy of AgeCryptResult
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AgeCryptResultCopyWith<AgeCryptResult> get copyWith => _$AgeCryptResultCopyWithImpl<AgeCryptResult>(this as AgeCryptResult, _$identity);

  /// Serializes this AgeCryptResult to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AgeCryptResult&&(identical(other.data, data) || other.data == data)&&(identical(other.error, error) || other.error == error));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,data,error);

@override
String toString() {
  return 'AgeCryptResult(data: $data, error: $error)';
}


}

/// @nodoc
abstract mixin class $AgeCryptResultCopyWith<$Res>  {
  factory $AgeCryptResultCopyWith(AgeCryptResult value, $Res Function(AgeCryptResult) _then) = _$AgeCryptResultCopyWithImpl;
@useResult
$Res call({
 String data, String error
});




}
/// @nodoc
class _$AgeCryptResultCopyWithImpl<$Res>
    implements $AgeCryptResultCopyWith<$Res> {
  _$AgeCryptResultCopyWithImpl(this._self, this._then);

  final AgeCryptResult _self;
  final $Res Function(AgeCryptResult) _then;

/// Create a copy of AgeCryptResult
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? data = null,Object? error = null,}) {
  return _then(AgeCryptResult(
data: null == data ? _self.data : data // ignore: cast_nullable_to_non_nullable
as String,error: null == error ? _self.error : error // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [AgeCryptResult].
extension AgeCryptResultPatterns on AgeCryptResult {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AgeCryptResult value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AgeCryptResult() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AgeCryptResult value)  $default,){
final _that = this;
switch (_that) {
case _AgeCryptResult():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AgeCryptResult value)?  $default,){
final _that = this;
switch (_that) {
case _AgeCryptResult() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String data,  String error)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AgeCryptResult() when $default != null:
return $default(_that.data,_that.error);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String data,  String error)  $default,) {final _that = this;
switch (_that) {
case _AgeCryptResult():
return $default(_that.data,_that.error);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String data,  String error)?  $default,) {final _that = this;
switch (_that) {
case _AgeCryptResult() when $default != null:
return $default(_that.data,_that.error);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _AgeCryptResult implements AgeCryptResult {
  const _AgeCryptResult({this.data = '', this.error = ''});
  factory _AgeCryptResult.fromJson(Map<String, dynamic> json) => _$AgeCryptResultFromJson(json);

@override@JsonKey() final  String data;
@override@JsonKey() final  String error;

/// Create a copy of AgeCryptResult
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AgeCryptResultCopyWith<_AgeCryptResult> get copyWith => __$AgeCryptResultCopyWithImpl<_AgeCryptResult>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AgeCryptResultToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AgeCryptResult&&(identical(other.data, data) || other.data == data)&&(identical(other.error, error) || other.error == error));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,data,error);

@override
String toString() {
  return 'AgeCryptResult(data: $data, error: $error)';
}


}

/// @nodoc
abstract mixin class _$AgeCryptResultCopyWith<$Res> implements $AgeCryptResultCopyWith<$Res> {
  factory _$AgeCryptResultCopyWith(_AgeCryptResult value, $Res Function(_AgeCryptResult) _then) = __$AgeCryptResultCopyWithImpl;
@override @useResult
$Res call({
 String data, String error
});




}
/// @nodoc
class __$AgeCryptResultCopyWithImpl<$Res>
    implements _$AgeCryptResultCopyWith<$Res> {
  __$AgeCryptResultCopyWithImpl(this._self, this._then);

  final _AgeCryptResult _self;
  final $Res Function(_AgeCryptResult) _then;

/// Create a copy of AgeCryptResult
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? data = null,Object? error = null,}) {
  return _then(_AgeCryptResult(
data: null == data ? _self.data : data // ignore: cast_nullable_to_non_nullable
as String,error: null == error ? _self.error : error // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
