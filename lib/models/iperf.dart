// ignore_for_file: invalid_annotation_target

import 'package:bett_box/enum/enum.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'generated/iperf.freezed.dart';
part 'generated/iperf.g.dart';

@freezed
abstract class IperfFlow with _$IperfFlow {
  const factory IperfFlow({
    @Default(0) double bytes,
    @Default(0) double bitrate,
    @Default(-1) int retransmits,
    @Default(0) double jitter,
    @Default(0) int lost,
    @Default(0) int packets,
    @JsonKey(name: 'rtt-min') @Default(0) double rttMin,
    @JsonKey(name: 'rtt-mean') @Default(0) double rttMean,
    @JsonKey(name: 'rtt-max') @Default(0) double rttMax,
  }) = _IperfFlow;

  factory IperfFlow.fromJson(Map<String, Object?> json) =>
      _$IperfFlowFromJson(json);
}

extension IperfFlowExt on IperfFlow {
  double get lossRate => packets > 0 ? lost / packets : 0;

  bool get hasRtt => rttMax > 0;
}

@freezed
abstract class IperfState with _$IperfState {
  const factory IperfState({
    @JsonKey(unknownEnumValue: IperfRole.client)
    @Default(IperfRole.client)
    IperfRole role,
    @Default(0) int session,
    @JsonKey(unknownEnumValue: IperfPhase.connecting)
    @Default(IperfPhase.connecting)
    IperfPhase phase,
    @Default('') String peer,
    @JsonKey(unknownEnumValue: IperfProtocol.tcp)
    @Default(IperfProtocol.tcp)
    IperfProtocol protocol,
    @JsonKey(unknownEnumValue: IperfDirection.upload)
    @Default(IperfDirection.upload)
    IperfDirection direction,
    @Default(1) int parallel,
    @Default(0) double duration,
    @Default(0) double elapsed,
    @Default(0) double upload,
    @Default(0) double download,
    @JsonKey(name: 'upload-result') IperfFlow? uploadResult,
    @JsonKey(name: 'download-result') IperfFlow? downloadResult,
    @Default('') String error,
  }) = _IperfState;

  factory IperfState.fromJson(Map<String, Object?> json) =>
      _$IperfStateFromJson(json);
}

extension IperfStateExt on IperfState {
  bool get isDone => phase == IperfPhase.done;

  bool get hasResult => isDone && error.isEmpty;

  bool get hasUpload => direction != IperfDirection.download;

  bool get hasDownload => direction != IperfDirection.upload;
}

@freezed
abstract class IperfServerInfo with _$IperfServerInfo {
  const factory IperfServerInfo({
    @Default(0) int port,
    @Default(false) bool udp,
    @Default('') String error,
  }) = _IperfServerInfo;

  factory IperfServerInfo.fromJson(Map<String, Object?> json) =>
      _$IperfServerInfoFromJson(json);
}

@freezed
abstract class IperfOptions with _$IperfOptions {
  const factory IperfOptions({
    @JsonKey(unknownEnumValue: IperfProtocol.tcp)
    @Default(IperfProtocol.tcp)
    IperfProtocol protocol,
    @JsonKey(unknownEnumValue: IperfDirection.upload)
    @Default(IperfDirection.upload)
    IperfDirection direction,
    @Default(1) int parallel,
    @Default(10) int duration,
    @Default(100) int bandwidth,
    @Default(5201) int serverPort,
  }) = _IperfOptions;

  factory IperfOptions.fromJson(Map<String, Object?> json) =>
      _$IperfOptionsFromJson(json);
}
