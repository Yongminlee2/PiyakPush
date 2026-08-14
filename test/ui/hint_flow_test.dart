/// 힌트를 눌렀을 때의 흐름.
///
/// 힌트는 개수가 정해져 있는데 예전에는 누르는 즉시 하나가 나갔다.
/// 게다가 푸는 데 시간이 걸려(별도 아이솔레이트에서 최대 12만 상태 탐색)
/// 누르고도 한참 아무 반응이 없었고, 길을 못 찾으면 **조용히 아무 일도
/// 일어나지 않아** 힌트가 고장 난 줄 알았다.
///
/// 이제는 먼저 묻고, 푸는 동안 도는 표시를 띄우고, 길이 없으면 그렇다고 알린다.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:piyak_push/engine/geometry.dart';
import 'package:piyak_push/models/level.dart';
import 'package:piyak_push/ui/screens/game_screen.dart';
import 'package:piyak_push/ui/strings.dart';

final _level = Level(
  id: 'c1s01',
  chapter: 1,
  title: '검증용',
  rows: const ['#####', '#@\$o#', '#####'],
  optimal: 1,
);

Widget _screen({
  required Future<List<Dir>?> Function(dynamic) provider,
  required int hintsLeft,
  required void Function() onSpend,
}) =>
    MaterialApp(
      home: GameScreen(
        level: _level,
        hintsLeft: hintsLeft,
        hintProvider: (c) => provider(c),
        onSpendHint: () async {
          onSpend();
          return true;
        },
      ),
    );

/// 병아리 숨쉬기 애니메이션이 끝없이 돌아 pumpAndSettle이 안 끝난다.
/// 팝업이 뜨고 닫힐 만큼만 시간을 돌린다.
Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

void main() {
  tearDown(() => S.use('ko'));

  testWidgets('묻지 않고는 힌트가 나가지 않는다 — 취소하면 그대로', (tester) async {
    var spent = 0;
    var solved = 0;
    await tester.pumpWidget(_screen(
      hintsLeft: 3,
      onSpend: () => spent++,
      provider: (_) async {
        solved++;
        return [Dir.right];
      },
    ));
    await tester.pump();

    await tester.tap(find.byIcon(Icons.lightbulb_outline_rounded));
    await tester.pump();
    expect(find.text(S.hintAsk), findsOneWidget, reason: '먼저 물어야 한다');

    await tester.tap(find.text(S.cancel));
    await _settle(tester);
    expect(spent, 0, reason: '취소했는데 힌트가 나갔다');
    expect(solved, 0, reason: '취소했는데 푸는 일을 했다');

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('쓰겠다고 하면 푸는 동안 도는 표시가 뜨고, 끝나면 하나 나간다', (tester) async {
    var spent = 0;
    final gate = Completer<List<Dir>?>();
    await tester.pumpWidget(_screen(
      hintsLeft: 3,
      onSpend: () => spent++,
      provider: (_) => gate.future,
    ));
    await tester.pump();

    await tester.tap(find.byIcon(Icons.lightbulb_outline_rounded));
    await tester.pump();
    await tester.tap(find.text(S.hintUse));
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget,
        reason: '푸는 동안 기다리는 표시가 있어야 한다');
    expect(spent, 0, reason: '아직 답이 안 나왔는데 힌트가 먼저 나갔다');

    gate.complete([Dir.right]);
    await _settle(tester);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(spent, 1);

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('길이 없으면 알려 주고 힌트를 깎지 않는다', (tester) async {
    var spent = 0;
    await tester.pumpWidget(_screen(
      hintsLeft: 3,
      onSpend: () => spent++,
      provider: (_) async => null, // 풀 수 없는 상태
    ));
    await tester.pump();

    await tester.tap(find.byIcon(Icons.lightbulb_outline_rounded));
    await tester.pump();
    await tester.tap(find.text(S.hintUse));
    await _settle(tester);

    expect(find.text(S.hintNoPath), findsOneWidget,
        reason: '아무 말 없이 넘어가면 고장 난 줄 안다');
    expect(spent, 0, reason: '길도 못 찾았는데 힌트를 깎았다');

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('힌트가 없으면 묻지도 않고 안내만 한다', (tester) async {
    var spent = 0;
    await tester.pumpWidget(_screen(
      hintsLeft: 0,
      onSpend: () => spent++,
      provider: (_) async => [Dir.right],
    ));
    await tester.pump();

    await tester.tap(find.byIcon(Icons.lightbulb_outline_rounded));
    await _settle(tester);

    expect(find.text(S.hintEmpty), findsOneWidget);
    expect(find.text(S.hintAsk), findsNothing);
    expect(spent, 0);

    await tester.pumpWidget(const SizedBox());
  });
}
