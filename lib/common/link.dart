import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:bett_box/common/system.dart';
import 'package:bett_box/plugins/app.dart';

import 'print.dart';

typedef InstallConfigCallBack = void Function(String url);

class LinkManager {
  static LinkManager? _instance;
  late AppLinks _appLinks;
  StreamSubscription? subscription;
  InstallConfigCallBack? _installConfigCallBack;
  /// 深链在回调注册前到达时先存一条，注册后补发（冷启动由深链拉起的场景）
  String? _pendingUri;

  LinkManager._internal() {
    _appLinks = AppLinks();
  }

  Future<void> initAppLinksListen(
    Function(String url) installConfigCallBack,
  ) async {
    _installConfigCallBack = installConfigCallBack;
    if (system.isOhos) {
      // 鸿蒙没有 app_links 实现：深链由 EntryAbility 把 want.uri 经 'app' 通道推过来
      //（见 ohos/entry/src/main/ets/entryability/EntryAbility.ets 与
      // ohos/entry/src/main/ets/plugins/AppPlugin.ets 的 deliverAppLink），
      // 这里接上回调，并把原生/本地缓存的最后一条补发掉。
      app.setAppLinkCallback(_handleUriString);
      final pending = _pendingUri;
      _pendingUri = null;
      if (pending != null) {
        _handleUriString(pending);
      }
      return;
    }
    try {
      commonPrint.log('initAppLinksListen');
      destroy();
      subscription = _appLinks.uriLinkStream.listen(
        (uri) {
          commonPrint.log('onAppLink: $uri');
          _handleUri(uri);
        },
        onError: (e) {
          commonPrint.log('app_links error: $e');
        },
      );
    } catch (e) {
      commonPrint.log('initAppLinksListen error: $e');
    }
  }

  /// clash://install-config?url=<订阅地址> ⇒ 把 url 交给导入流程
  void _handleUri(Uri uri) {
    if (uri.host != 'install-config') {
      return;
    }
    final url = uri.queryParameters['url'];
    if (url != null && url.isNotEmpty) {
      _installConfigCallBack?.call(url);
    }
  }

  void _handleUriString(String raw) {
    commonPrint.log('onAppLink: $raw');
    if (_installConfigCallBack == null) {
      _pendingUri = raw;
      return;
    }
    try {
      _handleUri(Uri.parse(raw));
    } catch (e) {
      commonPrint.log('onAppLink parse error: $e');
    }
  }

  void destroy() {
    subscription?.cancel();
    subscription = null;
    // 注意：**不要**在这里把鸿蒙的原生回调置空 —— 置空后到下次 initAppLinksListen
    // 之间到达的深链会被原生取走却没人处理（直接丢），而回调本身在应用生命周期内一直有效。
  }

  factory LinkManager() {
    _instance ??= LinkManager._internal();
    return _instance!;
  }
}

final linkManager = LinkManager();
