import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:question_shared/src/chart_palette.dart';
import 'package:question_shared/src/chart_type.dart';

/// Schematic illustration of a [QuestionChartType], used to pick a chart in
/// the administration and to preview it.
class ChartTypeThumbnail extends StatelessWidget {
  const ChartTypeThumbnail({
    required this.type,
    this.trackColor,
    this.colors = ChartPalette.colors,
    super.key,
  });

  final QuestionChartType type;
  final Color? trackColor;
  final List<Color> colors;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _ThumbnailPainter(
        type: type,
        colors: colors,
        trackColor:
            trackColor ?? Theme.of(context).colorScheme.surfaceContainerHighest,
      ),
    );
  }
}

class _ThumbnailPainter extends CustomPainter {
  const _ThumbnailPainter({
    required this.type,
    required this.colors,
    required this.trackColor,
  });

  final QuestionChartType type;
  final List<Color> colors;
  final Color trackColor;

  static const _fractions = [0.5, 0.3, 0.2];

  Color _color(int index) => colors[index % colors.length];

  @override
  void paint(Canvas canvas, Size size) {
    final bounds = Rect.fromLTWH(
      0,
      0,
      size.width,
      size.height,
    ).deflate(size.shortestSide * 0.1);
    switch (type) {
      case QuestionChartType.donut:
        _paintDonut(canvas, bounds);
      case QuestionChartType.bars:
        _paintBars(canvas, bounds);
      case QuestionChartType.columns:
        _paintColumns(canvas, bounds);
      case QuestionChartType.waffle:
        _paintWaffle(canvas, bounds);
      case QuestionChartType.podium:
        _paintPodium(canvas, bounds);
      case QuestionChartType.bubbles:
        _paintBubbles(canvas, bounds);
      case QuestionChartType.versus:
        _paintVersus(canvas, bounds);
    }
  }

  void _paintDonut(Canvas canvas, Rect bounds) {
    final stroke = bounds.shortestSide * 0.22;
    final radius = bounds.shortestSide / 2 - stroke / 2;
    final rect = Rect.fromCircle(center: bounds.center, radius: radius);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..color = trackColor;
    canvas.drawCircle(bounds.center, radius, paint);
    var start = -math.pi / 2;
    for (final (index, fraction) in _fractions.indexed) {
      final sweep = fraction * 2 * math.pi;
      paint.color = _color(index);
      canvas.drawArc(rect, start + 0.08, sweep - 0.16, false, paint);
      start += sweep;
    }
  }

  void _paintBars(Canvas canvas, Rect bounds) {
    final gap = bounds.height * 0.12;
    final barHeight = (bounds.height - gap * 2) / 3;
    final paint = Paint();
    for (final (index, fraction) in _fractions.indexed) {
      final top = bounds.top + index * (barHeight + gap);
      final track = Rect.fromLTWH(bounds.left, top, bounds.width, barHeight);
      final radius = Radius.circular(barHeight / 2);
      canvas.drawRRect(
        RRect.fromRectAndRadius(track, radius),
        paint..color = trackColor,
      );
      final width = bounds.width * (0.4 + fraction * 1.2);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(bounds.left, top, width, barHeight),
          radius,
        ),
        paint..color = _color(index),
      );
    }
  }

  void _paintColumns(Canvas canvas, Rect bounds) {
    final gap = bounds.width * 0.12;
    final columnWidth = (bounds.width - gap * 2) / 3;
    final paint = Paint();
    final baseline = bounds.bottom;
    for (final (index, fraction) in _fractions.indexed) {
      final height = bounds.height * (0.35 + fraction * 1.3);
      final left = bounds.left + index * (columnWidth + gap);
      canvas.drawRRect(
        RRect.fromRectAndCorners(
          Rect.fromLTRB(left, baseline - height, left + columnWidth, baseline),
          topLeft: Radius.circular(columnWidth / 3),
          topRight: Radius.circular(columnWidth / 3),
        ),
        paint..color = _color(index),
      );
    }
    canvas.drawLine(
      Offset(bounds.left, baseline),
      Offset(bounds.right, baseline),
      paint
        ..color = trackColor
        ..strokeWidth = bounds.height * 0.06,
    );
  }

  void _paintWaffle(Canvas canvas, Rect bounds) {
    const columns = 5;
    final cell = bounds.shortestSide / columns;
    final square = cell * 0.78;
    final origin = Offset(
      bounds.center.dx - cell * columns / 2,
      bounds.center.dy - cell * columns / 2,
    );
    final paint = Paint();
    const counts = [12, 8, 5];
    var filled = 0;
    var segment = 0;
    for (var i = 0; i < columns * columns; i++) {
      while (segment < counts.length && filled >= counts[segment]) {
        segment++;
        filled = 0;
      }
      final column = i % columns;
      final row = columns - 1 - i ~/ columns;
      paint.color = segment < counts.length ? _color(segment) : trackColor;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            origin.dx + column * cell + (cell - square) / 2,
            origin.dy + row * cell + (cell - square) / 2,
            square,
            square,
          ),
          Radius.circular(square * 0.25),
        ),
        paint,
      );
      filled++;
    }
  }

  void _paintPodium(Canvas canvas, Rect bounds) {
    final gap = bounds.width * 0.06;
    final stepWidth = (bounds.width - gap * 2) / 3;
    final paint = Paint();
    // Steps ordered second, first, third as on a real podium.
    const order = [1, 0, 2];
    const heights = [0.62, 0.9, 0.42];
    for (final (slot, entry) in order.indexed) {
      final left = bounds.left + slot * (stepWidth + gap);
      final height = bounds.height * heights[slot] * 0.72;
      final rect = Rect.fromLTRB(
        left,
        bounds.bottom - height,
        left + stepWidth,
        bounds.bottom,
      );
      canvas.drawRRect(
        RRect.fromRectAndCorners(
          rect,
          topLeft: Radius.circular(stepWidth * 0.2),
          topRight: Radius.circular(stepWidth * 0.2),
        ),
        paint..color = _color(entry),
      );
      canvas.drawCircle(
        Offset(rect.center.dx, rect.top - stepWidth * 0.36),
        stepWidth * 0.24,
        paint..color = _color(entry).withValues(alpha: 0.45),
      );
    }
  }

  void _paintBubbles(Canvas canvas, Rect bounds) {
    final unit = bounds.shortestSide;
    final paint = Paint();
    final bubbles = [
      (center: Offset(0.36, 0.5), radius: 0.3, index: 0),
      (center: Offset(0.78, 0.32), radius: 0.19, index: 1),
      (center: Offset(0.76, 0.76), radius: 0.14, index: 2),
    ];
    for (final bubble in bubbles) {
      final center = bounds.topLeft + bubble.center.scale(unit, unit);
      paint.color = _color(bubble.index).withValues(alpha: 0.25);
      canvas.drawCircle(center, bubble.radius * unit, paint);
      paint.color = _color(bubble.index);
      canvas.drawCircle(center, bubble.radius * unit * 0.72, paint);
    }
  }

  void _paintVersus(Canvas canvas, Rect bounds) {
    final barHeight = bounds.height * 0.34;
    final top = bounds.center.dy - barHeight / 2;
    final radius = Radius.circular(barHeight / 2);
    final split = bounds.left + bounds.width * 0.6;
    final gap = bounds.width * 0.03;
    final paint = Paint();
    canvas.drawRRect(
      RRect.fromRectAndCorners(
        Rect.fromLTRB(bounds.left, top, split - gap, top + barHeight),
        topLeft: radius,
        bottomLeft: radius,
      ),
      paint..color = _color(0),
    );
    canvas.drawRRect(
      RRect.fromRectAndCorners(
        Rect.fromLTRB(split + gap, top, bounds.right, top + barHeight),
        topRight: radius,
        bottomRight: radius,
      ),
      paint..color = _color(1),
    );
    final badgeRadius = barHeight * 0.62;
    canvas.drawCircle(
      Offset(split, bounds.center.dy),
      badgeRadius,
      paint..color = trackColor,
    );
    final textPainter = TextPainter(
      text: TextSpan(
        text: 'VS',
        style: TextStyle(
          fontSize: badgeRadius * 0.9,
          fontWeight: FontWeight.w900,
          color: _color(0),
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(
      canvas,
      Offset(split, bounds.center.dy) -
          Offset(textPainter.width / 2, textPainter.height / 2),
    );
  }

  @override
  bool shouldRepaint(_ThumbnailPainter oldDelegate) =>
      type != oldDelegate.type ||
      trackColor != oldDelegate.trackColor ||
      colors != oldDelegate.colors;
}
