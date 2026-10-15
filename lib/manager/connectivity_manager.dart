import 'dart:async';

import 'package:bett_box/common/print.dart';
import 'package:bett_box/common/system.dart';
import 'package:bett_box/plugins/service.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:material_ui/material_ui.dart';

/// 网络变化监听。
///
/// 鸿蒙没有 connectivity_plus 实现（未注册对应插件），直接订阅
/// `Connectivity().onConnectivityChanged` 只会抛 MissingPluginException 并
/// 永远收不到事件；鸿蒙端改由原生 VpnPlugin 经 'service' 通道推送
/// networkChanged（@ohos.net.connection 回调），语义与 Android 一致：
/// 网络切换即清掉旧连接。
class ConnectivityManager extends StatefulWidget {
  final Function(List<ConnectivityResult> results)? onConnectivityChanged;
  final Widget child;

  const ConnectivityManager({
    super.key,
    this.onConnectivityChanged,
    required this.child,
  });

  @override
  State<ConnectivityManager> createState() => _ConnectivityManagerState();
}

class _ConnectivityManagerState extends State<ConnectivityManager> {
  StreamSubscription<List<ConnectivityResult>>? subscription;
  NativeEventCallback? nativeCallback;

  @override
  void initState() {
    super.initState();
    if (system.isOhos) {
      nativeCallback = (String method, dynamic arguments) async {
        if (method == 'networkChanged') {
          widget.onConnectivityChanged?.call(const <ConnectivityResult>[]);
        }
      };
      service?.addNativeEventCallback(nativeCallback!);
      return;
    }
    try {
      subscription = Connectivity().onConnectivityChanged.listen((results) {
        widget.onConnectivityChanged?.call(results);
      });
    } catch (e) {
      commonPrint.log('Connectivity listen error: $e');
    }
  }

  @override
  void dispose() {
    subscription?.cancel();
    final callback = nativeCallback;
    if (callback != null) {
      service?.removeNativeEventCallback(callback);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
