/// 방향키를 톡 눌렀다 떼도 병아리가 걸음 도중에 툭 튀지 않아야 한다.
///
/// 누르고 있는 동안은 등속(linear), 떼면 감속(easeOut)으로 곡선이 바뀐다.
/// 예전엔 걸음 도중에 뗀 순간 곡선이 바로 바뀌어서, 같은 시점의 위치가
/// 등속 25% → 감속 50%로 한 프레임 만에 건너뛰었다 — 톡톡 누를 때마다
/// 병아리가 뚝뚝 끊겨 보였다. 곡선은 걸음을 시작할 때 정하고 끝까지 간다.
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
  rows: const [
    '##########',
    '#@.......#',
    '#\$......o#',
    '##########',
  ],
  optimal: 2,
);

double _chickX(WidgetTester tester) =>
    tester.getTopLeft(find.byKey(const ValueKey('chick'))).dx;

void main() {
  testWidgets('걸음 도중에 손을 떼도 위치가 건너뛰지 않는다', (tester) async {
    final key = GlobalKey<State<GameScreen>>();
    await tester.pumpWidget(MaterialApp(home: GameScreen(key: key, level: _hall)));
    await tester.pump();
    final cell = tester.widget<BoardView>(find.byType(BoardView)).cellSize;

    final state = key.currentState! as dynamic;
    state.holdDir(Dir.right);
    await tester.pump(); // 걸음 시작
    await tester.pump(const Duration(milliseconds: 40));
    final before = _chickX(tester);

    state.releaseDir(); // 걸음 도중에 뗀다
    await tester.pump(const Duration(milliseconds: 16));
    final after = _chickX(tester);

    // 16ms면 등속으로 한 칸의 10% 남짓 간다. 곡선이 바뀌어 튀면 25% 넘게 뛴다.
    expect(after - before, lessThan(cell * 0.15));
    await tester.pump(const Duration(seconds: 1)); // 걸음 타이머 정리
  });
}
