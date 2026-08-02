import 'package:flutter/material.dart';

import 'models/level.dart';
import 'services/level_repository.dart';
import 'ui/screens/game_screen.dart';
import 'ui/strings.dart';
import 'ui/theme.dart';

void main() => runApp(const PiyakPushApp());

class PiyakPushApp extends StatelessWidget {
  const PiyakPushApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: S.appTitle,
        theme: piyakTheme(),
        debugShowCheckedModeBanner: false,
        home: const _DevChapterRunner(),
      );
}

/// 임시 홈: 챕터1을 순서대로 플레이. T15에서 타이틀·챕터 내비게이션으로 교체.
class _DevChapterRunner extends StatefulWidget {
  const _DevChapterRunner();

  @override
  State<_DevChapterRunner> createState() => _DevChapterRunnerState();
}

class _DevChapterRunnerState extends State<_DevChapterRunner> {
  int _idx = 0;
  late final Future<List<Level>> _levels = LevelRepository.loadChapter(1);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Level>>(
      future: _levels,
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Scaffold(
              body: Center(child: CircularProgressIndicator()));
        }
        final levels = snap.data!;
        return GameScreen(
          key: ValueKey(_idx),
          level: levels[_idx],
          onNext: () => setState(() => _idx = (_idx + 1) % levels.length),
        );
      },
    );
  }
}
