/// 힌트: 현재 보드를 백그라운드 isolate에서 풀어 앞 N수를 돌려준다.
///
/// compute 메시지는 순수 데이터만 가능 — 보드를 (크기, 타일 인덱스,
/// 알 인덱스, 병아리 인덱스) 레코드로 직렬화한다. ASCII 왕복은
/// 병아리가 얼음·굴 위에 있을 때 밑 타일 정보를 잃어서 쓰지 않는다.
library;

import 'package:flutter/foundation.dart';

import '../engine/board.dart';
import '../engine/geometry.dart';
import '../engine/solver.dart';
import '../engine/tile.dart';

typedef _BoardMsg = (int, int, List<int>, List<int>, int);

_BoardMsg _toMsg(Board b) => (
      b.width,
      b.height,
      b.tiles.map((t) => t.index).toList(),
      b.eggs.map((p) => p.y * b.width + p.x).toList(),
      b.chick.y * b.width + b.chick.x,
    );

List<int>? _solveEntry(_BoardMsg m) {
  final (w, h, tiles, eggs, chick) = m;
  final board = Board(
    width: w,
    height: h,
    tiles: tiles.map((i) => Tile.values[i]).toList(),
    eggs: eggs.map((i) => Point(i % w, i ~/ w)).toSet(),
    chick: Point(chick % w, chick ~/ w),
  );
  return Solver().solve(board)?.map((d) => d.index).toList();
}

Future<List<Dir>?> hintFor(Board board, {int steps = 5}) async {
  final idx = await compute(_solveEntry, _toMsg(board));
  if (idx == null) return null;
  return idx.take(steps).map((i) => Dir.values[i]).toList();
}
