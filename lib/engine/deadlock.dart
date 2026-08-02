/// 간단 데드락 감지: 둥지가 아닌 칸의 알이 직교 두 방향이 모두
/// 벽(보드 밖·구멍 포함)이면 더는 어느 축으로도 밀 수 없다.
///
/// 문·다른 알은 벽으로 세지 않는다 — 열리거나 움직일 수 있어 오탐이 된다.
/// 솔버 가지치기와 게임 화면의 슬픔 연출 양쪽에서 쓴다.
library;

import 'board.dart';
import 'geometry.dart';
import 'tile.dart';

bool hasCornerDeadlock(Board b) {
  bool wallAt(Point p) {
    if (!b.inBounds(p)) return true;
    final t = b.tileAt(p);
    return t == Tile.wall || t == Tile.hole;
  }

  for (final egg in b.eggs) {
    if (b.tileAt(egg) == Tile.nest) continue;
    final vertical = wallAt(egg.step(Dir.up)) || wallAt(egg.step(Dir.down));
    final horizontal =
        wallAt(egg.step(Dir.left)) || wallAt(egg.step(Dir.right));
    if (vertical && horizontal) return true;
  }
  return false;
}
