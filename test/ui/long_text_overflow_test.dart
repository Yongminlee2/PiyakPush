/// 번역이 길어져 화면이 깨지는지 확인.
///
/// 한국어는 짧아서 문제가 안 보인다. 스페인어·독일어가 가장 길고
/// ("다음 챕터"=4자 → "Siguiente capítulo"=18자, "이전 챕터를 8판…"=16자 →
/// 53자), 좁은 버튼이나 카드에서 잘리거나 넘칠 수 있다.
/// 실기기에서 12개 언어를 다 눌러보기 전에 기계로 먼저 본다.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:piyak_push/models/level.dart';
import 'package:piyak_push/services/save_service.dart';
import 'package:piyak_push/ui/screens/chapter_screen.dart';
import 'package:piyak_push/ui/screens/game_screen.dart';
import 'package:piyak_push/ui/strings.dart';
import 'package:piyak_push/ui/widgets/clear_popup.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 글자가 가장 긴 축에 속하는 언어들.
const _longest = ['es', 'de', 'fr', 'ru', 'pt'];

final _tutorial = Level(
  id: 'c1s01',
  chapter: 1,
  title: '첫 걸음',
  rows: const ['#####', '#@\$o#', '#####'],
  optimal: 1,
);

void main() {
  tearDown(() => S.use('ko'));

  testWidgets('클리어 팝업의 다음 버튼이 긴 번역에도 안 깨진다', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    for (final code in _longest) {
      S.use(code);
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: ClearPopup(
            stars: 3,
            moves: 10,
            optimal: 8,
            nextLabel: S.nextChapter,
            note: S.chapterCleared,
            onNext: () {},
            onRetry: () {},
            onList: () {},
          ),
        ),
      ));
      await tester.pump(const Duration(milliseconds: 900));
      expect(tester.takeException(), isNull, reason: '$code 에서 깨짐');
    }
  });

  testWidgets('챕터 목록의 잠금 안내가 긴 번역에도 안 깨진다', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    SharedPreferences.setMockInitialValues({});
    final save = await SaveService.load();
    for (final code in _longest) {
      S.use(code);
      await tester.pumpWidget(ChangeNotifierProvider.value(
        value: save,
        child: const MaterialApp(home: ChapterScreen()),
      ));
      await tester.pump(const Duration(milliseconds: 300));
      expect(tester.takeException(), isNull, reason: '$code 에서 깨짐');
    }
  });

  testWidgets('튜토리얼 말풍선이 긴 번역에도 안 깨진다', (tester) async {
    // 좁은 화면일수록 위험하다 — 작은 기기 크기로 본다.
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    for (final code in _longest) {
      S.use(code);
      await tester.pumpWidget(MaterialApp(
        home: GameScreen(level: _tutorial),
      ));
      await tester.pump(const Duration(milliseconds: 300));
      expect(tester.takeException(), isNull, reason: '$code 에서 깨짐');
    }
  });
}
