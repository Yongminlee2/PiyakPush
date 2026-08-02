/// 보드 렌더링: 바닥 CustomPaint + 알(AnimatedPositioned) + 병아리 이미지.
///
/// 알 애니메이션 연속성: 한 이동에 알은 최대 1개만 움직이므로,
/// 이전 프레임과 비교해 "사라진 위치→나타난 위치"를 같은 id로 매칭한다.
library;

import 'package:flutter/material.dart';

import '../../engine/board.dart';
import '../../engine/geometry.dart';
import '../../engine/tile.dart';
import 'tile_painter.dart';

const kMoveAnim = Duration(milliseconds: 120);

class BoardView extends StatefulWidget {
  final Board board;
  final double cellSize;

  /// 'idle' | 'think' | 'sleep' | 'cheer' | 'sad' | 'speak' ...
  final String chickMood;
  const BoardView({
    required this.board,
    required this.cellSize,
    this.chickMood = 'idle',
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
        ],
      ),
    );
  }
}
