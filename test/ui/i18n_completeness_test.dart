/// 12개 언어 번역 상태 점검.
///
/// 빠진 키는 영어로 대체되므로 화면이 비지는 않지만, 한국어 화면에 영어가
/// 섞여 나오는 식이라 출시 전에는 0이어야 한다. 자리표시자({n})가 번역 중
/// 사라지면 개수가 안 보이므로 그것도 함께 본다.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:piyak_push/ui/strings.dart';
import 'package:piyak_push/ui/strings_data.dart';

void main() {
  final ko = kStrings['ko']!;

  test('모든 언어가 한국어와 같은 키를 갖는다', () {
    final missing = <String, List<String>>{};
    for (final code in kLangCodes) {
      final m = kStrings[code]!;
      final gone = ko.keys.where((k) => !m.containsKey(k)).toList();
      if (gone.isNotEmpty) missing[code] = gone;
    }
    expect(missing, isEmpty, reason: '번역 누락: $missing');
  });

  test('자리표시자가 번역에서 사라지지 않았다', () {
    // 값에 {n}이 들어가야 하는 키
    final withSlot = ko.entries
        .where((e) => e.value.contains('{n}'))
        .map((e) => e.key)
        .toList();
    expect(withSlot, isNotEmpty);
    for (final code in kLangCodes) {
      for (final k in withSlot) {
        expect(kStrings[code]![k], contains('{n}'),
            reason: '$code/$k 에 {n} 없음 — 숫자가 안 보인다');
      }
    }
  });

  test('언어 선택 화면에 12개 언어 이름이 모두 있다', () {
    expect(kLangCodes.length, 12);
    for (final code in kLangCodes) {
      expect(kLangNames[code], isNotNull, reason: code);
      expect(kStrings[code], isNotNull, reason: code);
    }
  });

  test('버튼에 들어가는 짧은 문구가 지나치게 길지 않다', () {
    // 좁은 화면에서 줄바꿈되거나 잘리는 걸 막는 최소한의 방어선.
    const limits = {
      'start': 14, 'daily': 14, 'next': 16, 'undo': 14,
      'restart': 16, 'hint': 14, 'cancel': 14, 'ok': 10,
    };
    final tooLong = <String>[];
    for (final code in kLangCodes) {
      limits.forEach((k, max) {
        final v = kStrings[code]![k]!;
        if (v.length > max) tooLong.add('$code/$k "$v" (${v.length}자)');
      });
    }
    expect(tooLong, isEmpty, reason: tooLong.join('\n'));
  });

  test('언어를 바꾸면 S가 그 언어를 돌려준다', () {
    S.use('ja');
    expect(S.appTitle, 'ピヨプッシュ');
    S.use('ru');
    expect(S.start, 'Играть');
    S.use('ko');
    expect(S.appTitle, '삐약푸쉬');
    // 모르는 코드는 기기 언어로 — 테스트 환경에선 영어
    S.use('xx');
    expect(kLangCodes.contains(S.code), true);
  });
}
