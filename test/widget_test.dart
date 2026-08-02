import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:piyak_push/main.dart';
import 'package:piyak_push/services/save_service.dart';
import 'package:piyak_push/ui/screens/chapter_screen.dart';
import 'package:piyak_push/ui/screens/title_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('앱 부팅 → 타이틀 → 챕터 화면 이동', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final save = await SaveService.load();
    await tester.pumpWidget(PiyakPushApp(save: save));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(TitleScreen), findsOneWidget);
    expect(find.text('삐약푸시'), findsOneWidget);

    await tester.tap(find.text('시작'));
    await tester.pumpAndSettle();
    expect(find.byType(ChapterScreen), findsOneWidget);
    expect(find.text('1막 · 배우기'), findsOneWidget);
    expect(find.textContaining('풀밭'), findsOneWidget);
    // 첫 실행이라 1챕터만 열려 있고 나머지는 잠겨 있다
    expect(find.byIcon(Icons.lock_rounded), findsWidgets);
  });
}
