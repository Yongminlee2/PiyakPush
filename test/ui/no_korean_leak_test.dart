/// 외국어로 설정했을 때 한글이 새어 나오지 않는지 검사.
///
/// 문자열 표에 12개 언어를 채워 넣어도, 어느 한 칸에 한국어가 남아 있거나
/// 코드에 글자가 박혀 있으면 그 화면에서만 한글이 튀어나온다.
/// 눈으로는 12개 언어 × 모든 화면을 다 볼 수 없으니 기계가 본다.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:piyak_push/ui/strings.dart';
import 'package:piyak_push/ui/strings_data.dart';

/// 한글 음절·자모가 하나라도 있으면 true.
bool hasHangul(String s) =>
    RegExp(r'[가-힣ㄱ-ㆎ]').hasMatch(s);

void main() {
  test('한국어 말고는 어느 문자열에도 한글이 없다', () {
    final leaks = <String>[];
    for (final code in kLangCodes) {
      if (code == 'ko') continue;
      kStrings[code]!.forEach((key, value) {
        if (hasHangul(value)) leaks.add('$code / $key = "$value"');
      });
    }
    expect(leaks, isEmpty, reason: '한글이 남아 있다:\n${leaks.join('\n')}');
  });

  test('S가 내주는 값에도 한글이 없다', () {
    // 표에 없고 코드에서 만들어지는 값(스테이지 이름·날짜 등)까지 확인한다.
    final leaks = <String>[];
    for (final code in kLangCodes) {
      if (code == 'ko') continue;
      S.use(code);

      void check(String label, String v) {
        if (hasHangul(v)) leaks.add('$code / $label = "$v"');
      }

      check('appTitle', S.appTitle);
      check('start', S.start);
      check('needMoreClears', S.needMoreClears(3));
      check('hintGot', S.hintGot(2));
      check('date', S.date(8, 4));
      for (final w in S.weekdays) {
        check('weekday', w);
      }
      for (final n in S.chapterNames) {
        check('chapterName', n);
      }
      for (final n in S.actNames) {
        check('actName', n);
      }
      // 스테이지 이름 — 레벨 파일 제목은 한국어라 다른 언어에서는
      // 챕터명으로 만들어야 한다. 원본 제목을 넘겨 새어 나오는지 본다.
      check('stage 기본', S.stageTitle(2, 3, '얼음 세로길'));
      check('stage 도전', S.stageTitle(2, 12, '도전 2'));
    }
    S.use('ko');
    expect(leaks, isEmpty, reason: '한글이 새어 나온다:\n${leaks.join('\n')}');
  });

  test('한국어에서는 한글이 그대로 나온다 (검사가 헛돌지 않는지)', () {
    S.use('ko');
    expect(hasHangul(S.appTitle), true);
    expect(hasHangul(S.date(8, 4)), true);
    expect(hasHangul(S.stageTitle(2, 3, '얼음 세로길')), true);
  });
}
