/// 챕터 선택: 5개 카드, 잠금은 이전 챕터 별 12개로 해제.
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/save_service.dart';
import '../strings.dart';
import '../theme.dart';
import 'stage_screen.dart';

class ChapterScreen extends StatelessWidget {
  const ChapterScreen({super.key});

  static const _icons = [
    Icons.grass_rounded,
    Icons.ac_unit_rounded,
    Icons.blur_circular_rounded,
    Icons.radio_button_checked_rounded,
    Icons.broken_image_rounded,
  ];

  @override
  Widget build(BuildContext context) {
    final save = context.watch<SaveService>();
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          S.chapterTitle,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: PiyakColors.outline,
          ),
        ),
        backgroundColor: PiyakColors.creamBg,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 5,
        itemBuilder: (context, i) {
          final c = i + 1;
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
                          : const Text(
                              S.lockedChapter,
                              style: TextStyle(
                                color: PiyakColors.outline,
                                fontSize: 12,
                              ),
                            ),
                      onTap: unlocked
                          ? () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => StageScreen(chapter: c),
                              ),
                            )
                          : null,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
