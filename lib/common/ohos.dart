import 'dart:async';
import 'dart:convert';

import 'package:bett_box/common/app_localizations.dart';
import 'package:bett_box/common/print.dart';
import 'package:bett_box/enum/enum.dart';
import 'package:bett_box/models/models.dart';
import 'package:bett_box/plugins/app.dart';
import 'package:bett_box/providers/state.dart';
import 'package:bett_box/state.dart';
import 'package:bett_box/views/proxies/common.dart';
import 'package:intl/intl.dart';

import 'system.dart';

/// PC/2in1 状态栏托盘菜单（Desktop Extension Kit）。
///
/// 菜单是快照式的：每次状态变化把整份菜单结构下发给原生重建；菜单项动作
/// 通过 menuCode 事件回传（`app.onTrayAction`），在这里分发到具体业务。
class Ohos {
  Timer? _debounce;

  /// 菜单动作编码（与原生 menuCode、Dart 分发一一对应）
  static const _codeToggleProxy = 'toggleProxy';
  static const _codeModePrefix = 'mode:';
  static const _codeProxyPrefix = 'proxy:';
  static const _codeDelayTestPrefix = 'delayTest:';
  static const _codeRestartCore = 'restartCore';
  static const _codeWakelock = 'wakelock';

  /// 系统限制：单个一级项最多 20 个二级项，留给「延迟测试」一项
  static const _maxNodesPerGroup = 19;

  /// 系统限制：所有分组的一级项总和不超过 20，这里预留余量
  static const _maxGroups = 12;

  Future<void> init() async {
    app.onTrayAction = _handleAction;
  }

  /// 状态变化时重建状态栏菜单（防抖，避免频繁调用系统接口）
  void updateTrayMenu(TrayState state) {
    if (!system.isOhos) {
      return;
    }
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      unawaited(_sendMenu(state));
    });
  }

  Future<void> _sendMenu(TrayState state) async {
    try {
      // 原生 StatusBarTray 的契约是 { groups: [...] }，此前直接下发数组，
      // 导致 spec.groups 为 undefined、菜单重建每次抛错（托盘菜单永不更新）
      await app.updateTrayMenu(jsonEncode({'groups': _buildMenuSpec(state)}));
    } catch (e) {
      commonPrint.log('Update tray menu error: $e');
    }
  }

  List<Map<String, Object?>> _buildMenuSpec(TrayState state) {
    final groups = <Map<String, Object?>>[];

    groups.add({
      'items': [
        {'label': appLocalizations.show},
        {
          'label':
              state.isStart ? appLocalizations.stop : appLocalizations.start,
          'code': _codeToggleProxy,
        },
      ],
    });

    groups.add({
      'items': Mode.values
          .map(
            (mode) => <String, Object?>{
              'label': Intl.message(mode.name),
              'code': '$_codeModePrefix${mode.name}',
              'selected': mode == state.mode,
            },
          )
          .toList(),
    });

    if (state.trayEnhancement) {
      for (final group in state.groups.take(_maxGroups)) {
        groups.add({
          'items': [_buildGroupItem(state, group)],
        });
      }
    }

    groups.add({
      'items': [
        {'label': appLocalizations.restartCoreTitle, 'code': _codeRestartCore},
        {
          'label': appLocalizations.wakelock,
          'code': _codeWakelock,
          'selected': state.wakelockEnabled,
        },
      ],
    });

    return groups;
  }

  Map<String, Object?> _buildGroupItem(TrayState state, Group group) {
    final appController = globalState.appController;
    final proxies = appController.getSortProxies(
      proxies: group.all,
      sortType: globalState.config.proxiesStyle.sortType,
      testUrl: group.testUrl,
    );
    final selectedName = group.getCurrentSelectedName(
      state.selectedMap[group.name] ?? '',
    );
    final submenu = <Map<String, Object?>>[
      {
        'label': '⚡ ${appLocalizations.startTest}',
        'code': '$_codeDelayTestPrefix${group.name}',
      },
    ];
    for (final proxy in proxies.take(_maxNodesPerGroup)) {
      final delay = appController.getTrayProxyDelay(
        proxyName: proxy.name,
        testUrl: group.testUrl,
      );
      submenu.add({
        'label': _formatProxyLabel(proxy.name, delay),
        'code': '$_codeProxyPrefix${group.name}\u001f${proxy.name}',
        'selected': selectedName == proxy.name,
      });
    }
    return {'label': group.name, 'submenu': submenu};
  }

  /// 菜单不支持副标题，延迟以「名称  123ms」形式拼在标题里
  String _formatProxyLabel(String name, int? delay) {
    if (delay == null) {
      return name;
    }
    if (delay < 0) {
      return '$name  ×';
    }
    if (delay == 0) {
      return '$name  ...';
    }
    return '$name  ${delay}ms';
  }

  Future<void> _handleAction(String action) async {
    final appController = globalState.appController;
    if (action == _codeToggleProxy) {
      await appController.updateStatus(!globalState.isStart);
      return;
    }
    if (action.startsWith(_codeModePrefix)) {
      final name = action.substring(_codeModePrefix.length);
      for (final mode in Mode.values) {
        if (mode.name == name) {
          appController.changeMode(mode);
          return;
        }
      }
      return;
    }
    if (action.startsWith(_codeProxyPrefix)) {
      final parts = action.substring(_codeProxyPrefix.length).split('\u001f');
      if (parts.length == 2) {
        appController.updateCurrentSelectedMap(parts[0], parts[1]);
        await appController.changeProxy(
          groupName: parts[0],
          proxyName: parts[1],
        );
      }
      return;
    }
    if (action.startsWith(_codeDelayTestPrefix)) {
      await _testGroupDelay(action.substring(_codeDelayTestPrefix.length));
      return;
    }
    if (action == _codeRestartCore) {
      await appController.restartCore();
      return;
    }
    if (action == _codeWakelock) {
      await _toggleWakelock();
    }
  }

  Future<void> _testGroupDelay(String groupName) async {
    try {
      final state = globalState.appController.ref.read(trayStateProvider);
      final group = state.groups.firstWhere((group) => group.name == groupName);
      await delayTest(
        group.all,
        testUrl: group.testUrl,
        groupName: group.name,
      );
    } catch (e) {
      commonPrint.log('Tray delay test error: $e');
    } finally {
      // 延迟不进 TrayState，测速结束后主动刷新一次菜单标题
      updateTrayMenu(globalState.appController.ref.read(trayStateProvider));
    }
  }

  Future<void> _toggleWakelock() async {
    final enabled = globalState.appController.ref.read(wakelockStateProvider);
    try {
      // 鸿蒙无 wakelock_plus 实现，走原生窗口保持常亮
      await app.setKeepScreenOn(!enabled);
      if (enabled) {
        globalState.appController.stopWakelockAutoRecovery();
      } else {
        globalState.appController.startWakelockAutoRecovery();
      }
      globalState.updateWakelockState(!enabled);
    } catch (e) {
      commonPrint.log('WakeLock toggle error: $e');
    }
  }
}

final ohos = system.isOhos ? Ohos() : null;
