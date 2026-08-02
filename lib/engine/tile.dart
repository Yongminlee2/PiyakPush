/// 바닥 타일 종류와 기믹 헬퍼.
///
/// 굴은 1↔2, 3↔4가 짝. 버튼 b/d는 같은 글자의 문 B/D를 연다.
library;

enum Tile {
  floor,
  wall,
  nest,
  ice,
  cracked,
  hole,
  portal1,
  portal2,
  portal3,
  portal4,
  buttonB,
  buttonD,
  doorB,
  doorD,
}

Tile? portalPair(Tile t) => switch (t) {
      Tile.portal1 => Tile.portal2,
      Tile.portal2 => Tile.portal1,
      Tile.portal3 => Tile.portal4,
      Tile.portal4 => Tile.portal3,
      _ => null,
    };

bool isPortal(Tile t) => portalPair(t) != null;

bool isButton(Tile t) => t == Tile.buttonB || t == Tile.buttonD;

bool isDoor(Tile t) => t == Tile.doorB || t == Tile.doorD;

Tile doorForButton(Tile b) {
  assert(isButton(b));
  return b == Tile.buttonB ? Tile.doorB : Tile.doorD;
}

Tile buttonForDoor(Tile d) {
  assert(isDoor(d));
  return d == Tile.doorB ? Tile.buttonB : Tile.buttonD;
}
