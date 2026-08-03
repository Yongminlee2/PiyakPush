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
  static List<Level>? _challengeCache;

  /// 일요일은 도전의 날.
  ///
  /// 매일 나오는 퍼즐은 한 번에 끝낼 수 있어야 해서 8~14수로 짧다. 도전 판은
  /// 22~46수라 아무 날에나 섞으면 하루에 못 끝내는 날이 생긴다. 요일로 고정해
  /// 두면 언제 어려운 게 나오는지 미리 알 수 있어 마음의 준비가 된다.
  static bool isChallengeDay(DateTime date) => date.weekday == DateTime.sunday;

  static Future<Level> levelFor(DateTime date) async {
    if (isChallengeDay(date)) {
      final pool = await _challenges();
      return pool[daySeed(date) % pool.length];
    }
    final gen = tryGenerateDaily(date);
    if (gen != null) return gen;
    final presets = await _presets();
    return presets[daySeed(date) % presets.length];
  }

  static Future<List<Level>> _presets() async =>
      _presetCache ??= await _load('assets/levels/daily_presets.json');

  static Future<List<Level>> _challenges() async =>
      _challengeCache ??= await _load('assets/levels/daily_challenge.json');

  static Future<List<Level>> _load(String path) async {
    final raw = await rootBundle.loadString(path);
    return (jsonDecode(raw) as List)
        .map((e) => Level.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
