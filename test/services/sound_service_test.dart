import 'package:flutter_test/flutter_test.dart';
import 'package:piyak_push/engine/geometry.dart';
import 'package:piyak_push/engine/move.dart';
import 'package:piyak_push/services/sound_service.dart';

void main() {
  test('음소거면 재생 안 함', () async {
    final played = <String>[];
    final s = SoundService(
        isMuted: () => true, playOverride: (a) async => played.add(a));
    await s.play(Sfx.move);
    expect(played, isEmpty);
  });

  test('재생 시 에셋 경로', () async {
    final played = <String>[];
    final s = SoundService(
        isMuted: () => false, playOverride: (a) async => played.add(a));
    await s.play(Sfx.nest);
    expect(played, ['audio/nest.wav']);
  });

  test('이동음은 처프 3종을 순환한다', () async {
    final played = <String>[];
    final s = SoundService(
        isMuted: () => false, playOverride: (a) async => played.add(a));
    for (var i = 0; i < 4; i++) {
      await s.play(Sfx.move);
    }
    expect(played, [
      'audio/chirp1.wav',
      'audio/chirp2.wav',
      'audio/chirp3.wav',
      'audio/chirp1.wav',
    ]);
  });

  test('음소거 중엔 처프 순번이 진행하지 않는다', () async {
    var muted = true;
    final played = <String>[];
    final s = SoundService(
        isMuted: () => muted, playOverride: (a) async => played.add(a));
    await s.play(Sfx.move);
    muted = false;
    await s.play(Sfx.move);
    expect(played, ['audio/chirp1.wav']);
  });

  test('이벤트 매핑: 우선순위 (클리어 > 둥지 > 텔레포트 > 슬라이드 > 밀기 > 이동)', () async {
    final played = <String>[];
    final s = SoundService(
        isMuted: () => false, playOverride: (a) async => played.add(a));

    GameEvent ev(GameEventType t) =>
        GameEvent(t, const Point(0, 0), const Point(1, 0));

    await s.playForEvents([ev(GameEventType.chickMoved)], false);
    await s.playForEvents(
        [ev(GameEventType.eggPushed), ev(GameEventType.chickMoved)], false);
    await s.playForEvents(
        [ev(GameEventType.eggPushed), ev(GameEventType.eggSlid)], false);
    await s.playForEvents(
        [ev(GameEventType.eggPushed), ev(GameEventType.eggNested)], true);
    expect(played, [
      'audio/chirp1.wav',
      'audio/push.wav',
      'audio/slide.wav',
      'audio/clear.wav',
    ]);

    played.clear();
    await s.playForEvents(
        [ev(GameEventType.eggPushed), ev(GameEventType.floorBroke)], false);
    expect(played, ['audio/push.wav', 'audio/crack.wav']);
  });
}
