import 'package:flutter/material.dart';
import 'dart:math';

class GaugePainter extends CustomPainter {
  final double value;
  final double max;
  final bool isDark;

  GaugePainter({required this.value, required this.max, required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.8);
    final radius = size.width * 0.45;
    final thickness = 8.0;

    // 1. Achtergrond boog (Spoor)
    final trackPaint = Paint()
      ..color = isDark ? Colors.white10 : Colors.grey.withValues(alpha: 0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = thickness
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), pi, pi, false, trackPaint);

    // 2. Gekleurde voortgang
    final progressPct = (value / (max > 0 ? max : 1)).clamp(0.0, 1.0);
    final progressPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Colors.orange, Colors.greenAccent],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.stroke
      ..strokeWidth = thickness
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), pi, pi * progressPct, false, progressPaint);

    // 3. De Naald (De ijk-aanwijzer)
    final needleAngle = pi + (pi * progressPct);
    final needlePaint = Paint()
      ..color = isDark ? Colors.white : Colors.black87
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    final needleEnd = Offset(center.dx + radius * cos(needleAngle), center.dy + radius * sin(needleAngle));
    canvas.drawLine(center, needleEnd, needlePaint);
    canvas.drawCircle(center, 5, needlePaint);
  }

  @override
  bool shouldRepaint(covariant GaugePainter oldDelegate) => oldDelegate.value != value;
}

class ApkRingPainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color backgroundColor;

  ApkRingPainter({required this.progress, required this.color, required this.backgroundColor});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2;
    const strokeWidth = 5.0;

    canvas.drawCircle(center, radius - strokeWidth, Paint()..color = backgroundColor..style = PaintingStyle.stroke..strokeWidth = strokeWidth);

    final fgPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = strokeWidth;

    canvas.drawArc(Rect.fromCircle(center: center, radius: radius - strokeWidth), -pi / 2, 2 * pi * progress, false, fgPaint);
  }

  @override
  bool shouldRepaint(covariant ApkRingPainter oldDelegate) => oldDelegate.progress != progress;
}