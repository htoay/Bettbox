// GENERATED CODE - DO NOT MODIFY BY HAND

part of '../local_ping.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_LocalPingReply _$LocalPingReplyFromJson(Map<String, dynamic> json) =>
    _LocalPingReply(
      seq: (json['seq'] as num?)?.toInt() ?? 0,
      status:
          $enumDecodeNullable(
            _$LocalPingStatusEnumMap,
            json['status'],
            unknownValue: LocalPingStatus.error,
          ) ??
          LocalPingStatus.error,
      rtt: (json['rtt'] as num?)?.toDouble() ?? 0,
      ttl: (json['ttl'] as num?)?.toInt() ?? 0,
      bytes: (json['bytes'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$LocalPingReplyToJson(_LocalPingReply instance) =>
    <String, dynamic>{
      'seq': instance.seq,
      'status': _$LocalPingStatusEnumMap[instance.status]!,
      'rtt': instance.rtt,
      'ttl': instance.ttl,
      'bytes': instance.bytes,
    };

const _$LocalPingStatusEnumMap = {
  LocalPingStatus.ok: 'ok',
  LocalPingStatus.closed: 'closed',
  LocalPingStatus.timeout: 'timeout',
  LocalPingStatus.unreachable: 'unreachable',
  LocalPingStatus.error: 'error',
};

_LocalPingState _$LocalPingStateFromJson(Map<String, dynamic> json) =>
    _LocalPingState(
      session: (json['session'] as num?)?.toInt() ?? 0,
      phase:
          $enumDecodeNullable(
            _$LocalPingPhaseEnumMap,
            json['phase'],
            unknownValue: LocalPingPhase.done,
          ) ??
          LocalPingPhase.resolving,
      target: json['target'] as String? ?? '',
      address: json['address'] as String? ?? '',
      protocol:
          $enumDecodeNullable(
            _$LocalPingProtocolEnumMap,
            json['protocol'],
            unknownValue: LocalPingProtocol.icmp,
          ) ??
          LocalPingProtocol.icmp,
      port: (json['port'] as num?)?.toInt() ?? 0,
      size: (json['size'] as num?)?.toInt() ?? 0,
      count: (json['count'] as num?)?.toInt() ?? 0,
      interval: (json['interval'] as num?)?.toInt() ?? 0,
      sent: (json['sent'] as num?)?.toInt() ?? 0,
      elapsed: (json['elapsed'] as num?)?.toDouble() ?? 0,
      reply: json['reply'] == null
          ? null
          : LocalPingReply.fromJson(json['reply'] as Map<String, dynamic>),
      replies:
          (json['replies'] as List<dynamic>?)
              ?.map((e) => LocalPingReply.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      error: json['error'] as String? ?? '',
    );

Map<String, dynamic> _$LocalPingStateToJson(_LocalPingState instance) =>
    <String, dynamic>{
      'session': instance.session,
      'phase': _$LocalPingPhaseEnumMap[instance.phase]!,
      'target': instance.target,
      'address': instance.address,
      'protocol': _$LocalPingProtocolEnumMap[instance.protocol]!,
      'port': instance.port,
      'size': instance.size,
      'count': instance.count,
      'interval': instance.interval,
      'sent': instance.sent,
      'elapsed': instance.elapsed,
      'reply': instance.reply,
      'replies': instance.replies,
      'error': instance.error,
    };

const _$LocalPingPhaseEnumMap = {
  LocalPingPhase.resolving: 'resolving',
  LocalPingPhase.running: 'running',
  LocalPingPhase.done: 'done',
};

const _$LocalPingProtocolEnumMap = {
  LocalPingProtocol.icmp: 'icmp',
  LocalPingProtocol.tcp: 'tcp',
  LocalPingProtocol.udp: 'udp',
};

_LocalPingOptions _$LocalPingOptionsFromJson(Map<String, dynamic> json) =>
    _LocalPingOptions(
      protocol:
          $enumDecodeNullable(
            _$LocalPingProtocolEnumMap,
            json['protocol'],
            unknownValue: LocalPingProtocol.icmp,
          ) ??
          LocalPingProtocol.icmp,
      count: (json['count'] as num?)?.toInt() ?? 10,
      interval: (json['interval'] as num?)?.toInt() ?? 1000,
      size: (json['size'] as num?)?.toInt() ?? 56,
      tcpPort: (json['tcpPort'] as num?)?.toInt() ?? 443,
      udpPort: (json['udpPort'] as num?)?.toInt() ?? 53,
    );

Map<String, dynamic> _$LocalPingOptionsToJson(_LocalPingOptions instance) =>
    <String, dynamic>{
      'protocol': _$LocalPingProtocolEnumMap[instance.protocol]!,
      'count': instance.count,
      'interval': instance.interval,
      'size': instance.size,
      'tcpPort': instance.tcpPort,
      'udpPort': instance.udpPort,
    };
