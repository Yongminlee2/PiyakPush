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

  test('chapterClearedCount는 별 1개 이상인 스테이지 수', () async {
    final s = await SaveService.load();
    await s.setStars('c2s01', 3);
    await s.setStars('c2s02', 1);
    await s.setStars('c2s03', 2);
    expect(s.chapterClearedCount(2), 3);
    expect(s.chapterClearedCount(1), 0);
  });

  test('챕터 해금: 클리어 8개 경계', () async {
    final s = await SaveService.load();
    expect(s.chapterUnlocked(1), true);
    for (var i = 1; i <= 7; i++) {
      await s.setStars('c1s0$i', 1);
    }
    expect(s.chapterUnlocked(2), false); // 7개로는 안 열린다
    await s.setStars('c1s08', 1);
    expect(s.chapterUnlocked(2), true); // 8개면 열린다
  });

  test('10스테이지를 별 1개씩 다 깨면 다음 챕터가 열린다 (v1.1 결함 회귀)', () async {
    final s = await SaveService.load();
    for (var i = 1; i <= 10; i++) {
      await s.setStars('c3s${i.toString().padLeft(2, '0')}', 1);
    }
    expect(s.chapterStars(3), 10); // 별로는 옛 기준 12개에 못 미친다
    expect(s.chapterUnlocked(4), true); // 그래도 열려야 한다
  });

  test('totalStars는 20챕터를 모두 센다', () async {
    final s = await SaveService.load();
    await s.setStars('c1s01', 3);
    await s.setStars('c12s01', 3);
    await s.setStars('c20s10', 2);
    expect(s.totalStars, 8);
  });

  test('설정 토글과 초기화 (방향키는 기본 켜짐)', () async {
    final s = await SaveService.load();
    expect(s.soundOn, true);
    expect(s.dpadOn, true); // 스와이프보다 방향키가 기본
    await s.setSoundOn(false);
    await s.setDpadOn(false);
    expect(s.soundOn, false);
    expect(s.dpadOn, false);
    await s.resetAll();
    expect(s.soundOn, true);
    expect(s.dpadOn, true);
    expect(s.starsOf('c1s01'), 0);
  });
}
