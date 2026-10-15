import 'dart:async';
import 'dart:convert';
import 'dart:ffi';
import 'dart:isolate';

import 'package:bett_box/clash/interface.dart';
import 'package:bett_box/clash/lib.dart';
import 'package:bett_box/common/common.dart';
import 'package:bett_box/enum/enum.dart';
import 'package:bett_box/models/models.dart';

class ClashOhosLib extends ClashHandlerInterface with AndroidClashInterface {
  static ClashOhosLib? _instance;
  late final ClashLibHandler _handler;
  final ReceivePort _messageReceiverPort = ReceivePort();

  ClashOhosLib._internal() {
    _handler = ClashLibHandler();
    _handler.attachMessagePort(_messageReceiverPort.sendPort.nativePort);
    _messageReceiverPort.listen((message) {
      try {
        handleResult(ActionResult.fromJson(json.decode(message)));
      } catch (e) {
        commonPrint.log('ClashOhosLib message listener error: $e');
      }
    });
  }

  factory ClashOhosLib() {
    _instance ??= ClashOhosLib._internal();
    return _instance!;
  }

  @override
  Future<bool> preload() async {
    return true;
  }

  @override
  Future<void> sendMessage(String message) async {
    final res = await _handler.invokeAction(message);
    if (res.isNotEmpty) {
      try {
        handleResult(ActionResult.fromJson(json.decode(res)));
      } catch (e) {
        commonPrint.log('ClashOhosLib handleResult error: $e');
      }
    }
  }

  @override
  Future<void> reStart() async {}

  @override
  Future<bool> destroy() async {
    return true;
  }

  @override
  Future<AndroidVpnOptions?> getAndroidVpnOptions() async {
    try {
      return _handler.getAndroidVpnOptions();
    } catch (_) {
      return null;
    }
  }

  @override
  Future<bool> updateDns(String value) async {
    try {
      _handler.updateDns(value);
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<String> getCurrentProfileName() async {
    try {
      return _handler.getCurrentProfileName();
    } catch (_) {
      return '';
    }
  }

  @override
  Future<DateTime?> getRunTime() async {
    try {
      return _handler.getRunTime();
    } catch (_) {
      return null;
    }
  }

  @override
  Future<bool> setState(CoreState state) async {
    try {
      _handler.setState(state);
      return true;
    } catch (_) {
      return false;
    }
  }

  bool startTun(int fd) {
    try {
      return _handler.startTun(fd);
    } catch (_) {
      return false;
    }
  }

  void stopTun() {
    try {
      _handler.stopTun();
    } catch (_) {}
  }

  int listenTunBridge(String sockPath) {
    try {
      return _handler.listenTunBridge(sockPath);
    } catch (e) {
      commonPrint.log('ClashOhosLib listenTunBridge error: $e');
      return -1;
    }
  }

  @override
  Future<bool> startListener() async {
    final res = await _handler.startListener();
    return res;
  }

  @override
  Future<bool> stopListener() async {
    return _handler.stopListener();
  }
}
