/// 스테이지 선택: 10개 그리드 + 별. 클리어 시 다음 스테이지로 이어 플레이.
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/level.dart';
import '../../services/hint_service.dart';
import '../../services/level_repository.dart';
import '../../services/save_service.dart';
import '../strings.dart';
import '../theme.dart';
import 'game_screen.dart';

class StageScreen extends StatelessWidget {
  final int chapter;
  const StageScreen({required this.chapter, super.key});

  Route _gameRoute(BuildContext context, List<Level> levels, int idx) {
    final save = context.read<SaveService>();
    final level = levels[idx];
    return MaterialPageRoute(
      builder: (_) => GameScreen(
        key: ValueKey(level.id),
        level: level,
        showDpad: save.dpadOn,
        hintProvider: (c) => hintFor(c.board),
        onCleared: (stars) => save.setStars(level.id, stars),
        onNext: idx + 1 < levels.length
            ? () => Navigator.pushReplacement(
                context, _gameRoute(context, levels, idx + 1))
            : () => Navigator.pop(context),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final save = context.watch<SaveService>();
    return Scaffold(
      appBar: AppBar(
        title: Text('${S.chapterTitle} $chapter. ${S.chapterNames[chapter - 1]}',
            style: const TextStyle(
                fontWeight: FontWeight.bold, color: PiyakColors.outline)),
        backgroundColor: PiyakColors.creamBg,
      ),
      body: FutureBuilder<List<Level>>(
        future: LevelRepository.loadChapter(chapter),
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final levels = snap.data!;
          return GridView.builder(
            padding: const EdgeInsets.all(20),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 14,
              crossAxisSpacing: 14,
              childAspectRatio: 1.5,
            ),
            itemCount: levels.length,
            itemBuilder: (context, i) {
              final stars = save.starsOf(levels[i].id);
              return Material(
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                  side: const BorderSide(color: PiyakColors.outline, width: 2),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(18),
                  onTap: () => Navigator.push(
                      context, _gameRoute(context, levels, i)),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('${i + 1}',
                          style: const TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w900,
                              color: PiyakColors.outline)),
                      Text(levels[i].title,
                          style: const TextStyle(
                              fontSize: 12, color: PiyakColors.outline)),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          3,
                          (s) => Icon(
                            Icons.star_rounded,
                            size: 20,
                            color: s < stars
                                ? PiyakColors.starYellow
                                : PiyakColors.outline.withValues(alpha: 0.2),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
