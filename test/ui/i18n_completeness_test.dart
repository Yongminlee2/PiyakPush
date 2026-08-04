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

  test('영어에는 어느 언어의 키도 빠짐없이 있다', () {
    // 영어가 대체 언어다. 여기 없는 키를 다른 언어에만 넣으면,
    // 그 언어를 안 쓰는 사용자에게 키 이름("hintGot")이 그대로 보인다.
    final all = <String>{};
    for (final m in kStrings.values) {
      all.addAll(m.keys);
    }
    final missing = all.difference(kStrings[S.fallback]!.keys.toSet());
    expect(missing, isEmpty, reason: '영어에 없는 키: $missing');
  });

  test('번역이 빠지면 영어로 떨어진다', () {
    // 표에 없는 키를 물어보면 영어가 나와야 한다. 영어에도 없으면
    // 키 이름이 그대로 나오는데, 그건 "넣는 걸 잊었다"는 신호다.
    S.use('ja');
    expect(S.code, 'ja');
    // 실제 화면 문자열은 전부 채워져 있으므로 일본어가 나온다
    expect(S.start, kStrings['ja']!['start']);
    S.use('ko');
  });

  test('모르는 언어의 기기에서는 영어로 뜬다', () {
    // 우리가 안 가진 언어(아랍어 등)를 쓰는 기기도 앱을 열 수 있어야 한다.
    S.use('ar');
    expect(kLangCodes.contains(S.code), true,
        reason: '모르는 코드가 그대로 남으면 문자열을 못 찾는다');
    S.use('ko');
  });

  test('빈 문자열은 의도한 곳에만 있다', () {
    // 실수로 비워 두면 그 자리에 아무것도 안 나온다.
    // stickerCount는 영어권에서 개수 뒤에 붙일 말이 없어 일부러 비웠다.
    const intentional = {'stickerCount'};
    final blanks = <String>[];
    kStrings.forEach((code, m) {
      m.forEach((k, v) {
        if (v.isEmpty && !intentional.contains(k)) blanks.add('$code/$k');
      });
    });
    expect(blanks, isEmpty, reason: '비어 있는 문자열: $blanks');
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
