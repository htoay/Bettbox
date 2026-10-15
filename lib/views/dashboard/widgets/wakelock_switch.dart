import 'package:bett_box/common/common.dart';
import 'package:bett_box/plugins/app.dart';
import 'package:bett_box/providers/state.dart';
import 'package:bett_box/state.dart';
import 'package:bett_box/widgets/widgets.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

class WakelockSwitch extends StatelessWidget {
  const WakelockSwitch({super.key});

  Future<void> _toggleWakelock(BuildContext context, bool enabled) async {
    try {
      if (system.isOhos) {
        // 鸿蒙无 wakelock_plus 实现，走原生窗口保持常亮
        await app.setKeepScreenOn(!enabled);
      } else {
        if (enabled) {
          await WakelockPlus.disable();
        } else {
          await WakelockPlus.enable();
        }
      }
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

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: getWidgetHeight(context, 1),
      child: CommonCard(
        info: Info(
          label: appLocalizations.wakelock,
          iconData: Icons.lightbulb_outline,
        ),
        onPressed: () async {
          // click: show function description dialog
          await globalState.showCommonDialog<void>(
            child: CommonDialog(
              title: appLocalizations.wakelock,
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context, rootNavigator: true).pop();
                  },
                  child: Text(appLocalizations.confirm),
                ),
              ],
              child: Text(appLocalizations.wakelockDescription),
            ),
          );
        },
        child: Container(
          padding: baseInfoEdgeInsets.copyWith(top: 4, bottom: 8, right: 8),
          child: Row(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                flex: 1,
                child: TooltipText(
                  text: Text(
                    appLocalizations.switchLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(
                      context,
                    ).textTheme.titleSmall?.adjustSize(-2).toLight,
                  ),
                ),
              ),
              Consumer(
                builder: (_, ref, _) {
                  final wakelockEnabled = ref.watch(wakelockStateProvider);
                  return Switch(
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    value: wakelockEnabled,
                    // 我方鸿蒙改动：_toggleWakelock 需要当前状态（ohos 无 wakelock_plus 查询）
                    onChanged: (_) =>
                        _toggleWakelock(context, wakelockEnabled),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
