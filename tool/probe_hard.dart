/// 도전 등급 밴드를 정하기 위한 측정 도구.
///
/// 조건을 거의 걸지 않고 후보를 많이 뽑아, 각 지표가 실제로 어느 범위에
/// 분포하는지 본다. 밴드는 추측이 아니라 이 분포를 보고 정한다.
///
///     dart run tool/probe_hard.dart 8 8 4 11 100
///     (가로 세로 알수 벽수 표본수)
library;

import 'dart:io';
import 'dart:math';

import 'package:piyak_push/services/level_generator.dart';

void main(List<String> args) {
  final w = int.parse(args.isNotEmpty ? args[0] : '8');
  final h = int.parse(args.length > 1 ? args[1] : '8');
  final eggs = int.parse(args.length > 2 ? args[2] : '4');
  final walls = int.parse(args.length > 3 ? args[3] : '11');
  final n = int.parse(args.length > 4 ? args[4] : '100');
  final steps = int.parse(args.length > 5 ? args[5] : '100');

  final spec = GenSpec(
    width: w,
    height: h,
    eggCount: eggs,
    wallCount: walls,
    gimmicks: const [],
    minOptimal: 1,
    maxOptimal: 999,
    minPushes: 0,
    minStates: 0,
    minDeadlockRatio: 0.0,
    scrambleSteps: steps,
    maxStates: 600000,
  );

  final moves = <int>[];
  final pushes = <int>[];
  final states = <int>[];
  final traps = <double>[];
  var seed = 1;
  final sw = Stopwatch()..start();
  while (moves.length < n && sw.elapsed.inSeconds < 240) {
    final g = generate(Random(seed++), spec, maxAttempts: 60);
    if (g == null) continue;
    moves.add(g.report.optimalMoves);
    pushes.add(g.report.pushes);
    states.add(g.report.statesExplored);
    traps.add(g.report.deadlockRatio);
  }

  void show(String name, List<num> xs) {
    if (xs.isEmpty) return;
    final s = [...xs]..sort();
    String at(double p) => s[(s.length * p).clamp(0, s.length - 1).toInt()]
        .toStringAsFixed(name == '함정비율' ? 3 : 0);
    stdout.writeln('$name  최소 ${at(0)}  중앙 ${at(0.5)}  상위30% ${at(0.7)}  '
        '상위10% ${at(0.9)}  최대 ${at(0.999)}');
  }

  stdout.writeln(
      '표본 ${moves.length}개 (${sw.elapsed.inSeconds}초, ${w}x$h 알$eggs 벽$walls)');
  show('최적턴  ', moves);
  show('밀기수  ', pushes);
  show('탐색상태', states);
  show('함정비율', traps);
}
