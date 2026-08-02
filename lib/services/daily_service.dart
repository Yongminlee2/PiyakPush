/// 데일리 퍼즐 진입점: 생성 시도 → 실패 시 프리셋에서 날짜 해시로 선택.
///
/// 생성 로직 자체는 순수 Dart인 daily_generator.dart에 있다 (CLI 도구 공용).
library;

import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import '../models/level.dart';
import 'daily_generator.dart';

export 'daily_generator.dart' show daySeed, tryGenerateDaily;

class DailyService {
  static List<Level>? _presetCache;

  static Future<Level> levelFor(DateTime date) async {
    final gen = tryGenerateDaily(date);
    if (gen != null) return gen;
    final presets = await _presets();
    return presets[daySeed(date) % presets.length];
  }

  static Future<List<Level>> _presets() async {
    if (_presetCache != null) return _presetCache!;
    final raw =
        await rootBundle.loadString('assets/levels/daily_presets.json');
    _presetCache = (jsonDecode(raw) as List)
        .map((e) => Level.fromJson(e as Map<String, dynamic>))
        .toList();
    return _presetCache!;
  }
}
