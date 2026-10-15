import 'dart:async';
import 'dart:convert';

import 'package:bett_box/common/common.dart';
import 'package:bett_box/state.dart';
import 'package:flutter/services.dart';

import '../clash/core.dart';
import '../clash/lib.dart';
import '../clash/ohos.dart';

typedef NativeEventCallback = Future<void> Function(String method, dynamic arguments);

class Service {
  static final Service _instance = Service._internal();
  final MethodChannel methodChannel = const MethodChannel('service');

  final List<NativeEventCallback> _nativeEventCallbacks = [];

  Service._internal() {
    methodChannel.setMethodCallHandler(_handleMethodCall);
  }

  factory Service() => _instance;

  Future<dynamic> _handleMethodCall(MethodCall call) async {
    if (call.method == 'runStateChanged') {
      final state = call.arguments as String?;
      if (state == 'STOP') {
        globalState.startTime = null;
        globalState.appState = globalState.appState.copyWith(runTime: null);
      }
    } else if (call.method == 'networkChanged' && system.isOhos) {
      // 物理网络变化：鸿蒙端没有 dnsChanged 事件，这里主动把新的系统 DNS 推给核心
      unawaited(pushSystemDns());
    }
    for (final callback in _nativeEventCallbacks) {
      await callback(call.method, call.arguments);
    }
  }

  void addNativeEventCallback(NativeEventCallback callback) {
    _nativeEventCallbacks.add(callback);
  }

  void removeNativeEventCallback(NativeEventCallback callback) {
    _nativeEventCallbacks.remove(callback);
  }

  Future<bool?> init() => methodChannel.invokeMethod<bool>('init');

  Future<bool?> destroy() => methodChannel.invokeMethod<bool>('destroy');

  /// 启动中的 VPN 请求：并发/重复点击时复用同一次结果。
  ///
  /// 鸿蒙端每次启动都会新建一个 tun 桥接 socket，并把路径下发给 VPN 扩展；
  /// 如果重复启动，后一次会关掉前一次仍在等待 fd 的 socket，扩展再投递必然失败
  ///（日志：[TUN Bridge] Accept error: use of closed network connection）。
  Future<bool?>? _startingVpn;

  Future<bool?> startVpn() {
    final existing = _startingVpn;
    if (existing != null) {
      commonPrint.log('startVpn already in progress, reuse in-flight result');
      return existing;
    }
    late final Future<bool?> future;
    future = _startVpnInternal().whenComplete(() {
      if (identical(_startingVpn, future)) {
        _startingVpn = null;
      }
    });
    _startingVpn = future;
    return future;
  }


  Future<bool?> _startVpnInternal() async {
    final options = await clashCore.getAndroidVpnOptions();
    String sockPath = '';
    if (system.isOhos) {
      final stamp = DateTime.now().millisecondsSinceEpoch;
      // 只用抽象命名空间 socket（@name，无文件 inode）：
      // 真机实测 release 下 VPN 扩展处于隔离 SELinux 域，文件型 socket 的
      // connect 一律 EACCES(-13)，只有抽象 socket 能完成 TUN fd 交接。
      sockPath = '@bettbox_tun_$stamp';
      final ret = ClashOhosLib().listenTunBridge(sockPath);
      commonPrint.log('listenTunBridge($sockPath) ret=$ret');
      if (ret != 0) {
        // 监听失败就没人能接收 tun fd，继续启动只会得到一个「假连接」
        commonPrint.log('listenTunBridge failed with code $ret');
        return false;
      }
    }

    dynamic result;
    try {
      result = await methodChannel.invokeMethod('startVpn', {
        'data': json.encode(options),
        'sockPath': sockPath,
      });
    } catch (e) {
      // 鸿蒙原生启动失败会走 PlatformException，同时经 'vpnStartFailed' 事件通知状态回滚
      commonPrint.log('startVpn error: $e');
      return false;
    }
    if (system.isOhos) {
      // 鸿蒙原生返回的是 vNIC 的 fd；0/1/2 是标准输入输出，不可能是有效 fd
      if (result is int) {
        return result > 2;
      }
      return false;
    }
    return result != null && result != false;
  }

  Future<bool?> stopVpn() async {
    // 停止时取消「启动中」标记：允许随后立即重新启动
    _startingVpn = null;
    if (system.isOhos) {
      ClashOhosLib().stopTun();
    }
    return await methodChannel.invokeMethod<bool>('stopVpn');
  }

  /// 拉取设备当前（物理网络）的 DNS 并推给核心。
  ///
  /// Android 端由 VpnPlugin 的 NetworkCallback 主动下发 `dnsChanged` 事件；
  /// 鸿蒙端核心的 `system` 解析器（core/Clash.Meta/dns/patch_ohos.go）只能靠这里填充。
  /// 不填充时 mihomo 会退回内置的 114.114.114.114:53 + 8.8.8.8:53
  /// （core/Clash.Meta/dns/system.go），被墙域名会解析到污染地址，
  /// 表现为部分网站 TLS 握手/证书失败。
  Future<void> pushSystemDns() async {
    if (!system.isOhos) {
      return;
    }
    try {
      final dns = await methodChannel.invokeMethod<String>('getSystemDns');
      if (dns == null || dns.isEmpty) {
        return;
      }
      await ClashOhosLib().updateDns(dns);
      commonPrint.log('pushSystemDns: $dns');
    } catch (e) {
      commonPrint.log('pushSystemDns error: $e');
    }
  }

  Future<bool?> smartStop() => methodChannel.invokeMethod<bool>('smartStop');

  Future<bool?> smartResume() async {
    final options = await clashLib?.getAndroidVpnOptions();
    return await methodChannel.invokeMethod<bool>('smartResume', {
      'data': json.encode(options),
    });
  }

  Future<void> setSmartStopped(bool value) async {
    await methodChannel.invokeMethod<bool>('setSmartStopped', {'value': value});
  }

  Future<bool> isSmartStopped() async {
    return await methodChannel.invokeMethod<bool>('isSmartStopped') ?? false;
  }

  Future<List<String>> getLocalIpAddresses() async {
    return await methodChannel.invokeListMethod<String>(
          'getLocalIpAddresses',
        ) ??
        const [];
  }

  Future<List<String>> getLocalGateways() async {
    return await methodChannel.invokeListMethod<String>(
          'getLocalGateways',
        ) ??
        const [];
  }

  Future<String?> getCurrentDns() =>
      methodChannel.invokeMethod<String>('getCurrentDns');


  Future<bool?> setQuickResponse(bool enabled) async {
    return await methodChannel.invokeMethod<bool>('setQuickResponse', {
      'enabled': enabled,
    });
  }

  Future<bool> isServiceEngineRunning() async {
    return await methodChannel.invokeMethod<bool>('isServiceEngineRunning') ?? false;
  }

  Future<bool> getStatus() async {
    return await methodChannel.invokeMethod<bool>('status') ?? false;
  }

  Future<void> updateNotificationSpeed(String profileName, String speedInfo) async {
    await methodChannel.invokeMethod<void>('updateNotificationSpeed', {
      'profileName': profileName,
      'speedInfo': speedInfo,
    });
  }

  Future<void> restoreNotification() async {
    await methodChannel.invokeMethod<void>('restoreNotification');
  }

  Future<bool?> setHighPriorityNotification(bool enabled) async {
    return await methodChannel.invokeMethod<bool>('setHighPriorityNotification', {
      'enabled': enabled,
    });
  }

  Future<bool?> reconnectIpc() => methodChannel.invokeMethod<bool>('reconnectIpc');
}

Service? get service =>
    (system.isAndroid || system.isOhos) && !globalState.isService ? Service() : null;
