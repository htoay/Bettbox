// ignore_for_file: invalid_annotation_target

import 'package:bett_box/enum/enum.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import 'speed_test.dart';

part 'generated/stun_test.freezed.dart';
part 'generated/stun_test.g.dart';

@freezed
abstract class StunTestState with _$StunTestState {
  const factory StunTestState({
    @Default(StunTestPhase.connecting) StunTestPhase phase,
    @Default(0) double progress,
    @Default('') String server,
    @Default('') String address,
    @Default(false) bool direct,
    SpeedTestOutbound? outbound,
    @JsonKey(name: 'nat-type') @Default(NatType.unknown) NatType natType,
    @Default('') String mapping,
    @Default('') String filtering,
    @Default(false) bool public,
    @JsonKey(name: 'rfc5780') @Default(false) bool supported,
    @JsonKey(name: 'external-ip') @Default('') String externalIp,
    @JsonKey(name: 'external-port') @Default(0) int externalPort,
    @JsonKey(name: 'local-ip') @Default('') String localIp,
    @JsonKey(name: 'local-port') @Default(0) int localPort,
    @JsonKey(name: 'port-preserved') @Default(-1) int portPreserved,
    @JsonKey(name: 'other-address') @Default('') String otherAddress,
    @Default('') String software,
    @Default(-1) double latency,
    @Default(0) double jitter,
    @JsonKey(name: 'packet-loss') @Default(-1) double packetLoss,
    @Default('') String error,
  }) = _StunTestState;

  factory StunTestState.fromJson(Map<String, Object?> json) =>
      _$StunTestStateFromJson(json);
}

extension StunTestStateExt on StunTestState {
  bool get isFinished => phase == StunTestPhase.done || error.isNotEmpty;

  bool get hasResult => phase == StunTestPhase.done && error.isEmpty;
}
