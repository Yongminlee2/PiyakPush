/// 보드 렌더링: 바닥 CustomPaint + 알(AnimatedPositioned) + 병아리 이미지.
///
/// 알 애니메이션 연속성: 한 이동에 알은 최대 1개만 움직이므로,
/// 이전 프레임과 비교해 "사라진 위치→나타난 위치"를 같은 id로 매칭한다.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../engine/board.dart';
import '../../engine/geometry.dart';
import '../../engine/move.dart';
import '../../engine/tile.dart';
import '../theme.dart';
import 'tile_painter.dart';

/// 한 칸 이동 시간. DPad 연속 간격(170ms)과 거의 맞물려야 꾹 눌러 이동할 때
/// 칸마다 멈칫하지 않는다.
const kMoveAnim = Duration(milliseconds: 160);

class BoardView extends StatefulWidget {
  final Board board;
  final double cellSize;

  /// 'idle' | 'think' | 'sleep' | 'cheer' | 'sad' | 'speak' ...
  final String chickMood;

  /// 힌트: 다음 이동들 — 실제 tryMove 시뮬레이션으로 병아리 경로에 화살표 표시.
  final List<Dir>? hintMoves;

  /// 막힌 입력 피드백: 토큰이 바뀌면 병아리가 그 방향으로 살짝 밀렸다 돌아온다.
  final Dir? bumpDir;
  final int bumpToken;
  const BoardView({
    required this.board,
    required this.cellSize,
    this.chickMood = 'idle',
    this.hintMoves,
    this.bumpDir,
    this.bumpToken = 0,
    super.key,
  });

  @override
  State<BoardView> createState() => _BoardViewState();
}

class _BoardViewState extends State<BoardView> {
  late List<Point> _eggOrder; // index = 안정 id

  @override
  void initState() {
    super.initState();
    _eggOrder = widget.board.eggs.toList();
  }

  @override
  void didUpdateWidget(BoardView old) {
    super.didUpdateWidget(old);
    final now = widget.board.eggs;
    final removed = _eggOrder.where((p) => !now.contains(p)).toList();
    final added = now.where((p) => !_eggOrder.contains(p)).toList();
    if (removed.length == 1 && added.length == 1) {
      _eggOrder = _eggOrder
          .map((p) => p == removed.single ? added.single : p)
          .toList();
    } else if (removed.isNotEmpty || added.isNotEmpty) {
      _eggOrder = now.toList(); // 재시작·레벨 교체 등은 리셋
    }
  }

  @override
  Widget build(BuildContext context) {
    final cell = widget.cellSize;
    final b = widget.board;
    return SizedBox(
      width: b.width * cell,
      height: b.height * cell,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          CustomPaint(
            size: Size(b.width * cell, b.height * cell),
            painter: BoardPainter(b, cell),
          ),
          for (var i = 0; i < _eggOrder.length; i++)
            AnimatedPositioned(
              key: ValueKey('egg$i'),
              duration: kMoveAnim,
              curve: Curves.easeInOut,
              left: _eggOrder[i].x * cell,
              top: _eggOrder[i].y * cell,
              width: cell,
              height: cell,
              child: EggWidget(
                size: cell,
                onNest: b.tileAt(_eggOrder[i]) == Tile.nest,
              ),
            ),
          AnimatedPositioned(
            key: const ValueKey('chick'),
            duration: kMoveAnim,
            curve: Curves.easeInOut,
            left: b.chick.x * cell,
            top: b.chick.y * cell - cell * 0.12, // 살짝 위로 — 입체감
            width: cell,
            height: cell * 1.12,
            child: ChickSprite(
              pos: b.chick,
              cell: cell,
              mood: widget.chickMood,
              bumpDir: widget.bumpDir,
              bumpToken: widget.bumpToken,
            ),
          ),
          for (final (i, step) in _hintSteps.indexed)
            Positioned(
              left: step.$1.x * cell,
              top: step.$1.y * cell,
              width: cell,
              height: cell,
              child: IgnorePointer(
                child: Opacity(
                  opacity: (1.0 - i * 0.15).clamp(0.3, 1.0),
                  child: Transform.rotate(
                    angle: switch (step.$2) {
                      Dir.up => -1.5708,
                      Dir.down => 1.5708,
                      Dir.left => 3.1416,
                      Dir.right => 0,
                    },
                    child: Icon(
                      Icons.arrow_forward_rounded,
                      size: cell * 0.6,
                      color: PiyakColors.starYellow,
                      shadows: const [
                        Shadow(color: PiyakColors.outline, blurRadius: 3),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// 힌트 이동을 실제 엔진으로 시뮬레이션해 (도착 칸, 방향) 목록을 만든다.
  List<(Point, Dir)> get _hintSteps {
    final moves = widget.hintMoves;
    if (moves == null) return const [];
    final steps = <(Point, Dir)>[];
    var b = widget.board;
    for (final d in moves) {
      final o = b.tryMove(d);
      if (o.blocked) break;
      b = o.board!;
      steps.add((b.chick, d));
    }
    return steps;
  }
}

/// 살아있는 병아리: 평소엔 숨쉬기 보브, 이동할 때마다 총총 뛰는 홉 +
/// 이동 방향으로 살짝 기울어진다.
class ChickSprite extends StatefulWidget {
  final Point pos;
  final double cell;
  final String mood;

  /// 벽·알에 막혔을 때 밀리는 방향. [bumpToken]이 바뀔 때만 반응한다.
  final Dir? bumpDir;
  final int bumpToken;
  const ChickSprite({
    required this.pos,
    required this.cell,
    required this.mood,
    this.bumpDir,
    this.bumpToken = 0,
    super.key,
  });

  @override
  State<ChickSprite> createState() => _ChickSpriteState();
}

class _ChickSpriteState extends State<ChickSprite>
    with TickerProviderStateMixin {
  late final AnimationController _bob = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat(reverse: true);
  late final AnimationController _hop = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 160),
  );
  late final AnimationController _bump = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 140),
  );
  int _tiltSign = 0;
  Dir? _lastBumpDir;

  @override
  void didUpdateWidget(ChickSprite old) {
    super.didUpdateWidget(old);
    if (old.pos != widget.pos) {
      final dx = widget.pos.x - old.pos.x;
      _tiltSign = dx == 0 ? _tiltSign : (dx > 0 ? 1 : -1);
      _hop.forward(from: 0);
    }
    if (widget.bumpToken != old.bumpToken && widget.bumpDir != null) {
      _lastBumpDir = widget.bumpDir;
      _bump.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _bob.dispose();
    _hop.dispose();
    _bump.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_bob, _hop, _bump]),
      builder: (context, child) {
        final hopT = _hop.value;
        final arc = math.sin(math.pi * hopT);
        final hopY = -arc * widget.cell * 0.22;
        final tilt = _tiltSign * 0.12 * arc;
        // 숨쉬기: 세로로 살짝 늘었다 줄었다
        final breathe = 1.0 + 0.03 * _bob.value;
        // 막힘: 그 방향으로 밀렸다 제자리로
        final push = widget.cell * 0.12 * math.sin(math.pi * _bump.value);
        final bump = switch (_lastBumpDir) {
          Dir.up => Offset(0, -push),
          Dir.down => Offset(0, push),
          Dir.left => Offset(-push, 0),
          Dir.right => Offset(push, 0),
          null => Offset.zero,
        };
        return Transform.translate(
          offset: Offset(bump.dx, hopY + bump.dy),
          child: Transform.rotate(
            angle: tilt,
            child: Transform(
              alignment: Alignment.bottomCenter,
              transform: Matrix4.diagonal3Values(
                  2.0 - breathe, breathe, 1.0),
              child: child,
            ),
          ),
        );
      },
      child: Image.asset(
        'assets/images/chick/chick_${widget.mood}.png',
        gaplessPlayback: true,
        fit: BoxFit.contain,
      ),
    );
  }
}
