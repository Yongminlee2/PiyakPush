/// 번들 에셋에서 레벨 JSON을 읽는다. 챕터 단위 캐시.
library;

import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import '../models/level.dart';

class LevelRepository {
  static final Map<int, List<Level>> _cache = {};

  static Future<List<Level>> loadChapter(int c) async {
    if (_cache.containsKey(c)) return _cache[c]!;
    final raw = await rootBundle.loadString('assets/levels/chapter$c.json');
    final list = (jsonDecode(raw) as List)
        .map((e) => Level.fromJson(e as Map<String, dynamic>))
        .toList();
    _cache[c] = list;
    return list;
  }

  /// id 형식: c<챕터>s<번호> (예: c1s01)
  static Future<Level> byId(String id) async {
    final c = int.parse(id.substring(1, id.indexOf('s')));
    final levels = await loadChapter(c);
    return levels.firstWhere((l) => l.id == id);
  }
}
