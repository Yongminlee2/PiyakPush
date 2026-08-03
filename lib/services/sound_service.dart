/// 짧은 SFX 재생. 음소거는 설정(SaveService)을 콜백으로 조회한다.
library;

import 'package:audioplayers/audioplayers.dart';

import '../engine/move.dart';

enum Sfx {
  move,
  bump,
  push,
  slide,
  nest,
  clear,
  unlock,
  button,
  crack,
  teleport,
}

class SoundService {
  final bool Function() isMuted;

  /// 테스트 주입용. null이면 실제 AudioPlayer 재생.
  final Future<void> Function(String asset)? playOverride;

  SoundService({required this.isMuted, this.playOverride});

  /// 미리 로드해 둔 플레이어 풀. 소리 낼 때마다 새 플레이어를 만들고
  /// 파일을 그때 로드하면, 버튼을 누르고 소리가 날 때까지 지연이 생긴다.
  final Map<Sfx, AudioPool> _pools = {};

  /// 앱 시작 때 한 번 호출 — 효과음 전부를 미리 올려 둔다.
  Future<void> init() async {
    if (playOverride != null) return;
    for (final s in Sfx.values) {
      // 걸음이 160ms 간격이라 그보다 긴 소리(둥지 230·굴 250·미끄럼 200)는
      // 2개로는 다음 걸음에 밀려 잘린다. 넉넉히 4개씩 잡는다.
      _pools[s] = await AudioPool.createFromAsset(
        path: _assetFor(s),
        maxPlayers: 4,
      );
    }
  }

  String _assetFor(Sfx s) => 'audio/${s.name}.wav';

  Future<void> play(Sfx s) async {
    if (isMuted()) return;
    if (playOverride != null) {
      await playOverride!(_assetFor(s));
      return;
    }
    // 소리 하나 못 냈다고 게임이 멈추면 안 된다. 기기에 따라 오디오 세션이
    // 뺏기거나(통화·다른 앱) 재생이 실패할 수 있다.
    try {
      await _pools[s]?.start();
    } catch (_) {}
  }

  /// 한 이동의 이벤트 묶음 → 대표음 1개 + 부가음(붕괴·문).
  ///
  /// 둘을 이어서 await 하면 뒤엣것이 앞엣것의 재생 요청이 끝날 때까지
  /// 기다린다 — 같은 순간에 나야 할 소리가 한 박자 밀린다.
  /// 동시에 띄우고 함께 기다린다.
  Future<void> playForEvents(List<GameEvent> events, bool cleared) {
    final types = events.map((e) => e.type).toSet();
    final main = _mainSfx(types, cleared);
    final extra = _extraSfx(types);
    return Future.wait([
      if (main != null) play(main),
      if (extra != null) play(extra),
    ]);
  }

  /// 이번 이동을 대표하는 소리 하나. 위쪽이 우선한다.
  Sfx? _mainSfx(Set<GameEventType> types, bool cleared) {
    if (cleared) return Sfx.clear;
    if (types.contains(GameEventType.eggNested)) return Sfx.nest;
    if (types.contains(GameEventType.eggTeleported) ||
        types.contains(GameEventType.chickTeleported)) {
      return Sfx.teleport;
    }
    if (types.contains(GameEventType.eggSlid)) return Sfx.slide;
    if (types.contains(GameEventType.eggPushed)) return Sfx.push;
    if (types.contains(GameEventType.chickMoved)) return Sfx.move;
    return null;
  }

  /// 대표음과 함께 나는 소리 (바닥 붕괴·문 여닫힘).
  Sfx? _extraSfx(Set<GameEventType> types) {
    if (types.contains(GameEventType.floorBroke)) return Sfx.crack;
    if (types.contains(GameEventType.doorOpened) ||
        types.contains(GameEventType.doorClosed)) {
      return Sfx.button;
    }
    return null;
  }
}
