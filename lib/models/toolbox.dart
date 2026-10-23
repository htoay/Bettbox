// ignore_for_file: invalid_annotation_target

import 'package:freezed_annotation/freezed_annotation.dart';

part 'generated/toolbox.freezed.dart';
part 'generated/toolbox.g.dart';

@freezed
abstract class RouteTraceStep with _$RouteTraceStep {
  const factory RouteTraceStep({
    @Default(0) int index,
    @Default('') String type,
    @Default('') String payload,
    @Default('') String adapter,
    @Default(false) bool matched,
    @Default(false) bool resolve,
    @Default('') String skipped,
    @Default(0) int duration,
  }) = _RouteTraceStep;

  factory RouteTraceStep.fromJson(Map<String, Object?> json) =>
      _$RouteTraceStepFromJson(json);
}

@freezed
abstract class RouteTraceChain with _$RouteTraceChain {
  const factory RouteTraceChain({
    @Default('') String name,
    @Default('') String type,
  }) = _RouteTraceChain;

  factory RouteTraceChain.fromJson(Map<String, Object?> json) =>
      _$RouteTraceChainFromJson(json);
}

@freezed
abstract class RouteTraceResult with _$RouteTraceResult {
  const factory RouteTraceResult({
    @Default('') String target,
    @Default('') String host,
    @Default('tcp') String network,
    @Default(443) int port,
    @Default('') String mode,
    @JsonKey(name: 'dns-mode') @Default('') String dnsMode,
    @JsonKey(name: 'hosts-ips') @Default([]) List<String> hostsIps,
    @JsonKey(name: 'resolved-ips') @Default([]) List<String> resolvedIps,
    @JsonKey(name: 'resolve-time') @Default(0) double resolveTime,
    @JsonKey(name: 'resolve-error') @Default('') String resolveError,
    @JsonKey(name: 'resolved-by') @Default(-1) int resolvedBy,
    @JsonKey(name: 'dst-ip') @Default('') String dstIp,
    @Default(0) int total,
    @Default(0) int checked,
    @Default(false) bool truncated,
    @Default([]) List<RouteTraceStep> steps,
    RouteTraceStep? matched,
    @Default([]) List<RouteTraceChain> chains,
    @JsonKey(name: 'support-udp') @Default(false) bool supportUdp,
    @JsonKey(name: 'match-time') @Default(0) double matchTime,
    @JsonKey(name: 'fallback-direct') @Default(false) bool fallbackDirect,
    @Default('') String error,
  }) = _RouteTraceResult;

  factory RouteTraceResult.fromJson(Map<String, Object?> json) =>
      _$RouteTraceResultFromJson(json);
}

@freezed
abstract class DnsQueryRecord with _$DnsQueryRecord {
  const factory DnsQueryRecord({
    @Default('') String name,
    @Default('') String type,
    @Default(0) int ttl,
    @Default('') String data,
  }) = _DnsQueryRecord;

  factory DnsQueryRecord.fromJson(Map<String, Object?> json) =>
      _$DnsQueryRecordFromJson(json);
}

@freezed
abstract class DnsQueryResult with _$DnsQueryResult {
  const factory DnsQueryResult({
    @Default('') String domain,
    @Default('A') String type,
    @Default('') String mode,
    @Default('') String server,
    @Default('') String rcode,
    @Default([]) List<DnsQueryRecord> answers,
    @Default(0) double elapsed,
    @Default('') String route,
    @Default([]) List<String> hosts,
    @JsonKey(name: 'fake-ip-range') @Default('') String fakeIpRange,
    @JsonKey(name: 'filter-mode') @Default('') String filterMode,
    @Default('') String outbound,
    @JsonKey(name: 'outbound-type') @Default('') String outboundType,
    @Default('') String error,
  }) = _DnsQueryResult;

  factory DnsQueryResult.fromJson(Map<String, Object?> json) =>
      _$DnsQueryResultFromJson(json);
}

@freezed
abstract class MrsPrepareResult with _$MrsPrepareResult {
  const factory MrsPrepareResult({
    @Default('') String version,
    @Default(0) int geosite,
    @Default(0) int geoip,
    @Default(false) bool extracted,
    @Default(0) double elapsed,
    @Default('') String error,
  }) = _MrsPrepareResult;

  factory MrsPrepareResult.fromJson(Map<String, Object?> json) =>
      _$MrsPrepareResultFromJson(json);
}

@freezed
abstract class MrsMatch with _$MrsMatch {
  const factory MrsMatch({
    @Default('') String kind,
    @Default('') String name,
    @Default('') String file,
    @Default(0) int count,
    @Default('') String via,
    @Default(false) bool referenced,
  }) = _MrsMatch;

  factory MrsMatch.fromJson(Map<String, Object?> json) =>
      _$MrsMatchFromJson(json);
}

@freezed
abstract class MrsLookupResult with _$MrsLookupResult {
  const factory MrsLookupResult({
    @Default('') String target,
    @Default('') String host,
    @Default([]) List<String> ips,
    @Default([]) List<MrsMatch> matches,
    @Default(0) double elapsed,
    @Default('') String error,
  }) = _MrsLookupResult;

  factory MrsLookupResult.fromJson(Map<String, Object?> json) =>
      _$MrsLookupResultFromJson(json);
}

@freezed
abstract class AgeCryptResult with _$AgeCryptResult {
  const factory AgeCryptResult({
    @Default('') String data,
    @Default('') String error,
  }) = _AgeCryptResult;

  factory AgeCryptResult.fromJson(Map<String, Object?> json) =>
      _$AgeCryptResultFromJson(json);
}
