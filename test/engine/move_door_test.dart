import 'package:flutter_test/flutter_test.dart';
import 'package:piyak_push/engine/board.dart';
import 'package:piyak_push/engine/geometry.dart';
import 'package:piyak_push/engine/move.dart';
import 'package:piyak_push/engine/tile.dart';

void main() {
  test('버튼 위로 알을 밀면 문 열림 + doorOpened 이벤트', () {
    final o = Board.fromAscii(['#######', '#@\$b.B#', '#....o#', '#######'])
        .tryMove(Dir.right);
    expect(o.board!.doorOpenFor(Tile.doorB), true);
    expect(o.events.map((e) => e.type), contains(GameEventType.doorOpened));
  });

  test('알을 버튼에서 밀어내도 병아리가 버튼을 이어 밟아 문 유지', () {
    final open = Board.fromAscii(['#######', '#@\$b.B#', '#....o#', '#######'])
        .tryMove(Dir.right)
        .board!;
    final o = open.tryMove(Dir.right); // 알은 버튼 밖으로, 병아리가 버튼 위로
    expect(o.board!.chick, const Point(3, 1));
    expect(o.board!.doorOpenFor(Tile.doorB), true);
  });

  test('병아리가 버튼에서 걸어 나가면 문 닫힘 + doorClosed 이벤트', () {
    final onButton =
        Board.fromAscii(['######', '#@b.B#', '######']).tryMove(Dir.right);
    expect(onButton.events.map((e) => e.type),
        contains(GameEventType.doorOpened));
    final o = onButton.board!.tryMove(Dir.left);
    expect(o.board!.doorOpenFor(Tile.doorB), false);
    expect(o.events.map((e) => e.type), contains(GameEventType.doorClosed));
  });

  test('닫힌 문은 병아리에게 벽', () {
    expect(
        Board.fromAscii(['#####', '#@B.#', '#####']).tryMove(Dir.right).blocked,
        true);
  });

  test('문 칸 점유 중엔 버튼을 떼도 안 닫힘 (끼임 방지)', () {
    final base = Board.fromAscii(['#######', '#@.b.B#', '#.....#', '#######']);
    final buttonHeld =
        base.copyWith(eggs: {const Point(3, 1)}, chick: const Point(5, 1));
    expect(buttonHeld.doorOpenFor(Tile.doorB), true); // 버튼 점유
    final released =
        base.copyWith(eggs: {const Point(2, 1)}, chick: const Point(5, 1));
    expect(released.doorOpenFor(Tile.doorB), true); // 병아리가 문 위
    final eggOnDoor =
        base.copyWith(eggs: {const Point(5, 1)}, chick: const Point(1, 1));
    expect(eggOnDoor.doorOpenFor(Tile.doorB), true); // 알이 문 위
  });

  test('미끄러지던 알은 닫힌 문 앞에서 정지', () {
    final o = Board.fromAscii(['########', '#@\$iB.o#', '########'])
        .tryMove(Dir.right);
    expect(o.board!.eggs, {const Point(3, 1)});
  });

  test('d 버튼은 B 문과 무관', () {
    final b = Board.fromAscii(['######', '#@dB.#', '######'])
        .tryMove(Dir.right)
        .board!; // 병아리가 d 버튼 위로
    expect(b.doorOpenFor(Tile.doorD), true);
    expect(b.doorOpenFor(Tile.doorB), false);
    expect(b.tryMove(Dir.right).blocked, true); // B 문은 여전히 닫힘
  });
}
