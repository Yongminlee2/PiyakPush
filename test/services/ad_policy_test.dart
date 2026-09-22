/// 광고를 **언제** 띄울지의 규칙.
///
/// 광고는 한 번 잘못 띄우면 사람이 떠나거나 정책에 걸리는데, 눈으로 확인하기
/// 가장 어려운 종류다. 그래서 판단을 화면에서 떼어내 여기서 못박는다.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:piyak_push/services/ad_policy.dart';

bool _show({
  required int clears,
  Duration? sinceLast,
  bool adReady = true,
}) =>
    InterstitialPolicy.shouldShow(
      clears: clears,
      sinceLast: sinceLast,
      adReady: adReady,
    );

void main() {
  group('전면 광고', () {
    test('시작하자마자는 절대 안 띄운다', () {
      // 튜토리얼 구간에서 광고를 보면 그냥 지운다.
      for (var i = 1; i <= InterstitialPolicy.kGraceClears; i++) {
        expect(_show(clears: i), false, reason: '$i번째 판에서 띄웠다');
      }
    });

    test('정해진 판수마다 한 번만', () {
      // 유예 구간을 지난 뒤, 배수일 때만.
      expect(_show(clears: 8), true);
      expect(_show(clears: 9), false);
      expect(_show(clears: 10), false);
      expect(_show(clears: 11), false);
      expect(_show(clears: 12), true);
    });

    test('직전 광고 직후면 안 띄운다', () {
      // 쉬운 판이 몰리면 배수 조건만으로는 연달아 뜬다.
      expect(_show(clears: 12, sinceLast: const Duration(seconds: 30)), false);
      expect(_show(clears: 12, sinceLast: const Duration(minutes: 10)), true);
    });

    test('광고가 준비 안 됐으면 그냥 넘어간다', () {
      // 광고 때문에 다음 판으로 못 가는 일이 있으면 안 된다.
      expect(_show(clears: 12, adReady: false), false);
    });
  });

  group('보상형 광고', () {
    test('하루 상한까지만 볼 수 있다', () {
      expect(RewardPolicy.canWatch(watchedToday: 0), true);
      expect(RewardPolicy.canWatch(watchedToday: RewardPolicy.kPerDay - 1),
          true);
      expect(RewardPolicy.canWatch(watchedToday: RewardPolicy.kPerDay), false,
          reason: '무제한이면 힌트로 다 밀어버려 퍼즐이 성립하지 않는다');
    });

    test('남은 횟수는 음수로 내려가지 않는다', () {
      expect(RewardPolicy.remainingToday(watchedToday: 99), 0);
    });
  });
}
