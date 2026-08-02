/// 데일리 퍼즐 생성기 — 순수 Dart (CLI 도구에서도 실행 가능, Flutter 의존 금지).
///
/// 절차: ①7×7 무작위 보드를 "완성 상태"(알 전부 둥지 위)로 만들고
/// ②역방향 이동(걷기·당기기)을 25~45회 적용해 흐트러뜨린 뒤
/// ③솔버 최적수가 8~25면 채택. 역방향으로 만든 상태는 완성 상태로
/// 가는 순방향 경로가 반드시 존재하므로 풀이 가능성이 보장된다.
library;

import 'dart:math';

import '../engine/board.dart';
import '../engine/geometry.dart';
import '../engine/solver.dart';
import '../engine/tile.dart';
import '../models/level.dart';

int daySeed(DateTime d) => d.year * 10000 + d.month * 100 + d.day;

Dir _opposite(Dir d) => switch (d) {
      Dir.up => Dir.down,
      Dir.down => Dir.up,
      Dir.left => Dir.right,
      Dir.right => Dir.left,
    };

/// 날짜 시드로 결정적 생성. 실패하면 null (→ 프리셋 폴백).
Level? tryGenerateDaily(DateTime date, {int? seedOverride}) {
  final rng = Random(seedOverride ?? daySeed(date));
  for (var attempt = 0; attempt < 120; attempt++) {
    final solved = _randomSolvedBoard(rng);
    if (solved == null) continue;
    final scrambled =
        _reverseScramble(solved, rng, steps: 25 + rng.nextInt(21));
    if (scrambled.isCleared) continue;
    final sol = Solver(maxStates: 300000).solve(scrambled);
    if (sol == null || sol.length < 8 || sol.length > 25) continue;
    return Level(
      id: 'daily',
      chapter: 0,
      title: '오늘의 퍼즐',
      rows: scrambled.toAsciiRows(),
      optimal: sol.length,
    );
  }
  return null;
}

/// 7×7 보드: 테두리 벽 + 내벽 6~10 + 둥지 2~3(알을 올려 완성 상태) + 병아리.
Board? _randomSolvedBoard(Random rng) {
  const n = 7;
  final tiles = List<Tile>.generate(n * n, (i) {
    final x = i % n, y = i ~/ n;
    return (x == 0 || y == 0 || x == n - 1 || y == n - 1)
        ? Tile.wall
        : Tile.floor;
  });
  final inner = <int>[
    for (var y = 1; y < n - 1; y++)
      for (var x = 1; x < n - 1; x++) y * n + x
  ]..shuffle(rng);
  var k = 0;
  final wallCount = 6 + rng.nextInt(5);
  for (var i = 0; i < wallCount; i++) {
    tiles[inner[k++]] = Tile.wall;
  }
  final nestCount = 2 + rng.nextInt(2);
  final eggs = <Point>{};
  for (var i = 0; i < nestCount; i++) {
    final idx = inner[k++];
    tiles[idx] = Tile.nest;
    eggs.add(Point(idx % n, idx ~/ n));
  }
  final chickIdx = inner[k++];
  final chick = Point(chickIdx % n, chickIdx ~/ n);
  return Board(width: n, height: n, tiles: tiles, eggs: eggs, chick: chick);
}

/// 역방향 이동(역-걷기·당기기)을 무작위 적용.
///
/// 걷기 선택지는 항상 최대 4개인데 당기기는 어쩌다 생기므로, 균등 선택하면
/// 알이 거의 안 움직여 너무 쉬운 퍼즐만 나온다. 당기기 가능할 땐 70%
/// 확률로 당기기를 고른다.
Board _reverseScramble(Board b, Random rng, {required int steps}) {
  var cur = b;
  for (var i = 0; i < steps; i++) {
    final walks = <Board>[];
    final pulls = <Board>[];
    for (final d in Dir.values) {
      final to = cur.chick.step(d);
      if (!cur.inBounds(to)) continue;
      final t = cur.tileAt(to);
      if (t == Tile.wall || cur.eggs.contains(to)) continue;
      // 역-걷기: 병아리만 이동
      walks.add(cur.copyWith(chick: to));
      // 당기기: 병아리 반대편의 알이 병아리 자리로 따라온다
      final eggPos = cur.chick.step(_opposite(d));
      if (cur.eggs.contains(eggPos)) {
        final eggs = Set<Point>.from(cur.eggs)
          ..remove(eggPos)
          ..add(cur.chick);
        pulls.add(cur.copyWith(chick: to, eggs: eggs));
      }
    }
    if (walks.isEmpty && pulls.isEmpty) break;
    final usePull = pulls.isNotEmpty && (walks.isEmpty || rng.nextDouble() < 0.7);
    final pool = usePull ? pulls : walks;
    cur = pool[rng.nextInt(pool.length)];
  }
  return cur;
}
