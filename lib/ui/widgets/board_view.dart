/// 보드 렌더링: 바닥 CustomPaint + 알(AnimatedPositioned) + 병아리 이미지.
///
/// 알 애니메이션 연속성: 한 이동에 알은 최대 1개만 움직이므로,
/// 이전 프레임과 비교해 "사라진 위치→나타난 위치"를 같은 id로 매칭한다.
library;

import 'package:flutter/material.dart';

import '../../engine/board.dart';
import '../../engine/geometry.dart';
import '../../engine/move.dart';
import '../../engine/tile.dart';
import '../theme.dart';
import 'tile_painter.dart';

const kMoveAnim = Duration(milliseconds: 120);

class BoardView extends StatefulWidget {
  final Board board;
  final double cellSize;

  /// 'idle' | 'think' | 'sleep' | 'cheer' | 'sad' | 'speak' ...
  final String chickMood;

  /// 힌트: 다음 이동들 — 실제 tryMove 시뮬레이션으로 병아리 경로에 화살표 표시.
  final List<Dir>? hintMoves;
  const BoardView({
    required this.board,
    required this.cellSize,
    this.chickMood = 'idle',
    this.hintMoves,
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
              curve: Curves.easeOut,
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
            curve: Curves.easeOut,
            left: b.chick.x * cell,
            top: b.chick.y * cell - cell * 0.12, // 살짝 위로 — 입체감
            width: cell,
            height: cell * 1.12,
            child: Image.asset(
              'assets/images/chick/chick_${widget.chickMood}.png',
              gaplessPlayback: true,
              fit: BoxFit.contain,
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
