// ignore_for_file: invalid_annotation_target

import 'dart:math' as math;

import 'package:bett_box/enum/enum.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'generated/local_ping.freezed.dart';
part 'generated/local_ping.g.dart';

@freezed
abstract class LocalPingReply with _$LocalPingReply {
  const factory LocalPingReply({
    @Default(0) int seq,
    @JsonKey(unknownEnumValue: LocalPingStatus.error)
    @Default(LocalPingStatus.error)
    LocalPingStatus status,
    @Default(0) double rtt,
    @Default(0) int ttl,
    @Default(0) int bytes,
  }) = _LocalPingReply;

  factory LocalPingReply.fromJson(Map<String, Object?> json) =>
      _$LocalPingReplyFromJson(json);
}

extension LocalPingReplyExt on LocalPingReply {
  bool get reachable =>
      status == LocalPingStatus.ok || status == LocalPingStatus.closed;
}

@freezed
abstract class LocalPingState with _$LocalPingState {
  const factory LocalPingState({
    @Default(0) int session,
    @JsonKey(unknownEnumValue: LocalPingPhase.done)
    @Default(LocalPingPhase.resolving)
    LocalPingPhase phase,
    @Default('') String target,
    @Default('') String address,
    @JsonKey(unknownEnumValue: LocalPingProtocol.icmp)
    @Default(LocalPingProtocol.icmp)
    LocalPingProtocol protocol,
    @Default(0) int port,
    @Default(0) int size,
    @Default(0) int count,
    @Default(0) int interval,
    @Default(0) int sent,
    @Default(0) double elapsed,
    LocalPingReply? reply,
    @Default([]) List<LocalPingReply> replies,
    @Default('') String error,
  }) = _LocalPingState;

  factory LocalPingState.fromJson(Map<String, Object?> json) =>
      _$LocalPingStateFromJson(json);
}

extension LocalPingStateExt on LocalPingState {
  bool get isDone => phase == LocalPingPhase.done;

  bool get hasError => error.isNotEmpty;
}

@freezed
abstract class LocalPingOptions with _$LocalPingOptions {
  const factory LocalPingOptions({
    @JsonKey(unknownEnumValue: LocalPingProtocol.icmp)
    @Default(LocalPingProtocol.icmp)
    LocalPingProtocol protocol,
    @Default(10) int count,
    @Default(1000) int interval,
    @Default(56) int size,
    @Default(443) int tcpPort,
    @Default(53) int udpPort,
  }) = _LocalPingOptions;

  factory LocalPingOptions.fromJson(Map<String, Object?> json) =>
      _$LocalPingOptionsFromJson(json);
}

extension LocalPingOptionsExt on LocalPingOptions {
  int get port => switch (protocol) {
    LocalPingProtocol.icmp => 0,
    LocalPingProtocol.tcp => tcpPort,
    LocalPingProtocol.udp => udpPort,
  };

  bool get usesSize =>
      protocol == LocalPingProtocol.icmp ||
      (protocol == LocalPingProtocol.udp && udpPort != 53);
}

class LocalPingStats {
  final int sent;
  final int completed;
  final int received;
  final double? min;
  final double? max;
  final double? avg;
  final double? jitter;
  final int ttl;

  const LocalPingStats({
    this.sent = 0,
    this.completed = 0,
    this.received = 0,
    this.min,
    this.max,
    this.avg,
    this.jitter,
    this.ttl = 0,
  });

  factory LocalPingStats.of(int sent, List<LocalPingReply> replies) {
    final rtts = <double>[];
    var ttl = 0;
    for (final reply in replies) {
      if (!reply.reachable) continue;
      rtts.add(reply.rtt);
      if (reply.ttl > 0) ttl = reply.ttl;
    }
    if (rtts.isEmpty) {
      return LocalPingStats(
        sent: math.max(sent, replies.length),
        completed: replies.length,
      );
    }
    var total = 0.0;
    var low = rtts.first;
    var high = rtts.first;
    for (final rtt in rtts) {
      total += rtt;
      low = math.min(low, rtt);
      high = math.max(high, rtt);
    }
    double? jitter;
    if (rtts.length > 1) {
      var delta = 0.0;
      for (var i = 1; i < rtts.length; i++) {
        delta += (rtts[i] - rtts[i - 1]).abs();
      }
      jitter = delta / (rtts.length - 1);
    }
    return LocalPingStats(
      sent: math.max(sent, replies.length),
      completed: replies.length,
      received: rtts.length,
      min: low,
      max: high,
      avg: total / rtts.length,
      jitter: jitter,
      ttl: ttl,
    );
  }

  int get lost => completed - received;

  double get loss => completed == 0 ? 0 : lost / completed;
}
