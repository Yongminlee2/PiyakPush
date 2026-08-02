/// 레벨 후보 생성 — 순수 Dart(CLI에서 실행). Flutter import 금지.
///
/// 절차: ①벽·둥지만으로 완성 상태를 만들고 역방향으로 흐트러뜨려 풀이
/// 가능성을 확보한 뒤 ②기믹 타일을 빈 바닥에 얹고 ③솔버로 재검증·측정해
/// ④밴드를 통과한 것만 채택한다. 기믹을 얹으면 막힐 수 있으므로 솔버가
/// 진실의 기준이다.
library;

import 'dart:math';

import '../engine/board.dart';
import '../engine/geometry.dart';
import '../engine/solve_report.dart';
import '../engine/solver.dart';
import '../engine/tile.dart';

enum Gimmick { ice, portal, door, cracked }

class GenSpec {
  final int width, height, eggCount, wallCount;
  final List<Gimmick> gimmicks;
  final int minOptimal, maxOptimal, minPushes, minStates;
  final double minDeadlockRatio;
  final int maxStates;
  const GenSpec({
    required this.width,
    required this.height,
    required this.eggCount,
    required this.wallCount,
    required this.gimmicks,
    required this.minOptimal,
    required this.maxOptimal,
    required this.minPushes,
    required this.minStates,
    required this.minDeadlockRatio,
    this.maxStates = 400000,
  });
}

class GenResult {
  final List<String> rows;
  final SolveReport report;
  const GenResult(this.rows, this.report);
}

GenResult? generate(Random rng, GenSpec spec, {int maxAttempts = 400}) {
  for (var attempt = 0; attempt < maxAttempts; attempt++) {
    final solved = randomSolvedBoard(
        rng, spec.width, spec.height, spec.wallCount, spec.eggCount);
    if (solved == null) continue;
    var board = reverseScramble(solved, rng,
        steps: spec.width * spec.height + rng.nextInt(20));
    if (board.isCleared) continue;
    board = _sprinkleGimmicks(board, rng, spec);

    final report = Solver(maxStates: spec.maxStates).analyze(board);
    if (!report.solved) continue;
    if (report.optimalMoves < spec.minOptimal) continue;
    if (report.optimalMoves > spec.maxOptimal) continue;
    if (report.pushes < spec.minPushes) continue;
    if (report.statesExplored < spec.minStates) continue;
    if (report.deadlockRatio < spec.minDeadlockRatio) continue;

    try {
      return GenResult(board.toAsciiRows(), report);
    } on StateError {
      continue; // 기믹 위에 알이 올라간 배치 — 표현 불가라 폐기
    }
  }
  return null;
}

/// 테두리 벽 + 내벽 + 둥지(알을 올려 완성 상태) + 병아리.
Board? randomSolvedBoard(
    Random rng, int width, int height, int wallCount, int eggCount) {
  final tiles = List<Tile>.generate(width * height, (i) {
    final x = i % width, y = i ~/ width;
    return (x == 0 || y == 0 || x == width - 1 || y == height - 1)
        ? Tile.wall
        : Tile.floor;
  });
  final inner = <int>[
    for (var y = 1; y < height - 1; y++)
      for (var x = 1; x < width - 1; x++) y * width + x
  ]..shuffle(rng);
  if (inner.length < wallCount + eggCount + 1) return null;
  var k = 0;
  for (var i = 0; i < wallCount; i++) {
    tiles[inner[k++]] = Tile.wall;
  }
  final eggs = <Point>{};
  for (var i = 0; i < eggCount; i++) {
    final idx = inner[k++];
    tiles[idx] = Tile.nest;
    eggs.add(Point(idx % width, idx ~/ width));
  }
  final chickIdx = inner[k++];
  return Board(
    width: width,
    height: height,
    tiles: tiles,
    eggs: eggs,
    chick: Point(chickIdx % width, chickIdx ~/ width),
  );
}

Dir _opposite(Dir d) => switch (d) {
      Dir.up => Dir.down,
      Dir.down => Dir.up,
      Dir.left => Dir.right,
      Dir.right => Dir.left,
    };

/// 역방향 이동(역-걷기·당기기)을 무작위 적용. 당기기가 드물게 나오므로
/// 가능할 땐 70% 확률로 당기기를 골라 알이 충분히 움직이게 한다.
Board reverseScramble(Board b, Random rng, {required int steps}) {
  var cur = b;
  for (var i = 0; i < steps; i++) {
    final walks = <Board>[];
    final pulls = <Board>[];
    for (final d in Dir.values) {
      final to = cur.chick.step(d);
      if (!cur.inBounds(to)) continue;
      if (cur.tileAt(to) == Tile.wall || cur.eggs.contains(to)) continue;
      walks.add(cur.copyWith(chick: to));
      final eggPos = cur.chick.step(_opposite(d));
      if (cur.eggs.contains(eggPos)) {
        final eggs = Set<Point>.from(cur.eggs)
          ..remove(eggPos)
          ..add(cur.chick);
        pulls.add(cur.copyWith(chick: to, eggs: eggs));
      }
    }
    if (walks.isEmpty && pulls.isEmpty) break;
    final usePull =
        pulls.isNotEmpty && (walks.isEmpty || rng.nextDouble() < 0.7);
    final pool = usePull ? pulls : walks;
    cur = pool[rng.nextInt(pool.length)];
  }
  return cur;
}

/// 알·병아리·둥지가 없는 바닥 칸에만 기믹을 놓는다. 굴과 문은 짝을 이뤄야
/// 의미가 있으므로 쌍으로 배치한다.
Board _sprinkleGimmicks(Board b, Random rng, GenSpec spec) {
  if (spec.gimmicks.isEmpty) return b;
  final free = <int>[];
  for (var i = 0; i < b.tiles.length; i++) {
    final p = Point(i % b.width, i ~/ b.width);
    if (b.tiles[i] != Tile.floor) continue;
    if (b.eggs.contains(p) || b.chick == p) continue;
    free.add(i);
  }
  free.shuffle(rng);
  final tiles = List<Tile>.from(b.tiles);
  var k = 0;

  bool take(int n) => free.length - k >= n;

  for (final g in spec.gimmicks) {
    switch (g) {
      case Gimmick.ice:
        final n = 2 + rng.nextInt(3);
        if (!take(n)) break;
        for (var i = 0; i < n; i++) {
          tiles[free[k++]] = Tile.ice;
        }
      case Gimmick.portal:
        if (!take(2)) break;
        tiles[free[k++]] = Tile.portal1;
        tiles[free[k++]] = Tile.portal2;
      case Gimmick.door:
        if (!take(2)) break;
        tiles[free[k++]] = Tile.buttonB;
        tiles[free[k++]] = Tile.doorB;
      case Gimmick.cracked:
        final n = 1 + rng.nextInt(3);
        if (!take(n)) break;
        for (var i = 0; i < n; i++) {
          tiles[free[k++]] = Tile.cracked;
        }
    }
  }
  return b.copyWith(tiles: tiles);
}
