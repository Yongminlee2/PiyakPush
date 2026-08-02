import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:piyak_push/engine/solver.dart';
import 'package:piyak_push/models/level.dart';

/// 챕터가 늘어나도 자동 포함: assets/levels/ 아래 모든 JSON을 검사한다.
/// optimal 불일치가 나면 `dart run tool/validate_levels.dart`를 돌리지 않은 것.
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
    for (final lv in levels) {
      test('${lv.id} 풀이 가능 + optimal 일치', () {
        final sol = Solver().solve(lv.toBoard());
        expect(sol, isNotNull, reason: '${lv.id} 풀이 불가');
        expect(lv.optimal, sol!.length,
            reason: '${lv.id} optimal 미갱신 — 검증 CLI 실행 필요');
      });
    }
  }
}
