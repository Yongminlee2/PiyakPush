import 'package:flutter_test/flutter_test.dart';
import 'package:piyak_push/engine/board.dart';
import 'package:piyak_push/engine/deadlock.dart';

void main() {
  test('모서리(벽 두 방향)에 낀 알은 데드락', () {
    expect(hasCornerDeadlock(Board.fromAscii(['####', '#\$.#', '#.@#', '#o.#', '####'])),
        true);
  });

  test('둥지 위 모서리 알은 데드락 아님', () {
    expect(hasCornerDeadlock(Board.fromAscii(['####', '#*.#', '#.@#', '####'])),
        false);
  });

  test('한쪽만 벽이면 데드락 아님', () {
    expect(
        hasCornerDeadlock(
            Board.fromAscii(['#####', '#.\$.#', '#.@o#', '#####'])),
        false);
  });

  test('보드 밖 경계도 벽 취급', () {
    // 위쪽 테두리 벽이 없는 보드: 알이 (0,0) 모서리
    expect(hasCornerDeadlock(Board.fromAscii(['\$.', '.@', 'o.'])), true);
  });

  test('닫힌 문 옆 알은 데드락 아님 (문은 열릴 수 있음)', () {
    // 알 (2,1): 위는 벽, 오른쪽은 문 → 문은 벽으로 세지 않으므로 데드락 아님
    expect(
        hasCornerDeadlock(
            Board.fromAscii(['#####', '#.\$B#', '#.@.#', '#o.b#', '#####'])),
        false);
  });
}
