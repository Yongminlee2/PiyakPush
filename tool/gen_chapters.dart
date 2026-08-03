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

/// 도전 5판(11~15번)의 규격.
///
/// 최적 턴 수를 늘리는 것만으로는 "어렵다"가 안 된다 — 막 움직여도 언젠간
/// 깨지기 때문이다. 잘못 민 수가 되돌릴 수 없게 되는 비율(함정)을 대폭 올려,
/// 밀기 전에 생각하지 않으면 못 깨는 판만 고른다.
/// 밴드는 "너무 시시한 것만 거르는" 최소 문턱이고, 실제 선별은
/// _hardness 점수 순위가 한다. 네 지표를 동시에 만족시키라고 하면
/// 그런 판이 사실상 없어 생성이 실패한다(실측으로 확인).
GenSpec hardSpecFor(int chapter) {
  final g = _gimmicks[chapter] ?? const <Gimmick>[];
  if (chapter <= 10) {
    return GenSpec(
      width: 8,
      height: 8,
      eggCount: 4,
      wallCount: 11,
      gimmicks: g,
      minOptimal: 18,
      maxOptimal: 60,
      minPushes: 8,
      minStates: 800,
      minDeadlockRatio: 0.0,
      scrambleSteps: 110,
      maxStates: 600000,
    );
  }
  if (chapter <= 15) {
    return GenSpec(
      width: 9,
      height: 9,
      eggCount: 5,
      wallCount: 12,
      gimmicks: g,
      minOptimal: 22,
      maxOptimal: 70,
      minPushes: 10,
      minStates: 1500,
      minDeadlockRatio: 0.0,
      scrambleSteps: 130,
      maxStates: 700000,
    );
  }
  // 4막은 알 5개·9×9라 한 판 푸는 비용이 급격히 커진다. 탐색 상한을 80만으로
  // 두면 한 챕터에 78분이 걸려(실측) 못 쓴다. 30만으로 낮추고 문턱도 내려
  // 헛수고를 줄인다 — 어차피 최종 선별은 난이도 점수 순위가 한다.
  return GenSpec(
    width: 9,
    height: 9,
    eggCount: 5,
    wallCount: 10,
    gimmicks: g,
    minOptimal: 20,
    maxOptimal: 80,
    minPushes: 10,
    minStates: 1500,
    minDeadlockRatio: 0.0,
    scrambleSteps: 150,
    maxStates: chapter == 20 ? 120000 : 220000,
  );
}

/// "생각해야 하는" 정도를 하나의 점수로 —
/// 잘못 밀면 못 돌아오는 비율(함정)과 갈래 수를 크게 보고,
/// 밀기 횟수·턴 수는 거들게 한다. 턴 수만 길면 막 움직여도 깨지기 때문이다.
double _hardness(GenResult g) {
  final r = g.report;
  return r.deadlockRatio * 260 +
      (log(max(r.statesExplored, 10)) / ln10) * 9 +
      r.pushes * 1.6 +
      r.optimalMoves * 0.25;
}

/// 후보를 [pool]개 뽑아 어려운 순으로 [count]개를 고른다.
///
/// 고정 문턱값을 쓰면 네 지표를 동시에 만족하는 판이 거의 없어 실패한다.
/// 대신 많이 뽑아 순위로 고르면 항상 그 규격에서 가장 어려운 판이 남는다.
List<GenResult> _collectHardest(
    int chapter, GenSpec spec, int count, int pool, int seed0,
    {required String label}) {
  final cands = <GenResult>[];
  var seed = seed0;
  var tries = 0;
  while (cands.length < pool && tries < pool * 30) {
    tries++;
    final g = generate(Random(seed++), spec, maxAttempts: 25);
    if (g == null) continue;
    if (cands.any((r) => r.rows.join('|') == g.rows.join('|'))) continue;
    cands.add(g);
  }
  if (cands.length < count) {
    stderr.writeln('챕터 $chapter $label: 후보 부족 (${cands.length}/$count)');
    exit(1);
  }
  cands.sort((a, b) => _hardness(b).compareTo(_hardness(a)));
  final picked = cands.take(count).toList()
    ..sort((a, b) => a.report.optimalMoves - b.report.optimalMoves);
  for (var i = 0; i < picked.length; i++) {
    final r = picked[i].report;
    stdout.writeln('  $label ${i + 1}/$count  ${r.optimalMoves}수 '
        '밀기${r.pushes} 상태${r.statesExplored} '
        '함정${(r.deadlockRatio * 100).round()}% '
        '(후보 ${cands.length}개 중)');
  }
  return picked;
}

/// 조건을 만족하는 서로 다른 판 [count]개를 모은다.
List<GenResult> _collect(int chapter, GenSpec spec, int count, int seed0,
    {required String label}) {
  final results = <GenResult>[];
  var seed = seed0;
  var giveUp = 0;
  while (results.length < count) {
    final g = generate(Random(seed++), spec);
    if (g == null) {
      if (++giveUp > 400) {
        stderr.writeln('챕터 $chapter $label: 후보 확보 실패 '
            '(${results.length}/$count) — 밴드를 완화해야 한다');
        exit(1);
      }
      continue;
    }
    if (results.any((r) => r.rows.join('|') == g.rows.join('|'))) continue;
    results.add(g);
    stdout.writeln('  $label ${results.length}/$count  '
        '${g.report.optimalMoves}수 밀기${g.report.pushes} '
        '상태${g.report.statesExplored} '
        '함정${(g.report.deadlockRatio * 100).round()}%');
  }
  results.sort((a, b) => a.report.optimalMoves - b.report.optimalMoves);
  return results;
}

void main(List<String> args) {
  final chapters = args.isEmpty
      ? [for (var c = 1; c <= 20; c++) c]
      : args.map(int.parse).toList();

  for (final chapter in chapters) {
    final sw = Stopwatch()..start();
    final path = 'assets/levels/chapter$chapter.json';
    final levels = <Map<String, dynamic>>[];

    // 1~5막은 손으로 만든 학습용 판이라 그대로 두고 도전 5판만 덧붙인다.
    if (chapter <= 5) {
      final existing = (jsonDecode(File(path).readAsStringSync()) as List)
          .cast<Map<String, dynamic>>()
          .where((m) => (m['id'] as String).compareTo('c${chapter}s11') < 0)
          .toList();
      levels.addAll(existing);
    } else {
      final base = _collect(chapter, specFor(chapter), 10, chapter * 1000,
          label: '기본');
      for (var i = 0; i < base.length; i++) {
        levels.add(Level(
          id: 'c${chapter}s${(i + 1).toString().padLeft(2, '0')}',
          chapter: chapter,
          title: '${_names[chapter]} ${i + 1}',
          rows: base[i].rows,
          optimal: base[i].report.optimalMoves,
        ).toJson());
      }
    }

    // 4막은 한 판 푸는 비용이 커서 풀을 줄인다(220 → 70).
    // 4막은 알 5개라 한 판 푸는 비용이 커서 풀을 크게 줄인다.
    // 20막은 기믹 4종이 모두 들어가 특히 느려 더 줄인다(실측 90분 초과).
    final pool = chapter <= 15
        ? 220
        : chapter == 20
            ? 26
            : 45;
    final hard = _collectHardest(
        chapter, hardSpecFor(chapter), 5, pool, chapter * 7777,
        label: '도전');
    for (var i = 0; i < hard.length; i++) {
      levels.add(Level(
        id: 'c${chapter}s${(11 + i).toString().padLeft(2, '0')}',
        chapter: chapter,
        title: '도전 ${i + 1}',
        rows: hard[i].rows,
        optimal: hard[i].report.optimalMoves,
      ).toJson());
    }

    const enc = JsonEncoder.withIndent('  ');
    File(path).writeAsStringSync('${enc.convert(levels)}\n');
    stdout.writeln('챕터 $chapter 완료 — ${levels.length}판, '
        '${sw.elapsed.inSeconds}초');
  }
}
