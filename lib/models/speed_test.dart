// ignore_for_file: invalid_annotation_target

import 'package:bett_box/enum/enum.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'generated/speed_test.freezed.dart';
part 'generated/speed_test.g.dart';

@freezed
abstract class SpeedTestOutbound with _$SpeedTestOutbound {
  const factory SpeedTestOutbound({
    @Default([]) List<String> chains,
    @Default('') String rule,
    @JsonKey(name: 'rule-payload') @Default('') String rulePayload,
  }) = _SpeedTestOutbound;

  factory SpeedTestOutbound.fromJson(Map<String, Object?> json) =>
      _$SpeedTestOutboundFromJson(json);
}

@freezed
abstract class SpeedTestServer with _$SpeedTestServer {
  const factory SpeedTestServer({
    @Default('') String ip,
    @Default('') String country,
    @Default('') String city,
    @Default('') String colo,
    @Default('') String host,
    @Default('') String sponsor,
  }) = _SpeedTestServer;

  factory SpeedTestServer.fromJson(Map<String, Object?> json) =>
      _$SpeedTestServerFromJson(json);
}

@freezed
abstract class SpeedTestState with _$SpeedTestState {
  const factory SpeedTestState({
    @Default(SpeedTestProvider.apple) SpeedTestProvider provider,
    @Default('h1') String protocol,
    @Default(false) bool fallback,
    @JsonKey(name: 'exit-info') Map<String, dynamic>? exitInfo,
    @Default(6) int streams,
    @Default(10) int duration,
    @Default(SpeedTestPhase.connecting) SpeedTestPhase phase,
    @Default(0) double progress,
    @Default(0) double speed,
    @Default(false) bool direct,
    SpeedTestOutbound? outbound,
    SpeedTestServer? server,
    @Default(0) double latency,
    @Default(0) double jitter,
    @Default(0) double download,
    @Default(0) double upload,
    @JsonKey(name: 'download-latency') @Default(0) double downloadLatency,
    @JsonKey(name: 'upload-latency') @Default(0) double uploadLatency,
    @Default(0) int rpm,
    @Default(0) int bytes,
    @Default('') String error,
  }) = _SpeedTestState;

  factory SpeedTestState.fromJson(Map<String, Object?> json) =>
      _$SpeedTestStateFromJson(json);
}

@freezed
abstract class SpeedTestRecord with _$SpeedTestRecord {
  const factory SpeedTestRecord({
    required int time,
    @Default('') String proxy,
    required SpeedTestState result,
  }) = _SpeedTestRecord;

  factory SpeedTestRecord.fromJson(Map<String, Object?> json) =>
      _$SpeedTestRecordFromJson(json);
}

@freezed
abstract class SpeedTestNode with _$SpeedTestNode {
  const factory SpeedTestNode({
    @Default('') String host,
    @Default('') String name,
    @Default('') String cc,
    @Default('') String sponsor,
    @Default(0) double latency,
  }) = _SpeedTestNode;

  factory SpeedTestNode.fromJson(Map<String, Object?> json) =>
      _$SpeedTestNodeFromJson(json);
}

@freezed
abstract class SpeedTestSettings with _$SpeedTestSettings {
  const factory SpeedTestSettings({
    @Default(SpeedTestProvider.apple) SpeedTestProvider provider,
    @Default(SpeedTestProtocol.http2) SpeedTestProtocol protocol,
    @Default(10) int duration,
    @Default(true) bool multiThread,
    @JsonKey(name: 'use-system-dns') @Default(false) bool useSystemDns,
    SpeedTestNode? server,
  }) = _SpeedTestSettings;

  factory SpeedTestSettings.fromJson(Map<String, Object?> json) =>
      _$SpeedTestSettingsFromJson(json);
}

@freezed
abstract class SpeedTestData with _$SpeedTestData {
  const factory SpeedTestData({
    @Default(SpeedTestSettings()) SpeedTestSettings settings,
    @Default([]) List<SpeedTestRecord> records,
  }) = _SpeedTestData;

  factory SpeedTestData.fromJson(Map<String, Object?> json) =>
      _$SpeedTestDataFromJson(json);
}

extension SpeedTestStateExt on SpeedTestState {
  bool get isFinished => phase == SpeedTestPhase.done || error.isNotEmpty;

  bool get isRunning => !isFinished;

  String get protocolLabel => SpeedTestProtocol.fromValue(protocol).label;
}

extension SpeedTestSettingsExt on SpeedTestSettings {
  static const multiThreadStreams = 8;

  SpeedTestSettings get normalized => protocol == SpeedTestProtocol.http1
      ? copyWith(protocol: SpeedTestProtocol.http2)
      : this;

  Map<String, Object?> toParams(String proxy) => {
    'provider': provider.name,
    'proxy': proxy,
    'duration': duration,
    'protocol': protocol.value,
    'streams': multiThread ? multiThreadStreams : 1,
    'use-system-dns': useSystemDns,
    'server': server?.toJson(),
  };
}
