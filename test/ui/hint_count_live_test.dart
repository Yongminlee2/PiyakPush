/// 힌트를 쓰면 화면의 남은 개수가 따라 줄어야 한다.
///
/// 처음엔 스테이지 화면이 `save.hints`를 **화면을 여는 순간 한 번만** 읽어서
/// GameScreen에 넘겼다. 힌트를 써도 그 숫자가 그대로라,
/// - 확인 팝업이 "남은 힌트 5개"를 계속 보여 주고
/// - **0이 되지 않아 "광고 보고 받기" 안내가 영영 안 떴다.**
///
/// 실기기에서 힌트를 다섯 번 쓰고도 5개로 남아 있는 걸 보고 찾았다.
/// 테스트가 224개 통과하던 때였다 — 화면 사이 배선은 테스트가 못 보던 자리였다.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:piyak_push/models/level.dart';
import 'package:piyak_push/services/save_service.dart';
import 'package:piyak_push/ui/screens/game_screen.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

final _level = Level(
  id: 'c1s01',
  chapter: 1,
  title: '검증용',
  rows: const ['#####', '#@\$o#', '#####'],
  optimal: 1,
);

/// 스테이지·데일리 화면이 GameScreen을 만드는 방식 그대로.
/// (Consumer 없이 밖에서 한 번만 읽으면 이 테스트가 깨진다.)
Widget _route(SaveService save) => ChangeNotifierProvider<SaveService>.value(
      value: save,
      child: MaterialApp(
        home: Consumer<SaveService>(
          builder: (context, s, _) => GameScreen(
            level: _level,
            hintsLeft: s.hints,
            onSpendHint: s.spendHint,
            hintProvider: (c) async => null,
          ),
        ),
      ),
    );

int _shownHints(WidgetTester tester) =>
    tester.widget<GameScreen>(find.byType(GameScreen)).hintsLeft!;

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('힌트를 쓰면 화면에 보이는 남은 개수가 줄어든다', (tester) async {
    final save = await SaveService.load();
    await tester.pumpWidget(_route(save));
    await tester.pump();

    final start = _shownHints(tester);
    expect(start, SaveService.kHintStart);

    await save.spendHint();
    await tester.pump();

    expect(_shownHints(tester), start - 1,
        reason: '힌트를 썼는데 화면 숫자가 그대로다 — '
            '0이 되지 않으면 광고로 받는 길이 열리지 않는다');

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('다 쓰면 화면에 0으로 보인다', (tester) async {
    final save = await SaveService.load();
    await tester.pumpWidget(_route(save));
    await tester.pump();

    for (var i = 0; i < SaveService.kHintStart; i++) {
      await save.spendHint();
    }
    await tester.pump();

    expect(_shownHints(tester), 0,
        reason: '0이 되어야 "힌트를 다 썼어요" 안내와 광고 보기가 뜬다');

    await tester.pumpWidget(const SizedBox());
  });
}
