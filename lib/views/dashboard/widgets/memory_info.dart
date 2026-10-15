import 'dart:async';

import 'package:bett_box/clash/clash.dart';
import 'package:bett_box/common/common.dart';
import 'package:bett_box/models/common.dart';
import 'package:bett_box/state.dart';
import 'package:bett_box/widgets/widgets.dart';
import 'package:material_ui/material_ui.dart';

import 'core_status_dialog.dart';

class MemoryInfo extends StatefulWidget {
  const MemoryInfo({super.key});

  @override
  State<MemoryInfo> createState() => _MemoryInfoState();
}

class _MemoryInfoState extends State<MemoryInfo> {
  late final VoidCallback _tickListener;
  // Cache last memory value to avoid showing 0 on rebuild
  static TrafficValue _lastMemoryValue = TrafficValue(value: 0);
  TrafficValue _memoryValue = _lastMemoryValue;
  Timer? _initTimer;
  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();
    _tickListener = _updateMemory;
    dashboardRefreshManager.tick2s.addListener(_tickListener);

    // Get immediately on first open, otherwise delay 1000ms
    if (_lastMemoryValue.value == 0) {
      _retryUpdateMemory();
    } else {
      // Has cached value, delay
      _initTimer = Timer(const Duration(milliseconds: 1000), _updateMemory);
    }
  }

  Future<void> _retryUpdateMemory() async {
    for (int i = 0; i < 5; i++) {
      if (!mounted) return;
      await _updateMemory();
      if (_memoryValue.value > 0) break;
      await Future.delayed(const Duration(milliseconds: 500));
    }
  }

  @override
  void dispose() {
    _initTimer?.cancel();
    dashboardRefreshManager.tick2s.removeListener(_tickListener);
    super.dispose();
  }

  Future<void> _updateMemory() async {
    if (!mounted) return;
    if (_isUpdating) return;
    _isUpdating = true;

    try {
      final memoryValue = await clashCore.getMemory();
      // Update only if valid (non-zero)
      if (memoryValue > 0) {
        final adjustedValue = memoryValue;

        if (mounted) {
          setState(() {
            _memoryValue = TrafficValue(value: adjustedValue);
            _lastMemoryValue = _memoryValue; // Cache latest valid value
          });
        }
      }
      // If 0, keep last valid value
    } catch (e) {
      // Ignore error, keep current value
    } finally {
      _isUpdating = false;
    }
  }

  Future<void> _showMemoryInfoDialog(BuildContext context) async {
    await globalState.showCommonDialog<void>(
      child: CommonDialog(
        title: appLocalizations.memoryInfo,
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context, rootNavigator: true).pop();
            },
            child: Text(appLocalizations.confirm),
          ),
        ],
        child: Text(appLocalizations.memoryInfoDesc),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: getWidgetHeight(context, 1),
      child: CommonCard(
        onPressed: () => showCoreStatusDialog(context),
        onLongPress: () async {
          // Show confirmation dialog
          final result = await globalState.showCommonDialog<bool>(
            child: CommonDialog(
              title: appLocalizations.forceGCTitle,
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context, rootNavigator: true).pop(false);
                  },
                  child: Text(appLocalizations.cancel),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context, rootNavigator: true).pop(true);
                  },
                  child: Text(appLocalizations.confirm),
                ),
              ],
              child: Text(appLocalizations.forceGCDesc),
            ),
          );

          // Execute force GC after user confirms
          if (result == true) {
            await clashCore.requestGc(forceFreeOSMemory: true);
            globalState.showNotifier(appLocalizations.success);
          }
        },
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              height: globalState.measure.titleMediumHeight + 16,
              padding: baseInfoEdgeInsets.copyWith(bottom: 0),
              child: Row(
                mainAxisSize: MainAxisSize.max,
                children: [
                  Icon(
                    Icons.memory,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    flex: 1,
                    child: TooltipText(
                      text: Text(
                        appLocalizations.memoryInfo,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: context.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 2),
                  AspectRatio(
                    aspectRatio: 1,
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      onPressed: () => _showMemoryInfoDialog(context),
                      icon: Icon(
                        size: 16.ap,
                        Icons.info_outline,
                        color: context.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: baseInfoEdgeInsets.copyWith(top: 0),
              child: Column(
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    height: globalState.measure.bodyMediumHeight + 2,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Text(
                          _memoryValue.showValue,
                          style: context.textTheme.bodyMedium?.toLight
                              .adjustSize(1),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _memoryValue.showUnit,
                          style: context.textTheme.bodyMedium?.toLight
                              .adjustSize(1),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
