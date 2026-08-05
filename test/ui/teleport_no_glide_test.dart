/// 굴로 순간이동하는 병아리가 화면 위에서 미끄러지듯 이동하면 안 된다.
///
/// AnimatedPositioned가 이전 칸→새 칸을 항상 [kMoveAnim] 동안 매끄럽게
/// 잇다 보니, 짝 굴이 멀리 떨어져 있으면 순간이동이 아니라 보드를
/// 가로질러 쭉 미끄러져 가는 것처럼 보인다. 애니메이션 절반 지점에
/// 이미 최종 위치에 가 있어야 한다 — 중간에 걸쳐 있으면 미끄러진 것이다.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:piyak_push/engine/geometry.dart';
import 'package:piyak_push/models/level.dart';
import 'package:piyak_push/ui/screens/game_screen.dart';
import 'package:piyak_push/ui/widgets/board_view.dart';

/// 굴 한 쌍이 8칸 떨어져 있는 복도. 굴을 밟으면 짝 굴로 순간이동한다.
/// 알을 하나 두는 이유: 알이 하나도 없으면 [Board.isCleared]가 빈 집합에
/// 대해 무조건 true라 게임이 시작부터 클리어 상태로 판정돼 이동 자체가
/// 막힌다. 병아리의 이동 경로와 무관한 자리에 둔다.
final _portalHall = Level(
  id: 'c1s01',
  chapter: 1,
  title: '검증용',
  rows: const [
    '###########',
    '#@1......2#',
    '#\$.......o#',
    '###########',
  ],
  optimal: 2,
);

Offset _chickTopLeft(WidgetTester tester) =>
    tester.getTopLeft(find.byKey(const ValueKey('chick')));

void main() {
  testWidgets('굴을 통과한 병아리는 미끄러지지 않고 즉시 나타난다', (tester) async {
    final key = GlobalKey<State<GameScreen>>();
    await tester.pumpWidget(MaterialApp(
      home: GameScreen(key: key, level: _portalHall),
    ));
    await tester.pump();
    final start = _chickTopLeft(tester);
    final cell = tester.widget<BoardView>(find.byType(BoardView)).cellSize;

    final state = key.currentState! as dynamic;
    state.holdDir(Dir.right);
    state.releaseDir();
    await tester.pump(); // 이동 발생, 애니메이션 시작

    // 애니메이션 절반 지점 — 미끄러지는 이동이라면 아직 중간쯤이어야 한다.
    await tester.pump(Duration(milliseconds: kMoveAnim.inMilliseconds ~/ 2));
    final mid = _chickTopLeft(tester);

    await tester.pump(kMoveAnim); // 완전히 끝날 때까지
    final end = _chickTopLeft(tester);

    // 굴은 1(x=2)에서 2(x=9)로, 병아리 시작 x=1 기준 8칸을 순간이동한다.
    expect(end.dx - start.dx, closeTo(cell * 8, 0.5),
        reason: '테스트 보드 설계 확인용 — 최종 위치가 굴 짝 자리와 달라졌다');
    expect((mid.dx - end.dx).abs(), lessThan(1.0),
        reason: '절반 지점에서 이미 도착해 있어야 한다 (굴은 순간이동이지 미끄럼이 아니다)');

    await tester.pumpWidget(const SizedBox());
  });
}
