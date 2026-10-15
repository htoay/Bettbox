import 'package:bett_box/common/common.dart';
import 'package:bett_box/models/models.dart';
import 'package:bett_box/providers/app.dart';
import 'package:bett_box/state.dart';
import 'package:bett_box/widgets/widgets.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class NetworkSpeedSmall extends ConsumerWidget {
  const NetworkSpeedSmall({super.key});

  // Cache as const
  static const _initPoints = [Point(0, 0), Point(1, 0)];

  static List<Point> _getPoints(List<Traffic> traffics) {
    if (traffics.isEmpty) return _initPoints;

    // Pre-allocate array capacity
    final totalLength = traffics.length + _initPoints.length;
    final result = List<Point>.filled(totalLength, Point(0, 0));

    // Assign init points
    result[0] = _initPoints[0];
    result[1] = _initPoints[1];

    // Assign traffic points
    for (int i = 0; i < traffics.length; i++) {
      result[i + 2] = Point((i + 2).toDouble(), traffics[i].speed.toDouble());
    }

    return result;
  }

  static Traffic _getLastTraffic(List<Traffic> traffics) {
    if (traffics.isEmpty) return Traffic();
    return traffics.last;
  }

  static String _formatTrafficValue(TrafficValue tv) {
    final show = tv.trafficValueShow;
    final numStr = show.value >= 100
        ? show.value.fixed(decimals: 1)
        : show.value.fixed(decimals: 2);
    return '$numStr${show.unit.name}';
  }

  static String _getSpeedText(Traffic traffic, bool isMobile) {
    if (isMobile) {
      final total = TrafficValue(value: traffic.up.value + traffic.down.value);
      return '$total ↓↑';
    }
    return '${_formatTrafficValue(traffic.up)}↑ ${_formatTrafficValue(traffic.down)}↓';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isMobile = ref.watch(isMobileViewProvider);
    final primaryColor = Theme.of(context).colorScheme.primary;
    final speedStyle = isMobile
        ? context.textTheme.titleSmall?.copyWith(
            fontSize: 14,
            fontFeatures: const [FontFeature.tabularFigures()],
          )
        : context.textTheme.titleSmall
              ?.adjustSize(-2)
              .copyWith(fontFeatures: const [FontFeature.tabularFigures()]);
    return RepaintBoundary(
      child: SizedBox(
        height: getWidgetHeight(context, 1),
        child: ValueListenableBuilder<int>(
          valueListenable: dashboardRefreshManager.tick1s,
          builder: (_, _, _) {
            final traffics = ref.read(trafficsProvider).list;
            final points = _getPoints(traffics);
            final speedText = _getSpeedText(
              _getLastTraffic(traffics),
              isMobile,
            );
            return CommonCard(
              onPressed: () {
                globalState.openUrl('https://ptclspeed.speedtestcustom.com');
              },
              info: Info(
                label: speedText,
                iconData: Icons.speed_sharp,
                style: speedStyle,
              ),
              child: Padding(
                padding: const EdgeInsets.only(
                  top: 16,
                  left: 0,
                  right: 0,
                  bottom: 0,
                ),
                child: LineChart(
                  gradient: true,
                  color: primaryColor,
                  points: points,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
