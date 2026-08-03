/// 막별 배경 — 기존 codex 배너 그림을 하단에 깔고 위는 크림색으로 녹인다.
library;

import 'package:flutter/material.dart';

import '../theme.dart';

class ActBackground extends StatelessWidget {
  final int chapter;

  /// 그림 띠의 높이. null이면 그림 비율대로.
  final double? height;
  const ActBackground({this.chapter = 1, this.height, super.key});

  /// 그림 위쪽에서 크림색으로 녹여 없애는 구간.
  ///
  /// 지울수록 그림이 덜 보인다. 배경 그림을 세로로 긴 정사각형(1080×1080)으로
  /// 다시 그리면서, 화면 아래 조작 영역(276dp)을 또렷한 부분으로 덮을 수 있게
  /// 35%에서 줄였다.
  static const double fadeStop = 0.25;

  @override
  Widget build(BuildContext context) {
    final act = ((chapter - 1) ~/ 5).clamp(0, 3) + 1;
    return Positioned.fill(
      child: Column(
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
            // 기본은 가로에 맞추고 높이는 비율대로 — 위아래가 안 잘린다.
            child: height == null
                ? Image.asset(
                    'assets/images/bg/bg_act$act.png',
                    width: double.infinity,
                    fit: BoxFit.fitWidth,
                  )
                : Image.asset(
                    'assets/images/bg/bg_act$act.png',
                    width: double.infinity,
                    height: height,
                    fit: BoxFit.cover,
                  ),
          ),
        ],
      ),
    );
  }
}
