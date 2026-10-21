import 'dart:math';
import 'package:flutter/material.dart';

class GraphSegment {
  final double value;
  final Color color;
  GraphSegment({required this.value, required this.color});
}

class MultiSegmentGraphPainter extends CustomPainter {
  final List<GraphSegment> segments;
  final double total;
  final double strokeWidth;
  final Color backgroundColor;

  MultiSegmentGraphPainter({
    required this.segments,
    required this.total,
    required this.backgroundColor,
    this.strokeWidth = 8.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromCircle(
        center: size.center(Offset.zero),
        radius: size.width / 2 - strokeWidth / 2);

    if (total <= 0) {
      final bgPaint = Paint()
        ..color = backgroundColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;
      canvas.drawCircle(rect.center, rect.width / 2, bgPaint);
      return;
    }

    double startAngle = -pi / 2;
    double radius = size.width / 2 - strokeWidth / 2;

    final activeSegments = segments.where((s) => s.value > 0).toList();

    if (activeSegments.isEmpty) {
      final bgPaint = Paint()
        ..color = backgroundColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;
      canvas.drawCircle(rect.center, rect.width / 2, bgPaint);
      return;
    }

    // arc-length gap = strokeWidth (caps) + 1px visible white space between them.
    // This gives rounded ends with a small clean separation like the design.
    final double gapRadians =
        activeSegments.length > 1 ? ((strokeWidth + 1.0) / radius) : 0.0;

    double actualTotal =
        activeSegments.fold(0.0, (sum, item) => sum + item.value);
    double renderTotal = max(total, actualTotal);

    for (var segment in activeSegments) {
      final sweepAngle = (segment.value / renderTotal) * 2 * pi;

      final paint = Paint()
        ..color = segment.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      double actualSweep = sweepAngle - gapRadians;
      if (actualSweep <= 0) {
        actualSweep = 0.01;
      }

      canvas.drawArc(
        rect,
        startAngle + (gapRadians / 2),
        actualSweep,
        false,
        paint,
      );

      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
