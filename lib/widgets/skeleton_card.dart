// Skeleton loader cards voor dashboard laadtoestand
import 'package:flutter/material.dart';

class SkeletonCard extends StatefulWidget {
  final bool isXL; // true = volle breedte, false = M (vierkant)

  const SkeletonCard({super.key, this.isXL = true});

  @override
  State<SkeletonCard> createState() => _SkeletonCardState();
}

class _SkeletonCardState extends State<SkeletonCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE8E8E8);
    final shimmerColor = isDark ? const Color(0xFF3A3A3A) : const Color(0xFFF5F5F5);

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, _) {
        final color = Color.lerp(baseColor, shimmerColor, _animation.value)!;
        return widget.isXL ? _buildXL(color, isDark) : _buildM(color, isDark);
      },
    );
  }

  Widget _buildXL(Color shimmer, bool isDark) {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
            blurRadius: 20,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Titel placeholder
          _bar(shimmer, width: 120, height: 12),
          const SizedBox(height: 16),
          // Grafiek placeholder
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(8, (i) {
                final heights = [0.4, 0.7, 0.5, 0.9, 0.6, 0.8, 0.45, 0.75];
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: FractionallySizedBox(
                      heightFactor: heights[i % heights.length],
                      alignment: Alignment.bottomCenter,
                      child: Container(
                        decoration: BoxDecoration(
                          color: shimmer,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 12),
          // Stats onderaan
          Row(
            children: [
              _bar(shimmer, width: 60, height: 10),
              const SizedBox(width: 16),
              _bar(shimmer, width: 60, height: 10),
              const SizedBox(width: 16),
              _bar(shimmer, width: 60, height: 10),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildM(Color shimmer, bool isDark) {
    return AspectRatio(
      aspectRatio: 1.0,
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
              blurRadius: 20,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _bar(shimmer, width: 80, height: 10),
            const SizedBox(height: 12),
            _bar(shimmer, width: 50, height: 28),
            const Spacer(),
            // Mini sparkline placeholder
            SizedBox(
              height: 40,
              child: CustomPaint(
                painter: _SkeletonSparklinePainter(shimmer),
                size: Size.infinite,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _bar(Color color, {required double width, required double height}) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(6),
      ),
    );
  }
}

class _SkeletonSparklinePainter extends CustomPainter {
  final Color color;
  _SkeletonSparklinePainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final points = [0.5, 0.3, 0.6, 0.2, 0.5, 0.4, 0.3, 0.5];
    final path = Path();
    for (int i = 0; i < points.length; i++) {
      final x = i / (points.length - 1) * size.width;
      final y = points[i] * size.height;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_SkeletonSparklinePainter old) => old.color != color;
}