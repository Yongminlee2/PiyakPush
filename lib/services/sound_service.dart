/// 짧은 SFX 재생. 음소거는 설정(SaveService)을 콜백으로 조회한다.
library;

import 'package:audioplayers/audioplayers.dart';

import '../engine/move.dart';

enum Sfx { move, push, slide, nest, clear, unlock, button, crack, teleport }

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
      _pools[s] =
          await AudioPool.createFromAsset(path: _assetFor(s), maxPlayers: 2);
    }
  }

  String _assetFor(Sfx s) => 'audio/${s.name}.wav';

  Future<void> play(Sfx s) async {
    if (isMuted()) return;
    if (playOverride != null) {
      await playOverride!(_assetFor(s));
      return;
    }
    await _pools[s]?.start();
  }

  /// 한 이동의 이벤트 묶음 → 대표음 1개 + 부가음(붕괴·문).
  Future<void> playForEvents(List<GameEvent> events, bool cleared) async {
    final types = events.map((e) => e.type).toSet();
    if (cleared) {
      await play(Sfx.clear);
    } else if (types.contains(GameEventType.eggNested)) {
      await play(Sfx.nest);
    } else if (types.contains(GameEventType.eggTeleported) ||
        types.contains(GameEventType.chickTeleported)) {
      await play(Sfx.teleport);
    } else if (types.contains(GameEventType.eggSlid)) {
      await play(Sfx.slide);
    } else if (types.contains(GameEventType.eggPushed)) {
      await play(Sfx.push);
    } else if (types.contains(GameEventType.chickMoved)) {
      await play(Sfx.move);
    }
    if (types.contains(GameEventType.floorBroke)) {
      await play(Sfx.crack);
    } else if (types.contains(GameEventType.doorOpened) ||
        types.contains(GameEventType.doorClosed)) {
      await play(Sfx.button);
    }
  }
}
