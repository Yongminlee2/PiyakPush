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

  /// 잘못 민 수가 되돌릴 수 없게 되는 비율. 이 값이 높을수록 "막 움직이면
  /// 못 깨는" 판이다 — 최적 턴 수보다 이쪽이 체감 난이도를 좌우한다.
  final double minDeadlockRatio;
  final int maxStates;

  /// 역방향 흐트러뜨리기 횟수. 크게 줄수록 알이 둥지에서 멀어진다.
  final int? scrambleSteps;
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
    this.scrambleSteps,
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
        steps: (spec.scrambleSteps ?? spec.width * spec.height) +
            rng.nextInt(20));
    // 흐트러뜨리기가 알을 전부 둥지 밖으로 빼지 못하면 시작부터 몇 개가
    // 이미 놓인 판이 된다 — 그만큼 실제로 풀 문제가 줄어 시시해진다.
    // isCleared(전부 놓임)만 걸러서는 부족하고, 하나라도 놓여 있으면 버린다.
    if (board.eggs.any((e) => board.tileAt(e) == Tile.nest)) continue;
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

/// 알·벽이 없어 병아리가 딛을 수 있는 칸인가.
bool _free(Board b, Point p) =>
    b.inBounds(p) && b.tileAt(p) != Tile.wall && !b.eggs.contains(p);

/// 병아리가 알을 건드리지 않고 [to]까지 걸어갈 수 있는가.
///
/// 걷기는 순방향에서도 자유로우므로, 갈 수만 있으면 흐트러뜨리는 도중
/// 병아리를 그 자리로 바로 옮겨도 된다 — 그 걸음은 순방향 해에 포함된다.
bool _canWalk(Board b, Point to) {
  if (!_free(b, to)) return false;
  final seen = <Point>{b.chick};
  final q = <Point>[b.chick];
  while (q.isNotEmpty) {
    final p = q.removeLast();
    if (p == to) return true;
    for (final d in Dir.values) {
      final n = p.step(d);
      if (!_free(b, n) || !seen.add(n)) continue;
      q.add(n);
    }
  }
  return false;
}

/// 완성 상태를 역방향으로 흐트러뜨린다.
///
/// 무작위 역-걷기에 당기기를 섞는 방식은 당길 기회가 드물어 알이 거의
/// 제자리였다(알 4개에 밀기 중앙값 7 = 알당 1.75칸). 대신 **알을 하나 골라
/// 끌어낼 자리까지 병아리를 보낸 뒤 연달아 당기는** 방식으로 바꿨다.
/// 알이 둥지에서 확실히 멀어져야 풀 때 생각할 거리가 생긴다.
Board reverseScramble(Board b, Random rng, {required int steps}) {
  var cur = b;
  final campaigns = (steps / 6).ceil();
  for (var c = 0; c < campaigns; c++) {
    final eggs = cur.eggs.toList()..shuffle(rng);
    var moved = false;
    for (final egg in eggs) {
      final dirs = [...Dir.values]..shuffle(rng);
      for (final d in dirs) {
        // 알을 d 방향으로 당기려면 병아리가 알이 갈 자리에 서고,
        // 그 뒤 칸으로 물러나야 한다.
        final standing = egg.step(d);
        if (!_free(cur, standing) || !_free(cur, standing.step(d))) continue;
        if (!_canWalk(cur, standing)) continue;

        cur = cur.copyWith(chick: standing);
        var e = egg;
        final pulls = 1 + rng.nextInt(4);
        for (var k = 0; k < pulls; k++) {
          final next = cur.chick.step(d); // 병아리가 물러날 자리
          if (!_free(cur, next)) break;
          final moved2 = Set<Point>.from(cur.eggs)
            ..remove(e)
            ..add(cur.chick);
          e = cur.chick;
          cur = cur.copyWith(chick: next, eggs: moved2);
        }
        moved = true;
        break;
      }
      if (moved) break;
    }
    if (!moved) break; // 어떤 알도 못 당기면 그만
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
