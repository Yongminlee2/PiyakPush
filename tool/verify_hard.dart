/// 도전 5판(11~15번)이 정말 풀리는지 전수 검증.
///
///     dart run tool/verify_hard.dart          # 1~5막
///     dart run tool/verify_hard.dart 1 2 3    # 지정한 챕터만
///
/// 생성기가 이미 솔버로 걸렀지만, 파일에 들어간 최종본을 다시 푸는 것과는
/// 다른 이야기다. 기록된 optimal이 실제 최적수와 맞는지까지 본다.
library;

import 'dart:convert';
import 'dart:io';

import 'package:piyak_push/engine/solver.dart';
import 'package:piyak_push/models/level.dart';

void main(List<String> args) {
  final chapters = args.isEmpty
      ? [for (var c = 1; c <= 5; c++) c]
      : args.map(int.parse).toList();

  var bad = 0;
  for (final c in chapters) {
    final levels = (jsonDecode(
                File('assets/levels/chapter$c.json').readAsStringSync())
            as List)
        .map((e) => Level.fromJson(e as Map<String, dynamic>))
        .toList();

    for (var i = 10; i < levels.length; i++) {
      final lv = levels[i];
      final sw = Stopwatch()..start();
      final report = Solver(maxStates: 1500000).analyze(lv.toBoard());
      final moves = report.moves;
      if (moves == null) {
        stdout.writeln('  ${lv.id}  풀이 불가!');
        bad++;
        continue;
      }
      final match = moves.length == lv.optimal ? '' : ' (기록 ${lv.optimal})';
      if (moves.length != lv.optimal) bad++;
      stdout.writeln('  ${lv.id}  ${moves.length}수$match  '
          '상태${report.statesExplored}  ${sw.elapsedMilliseconds}ms');
    }
  }
  stdout.writeln(bad == 0 ? '전부 정상' : '문제 $bad건');
  if (bad > 0) exit(1);
}
