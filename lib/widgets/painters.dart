import 'package:flutter/material.dart';
import 'dart:math';

// =============================================================================
// GAUGE PAINTER (Voor Verbruik)
// =============================================================================

class GaugePainter extends CustomPainter {
  final double value; 
  final double max;   
  final double oStart; 
  final double gStart; 
  final bool isDark;

  GaugePainter({required this.value, required this.max, required this.oStart, required this.gStart, required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.95);
    final radius = size.width * 0.45;
    final strokeWidth = size.width * 0.14;

    final paint = Paint()..style = PaintingStyle.stroke..strokeWidth = strokeWidth;

    paint.color = Colors.red.withValues(alpha: 0.6);
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), pi, (oStart / max) * pi, false, paint);

    paint.color = Colors.orange.withValues(alpha: 0.6);
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), pi + (oStart / max) * pi, ((gStart - oStart) / max) * pi, false, paint);

    paint.color = Colors.green.withValues(alpha: 0.6);
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), pi + (gStart / max) * pi, ((max - gStart) / max) * pi, false, paint);

    final tickPaint = Paint()..color = isDark ? Colors.white54 : Colors.black45..style = PaintingStyle.stroke;

    for (int i = 0; i <= max.toInt(); i++) {
      double angle = pi + (i / max) * pi;
      bool isMajor = i % 5 == 0;
      tickPaint.strokeWidth = isMajor ? 1.5 : 0.8;
      double len = isMajor ? 8 : 4;
      
      double innerR = radius + (strokeWidth / 2);
      double outerR = innerR + len;
      
      Offset p1 = Offset(center.dx + innerR * cos(angle), center.dy + innerR * sin(angle));
      Offset p2 = Offset(center.dx + outerR * cos(angle), center.dy + outerR * sin(angle));
      canvas.drawLine(p1, p2, tickPaint);
    }

    final needlePaint = Paint()..color = isDark ? Colors.white : Colors.black..strokeWidth = 2.2..strokeCap = StrokeCap.round;
    double displayVal = value > max ? max : (value < 0 ? 0 : value);
    double needleAngle = pi + (displayVal / max) * pi;
    
    Offset pStart = Offset(center.dx + (radius * 0.45) * cos(needleAngle), center.dy + (radius * 0.45) * sin(needleAngle));
    Offset pEnd = Offset(center.dx + (radius * 1.05) * cos(needleAngle), center.dy + (radius * 1.05) * sin(needleAngle));
    canvas.drawLine(pStart, pEnd, needlePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// =============================================================================
// APK RING PAINTER
// =============================================================================

class ApkRingPainter extends CustomPainter {
  final double progress; 
  final Color color;
  final Color backgroundColor;

  ApkRingPainter({required this.progress, required this.color, required this.backgroundColor});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final strokeWidth = 9.0;
    final radius = min(size.width, size.height) / 2 - (strokeWidth / 2); 

    final bgPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    canvas.drawCircle(center, radius, bgPaint);

    final fgPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), -pi / 2, -(progress * 2 * pi), false, fgPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}