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
    for (var i = 1; i <= kStagesPerChapter; i++) {
      sum += starsOf('c${c}s${i.toString().padLeft(2, '0')}');
    }
    return sum;
  }

  /// 별 1개 이상 받은 스테이지 수 — 챕터 해금 판정의 기준.
  int chapterClearedCount(int c) {
    var n = 0;
    for (var i = 1; i <= kStagesPerChapter; i++) {
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

  /// 개발자 모드. 타이틀 제목을 일곱 번 두드리면 켜진다.
  ///
  /// 배포판에서도 전 챕터를 열어 아무 스테이지나 테스트할 수 있어야 하는데,
  /// 그 스위치를 설정에 그냥 두면 누구나 300스테이지를 건너뛴다.
  /// 우연히는 못 누르고 알면 누를 수 있는 자리에 숨긴다.
  bool get devMode => _p.getBool('opt.dev') ?? false;

  Future<void> setDevMode(bool v) async {
    await _p.setBool('opt.dev', v);
    if (!v) await _p.remove('opt.unlockAll'); // 끄면 해금도 되돌린다
    notifyListeners();
  }

  /// 확인용 전체 해금 — 켜면 모든 챕터가 열린다 (설정에서 토글).
  bool get unlockAll => _p.getBool('opt.unlockAll') ?? false;

  Future<void> setUnlockAll(bool v) async {
    await _p.setBool('opt.unlockAll', v);
    notifyListeners();
  }

  bool chapterUnlocked(int c) =>
      unlockAll || c == 1 || chapterClearedCount(c - 1) >= kChapterUnlockClears;

  // ── 힌트
  //
  // 무제한이면 아무 판이나 힌트로 밀어버릴 수 있어 퍼즐이 성립하지 않는다.
  // 새 스테이지를 깰 때마다 1개씩 들어오므로, 대체로 한 판에 한 번 쓸 수 있다.
  // (나중에 광고 보상으로 [addHints]를 부르면 그대로 이어진다)
  static const kHintStart = 5;
  static const kHintPerStage = 1;
  static const kHintPerDaily = 2;

  int get hints => _p.getInt('opt.hints') ?? kHintStart;

  /// 한 개 쓴다. 없으면 false.
  Future<bool> spendHint() async {
    final n = hints;
    if (n <= 0) return false;
    await _p.setInt('opt.hints', n - 1);
    notifyListeners();
    return true;
  }

  Future<void> addHints(int n) async {
    await _p.setInt('opt.hints', hints + n);
    notifyListeners();
  }

  // ── 설정
  bool get soundOn => _p.getBool('opt.sound') ?? true;

  /// 선택한 언어 코드. null이면 기기 언어를 따른다.
  String? get langCode => _p.getString('opt.lang');

  Future<void> setLangCode(String? code) async {
    if (code == null) {
      await _p.remove('opt.lang');
    } else {
      await _p.setString('opt.lang', code);
    }
    notifyListeners();
  }

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
