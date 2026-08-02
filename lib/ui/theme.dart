/// 삐약푸시 팔레트 — 기존 삐약 에셋 스타일(진갈색 외곽선 + 파스텔 + 볼터치).
library;

import 'package:flutter/material.dart';

abstract final class PiyakColors {
  static const outline = Color(0xFF5D4037);
  static const creamBg = Color(0xFFFFF8E1);

  static const grass = Color(0xFFC5E8B0);
  static const grassDark = Color(0xFFB5DCA0);
  static const wallBrown = Color(0xFF9C7B5C);
  static const wallLight = Color(0xFFB99B7C);
  static const nestStraw = Color(0xFFE0B878);
  static const nestDark = Color(0xFFC29A58);
  static const iceBlue = Color(0xFFBFE5F5);
  static const iceShine = Color(0xFFE8F7FD);
  static const holeDark = Color(0xFF52372A);
  static const crack = Color(0xFF8A7355);

  static const portalPurple = Color(0xFFCE93D8);
  static const portalOrange = Color(0xFFFFCC80);
  static const buttonPinkB = Color(0xFFF48FB1);
  static const buttonBlueD = Color(0xFF90CAF9);

  static const eggWhite = Color(0xFFFFFDF2);
  static const blush = Color(0xFFF8BBD0);
  static const starYellow = Color(0xFFFFD54F);
  static const chickYellow = Color(0xFFFFE082);
}

const double kTileGap = 1.5; // 타일 사이 실틈 — 아기자기한 보드게임 느낌
const double kOutlineWidth = 2.5;

ThemeData piyakTheme() => ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: PiyakColors.creamBg,
      colorScheme: ColorScheme.fromSeed(
        seedColor: PiyakColors.chickYellow,
        surface: PiyakColors.creamBg,
      ),
      fontFamily: null, // 시스템 기본(한글 지원)
    );
