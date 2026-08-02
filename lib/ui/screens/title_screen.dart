/// 타이틀: 로고 + 병아리 + 메뉴 버튼.
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/save_service.dart';
import '../strings.dart';
import '../theme.dart';
import 'chapter_screen.dart';
import 'daily_screen.dart';
import 'deco_board_screen.dart';
import 'settings_screen.dart';
import 'sticker_book_screen.dart';

class TitleScreen extends StatelessWidget {
  const TitleScreen({super.key});

  Widget _menuButton(BuildContext context, String label, Widget page,
      {bool primary = false}) {
    final style = FilledButton.styleFrom(
      backgroundColor: primary ? PiyakColors.chickYellow : Colors.white,
      foregroundColor: PiyakColors.outline,
      minimumSize: const Size(220, 52),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: PiyakColors.outline, width: 2.5),
      ),
      textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
                color: Color(0x335D4037), offset: Offset(0, 4), blurRadius: 0),
          ],
        ),
        child: FilledButton(
          style: style,
          onPressed: () => Navigator.push(
              context, MaterialPageRoute(builder: (_) => page)),
          child: Text(label),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final save = context.watch<SaveService>();
    return Scaffold(
      body: SafeArea(
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
                      const Text(
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
                            value: save.totalStars / 150,
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
                          Text(' ${save.totalStars} / 150',
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
                _menuButton(context, S.start, const ChapterScreen(),
                    primary: true),
                _menuButton(context, S.daily, const DailyScreen()),
                _menuButton(context, S.stickerBook, const StickerBookScreen()),
                _menuButton(context, S.decoBoard, const DecoBoardScreen()),
                _menuButton(context, S.settings, const SettingsScreen()),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
