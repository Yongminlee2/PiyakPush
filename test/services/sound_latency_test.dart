/// 효과음이 밀리지 않는지.
///
/// 소리 두 개가 같은 순간에 나야 할 때(알을 밀며 바닥이 무너짐 등),
/// 앞 소리의 재생 요청이 끝나기를 기다렸다가 뒤 소리를 내면 한 박자 밀린다.
/// 재생을 일부러 느리게 만들어 놓고, 두 번째가 첫 번째를 기다리는지 본다.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:piyak_push/engine/geometry.dart';
import 'package:piyak_push/engine/move.dart';
import 'package:piyak_push/services/sound_service.dart';

GameEvent _ev(GameEventType t) =>
    GameEvent(t, const Point(0, 0), const Point(1, 0));

void main() {
  test('같이 나야 할 소리가 서로를 기다리지 않는다', () async {
    final started = <String>[];
    final sw = Stopwatch()..start();
    final startedAt = <String, int>{};

    final s = SoundService(
      isMuted: () => false,
      playOverride: (a) async {
        started.add(a);
        startedAt[a] = sw.elapsedMilliseconds;
        // 기기에서 재생 요청이 오래 걸리는 상황을 흉내 낸다
        await Future<void>.delayed(const Duration(milliseconds: 80));
      },
    );

    // 알을 밀었고 그 자리 바닥이 무너졌다 — 두 소리가 같이 나야 한다
    await s.playForEvents(
      [_ev(GameEventType.eggPushed), _ev(GameEventType.floorBroke)],
      false,
    );

    expect(started, containsAll(['audio/push.wav', 'audio/crack.wav']));
    final gap =
        (startedAt['audio/crack.wav']! - startedAt['audio/push.wav']!).abs();
    expect(gap, lessThan(20),
        reason: '두 번째 소리가 ${gap}ms 밀렸다 — 같이 나야 한다');
  });

  test('한 이동에 대표음은 하나만 난다', () async {
    final played = <String>[];
    final s = SoundService(
        isMuted: () => false, playOverride: (a) async => played.add(a));

    // 밀기 + 둥지 안착이 함께 일어나면 둥지 소리만 (둘 다 나면 시끄럽다)
    await s.playForEvents(
      [_ev(GameEventType.eggPushed), _ev(GameEventType.eggNested)],
      false,
    );
    expect(played, ['audio/nest.wav']);
  });

  test('걸음마다 소리가 빠짐없이 난다', () async {
    // 연속 이동은 160ms 간격이다. 빠르게 이어져도 요청이 누락되면 안 된다.
    final played = <String>[];
    final s = SoundService(
      isMuted: () => false,
      playOverride: (a) async {
        played.add(a);
        await Future<void>.delayed(const Duration(milliseconds: 50));
      },
    );
    final futures = [
      for (var i = 0; i < 10; i++)
        s.playForEvents([_ev(GameEventType.chickMoved)], false),
    ];
    await Future.wait(futures);
    expect(played.length, 10);
    expect(played.every((p) => p == 'audio/move.wav'), true);
  });

  test('재생이 실패해도 게임은 멈추지 않는다', () async {
    // 오디오를 뺏기는 상황을 흉내 낸다. 예외가 밖으로 나가면
    // 이동 처리까지 끊겨 게임이 멈춘다.
    final s = SoundService(
      isMuted: () => false,
      playOverride: (_) async => throw StateError('오디오 없음'),
    );
    await expectLater(
      s.playForEvents([_ev(GameEventType.chickMoved)], false),
      completes,
    );
  });

  test('음소거면 아무것도 재생하지 않는다', () async {
    final played = <String>[];
    final s = SoundService(
        isMuted: () => true, playOverride: (a) async => played.add(a));
    await s.playForEvents([_ev(GameEventType.chickMoved)], false);
    await s.playForEvents([_ev(GameEventType.eggPushed)], true);
    expect(played, isEmpty);
  });
}
