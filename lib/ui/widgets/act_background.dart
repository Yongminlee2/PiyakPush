/// 막별 배경 — 기존 codex 배너 그림을 하단에 깔고 위는 크림색으로 녹인다.
library;

import 'package:flutter/material.dart';

import '../theme.dart';

class ActBackground extends StatelessWidget {
  final int chapter;

  /// 그림 띠의 높이. null이면 그림 비율대로.
  final double? height;

  /// 가로로 긴 판(1080×400)을 쓸지.
  ///
  /// 게임 화면은 아래쪽이 조작 영역이라 세로로 긴 정사각 그림으로 꽉 채우지만,
  /// 타이틀·챕터·데일리처럼 목록이 세로로 흐르는 화면에서는 배경이 그만큼
  /// 크면 답답하다. 이런 화면은 얇은 띠가 낫다.
  final bool wide;
  const ActBackground({
    this.chapter = 1,
    this.height,
    this.wide = false,
    super.key,
  });

  /// 그림 위쪽에서 크림색으로 녹여 없애는 구간.
  ///
  /// 지울수록 그림이 덜 보인다. 배경 그림을 세로로 긴 정사각형(1080×1080)으로
  /// 다시 그리면서, 화면 아래 조작 영역(276dp)을 또렷한 부분으로 덮을 수 있게
  /// 35%에서 줄였다.
  static const double fadeStop = 0.25;

  /// 배경 그림의 가로세로비. 게임용은 1080×800, 메뉴용은 1080×400.
  ///
  /// 게임용 원본은 1080×1080이지만 그대로 쓰면 화면 절반을 먹어 답답하다.
  /// `tool/shrink_bg.py`로 세로만 눌러 넣는다 — 무지개·해·달이 모두 위쪽에
  /// 있어 잘라내면 사라지기 때문이다.
  static const double aspect = 1080 / 800;
  static const double wideAspect = 1080 / 400;

  @override
  Widget build(BuildContext context) {
    final act = ((chapter - 1) ~/ 5).clamp(0, 3) + 1;
    final name = wide ? 'bg_act${act}_wide' : 'bg_act$act';
    return Positioned.fill(
      child: LayoutBuilder(
        builder: (context, box) {
          // 폭에 맞춘 높이가 화면보다 크면 화면에 맞춘다. 정사각 그림이라
          // 가로로 넓거나 세로가 짧은 기기에서는 그냥 두면 넘친다.
          final fit = box.maxWidth / (wide ? wideAspect : aspect);
          final h = height ?? (fit < box.maxHeight ? fit : box.maxHeight);
          return Column(
            children: [
              const Expanded(
                child: DecoratedBox(
                  decoration: BoxDecoration(color: PiyakColors.creamBg),
                  child: SizedBox.expand(),
                ),
              ),
              ShaderMask(
                shaderCallback: (r) => const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black],
                  stops: [0.0, fadeStop],
                ).createShader(r),
                blendMode: BlendMode.dstIn,
                child: Image.asset(
                  'assets/images/bg/$name.png',
                  width: double.infinity,
                  height: h,
                  fit: BoxFit.cover,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
