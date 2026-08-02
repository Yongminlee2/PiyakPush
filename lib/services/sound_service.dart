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

  /// 이동음은 삐약영어 앱에서 쓰던 진짜 삐약 소리(sfx_piyak.ogg)를 그대로 쓴다.
  /// 직접 합성한 처프는 오리 소리처럼 들려서 교체했다.
  String _assetFor(Sfx s) =>
      s == Sfx.move ? 'audio/chirp.ogg' : 'audio/${s.name}.wav';

  Future<void> play(Sfx s) async {
    if (isMuted()) return; // 음소거면 처프 순번도 진행하지 않는다
    final asset = _assetFor(s);
    if (playOverride != null) {
      await playOverride!(asset);
      return;
    }
    final p = AudioPlayer();
    p.onPlayerComplete.listen((_) => p.dispose());
    await p.play(AssetSource(asset), mode: PlayerMode.lowLatency);
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
