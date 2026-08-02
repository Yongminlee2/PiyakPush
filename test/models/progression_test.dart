import 'package:flutter_test/flutter_test.dart';
import 'package:piyak_push/models/progression.dart';

void main() {
  test('챕터 중간이면 같은 챕터 다음 스테이지', () {
    final s = resolveNextStep(
        chapter: 1, index: 3, levelCount: 10, currentChapterClears: 4);
    expect(s, isA<NextInChapter>());
    expect((s as NextInChapter).index, 4);
  });

  test('챕터 마지막 + 8개 이상 클리어면 다음 챕터', () {
    final s = resolveNextStep(
        chapter: 3, index: 9, levelCount: 10, currentChapterClears: 8);
    expect(s, isA<NextChapter>());
    expect((s as NextChapter).chapter, 4);
  });

  test('챕터 마지막 + 클리어 부족이면 잠김과 부족분', () {
    final s = resolveNextStep(
        chapter: 3, index: 9, levelCount: 10, currentChapterClears: 5);
    expect(s, isA<ChapterLocked>());
    expect((s as ChapterLocked).chapter, 4);
    expect(s.clearsNeeded, 3);
  });

  test('20챕터 마지막 스테이지면 전체 클리어', () {
    final s = resolveNextStep(
        chapter: 20, index: 9, levelCount: 10, currentChapterClears: 10);
    expect(s, isA<AllChaptersCleared>());
  });

  test('19챕터 마지막은 전체 클리어가 아니라 다음 챕터', () {
    final s = resolveNextStep(
        chapter: 19, index: 9, levelCount: 10, currentChapterClears: 10);
    expect(s, isA<NextChapter>());
    expect((s as NextChapter).chapter, 20);
  });
}
