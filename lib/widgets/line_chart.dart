import 'dart:ui' as ui;

import 'package:bett_box/common/color.dart';
import 'package:material_ui/material_ui.dart';

class Point {
  final double x;
  final double y;

  const Point(this.x, this.y);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is Point && other.x == x && other.y == y);
  }

  @override
  int get hashCode => Object.hash(x, y);
}

bool _pointsEqual(List<Point> a, List<Point> b) {
  if (identical(a, b)) return true;
  final length = a.length;
  if (length != b.length) return false;
  for (var i = 0; i < length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

class LineChart extends StatefulWidget {
  final List<Point> points;
  final Color color;
  final Duration duration;
  final bool gradient;

  const LineChart({
    super.key,
    this.gradient = false,
    required this.points,
    required this.color,
    this.duration = Duration.zero,
  });

  @override
  State<LineChart> createState() => _LineChartState();
}

class _LineChartState extends State<LineChart>
    with SingleTickerProviderStateMixin {
  AnimationController? _controller;
  List<Point> prevPoints = const [];
  List<Point> points = const [];

  bool get _hasAnimation => widget.duration > Duration.zero;

  @override
  void initState() {
    super.initState();
    points = widget.points;
    prevPoints = points;

    if (_hasAnimation) {
      _controller = AnimationController(vsync: this, duration: widget.duration);
    }
  }

  @override
  void didUpdateWidget(LineChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.duration != oldWidget.duration) {
      if (_hasAnimation) {
        final controller = _controller;
        if (controller == null) {
          _controller = AnimationController(
            vsync: this,
            duration: widget.duration,
          );
        } else {
          controller.duration = widget.duration;
        }
      } else {
        _controller?.dispose();
        _controller = null;
      }
    }

    if (!_pointsEqual(widget.points, points)) {
      prevPoints = points;
      points = widget.points;

      if (_hasAnimation) {
        _controller?.forward(from: 0);
      } else {
        setState(() {});
      }
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    if (!_hasAnimation || controller == null) {
      return RepaintBoundary(
        child: CustomPaint(
          painter: LineChartPainter(
            prevPoints: points,
            points: points,
            progress: 1.0,
            gradient: widget.gradient,
            color: widget.color,
            hasAnimation: false,
          ),
          child: const SizedBox.expand(),
        ),
      );
    }

    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: controller.view,
        child: const SizedBox.expand(),
        builder: (_, child) {
          return CustomPaint(
            painter: LineChartPainter(
              prevPoints: prevPoints,
              points: points,
              progress: controller.value,
              gradient: widget.gradient,
              color: widget.color,
              hasAnimation: true,
            ),
            child: child,
          );
        },
      ),
    );
  }
}

class LineChartPainter extends CustomPainter {
  static final Path _strokePath = Path();
  static final Path _fillPath = Path();
  static final Paint _strokePaint = Paint()
    ..strokeWidth = 2.0
    ..style = PaintingStyle.stroke;
  static final Paint _fillPaint = Paint()..style = PaintingStyle.fill;

  static Color? _cachedShaderColor;
  static double _cachedShaderWidth = -1;
  static double _cachedShaderHeight = -1;
  static ui.Shader? _cachedShader;

  final List<Point> prevPoints;
  final List<Point> points;
  final double progress;
  final Color color;
  final bool gradient;
  final bool hasAnimation;

  LineChartPainter({
    required this.prevPoints,
    required this.points,
    required this.progress,
    required this.color,
    required this.gradient,
    this.hasAnimation = true,
  });

  static ui.Shader _resolveShader(Color color, double width, double height) {
    final existing = _cachedShader;
    if (existing != null &&
        _cachedShaderColor == color &&
        _cachedShaderWidth == width &&
        _cachedShaderHeight == height) {
      return existing;
    }
    final shader = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [color.opacity38, color.opacity10],
    ).createShader(Rect.fromLTWH(0, 0, width, height));
    _cachedShaderColor = color;
    _cachedShaderWidth = width;
    _cachedShaderHeight = height;
    _cachedShader = shader;
    return shader;
  }

  List<Point> getRenderPoints(List<Point> points) {
    final length = points.length;
    if (length == 0) return const [];
    double maxX = points[0].x;
    double minX = maxX;
    double maxY = points[0].y;
    double minY = maxY;

    for (var i = 1; i < length; i++) {
      final point = points[i];
      if (point.x > maxX) maxX = point.x;
      if (point.x < minX) minX = point.x;
      if (point.y > maxY) maxY = point.y;
      if (point.y < minY) minY = point.y;
    }

    final spanX = maxX - minX;
    final spanY = maxY - minY;
    final invSpanX = spanX > 0 ? 1.0 / spanX : 0.0;
    final invSpanY = spanY > 0 ? 1.0 / spanY : 0.0;

    return List<Point>.generate(length, (i) {
      final e = points[i];
      return Point(
        spanX > 0 ? (e.x - minX) * invSpanX : 0.0,
        spanY > 0 ? (e.y - minY) * invSpanY : 0.0,
      );
    }, growable: false);
  }

  List<Point> getInterpolatePoints(
    List<Point> prevPoints,
    List<Point> points,
    double t,
  ) {
    final renderPrevPoints = getRenderPoints(prevPoints);
    final renderPoints = getRenderPoints(points);
    final prevLen = renderPrevPoints.length;

    return List<Point>.generate(renderPoints.length, (i) {
      final curr = renderPoints[i];
      if (i >= prevLen) {
        return curr;
      }
      final prev = renderPrevPoints[i];
      return Point(
        prev.x + (curr.x - prev.x) * t,
        prev.y + (curr.y - prev.y) * t,
      );
    }, growable: false);
  }

  static void _writeNormalizedPointsToPath(
    Path target,
    List<Point> normalizedPoints,
    Size size,
  ) {
    target.reset();
    final length = normalizedPoints.length;
    if (length == 0) return;

    final width = size.width;
    final height = size.height;
    final first = normalizedPoints[0];
    target.moveTo(first.x * width, (1.0 - first.y) * height);

    for (var i = 1; i < length - 1; i++) {
      final currentPoint = normalizedPoints[i];
      final nextPoint = normalizedPoints[i + 1];
      final midX = (currentPoint.x + nextPoint.x) * 0.5;
      final midY = (currentPoint.y + nextPoint.y) * 0.5;

      target.quadraticBezierTo(
        currentPoint.x * width,
        (1.0 - currentPoint.y) * height,
        midX * width,
        (1.0 - midY) * height,
      );
    }

    final last = normalizedPoints[length - 1];
    target.lineTo(last.x * width, (1.0 - last.y) * height);
  }

  static void _writeDirectPointsToPath(
    Path target,
    List<Point> rawPoints,
    Size size,
  ) {
    target.reset();
    final length = rawPoints.length;
    if (length == 0) return;

    double maxX = rawPoints[0].x;
    double minX = maxX;
    double maxY = rawPoints[0].y;
    double minY = maxY;

    for (var i = 1; i < length; i++) {
      final point = rawPoints[i];
      if (point.x > maxX) maxX = point.x;
      if (point.x < minX) minX = point.x;
      if (point.y > maxY) maxY = point.y;
      if (point.y < minY) minY = point.y;
    }

    final spanX = maxX - minX;
    final spanY = maxY - minY;
    final invSpanX = spanX > 0 ? 1.0 / spanX : 0.0;
    final invSpanY = spanY > 0 ? 1.0 / spanY : 0.0;
    final width = size.width;
    final height = size.height;

    double mapX(Point p) => (spanX > 0 ? (p.x - minX) * invSpanX : 0.0) * width;
    double mapY(Point p) =>
        (1.0 - (spanY > 0 ? (p.y - minY) * invSpanY : 0.0)) * height;

    final first = rawPoints[0];
    target.moveTo(mapX(first), mapY(first));

    if (length > 2) {
      var currX = mapX(rawPoints[1]);
      var currY = mapY(rawPoints[1]);
      for (var i = 1; i < length - 1; i++) {
        final next = rawPoints[i + 1];
        final nextX = mapX(next);
        final nextY = mapY(next);
        target.quadraticBezierTo(
          currX,
          currY,
          (currX + nextX) * 0.5,
          (currY + nextY) * 0.5,
        );
        currX = nextX;
        currY = nextY;
      }
    }

    final last = rawPoints[length - 1];
    target.lineTo(mapX(last), mapY(last));
  }

  Path getPath(List<Point> points, Size size) {
    final path = Path();
    _writeNormalizedPointsToPath(path, points, size);
    return path;
  }

  Path getAnimatedPath(Size size) {
    final interpolatedPoints = getInterpolatePoints(
      prevPoints,
      points,
      progress,
    );
    return getPath(interpolatedPoints, size);
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty || size.isEmpty) return;

    const strokeWidth = 2.0;
    final chartSize = Size(size.width, size.height * 0.7);

    if (!hasAnimation || progress >= 1.0) {
      _writeDirectPointsToPath(_strokePath, points, chartSize);
    } else {
      final interpolatedPoints = getInterpolatePoints(
        prevPoints,
        points,
        progress,
      );
      _writeNormalizedPointsToPath(_strokePath, interpolatedPoints, chartSize);
    }

    if (gradient) {
      final bottomY = size.height + strokeWidth * 2;
      _fillPath
        ..reset()
        ..addPath(_strokePath, Offset.zero)
        ..lineTo(size.width, bottomY)
        ..lineTo(0, bottomY)
        ..close();

      _fillPaint.shader = _resolveShader(color, size.width, bottomY);
      canvas.drawPath(_fillPath, _fillPaint);
    }

    _strokePaint.color = color;
    canvas.drawPath(_strokePath, _strokePaint);
  }

  @override
  bool shouldRepaint(covariant LineChartPainter oldDelegate) {
    if (oldDelegate.progress != progress ||
        oldDelegate.color != color ||
        oldDelegate.gradient != gradient ||
        oldDelegate.hasAnimation != hasAnimation) {
      return true;
    }
    if (!_pointsEqual(oldDelegate.points, points)) {
      return true;
    }
    if (hasAnimation && progress < 1.0) {
      return !_pointsEqual(oldDelegate.prevPoints, prevPoints);
    }
    return false;
  }
}
