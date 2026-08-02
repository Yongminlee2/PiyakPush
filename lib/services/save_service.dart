/// 로컬 진행 저장. 키 규칙:
/// `stars.<levelId>`(int, 최고 기록만) · `opt.sound`/`opt.dpad`(bool)
/// `deco.items`(json — T18 꾸미기 보드) · `daily.<yyyy-MM-dd>`(bool — T19)
library;

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/progression.dart';

class SaveService extends ChangeNotifier {
  final SharedPreferences _p;
  SaveService._(this._p);

  static Future<SaveService> load() async =>
      SaveService._(await SharedPreferences.getInstance());

  // ── 별
  int starsOf(String levelId) => _p.getInt('stars.$levelId') ?? 0;

  Future<void> setStars(String levelId, int stars) async {
    if (stars <= starsOf(levelId)) return;
    await _p.setInt('stars.$levelId', stars);
    notifyListeners();
  }

  int chapterStars(int c) {
    var sum = 0;
    for (var i = 1; i <= 10; i++) {
      sum += starsOf('c${c}s${i.toString().padLeft(2, '0')}');
    }
    return sum;
  }

  /// 별 1개 이상 받은 스테이지 수 — 챕터 해금 판정의 기준.
  int chapterClearedCount(int c) {
    var n = 0;
    for (var i = 1; i <= 10; i++) {
      if (starsOf('c${c}s${i.toString().padLeft(2, '0')}') > 0) n++;
    }
    return n;
  }

  int get totalStars {
    var sum = 0;
    for (var c = 1; c <= kChapterCount; c++) {
      sum += chapterStars(c);
    }
    return sum;
  }

  /// 확인용 전체 해금 — 켜면 모든 챕터가 열린다 (설정에서 토글).
  bool get unlockAll => _p.getBool('opt.unlockAll') ?? false;

  Future<void> setUnlockAll(bool v) async {
    await _p.setBool('opt.unlockAll', v);
    notifyListeners();
  }

  bool chapterUnlocked(int c) =>
      unlockAll || c == 1 || chapterClearedCount(c - 1) >= kChapterUnlockClears;

  // ── 설정
  bool get soundOn => _p.getBool('opt.sound') ?? true;

  /// 조작 방식 — true면 십자 방향키, false면 조이스틱(기본).
  bool get dpadOn => _p.getBool('opt.dpad') ?? false;

  Future<void> setSoundOn(bool v) async {
    await _p.setBool('opt.sound', v);
    notifyListeners();
  }

  Future<void> setDpadOn(bool v) async {
    await _p.setBool('opt.dpad', v);
    notifyListeners();
  }

  // ── 범용 문자열 (꾸미기 보드 배치 등)
  String? getString(String key) => _p.getString(key);

  Future<void> setString(String key, String value) async {
    await _p.setString(key, value);
    notifyListeners();
  }

  // ── 데일리 도장
  bool dailyCleared(DateTime day) => _p.getBool(_dailyKey(day)) ?? false;

  Future<void> setDailyCleared(DateTime day) async {
    await _p.setBool(_dailyKey(day), true);
    notifyListeners();
  }

  /// 오늘부터 거꾸로 연속 클리어 일수.
  int dailyStreak(DateTime today) {
    var streak = 0;
    var d = DateTime(today.year, today.month, today.day);
    while (dailyCleared(d)) {
      streak++;
      d = d.subtract(const Duration(days: 1));
    }
    return streak;
  }

  static String _dailyKey(DateTime d) =>
      'daily.${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<void> resetAll() async {
    await _p.clear();
    notifyListeners();
  }
}
