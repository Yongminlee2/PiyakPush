import 'package:flutter_test/flutter_test.dart';
import 'package:piyak_push/engine/solver.dart';
import 'package:piyak_push/services/daily_generator.dart';

void main() {
  test('같은 날짜는 같은 퍼즐 (결정성)', () {
    final a = tryGenerateDaily(DateTime(2026, 8, 2));
    final b = tryGenerateDaily(DateTime(2026, 8, 2));
    expect(a, isNotNull);
    expect(a!.rows, b!.rows);
    expect(a.optimal, b.optimal);
  });

  test('생성 퍼즐은 풀이 가능 + 최적수 8~25', () {
    for (final date in [
      DateTime(2026, 8, 2),
      DateTime(2026, 8, 3),
      DateTime(2026, 12, 25),
    ]) {
      final lv = tryGenerateDaily(date);
      expect(lv, isNotNull, reason: '$date 생성 실패');
      final sol = Solver().solve(lv!.toBoard());
      expect(sol, isNotNull);
      expect(sol!.length, lv.optimal);
      expect(lv.optimal, inInclusiveRange(8, 25));
    }
  });

  test('다른 날짜는 (거의 항상) 다른 퍼즐', () {
    final a = tryGenerateDaily(DateTime(2026, 8, 2));
    final b = tryGenerateDaily(DateTime(2026, 8, 3));
    expect(a!.rows, isNot(b!.rows));
  });
}
