import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:piyak_push/engine/board.dart';
import 'package:piyak_push/engine/solver.dart';
import 'package:piyak_push/engine/tile.dart';
import 'package:piyak_push/services/level_generator.dart';

const _easySpec = GenSpec(
  width: 7,
  height: 7,
  eggCount: 2,
  wallCount: 6,
  gimmicks: [],
  minOptimal: 8,
  maxOptimal: 30,
  minPushes: 3,
  minStates: 50,
  minDeadlockRatio: 0.0,
  maxStates: 200000,
);

void main() {
  test('기본 규격으로 생성하면 풀이 가능하고 밴드를 지킨다', () {
    final g = generate(Random(1), _easySpec);
    expect(g, isNotNull);
    final report = Solver().analyze(Board.fromAscii(g!.rows));
    expect(report.solved, true);
    expect(report.optimalMoves, g.report.optimalMoves);
    expect(report.optimalMoves, inInclusiveRange(8, 30));
    expect(report.pushes, greaterThanOrEqualTo(3));
  });

  test('같은 시드는 같은 결과 (재현 가능)', () {
    final a = generate(Random(7), _easySpec);
    final b = generate(Random(7), _easySpec);
    expect(a!.rows, b!.rows);
  });

  test('기믹을 요구하면 보드에 실제로 들어간다', () {
    const spec = GenSpec(
      width: 8,
      height: 8,
      eggCount: 2,
      wallCount: 6,
      gimmicks: [Gimmick.ice, Gimmick.portal],
      minOptimal: 8,
      maxOptimal: 40,
      minPushes: 3,
      minStates: 50,
      minDeadlockRatio: 0.0,
      maxStates: 200000,
    );
    final g = generate(Random(3), spec);
    expect(g, isNotNull);
    final tiles = Board.fromAscii(g!.rows).tiles.toSet();
    expect(
        tiles.contains(Tile.ice) ||
            (tiles.contains(Tile.portal1) && tiles.contains(Tile.portal2)),
        true);
  });

  test('toAsciiRows는 기믹 타일을 직렬화하고 왕복한다', () {
    final rows = ['########', '#@\$iio.#', '#1..2bB#', '#c\$...o#', '########'];
    final board = Board.fromAscii(rows);
    expect(Board.fromAscii(board.toAsciiRows()).stateKey, board.stateKey);
  });
}
