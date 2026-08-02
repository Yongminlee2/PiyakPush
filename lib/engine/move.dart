/// 이동·밀기 판정. Board는 불변 — tryMove는 새 Board와 이벤트 목록을 돌려준다.
///
/// 처리 순서: ①목표 칸 판정 ②알이면 착지 계산(굴 해석→얼음 슬라이드)
/// ③알 이동 확정 + 떠난 칸 붕괴 ④병아리 이동(막히면 제자리) ⑤병아리가 떠난 칸 붕괴
/// ⑥문 상태 변화 이벤트
library;

import 'board.dart';
import 'geometry.dart';
import 'tile.dart';

enum GameEventType {
  chickMoved,
  chickTeleported,
  eggPushed,
  eggSlid,
  eggTeleported,
  eggNested,
  floorBroke,
  doorOpened,
  doorClosed,
}

class GameEvent {
  final GameEventType type;
  final Point from;
  final Point to;
  const GameEvent(this.type, this.from, this.to);

  @override
  String toString() => '${type.name} $from→$to';
}

class MoveOutcome {
  final Board? board;
  final List<GameEvent> events;
  const MoveOutcome(this.board, this.events);
  bool get blocked => board == null;
}

const _blocked = MoveOutcome(null, []);

extension BoardMove on Board {
  bool occupied(Point p) => p == chick || eggs.contains(p);

  /// 파생 상태: 대응 버튼 위에 알·병아리가 있거나, 그 문 칸 위에
  /// 알·병아리가 있으면 열림(끼임 방지). 저장하지 않는다.
  bool doorOpenFor(Tile door) {
    assert(isDoor(door));
    final btn = buttonForDoor(door);
    for (var i = 0; i < tiles.length; i++) {
      if (tiles[i] != btn && tiles[i] != door) continue;
      if (occupied(Point(i % width, i ~/ width))) return true;
    }
    return false;
  }

  /// 병아리가 밟을 수 있는 칸인가 (알 점유는 밀기로 따로 처리).
  bool _walkable(Point p) {
    if (!inBounds(p)) return false;
    final t = tileAt(p);
    if (t == Tile.wall || t == Tile.hole) return false;
    if (isDoor(t) && !doorOpenFor(t)) return false;
    return true;
  }

  /// 알이 들어갈 수 있는 칸인가.
  bool _eggCanEnter(Point p) {
    if (!_walkable(p)) return false;
    if (occupied(p)) return false;
    return true;
  }

  MoveOutcome tryMove(Dir d) {
    final events = <GameEvent>[];
    final ahead = chick.step(d);
    if (!_walkable(ahead)) return _blocked;

    var newTiles = tiles;
    var newEggs = eggs;
    var newChick = chick;

    // 떠난 칸이 금 간 바닥이면 구멍으로 (T7에서 활성화되는 규칙이지만 로직은 공통)
    List<Tile> breakIfCracked(List<Tile> ts, Point left) {
      if (tileAt(left) != Tile.cracked) return ts;
      final copy = ts == tiles ? List<Tile>.from(ts) : ts;
      copy[left.y * width + left.x] = Tile.hole;
      events.add(GameEvent(GameEventType.floorBroke, left, left));
      return copy;
    }

    if (eggs.contains(ahead)) {
      // ── 밀기: 착지 칸 계산 (굴 해석 → 얼음 슬라이드는 T4/T5에서 확장)
      final landing = _resolveEggLanding(ahead, d, events);
      if (landing == null) return _blocked;

      newEggs = Set<Point>.from(eggs)
        ..remove(ahead)
        ..add(landing);
      events.insert(0, GameEvent(GameEventType.eggPushed, ahead, landing));
      if (tileAt(landing) == Tile.nest) {
        events.add(GameEvent(GameEventType.eggNested, landing, landing));
      }
      // 알이 떠난 칸 붕괴
      newTiles = breakIfCracked(newTiles, ahead);

      // 병아리 진입: 알이 떠난 칸이 방금 구멍이 됐으면 제자리
      final aheadNow =
          newTiles == tiles ? tileAt(ahead) : newTiles[ahead.y * width + ahead.x];
      if (aheadNow != Tile.hole) {
        newChick = ahead;
        events.add(GameEvent(GameEventType.chickMoved, chick, ahead));
      }
    } else {
      // ── 단순 이동 (굴 해석은 T5에서 확장)
      final landing = _resolveChickLanding(ahead, events);
      if (landing == null) return _blocked;
      newChick = landing;
      events.add(GameEvent(GameEventType.chickMoved, chick, landing));
    }

    if (newChick != chick) {
      newTiles = breakIfCracked(newTiles, chick);
    }

    final next = copyWith(tiles: newTiles, eggs: newEggs, chick: newChick);
    _emitDoorChanges(next, events);
    return MoveOutcome(next, events);
  }

  /// [t] 타일이 처음 나오는 위치. 굴 짝 찾기에 사용 (레벨당 굴은 쌍당 1개씩).
  Point? _findTile(Tile t) {
    final idx = tiles.indexOf(t);
    if (idx < 0) return null;
    return Point(idx % width, idx ~/ width);
  }

  /// [p] 칸 진입을 해석해 실제 도착 칸을 돌려준다. 굴이면 짝 굴로 치환.
  /// 진입 불가(막힘·출구 점유)면 null.
  Point? _enterResolved(Point p, GameEventType teleportEvent,
      List<GameEvent> events, bool Function(Point) canEnter) {
    if (!canEnter(p)) return null;
    final pair = portalPair(tileAt(p));
    if (pair == null) return p;
    final exit = _findTile(pair);
    if (exit == null) return p; // 짝 없는 굴은 바닥 취급
    if (occupied(exit)) return null; // 출구 막힘 → 진입 자체 불가
    events.add(GameEvent(teleportEvent, p, exit));
    return exit;
  }

  /// 알이 [from]에서 [d] 방향으로 밀렸을 때 최종 착지 칸. 못 밀면 null.
  ///
  /// 얼음 칸에 있는 동안 같은 방향으로 계속 미끄러지고, 비얼음 칸에
  /// 들어서거나 전방이 막히면 멈춘다. 굴에 들어가면 짝 굴에서 정지
  /// (굴 칸은 얼음이 아니므로 슬라이드 루프가 자연히 끝난다).
  Point? _resolveEggLanding(Point from, Dir d, List<GameEvent> events) {
    final dest =
        _enterResolved(from.step(d), GameEventType.eggTeleported, events, _eggCanEnter);
    if (dest == null) return null;
    var cur = dest;
    while (tileAt(cur) == Tile.ice) {
      final nxt = _enterResolved(
          cur.step(d), GameEventType.eggTeleported, events, _eggCanEnter);
      if (nxt == null) break;
      events.add(GameEvent(GameEventType.eggSlid, cur, nxt));
      cur = nxt;
    }
    return cur;
  }

  /// 병아리가 [dest]로 걸어 들어갈 때 최종 위치. 못 들어가면 null.
  Point? _resolveChickLanding(Point dest, List<GameEvent> events) {
    return _enterResolved(
        dest, GameEventType.chickTeleported, events, _walkable);
  }

  /// 이동 전후로 문 열림 상태가 바뀌었으면 이벤트 발행.
  void _emitDoorChanges(Board next, List<GameEvent> events) {
    for (final door in [Tile.doorB, Tile.doorD]) {
      if (!tiles.contains(door)) continue;
      final before = doorOpenFor(door);
      final after = next.doorOpenFor(door);
      if (before == after) continue;
      final idx = tiles.indexOf(door);
      final p = Point(idx % width, idx ~/ width);
      events.add(GameEvent(
          after ? GameEventType.doorOpened : GameEventType.doorClosed, p, p));
    }
  }
}
