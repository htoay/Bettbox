import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import 'num.dart';

const double dashboardCellCrossAxisCount = 4;
const double dashboardMaxGridWidth = 1120.0;
const double baseUnitHeight = 84.0;
const double maxUnitHeight = 100.0;
const double minContentWidth = 560.0;
const double maxContentWidth = 1120.0;

enum DashboardGridBand {
  compact(columns: 8),
  medium(columns: 12),
  wide(columns: 16);

  static const double _mediumBreakpoint = 520.0;
  static const double _wideBreakpoint = 880.0;

  final int columns;

  const DashboardGridBand({required this.columns});

  static DashboardGridBand of(double gridWidth) {
    if (gridWidth < _mediumBreakpoint) return compact;
    if (gridWidth <= _wideBreakpoint) return medium;
    return wide;
  }
}

/// Dynamically calculates the unit row height balancing card proportions with viewport capacity.
///
/// Ensures that:
/// 1. Standard base height remains at [baseUnitHeight] (84dp).
/// 2. In height-constrained scenarios (tablets, laptops, or standard 620dp desktop windows),
///    unit height stays compact (<= 86dp) so that 5 rows comfortably fit on screen without vertical scrolling.
/// 3. Only when vertical space is genuinely ample does it gently scale up to [maxUnitHeight] (90dp).
double dashboardUnitHeight(
  double contentWidth, {
  double? availableHeight,
  double spacing = 12.0,
  double verticalPadding = 32.0,
}) {
  final widthProgress =
      ((contentWidth - minContentWidth) / (maxContentWidth - minContentWidth))
          .clamp(0.0, 1.0);
  final widthBasedHeight =
      baseUnitHeight + widthProgress * (maxUnitHeight - baseUnitHeight);

  if (availableHeight != null &&
      availableHeight.isFinite &&
      availableHeight > 0) {
    final usableHeight = availableHeight - verticalPadding;
    // Budget required for 5 full rows without scrolling:
    // 5 * unitHeight + 4 * spacing <= usableHeight => unitHeight <= (usableHeight - 4 * spacing) / 5
    if (usableHeight > 0) {
      final fiveRowsMaxUnitHeight = (usableHeight - 4 * spacing) / 5;
      if (fiveRowsMaxUnitHeight > 0) {
        // Clamp between baseUnitHeight and widthBasedHeight to ensure 5 rows fit if possible,
        // without shrinking below baseUnitHeight (84dp).
        final target = math.max(
          baseUnitHeight,
          math.min(widthBasedHeight, fiveRowsMaxUnitHeight),
        );
        return target.ap.roundToDouble();
      }
    }
  }

  return widthBasedHeight.ap.roundToDouble();
}

class DashboardWidgetMetrics extends InheritedWidget {
  final double unitHeight;
  final double spacing;
  final int columns;

  const DashboardWidgetMetrics({
    super.key,
    required this.unitHeight,
    required this.spacing,
    required this.columns,
    required super.child,
  });

  static DashboardWidgetMetrics? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<DashboardWidgetMetrics>();
  }

  static double unitHeightOf(BuildContext context) {
    return maybeOf(context)?.unitHeight ?? baseUnitHeight.ap;
  }

  static double spacingOf(BuildContext context) {
    return maybeOf(context)?.spacing ?? 12.mAp;
  }

  static int columnsOf(BuildContext context) {
    return maybeOf(context)?.columns ?? 8;
  }

  static double heightOf(BuildContext context, num lines) {
    final metrics = maybeOf(context);
    final unitHeight = metrics?.unitHeight ?? baseUnitHeight.ap;
    final spacing = metrics?.spacing ?? 12.mAp;
    if (lines <= 1) {
      return math.max(lines * unitHeight, 0);
    }
    return math.max(lines * (unitHeight + spacing) - spacing, 0);
  }

  @override
  bool updateShouldNotify(DashboardWidgetMetrics oldWidget) {
    return unitHeight != oldWidget.unitHeight ||
        spacing != oldWidget.spacing ||
        columns != oldWidget.columns;
  }
}

double getWidgetHeight(BuildContext context, num lines) {
  return DashboardWidgetMetrics.heightOf(context, lines);
}
