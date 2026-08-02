/// 타이틀: 로고 + 병아리 + 메뉴 버튼.
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/save_service.dart';
import '../../services/tile_art.dart';
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
          const ActBackground(),
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
                      // codex 로고 그림이 도착하면 이미지로, 그전엔 텍스트로
                      TileArt.logo != null
                          ? Image(image: TileArt.logo!, height: 90)
                          : const Text(
                              S.appTitle,
                              style: TextStyle(
                                fontSize: 44,
                                fontWeight: FontWeight.w900,
                                color: PiyakColors.outline,
                                letterSpacing: 2,
                              ),
                            ),
                      Image.asset('assets/images/chick/chick_cheer.png',
                          height: 120),
                      SizedBox(
                        width: 200,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: save.totalStars / 600,
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
                          Text(' ${save.totalStars} / 600',
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
