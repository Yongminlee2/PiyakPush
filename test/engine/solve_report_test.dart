import 'package:flutter_test/flutter_test.dart';
import 'package:piyak_push/engine/board.dart';
import 'package:piyak_push/engine/solver.dart';

void main() {
  test('1수 레벨: 이동 1, 밀기 1', () {
    final r = Solver().analyze(Board.fromAscii(['#####', '#@\$o#', '#####']));
    expect(r.solved, true);
    expect(r.optimalMoves, 1);
    expect(r.pushes, 1);
  });

  test('걷다가 미는 레벨: 밀기는 민 횟수만 센다', () {
    final r =
        Solver().analyze(Board.fromAscii(['######', '#@.\$o#', '######']));
    expect(r.optimalMoves, 2);
    expect(r.pushes, 1);
  });

  test('풀이 불가면 solved=false, optimalMoves=0', () {
    final r =
        Solver().analyze(Board.fromAscii(['####', '#@\$#', '#o.#', '####']));
    expect(r.solved, false);
    expect(r.optimalMoves, 0);
    expect(r.moves, null);
  });

  test('이미 클리어면 빈 해', () {
    final r = Solver().analyze(Board.fromAscii(['####', '#@*#', '####']));
    expect(r.solved, true);
    expect(r.optimalMoves, 0);
    expect(r.pushes, 0);
  });

  test('탐색 상태 수와 데드락 비율이 기록된다', () {
    final r = Solver().analyze(Board.fromAscii(
        ['#######', '#..o..#', '#.\$...#', '#..@..#', '#.....#', '#######']));
    expect(r.solved, true);
    expect(r.statesExplored, greaterThan(0));
    expect(r.deadlockRatio, inInclusiveRange(0.0, 1.0));
  });

  test('solve()는 analyze()의 moves와 같다', () {
    final b = Board.fromAscii(['#####', '#@\$o#', '#####']);
    expect(Solver().solve(b), Solver().analyze(b).moves);
  });
}
