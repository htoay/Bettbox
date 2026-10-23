// GENERATED CODE - DO NOT MODIFY BY HAND

part of '../toolbox.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_RouteTraceStep _$RouteTraceStepFromJson(Map<String, dynamic> json) =>
    _RouteTraceStep(
      index: (json['index'] as num?)?.toInt() ?? 0,
      type: json['type'] as String? ?? '',
      payload: json['payload'] as String? ?? '',
      adapter: json['adapter'] as String? ?? '',
      matched: json['matched'] as bool? ?? false,
      resolve: json['resolve'] as bool? ?? false,
      skipped: json['skipped'] as String? ?? '',
      duration: (json['duration'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$RouteTraceStepToJson(_RouteTraceStep instance) =>
    <String, dynamic>{
      'index': instance.index,
      'type': instance.type,
      'payload': instance.payload,
      'adapter': instance.adapter,
      'matched': instance.matched,
      'resolve': instance.resolve,
      'skipped': instance.skipped,
      'duration': instance.duration,
    };

_RouteTraceChain _$RouteTraceChainFromJson(Map<String, dynamic> json) =>
    _RouteTraceChain(
      name: json['name'] as String? ?? '',
      type: json['type'] as String? ?? '',
    );

Map<String, dynamic> _$RouteTraceChainToJson(_RouteTraceChain instance) =>
    <String, dynamic>{'name': instance.name, 'type': instance.type};

_RouteTraceResult _$RouteTraceResultFromJson(Map<String, dynamic> json) =>
    _RouteTraceResult(
      target: json['target'] as String? ?? '',
      host: json['host'] as String? ?? '',
      network: json['network'] as String? ?? 'tcp',
      port: (json['port'] as num?)?.toInt() ?? 443,
      mode: json['mode'] as String? ?? '',
      dnsMode: json['dns-mode'] as String? ?? '',
      hostsIps:
          (json['hosts-ips'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      resolvedIps:
          (json['resolved-ips'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      resolveTime: (json['resolve-time'] as num?)?.toDouble() ?? 0,
      resolveError: json['resolve-error'] as String? ?? '',
      resolvedBy: (json['resolved-by'] as num?)?.toInt() ?? -1,
      dstIp: json['dst-ip'] as String? ?? '',
      total: (json['total'] as num?)?.toInt() ?? 0,
      checked: (json['checked'] as num?)?.toInt() ?? 0,
      truncated: json['truncated'] as bool? ?? false,
      steps:
          (json['steps'] as List<dynamic>?)
              ?.map((e) => RouteTraceStep.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      matched: json['matched'] == null
          ? null
          : RouteTraceStep.fromJson(json['matched'] as Map<String, dynamic>),
      chains:
          (json['chains'] as List<dynamic>?)
              ?.map((e) => RouteTraceChain.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      supportUdp: json['support-udp'] as bool? ?? false,
      matchTime: (json['match-time'] as num?)?.toDouble() ?? 0,
      fallbackDirect: json['fallback-direct'] as bool? ?? false,
      error: json['error'] as String? ?? '',
    );

Map<String, dynamic> _$RouteTraceResultToJson(_RouteTraceResult instance) =>
    <String, dynamic>{
      'target': instance.target,
      'host': instance.host,
      'network': instance.network,
      'port': instance.port,
      'mode': instance.mode,
      'dns-mode': instance.dnsMode,
      'hosts-ips': instance.hostsIps,
      'resolved-ips': instance.resolvedIps,
      'resolve-time': instance.resolveTime,
      'resolve-error': instance.resolveError,
      'resolved-by': instance.resolvedBy,
      'dst-ip': instance.dstIp,
      'total': instance.total,
      'checked': instance.checked,
      'truncated': instance.truncated,
      'steps': instance.steps,
      'matched': instance.matched,
      'chains': instance.chains,
      'support-udp': instance.supportUdp,
      'match-time': instance.matchTime,
      'fallback-direct': instance.fallbackDirect,
      'error': instance.error,
    };

_DnsQueryRecord _$DnsQueryRecordFromJson(Map<String, dynamic> json) =>
    _DnsQueryRecord(
      name: json['name'] as String? ?? '',
      type: json['type'] as String? ?? '',
      ttl: (json['ttl'] as num?)?.toInt() ?? 0,
      data: json['data'] as String? ?? '',
    );

Map<String, dynamic> _$DnsQueryRecordToJson(_DnsQueryRecord instance) =>
    <String, dynamic>{
      'name': instance.name,
      'type': instance.type,
      'ttl': instance.ttl,
      'data': instance.data,
    };

_DnsQueryResult _$DnsQueryResultFromJson(Map<String, dynamic> json) =>
    _DnsQueryResult(
      domain: json['domain'] as String? ?? '',
      type: json['type'] as String? ?? 'A',
      mode: json['mode'] as String? ?? '',
      server: json['server'] as String? ?? '',
      rcode: json['rcode'] as String? ?? '',
      answers:
          (json['answers'] as List<dynamic>?)
              ?.map((e) => DnsQueryRecord.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      elapsed: (json['elapsed'] as num?)?.toDouble() ?? 0,
      route: json['route'] as String? ?? '',
      hosts:
          (json['hosts'] as List<dynamic>?)?.map((e) => e as String).toList() ??
          const [],
      fakeIpRange: json['fake-ip-range'] as String? ?? '',
      filterMode: json['filter-mode'] as String? ?? '',
      outbound: json['outbound'] as String? ?? '',
      outboundType: json['outbound-type'] as String? ?? '',
      error: json['error'] as String? ?? '',
    );

Map<String, dynamic> _$DnsQueryResultToJson(_DnsQueryResult instance) =>
    <String, dynamic>{
      'domain': instance.domain,
      'type': instance.type,
      'mode': instance.mode,
      'server': instance.server,
      'rcode': instance.rcode,
      'answers': instance.answers,
      'elapsed': instance.elapsed,
      'route': instance.route,
      'hosts': instance.hosts,
      'fake-ip-range': instance.fakeIpRange,
      'filter-mode': instance.filterMode,
      'outbound': instance.outbound,
      'outbound-type': instance.outboundType,
      'error': instance.error,
    };

_MrsPrepareResult _$MrsPrepareResultFromJson(Map<String, dynamic> json) =>
    _MrsPrepareResult(
      version: json['version'] as String? ?? '',
      geosite: (json['geosite'] as num?)?.toInt() ?? 0,
      geoip: (json['geoip'] as num?)?.toInt() ?? 0,
      extracted: json['extracted'] as bool? ?? false,
      elapsed: (json['elapsed'] as num?)?.toDouble() ?? 0,
      error: json['error'] as String? ?? '',
    );

Map<String, dynamic> _$MrsPrepareResultToJson(_MrsPrepareResult instance) =>
    <String, dynamic>{
      'version': instance.version,
      'geosite': instance.geosite,
      'geoip': instance.geoip,
      'extracted': instance.extracted,
      'elapsed': instance.elapsed,
      'error': instance.error,
    };

_MrsMatch _$MrsMatchFromJson(Map<String, dynamic> json) => _MrsMatch(
  kind: json['kind'] as String? ?? '',
  name: json['name'] as String? ?? '',
  file: json['file'] as String? ?? '',
  count: (json['count'] as num?)?.toInt() ?? 0,
  via: json['via'] as String? ?? '',
  referenced: json['referenced'] as bool? ?? false,
);

Map<String, dynamic> _$MrsMatchToJson(_MrsMatch instance) => <String, dynamic>{
  'kind': instance.kind,
  'name': instance.name,
  'file': instance.file,
  'count': instance.count,
  'via': instance.via,
  'referenced': instance.referenced,
};

_MrsLookupResult _$MrsLookupResultFromJson(Map<String, dynamic> json) =>
    _MrsLookupResult(
      target: json['target'] as String? ?? '',
      host: json['host'] as String? ?? '',
      ips:
          (json['ips'] as List<dynamic>?)?.map((e) => e as String).toList() ??
          const [],
      matches:
          (json['matches'] as List<dynamic>?)
              ?.map((e) => MrsMatch.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      elapsed: (json['elapsed'] as num?)?.toDouble() ?? 0,
      error: json['error'] as String? ?? '',
    );

Map<String, dynamic> _$MrsLookupResultToJson(_MrsLookupResult instance) =>
    <String, dynamic>{
      'target': instance.target,
      'host': instance.host,
      'ips': instance.ips,
      'matches': instance.matches,
      'elapsed': instance.elapsed,
      'error': instance.error,
    };

_AgeCryptResult _$AgeCryptResultFromJson(Map<String, dynamic> json) =>
    _AgeCryptResult(
      data: json['data'] as String? ?? '',
      error: json['error'] as String? ?? '',
    );

Map<String, dynamic> _$AgeCryptResultToJson(_AgeCryptResult instance) =>
    <String, dynamic>{'data': instance.data, 'error': instance.error};
