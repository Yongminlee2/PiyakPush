import 'package:flutter_test/flutter_test.dart';
import 'package:piyak_push/engine/geometry.dart';
import 'package:piyak_push/models/level.dart';
import 'package:piyak_push/services/level_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('fromJson/toJson 왕복', () {
    final j = {
      'id': 'c1s01',
      'chapter': 1,
      'title': '첫 걸음',
      'rows': ['#####', '#@\$o#', '#####'],
      'optimal': 1,
    };
    final lv = Level.fromJson(j);
    expect(lv.id, 'c1s01');
    expect(lv.optimal, 1);
    expect(lv.toJson(), j);
  });

  test('toBoard 파싱', () {
    final lv = Level.fromJson({
      'id': 'x',
      'chapter': 1,
      'title': 't',
      'rows': ['#####', '#@\$o#', '#####'],
    });
    final b = lv.toBoard();
    expect(b.chick, const Point(1, 1));
    expect(lv.optimal, 0); // 미기록 시 0
  });

  test('알·둥지 불일치 레벨은 toBoard에서 ArgumentError', () {
    final lv = Level.fromJson({
      'id': 'x',
      'chapter': 1,
      'title': 't',
      'rows': ['####', '#@\$#', '####'],
    });
    expect(() => lv.toBoard(), throwsArgumentError);
  });

  test('LevelRepository가 챕터1을 로드하고 byId로 찾는다', () async {
    final levels = await LevelRepository.loadChapter(1);
    expect(levels, isNotEmpty);
    final first = await LevelRepository.byId(levels.first.id);
    expect(first.id, levels.first.id);
  });
}
