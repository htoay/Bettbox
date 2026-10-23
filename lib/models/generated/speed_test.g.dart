// GENERATED CODE - DO NOT MODIFY BY HAND

part of '../speed_test.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_SpeedTestOutbound _$SpeedTestOutboundFromJson(Map<String, dynamic> json) =>
    _SpeedTestOutbound(
      chains:
          (json['chains'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      rule: json['rule'] as String? ?? '',
      rulePayload: json['rule-payload'] as String? ?? '',
    );

Map<String, dynamic> _$SpeedTestOutboundToJson(_SpeedTestOutbound instance) =>
    <String, dynamic>{
      'chains': instance.chains,
      'rule': instance.rule,
      'rule-payload': instance.rulePayload,
    };

_SpeedTestServer _$SpeedTestServerFromJson(Map<String, dynamic> json) =>
    _SpeedTestServer(
      ip: json['ip'] as String? ?? '',
      country: json['country'] as String? ?? '',
      city: json['city'] as String? ?? '',
      colo: json['colo'] as String? ?? '',
      host: json['host'] as String? ?? '',
      sponsor: json['sponsor'] as String? ?? '',
    );

Map<String, dynamic> _$SpeedTestServerToJson(_SpeedTestServer instance) =>
    <String, dynamic>{
      'ip': instance.ip,
      'country': instance.country,
      'city': instance.city,
      'colo': instance.colo,
      'host': instance.host,
      'sponsor': instance.sponsor,
    };

_SpeedTestState _$SpeedTestStateFromJson(Map<String, dynamic> json) =>
    _SpeedTestState(
      provider:
          $enumDecodeNullable(_$SpeedTestProviderEnumMap, json['provider']) ??
          SpeedTestProvider.apple,
      protocol: json['protocol'] as String? ?? 'h1',
      fallback: json['fallback'] as bool? ?? false,
      exitInfo: json['exit-info'] as Map<String, dynamic>?,
      streams: (json['streams'] as num?)?.toInt() ?? 6,
      duration: (json['duration'] as num?)?.toInt() ?? 10,
      phase:
          $enumDecodeNullable(_$SpeedTestPhaseEnumMap, json['phase']) ??
          SpeedTestPhase.connecting,
      progress: (json['progress'] as num?)?.toDouble() ?? 0,
      speed: (json['speed'] as num?)?.toDouble() ?? 0,
      direct: json['direct'] as bool? ?? false,
      outbound: json['outbound'] == null
          ? null
          : SpeedTestOutbound.fromJson(
              json['outbound'] as Map<String, dynamic>,
            ),
      server: json['server'] == null
          ? null
          : SpeedTestServer.fromJson(json['server'] as Map<String, dynamic>),
      latency: (json['latency'] as num?)?.toDouble() ?? 0,
      jitter: (json['jitter'] as num?)?.toDouble() ?? 0,
      download: (json['download'] as num?)?.toDouble() ?? 0,
      upload: (json['upload'] as num?)?.toDouble() ?? 0,
      downloadLatency: (json['download-latency'] as num?)?.toDouble() ?? 0,
      uploadLatency: (json['upload-latency'] as num?)?.toDouble() ?? 0,
      rpm: (json['rpm'] as num?)?.toInt() ?? 0,
      bytes: (json['bytes'] as num?)?.toInt() ?? 0,
      error: json['error'] as String? ?? '',
    );

Map<String, dynamic> _$SpeedTestStateToJson(_SpeedTestState instance) =>
    <String, dynamic>{
      'provider': _$SpeedTestProviderEnumMap[instance.provider]!,
      'protocol': instance.protocol,
      'fallback': instance.fallback,
      'exit-info': instance.exitInfo,
      'streams': instance.streams,
      'duration': instance.duration,
      'phase': _$SpeedTestPhaseEnumMap[instance.phase]!,
      'progress': instance.progress,
      'speed': instance.speed,
      'direct': instance.direct,
      'outbound': instance.outbound,
      'server': instance.server,
      'latency': instance.latency,
      'jitter': instance.jitter,
      'download': instance.download,
      'upload': instance.upload,
      'download-latency': instance.downloadLatency,
      'upload-latency': instance.uploadLatency,
      'rpm': instance.rpm,
      'bytes': instance.bytes,
      'error': instance.error,
    };

const _$SpeedTestProviderEnumMap = {
  SpeedTestProvider.apple: 'apple',
  SpeedTestProvider.speedtest: 'speedtest',
  SpeedTestProvider.cloudflare: 'cloudflare',
};

const _$SpeedTestPhaseEnumMap = {
  SpeedTestPhase.connecting: 'connecting',
  SpeedTestPhase.latency: 'latency',
  SpeedTestPhase.download: 'download',
  SpeedTestPhase.upload: 'upload',
  SpeedTestPhase.done: 'done',
};

_SpeedTestRecord _$SpeedTestRecordFromJson(Map<String, dynamic> json) =>
    _SpeedTestRecord(
      time: (json['time'] as num).toInt(),
      proxy: json['proxy'] as String? ?? '',
      result: SpeedTestState.fromJson(json['result'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$SpeedTestRecordToJson(_SpeedTestRecord instance) =>
    <String, dynamic>{
      'time': instance.time,
      'proxy': instance.proxy,
      'result': instance.result,
    };

_SpeedTestNode _$SpeedTestNodeFromJson(Map<String, dynamic> json) =>
    _SpeedTestNode(
      host: json['host'] as String? ?? '',
      name: json['name'] as String? ?? '',
      cc: json['cc'] as String? ?? '',
      sponsor: json['sponsor'] as String? ?? '',
      latency: (json['latency'] as num?)?.toDouble() ?? 0,
    );

Map<String, dynamic> _$SpeedTestNodeToJson(_SpeedTestNode instance) =>
    <String, dynamic>{
      'host': instance.host,
      'name': instance.name,
      'cc': instance.cc,
      'sponsor': instance.sponsor,
      'latency': instance.latency,
    };

_SpeedTestSettings _$SpeedTestSettingsFromJson(Map<String, dynamic> json) =>
    _SpeedTestSettings(
      provider:
          $enumDecodeNullable(_$SpeedTestProviderEnumMap, json['provider']) ??
          SpeedTestProvider.apple,
      protocol:
          $enumDecodeNullable(_$SpeedTestProtocolEnumMap, json['protocol']) ??
          SpeedTestProtocol.http2,
      duration: (json['duration'] as num?)?.toInt() ?? 10,
      multiThread: json['multiThread'] as bool? ?? true,
      useSystemDns: json['use-system-dns'] as bool? ?? false,
      server: json['server'] == null
          ? null
          : SpeedTestNode.fromJson(json['server'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$SpeedTestSettingsToJson(_SpeedTestSettings instance) =>
    <String, dynamic>{
      'provider': _$SpeedTestProviderEnumMap[instance.provider]!,
      'protocol': _$SpeedTestProtocolEnumMap[instance.protocol]!,
      'duration': instance.duration,
      'multiThread': instance.multiThread,
      'use-system-dns': instance.useSystemDns,
      'server': instance.server,
    };

const _$SpeedTestProtocolEnumMap = {
  SpeedTestProtocol.http1: 'http1',
  SpeedTestProtocol.http2: 'http2',
  SpeedTestProtocol.http3: 'http3',
};

_SpeedTestData _$SpeedTestDataFromJson(Map<String, dynamic> json) =>
    _SpeedTestData(
      settings: json['settings'] == null
          ? const SpeedTestSettings()
          : SpeedTestSettings.fromJson(
              json['settings'] as Map<String, dynamic>,
            ),
      records:
          (json['records'] as List<dynamic>?)
              ?.map((e) => SpeedTestRecord.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );

Map<String, dynamic> _$SpeedTestDataToJson(_SpeedTestData instance) =>
    <String, dynamic>{
      'settings': instance.settings,
      'records': instance.records,
    };
