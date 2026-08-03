/// 챕터 선택: 5개 카드, 잠금은 이전 챕터 별 12개로 해제.
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/progression.dart';
import '../../services/save_service.dart';
import '../nav.dart';
import '../strings.dart';
import '../theme.dart';
import '../widgets/act_background.dart';
import 'stage_screen.dart';

class ChapterScreen extends StatelessWidget {
  const ChapterScreen({super.key});

  static const _icons = [
    Icons.grass_rounded, Icons.ac_unit_rounded, //
    Icons.blur_circular_rounded, Icons.radio_button_checked_rounded,
    Icons.broken_image_rounded,
    Icons.severe_cold_rounded, Icons.lock_open_rounded, //
    Icons.icecream_rounded, Icons.vpn_key_rounded,
    Icons.warning_amber_rounded,
    Icons.landscape_rounded, Icons.egg_rounded, //
    Icons.cloudy_snowing, Icons.route_rounded,
    Icons.local_florist_rounded,
    Icons.shuffle_rounded, Icons.school_rounded, //
    Icons.filter_5_rounded, Icons.door_front_door_rounded,
    Icons.emoji_events_rounded,
  ];

  @override
  Widget build(BuildContext context) {
    final save = context.watch<SaveService>();
    return Scaffold(
      appBar: AppBar(
        title: Text(
          S.chapterTitle,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: PiyakColors.outline,
          ),
        ),
        backgroundColor: PiyakColors.creamBg,
      ),
      body: Stack(
        children: [
          const ActBackground(wide: true),
          ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: kChapterCount + S.actNames.length,
        itemBuilder: (context, row) {
          // 5챕터마다 막 헤더가 하나씩 앞에 붙는다 — 0·6·12·18번 행이 헤더다.
          final act = row ~/ 6;
          if (row % 6 == 0) {
            return Padding(
              padding: EdgeInsets.only(top: act == 0 ? 0 : 20, bottom: 8),
              child: Text(
                S.actNames[act],
                style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: PiyakColors.outline),
              ),
            );
          }
          final c = act * 5 + (row % 6);
          final i = c - 1;
          final unlocked = save.chapterUnlocked(c);
          final stars = save.chapterStars(c);
          // ListTile은 가장 가까운 Material에 배경과 잉크를 그리므로,
          // 색을 가진 Container로 감싸면 assert가 난다. Material을 직접 쓴다.
          return Container(
            margin: const EdgeInsets.symmetric(vertical: 8),
            child: Material(
              color: unlocked
                  ? Colors.white
                  : Colors.white.withValues(alpha: 0.5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
                side: const BorderSide(color: PiyakColors.outline, width: 2),
              ),
              clipBehavior: Clip.antiAlias,
              child: Row(
                children: [
                  Container(
                    width: 14,
                    height: 96,
                    color: unlocked
                        ? PiyakColors.chapterColors[i]
                        : PiyakColors.outline.withValues(alpha: 0.2),
                  ),
                  Expanded(
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      leading: Icon(
                        unlocked ? _icons[i] : Icons.lock_rounded,
                        size: 36,
                        color: PiyakColors.outline,
                      ),
                      title: Text(
                        '$c. ${S.chapterNames[i]}',
                        style: const TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.bold,
                          color: PiyakColors.outline,
                        ),
                      ),
                      subtitle: unlocked
                          ? Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const SizedBox(height: 4),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(6),
                                  child: LinearProgressIndicator(
                                    value: stars / 30,
                                    minHeight: 8,
                                    backgroundColor: PiyakColors.creamBg,
                                    valueColor: AlwaysStoppedAnimation(
                                      PiyakColors.chapterColors[i],
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.star_rounded,
                                      color: PiyakColors.starYellow,
                                      size: 16,
                                    ),
                                    Text(
                                      ' $stars / 30',
                                      style: const TextStyle(
                                        color: PiyakColors.outline,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            )
                          : Text(
                              S.lockedChapter,
                              style: const TextStyle(
                                color: PiyakColors.outline,
                                fontSize: 12,
                              ),
                            ),
                      onTap: unlocked
                          ? () => Navigator.push(
                              context, piyakRoute(StageScreen(chapter: c)))
                          : null,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
          ),
        ],
      ),
    );
  }
}
