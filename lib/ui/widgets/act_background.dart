/// 막별 배경 — 기존 codex 배너 그림을 하단에 깔고 위는 크림색으로 녹인다.
library;

import 'package:flutter/material.dart';

import '../theme.dart';

class ActBackground extends StatelessWidget {
  final int chapter;
  const ActBackground({this.chapter = 1, super.key});

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
            // 높이를 고정하고 cover로 채우면 그림 위아래가 잘린다.
            // 가로에만 맞추고 높이는 그림 비율대로 둔다.
            child: Image.asset(
              'assets/images/bg/bg_act$act.png',
              width: double.infinity,
              fit: BoxFit.fitWidth,
            ),
          ),
        ],
      ),
    );
  }
}
