import 'package:flutter_test/flutter_test.dart';
import 'package:piyak_push/engine/board.dart';
import 'package:piyak_push/engine/geometry.dart';
import 'package:piyak_push/engine/solver.dart';

void main() {
  test('1수 최적해', () {
    expect(Solver().solve(Board.fromAscii(['#####', '#@\$o#', '#####'])),
        [Dir.right]);
  });

  test('이미 클리어면 빈 해', () {
    expect(Solver().solve(Board.fromAscii(['####', '#@*#', '####'])), <Dir>[]);
  });

  test('위로 한 번 밀면 끝', () {
    final sol = Solver()
        .solve(Board.fromAscii(['#####', '#.o.#', '#.\$.#', '#.@.#', '#####']));
    expect(sol, [Dir.up]);
  });

  test('돌아 들어가 미는 최적해 길이', () {
    // 병아리가 알 왼쪽으로 돌아가 오른쪽으로 밀어야 함
    final sol = Solver()
        .solve(Board.fromAscii(['######', '#..\$o#', '#.@..#', '######']))!;
    // (2,2)→(1,2)→(1,1)? (1,1)은 '.', 알 (3,1) 왼쪽 (2,1)로 가서 오른쪽 밀기 1회
    // 최단: (2,2)→(2,1)→밀기 = 2수
    expect(sol.length, 2);
  });

  test('시작부터 데드락이면 null', () {
    expect(
        Solver().solve(Board.fromAscii(['####', '#@\$#', '#o.#', '####'])), null);
  });

  test('얼음 포함 레벨 풀이', () {
    expect(Solver().solve(Board.fromAscii(['#######', '#@\$iio#', '#######'])),
        [Dir.right]);
  });

  test('굴 포함 레벨 풀이', () {
    // 알을 굴로 보낸 뒤(1→2), 병아리가 아래로 돌아가 출구 옆에서 둥지로 밀어 넣기
    final sol = Solver().solve(Board.fromAscii(
        ['########', '#@\$1.2o#', '#......#', '########']));
    expect(sol, isNotNull);
  });
}
