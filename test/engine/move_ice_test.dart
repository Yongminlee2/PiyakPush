import 'package:flutter_test/flutter_test.dart';
import 'package:piyak_push/engine/board.dart';
import 'package:piyak_push/engine/geometry.dart';
import 'package:piyak_push/engine/move.dart';

void main() {
  test('얼음 지나 바닥에서 정지 + 칸당 eggSlid 이벤트', () {
    final o = Board.fromAscii(['#######', '#@\$ii.#', '#....o#', '#######'])
        .tryMove(Dir.right);
    expect(o.board!.eggs, {const Point(5, 1)});
    expect(o.events.where((e) => e.type == GameEventType.eggSlid).length, 2);
  });

  test('얼음에서 둥지로 미끄러져 클리어', () {
    final o =
        Board.fromAscii(['#######', '#@\$iio#', '#######']).tryMove(Dir.right);
    expect(o.board!.eggs, {const Point(5, 1)});
    expect(o.board!.isCleared, true);
    expect(o.events.map((e) => e.type), contains(GameEventType.eggNested));
  });

  test('얼음 중간 벽에 막히면 얼음 위에서 정지', () {
    final o = Board.fromAscii(['######', '#@\$i##', '#...o#', '######'])
        .tryMove(Dir.right);
    expect(o.board!.eggs, {const Point(3, 1)});
  });

  test('얼음 위 다른 알에 막힘', () {
    final o = Board.fromAscii(
            ['########', '#@\$i\$.o#', '#.....o#', '########'])
        .tryMove(Dir.right);
    expect(o.board!.eggs.contains(const Point(3, 1)), true);
    expect(o.board!.eggs.contains(const Point(4, 1)), true);
  });

  test('병아리는 얼음에서 한 칸씩 걷는다', () {
    final o = Board.fromAscii(['#####', '#@ii#', '#####']).tryMove(Dir.right);
    expect(o.board!.chick, const Point(2, 1));
  });
}
