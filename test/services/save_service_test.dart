import 'package:flutter_test/flutter_test.dart';
import 'package:piyak_push/services/save_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('별 저장은 최고 기록만 갱신', () async {
    final s = await SaveService.load();
    await s.setStars('c1s01', 2);
    expect(s.starsOf('c1s01'), 2);
    await s.setStars('c1s01', 1); // 더 낮음 — 무시
    expect(s.starsOf('c1s01'), 2);
    await s.setStars('c1s01', 3);
    expect(s.starsOf('c1s01'), 3);
  });

  test('챕터 합계·전체 합계', () async {
    final s = await SaveService.load();
    await s.setStars('c1s01', 3);
    await s.setStars('c1s10', 2);
    await s.setStars('c2s01', 1);
    expect(s.chapterStars(1), 5);
    expect(s.chapterStars(2), 1);
    expect(s.totalStars, 6);
  });

  test('챕터 해금: 이전 챕터 별 12개 경계', () async {
    final s = await SaveService.load();
    expect(s.chapterUnlocked(1), true);
    for (var i = 1; i <= 4; i++) {
      await s.setStars('c1s0$i', 3); // 12개
    }
    expect(s.chapterStars(1), 12);
    expect(s.chapterUnlocked(2), true);
    expect(s.chapterUnlocked(3), false);

    final s2 = await SaveService.load();
    await s2.resetAll();
    await s2.setStars('c1s01', 3);
    await s2.setStars('c1s02', 3);
    await s2.setStars('c1s03', 3);
    await s2.setStars('c1s04', 2); // 11개
    expect(s2.chapterUnlocked(2), false);
  });

  test('설정 토글과 초기화', () async {
    final s = await SaveService.load();
    expect(s.soundOn, true);
    expect(s.dpadOn, false);
    await s.setSoundOn(false);
    await s.setDpadOn(true);
    expect(s.soundOn, false);
    expect(s.dpadOn, true);
    await s.resetAll();
    expect(s.soundOn, true);
    expect(s.starsOf('c1s01'), 0);
  });
}
