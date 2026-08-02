import 'package:flutter_test/flutter_test.dart';
import 'package:piyak_push/engine/board.dart';
import 'package:piyak_push/engine/geometry.dart';
import 'package:piyak_push/engine/move.dart';
import 'package:piyak_push/engine/tile.dart';

Board withTile(Board b, Point p, Tile t) {
  final tiles = List<Tile>.from(b.tiles);
  tiles[p.y * b.width + p.x] = t;
  return b.copyWith(tiles: tiles);
}

void main() {
  test('병아리가 밟고 떠나면 구멍 + 못 돌아감', () {
    final b1 = Board.fromAscii(['#####', '#@c.#', '#####'])
        .tryMove(Dir.right)
        .board!;
    expect(b1.tileAt(const Point(2, 1)), Tile.cracked); // 밟는 중엔 유지
    final o2 = b1.tryMove(Dir.right);
    expect(o2.board!.tileAt(const Point(2, 1)), Tile.hole);
    expect(o2.events.map((e) => e.type), contains(GameEventType.floorBroke));
    expect(o2.board!.tryMove(Dir.left).blocked, true); // 구멍으로 복귀 불가
  });

  test('금 간 바닥 위 알을 밀면 알만 가고 병아리는 제자리', () {
    final base = Board.fromAscii(['#####', '#@\$.#', '#..o#', '#####']);
    final start = withTile(base, const Point(2, 1), Tile.cracked);
    final o = start.tryMove(Dir.right);
    expect(o.blocked, false);
    expect(o.board!.eggs, {const Point(3, 1)});
    expect(o.board!.chick, const Point(1, 1)); // 제자리
    expect(o.board!.tileAt(const Point(2, 1)), Tile.hole);
    final types = o.events.map((e) => e.type);
    expect(types, contains(GameEventType.eggPushed));
    expect(types, contains(GameEventType.floorBroke));
  });

  test('구멍 방향으로는 알을 못 민다', () {
    final base = Board.fromAscii(['#####', '#@\$.#', '#..o#', '#####']);
    final start = withTile(base, const Point(3, 1), Tile.hole);
    expect(start.tryMove(Dir.right).blocked, true);
  });

  test('붕괴 상태는 stateKey에 반영된다', () {
    final before = Board.fromAscii(['#####', '#@c.#', '#####']);
    final after =
        before.tryMove(Dir.right).board!.tryMove(Dir.right).board!;
    final backAtStart = after.copyWith(chick: const Point(1, 1));
    expect(backAtStart.stateKey, isNot(before.stateKey));
  });
}
