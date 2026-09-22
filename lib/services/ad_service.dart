/// 광고. 화면들이 AdMob을 직접 부르지 않도록 한 겹 감싼다.
///
/// **게임은 광고 없이도 그대로 돌아가야 한다.** 이 앱은 원래 권한이 0개였고
/// 비행기 모드에서 전부 됐다. 광고를 붙이면서 그 성질을 잃으면 안 된다.
/// 그래서 여기 있는 모든 함수는 **실패해도 조용히 아무 일도 안 일어난다** —
/// 인터넷이 없든, 광고가 안 차든, 초기화가 안 됐든.
///
/// 테스트에서는 [AdService.disabled]를 쓰면 광고가 전혀 없는 상태가 된다.
library;

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'ad_policy.dart';

/// 광고 단위 ID.
///
/// **디버그 빌드에서는 구글 테스트 광고를 쓴다.** 개발하다 내 광고를 내가
/// 누르면 AdMob 계정이 정지된다. 실수로라도 그럴 수 없게 빌드로 갈라 둔다.
abstract final class AdUnits {
  static const _testBanner = 'ca-app-pub-3940256099942544/6300978111';
  static const _testInterstitial = 'ca-app-pub-3940256099942544/1033173712';
  static const _testRewarded = 'ca-app-pub-3940256099942544/5224354917';

  static const _realBanner = 'ca-app-pub-6583185616347720/9454308401';
  static const _realInterstitial = 'ca-app-pub-6583185616347720/6850080385';
  static const _realRewarded = 'ca-app-pub-6583185616347720/7405537596';

  static String get banner => kDebugMode ? _testBanner : _realBanner;
  static String get interstitial =>
      kDebugMode ? _testInterstitial : _realInterstitial;
  static String get rewarded => kDebugMode ? _testRewarded : _realRewarded;
}

class AdService {
  /// 광고를 아예 쓰지 않는 서비스 (테스트·광고 끄기용).
  AdService.disabled() : _enabled = false;

  AdService() : _enabled = true;

  final bool _enabled;
  bool _ready = false;

  InterstitialAd? _interstitial;
  bool _loadingInterstitial = false;
  DateTime? _lastInterstitialAt;

  RewardedAd? _rewarded;
  bool _loadingRewarded = false;

  /// 배너를 띄워도 되는지 — 초기화 전에는 자리를 잡지 않는다.
  bool get ready => _enabled && _ready;

  /// 앱 시작 때 한 번. 실패해도 게임은 그대로 시작한다.
  Future<void> init() async {
    if (!_enabled) return;
    try {
      await MobileAds.instance.initialize();
      // 콘텐츠 등급을 "어린이와 성인 모두"로 신고해 뒀다. 그래서 광고도
      // 전체 이용가만 나오게 묶고, 어린이 대상 취급으로 맞춤 광고를 끈다.
      // 수익은 줄지만 정책 위반 위험이 없다.
      await MobileAds.instance.updateRequestConfiguration(
        RequestConfiguration(
          maxAdContentRating: MaxAdContentRating.g,
          ageRestrictedTreatment: AgeRestrictedTreatment.child,
        ),
      );
      _ready = true;
      unawaited(_loadInterstitial());
      unawaited(_loadRewarded());
    } catch (_) {
      // 광고를 못 켜도 게임은 한다.
      _ready = false;
    }
  }

  // ── 전면

  Future<void> _loadInterstitial() async {
    if (!ready || _interstitial != null || _loadingInterstitial) return;
    _loadingInterstitial = true;
    try {
      await InterstitialAd.load(
        adUnitId: AdUnits.interstitial,
        request: const AdRequest(),
        adLoadCallback: InterstitialAdLoadCallback(
          onAdLoaded: (ad) {
            _interstitial = ad;
            _loadingInterstitial = false;
          },
          onAdFailedToLoad: (_) {
            _interstitial = null;
            _loadingInterstitial = false;
          },
        ),
      );
    } catch (_) {
      _loadingInterstitial = false;
    }
  }

  /// 규칙에 맞으면 전면 광고를 띄운다. 안 맞거나 준비가 안 됐으면 아무 일도 없다.
  ///
  /// [clears]는 지금까지 깬 총 판 수. 판단은 [InterstitialPolicy]가 한다.
  Future<void> maybeShowInterstitial(int clears) async {
    if (!ready) return;
    final since = _lastInterstitialAt == null
        ? null
        : DateTime.now().difference(_lastInterstitialAt!);
    if (!InterstitialPolicy.shouldShow(
      clears: clears,
      sinceLast: since,
      adReady: _interstitial != null,
    )) {
      unawaited(_loadInterstitial()); // 다음을 위해 미리 받아 둔다
      return;
    }
    final ad = _interstitial;
    _interstitial = null;
    if (ad == null) return;
    _lastInterstitialAt = DateTime.now();
    try {
      ad.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (a) {
          a.dispose();
          unawaited(_loadInterstitial());
        },
        onAdFailedToShowFullScreenContent: (a, _) {
          a.dispose();
          unawaited(_loadInterstitial());
        },
      );
      await ad.show();
    } catch (_) {
      ad.dispose();
      unawaited(_loadInterstitial());
    }
  }

  // ── 보상형

  Future<void> _loadRewarded() async {
    if (!ready || _rewarded != null || _loadingRewarded) return;
    _loadingRewarded = true;
    try {
      await RewardedAd.load(
        adUnitId: AdUnits.rewarded,
        request: const AdRequest(),
        rewardedAdLoadCallback: RewardedAdLoadCallback(
          onAdLoaded: (ad) {
            _rewarded = ad;
            _loadingRewarded = false;
          },
          onAdFailedToLoad: (_) {
            _rewarded = null;
            _loadingRewarded = false;
          },
        ),
      );
    } catch (_) {
      _loadingRewarded = false;
    }
  }

  /// 지금 보상형 광고를 보여줄 수 있는지.
  bool get rewardedReady => ready && _rewarded != null;

  /// 보상형 광고를 끝까지 봤으면 true. 중간에 닫거나 실패하면 false.
  ///
  /// **false면 보상을 주면 안 된다.**
  Future<bool> showRewarded() async {
    if (!ready) return false;
    final ad = _rewarded;
    _rewarded = null;
    if (ad == null) {
      unawaited(_loadRewarded());
      return false;
    }
    final done = Completer<bool>();
    var earned = false;
    try {
      ad.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (a) {
          a.dispose();
          unawaited(_loadRewarded());
          if (!done.isCompleted) done.complete(earned);
        },
        onAdFailedToShowFullScreenContent: (a, _) {
          a.dispose();
          unawaited(_loadRewarded());
          if (!done.isCompleted) done.complete(false);
        },
      );
      await ad.show(onUserEarnedReward: (_, _) => earned = true);
    } catch (_) {
      ad.dispose();
      unawaited(_loadRewarded());
      if (!done.isCompleted) done.complete(false);
    }
    return done.future;
  }

  /// 미리 받아 둔다 — 힌트가 떨어질 즈음에 이미 준비돼 있게.
  void warmUpRewarded() => unawaited(_loadRewarded());

  void dispose() {
    _interstitial?.dispose();
    _rewarded?.dispose();
    _interstitial = null;
    _rewarded = null;
  }
}
