import 'package:flutter_test/flutter_test.dart';
import 'package:piyak_push/engine/board.dart';
import 'package:piyak_push/engine/geometry.dart';
import 'package:piyak_push/engine/move.dart';

void main() {
  test('병아리 굴 통과', () {
    final o = Board.fromAscii(['######', '#@1.2#', '######']).tryMove(Dir.right);
    expect(o.board!.chick, const Point(4, 1));
    expect(o.events.map((e) => e.type),
        contains(GameEventType.chickTeleported));
  });

  test('알 굴 통과 후 짝 굴 자리에서 정지', () {
    final o = Board.fromAscii(['#######', '#@\$1.2#', '#....o#', '#######'])
        .tryMove(Dir.right);
    expect(o.board!.eggs, {const Point(5, 1)});
    expect(o.events.map((e) => e.type), contains(GameEventType.eggTeleported));
  });

  test('출구가 알로 막히면 병아리 진입 불가', () {
    final b = Board.fromAscii(['######', '#@1.2#', '######'])
        .copyWith(eggs: {const Point(4, 1)});
    expect(b.tryMove(Dir.right).blocked, true);
  });

  test('출구가 막히면 알도 밀 수 없다', () {
    final b = Board.fromAscii(['#######', '#@\$1.2#', '#....o#', '#######'])
        .copyWith(eggs: {const Point(2, 1), const Point(5, 1)});
    expect(b.tryMove(Dir.right).blocked, true);
  });

  test('미끄러지던 알이 굴 진입 → 짝 굴에서 정지', () {
    final o = Board.fromAscii(
            ['##########', '#@\$ii1..2#', '#.......o#', '##########'])
        .tryMove(Dir.right);
    expect(o.board!.eggs, {const Point(8, 1)});
  });

  test('3·4 쌍은 1·2와 독립', () {
    final o = Board.fromAscii(['########', '#@3.1.4#', '#..2...#', '########'])
        .tryMove(Dir.right);
    expect(o.board!.chick, const Point(6, 1)); // 3에서 4로
  });
}
