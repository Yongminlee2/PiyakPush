/// 불변 보드 상태: 타일 격자 + 알 위치 집합 + 병아리 위치.
///
/// ASCII 기호: `#`벽 `.`/공백 바닥 `@`병아리 `+`둥지 위 병아리 `$`알 `*`둥지 위 알
/// `o`둥지 `i`얼음 `c`금 간 바닥 `1~4`굴 `b`/`d`버튼 `B`/`D`문
library;

import 'geometry.dart';
import 'tile.dart';

class Board {
  final int width, height;

  /// row-major: index = y * width + x
  final List<Tile> tiles;
  final Set<Point> eggs;
  final Point chick;

  const Board({
    required this.width,
    required this.height,
    required this.tiles,
    required this.eggs,
    required this.chick,
  });

  factory Board.fromAscii(List<String> rows) {
    if (rows.isEmpty) throw ArgumentError('빈 보드');
    final height = rows.length;
    final width = rows.map((r) => r.length).reduce((a, b) => a > b ? a : b);
    final tiles = List<Tile>.filled(width * height, Tile.wall);
    final eggs = <Point>{};
    Point? chick;
    var nests = 0;
    for (var y = 0; y < height; y++) {
      final row = rows[y];
      for (var x = 0; x < width; x++) {
        // 짧은 행은 벽으로 패딩
        final ch = x < row.length ? row[x] : '#';
        final p = Point(x, y);
        Tile tile;
        switch (ch) {
          case '#':
            tile = Tile.wall;
          case '.' || ' ':
            tile = Tile.floor;
          case '@':
            tile = Tile.floor;
            chick = p;
          case '+':
            tile = Tile.nest;
            chick = p;
          case '\$':
            tile = Tile.floor;
            eggs.add(p);
          case '*':
            tile = Tile.nest;
            eggs.add(p);
          case 'o':
            tile = Tile.nest;
          case 'i':
            tile = Tile.ice;
          case 'c':
            tile = Tile.cracked;
          case '1':
            tile = Tile.portal1;
          case '2':
            tile = Tile.portal2;
          case '3':
            tile = Tile.portal3;
          case '4':
            tile = Tile.portal4;
          case 'b':
            tile = Tile.buttonB;
          case 'd':
            tile = Tile.buttonD;
          case 'B':
            tile = Tile.doorB;
          case 'D':
            tile = Tile.doorD;
          default:
            throw ArgumentError('알 수 없는 기호: $ch (행 $y, 열 $x)');
        }
        if (tile == Tile.nest) nests++;
        tiles[y * width + x] = tile;
      }
    }
    if (chick == null) throw ArgumentError('병아리(@ 또는 +)가 없음');
    if (eggs.length != nests) {
      throw ArgumentError('알 ${eggs.length}개 ≠ 둥지 $nests개');
    }
    return Board(
      width: width,
      height: height,
      tiles: tiles,
      eggs: eggs,
      chick: chick,
    );
  }

  Tile tileAt(Point p) => tiles[p.y * width + p.x];

  bool inBounds(Point p) =>
      p.x >= 0 && p.x < width && p.y >= 0 && p.y < height;

  bool get isCleared => eggs.every((e) => tileAt(e) == Tile.nest);

  /// 솔버 방문 판정용 키. 동적인 것만 포함: 병아리·알·아직 안 부서진 금 간 바닥.
  String get stateKey {
    final es = eggs.map((e) => '${e.x},${e.y}').toList()..sort();
    final cracked = <int>[];
    for (var i = 0; i < tiles.length; i++) {
      if (tiles[i] == Tile.cracked) cracked.add(i);
    }
    return '${chick.x},${chick.y}|${es.join(';')}|${cracked.join(';')}';
  }

  Board copyWith({List<Tile>? tiles, Set<Point>? eggs, Point? chick}) => Board(
        width: width,
        height: height,
        tiles: tiles ?? this.tiles,
        eggs: eggs ?? this.eggs,
        chick: chick ?? this.chick,
      );
}
