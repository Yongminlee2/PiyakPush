/// 방향키를 연타하면 "끊겼다 한 번에 움직이는" 느낌이 나던 문제.
///
/// 원인이 둘이었다.
/// 1. 걷는 중에 들어와 미뤄 둔 걸음은 감속 곡선(easeOut)으로 걸었다. 감속
///    곡선은 **빠르게 출발해 멈추듯 끝난다.** 연타하면 걸음마다 멈췄다가
///    확 튀어 나가는 박자가 되었다.
/// 2. 미뤄 둔 걸음을 **하나만** 기억해서, 빠르게 세 번 누르면 한 번이 사라졌다.
///
/// 연타 내내 한 프레임에 가는 거리가 등속보다 크게 튀지 않는지, 누른 횟수만큼
/// 가는지 본다.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:piyak_push/engine/geometry.dart';
import 'package:piyak_push/models/level.dart';
import 'package:piyak_push/ui/screens/game_screen.dart';
import 'package:piyak_push/ui/widgets/board_view.dart';

final _hall = Level(
  id: 'x',
  chapter: 1,
  title: '검증용',
  rows: const ['############', '#@........\$o#', '############'],
  optimal: 1,
);

void main() {
  testWidgets('연타해도 튀지 않고, 누른 만큼 간다', (tester) async {
    final key = GlobalKey<State<GameScreen>>();
    await tester.pumpWidget(MaterialApp(home: GameScreen(key: key, level: _hall)));
    await tester.pump();
    final view = tester.widget<BoardView>(find.byType(BoardView));
    final cell = view.cellSize;
    final startX = view.board.chick.x;
    double px() => tester.getTopLeft(find.byKey(const ValueKey('chick'))).dx;

    final state = key.currentState! as dynamic;
    const frame = 10;
    const taps = 5;
    var last = px();
    var maxStep = 0.0;
    // 80ms마다 한 번씩 누른다 — 걸음(160ms)보다 두 배 빠른 연타.
    for (var t = 0; t < 1400; t += frame) {
      if (t < taps * 80 && t % 80 == 0) state.holdDir(Dir.right);
      if (t < taps * 80 && t % 80 == 40) state.releaseDir();
      await tester.pump(const Duration(milliseconds: frame));
      final now = px();
      if (now - last > maxStep) maxStep = now - last;
      last = now;
    }

    final chickX = tester.widget<BoardView>(find.byType(BoardView)).board.chick.x;
    expect(chickX - startX, taps, reason: '누른 횟수만큼 가야 한다');
    // 등속이면 한 프레임에 cell*10/160. 감속 곡선의 출발은 그 1.7배쯤 된다.
    final linear = cell * frame / kMoveAnim.inMilliseconds;
    expect(maxStep, lessThan(linear * 1.3), reason: '한 프레임에 확 튀면 안 된다');
  });
}
