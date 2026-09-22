/// 보상형 광고를 보고 힌트를 받는 한 줄기. 화면 두 곳(스테이지·데일리)이
/// 똑같이 쓰므로 여기 한 번만 둔다.
library;

import 'ad_policy.dart';
import 'ad_service.dart';
import 'save_service.dart';

/// 광고를 끝까지 봤으면 힌트를 넣어 주고 받은 개수를 돌려준다.
/// 못 봤으면 0 — **아무것도 주지 않는다.**
///
/// 하루 상한도 여기서 지킨다. 광고를 본 횟수는 광고가 실제로 끝났을 때만 센다.
Future<int> watchAdForHints(SaveService save, AdService ads) async {
  final today = DateTime.now();
  if (!RewardPolicy.canWatch(watchedToday: save.rewardedWatchedOn(today))) {
    return 0;
  }
  final watched = await ads.showRewarded();
  if (!watched) return 0;
  await save.addRewardedWatch(today);
  await save.addHints(RewardPolicy.kHintsPerAd);
  return RewardPolicy.kHintsPerAd;
}
