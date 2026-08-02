/// 챕터 6~20(150스테이지) 생성. 프로젝트 루트에서:
///
///     dart run tool/gen_chapters.dart          # 전부
///     dart run tool/gen_chapters.dart 6        # 한 챕터만 (밴드 조율용)
///
/// 시드가 챕터 번호로 고정돼 있어 같은 명령은 같은 레벨을 만든다.
library;

import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:piyak_push/models/level.dart';
import 'package:piyak_push/services/level_generator.dart';

const _names = {
  6: '얼음 굴',
  7: '미끄럼 자물쇠',
  8: '부서지는 얼음',
  9: '굴과 자물쇠',
  10: '무너지는 통로',
  11: '넓은 들판',
  12: '알 넷의 방',
  13: '얼어붙은 광장',
  14: '굴 미로',
  15: '잠긴 정원',
  16: '뒤엉킨 길',
  17: '삐약의 시험',
  18: '다섯 알의 탑',
  19: '마지막 관문',
  20: '삐약 마스터',
};

const _gimmicks = {
  6: [Gimmick.ice, Gimmick.portal],
  7: [Gimmick.ice, Gimmick.door],
  8: [Gimmick.ice, Gimmick.cracked],
  9: [Gimmick.portal, Gimmick.door],
  10: [Gimmick.portal, Gimmick.cracked],
  11: <Gimmick>[],
  12: [Gimmick.cracked],
  13: [Gimmick.ice],
  14: [Gimmick.portal],
  15: [Gimmick.door],
  16: [Gimmick.ice, Gimmick.portal, Gimmick.door],
  17: [Gimmick.ice, Gimmick.door, Gimmick.cracked],
  18: [Gimmick.portal, Gimmick.door, Gimmick.cracked],
  19: [Gimmick.ice, Gimmick.portal, Gimmick.cracked],
  20: [Gimmick.ice, Gimmick.portal, Gimmick.door, Gimmick.cracked],
};

GenSpec specFor(int chapter) {
  final g = _gimmicks[chapter]!;
  if (chapter <= 10) {
    // 2막: 기믹 2종 조합
    return GenSpec(
      width: 8,
      height: 8,
      eggCount: 3,
      wallCount: 8,
      gimmicks: g,
      minOptimal: 15,
      maxOptimal: 25,
      minPushes: 8,
      minStates: 1500,
      minDeadlockRatio: 0.03,
    );
  }
  if (chapter <= 15) {
    // 3막: 넓은 보드, 알 4개
    return GenSpec(
      width: 9,
      height: 9,
      eggCount: 4,
      wallCount: 10,
      gimmicks: g,
      minOptimal: 22,
      maxOptimal: 32,
      minPushes: 12,
      minStates: 4000,
      minDeadlockRatio: 0.05,
    );
  }
  // 4막: 전 기믹, 알 5개.
  //
  // 8×8·벽10으로는 후보가 하나도 안 나왔다 — 알 5개면 남는 칸이 20개 남짓이라
  // 탐색이 40만 상한을 넘겨 전부 폐기됐다. 판을 넓히고 벽을 줄여 숨통을 틔우고,
  // 상한도 60만으로 올린다(힌트 응답이 몇 초 안에 끝나는 선).
  return GenSpec(
    width: 9,
    height: 9,
    eggCount: 5,
    wallCount: 8,
    gimmicks: g,
    minOptimal: 26,
    maxOptimal: 42,
    minPushes: 14,
    minStates: 5000,
    minDeadlockRatio: 0.05,
    maxStates: 600000,
  );
}

void main(List<String> args) {
  final chapters = args.isEmpty
      ? [for (var c = 6; c <= 20; c++) c]
      : args.map(int.parse).toList();

  for (final chapter in chapters) {
    final spec = specFor(chapter);
    final sw = Stopwatch()..start();
    final results = <GenResult>[];
    var seed = chapter * 1000;
    var giveUp = 0;
    while (results.length < 10) {
      final g = generate(Random(seed++), spec);
      if (g == null) {
        if (++giveUp > 200) {
          stderr.writeln('챕터 $chapter: 후보 확보 실패 (${results.length}/10) — '
              '밴드를 완화해야 한다');
          exit(1);
        }
        continue;
      }
      // 같은 배치가 두 번 나오면 버린다
      if (results.any((r) => r.rows.join('|') == g.rows.join('|'))) continue;
      results.add(g);
      stdout.writeln('  ${results.length}/10  '
          '${g.report.optimalMoves}수 밀기${g.report.pushes} '
          '상태${g.report.statesExplored} '
          '함정${(g.report.deadlockRatio * 100).round()}%');
    }
    results.sort((a, b) => a.report.optimalMoves - b.report.optimalMoves);

    final levels = <Map<String, dynamic>>[];
    for (var i = 0; i < results.length; i++) {
      levels.add(Level(
        id: 'c${chapter}s${(i + 1).toString().padLeft(2, '0')}',
        chapter: chapter,
        title: '${_names[chapter]} ${i + 1}',
        rows: results[i].rows,
        optimal: results[i].report.optimalMoves,
      ).toJson());
    }
    const enc = JsonEncoder.withIndent('  ');
    File('assets/levels/chapter$chapter.json')
        .writeAsStringSync('${enc.convert(levels)}\n');
    stdout.writeln('챕터 $chapter (${_names[chapter]}) 완료 — '
        '${sw.elapsed.inSeconds}초');
  }
}
