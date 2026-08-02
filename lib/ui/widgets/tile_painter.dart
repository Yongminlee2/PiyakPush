/// 보드 바닥층 페인터. 타일 전부를 한 번에 그린다 (알·병아리는 BoardView의 위 레이어).
///
/// 모든 도형은 진갈색 외곽선 + 파스텔 채움 — 기존 삐약 에셋과 톤 일치.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../engine/board.dart';
import '../../engine/geometry.dart';
import '../../engine/move.dart';
import '../../engine/tile.dart';
import '../theme.dart';

class BoardPainter extends CustomPainter {
  final Board board;
  final double cell;

  /// PNG 아트가 대신 그리는 타일 — 바탕 잔디만 깔고 장식은 건너뛴다.
  final Set<Tile> skip;
  BoardPainter(this.board, this.cell, {this.skip = const {}});

  @override
  void paint(Canvas canvas, Size size) {
    for (var y = 0; y < board.height; y++) {
      for (var x = 0; x < board.width; x++) {
        _paintCell(canvas, Point(x, y));
      }
    }
  }

  Rect _rect(Point p) => Rect.fromLTWH(
      p.x * cell + kTileGap, p.y * cell + kTileGap,
      cell - kTileGap * 2, cell - kTileGap * 2);

  RRect _rrect(Point p) =>
      RRect.fromRectAndRadius(_rect(p), Radius.circular(cell * 0.18));

  Paint _fill(Color c) => Paint()..color = c;
  Paint get _line => Paint()
    ..color = PiyakColors.outline
    ..style = PaintingStyle.stroke
    ..strokeWidth = kOutlineWidth
    ..strokeCap = StrokeCap.round;

  void _paintCell(Canvas canvas, Point p) {
    final t = board.tileAt(p);
    final r = _rect(p);
    final rr = _rrect(p);
    // 바탕 잔디 (벽·구멍 제외 모든 칸)
    if (t != Tile.wall && t != Tile.hole) {
      final alt = (p.x + p.y).isEven;
      canvas.drawRRect(
          rr, _fill(alt ? PiyakColors.grass : PiyakColors.grassDark));
    }
    if (skip.contains(t) && t != Tile.floor) return; // 그림이 대신 그린다
    switch (t) {
      case Tile.floor:
        // 좌표 해시로 무늬를 고정한다 — 난수를 쓰면 프레임마다 흔들린다.
        final h = (p.x * 31 + p.y * 17) % 4;
        if (h < 2) {
          final blade = Paint()
            ..color = PiyakColors.grassDark
            ..strokeWidth = cell * 0.05
            ..strokeCap = StrokeCap.round
            ..style = PaintingStyle.stroke;
          final bx = r.left + r.width * (h == 0 ? 0.30 : 0.62);
          final by = r.top + r.height * (h == 0 ? 0.68 : 0.40);
          final s = cell * 0.10;
          canvas.drawLine(Offset(bx, by), Offset(bx - s, by - s), blade);
          canvas.drawLine(Offset(bx, by), Offset(bx + s, by - s), blade);
        }
      case Tile.wall:
        canvas.drawRRect(rr, _fill(PiyakColors.wallBrown));
        canvas.drawRRect(rr, _line);
        // 울타리 널빤지 느낌의 가로줄
        final y1 = r.top + r.height * 0.38;
        final y2 = r.top + r.height * 0.68;
        final plank = Paint()
          ..color = PiyakColors.wallLight
          ..strokeWidth = cell * 0.10
          ..strokeCap = StrokeCap.round;
        canvas.drawLine(Offset(r.left + 3, y1), Offset(r.right - 3, y1), plank);
        canvas.drawLine(Offset(r.left + 3, y2), Offset(r.right - 3, y2), plank);
        // 아래쪽 그림자 띠로 입체감
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTRB(
                r.left, r.bottom - r.height * 0.16, r.right, r.bottom),
            Radius.circular(cell * 0.14),
          ),
          Paint()..color = PiyakColors.outline.withValues(alpha: 0.18),
        );
      case Tile.nest:
        // 지푸라기 둥지 링
        final c = r.center;
        canvas.drawCircle(c, r.width * 0.34,
            Paint()..color = PiyakColors.nestStraw);
        canvas.drawCircle(c, r.width * 0.34, _line);
        canvas.drawCircle(c, r.width * 0.18,
            Paint()..color = PiyakColors.nestDark);
        // 지푸라기 결
        final straw = Paint()
          ..color = PiyakColors.outline.withValues(alpha: 0.35)
          ..strokeWidth = 1.4
          ..strokeCap = StrokeCap.round;
        for (var k = 0; k < 3; k++) {
          final a = 0.6 + k * 1.9;
          canvas.drawLine(
            Offset(c.dx + math.cos(a) * r.width * 0.20,
                c.dy + math.sin(a) * r.width * 0.20),
            Offset(c.dx + math.cos(a) * r.width * 0.33,
                c.dy + math.sin(a) * r.width * 0.33),
            straw,
          );
        }
      case Tile.ice:
        canvas.drawRRect(rr, _fill(PiyakColors.iceBlue));
        canvas.drawRRect(rr, _line);
        final shine = Paint()
          ..color = PiyakColors.iceShine
          ..strokeWidth = cell * 0.08
          ..strokeCap = StrokeCap.round;
        canvas.drawLine(Offset(r.left + r.width * 0.25, r.top + r.height * 0.6),
            Offset(r.left + r.width * 0.5, r.top + r.height * 0.3), shine);
        canvas.drawLine(Offset(r.left + r.width * 0.5, r.top + r.height * 0.75),
            Offset(r.left + r.width * 0.75, r.top + r.height * 0.45), shine);
      case Tile.cracked:
        final crack = Paint()
          ..color = PiyakColors.crack
          ..strokeWidth = 1.8
          ..strokeCap = StrokeCap.round;
        final c = r.center;
        canvas.drawLine(Offset(r.left + 4, c.dy), Offset(c.dx - 2, c.dy - 4), crack);
        canvas.drawLine(Offset(c.dx - 2, c.dy - 4), Offset(r.right - 5, c.dy + 2), crack);
        canvas.drawLine(Offset(c.dx - 1, c.dy - 1), Offset(c.dx + 2, r.bottom - 4), crack);
      case Tile.hole:
        canvas.drawOval(r.deflate(cell * 0.08), _fill(PiyakColors.holeDark));
        canvas.drawOval(r.deflate(cell * 0.08), _line);
      case Tile.portal1 || Tile.portal2 || Tile.portal3 || Tile.portal4:
        final ring = (t == Tile.portal1 || t == Tile.portal2)
            ? PiyakColors.portalPurple
            : PiyakColors.portalOrange;
        final c = r.center;
        canvas.drawCircle(c, r.width * 0.36, _fill(ring));
        canvas.drawCircle(c, r.width * 0.36, _line);
        canvas.drawCircle(c, r.width * 0.22, _fill(PiyakColors.holeDark));
      case Tile.buttonB || Tile.buttonD:
        final col = t == Tile.buttonB
            ? PiyakColors.buttonPinkB
            : PiyakColors.buttonBlueD;
        final c = r.center;
        canvas.drawCircle(c, r.width * 0.30, _fill(col));
        canvas.drawCircle(c, r.width * 0.30, _line);
        canvas.drawCircle(
            Offset(c.dx, c.dy - r.height * 0.06), r.width * 0.18,
            _fill(Colors.white.withValues(alpha: 0.45)));
      case Tile.doorB || Tile.doorD:
        final col = t == Tile.doorB
            ? PiyakColors.buttonPinkB
            : PiyakColors.buttonBlueD;
        final open = board.doorOpenFor(t);
        if (open) {
          // 열린 문: 문짝이 왼쪽으로 젖혀지고 통로가 뚫린다.
          // 테두리만 남기면 열렸는지 알아보기 어려워 문짝을 남겨 둔다.
          canvas.drawRRect(
            rr.deflate(cell * 0.04),
            Paint()
              ..color = col.withValues(alpha: 0.5)
              ..style = PaintingStyle.stroke
              ..strokeWidth = cell * 0.07,
          );
          final leaf = RRect.fromRectAndRadius(
            Rect.fromLTWH(r.left, r.top, r.width * 0.24, r.height),
            Radius.circular(cell * 0.08),
          );
          canvas.drawRRect(leaf, _fill(col));
          canvas.drawRRect(leaf, _line);
        } else {
          canvas.drawRRect(rr, _fill(col));
          canvas.drawRRect(rr, _line);
          // 자물쇠 구멍
          final c = r.center;
          canvas.drawCircle(Offset(c.dx, c.dy - 2), r.width * 0.10,
              _fill(PiyakColors.outline));
          canvas.drawLine(Offset(c.dx, c.dy), Offset(c.dx, c.dy + r.height * 0.16),
              _line..strokeWidth = 3);
        }
    }
  }

  @override
  bool shouldRepaint(BoardPainter old) =>
      old.board != board || old.cell != cell;
}

/// 알 — 밀리기 시작하면 이동 축으로 살짝 찌그러졌다 복원된다.
/// 둥지 위에선 행복한 얼굴.
class EggSprite extends StatefulWidget {
  final Point pos;
  final double size;
  final bool onNest;
  const EggSprite(
      {required this.pos, required this.size, this.onNest = false, super.key});

  @override
  State<EggSprite> createState() => _EggSpriteState();
}

class _EggSpriteState extends State<EggSprite>
    with SingleTickerProviderStateMixin {
  late final AnimationController _recoil = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 120),
  );
  bool _horizontal = true;

  @override
  void didUpdateWidget(EggSprite old) {
    super.didUpdateWidget(old);
    if (old.pos != widget.pos) {
      _horizontal = widget.pos.y == old.pos.y;
      _recoil.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _recoil.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _recoil,
      builder: (context, child) {
        final t = math.sin(math.pi * _recoil.value);
        final s = 1.0 - 0.10 * t;
        return Transform(
          alignment: Alignment.center,
          transform: _horizontal
              ? Matrix4.diagonal3Values(s, 2.0 - s, 1.0)
              : Matrix4.diagonal3Values(2.0 - s, s, 1.0),
          child: child,
        );
      },
      child: CustomPaint(
        size: Size(widget.size, widget.size),
        painter: _EggPainter(widget.onNest),
      ),
    );
  }
}

class _EggPainter extends CustomPainter {
  final bool happy;
  _EggPainter(this.happy);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final rect = Rect.fromLTWH(w * 0.18, h * 0.10, w * 0.64, h * 0.78);
    final fill = Paint()..color = PiyakColors.eggWhite;
    final line = Paint()
      ..color = PiyakColors.outline
      ..style = PaintingStyle.stroke
      ..strokeWidth = kOutlineWidth;
    canvas.drawOval(rect, fill);
    canvas.drawOval(rect, line);
    // 좌상단 광택
    canvas.save();
    canvas.translate(w * 0.38, h * 0.30);
    canvas.rotate(-0.5);
    canvas.drawOval(
      Rect.fromCenter(center: Offset.zero, width: w * 0.16, height: h * 0.10),
      Paint()..color = Colors.white.withValues(alpha: 0.85),
    );
    canvas.restore();
    // 볼터치
    final blush = Paint()..color = PiyakColors.blush;
    canvas.drawOval(
        Rect.fromCenter(
            center: Offset(w * 0.32, h * 0.58), width: w * 0.14, height: h * 0.09),
        blush);
    canvas.drawOval(
        Rect.fromCenter(
            center: Offset(w * 0.68, h * 0.58), width: w * 0.14, height: h * 0.09),
        blush);
    if (happy) {
      // 감은 행복 눈(^ ^) + 미소
      final stroke = Paint()
        ..color = PiyakColors.outline
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(
          Rect.fromCenter(
              center: Offset(w * 0.38, h * 0.44), width: w * 0.12, height: h * 0.10),
          3.34, 2.74, false, stroke);
      canvas.drawArc(
          Rect.fromCenter(
              center: Offset(w * 0.62, h * 0.44), width: w * 0.12, height: h * 0.10),
          3.34, 2.74, false, stroke);
      canvas.drawArc(
          Rect.fromCenter(
              center: Offset(w * 0.5, h * 0.52), width: w * 0.16, height: h * 0.10),
          0.4, 2.34, false, stroke);
    } else {
      // 점 눈
      final dot = Paint()..color = PiyakColors.outline;
      canvas.drawCircle(Offset(w * 0.40, h * 0.45), w * 0.035, dot);
      canvas.drawCircle(Offset(w * 0.60, h * 0.45), w * 0.035, dot);
    }
  }

  @override
  bool shouldRepaint(_EggPainter old) => old.happy != happy;
}
