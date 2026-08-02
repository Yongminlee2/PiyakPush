import 'package:flutter_test/flutter_test.dart';
import 'package:piyak_push/engine/geometry.dart';
import 'package:piyak_push/models/level.dart';
import 'package:piyak_push/ui/game_controller.dart';

Level lv(List<String> rows, {int optimal = 0}) => Level(
    id: 'test', chapter: 1, title: 't', rows: rows, optimal: optimal);

void main() {
  test('이동 성공 시 moves 증가, 실패 시 그대로', () {
    final c = GameController(lv(['#######', '#@..\$o#', '#######']));
    expect(c.move(Dir.right), true);
    expect(c.moves, 1);
    expect(c.move(Dir.up), false); // 벽
    expect(c.moves, 1);
  });

  test('undo는 한 수 되돌리고 시작점에선 무시', () {
    final c = GameController(lv(['#######', '#@..\$o#', '#######']));
    c.move(Dir.right);
    c.move(Dir.right);
    c.undo();
    expect(c.moves, 1);
    expect(c.board.chick, const Point(2, 1));
    c.undo();
    c.undo(); // 초과 — 무시
    expect(c.moves, 0);
  });

  test('restart는 처음으로', () {
    final c = GameController(lv(['#####', '#@\$o#', '#####'], optimal: 1));
    c.move(Dir.right);
    expect(c.cleared, true);
    c.restart();
    expect(c.moves, 0);
    expect(c.cleared, false);
  });

  test('별점: 최적=3★, 1.5배 이내=2★, 그 외=1★', () {
    // 최적 3수 레벨 (아래, 오른쪽×2)
    final rows = ['######', '#@...#', '#.\$.o#', '#....#', '######'];
    final c3 = GameController(lv(rows, optimal: 3));
    c3.move(Dir.down);
    c3.move(Dir.right);
    c3.move(Dir.right);
    expect(c3.cleared, true);
    expect(c3.stars, 3);

    final c2 = GameController(lv(rows, optimal: 3));
    c2.move(Dir.down);
    c2.move(Dir.down);
    c2.move(Dir.up); // 낭비 2수
    c2.move(Dir.right);
    c2.move(Dir.right);
    expect(c2.cleared, true);
    expect(c2.moves, 5); // ceil(4.5)=5 이내
    expect(c2.stars, 2);

    final c1 = GameController(lv(rows, optimal: 3));
    c1.move(Dir.down);
    c1.move(Dir.down);
    c1.move(Dir.up);
    c1.move(Dir.down);
    c1.move(Dir.up);
    c1.move(Dir.right);
    c1.move(Dir.right);
    expect(c1.cleared, true);
    expect(c1.stars, 1);
  });

  test('클리어 전 stars는 0', () {
    final c = GameController(lv(['#####', '#@\$o#', '#####'], optimal: 1));
    expect(c.stars, 0);
  });

  test('무드: 클리어→cheer, 데드락→sad, 대기→think→sleep, 입력 시 idle', () {
    final c = GameController(lv(['#####', '#@\$.#', '#..o#', '#####']));
    expect(c.mood, ChickMood.idle);
    c.markIdle10s();
    expect(c.mood, ChickMood.think);
    c.markIdle30s();
    expect(c.mood, ChickMood.sleep);
    c.move(Dir.down);
    expect(c.mood, ChickMood.idle);
    c.undo();
    c.move(Dir.right); // 알이 오른쪽 위 모서리로 → 데드락
    expect(c.deadlocked, true);
    expect(c.mood, ChickMood.sad);

    final win = GameController(lv(['#####', '#@\$o#', '#####'], optimal: 1));
    win.move(Dir.right);
    expect(win.mood, ChickMood.cheer);
  });
}
