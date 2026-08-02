/// 클리어 축하 꽃가루. 외부 패키지 없이 CustomPainter로만 그린다.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme.dart';

class ConfettiOverlay extends StatelessWidget {
  final Animation<double> progress;
  const ConfettiOverlay({required this.progress, super.key});

  @override
  Widget build(BuildContext context) => IgnorePointer(
        child: AnimatedBuilder(
          animation: progress,
          builder: (context, _) => CustomPaint(
            size: Size.infinite,
            painter: _ConfettiPainter(progress.value),
          ),
        ),
      );
}

class _ConfettiPainter extends CustomPainter {
  final double t;
  _ConfettiPainter(this.t);

  static const _colors = [
    PiyakColors.starYellow,
    PiyakColors.blush,
    PiyakColors.iceBlue,
    PiyakColors.grass,
  ];

  @override
  void paint(Canvas canvas, Size size) {
    if (t <= 0) return;
    // 고정 시드 — 매 프레임 같은 궤적이어야 조각이 떨지 않는다.
    final rng = math.Random(7);
    final origin = Offset(size.width / 2, size.height * 0.38);
    for (var i = 0; i < 28; i++) {
      final angle = rng.nextDouble() * math.pi * 2;
      final speed = 90 + rng.nextDouble() * 190;
      final spin = rng.nextDouble() * math.pi;
      final color = _colors[i % _colors.length];
      final dx = math.cos(angle) * speed * t;
      final dy = math.sin(angle) * speed * t + 320 * t * t; // 중력
      final p = origin + Offset(dx, dy);
      final fade = (1.0 - t).clamp(0.0, 1.0);
      canvas.save();
      canvas.translate(p.dx, p.dy);
      canvas.rotate(spin + t * 6);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset.zero, width: 9, height: 6),
          const Radius.circular(2),
        ),
        Paint()..color = color.withValues(alpha: fade),
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) => old.t != t;
}
