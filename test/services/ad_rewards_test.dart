/// 보상형 광고로 힌트를 받는 흐름.
///
/// 제일 중요한 것: **광고를 끝까지 안 봤으면 아무것도 주지 않는다.**
/// 그리고 하루 상한을 넘겨 받을 수 없어야 한다.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:piyak_push/services/ad_policy.dart';
import 'package:piyak_push/services/ad_rewards.dart';
import 'package:piyak_push/services/ad_service.dart';
import 'package:piyak_push/services/save_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 광고를 본 척하는 가짜. [watched]로 끝까지 봤는지를 정한다.
class _FakeAds implements AdService {
  final bool watched;
  int shown = 0;
  _FakeAds({required this.watched});

  @override
  Future<bool> showRewarded() async {
    shown++;
    return watched;
  }

  @override
  bool get rewardedReady => true;

  @override
  bool get ready => true;

  @override
  noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('끝까지 보면 힌트를 받는다', () async {
    final save = await SaveService.load();
    final before = save.hints;
    final ads = _FakeAds(watched: true);

    final got = await watchAdForHints(save, ads);

    expect(got, RewardPolicy.kHintsPerAd);
    expect(save.hints, before + RewardPolicy.kHintsPerAd);
    expect(save.rewardedWatchedOn(DateTime.now()), 1);
  });

  test('중간에 닫으면 아무것도 주지 않는다', () async {
    final save = await SaveService.load();
    final before = save.hints;
    final ads = _FakeAds(watched: false);

    final got = await watchAdForHints(save, ads);

    expect(got, 0);
    expect(save.hints, before, reason: '안 봤는데 힌트를 줬다');
    expect(save.rewardedWatchedOn(DateTime.now()), 0,
        reason: '안 본 광고를 횟수에 세면 상한만 깎인다');
  });

  test('하루 상한을 넘으면 광고를 띄우지도 않는다', () async {
    final save = await SaveService.load();
    final ads = _FakeAds(watched: true);

    for (var i = 0; i < RewardPolicy.kPerDay; i++) {
      await watchAdForHints(save, ads);
    }
    final hintsAtCap = save.hints;

    final got = await watchAdForHints(save, ads);

    expect(got, 0);
    expect(save.hints, hintsAtCap);
    expect(ads.shown, RewardPolicy.kPerDay,
        reason: '상한을 넘었는데 광고를 한 번 더 띄웠다');
  });
}
