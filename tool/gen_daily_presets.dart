/// 데일리 프리셋 20개 생성(1회성 도구). 프로젝트 루트에서:
///
///     dart run tool/gen_daily_presets.dart
///
/// 데일리 생성기와 같은 코드로 만들되 고정 시드를 써서 결정적이다.
/// 생성 후 반드시 `dart run tool/validate_levels.dart`로 재검증한다.
library;

import 'dart:convert';
import 'dart:io';

import 'package:piyak_push/models/level.dart';
import 'package:piyak_push/services/daily_generator.dart';

void main() {
  final levels = <Level>[];
  var seed = 1000;
  while (levels.length < 20) {
    final lv = tryGenerateDaily(DateTime(2026), seedOverride: seed);
    seed += 7;
    if (lv == null) continue;
    final n = levels.length + 1;
    levels.add(Level(
      id: 'd${n.toString().padLeft(2, '0')}',
      chapter: 0,
      title: '오늘의 퍼즐',
      rows: lv.rows,
      optimal: lv.optimal,
    ));
    stdout.writeln('${levels.last.id}: 최적 ${lv.optimal}수');
  }
  const enc = JsonEncoder.withIndent('  ');
  File('assets/levels/daily_presets.json')
      .writeAsStringSync('${enc.convert(levels.map((e) => e.toJson()).toList())}\n');
  stdout.writeln('daily_presets.json 저장 완료');
}
