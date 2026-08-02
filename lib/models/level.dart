/// 레벨 정의. JSON(assets/levels/*.json) 한 항목과 1:1.
///
/// `optimal`은 손으로 쓰지 않는다 — `dart run tool/validate_levels.dart`가
/// 솔버 실측값으로 재기록한다.
library;

import '../engine/board.dart';

class Level {
  final String id;
  final int chapter;
  final String title;
  final List<String> rows;
  final int optimal;

  const Level({
    required this.id,
    required this.chapter,
    required this.title,
    required this.rows,
    this.optimal = 0,
  });

  Board toBoard() => Board.fromAscii(rows);

  factory Level.fromJson(Map<String, dynamic> j) => Level(
        id: j['id'] as String,
        chapter: j['chapter'] as int,
        title: j['title'] as String,
        rows: (j['rows'] as List).cast<String>(),
        optimal: (j['optimal'] as int?) ?? 0,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'chapter': chapter,
        'title': title,
        'rows': rows,
        'optimal': optimal,
      };
}
