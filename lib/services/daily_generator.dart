/// 데일리 퍼즐 생성기 — 순수 Dart (CLI 도구에서도 실행 가능, Flutter 의존 금지).
///
/// 보드 생성과 역방향 흐트러뜨리기는 `level_generator.dart`의 공용 함수를 쓴다.
/// 여기서는 데일리에 맞는 규격(7×7, 알 2~3, 최적 8~25수)만 정한다.
library;

import 'dart:math';

import '../engine/solver.dart';
import '../models/level.dart';
import 'level_generator.dart';

int daySeed(DateTime d) => d.year * 10000 + d.month * 100 + d.day;

/// 날짜 시드로 결정적 생성. 실패하면 null (→ 프리셋 폴백).
Level? tryGenerateDaily(DateTime date, {int? seedOverride}) {
  final rng = Random(seedOverride ?? daySeed(date));
  for (var attempt = 0; attempt < 120; attempt++) {
    final solved =
        randomSolvedBoard(rng, 7, 7, 6 + rng.nextInt(5), 2 + rng.nextInt(2));
    if (solved == null) continue;
    final scrambled =
        reverseScramble(solved, rng, steps: 25 + rng.nextInt(21));
    if (scrambled.isCleared) continue;
    final sol = Solver(maxStates: 300000).solve(scrambled);
    if (sol == null || sol.length < 8 || sol.length > 25) continue;
    return Level(
      id: 'daily',
      chapter: 0,
      title: '오늘의 퍼즐',
      rows: scrambled.toAsciiRows(),
      optimal: sol.length,
    );
  }
  return null;
}
