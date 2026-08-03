/// 기기가 제각각일 때 화면이 버티는지.
///
/// 전 세계에 뿌리면 화면 크기와 글씨 크기가 천차만별이다.
/// 작은 보급형 기기, 접는 폰의 넓은 화면, 시력 보조로 글씨를 키운 사용자까지
/// 게임 화면이 깨지지 않아야 한다.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:piyak_push/models/level.dart';
import 'package:piyak_push/ui/screens/game_screen.dart';
import 'package:piyak_push/ui/strings.dart';
import 'package:piyak_push/ui/widgets/board_view.dart';

/// 9×9 — 가장 큰 판이라 자리가 모자라면 여기서 먼저 터진다.
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

/// (이름, 실제 픽셀, 배율)
const _devices = [
  ('작은 보급형 (320dp)', Size(960, 1706), 3.0),
  ('보통 (411dp)', Size(1080, 2400), 3.0),
  ('구형 낮은 화면 (360×640dp)', Size(720, 1280), 2.0),
  ('태블릿 (800dp)', Size(1600, 2560), 2.0),
  ('접는폰 펼침 (673dp)', Size(1768, 2208), 2.63),
];

void main() {
  tearDown(() => S.use('ko'));

  testWidgets('여러 기기 크기에서 게임 화면이 안 깨진다', (tester) async {
    for (final (name, px, ratio) in _devices) {
      for (final dpad in [false, true]) {
        tester.view.physicalSize = px;
        tester.view.devicePixelRatio = ratio;
        addTearDown(tester.view.reset);

        await tester.pumpWidget(MaterialApp(
          home: GameScreen(level: _big, useDpad: dpad),
        ));
        await tester.pump(const Duration(milliseconds: 300));
        expect(tester.takeException(), isNull,
            reason: '$name / ${dpad ? "방향키" : "조이스틱"} 에서 깨짐');

        // 판이 보이지 않을 만큼 쪼그라들면 게임이 성립하지 않는다.
        final cell = tester.widget<BoardView>(find.byType(BoardView)).cellSize;
        expect(cell, greaterThanOrEqualTo(20.0),
            reason: '$name 에서 칸이 너무 작다 ($cell)');
      }
    }
  });

  testWidgets('글씨 크게 설정(1.5배)에서도 게임 화면이 안 깨진다', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    for (final scale in [1.3, 1.5, 2.0]) {
      await tester.pumpWidget(MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(scale)),
          child: child!,
        ),
        home: GameScreen(level: _big),
      ));
      await tester.pump(const Duration(milliseconds: 300));
      expect(tester.takeException(), isNull, reason: '글씨 $scale배에서 깨짐');
    }
  });

  testWidgets('가로 화면에서도 게임 화면이 안 깨진다', (tester) async {
    // 세로 고정으로 걸어 뒀지만, 접는폰·태블릿은 가로로 뜰 수 있다.
    tester.view.physicalSize = const Size(2400, 1080);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(MaterialApp(home: GameScreen(level: _big)));
    await tester.pump(const Duration(milliseconds: 300));
    expect(tester.takeException(), isNull);
  });
}
