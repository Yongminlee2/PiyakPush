/// 레벨 파일과 진행 규칙 숫자가 서로 맞는지.
///
/// 챕터를 10판에서 15판으로 늘렸을 때 화면에 박힌 "별 30개 만점"이 그대로
/// 남아 45개를 모아도 "45 / 30"이 뜨고 있었다. 레벨을 늘리거나 줄일 때
/// 같이 고쳐야 할 숫자들을 실제 파일과 대조한다.
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:piyak_push/models/level.dart';
import 'package:piyak_push/models/progression.dart';

void main() {
  final chapters = <int, List<Level>>{};
  for (var c = 1; c <= kChapterCount; c++) {
    chapters[c] = (jsonDecode(
                File('assets/levels/chapter$c.json').readAsStringSync())
            as List)
        .map((e) => Level.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  test('레벨 파일 수가 kChapterCount와 같다', () {
    final files = Directory('assets/levels')
        .listSync()
        .whereType<File>()
        .where((f) => RegExp(r'chapter\d+\.json$').hasMatch(f.path))
        .length;
    expect(files, kChapterCount);
  });

  test('모든 챕터가 kStagesPerChapter 판씩 있다', () {
    chapters.forEach((c, levels) {
      expect(levels.length, kStagesPerChapter, reason: '챕터 $c');
    });
  });

  test('스테이지 id가 c{챕터}s{번호} 규칙을 지킨다', () {
    // SaveService가 이 규칙으로 별을 세므로 어긋나면 진행도가 0이 된다.
    chapters.forEach((c, levels) {
      for (var i = 0; i < levels.length; i++) {
        final want = 'c${c}s${(i + 1).toString().padLeft(2, '0')}';
        expect(levels[i].id, want, reason: '챕터 $c의 ${i + 1}번째');
        expect(levels[i].chapter, c, reason: levels[i].id);
      }
    });
  });

  test('별 만점 계산이 실제 스테이지 수와 맞는다', () {
    final total = chapters.values.fold<int>(0, (n, l) => n + l.length);
    expect(kStarsPerChapter, kStagesPerChapter * 3);
    expect(kMaxStars, total * 3);
  });

  test('챕터 해금 기준이 한 챕터 안에서 달성 가능하다', () {
    // 해금에 필요한 클리어 수가 챕터의 판 수보다 많으면 영구히 갇힌다.
    expect(kChapterUnlockClears, lessThanOrEqualTo(kStagesPerChapter));
  });

  test('마지막 챕터를 깨면 더 갈 곳이 없다고 판정한다', () {
    final step = resolveNextStep(
      chapter: kChapterCount,
      index: kStagesPerChapter - 1,
      levelCount: kStagesPerChapter,
      currentChapterClears: kStagesPerChapter,
    );
    expect(step, isA<AllChaptersCleared>());
  });
}
