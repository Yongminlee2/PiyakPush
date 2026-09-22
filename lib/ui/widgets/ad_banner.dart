/// 메뉴 화면 아래에 까는 배너.
///
/// **게임 화면에는 넣지 않는다.** 게임 화면은 조작 영역을 고정으로 빼고 남는
/// 공간에 맞춰 칸 크기를 정한다. 배너를 끼우면 판이 작아지고, 작은 기기에서는
/// 칸이 게임이 안 될 만큼 줄어든다.
///
/// 광고가 없거나(초기화 실패·인터넷 없음) 아직 안 차면 **아무 자리도 차지하지
/// 않는다.** 빈 회색 띠가 남아 있는 것보다 낫다.
library;

import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../../services/ad_service.dart';

class AdBanner extends StatefulWidget {
  final AdService ads;
  const AdBanner({required this.ads, super.key});

  @override
  State<AdBanner> createState() => _AdBannerState();
}

class _AdBannerState extends State<AdBanner> {
  BannerAd? _ad;
  bool _loaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_ad == null) _load();
  }

  void _load() {
    if (!widget.ads.ready) return;
    final width = MediaQuery.sizeOf(context).width.truncate();
    try {
      final ad = BannerAd(
        adUnitId: AdUnits.banner,
        size: AdSize.banner,
        request: const AdRequest(),
        listener: BannerAdListener(
          onAdLoaded: (_) {
            if (mounted) setState(() => _loaded = true);
          },
          onAdFailedToLoad: (ad, _) {
            ad.dispose();
            if (mounted) setState(() => _ad = null);
          },
        ),
      );
      _ad = ad;
      ad.load();
      // width는 기기마다 다르지만 고정 배너를 쓰므로 계산에 쓰지 않는다.
      // (적응형 배너로 바꾸면 여기서 쓴다)
      assert(width > 0);
    } catch (_) {
      _ad = null;
    }
  }

  @override
  void dispose() {
    _ad?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ad = _ad;
    // Scaffold의 하단 슬롯에 놓는다. SafeArea가 시스템 바 몫을 대신 잡아 주므로
    // 광고가 없을 때도 목록 마지막 항목이 내비게이션 바에 가리지 않는다.
    return SafeArea(
      top: false,
      child: (!_loaded || ad == null)
          ? const SizedBox.shrink()
          : SizedBox(
              width: ad.size.width.toDouble(),
              height: ad.size.height.toDouble(),
              child: AdWidget(ad: ad),
            ),
    );
  }
}
