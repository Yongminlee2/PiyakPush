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

/// 소리 하나가 쓰는 플레이어 묶음. 테스트에서 가짜로 갈아 끼울 수 있게
/// 최소한만 드러낸다.
abstract class SfxPool {
  Future<void> start();
  Future<void> dispose();
}

/// 실제 [AudioPool]을 감싼 것.
class _AudioSfxPool implements SfxPool {
  final AudioPool _pool;
  _AudioSfxPool(this._pool);

  @override
  Future<void> start() => _pool.start();

  @override
  Future<void> dispose() => _pool.dispose();
}

class SoundService {
  final bool Function() isMuted;

  /// 테스트 주입용. null이면 실제 AudioPlayer 재생.
  final Future<void> Function(String asset)? playOverride;

  /// 테스트 주입용. null이면 실제 [AudioPool]을 만든다.
  final Future<SfxPool> Function(String asset)? poolFactory;

  SoundService({required this.isMuted, this.playOverride, this.poolFactory});

  /// 미리 로드해 둔 플레이어 풀. 소리 낼 때마다 새 플레이어를 만들고
  /// 파일을 그때 로드하면, 버튼을 누르고 소리가 날 때까지 지연이 생긴다.
  final Map<Sfx, SfxPool> _pools = {};

  /// 지금 다시 만들고 있는 소리 — 한꺼번에 여러 번 만들지 않게.
  final Set<Sfx> _rebuilding = {};

  /// 소리별로 되살린 횟수. 한없이 되살리면 안 되기 때문에 센다.
  final Map<Sfx, int> _reviveCount = {};

  /// 한 소리를 되살려 보는 최대 횟수.
  ///
  /// 오디오를 못 쓰는 상태가 계속되면 되살리기도 계속 실패한다. 그때
  /// 무한정 다시 만들면 **네이티브 플레이어만 쌓여 앱이 통째로 죽는다.**
  /// 몇 번 해 보고 안 되면 그 소리는 조용히 포기한다 — 게임은 계속된다.
  static const kMaxRevives = 3;

  /// 되살린 횟수 (테스트에서 확인용).
  int rebuildCount = 0;

  /// 앱 시작 때 한 번 호출 — 효과음 전부를 미리 올려 둔다.
  Future<void> init() async {
    if (playOverride != null) return;
    for (final s in Sfx.values) {
      await _make(s);
    }
  }

  Future<SfxPool> _createPool(String asset) async {
    final custom = poolFactory;
    if (custom != null) return custom(asset);
    // maxPlayers는 "미리 만들어 두는 수"가 아니라 **재사용하려고 남겨 두는
    // 상한**이다. 재생 요청이 몰리면 풀이 알아서 더 만들고, 다 끝나면
    // 넷까지만 남기고 나머지는 반납한다. 걸음이 160ms 간격이라 그보다 긴
    // 소리(둥지 230·굴 250·미끄럼 200)가 겹칠 수 있어 넷까지 남긴다.
    return _AudioSfxPool(
      await AudioPool.createFromAsset(path: asset, maxPlayers: 4),
    );
  }

  Future<void> _make(Sfx s) async {
    // 갈아 끼우기 전에 **쓰던 풀을 반드시 반납한다.** 이걸 빼먹으면 되살릴
    // 때마다 네이티브 오디오 플레이어가 회수되지 않고 그대로 남는다.
    // 방향키로 계속 걸으면 걸음마다 되살리기가 돌 수 있어서, 몇십 초 만에
    // 안드로이드의 동시 재생 한도를 넘기고 앱이 예고 없이 꺼진다.
    // (Dart 예외가 아니라 네이티브 쪽에서 죽어서 아무 메시지도 안 남는다.)
    final old = _pools.remove(s);
    await old?.dispose();
    _pools[s] = await _createPool(_assetFor(s));
  }

  String _assetFor(Sfx s) => 'audio/${s.name}.wav';

  Future<void> play(Sfx s) async {
    if (isMuted()) return;
    try {
      if (playOverride != null) {
        await playOverride!(_assetFor(s));
      } else {
        await _pools[s]?.start();
      }
    } catch (_) {
      // 소리 하나 못 냈다고 게임이 멈추면 안 된다. 다만 **그냥 삼키면
      // 그 소리는 영영 안 난다** — 풀은 재생이 끝나야 플레이어를 돌려받는데,
      // 통화·다른 앱에 오디오를 뺏기거나 하면 그 신호를 놓쳐 자리가
      // 하나씩 줄고, 넷이 다 막히면 그때부터 죽은 채로 남는다.
      // 연속으로 누를 때 잘 생긴다 — 가장 자주 부르는 길이라서.
      // 되살려 둔다.
      await _revive(s);
    }
  }

  /// 죽은 소리를 다시 만든다. [kMaxRevives]번까지만.
  Future<void> _revive(Sfx s) async {
    if (playOverride != null) return;
    if ((_reviveCount[s] ?? 0) >= kMaxRevives) return; // 포기한 소리
    if (!_rebuilding.add(s)) return;
    _reviveCount[s] = (_reviveCount[s] ?? 0) + 1;
    try {
      await _make(s);
      rebuildCount++;
    } catch (_) {
      // 다시 만드는 것마저 실패하면 그 소리는 포기한다 (게임은 계속된다)
    } finally {
      _rebuilding.remove(s);
    }
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
