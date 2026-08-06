/// 안드로이드 내비게이션 바에 화면 아래가 가리는지.
///
/// targetSdk 35(안드로이드 15)부터 앱은 **시스템 바 뒤까지 그리는 게 기본**이다
/// (edge-to-edge 강제). 예전에는 OS가 알아서 아래를 비워 줬지만, 이제는 앱이
/// 직접 피해야 한다. 안 피하면 화면 맨 아래가 내비게이션 바에 덮인다 —
/// 버튼이 안 눌리거나 목록 마지막 항목이 반쯤 잘려 보인다.
/// (실제로 같은 계열 앱에서 하단 확인 버튼이 가려지는 일이 있었다.)
///
/// 이 앱은 targetSdk 36이라 그 조건에 그대로 해당한다.
/// 3버튼 내비게이션 바(48dp)를 깔아 두고, 눌러야 하는 것들이 그 위에 있는지 본다.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:piyak_push/models/level.dart';
import 'package:piyak_push/services/save_service.dart';
import 'package:piyak_push/ui/screens/chapter_screen.dart';
import 'package:piyak_push/ui/screens/daily_screen.dart';
import 'package:piyak_push/ui/screens/game_screen.dart';
import 'package:piyak_push/ui/screens/settings_screen.dart';
import 'package:piyak_push/ui/screens/sticker_book_screen.dart';
import 'package:piyak_push/ui/screens/title_screen.dart';
import 'package:piyak_push/ui/strings.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 3버튼 내비게이션 바 높이(48dp). 제스처 바(24dp)보다 크니 이쪽으로 잰다.
const double kNavBar = 48;

final _level = Level(
  id: 'c1s01',
  chapter: 1,
  title: '검증용',
  rows: const ['#####', '#@\$o#', '#####'],
  optimal: 1,
);

/// 화면 아래 [kNavBar]만큼을 시스템 바가 덮은 상태로 [child]를 띄운다.
Widget _withNavBar(Widget child) => Builder(
      builder: (context) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          padding: const EdgeInsets.only(bottom: kNavBar),
          viewPadding: const EdgeInsets.only(bottom: kNavBar),
        ),
        child: child,
      ),
    );

/// [finder]가 가리키는 것들이 내비게이션 바 위에 온전히 있는지 본다.
///
/// finder가 아무것도 못 찾으면 **실패로 친다.** 안 그러면 화면 구조가 바뀌어
/// 못 찾게 됐을 때 조용히 통과해 버려서, 검사한 적 없는 걸 검사했다고 믿게 된다.
void _expectAboveNavBar(WidgetTester tester, Finder finder, String what) {
  final found = finder.evaluate().length;
  expect(found, greaterThan(0), reason: '$what 을(를) 못 찾았다 — 검사가 헛돌았다');

  final screenBottom =
      tester.view.physicalSize.height / tester.view.devicePixelRatio;
  final safeBottom = screenBottom - kNavBar;
  var checked = 0;
  for (var i = 0; i < found; i++) {
    final r = tester.getRect(finder.at(i));
    // 화면 밖(스크롤로 아직 안 보이는 것)은 여기서 따지지 않는다.
    if (r.top >= screenBottom || r.bottom <= 0) continue;
    checked++;
    expect(r.bottom, lessThanOrEqualTo(safeBottom + 0.5),
        reason: '$what 의 아래쪽이 내비게이션 바에 가린다 '
            '(아래끝 ${r.bottom.toStringAsFixed(1)} > 안전선 $safeBottom)');
  }
  expect(checked, greaterThan(0),
      reason: '$what 이(가) 화면에 하나도 안 보인다 — 검사가 헛돌았다');
}

/// 첫 스크롤 목록을 맨 끝까지 보낸다.
///
/// ListView.builder는 아직 안 만든 항목의 높이를 **추정**해서 maxScrollExtent를
/// 낸다. 그래서 한 번 점프하면 그 근처까지만 가고, 거기서 새 항목이 만들어지며
/// 끝이 더 밀린다. 더 안 밀릴 때까지 되풀이해야 진짜 끝이다.
Future<void> _jumpToEnd(WidgetTester tester) async {
  final s = tester.state<ScrollableState>(find.byType(Scrollable).first);
  var last = -1.0;
  for (var i = 0; i < 30 && s.position.maxScrollExtent != last; i++) {
    last = s.position.maxScrollExtent;
    s.position.jumpTo(last);
    await tester.pumpAndSettle();
  }
  expect(s.position.pixels, closeTo(s.position.maxScrollExtent, 0.5),
      reason: '목록 끝까지 못 갔다 — 검사가 헛돌았다');
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });
  tearDown(() => S.use('ko'));

  Future<void> setPhone(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);
  }

  testWidgets('게임 화면 방향키가 내비게이션 바에 안 가린다', (tester) async {
    await setPhone(tester);
    await tester.pumpWidget(MaterialApp(
      home: _withNavBar(GameScreen(level: _level, useDpad: true)),
    ));
    await tester.pump(const Duration(milliseconds: 300));

    // 방향키는 아이콘 버튼 넷 — 가장 아래 것이 아래쪽 화살표다.
    _expectAboveNavBar(
        tester, find.byIcon(Icons.keyboard_arrow_down_rounded), '아래 방향키');
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('타이틀 메뉴 버튼이 내비게이션 바에 안 가린다', (tester) async {
    await setPhone(tester);
    final save = await SaveService.load();
    await tester.pumpWidget(ChangeNotifierProvider.value(
      value: save,
      child: MaterialApp(home: _withNavBar(const TitleScreen())),
    ));
    await tester.pump(const Duration(milliseconds: 300));

    // 맨 아래 버튼이 설정이다.
    _expectAboveNavBar(tester, find.text(S.settings), '설정 버튼');
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('설정 화면 항목이 내비게이션 바에 안 가린다', (tester) async {
    await setPhone(tester);
    final save = await SaveService.load();
    await tester.pumpWidget(ChangeNotifierProvider.value(
      value: save,
      child: MaterialApp(home: _withNavBar(const SettingsScreen())),
    ));
    await tester.pump(const Duration(milliseconds: 300));
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('챕터 목록을 끝까지 내려도 마지막 카드가 다 보인다', (tester) async {
    await setPhone(tester);
    final save = await SaveService.load();
    await tester.pumpWidget(ChangeNotifierProvider.value(
      value: save,
      child: MaterialApp(home: _withNavBar(const ChapterScreen())),
    ));
    await tester.pump(const Duration(milliseconds: 300));

    // 목록 맨 끝으로 — 드래그는 관성 때문에 끝에 정확히 안 서므로 직접 옮긴다.
    await _jumpToEnd(tester);
    _expectAboveNavBar(tester, find.byType(ListTile), '챕터 카드');
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('데일리 화면이 내비게이션 바에 안 가린다', (tester) async {
    await setPhone(tester);
    final save = await SaveService.load();
    await tester.pumpWidget(ChangeNotifierProvider.value(
      value: save,
      child: MaterialApp(home: _withNavBar(const DailyScreen())),
    ));
    await tester.pump(const Duration(milliseconds: 300));
    expect(tester.takeException(), isNull);

    // 달력 마지막 줄이 잘리면 날짜를 못 누른다.
    _expectAboveNavBar(tester, find.text('28'), '달력 날짜');
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('스티커북을 끝까지 내려도 마지막 줄이 다 보인다', (tester) async {
    await setPhone(tester);
    final save = await SaveService.load();
    await tester.pumpWidget(ChangeNotifierProvider.value(
      value: save,
      child: MaterialApp(home: _withNavBar(const StickerBookScreen())),
    ));
    await tester.pump(const Duration(milliseconds: 300));
    expect(tester.takeException(), isNull);

    if (find.byType(Scrollable).evaluate().isNotEmpty) {
      await _jumpToEnd(tester);
    }
    await tester.pumpWidget(const SizedBox());
  });
}
