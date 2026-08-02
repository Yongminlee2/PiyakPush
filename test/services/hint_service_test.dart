import 'package:flutter_test/flutter_test.dart';
import 'package:piyak_push/engine/board.dart';
import 'package:piyak_push/engine/geometry.dart';
import 'package:piyak_push/services/hint_service.dart';

void main() {
  test('1수 레벨 힌트', () async {
    final b = Board.fromAscii(['#####', '#@\$o#', '#####']);
    expect(await hintFor(b), [Dir.right]);
  });

  test('데드락이면 null', () async {
    final b = Board.fromAscii(['####', '#@\$#', '#o.#', '####']);
    expect(await hintFor(b), null);
  });

  test('최대 5수까지만', () async {
    final b = Board.fromAscii(['###########', '#@\$......o#', '###########']);
    final h = await hintFor(b);
    expect(h!.length, 5);
    expect(h.every((d) => d == Dir.right), true);
  });

  test('얼음·굴 상태도 그대로 풀이 (직렬화 손실 없음)', () async {
    final b = Board.fromAscii(['#######', '#@\$iio#', '#######']);
    expect(await hintFor(b), [Dir.right]);
  });
}
