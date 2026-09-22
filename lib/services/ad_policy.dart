/// 광고를 **언제** 띄울지 정하는 규칙. AdMob과 무관한 순수 Dart라 테스트된다.
///
/// 이 판단을 화면 코드에 묻으면 검증할 수 없다. 광고는 한 번 잘못 띄우면
/// 사람이 떠나거나 정책에 걸리는데, 눈으로 확인하기 가장 어려운 종류다.
library;

/// 전면 광고 규칙.
///
/// 이 게임은 천천히 생각해서 푸는 퍼즐이다. 매판 광고를 띄우면 게임이 아니라
/// 광고 시청이 된다. 그래서 세 가지로 묶어 둔다.
abstract final class InterstitialPolicy {
  /// 클리어 몇 판마다 한 번 띄울지.
  static const kEveryClears = 4;

  /// 직전 광고와 최소 간격. 빨리 깨는 판이 몰리면 연속으로 뜬다.
  static const kMinGap = Duration(minutes: 3);

  /// 이 수만큼 깨기 전에는 절대 안 띄운다 — 튜토리얼 구간.
  /// 시작하자마자 광고를 보면 그냥 지운다.
  static const kGraceClears = 5;

  /// 띄울까? [clears]는 지금까지 깬 총 판 수(이번 클리어 포함),
  /// [sinceLast]는 직전 전면 광고 이후 지난 시간(한 번도 안 띄웠으면 null).
  static bool shouldShow({
    required int clears,
    required Duration? sinceLast,
    required bool adReady,
  }) {
    // 광고가 준비 안 됐으면 그냥 넘어간다. 광고 때문에 다음 판으로 못 가면 안 된다.
    if (!adReady) return false;
    if (clears <= kGraceClears) return false;
    if (clears % kEveryClears != 0) return false;
    if (sinceLast != null && sinceLast < kMinGap) return false;
    return true;
  }
}

/// 보상형 광고(힌트) 규칙.
abstract final class RewardPolicy {
  /// 광고 한 번에 주는 힌트 개수.
  static const kHintsPerAd = 2;

  /// 하루에 볼 수 있는 횟수. 무제한이면 힌트로 다 밀어버려 퍼즐이 성립하지 않는다.
  static const kPerDay = 5;

  static bool canWatch({required int watchedToday}) => watchedToday < kPerDay;

  static int remainingToday({required int watchedToday}) =>
      (kPerDay - watchedToday).clamp(0, kPerDay);
}
