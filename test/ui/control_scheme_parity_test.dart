/// 조작 방식(조이스틱/방향키)을 바꿔도 화면이 달라 보이면 안 된다.
///
/// 예전에 조이스틱일 때만 조작 영역을 안 잡아 두고 배경 높이도 다르게 줘서,
/// 같은 판인데 보드 칸 크기와 배경이 달라졌다. 그 회귀를 막는다.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:piyak_push/models/level.dart';
import 'package:piyak_push/ui/screens/game_screen.dart';
import 'package:piyak_push/ui/widgets/board_view.dart';
import 'package:piyak_push/ui/widgets/act_background.dart';

/// 9×9 — 세로 공간이 모자라면 칸이 줄어드는 큰 판이라야 차이가 드러난다.
final _big = Level(
  id: 'c20s15',
  chapter: 20,
  title: '검증용',
  rows: const [
    '#########',
    '#@\$....o#',
    '#.......#',
    '#.......#',
    '#.......#',
    '#.......#',
    '#.......#',
    '#.......#',
    '#########',
  ],
  optimal: 5,
);

Future<double> _cellSize(WidgetTester tester, {required bool dpad}) async {
  await tester.pumpWidget(MaterialApp(
    home: GameScreen(level: _big, useDpad: dpad),
  ));
  await tester.pump(const Duration(milliseconds: 200));
  return tester.widget<BoardView>(find.byType(BoardView)).cellSize;
}

Future<double?> _bgHeight(WidgetTester tester, {required bool dpad}) async {
  await tester.pumpWidget(MaterialApp(
    home: GameScreen(level: _big, useDpad: dpad),
  ));
  await tester.pump(const Duration(milliseconds: 200));
  return tester.widget<ActBackground>(find.byType(ActBackground)).height;
}

void main() {
  testWidgets('조작 방식이 달라도 보드 칸 크기가 같다', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    final joystick = await _cellSize(tester, dpad: false);
    final dpad = await _cellSize(tester, dpad: true);
    expect(dpad, joystick,
        reason: '조작 방식을 바꿨다고 판 크기가 달라지면 안 된다');
  });

  testWidgets('조작 방식이 달라도 배경 높이가 같다', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    expect(await _bgHeight(tester, dpad: true),
        await _bgHeight(tester, dpad: false));
  });
}
