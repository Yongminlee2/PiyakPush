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

  /// 이동음은 처프 3종을 돌려써서 걸을 때 기계음처럼 들리지 않게 한다.
  int _chirp = 0;

  String _assetFor(Sfx s) {
    if (s != Sfx.move) return 'audio/${s.name}.wav';
    _chirp = (_chirp % 3) + 1;
    return 'audio/chirp$_chirp.wav';
  }

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
