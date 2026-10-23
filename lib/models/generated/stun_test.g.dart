// GENERATED CODE - DO NOT MODIFY BY HAND

part of '../stun_test.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_StunTestState _$StunTestStateFromJson(Map<String, dynamic> json) =>
    _StunTestState(
      phase:
          $enumDecodeNullable(_$StunTestPhaseEnumMap, json['phase']) ??
          StunTestPhase.connecting,
      progress: (json['progress'] as num?)?.toDouble() ?? 0,
      server: json['server'] as String? ?? '',
      address: json['address'] as String? ?? '',
      direct: json['direct'] as bool? ?? false,
      outbound: json['outbound'] == null
          ? null
          : SpeedTestOutbound.fromJson(
              json['outbound'] as Map<String, dynamic>,
            ),
      natType:
          $enumDecodeNullable(_$NatTypeEnumMap, json['nat-type']) ??
          NatType.unknown,
      mapping: json['mapping'] as String? ?? '',
      filtering: json['filtering'] as String? ?? '',
      public: json['public'] as bool? ?? false,
      supported: json['rfc5780'] as bool? ?? false,
      externalIp: json['external-ip'] as String? ?? '',
      externalPort: (json['external-port'] as num?)?.toInt() ?? 0,
      localIp: json['local-ip'] as String? ?? '',
      localPort: (json['local-port'] as num?)?.toInt() ?? 0,
      portPreserved: (json['port-preserved'] as num?)?.toInt() ?? -1,
      otherAddress: json['other-address'] as String? ?? '',
      software: json['software'] as String? ?? '',
      latency: (json['latency'] as num?)?.toDouble() ?? -1,
      jitter: (json['jitter'] as num?)?.toDouble() ?? 0,
      packetLoss: (json['packet-loss'] as num?)?.toDouble() ?? -1,
      error: json['error'] as String? ?? '',
    );

Map<String, dynamic> _$StunTestStateToJson(_StunTestState instance) =>
    <String, dynamic>{
      'phase': _$StunTestPhaseEnumMap[instance.phase]!,
      'progress': instance.progress,
      'server': instance.server,
      'address': instance.address,
      'direct': instance.direct,
      'outbound': instance.outbound,
      'nat-type': _$NatTypeEnumMap[instance.natType]!,
      'mapping': instance.mapping,
      'filtering': instance.filtering,
      'public': instance.public,
      'rfc5780': instance.supported,
      'external-ip': instance.externalIp,
      'external-port': instance.externalPort,
      'local-ip': instance.localIp,
      'local-port': instance.localPort,
      'port-preserved': instance.portPreserved,
      'other-address': instance.otherAddress,
      'software': instance.software,
      'latency': instance.latency,
      'jitter': instance.jitter,
      'packet-loss': instance.packetLoss,
      'error': instance.error,
    };

const _$StunTestPhaseEnumMap = {
  StunTestPhase.connecting: 'connecting',
  StunTestPhase.binding: 'binding',
  StunTestPhase.filtering: 'filtering',
  StunTestPhase.mapping: 'mapping',
  StunTestPhase.done: 'done',
};

const _$NatTypeEnumMap = {
  NatType.open: 'open',
  NatType.fullCone: 'full-cone',
  NatType.restricted: 'restricted',
  NatType.portRestricted: 'port-restricted',
  NatType.symmetric: 'symmetric',
  NatType.cone: 'cone',
  NatType.blocked: 'blocked',
  NatType.unknown: 'unknown',
};
