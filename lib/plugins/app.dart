import 'dart:async';

import 'package:bett_box/common/app_localizations.dart';
import 'package:bett_box/common/system.dart';
import 'package:bett_box/common/print.dart';
import 'package:bett_box/models/models.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

/// 系统文件选择器返回的文件信息（文件已复制到应用缓存目录）
class PickedFile {
  final String name;
  final String path;

  const PickedFile({required this.name, required this.path});
}

/// 应用自身版本信息（鸿蒙端由原生 bundleManager 提供）
class PackageInfoData {
  final String appName;
  final String packageName;
  final String version;
  final String buildNumber;

  const PackageInfoData({
    required this.appName,
    required this.packageName,
    required this.version,
    required this.buildNumber,
  });
}

class App {
  static App? _instance;
  late MethodChannel methodChannel;
  Function()? onExit;
  Function(String action)? onTrayAction;

  /// 鸿蒙深链回调（clash://install-config?url=…）。
  /// 原生只发「有新的深链」通知，内容由本侧主动 `consumeAppLinks` 取走：
  /// 冷启动时 Dart 监听器还没注册，通知会丢，所以注册回调时也要补取一次。
  void Function(String url)? onAppLink;
  bool _pullingAppLinks = false;

  App._internal() {
    methodChannel = const MethodChannel('app');
    methodChannel.setMethodCallHandler((call) async {
      switch (call.method) {
        case 'exit':
          await onExit?.call();
        case 'trayAction':
          final args = call.arguments;
          final action = args is Map ? args['action'] as String? ?? '' : '';
          await onTrayAction?.call(action);
        case 'appLinkAvailable':
          await _pullAppLinks();
        case 'getText':
          try {
            return Intl.message(call.arguments as String);
          } catch (_) {
            return '';
          }
        default:
          throw MissingPluginException();
      }
    });
  }

  /// 取走原生排队的深链并逐条回调（原生侧消费即清空，重复调用不会重复投递）。
  Future<void> _pullAppLinks() async {
    if (_pullingAppLinks) {
      return;
    }
    _pullingAppLinks = true;
    try {
      final links =
          await methodChannel.invokeListMethod<String>('consumeAppLinks') ??
          const <String>[];
      for (final uri in links) {
        if (uri.isNotEmpty) {
          onAppLink?.call(uri);
        }
      }
    } catch (e) {
      // 非鸿蒙平台没有这个 method，忽略
      commonPrint.warn('appLink pull failed: $e');
    } finally {
      _pullingAppLinks = false;
    }
  }

  void setAppLinkCallback(void Function(String url)? callback) {
    onAppLink = callback;
    if (callback != null) {
      unawaited(_pullAppLinks());
    }
  }

  factory App() {
    _instance ??= App._internal();
    return _instance!;
  }

  Future<bool?> moveTaskToBack() async {
    return await methodChannel.invokeMethod<bool>('moveTaskToBack');
  }

  /// 鸿蒙端打开外部链接（没有 url_launcher 实现，走原生 startAbility）
  Future<bool> openUrl(String url) async {
    if (!system.isOhos) return false;
    return await methodChannel.invokeMethod<bool>('openUrl', {'url': url}) ??
        false;
  }

  /// 鸿蒙端读取应用自身版本（没有 package_info_plus 实现，读 bundle 元数据）
  Future<PackageInfoData?> getPackageInfo() async {
    if (!system.isOhos) return null;
    final raw = await methodChannel.invokeMapMethod<String, dynamic>(
      'getPackageInfo',
    );
    if (raw == null) return null;
    return PackageInfoData(
      appName: (raw['appName'] ?? '').toString(),
      packageName: (raw['packageName'] ?? '').toString(),
      version: (raw['version'] ?? '').toString(),
      buildNumber: (raw['buildNumber'] ?? '').toString(),
    );
  }

  Future<bool> startBackgroundTask({
    List<String>? modes,
    String? taskTitle,
  }) async {
    return await methodChannel.invokeMethod<bool>('startBackgroundTask', {
          'modes': modes ?? const <String>[],
          'taskTitle': taskTitle ?? '',
        }) ??
        false;
  }

  Future<bool> stopBackgroundTask() async {
    return await methodChannel.invokeMethod<bool>('stopBackgroundTask') ?? false;
  }

  Future<List<String>> getBackgroundTaskModes() async {
    final modes = await methodChannel.invokeListMethod<String>(
          'getBackgroundTaskModes',
        ) ??
        const <String>[];
    return modes.map((e) => e.toString()).toList();
  }

  Future<List<Package>> getPackages({bool forceRefresh = false}) async {
    final packagesRaw = await methodChannel.invokeListMethod<Map<dynamic, dynamic>>(
      'getPackages',
      {'forceRefresh': forceRefresh},
    ) ?? const [];
    return packagesRaw
        .map((e) => Package.fromJson(Map<String, Object?>.from(e)))
        .toList();
  }

  Future<bool> hasPackageListPermission() async {
    final result = await methodChannel.invokeMethod<bool>(
      'hasPackageListPermission',
    );
    return result ?? true;
  }

  Future<bool> hasCameraPermission() async {
    final result = await methodChannel.invokeMethod<bool>(
      'hasCameraPermission',
    );
    return result ?? true;
  }

  Future<void> requestPackageListPermission() async {
    await methodChannel.invokeMethod<void>('requestPackageListPermission');
  }

  Future<void> openAppSettings() async {
    await methodChannel.invokeMethod<void>('openAppSettings');
  }

  Future<bool> openFcmDiagnostics() async {
    if (!system.isAndroid) return false;
    return await methodChannel.invokeMethod<bool>('openFcmDiagnostics') ??
        false;
  }

  Future<List<String>> getChinaPackageNames() async {
    final packageNamesRaw =
        await methodChannel.invokeListMethod<String>('getChinaPackageNames') ??
        const [];
    return packageNamesRaw.map((e) => e.toString()).toList();
  }

  Future<Uint8List?> getPackageIcon(
    String packageName, {
    bool forceRefresh = false,
  }) async {
    return await methodChannel.invokeMethod<Uint8List>('getPackageIcon', {
      'packageName': packageName,
      'forceRefresh': forceRefresh,
    });
  }

  /// 鸿蒙端系统文件选择器：path 为应用缓存目录下的可读路径
  Future<List<PickedFile>> pickFiles({
    bool allowMultiple = false,
    List<String>? allowedExtensions,
  }) async {
    final raw = await methodChannel.invokeListMethod<Map<dynamic, dynamic>>(
          'pickFiles',
          {
            'allowMultiple': allowMultiple,
            'allowedExtensions': allowedExtensions ?? const <String>[],
          },
        ) ??
        const [];
    return raw
        .map(
          (e) => PickedFile(
            name: (e['name'] ?? '').toString(),
            path: (e['path'] ?? '').toString(),
          ),
        )
        .where((e) => e.path.isNotEmpty)
        .toList();
  }

  /// 鸿蒙端系统文件保存：返回保存位置 URI，用户取消返回 null
  Future<String?> saveFile(String fileName, Uint8List bytes) async {
    return await methodChannel.invokeMethod<String>('saveFile', {
      'fileName': fileName,
      'bytes': bytes,
    });
  }

  /// PC/2in1：下发状态栏托盘菜单结构（JSON），原生重建菜单
  Future<void> updateTrayMenu(String menuJson) async {
    await methodChannel.invokeMethod<bool>('updateTrayMenu', {
      'menuJson': menuJson,
    });
  }

  /// 鸿蒙端保持屏幕常亮（无 wakelock_plus 实现，走原生窗口接口）
  Future<void> setKeepScreenOn(bool enabled) async {
    await methodChannel.invokeMethod<bool>('setKeepScreenOn', {
      'enabled': enabled,
    });
  }

  Future<bool?> tip(String? message) async {
    if (message == null || message.isEmpty) return false;
    return await methodChannel.invokeMethod<bool>('tip', {
      'message': message,
    });
  }

  Future<bool?> initShortcuts() async {
    return await methodChannel.invokeMethod<bool>(
      'initShortcuts',
      {
        'toggle': appLocalizations.toggle,
        'start': appLocalizations.start,
        'stop': appLocalizations.stop,
      },
    );
  }

  Future<bool?> updateExcludeFromRecents(bool value) async {
    return await methodChannel.invokeMethod<bool>('updateExcludeFromRecents', {
      'value': value,
    });
  }

  Future<int> getSelfLastUpdateTime() async {
    final result = await methodChannel.invokeMethod<int>(
      'getSelfLastUpdateTime',
    );
    return result ?? 0;
  }

  Future<bool> isIgnoringBatteryOptimizations() async {
    final result = await methodChannel.invokeMethod<bool>(
      'isIgnoringBatteryOptimizations',
    );
    return result ?? false;
  }

  Future<void> requestIgnoreBatteryOptimizations() async {
    await methodChannel.invokeMethod<void>('requestIgnoreBatteryOptimizations');
  }

  Future<bool> setLauncherIcon(bool useDarkIcon) async {
    final result = await methodChannel.invokeMethod<bool>('setLauncherIcon', {
      'useDarkIcon': useDarkIcon,
    });
    return result ?? false;
  }

  Future<bool> isAndroidTV() async {
    final result = await methodChannel.invokeMethod<bool>('isAndroidTV');
    return result ?? false;
  }
}

final app = App();
