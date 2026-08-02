import 'package:flutter_test/flutter_test.dart';
import 'package:piyak_push/models/progression.dart';

void main() {
  test('챕터 중간이면 같은 챕터 다음 스테이지', () {
    final s = resolveNextStep(
        chapter: 1, index: 3, levelCount: 10, currentChapterStars: 9);
    expect(s, isA<NextInChapter>());
    expect((s as NextInChapter).index, 4);
  });

  test('챕터 마지막 + 별 12개 이상이면 다음 챕터', () {
    final s = resolveNextStep(
        chapter: 1, index: 9, levelCount: 10, currentChapterStars: 12);
    expect(s, isA<NextChapter>());
    expect((s as NextChapter).chapter, 2);
  });

  test('챕터 마지막 + 별 부족이면 잠김과 부족분', () {
    final s = resolveNextStep(
        chapter: 2, index: 9, levelCount: 10, currentChapterStars: 9);
    expect(s, isA<ChapterLocked>());
    expect((s as ChapterLocked).chapter, 3);
    expect(s.starsNeeded, 3);
  });

  test('마지막 챕터 마지막 스테이지면 전체 클리어', () {
    final s = resolveNextStep(
        chapter: 5, index: 9, levelCount: 10, currentChapterStars: 30);
    expect(s, isA<AllChaptersCleared>());
  });

  test('마지막 챕터는 별이 모자라도 잠김이 아니라 전체 클리어', () {
    final s = resolveNextStep(
        chapter: 5, index: 9, levelCount: 10, currentChapterStars: 3);
    expect(s, isA<AllChaptersCleared>());
  });
}
