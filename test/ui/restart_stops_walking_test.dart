/// 새로고침(재시작)을 눌러도 이전 입력이 계속 살아 있던 문제.
///
/// 걸음은 `_step` → 타이머 → `_afterStep` → `_step` 으로 **스스로 도는 고리**다.
/// 누르고 있는 방향(`_heldDir`)이 남아 있으면 계속 돈다.
/// 그런데 재시작·되돌리기는 그 방향을 지우지 않았다. 그래서
/// 손 뗀 신호를 한 번 놓치면(버튼이 다시 그려지거나 화면이 바뀔 때 생긴다)
/// **재시작을 해도 병아리가 계속 걷고, 걸음마다 소리가 끝없이 난다.**
/// 소리가 끝없이 나면 네이티브 오디오 자원이 쌓여 앱이 통째로 꺼진다.
///
/// 벽에 대고 누르고 있을 때도 같다 — 막힌 걸 알면서 160ms마다
/// 계속 부딪혀 소리를 냈다.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:piyak_push/engine/geometry.dart';
import 'package:piyak_push/models/level.dart';
import 'package:piyak_push/ui/screens/game_screen.dart';
import 'package:piyak_push/ui/widgets/board_view.dart';

/// 가로로 긴 복도. 알은 병아리 경로 밖에 둔다 — 알이 없으면 시작부터
/// 클리어로 판정돼 이동이 막힌다.
final _hall = Level(
  id: 'c1s01',
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

int _chickX(WidgetTester tester) =>
    tester.widget<BoardView>(find.byType(BoardView)).board.chick.x;

void main() {
  testWidgets('재시작하면 누르고 있던 방향이 끊긴다', (tester) async {
    final key = GlobalKey<State<GameScreen>>();
    await tester.pumpWidget(MaterialApp(
      home: GameScreen(key: key, level: _hall),
    ));
    await tester.pump();
    final start = _chickX(tester);
    final state = key.currentState! as dynamic;

    // 누른 채로 몇 걸음 걷는다 (손 떼는 신호는 오지 않는다)
    state.holdDir(Dir.right);
    for (var i = 0; i < 3; i++) {
      await tester.pump(kMoveAnim);
    }
    expect(_chickX(tester), greaterThan(start), reason: '걷고 있어야 한다');

    // 새로고침 버튼을 실제로 누른다 — 판이 처음으로 돌아간다
    await tester.tap(find.byIcon(Icons.refresh_rounded));
    await tester.pump();
    expect(_chickX(tester), start, reason: '재시작하면 처음 자리로');

    // 여기서부터는 아무 입력도 없다. 그런데도 걸으면 이전 입력이 살아 있는 것이다.
    for (var i = 0; i < 5; i++) {
      await tester.pump(kMoveAnim);
    }
    expect(_chickX(tester), start,
        reason: '재시작했는데도 이전에 누르던 방향으로 계속 걷는다');

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('벽에 대고 계속 눌러도 부딪히는 소리가 끝없이 나지 않는다', (tester) async {
    var blocked = 0;
    final key = GlobalKey<State<GameScreen>>();
    await tester.pumpWidget(MaterialApp(
      home: GameScreen(
        key: key,
        level: _hall,
        onBlocked: () => blocked++,
      ),
    ));
    await tester.pump();
    final state = key.currentState! as dynamic;

    // 왼쪽은 바로 벽이다. 누른 채로 오래 둔다.
    state.holdDir(Dir.left);
    for (var i = 0; i < 20; i++) {
      await tester.pump(kMoveAnim);
    }

    expect(blocked, lessThanOrEqualTo(2),
        reason: '막힌 걸 알면서 계속 부딪힌다 ($blocked번) — '
            '소리가 끝없이 나면 오디오 자원이 쌓여 앱이 꺼진다');

    await tester.pumpWidget(const SizedBox());
  });
}
