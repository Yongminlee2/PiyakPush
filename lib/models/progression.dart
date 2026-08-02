/// 스테이지를 깬 뒤 "다음에 무엇을 할지" 판정. 화면 없이 테스트할 수 있도록
/// 순수 함수로 둔다 — v1에서 챕터 마지막 스테이지에 다음 경로가 없던 결손을
/// 재발시키지 않기 위한 분리다.
library;

const int kChapterUnlockStars = 12;
const int kChapterCount = 5;

sealed class NextStep {
  const NextStep();
}

/// 같은 챕터의 [index] 번째 스테이지로 이어서 플레이.
class NextInChapter extends NextStep {
  final int index;
  const NextInChapter(this.index);
}

/// [chapter] 챕터로 넘어간다.
class NextChapter extends NextStep {
  final int chapter;
  const NextChapter(this.chapter);
}

/// [chapter] 챕터가 별 [starsNeeded] 개 부족으로 잠겨 있다.
class ChapterLocked extends NextStep {
  final int chapter;
  final int starsNeeded;
  const ChapterLocked(this.chapter, this.starsNeeded);
}

/// 마지막 챕터의 마지막 스테이지까지 끝냈다.
class AllChaptersCleared extends NextStep {
  const AllChaptersCleared();
}

NextStep resolveNextStep({
  required int chapter,
  required int index,
  required int levelCount,
  required int currentChapterStars,
  int chapterCount = kChapterCount,
}) {
  if (index + 1 < levelCount) return NextInChapter(index + 1);
  if (chapter >= chapterCount) return const AllChaptersCleared();
  if (currentChapterStars >= kChapterUnlockStars) {
    return NextChapter(chapter + 1);
  }
  return ChapterLocked(chapter + 1, kChapterUnlockStars - currentChapterStars);
}
