/// 방향키로 계속 걷다가 앱이 예고 없이 꺼지던 문제.
///
/// 소리 재생이 실패하면 그 소리를 다시 만들어 되살리는데, **쓰던 풀을
/// 반납하지 않고 새로 만들기만 했다.** 풀 하나는 네이티브 오디오 플레이어를
/// 여러 개 쥐고 있어서, 되살릴 때마다 그게 회수되지 않고 쌓인다.
/// 걸음마다 되살리기가 돌면 몇십 초 만에 안드로이드의 동시 재생 한도를
/// 넘기고, Dart 예외 없이 프로세스가 통째로 죽는다(아무 메시지도 안 남는다).
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:piyak_push/engine/geometry.dart';
import 'package:piyak_push/engine/move.dart';
import 'package:piyak_push/services/sound_service.dart';

GameEvent _moved() =>
    const GameEvent(GameEventType.chickMoved, Point(0, 0), Point(1, 0));

/// 항상 재생에 실패하는 가짜 풀 — 오디오를 뺏긴 상태를 흉내 낸다.
class _FailingPool implements SfxPool {
  final void Function() onDispose;
  bool disposed = false;
  _FailingPool(this.onDispose);

  @override
  Future<void> start() async => throw StateError('오디오 없음');

  @override
  Future<void> dispose() async {
    disposed = true;
    onDispose();
  }
}

void main() {
  test('되살릴 때 쓰던 풀을 반드시 반납한다', () async {
    var created = 0;
    var disposed = 0;
    final s = SoundService(
      isMuted: () => false,
      poolFactory: (_) async {
        created++;
        return _FailingPool(() => disposed++);
      },
    );
    await s.init();
    final madeAtStart = created;

    // 한 번 걸으면 재생이 실패하고 되살리기가 돈다
    await s.playForEvents([_moved()], false);

    expect(created, madeAtStart + 1, reason: '되살리면서 새 풀을 만든다');
    expect(disposed, 1,
        reason: '새로 만들기 전에 쓰던 풀을 반납해야 한다 — '
            '안 하면 네이티브 플레이어가 쌓여 앱이 죽는다');
  });

  test('계속 실패해도 한없이 되살리지 않는다', () async {
    var created = 0;
    final s = SoundService(
      isMuted: () => false,
      poolFactory: (_) async {
        created++;
        return _FailingPool(() {});
      },
    );
    await s.init();
    final madeAtStart = created;

    // 방향키를 꾹 눌러 100걸음 걸었다고 치자
    for (var i = 0; i < 100; i++) {
      await s.playForEvents([_moved()], false);
    }

    expect(created - madeAtStart, lessThanOrEqualTo(SoundService.kMaxRevives),
        reason: '되살리기가 걸음 수만큼 돌면 그게 곧 자원 고갈이다');
  });

  test('되살리기에 성공하면 그다음부터 소리가 다시 난다', () async {
    var failNext = true;
    var started = 0;
    final s = SoundService(
      isMuted: () => false,
      poolFactory: (_) async => _RecoveringPool(
        shouldFail: () => failNext,
        onStart: () => started++,
      ),
    );
    await s.init();

    await s.playForEvents([_moved()], false); // 실패 → 되살림
    failNext = false;
    await s.playForEvents([_moved()], false); // 이제 나야 한다

    expect(started, greaterThan(0), reason: '되살린 뒤에도 소리가 안 난다');
  });
}

/// 조건에 따라 실패했다가 회복되는 가짜 풀.
class _RecoveringPool implements SfxPool {
  final bool Function() shouldFail;
  final void Function() onStart;
  _RecoveringPool({required this.shouldFail, required this.onStart});

  @override
  Future<void> start() async {
    if (shouldFail()) throw StateError('오디오 없음');
    onStart();
  }

  @override
  Future<void> dispose() async {}
}
