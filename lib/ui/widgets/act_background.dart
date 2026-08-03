/// 막별 배경 — 기존 codex 배너 그림을 하단에 깔고 위는 크림색으로 녹인다.
library;

import 'package:flutter/material.dart';

import '../theme.dart';

class ActBackground extends StatelessWidget {
  final int chapter;

  /// 그림 띠의 높이. null이면 그림 비율대로(1080×400 배너 → 화면폭 기준
  /// 약 150dp). 방향키 모드처럼 더 높은 영역을 받쳐야 할 때 지정한다 —
  /// 배너(2.7:1)가 화면보다 넓어 이때도 잘리는 건 좌우뿐이다.
  final double? height;
  const ActBackground({this.chapter = 1, this.height, super.key});

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
              stops: [0.0, 0.35],
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
