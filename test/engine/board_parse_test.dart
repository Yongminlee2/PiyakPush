import 'package:flutter_test/flutter_test.dart';
import 'package:piyak_push/engine/board.dart';
import 'package:piyak_push/engine/geometry.dart';
import 'package:piyak_push/engine/tile.dart';

void main() {
  test('ASCII 파싱: 기호별 타일·알·병아리 배치', () {
    final b = Board.fromAscii(['#####', '#@\$o#', '#i*c#', '#####']);
    expect(b.width, 5);
    expect(b.height, 4);
    expect(b.chick, const Point(1, 1));
    expect(b.eggs, {const Point(2, 1), const Point(2, 2)});
    expect(b.tileAt(const Point(3, 1)), Tile.nest);
    expect(b.tileAt(const Point(2, 2)), Tile.nest); // '*' 알 밑은 둥지
    expect(b.tileAt(const Point(1, 2)), Tile.ice);
    expect(b.tileAt(const Point(3, 2)), Tile.cracked);
    expect(b.isCleared, false);
  });

  test('굴·버튼·문 기호 파싱', () {
    final b = Board.fromAscii(['#######', '#@1b2B#', '#..dD.#', '#######']);
    expect(b.tileAt(const Point(2, 1)), Tile.portal1);
    expect(b.tileAt(const Point(3, 1)), Tile.buttonB);
    expect(b.tileAt(const Point(4, 1)), Tile.portal2);
    expect(b.tileAt(const Point(5, 1)), Tile.doorB);
    expect(b.tileAt(const Point(3, 2)), Tile.buttonD);
    expect(b.tileAt(const Point(4, 2)), Tile.doorD);
  });

  test('둥지 위 병아리(+) 파싱: 병아리 밑 둥지도 목표로 계수', () {
    final b = Board.fromAscii(['######', '#+\$\$o#', '######']);
    expect(b.tileAt(const Point(1, 1)), Tile.nest);
    expect(b.chick, const Point(1, 1));
    expect(b.eggs.length, 2);
    expect(b.isCleared, false);
  });

  test('모든 알이 둥지 위면 클리어', () {
    final b = Board.fromAscii(['####', '#@*#', '####']);
    expect(b.isCleared, true);
  });

  test('stateKey는 배치 동일하면 동일', () {
    final a = Board.fromAscii(['####', '#@\$#', '#.o#', '####']);
    final b = Board.fromAscii(['####', '#@\$#', '#.o#', '####']);
    expect(a.stateKey, b.stateKey);
  });

  test('알·둥지 수 불일치는 ArgumentError', () {
    expect(() => Board.fromAscii(['####', '#@\$#', '####']), throwsArgumentError);
  });

  test('짧은 행은 벽으로 패딩', () {
    final b = Board.fromAscii(['#####', '#@\$o#', '###']);
    expect(b.tileAt(const Point(4, 2)), Tile.wall);
  });
}
