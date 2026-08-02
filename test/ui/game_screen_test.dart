import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:piyak_push/models/level.dart';
import 'package:piyak_push/ui/screens/game_screen.dart';
import 'package:piyak_push/ui/widgets/clear_popup.dart';

Level lv(List<String> rows, {int optimal = 0, String id = 'test'}) => Level(
    id: id, chapter: 1, title: '테스트', rows: rows, optimal: optimal);

Future<void> cleanup(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
}

void main() {
  testWidgets('스와이프로 이동 → 이동수 표시 갱신', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: GameScreen(level: lv(['######', '#@\$.o#', '######'], optimal: 2)),
    ));
    await tester.pump();
    expect(find.textContaining('이동 0'), findsOneWidget);
    await tester.drag(find.byType(GameScreen), const Offset(80, 0));
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.textContaining('이동 1'), findsOneWidget);
    await cleanup(tester);
  });

  testWidgets('클리어 → 팝업과 별 + onCleared 콜백', (tester) async {
    int? gotStars;
    await tester.pumpWidget(MaterialApp(
      home: GameScreen(
        level: lv(['#####', '#@\$o#', '#####'], optimal: 1),
        onCleared: (s) => gotStars = s,
      ),
    ));
    await tester.pump();
    await tester.drag(find.byType(GameScreen), const Offset(80, 0));
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.byType(ClearPopup), findsOneWidget);
    expect(find.text('클리어!'), findsOneWidget);
    expect(gotStars, 3);
    await tester.pump(const Duration(seconds: 2)); // 별 애니메이션 소진
    await cleanup(tester);
  });

  testWidgets('되돌리기 버튼', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: GameScreen(level: lv(['######', '#@\$.o#', '######'], optimal: 2)),
    ));
    await tester.pump();
    await tester.drag(find.byType(GameScreen), const Offset(80, 0));
    await tester.pump(const Duration(milliseconds: 200));
    await tester.tap(find.byTooltip('되돌리기'));
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.textContaining('이동 0'), findsOneWidget);
    await cleanup(tester);
  });

  testWidgets('튜토리얼 말풍선은 c1s01에서 표시', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: GameScreen(
          level: lv(['#####', '#@\$o#', '#####'], optimal: 1, id: 'c1s01')),
    ));
    await tester.pump();
    expect(find.textContaining('스와이프'), findsOneWidget);
    await cleanup(tester);
  });
}
