import 'package:bett_box/common/common.dart';
import 'package:bett_box/providers/state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

/// PC/2in1：监听托盘状态并同步状态栏菜单。
///
/// 鸿蒙没有 tray_manager 插件，状态栏图标由原生 `StatusBarTray` 接入，
/// 这里复用桌面端相同的 `trayStateProvider` 状态流把菜单结构下发给原生。
class OhosTrayManager extends ConsumerStatefulWidget {
  final Widget child;

  const OhosTrayManager({super.key, required this.child});

  @override
  ConsumerState<OhosTrayManager> createState() => _OhosTrayManagerState();
}

class _OhosTrayManagerState extends ConsumerState<OhosTrayManager> {
  @override
  void initState() {
    super.initState();
    ref.listenManual(trayStateProvider, (prev, next) {
      if (prev != next) {
        ohos?.updateTrayMenu(next);
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ohos?.updateTrayMenu(ref.read(trayStateProvider));
    });
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
