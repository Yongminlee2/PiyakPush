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

  /// 배경 그림의 가로세로비 (1080×1080 = 1.0).
  static const double aspect = 1.0;

  @override
  Widget build(BuildContext context) {
    final act = ((chapter - 1) ~/ 5).clamp(0, 3) + 1;
    return Positioned.fill(
      child: LayoutBuilder(
        builder: (context, box) {
          // 폭에 맞춘 높이가 화면보다 크면 화면에 맞춘다. 정사각 그림이라
          // 가로로 넓거나 세로가 짧은 기기에서는 그냥 두면 넘친다.
          final wide = box.maxWidth / aspect;
          final h = height ?? (wide < box.maxHeight ? wide : box.maxHeight);
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
                  'assets/images/bg/bg_act$act.png',
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
