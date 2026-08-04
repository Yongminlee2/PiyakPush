/// 빠르게 두 번 누르면 두 칸이 한 번에 미끄러지던 문제.
///
/// 한 걸음은 [kMoveAnim] 동안 움직이는데, 그 사이에 다음 입력이 들어오면
/// 애니메이션이 목적지만 바뀌어 첫 칸이 안 보인 채 두 칸을 지나가 버렸다.
/// 걸음이 애니메이션 길이만큼 벌어지는지, 그러면서도 입력을 잃지 않는지 본다.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:piyak_push/engine/geometry.dart';
import 'package:piyak_push/models/level.dart';
import 'package:piyak_push/ui/screens/game_screen.dart';
import 'package:piyak_push/ui/widgets/board_view.dart';

/// 가로로 긴 빈 복도 — 여러 칸 걸어도 막히지 않는다.
final _hall = Level(
  id: 'c1s01',
  chapter: 1,
  title: '검증용',
  rows: const ['##########', '#@......\$o#', '##########'],
  optimal: 1,
);

int _chickX(WidgetTester tester) =>
    tester.widget<BoardView>(find.byType(BoardView)).board.chick.x;

void main() {
  testWidgets('빠르게 두 번 눌러도 한 칸씩 또박또박 간다', (tester) async {
    final key = GlobalKey<State<GameScreen>>();
    await tester.pumpWidget(MaterialApp(
      home: GameScreen(key: key, level: _hall),
    ));
    await tester.pump();
    final start = _chickX(tester);

    final state = key.currentState! as dynamic;

    // 첫 번째 누름 — 바로 한 칸
    state.holdDir(Dir.right);
    state.releaseDir();
    await tester.pump();
    expect(_chickX(tester), start + 1);

    // 20ms 뒤 두 번째 누름 — 아직 첫 걸음이 그려지는 중이라 미뤄져야 한다
    await tester.pump(const Duration(milliseconds: 20));
    state.holdDir(Dir.right);
    state.releaseDir();
    await tester.pump();
    expect(_chickX(tester), start + 1,
        reason: '첫 걸음이 끝나기 전에 두 칸째로 뛰면 안 된다');

    // 애니메이션이 끝나면 미뤄 둔 걸음이 들어온다 — 입력을 잃지 않는다
    await tester.pump(kMoveAnim);
    await tester.pump(const Duration(milliseconds: 20));
    expect(_chickX(tester), start + 2, reason: '누른 입력이 사라졌다');

    await tester.pumpWidget(const SizedBox()); // 무한 반복 연출 정리
  });

  testWidgets('천천히 누르면 즉시 반응한다', (tester) async {
    final key = GlobalKey<State<GameScreen>>();
    await tester.pumpWidget(MaterialApp(
      home: GameScreen(key: key, level: _hall),
    ));
    await tester.pump();
    final start = _chickX(tester);
    final state = key.currentState! as dynamic;

    for (var i = 1; i <= 3; i++) {
      state.holdDir(Dir.right);
      state.releaseDir();
      await tester.pump();
      expect(_chickX(tester), start + i, reason: '$i번째 걸음이 즉시 안 나갔다');
      // 애니메이션이 끝날 만큼 기다린 뒤 다음 입력
      await tester.pump(kMoveAnim + const Duration(milliseconds: 10));
    }
    await tester.pumpWidget(const SizedBox()); // 무한 반복 연출 정리
  });
}
