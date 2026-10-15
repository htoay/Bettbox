import 'dart:async';

import 'package:bett_box/clash/clash.dart';
import 'package:bett_box/common/common.dart';
import 'package:bett_box/state.dart';
import 'package:bett_box/views/connection/connections.dart';
import 'package:bett_box/widgets/widgets.dart';
import 'package:material_ui/material_ui.dart';

class ConnectionsCount extends StatefulWidget {
  const ConnectionsCount({super.key});

  @override
  State<ConnectionsCount> createState() => _ConnectionsCountState();
}

class _ConnectionsCountState extends State<ConnectionsCount> {
  static int? _lastCount;
  int _count = _lastCount ?? 0;
  late final VoidCallback _tickListener;
  Timer? _initTimer;
  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();
    _tickListener = _updateConnections;
    dashboardRefreshManager.tick2s.addListener(_tickListener);
    _initTimer = Timer(const Duration(milliseconds: 1000), _updateConnections);
  }

  @override
  void dispose() {
    _initTimer?.cancel();
    dashboardRefreshManager.tick2s.removeListener(_tickListener);
    super.dispose();
  }

  Future<void> _updateConnections() async {
    if (!mounted) return;
    if (_isUpdating) return;
    _isUpdating = true;

    try {
      // 只要数量：走轻量接口，避免每 2s 建一个 isolate 反序列化整份连接列表
      final count = await clashCore.getConnectionsCount();
      _lastCount = count;
      if (mounted) {
        setState(() {
          _count = count;
        });
      }
    } catch (e) {
      // Ignore error, keep current value
    } finally {
      _isUpdating = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: getWidgetHeight(context, 1),
      child: CommonCard(
        info: Info(
          iconData: Icons.cable_rounded,
          label: appLocalizations.connection,
        ),
        onPressed: () {
          showExtend(
            context,
            builder: (_, type) {
              return const ConnectionsView(respectCurrentPage: false);
            },
          );
        },
        child: Container(
          padding: baseInfoEdgeInsets.copyWith(top: 0),
          child: Align(
            alignment: Alignment.bottomLeft,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  '$_count',
                  style: context.textTheme.bodyLarge?.toLight.adjustSize(2),
                ),
                const SizedBox(width: 4),
                Text(
                  ' Connections',
                  style: context.textTheme.bodyMedium?.toLight.adjustSize(0),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
