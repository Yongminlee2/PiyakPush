import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:piyak_push/main.dart';
import 'package:piyak_push/services/save_service.dart';
import 'package:piyak_push/services/sound_service.dart';
import 'package:piyak_push/ui/screens/chapter_screen.dart';
import 'package:piyak_push/ui/screens/title_screen.dart';
import 'package:piyak_push/ui/strings.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  // 글자를 그대로 적으면 이름이 바뀌거나 언어가 달라질 때 깨진다.
  // 앱이 쓰는 문자열을 그대로 참조한다.
  testWidgets('앱 부팅 → 타이틀 → 챕터 화면 이동', (tester) async {
    SharedPreferences.setMockInitialValues({'opt.lang': 'ko'});
    final save = await SaveService.load();
    final sound = SoundService(
        isMuted: () => true, playOverride: (_) async {});
    await tester.pumpWidget(PiyakPushApp(save: save, sound: sound));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(TitleScreen), findsOneWidget);
    expect(find.text(S.appTitle), findsOneWidget);

    await tester.tap(find.text(S.start));
    await tester.pumpAndSettle();
    expect(find.byType(ChapterScreen), findsOneWidget);
    expect(find.text(S.actNames.first), findsOneWidget);
    expect(find.textContaining(S.chapterNames.first), findsOneWidget);
    // 첫 실행이라 1챕터만 열려 있고 나머지는 잠겨 있다
    expect(find.byIcon(Icons.lock_rounded), findsWidgets);
  });

  testWidgets('언어를 바꾸면 화면 글자가 그 언어로 바뀐다', (tester) async {
    SharedPreferences.setMockInitialValues({'opt.lang': 'ja'});
    final save = await SaveService.load();
    final sound = SoundService(
        isMuted: () => true, playOverride: (_) async {});
    await tester.pumpWidget(PiyakPushApp(save: save, sound: sound));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('ピヨプッシュ'), findsOneWidget);
    expect(find.text('あそぶ'), findsOneWidget);
  });
}
