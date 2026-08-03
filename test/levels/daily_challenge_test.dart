/// 일요일 도전 퍼즐 풀이 검증.
///
/// 챕터에서 빼낸 판을 옮겨 담은 것이라 파일이 그대로 실려 나가는지,
/// 기록된 optimal이 실제 최적수와 맞는지 확인한다.
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:piyak_push/engine/solver.dart';
import 'package:piyak_push/models/level.dart';
import 'package:piyak_push/services/daily_service.dart';

void main() {
  final levels =
      (jsonDecode(File('assets/levels/daily_challenge.json').readAsStringSync())
              as List)
          .map((e) => Level.fromJson(e as Map<String, dynamic>))
          .toList();

  test('도전 퍼즐 20판이 모두 파싱된다', () {
    expect(levels.length, 20);
    for (final lv in levels) {
      expect(() => lv.toBoard(), returnsNormally, reason: lv.id);
      expect(lv.optimal, greaterThan(0), reason: lv.id);
    }
  });

  test('짧은 것과 긴 것이 실제로 풀린다', () {
    for (final lv in {levels.first, levels.last}) {
      final sol = Solver(maxStates: 1500000).solve(lv.toBoard());
      expect(sol, isNotNull, reason: '${lv.id} 풀이 불가');
      expect(sol!.length, lv.optimal, reason: '${lv.id} optimal 불일치');
    }
  });

  test('도전의 날은 일요일뿐', () {
    // 2026-08-02는 일요일
    expect(DailyService.isChallengeDay(DateTime(2026, 8, 2)), true);
    for (var d = 3; d <= 8; d++) {
      expect(DailyService.isChallengeDay(DateTime(2026, 8, d)), false,
          reason: '8월 $d일');
    }
  });
}
