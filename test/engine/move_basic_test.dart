import 'package:flutter_test/flutter_test.dart';
import 'package:piyak_push/engine/board.dart';
import 'package:piyak_push/engine/geometry.dart';
import 'package:piyak_push/engine/move.dart';

void main() {
  test('빈 칸 이동', () {
    final o = Board.fromAscii(['####', '#@.#', '####']).tryMove(Dir.right);
    expect(o.blocked, false);
    expect(o.board!.chick, const Point(2, 1));
    expect(o.events.map((e) => e.type), contains(GameEventType.chickMoved));
  });

  test('벽으로 이동 불가', () {
    final o = Board.fromAscii(['###', '#@#', '###']).tryMove(Dir.right);
    expect(o.blocked, true);
    expect(o.events, isEmpty);
  });

  test('보드 밖 이동 불가', () {
    final o = Board.fromAscii(['@.']).tryMove(Dir.up);
    expect(o.blocked, true);
  });

  test('알 밀기 + 둥지 도착 이벤트 + 클리어', () {
    final o = Board.fromAscii(['#####', '#@\$o#', '#####']).tryMove(Dir.right);
    expect(o.board!.eggs, {const Point(3, 1)});
    expect(o.board!.chick, const Point(2, 1));
    expect(o.board!.isCleared, true);
    final types = o.events.map((e) => e.type);
    expect(types, contains(GameEventType.eggPushed));
    expect(types, contains(GameEventType.eggNested));
  });

  test('알 두 개 연속은 못 밈', () {
    final o = Board.fromAscii(['######', '#@\$\$o#', '#...o#', '######']);
    // 알 2개 둥지 2개 유효 보드
    expect(o.tryMove(Dir.right).blocked, true);
  });

  test('알 뒤가 벽이면 못 밈', () {
    final b = Board.fromAscii(['#####', '#.@\$#', '#..o#', '#####']);
    expect(b.tryMove(Dir.right).blocked, true);
  });

  test('둥지 위 알도 다시 밀 수 있다', () {
    final b = Board.fromAscii(['######', '#@*.o#', '#.\$..#', '######']);
    final o = b.tryMove(Dir.right);
    expect(o.blocked, false);
    expect(o.board!.eggs.contains(const Point(3, 1)), true);
  });

  test('밀기 성공 시 원래 보드는 불변', () {
    final b = Board.fromAscii(['#####', '#@\$o#', '#####']);
    b.tryMove(Dir.right);
    expect(b.chick, const Point(1, 1));
    expect(b.eggs, {const Point(2, 1)});
  });
}
