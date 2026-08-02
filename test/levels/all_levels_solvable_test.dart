import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:piyak_push/engine/solver.dart';
import 'package:piyak_push/models/level.dart';

/// 파싱은 전 레벨, 솔버 검증은 챕터별 첫·마지막만 — 200개를 모두 BFS로
/// 푸는 건 테스트로는 너무 느리다. 4막 레벨 하나가 50만 상태를 뒤진다.
/// 전수 검증은 생성 시점(tool/gen_chapters.dart)이 이미 솔버로 하고 있고,
/// 손으로 고친 뒤에는 tool/validate_levels.dart를 돌리면 된다.
void main() {
  final files = Directory('assets/levels')
      .listSync()
      .whereType<File>()
      .where((f) => f.path.endsWith('.json'))
      .toList()
    ..sort((a, b) => a.path.compareTo(b.path));

  for (final f in files) {
    final levels = (jsonDecode(f.readAsStringSync()) as List)
        .map((e) => Level.fromJson(e as Map<String, dynamic>))
        .toList();
    final name = f.uri.pathSegments.last;

    test('$name: 전 레벨 파싱 + optimal 기록됨', () {
      expect(levels, isNotEmpty);
      for (final lv in levels) {
        expect(() => lv.toBoard(), returnsNormally, reason: lv.id);
        expect(lv.optimal, greaterThan(0), reason: '${lv.id} optimal 미기록');
      }
    });

    // 4막(챕터 16~20)은 한 판 푸는 데 수십 초가 걸려 표본 검증에서도 뺀다.
    final heavy = RegExp(r'chapter(1[6-9]|20)\.json$').hasMatch(name);
    if (heavy) continue;

    for (final lv in {levels.first, levels.last}) {
      test('${lv.id} 풀이 가능 + optimal 일치', () {
        final sol = Solver().solve(lv.toBoard());
        expect(sol, isNotNull, reason: '${lv.id} 풀이 불가');
        expect(lv.optimal, sol!.length, reason: '${lv.id} optimal 불일치');
      });
    }
  }
}
