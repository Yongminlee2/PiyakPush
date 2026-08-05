/// 폰이 "애니메이션 끄기" 상태여도 병아리는 부드럽게 걸어야 한다.
///
/// 안드로이드의 애니메이터 배율을 끄거나(개발자 옵션) 절전 모드가 켜지면
/// OS가 앱에 "애니메이션을 꺼 달라"고 알린다. 그러면 Flutter는 기본 동작으로
/// **모든 애니메이션을 5% 길이로 줄인다** — 160ms짜리 걸음이 8ms, 즉 한
/// 프레임이 되어 병아리가 칸에서 칸으로 순간이동하듯 딱딱 끊긴다.
/// (기기마다 이 설정이 달라, 같은 앱인데 어떤 폰은 부드럽고 어떤 폰은 끊겼다.)
///
/// 병아리가 걸어가는 모습은 장식이 아니라 "방금 무슨 일이 일어났는지"를
/// 보여 주는 게임의 핵심 피드백이라, OS 설정과 무관하게 지켜야 한다.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:piyak_push/engine/geometry.dart';
import 'package:piyak_push/models/level.dart';
import 'package:piyak_push/ui/screens/game_screen.dart';
import 'package:piyak_push/ui/widgets/board_view.dart';

/// 가로로 긴 빈 복도. 알은 병아리 경로 밖에 둔다 — 알이 하나도 없으면
/// 시작부터 클리어로 판정돼 이동이 막힌다.
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

Offset _chickTopLeft(WidgetTester tester) =>
    tester.getTopLeft(find.byKey(const ValueKey('chick')));

void main() {
  testWidgets('OS가 애니메이션을 꺼도 한 칸 이동은 부드럽게 이어진다', (tester) async {
    // 폰이 "애니메이션 끄기"인 상태를 흉내 낸다.
    tester.binding.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(
      tester.binding.platformDispatcher.clearAccessibilityFeaturesTestValue,
    );

    final key = GlobalKey<State<GameScreen>>();
    await tester.pumpWidget(MaterialApp(home: GameScreen(key: key, level: _hall)));
    await tester.pump();

    final start = _chickTopLeft(tester);
    final cell = tester.widget<BoardView>(find.byType(BoardView)).cellSize;

    final state = key.currentState! as dynamic;
    state.holdDir(Dir.right);
    state.releaseDir();
    await tester.pump(); // 이동 발생, 애니메이션 시작

    // 애니메이션 절반 지점 — 아직 도착 전이라 칸 중간 어딘가에 있어야 한다.
    await tester.pump(Duration(milliseconds: kMoveAnim.inMilliseconds ~/ 2));
    final mid = _chickTopLeft(tester);
    final movedByHalfway = mid.dx - start.dx;

    await tester.pump(kMoveAnim);
    final end = _chickTopLeft(tester);

    expect(end.dx - start.dx, closeTo(cell, 0.5),
        reason: '한 칸(=$cell) 옆으로 갔어야 한다');
    expect(movedByHalfway, greaterThan(0.5),
        reason: '절반 지점에 이미 도착해 있다 — 걸어가지 않고 순간이동했다');
    expect(movedByHalfway, lessThan(cell - 0.5),
        reason: '절반 지점에 이미 도착해 있다 — 걸어가지 않고 순간이동했다');

    await tester.pumpWidget(const SizedBox()); // 무한 반복 연출 정리
  });
}
