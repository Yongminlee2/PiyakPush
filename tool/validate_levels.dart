/// 레벨 전수 검증 CLI. 프로젝트 루트에서:
///
///     dart run tool/validate_levels.dart
///
/// assets/levels/ 아래 모든 .json을 솔버로 풀어
/// ① 풀이 불가 레벨을 나열하고 exit 1
/// ② optimal 필드를 실측 최적수로 재기록
/// ③ 챕터별 최적수 분포를 출력한다.
library;

import 'dart:convert';
import 'dart:io';

import 'package:piyak_push/engine/solver.dart';
import 'package:piyak_push/models/level.dart';

void main() {
  final dir = Directory('assets/levels');
  if (!dir.existsSync()) {
    stderr.writeln('assets/levels 폴더가 없음 — 프로젝트 루트에서 실행할 것');
    exit(2);
  }
  final files = dir
      .listSync()
      .whereType<File>()
      .where((f) => f.path.endsWith('.json'))
      .toList()
    ..sort((a, b) => a.path.compareTo(b.path));

  var failed = false;
  final byChapter = <int, List<int>>{};

  for (final f in files) {
    final list = (jsonDecode(f.readAsStringSync()) as List)
        .map((e) => Level.fromJson(e as Map<String, dynamic>))
        .toList();
    final updated = <Map<String, dynamic>>[];
    for (final lv in list) {
      List<int>? sol;
      try {
        final moves = Solver().solve(lv.toBoard());
        sol = moves?.map((d) => d.index).toList();
      } on ArgumentError catch (e) {
        stderr.writeln('파싱 실패: ${lv.id} — $e');
        failed = true;
        updated.add(lv.toJson());
        continue;
      }
      if (sol == null) {
        stderr.writeln('풀이 불가: ${lv.id} (${f.path})');
        failed = true;
        updated.add(lv.toJson());
        continue;
      }
      updated.add(Level(
        id: lv.id,
        chapter: lv.chapter,
        title: lv.title,
        rows: lv.rows,
        optimal: sol.length,
      ).toJson());
      byChapter.putIfAbsent(lv.chapter, () => []).add(sol.length);
      stdout.writeln('${lv.id}: 최적 ${sol.length}수');
    }
    const enc = JsonEncoder.withIndent('  ');
    f.writeAsStringSync('${enc.convert(updated)}\n');
  }

  stdout.writeln('--- 챕터별 최적수 분포');
  final all = <int>[];
  for (final c in byChapter.keys.toList()..sort()) {
    final xs = byChapter[c]!..sort();
    all.addAll(xs);
    stdout.writeln('챕터 $c: ${xs.join(', ')}');
  }
  if (all.isNotEmpty) {
    final under20 = all.where((x) => x < 20).length;
    stdout.writeln(
        '전체 ${all.length}개 중 20수 미만 $under20개 (${(under20 * 100 / all.length).round()}%)');
  }
  if (failed) exit(1);
}
