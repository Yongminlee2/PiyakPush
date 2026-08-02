import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:piyak_push/models/level.dart';
import 'package:piyak_push/ui/screens/game_screen.dart';
import 'package:piyak_push/ui/widgets/board_view.dart';
import 'package:piyak_push/ui/widgets/clear_popup.dart';
import 'package:piyak_push/ui/widgets/joystick.dart';

Level lv(List<String> rows, {int optimal = 0, String id = 'test'}) => Level(
    id: id, chapter: 1, title: '테스트', rows: rows, optimal: optimal);

Future<void> cleanup(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
}

/// 조이스틱을 한 번 기울였다 놓는다 (한 칸 이동).
Future<void> joyMove(WidgetTester tester, Offset dir) async {
  final band = tester.getCenter(find.byType(Joystick));
  final g = await tester.startGesture(band);
  await g.moveBy(dir);
  await tester.pump(const Duration(milliseconds: 50));
  await g.up();
  await tester.pump(const Duration(milliseconds: 300));
}

void main() {
  testWidgets('클리어 → 팝업과 별 + onCleared 콜백', (tester) async {
    int? gotStars;
    await tester.pumpWidget(MaterialApp(
      home: GameScreen(
        level: lv(['#####', '#@\$o#', '#####'], optimal: 1),
        onCleared: (s) => gotStars = s,
      ),
    ));
    await tester.pump();
    await joyMove(tester, const Offset(40, 0));
    expect(find.byType(ClearPopup), findsOneWidget);
    expect(find.text('클리어!'), findsOneWidget);
    expect(gotStars, 3);
    await tester.pump(const Duration(seconds: 2)); // 별 애니메이션 소진
    await cleanup(tester);
  });

  testWidgets('되돌리기 버튼', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: GameScreen(level: lv(['#######', '#@..\$o#', '#######'], optimal: 3)),
    ));
    await tester.pump();
    await joyMove(tester, const Offset(40, 0));
    expect(find.textContaining('이동 1'), findsOneWidget);
    await tester.tap(find.byTooltip('되돌리기'));
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.textContaining('이동 0'), findsOneWidget);
    await cleanup(tester);
  });

  testWidgets('조이스틱 드래그로 이동하고 놓으면 멈춘다', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home:
          GameScreen(level: lv(['#######', '#@..\$o#', '#######'], optimal: 3)),
    ));
    await tester.pump();
    expect(find.byType(Joystick), findsOneWidget);

    final band = tester.getCenter(find.byType(Joystick));
    final g = await tester.startGesture(band);
    await g.moveBy(const Offset(40, 0)); // 데드존(18px) 초과 → 오른쪽
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.textContaining('이동 1'), findsOneWidget);
    await tester.pump(kMoveAnim); // 홀드 유지 → 두 번째 이동
    expect(find.textContaining('이동 2'), findsOneWidget);
    await g.up();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.textContaining('이동 2'), findsOneWidget); // 더는 안 움직임
    await cleanup(tester);
  });

  testWidgets('데드존 안 드래그는 이동 없음', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home:
          GameScreen(level: lv(['#######', '#@..\$o#', '#######'], optimal: 3)),
    ));
    await tester.pump();
    final band = tester.getCenter(find.byType(Joystick));
    final g = await tester.startGesture(band);
    await g.moveBy(const Offset(10, 0));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.textContaining('이동 0'), findsOneWidget);
    await g.up();
    await tester.pump(const Duration(milliseconds: 300));
    await cleanup(tester);
  });

  testWidgets('clearOutcome의 문구와 버튼이 팝업에 반영된다', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: GameScreen(
        level: lv(['#####', '#@\$o#', '#####'], optimal: 1),
        clearOutcome: () =>
            const ClearOutcome(note: '별 3개만 더 모으면 다음 챕터가 열려요'),
      ),
    ));
    await tester.pump();
    await joyMove(tester, const Offset(40, 0));
    expect(find.text('별 3개만 더 모으면 다음 챕터가 열려요'), findsOneWidget);
    expect(find.text('다음'), findsNothing); // onNext 없으면 다음 버튼도 없다
    await tester.pump(const Duration(seconds: 2));
    await cleanup(tester);
  });

  testWidgets('clearOutcome이 없으면 기존 onNext가 다음 버튼으로 뜬다', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: GameScreen(
        level: lv(['#####', '#@\$o#', '#####'], optimal: 1),
        onNext: () {},
      ),
    ));
    await tester.pump();
    await joyMove(tester, const Offset(40, 0));
    expect(find.text('다음'), findsOneWidget);
    await tester.pump(const Duration(seconds: 2));
    await cleanup(tester);
  });

  testWidgets('튜토리얼 말풍선은 c1s01에서 표시', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: GameScreen(
          level: lv(['#####', '#@\$o#', '#####'], optimal: 1, id: 'c1s01')),
    ));
    await tester.pump();
    expect(find.textContaining('기울여서'), findsOneWidget);
    await cleanup(tester);
  });
}
