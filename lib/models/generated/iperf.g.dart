// GENERATED CODE - DO NOT MODIFY BY HAND

part of '../iperf.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_IperfFlow _$IperfFlowFromJson(Map<String, dynamic> json) => _IperfFlow(
  bytes: (json['bytes'] as num?)?.toDouble() ?? 0,
  bitrate: (json['bitrate'] as num?)?.toDouble() ?? 0,
  retransmits: (json['retransmits'] as num?)?.toInt() ?? -1,
  jitter: (json['jitter'] as num?)?.toDouble() ?? 0,
  lost: (json['lost'] as num?)?.toInt() ?? 0,
  packets: (json['packets'] as num?)?.toInt() ?? 0,
  rttMin: (json['rtt-min'] as num?)?.toDouble() ?? 0,
  rttMean: (json['rtt-mean'] as num?)?.toDouble() ?? 0,
  rttMax: (json['rtt-max'] as num?)?.toDouble() ?? 0,
);

Map<String, dynamic> _$IperfFlowToJson(_IperfFlow instance) =>
    <String, dynamic>{
      'bytes': instance.bytes,
      'bitrate': instance.bitrate,
      'retransmits': instance.retransmits,
      'jitter': instance.jitter,
      'lost': instance.lost,
      'packets': instance.packets,
      'rtt-min': instance.rttMin,
      'rtt-mean': instance.rttMean,
      'rtt-max': instance.rttMax,
    };

_IperfState _$IperfStateFromJson(Map<String, dynamic> json) => _IperfState(
  role:
      $enumDecodeNullable(
        _$IperfRoleEnumMap,
        json['role'],
        unknownValue: IperfRole.client,
      ) ??
      IperfRole.client,
  session: (json['session'] as num?)?.toInt() ?? 0,
  phase:
      $enumDecodeNullable(
        _$IperfPhaseEnumMap,
        json['phase'],
        unknownValue: IperfPhase.connecting,
      ) ??
      IperfPhase.connecting,
  peer: json['peer'] as String? ?? '',
  protocol:
      $enumDecodeNullable(
        _$IperfProtocolEnumMap,
        json['protocol'],
        unknownValue: IperfProtocol.tcp,
      ) ??
      IperfProtocol.tcp,
  direction:
      $enumDecodeNullable(
        _$IperfDirectionEnumMap,
        json['direction'],
        unknownValue: IperfDirection.upload,
      ) ??
      IperfDirection.upload,
  parallel: (json['parallel'] as num?)?.toInt() ?? 1,
  duration: (json['duration'] as num?)?.toDouble() ?? 0,
  elapsed: (json['elapsed'] as num?)?.toDouble() ?? 0,
  upload: (json['upload'] as num?)?.toDouble() ?? 0,
  download: (json['download'] as num?)?.toDouble() ?? 0,
  uploadResult: json['upload-result'] == null
      ? null
      : IperfFlow.fromJson(json['upload-result'] as Map<String, dynamic>),
  downloadResult: json['download-result'] == null
      ? null
      : IperfFlow.fromJson(json['download-result'] as Map<String, dynamic>),
  error: json['error'] as String? ?? '',
);

Map<String, dynamic> _$IperfStateToJson(_IperfState instance) =>
    <String, dynamic>{
      'role': _$IperfRoleEnumMap[instance.role]!,
      'session': instance.session,
      'phase': _$IperfPhaseEnumMap[instance.phase]!,
      'peer': instance.peer,
      'protocol': _$IperfProtocolEnumMap[instance.protocol]!,
      'direction': _$IperfDirectionEnumMap[instance.direction]!,
      'parallel': instance.parallel,
      'duration': instance.duration,
      'elapsed': instance.elapsed,
      'upload': instance.upload,
      'download': instance.download,
      'upload-result': instance.uploadResult,
      'download-result': instance.downloadResult,
      'error': instance.error,
    };

const _$IperfRoleEnumMap = {
  IperfRole.client: 'client',
  IperfRole.server: 'server',
};

const _$IperfPhaseEnumMap = {
  IperfPhase.connecting: 'connecting',
  IperfPhase.running: 'running',
  IperfPhase.done: 'done',
};

const _$IperfProtocolEnumMap = {
  IperfProtocol.tcp: 'tcp',
  IperfProtocol.udp: 'udp',
};

const _$IperfDirectionEnumMap = {
  IperfDirection.upload: 'upload',
  IperfDirection.download: 'download',
  IperfDirection.bidir: 'bidir',
};

_IperfServerInfo _$IperfServerInfoFromJson(Map<String, dynamic> json) =>
    _IperfServerInfo(
      port: (json['port'] as num?)?.toInt() ?? 0,
      udp: json['udp'] as bool? ?? false,
      error: json['error'] as String? ?? '',
    );

Map<String, dynamic> _$IperfServerInfoToJson(_IperfServerInfo instance) =>
    <String, dynamic>{
      'port': instance.port,
      'udp': instance.udp,
      'error': instance.error,
    };

_IperfOptions _$IperfOptionsFromJson(Map<String, dynamic> json) =>
    _IperfOptions(
      protocol:
          $enumDecodeNullable(
            _$IperfProtocolEnumMap,
            json['protocol'],
            unknownValue: IperfProtocol.tcp,
          ) ??
          IperfProtocol.tcp,
      direction:
          $enumDecodeNullable(
            _$IperfDirectionEnumMap,
            json['direction'],
            unknownValue: IperfDirection.upload,
          ) ??
          IperfDirection.upload,
      parallel: (json['parallel'] as num?)?.toInt() ?? 1,
      duration: (json['duration'] as num?)?.toInt() ?? 10,
      bandwidth: (json['bandwidth'] as num?)?.toInt() ?? 100,
      serverPort: (json['serverPort'] as num?)?.toInt() ?? 5201,
    );

Map<String, dynamic> _$IperfOptionsToJson(_IperfOptions instance) =>
    <String, dynamic>{
      'protocol': _$IperfProtocolEnumMap[instance.protocol]!,
      'direction': _$IperfDirectionEnumMap[instance.direction]!,
      'parallel': instance.parallel,
      'duration': instance.duration,
      'bandwidth': instance.bandwidth,
      'serverPort': instance.serverPort,
    };
