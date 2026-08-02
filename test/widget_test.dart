import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:piyak_push/main.dart';
import 'package:piyak_push/ui/screens/game_screen.dart';

void main() {
  testWidgets('앱 부팅 → 게임 화면 표시', (tester) async {
    await tester.pumpWidget(const PiyakPushApp());
    await tester.pump(); // FutureBuilder 레벨 로드
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(GameScreen), findsOneWidget);
    await tester.pumpWidget(const SizedBox()); // 타이머 정리
  });
}
