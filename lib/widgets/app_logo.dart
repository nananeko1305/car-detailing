import 'dart:math' as math;

import 'package:flutter/material.dart';

/// The app icon, drawn: a pearl hexagon with water beads on graphite. The same
/// drawing as `assets/icon/logo.svg`, so it stays sharp at any size.
class AppLogo extends StatelessWidget {
  const AppLogo({super.key, this.size = 40});

  final double size;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(size * 0.24),
      child: SizedBox.square(
        dimension: size,
        child: const CustomPaint(painter: _HexPainter()),
      ),
    );
  }
}

class _HexPainter extends CustomPainter {
  const _HexPainter();

  static const _pearl = [
    Color(0xFFA795FF),
    Color(0xFF79DCEB),
    Color(0xFFBDF6DC),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    // Drawn on a 180-unit square, like the SVG.
    canvas.scale(size.width / 180);
    const full = Rect.fromLTWH(0, 0, 180, 180);
    canvas.drawRect(
      full,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF1F2229), Color(0xFF0C0D10)],
        ).createShader(full),
    );
    final hex = Path();
    for (var i = 0; i < 6; i++) {
      final a = math.pi / 3 * i - math.pi / 2;
      final p = Offset(90 + 60 * math.cos(a), 90 + 60 * math.sin(a));
      i == 0 ? hex.moveTo(p.dx, p.dy) : hex.lineTo(p.dx, p.dy);
    }
    hex.close();
    canvas.drawPath(
      hex,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 10
        ..strokeJoin = StrokeJoin.round
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: _pearl,
          stops: [0, 0.55, 1],
        ).createShader(const Rect.fromLTWH(30, 30, 120, 120)),
    );
    for (final b in const [
      (78.0, 84.0, 14.0),
      (106.0, 100.0, 10.0),
      (84.0, 114.0, 7.0),
      (104.0, 74.0, 5.0),
    ]) {
      final r = Rect.fromCircle(center: Offset(b.$1, b.$2), radius: b.$3);
      canvas.drawCircle(
        r.center,
        b.$3,
        Paint()
          ..shader = RadialGradient(
            center: const Alignment(-0.3, -0.4),
            radius: 0.75,
            colors: [
              Colors.white,
              Colors.white.withValues(alpha: 0.35),
              _pearl[1].withValues(alpha: 0.25),
            ],
            stops: const [0, 0.3, 1],
          ).createShader(r),
      );
      canvas.drawCircle(
        r.center,
        b.$3,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1
          ..color = Colors.white.withValues(alpha: 0.25),
      );
    }
  }

  @override
  bool shouldRepaint(_HexPainter oldDelegate) => false;
}
