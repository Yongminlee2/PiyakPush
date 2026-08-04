/// 타이틀: 로고 + 병아리 + 메뉴 버튼.
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/progression.dart';
import '../../services/save_service.dart';
import '../nav.dart';
import '../strings.dart';
import '../theme.dart';
import '../widgets/act_background.dart';
import 'chapter_screen.dart';
import 'daily_screen.dart';
import 'deco_board_screen.dart';
import 'settings_screen.dart';
import 'sticker_book_screen.dart';

class TitleScreen extends StatelessWidget {
  const TitleScreen({super.key});

  Widget _menuButton(
      BuildContext context, IconData icon, String label, Widget page,
      {bool primary = false}) {
    final style = FilledButton.styleFrom(
      backgroundColor: primary ? PiyakColors.chickYellow : Colors.white,
      foregroundColor: PiyakColors.outline,
      minimumSize: const Size(230, 54),
      shape: const StadiumBorder(
        side: BorderSide(color: PiyakColors.outline, width: 2.5),
      ),
      textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: DecoratedBox(
        decoration: const BoxDecoration(
          borderRadius: BorderRadius.all(Radius.circular(27)),
          boxShadow: [
            BoxShadow(
                color: Color(0x335D4037), offset: Offset(0, 4), blurRadius: 0),
          ],
        ),
        child: _Bouncy(
          child: FilledButton.icon(
            style: style,
            onPressed: () => Navigator.push(context, piyakRoute(page)),
            icon: Icon(icon, size: 24),
            label: Text(label),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final save = context.watch<SaveService>();
    return Scaffold(
      body: Stack(
        children: [
          const ActBackground(wide: true),
          SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.fromLTRB(28, 18, 28, 22),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(28),
                    border:
                        Border.all(color: PiyakColors.outline, width: 3),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // 로고를 그림으로 두면 언어를 바꿔도 제목이 안 바뀐다.
                      // 그림 안에 병아리가 또 들어 있어 아래 병아리와 겹치기도
                      // 했다 — 제목은 글자로 그리고 병아리는 하나만 둔다.
                      // 제목을 일곱 번 두드리면 개발자 모드 — 설정에
                      // '모든 챕터 열기'가 나타난다. 배포판에서 아무 스테이지나
                      // 테스트하려면 필요한데, 스위치를 그냥 두면 누구나 누른다.
                      _DevTapArea(
                        child: Text(
                          S.appTitle,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 44,
                            fontWeight: FontWeight.w900,
                            color: PiyakColors.outline,
                            letterSpacing: 1,
                            height: 1.1,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Image.asset('assets/images/chick/chick_cheer.png',
                          height: 120),
                      SizedBox(
                        width: 200,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: save.totalStars / kMaxStars,
                            minHeight: 12,
                            backgroundColor: PiyakColors.creamBg,
                            valueColor: const AlwaysStoppedAnimation(
                                PiyakColors.starYellow),
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.star_rounded,
                              color: PiyakColors.starYellow, size: 20),
                          Text(' ${save.totalStars} / $kMaxStars',
                              style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: PiyakColors.outline)),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                _menuButton(context, Icons.play_arrow_rounded, S.start,
                    const ChapterScreen(),
                    primary: true),
                _menuButton(context, Icons.calendar_month_rounded, S.daily,
                    const DailyScreen()),
                _menuButton(context, Icons.collections_bookmark_rounded,
                    S.stickerBook, const StickerBookScreen()),
                _menuButton(context, Icons.brush_rounded, S.decoBoard,
                    const DecoBoardScreen()),
                _menuButton(context, Icons.settings_rounded, S.settings,
                    const SettingsScreen()),
              ],
            ),
          ),
        ),
          ),
        ],
      ),
    );
  }
}

/// 일곱 번 두드리면 개발자 모드를 켠다 (안드로이드 빌드번호 방식).
class _DevTapArea extends StatefulWidget {
  final Widget child;
  const _DevTapArea({required this.child});

  @override
  State<_DevTapArea> createState() => _DevTapAreaState();
}

class _DevTapAreaState extends State<_DevTapArea> {
  static const _needed = 7;
  int _taps = 0;
  DateTime _last = DateTime.fromMillisecondsSinceEpoch(0);

  void _tap() {
    final now = DateTime.now();
    // 한참 뒤에 누른 건 새로 세기 시작한다 — 우연히 쌓이지 않게
    _taps = now.difference(_last) > const Duration(seconds: 2) ? 1 : _taps + 1;
    _last = now;
    if (_taps < _needed) return;
    _taps = 0;

    final save = context.read<SaveService>();
    final on = !save.devMode;
    save.setDevMode(on);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      duration: const Duration(seconds: 2),
      content: Text(on ? '개발자 모드 켜짐 — 설정에서 모든 챕터를 열 수 있어요'
          : '개발자 모드 꺼짐'),
    ));
  }

  @override
  Widget build(BuildContext context) => GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _tap,
        child: widget.child,
      );
}

/// 눌리는 동안 살짝 줄어드는 반동.
class _Bouncy extends StatefulWidget {
  final Widget child;
  const _Bouncy({required this.child});

  @override
  State<_Bouncy> createState() => _BouncyState();
}

class _BouncyState extends State<_Bouncy> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) => setState(() => _down = true),
      onPointerUp: (_) => setState(() => _down = false),
      onPointerCancel: (_) => setState(() => _down = false),
      child: AnimatedScale(
        scale: _down ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 90),
        child: widget.child,
      ),
    );
  }
}
