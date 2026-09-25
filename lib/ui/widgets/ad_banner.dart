/// 게임 화면 맨 위에 까는 배너. 배너는 이 자리 하나뿐이다.
///
/// 조작(조이스틱·방향키)은 화면 아래쪽이라, 배너를 위에 둬야 광고를 잘못
/// 누르지 않는다.
///
/// 광고를 쓸 수 있으면 **불러오기 전부터 자리를 잡아 둔다** — 판을 하는 도중에
/// 광고가 들어오면서 판이 아래로 밀리면 안 된다. 광고를 못 쓰면(초기화 실패·
/// 인터넷 없음) 아무 자리도 차지하지 않는다.
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
    if (!widget.ads.ready) return const SizedBox.shrink();
    return SizedBox(
      height: AdSize.banner.height.toDouble(),
      child: (!_loaded || ad == null)
          ? null
          : Center(
              child: SizedBox(
                width: ad.size.width.toDouble(),
                height: ad.size.height.toDouble(),
                child: AdWidget(ad: ad),
              ),
            ),
    );
  }
}
