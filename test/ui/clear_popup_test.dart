import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:piyak_push/ui/theme.dart';
import 'package:piyak_push/ui/widgets/clear_popup.dart';

Future<void> pumpPopup(WidgetTester tester, int stars) async {
  await tester.pumpWidget(MaterialApp(
    home: ClearPopup(stars: stars, moves: 9, optimal: 7, onRetry: () {}),
  ));
  await tester.pump(const Duration(milliseconds: 1600));
}

int yellowStars(WidgetTester tester) => tester
    .widgetList<Icon>(find.byIcon(Icons.star_rounded))
    .where((i) => i.color == PiyakColors.starYellow)
    .length;

void main() {
  for (final n in [1, 2, 3]) {
    testWidgets('별 $n개면 노란 별 $n개, 전체 별 자리는 3개', (tester) async {
      await pumpPopup(tester, n);
      expect(find.byIcon(Icons.star_rounded), findsNWidgets(3));
      expect(yellowStars(tester), n);
      await tester.pumpWidget(const SizedBox());
    });
  }

  testWidgets('애니메이션 시작 직후에도 별 자리 3개가 렌더된다', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: ClearPopup(stars: 2, moves: 9, optimal: 7, onRetry: () {}),
    ));
    await tester.pump(); // 첫 프레임
    expect(find.byIcon(Icons.star_rounded), findsNWidgets(3));
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpWidget(const SizedBox());
  });

  // 아래 두 건이 v1의 "별이 하나도 안 보이던" 증상을 잡는 회귀 테스트다.
  // 아이콘 위젯이 존재해도 크기가 0이면 화면엔 없는 것과 같으므로,
  // 존재 여부가 아니라 실제 배율을 확인한다.
  testWidgets('미획득 별은 애니메이션 없이 항상 보인다', (tester) async {
    await pumpPopup(tester, 2);
    // 획득한 별 2개 + 카드 등장 연출 1개 — 미획득 별은 연출 없이 그려진다
    expect(find.byType(ScaleTransition), findsNWidgets(3));
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('연출이 끝나면 어떤 별도 크기 0으로 남지 않는다', (tester) async {
    await pumpPopup(tester, 2);
    final scales = tester
        .widgetList<ScaleTransition>(find.byType(ScaleTransition))
        .map((t) => t.scale.value);
    for (final v in scales) {
      expect(v, greaterThan(0.9));
    }
    await tester.pumpWidget(const SizedBox());
  });
}
