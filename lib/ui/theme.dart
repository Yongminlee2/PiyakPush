/// 삐약푸시 팔레트 — 기존 삐약 에셋 스타일(진갈색 외곽선 + 파스텔 + 볼터치).
library;

import 'package:flutter/material.dart';

abstract final class PiyakColors {
  static const outline = Color(0xFF5D4037);
  static const creamBg = Color(0xFFFFF8E1);

  /// 보드를 감싸는 판 — 크림 배경보다 한 톤 진해 게임판처럼 보인다.
  static const boardPanel = Color(0xFFF2E7C9);

  /// 챕터 1~20 테마색. 막마다 색 계열이 옮겨간다
  /// (1막 자연색 → 2막 청록 → 3막 보라·분홍 → 4막 주황·자주).
  static const chapterColors = [
    Color(0xFF8FD16A), Color(0xFF7FC8E8), Color(0xFFB98FD6), //
    Color(0xFFF08FB0), Color(0xFFC49A6C),
    Color(0xFF6FC9A8), Color(0xFF5FBFC4), Color(0xFF7FB3E0), //
    Color(0xFF9FA8DC), Color(0xFFB79ED0),
    Color(0xFFD19ADC), Color(0xFFDE9BC0), Color(0xFFE8A0A8), //
    Color(0xFFEDAA92), Color(0xFFF0B87F),
    Color(0xFFF2A25C), Color(0xFFEE8F5C), Color(0xFFE87D6B), //
    Color(0xFFDC6F7E), Color(0xFFC96B92),
  ];

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

/// Jua로 온전히 그릴 수 있는 언어.
///
/// Jua는 한글용 폰트라 가나·한자·키릴·태국 글자가 통째로 없고, 라틴 언어도
/// 악센트 글자(é ñ ü ç …)가 빠져 있다. 없는 글자는 기기 기본 폰트로 대체되는데
/// 그러면 한 단어 안에서 글꼴이 섞여 망가져 보인다(`tool/check_font_coverage.py`).
/// 그래서 완전히 커버되는 언어만 Jua를 쓰고 나머지는 기기 폰트로 그린다.
const kJuaLanguages = {'ko', 'en', 'id'};

/// 스크롤 목록 여백 — 아래쪽에 **시스템 내비게이션 바 몫을 더한다.**
///
/// targetSdk 35(안드로이드 15)부터 앱은 시스템 바 뒤까지 그리는 게 기본이다
/// (edge-to-edge 강제). 예전에는 OS가 아래를 비워 줬지만 이제는 앱이 직접
/// 피해야 한다. 안 피하면 **목록 마지막 항목이 내비게이션 바에 덮여**
/// 끝까지 내려도 다 안 보이고 누르기도 어렵다.
///
/// 배경 그림은 바 뒤까지 이어져 보이는 편이 예쁘다. 그래서 SafeArea로
/// 통째로 잘라내지 않고 **스크롤 여백만** 늘려서, 끝까지 내리면 마지막
/// 항목이 바 위로 올라오게 한다.
EdgeInsets scrollPadding(BuildContext context, {double all = 16}) =>
    EdgeInsets.fromLTRB(
      all,
      all,
      all,
      all + MediaQuery.paddingOf(context).bottom,
    );

ThemeData piyakTheme({String lang = 'ko'}) => ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: PiyakColors.creamBg,
      colorScheme: ColorScheme.fromSeed(
        seedColor: PiyakColors.chickYellow,
        surface: PiyakColors.creamBg,
      ),
      // 둥글둥글한 한글 폰트 (OFL, assets/fonts)
      fontFamily: kJuaLanguages.contains(lang) ? 'Jua' : null,
    );
