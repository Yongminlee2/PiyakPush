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
        title: const Text(S.chapterTitle,
            style: TextStyle(
                fontWeight: FontWeight.bold, color: PiyakColors.outline)),
        backgroundColor: PiyakColors.creamBg,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 5,
        itemBuilder: (context, i) {
          final c = i + 1;
          final unlocked = save.chapterUnlocked(c);
          final stars = save.chapterStars(c);
          return Card(
            color: unlocked ? Colors.white : Colors.white.withValues(alpha: 0.5),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
              side: const BorderSide(color: PiyakColors.outline, width: 2),
            ),
            margin: const EdgeInsets.symmetric(vertical: 8),
            child: ListTile(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
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
                    color: PiyakColors.outline),
              ),
              subtitle: unlocked
                  ? Row(
                      children: [
                        const Icon(Icons.star_rounded,
                            color: PiyakColors.starYellow, size: 18),
                        Text(' $stars / 30',
                            style: const TextStyle(
                                color: PiyakColors.outline, fontSize: 14)),
                      ],
                    )
                  : const Text(S.lockedChapter,
                      style:
                          TextStyle(color: PiyakColors.outline, fontSize: 12)),
              onTap: unlocked
                  ? () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => StageScreen(chapter: c)))
                  : null,
            ),
          );
        },
      ),
    );
  }
}
