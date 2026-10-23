import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';

@immutable
class RingSegment {
  final double value;
  final Color color;

  const RingSegment({required this.value, required this.color});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RingSegment && value == other.value && color == other.color;

  @override
  int get hashCode => Object.hash(value, color);
}

class RingChart extends StatelessWidget {
  final List<RingSegment> segments;
  final double? total;
  final Color trackColor;
  final Widget? centerChild;
  final double size;
  final double strokeWidth;

  const RingChart({
    super.key,
    required this.segments,
    required this.trackColor,
    this.total,
    this.centerChild,
    this.size = 76,
    this.strokeWidth = 5.8,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 700),
            curve: Curves.easeOutCubic,
            builder: (context, progress, _) {
              return CustomPaint(
                size: Size(size, size),
                painter: _RingPainter(
                  segments: segments,
                  total: total,
                  trackColor: trackColor,
                  strokeWidth: strokeWidth,
                  progress: progress,
                ),
              );
            },
          ),
          ?centerChild,
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final List<RingSegment> segments;
  final double? total;
  final Color trackColor;
  final double strokeWidth;
  final double progress;

  _RingPainter({
    required this.segments,
    required this.total,
    required this.trackColor,
    required this.strokeWidth,
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..color = trackColor,
    );

    final sum = segments.fold<double>(0, (acc, item) => acc + item.value);
    final fullTotal = max(sum, total ?? 0);
    if (fullTotal <= 0) return;

    final rect = Rect.fromCircle(center: center, radius: radius);
    final visible = segments.where((item) => item.value > 0).length;
    final hasGap = visible > 1;
    final gap = hasGap ? (strokeWidth + 2.5) / radius : 0.0;
    final availableAngle = 2 * pi - gap * (hasGap ? visible : 0);

    var startAngle = -pi / 2 + gap / 2;
    for (final segment in segments) {
      if (segment.value <= 0) continue;
      final sweepAngle = segment.value / fullTotal * availableAngle * progress;
      if (sweepAngle <= 0) continue;
      canvas.drawArc(
        rect,
        startAngle,
        sweepAngle,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.round
          ..color = segment.color,
      );
      startAngle += sweepAngle + gap;
    }
  }

  @override
  bool shouldRepaint(_RingPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.total != total ||
        oldDelegate.trackColor != trackColor ||
        oldDelegate.strokeWidth != strokeWidth ||
        !listEquals(oldDelegate.segments, segments);
  }
}
