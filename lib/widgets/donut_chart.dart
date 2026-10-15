import 'dart:math';

import 'package:bett_box/common/common.dart';
import 'package:material_ui/material_ui.dart';

@immutable
class DonutChartData {
  final double _value;
  final Color color;

  const DonutChartData({required double value, required this.color})
    : _value = value + 1;

  double get value => _value;

  @override
  String toString() {
    return 'DonutChartData{_value: $_value}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DonutChartData &&
          runtimeType == other.runtimeType &&
          _value == other._value &&
          color == other.color;

  @override
  int get hashCode => _value.hashCode ^ color.hashCode;
}

class DonutChart extends StatefulWidget {
  final List<DonutChartData> data;
  final Duration duration;
  final Color? trackColor;

  const DonutChart({
    super.key,
    required this.data,
    this.duration = commonDuration,
    this.trackColor,
  });

  @override
  State<DonutChart> createState() => DonutChartState();
}

class DonutChartState extends State<DonutChart> with TickerProviderStateMixin {
  late AnimationController _dataController;
  late AnimationController _entryController;
  late CurvedAnimation _entryAnimation;
  late List<DonutChartData> _oldData;

  @override
  void initState() {
    super.initState();
    _oldData = widget.data;
    _dataController = AnimationController(
      vsync: this,
      duration: widget.duration,
    );
    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _entryAnimation = CurvedAnimation(
      parent: _entryController,
      curve: Curves.easeOutCubic,
    );
    _entryController.forward();
  }

  void replayEntryAnimation() {
    if (!mounted) return;
    _entryController.forward(from: 0);
  }

  @override
  void didUpdateWidget(DonutChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.data != widget.data) {
      _oldData = oldWidget.data;
      _dataController.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _dataController.dispose();
    _entryAnimation.dispose();
    _entryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: Listenable.merge([_dataController, _entryAnimation]),
        builder: (context, child) {
          return CustomPaint(
            painter: DonutChartPainter(
              oldData: _oldData,
              newData: widget.data,
              progress: _dataController.value,
              entryProgress: _entryAnimation.value,
              trackColor: widget.trackColor,
            ),
          );
        },
      ),
    );
  }
}

class DonutChartPainter extends CustomPainter {
  final List<DonutChartData> oldData;
  final List<DonutChartData> newData;
  final double progress;
  final double entryProgress;
  final Color? trackColor;

  DonutChartPainter({
    required this.oldData,
    required this.newData,
    required this.progress,
    required this.entryProgress,
    this.trackColor,
  });

  double _logTransform(double value) {
    const base = 10.0;
    const minValue = 0.1;
    if (value < minValue) return 0;
    return log(value) / log(base) + 1;
  }

  double _expTransform(double value) {
    const base = 10.0;
    if (value <= 0) return 0;
    return pow(base, value - 1).toDouble();
  }

  List<DonutChartData> get interpolatedData {
    if (progress >= 1.0 ||
        oldData == newData ||
        oldData.length != newData.length) {
      return newData;
    }
    return List.generate(newData.length, (index) {
      final oldValue = oldData[index].value;
      final newValue = newData[index].value;
      if (oldValue == newValue) return newData[index];

      final logOldValue = _logTransform(oldValue);
      final logNewValue = _logTransform(newValue);
      final interpolatedLogValue =
          logOldValue + (logNewValue - logOldValue) * progress;

      final interpolatedValue = _expTransform(interpolatedLogValue);

      return DonutChartData(
        value: interpolatedValue,
        color: newData[index].color,
      );
    });
  }

  @override
  void paint(Canvas canvas, Size size) {
    final strokeWidth = 10.0.ap;
    final minSide = min(size.width, size.height);
    if (minSide <= strokeWidth) return;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = (minSide - strokeWidth) / 2;

    final sinArg = (strokeWidth / (2 * radius)) * 1.2;
    if (sinArg >= 1.0) return;
    final gapAngle = 2 * asin(sinArg);

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    final currentTrackColor = trackColor;
    if (currentTrackColor != null) {
      paint.color = currentTrackColor;
      canvas.drawCircle(center, radius, paint);
    }

    final data = interpolatedData;
    final total = data.fold<double>(0, (sum, item) => sum + item.value);

    if (total <= 0 || entryProgress <= 0) return;

    final availableAngle = 2 * pi - (data.length * gapAngle);
    double startAngle = -pi / 2 + gapAngle / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);
    paint.strokeCap = StrokeCap.round;

    for (final item in data) {
      final sweepAngle = availableAngle * (item.value / total) * entryProgress;

      if (sweepAngle <= 0) continue;

      paint.color = item.color;
      canvas.drawArc(rect, startAngle, sweepAngle, false, paint);

      startAngle += sweepAngle + gapAngle;
    }
  }

  @override
  bool shouldRepaint(DonutChartPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.entryProgress != entryProgress ||
        oldDelegate.oldData != oldData ||
        oldDelegate.newData != newData ||
        oldDelegate.trackColor != trackColor;
  }
}
